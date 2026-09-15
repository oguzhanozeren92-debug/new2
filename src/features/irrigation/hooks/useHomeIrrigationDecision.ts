import { useCallback, useEffect, useState } from 'react';
import type { IrrigationDecisionResult } from '../types/irrigationDecision';
import {
  loadLatestDualKcShadowAudit,
  runDualKcShadowEvidenceBestEffort,
} from '../services/dualKcShadow.service';
import {
  publishHomeDualKcEvidenceSnapshot,
} from '../services/homeDualKcEvidenceSnapshot';

type HomeIrrigationDecisionState = {
  fieldKey: string;
  status: 'idle' | 'loading' | 'ready' | 'error';
  data: IrrigationDecisionResult | null;
  error: string | null;
};

export type HomeDualKcEvidenceStatus =
  | 'idle'
  | 'loading'
  | 'ready'
  | 'waiting'
  | 'not_applicable'
  | 'error';

type HomeDualKcEvidenceState = {
  fieldKey: string;
  status: HomeDualKcEvidenceStatus;
  missingInputs: string[];
};

const INITIAL_STATE: HomeIrrigationDecisionState = {
  fieldKey: '',
  status: 'idle',
  data: null,
  error: null,
};

const INITIAL_EVIDENCE_STATE: HomeDualKcEvidenceState = {
  fieldKey: '',
  status: 'idle',
  missingInputs: [],
};

/**
 * Ana ekran için hata-izole Irrigation Engine köprüsü.
 *
 * Irrigation service zinciri dinamik import edilir. Böylece kök bölgesi/Kc/
 * fenoloji gibi alt bağımlılıklardan biri yüklenemezse HomeScreen beyaz ekrana
 * düşmez; hook error durumuna geçer ve ortak karar motoru hava-tabanlı güvenli
 * fallback ile çalışmaya devam eder.
 *
 * Dual-Kc sonucu burada yalnız MODEL KANITI olarak okunur. Production sulama
 * kararını, karar kodunu veya önerilen su miktarını değiştirmez.
 */
