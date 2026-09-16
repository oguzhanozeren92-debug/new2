import { supabase } from '../../../supabaseClient';
import type { NdviTimeSeriesPoint } from '../types/ndviTimeSeries';

export type NdviAnomalyResult = {
  quality: 'insufficient' | 'usable';
  anomaly: boolean;
  direction: 'unknown' | 'negative' | 'positive' | 'none';
  latestDate: string | null;
  latestAverage: number | null;
  baselineMedian: number | null;
  deviation: number | null;
  mad: number | null;
  robustScore: number | null;
  observationCount: number;
  spanDays: number | null;
  reason: string;
};

export async function analyzeNdviAnomaly(points: NdviTimeSeriesPoint[]): Promise<NdviAnomalyResult> {
  const evidence = points
    .filter(point => Number.isFinite(point.average) && point.average >= -1 && point.average <= 1)
    .map(point => ({ date: point.date, average: point.average }));

  const { data, error } = await supabase.functions.invoke('satellite-ndvi-anomaly', {
    body: { points: evidence },
  });

  if (error) throw error;
  if (!data?.success) throw new Error(data?.message ?? 'NDVI anomali analizi alınamadı.');

  return {
    quality: data.quality === 'usable' ? 'usable' : 'insufficient',
    anomaly: data.quality === 'usable' && data.anomaly === true,
    direction: ['negative', 'positive', 'none'].includes(data.direction) && data.quality === 'usable' ? data.direction : 'unknown',
    latestDate: data.latestDate ? String(data.latestDate) : null,
    latestAverage: Number.isFinite(Number(data.latestAverage)) ? Number(data.latestAverage) : null,
    baselineMedian: Number.isFinite(Number(data.baselineMedian)) ? Number(data.baselineMedian) : null,
    deviation: Number.isFinite(Number(data.deviation)) ? Number(data.deviation) : null,
    mad: Number.isFinite(Number(data.mad)) ? Number(data.mad) : null,
    robustScore: Number.isFinite(Number(data.robustScore)) ? Number(data.robustScore) : null,
    observationCount: Number.isFinite(Number(data.observationCount)) ? Number(data.observationCount) : evidence.length,
    spanDays: Number.isFinite(Number(data.spanDays)) ? Number(data.spanDays) : null,
    reason: String(data.reason ?? ''),
  };
}
