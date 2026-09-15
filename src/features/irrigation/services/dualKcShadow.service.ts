import { supabase } from '../../../supabaseClient';

export type DualKcShadowScenarioFinalState = {
  surfaceDepletionMm: number | null;
  rootDepletionMm: number | null;
  stressCoefficient: number | null;
  actualEtMm: number | null;
};

export type DualKcShadowScenario = {
  rewMm: number | null;
  finalState: DualKcShadowScenarioFinalState;
};

export type DualKcShadowEvidence = {
  ok: boolean;
  blocked: boolean;
  notApplicable: boolean;
  cached: boolean;
  fieldId: string;
  productionAuthority: false;
  missingInputs: string[];
  scenarios: DualKcShadowScenario[];
  engineVersion: string | null;
  completedAt: string | null;
  error: string | null;
};

const inFlight = new Map<string, Promise<DualKcShadowEvidence>>();

function finiteOrNull(value: unknown) {
  if (value === null || value === undefined || value === '') return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function stringArray(value: unknown) {
  return Array.isArray(value) ? value.map(String) : [];
}

function normalizeScenario(value: any): DualKcShadowScenario {
  return {
    rewMm: finiteOrNull(value?.rew_mm),
    finalState: {
      surfaceDepletionMm: finiteOrNull(value?.final_state?.surface_depletion_mm),
      rootDepletionMm: finiteOrNull(value?.final_state?.root_depletion_mm),
      stressCoefficient: finiteOrNull(value?.final_state?.stress_coefficient),
      actualEtMm: finiteOrNull(value?.final_state?.actual_et_mm),
    },
  };
}

function emptyEvidence(fieldId: string, error: string): DualKcShadowEvidence {
  return {
    ok: false,
    blocked: true,
    notApplicable: false,
    cached: false,
    fieldId,
    productionAuthority: false,
    missingInputs: [],
    scenarios: [],
    engineVersion: null,
    completedAt: null,
    error,
  };
}

export async function runDualKcShadowEvidence(
  fieldId: string,
): Promise<DualKcShadowEvidence> {
  const field = String(fieldId ?? '').trim();
  if (!field) return emptyEvidence('', 'Tarla kimliği gerekli.');

  const existing = inFlight.get(field);
  if (existing) return existing;

  const request = (async () => {
    try {
      const { data, error } = await supabase.functions.invoke(
        'pyfao56-dual-kc-shadow-run',
        {
          body: { field_id: field },
        },
      );

      if (error) throw error;
      if (!data?.ok) {
        throw new Error(String(data?.error ?? 'Gelişmiş su modeli çalıştırılamadı.'));
      }

      const result = data?.result ?? null;
      const scenarios = Array.isArray(result?.scenarios)
        ? result.scenarios.map(normalizeScenario)
        : [];

      return {
        ok: true,
        blocked: Boolean(data?.blocked),
        notApplicable: Boolean(data?.not_applicable),
        cached: Boolean(data?.cached),
        fieldId: String(data?.field_id ?? field),
        productionAuthority: false as const,
        missingInputs: stringArray(data?.missing_inputs),
        scenarios,
        engineVersion:
          result?.engine_version == null
            ? null
            : String(result.engine_version),
        completedAt:
          data?.completed_at == null
            ? null
            : String(data.completed_at),
        error: null,
      };
    } catch (error) {
      return emptyEvidence(
        field,
        error instanceof Error
          ? error.message
          : 'Gelişmiş su modeli çalıştırılamadı.',
      );
    } finally {
      inFlight.delete(field);
    }
  })();

  inFlight.set(field, request);
  return request;
}

export function runDualKcShadowEvidenceBestEffort(fieldId: string) {
  const field = String(fieldId ?? '').trim();
  if (!field) return;

  void runDualKcShadowEvidence(field).then((result) => {
    if (!result.ok && result.error) {
      console.warn('[dual-kc-shadow] refresh failed', result.error);
    }
  });
}

export function summarizeDualKcShadowRange(
  evidence: DualKcShadowEvidence | null | undefined,
) {
  if (!evidence?.ok || evidence.blocked || evidence.scenarios.length === 0) {
    return null;
  }

  const rootValues = evidence.scenarios
    .map((scenario) => scenario.finalState.rootDepletionMm)
    .filter((value): value is number => value !== null);
  const surfaceValues = evidence.scenarios
    .map((scenario) => scenario.finalState.surfaceDepletionMm)
    .filter((value): value is number => value !== null);
  const stressValues = evidence.scenarios
    .map((scenario) => scenario.finalState.stressCoefficient)
    .filter((value): value is number => value !== null);

  const range = (values: number[]) =>
    values.length
      ? { min: Math.min(...values), max: Math.max(...values) }
      : null;

  return {
    rootDepletionMm: range(rootValues),
    surfaceDepletionMm: range(surfaceValues),
    stressCoefficient: range(stressValues),
    scenarioCount: evidence.scenarios.length,
    productionAuthority: false as const,
  };
}