export function useHomeIrrigationDecision(field: any | null | undefined) {
  const fieldKey = field?.id != null ? String(field.id) : '';
  const isDemo = Boolean(field?.demo);
  const irrigationStatus = String(field?.irrigationStatus ?? '').trim().toLowerCase();
  const isRainfed = irrigationStatus === 'rainfed';
  const [refreshKey, setRefreshKey] = useState(0);
  const [state, setState] = useState<HomeIrrigationDecisionState>(INITIAL_STATE);
  const [evidenceState, setEvidenceState] = useState<HomeDualKcEvidenceState>(INITIAL_EVIDENCE_STATE);

  useEffect(() => {
    let cancelled = false;

    if (!fieldKey || isDemo) {
      setState(INITIAL_STATE);
      return () => {
        cancelled = true;
      };
    }

    setState({
      fieldKey,
      status: 'loading',
      data: null,
      error: null,
    });

    void (async () => {
      try {
        const irrigationModule = await import(
          '../services/irrigationDecision.service'
        );

        if (typeof irrigationModule.calculateIrrigationDecision !== 'function') {
          throw new Error('Sulama Motoru servisi yüklenemedi.');
        }

        const result = await irrigationModule.calculateIrrigationDecision({
          id: fieldKey,
        });

        if (cancelled) return;

        console.info('[TarlaPusula] Sulama Motoru sonucu:', {
          fieldKey,
          decision: result?.decision ?? null,
          irrigationStatus: result?.irrigationStatus ?? null,
          confidence: result?.confidence ?? null,
        });

        setState({
          fieldKey,
          status: 'ready',
          data: result,
          error: null,
        });
      } catch (error: unknown) {
        if (cancelled) return;

        const message =
          error instanceof Error
            ? error.message
            : 'Sulama kararı hazırlanamadı.';

        console.warn('[TarlaPusula] Sulama Motoru sonucu alınamadı:', error);
        setState({
          fieldKey,
          status: 'error',
          data: null,
          error: message,
        });
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [fieldKey, isDemo, refreshKey]);

  useEffect(() => {
    let cancelled = false;

    if (!fieldKey || isDemo) {
      setEvidenceState(INITIAL_EVIDENCE_STATE);
      return () => {
        cancelled = true;
      };
    }

    if (isRainfed) {
      setEvidenceState({
        fieldKey,
        status: 'not_applicable',
        missingInputs: [],
      });
      return () => {
        cancelled = true;
      };
    }

    const loadEvidence = async () => {
      setEvidenceState((current) => ({
        fieldKey,
        status: current.fieldKey === fieldKey && current.status !== 'idle'
          ? current.status
          : 'loading',
        missingInputs: current.fieldKey === fieldKey ? current.missingInputs : [],
      }));

      try {
        const audit = await loadLatestDualKcShadowAudit(fieldKey);
        if (cancelled) return;

        if (!audit) {
          setEvidenceState({ fieldKey, status: 'waiting', missingInputs: [] });
          return;
        }

        setEvidenceState({
          fieldKey,
          status:
            audit.status === 'completed'
              ? 'ready'
              : audit.status === 'failed'
                ? 'error'
                : audit.status === 'running' || audit.status === 'queued'
                  ? 'loading'
                  : 'waiting',
          missingInputs: audit.missingInputs,
        });
      } catch {
        if (cancelled) return;
        setEvidenceState({ fieldKey, status: 'error', missingInputs: [] });
      }
    };

    void loadEvidence();

    const handleEvidenceUpdated = (event: Event) => {
      const changedFieldId = String((event as CustomEvent)?.detail?.fieldId ?? '');
      if (changedFieldId !== fieldKey) return;
      void loadEvidence();
    };

    if (typeof window !== 'undefined') {
      window.addEventListener(
        'tp:dual-kc-shadow-updated',
        handleEvidenceUpdated as EventListener,
      );
    }

    return () => {
      cancelled = true;
      if (typeof window !== 'undefined') {
        window.removeEventListener(
          'tp:dual-kc-shadow-updated',
          handleEvidenceUpdated as EventListener,
        );
      }
    };
  }, [fieldKey, isDemo, isRainfed]);

  useEffect(() => {
    if (!fieldKey || isDemo || typeof window === 'undefined') return;

    const handleFieldContextUpdated = (event: Event) => {
      const detail = (event as CustomEvent)?.detail ?? {};
      const changedFieldId = String(detail?.fieldId ?? '');
      const changedFields = Array.isArray(detail?.changedFields)
        ? detail.changedFields.map((item: unknown) => String(item))
        : [];

      if (changedFieldId !== fieldKey) return;

      const irrigationRelevant = [
        'irrigation_status',
        'irrigation_method',
        'canopy_development_class',
        'canopy_height_class',
        'canopy_cover_percent',
        'canopy_height_m',
        'bearing',
        'crop_cycle',
        'activities',
        'irrigation_history',
      ];

      if (
        changedFields.length > 0 &&
        !changedFields.some((name) => irrigationRelevant.includes(name))
      ) {
        return;
      }

      setRefreshKey((value) => value + 1);
      runDualKcShadowEvidenceBestEffort(fieldKey);
    };

    window.addEventListener(
      'tp:field-context-updated',
      handleFieldContextUpdated as EventListener,
    );

    return () => {
      window.removeEventListener(
        'tp:field-context-updated',
        handleFieldContextUpdated as EventListener,
      );
    };
  }, [fieldKey, isDemo]);

  const refresh = useCallback(() => {
    if (!fieldKey || isDemo) return;
    setRefreshKey((value) => value + 1);
  }, [fieldKey, isDemo]);

  const stateBelongsToField = state.fieldKey === fieldKey;
  const evidenceBelongsToField = evidenceState.fieldKey === fieldKey;
  const result = stateBelongsToField ? state.data : null;
  const modelEvidence: HomeDualKcEvidenceState = evidenceBelongsToField
    ? evidenceState
    : fieldKey
      ? {
          fieldKey,
          status: isRainfed ? 'not_applicable' : 'loading',
          missingInputs: [],
        }
      : INITIAL_EVIDENCE_STATE;

  publishHomeDualKcEvidenceSnapshot(modelEvidence);

  return {
    result,
    decision: result,
    status: stateBelongsToField ? state.status : fieldKey ? 'loading' : 'idle',
    loading: stateBelongsToField ? state.status === 'loading' : Boolean(fieldKey),
    error: stateBelongsToField ? state.error : null,
    modelEvidence,
    refresh,
  };
}
