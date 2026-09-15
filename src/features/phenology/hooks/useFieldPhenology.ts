import {
  useEffect,
  useMemo,
  useState,
} from 'react';

import {
  buildFieldPhenology,
} from '../services/buildFieldPhenology';

import type {
  FieldForPhenology,
  NdviTrendForPhenology,
} from '../services/buildFieldPhenology';

import {
  buildPcsePhenologyResult,
  runPcsePhenologyPilot,
  type PcsePhenologyPilotResponse,
} from '../services/pcsePhenology.service';

import type {
  PhenologyResult,
} from '../types/phenology';

function textOrNull(value: unknown) {
  const text = String(value ?? '').trim();
  return text || null;
}

export function useFieldPhenology(
  field:
    | FieldForPhenology
    | null
    | undefined,
  ndviTrend?:
    NdviTrendForPhenology,
): PhenologyResult | null {
  const localPhenology = useMemo(
    () => {
      if (!field) {
        return null;
      }

      return buildFieldPhenology(
        field,
        ndviTrend ??
          null,
      );
    },
    [
      field,
      ndviTrend?.direction,
      ndviTrend?.quality,
      ndviTrend?.latestAverage,
      ndviTrend?.changeFromPrevious,
      ndviTrend?.changeFromFirst,
    ],
  );

  const fieldRecord = field as (FieldForPhenology & Record<string, unknown>) | null | undefined;
  const fieldId = textOrNull(fieldRecord?.id);
  const cropCycle = textOrNull(fieldRecord?.cropCycle ?? fieldRecord?.crop_cycle)?.toLowerCase() ?? 'unknown';
  const sowingDate = textOrNull(
    fieldRecord?.sowingDate ??
    fieldRecord?.sowing_date ??
    fieldRecord?.plantingDate ??
    fieldRecord?.planting_date,
  );
  const actualHarvestDate = textOrNull(
    fieldRecord?.actualHarvestDate ??
    fieldRecord?.actual_harvest_date ??
    fieldRecord?.harvestedAt ??
    fieldRecord?.harvested_at,
  );
  const varietyHint = textOrNull(
    fieldRecord?.varietyName ??
    fieldRecord?.variety_name,
  );

  const [pcseRun, setPcseRun] = useState<PcsePhenologyPilotResponse | null>(null);

  useEffect(() => {
    if (
      !fieldId ||
      !sowingDate ||
      actualHarvestDate ||
      cropCycle === 'perennial'
    ) {
      setPcseRun(null);
      return;
    }

    let cancelled = false;
    setPcseRun(null);

    void runPcsePhenologyPilot(fieldId)
      .then((run) => {
        if (!cancelled) setPcseRun(run);
      })
      .catch((error) => {
        if (!cancelled) {
          setPcseRun(null);
          console.warn(
            '[TarlaPusula] PCSE fenoloji pilotu kullanılamadı; güvenli yerel fenoloji sonucu korunuyor:',
            error,
          );
        }
      });

    return () => {
      cancelled = true;
    };
  }, [
    fieldId,
    sowingDate,
    actualHarvestDate,
    cropCycle,
    varietyHint,
  ]);

  const pcsePhenology = useMemo(
    () => buildPcsePhenologyResult(
      pcseRun,
      ndviTrend ?? null,
    ),
    [
      pcseRun,
      ndviTrend?.direction,
      ndviTrend?.quality,
      ndviTrend?.latestAverage,
      ndviTrend?.changeFromPrevious,
      ndviTrend?.changeFromFirst,
    ],
  );

  return pcsePhenology ?? localPhenology;
}
