import type { HomeDecisionEvent } from '../../decision/types/homeDecision';
import type { NdviAnomalyResult } from '../types/ndviAnomaly';
import { isRecentSatelliteObservation } from './buildHomeSatelliteDecision';

export type HomeNdviAnomalySignal = NdviAnomalyResult & {
  fieldId: string;
  status: 'idle' | 'loading' | 'ready' | 'error';
};

/**
 * NDVI anomalisi bir teşhis değildir. Bu adaptör yalnızca motorun gerçek
 * gözlemlerden ürettiği negatif anomalinin sahada kontrol edilmesini ister.
 */
export function buildNdviAnomalyDecision(
  fieldId: string,
  signal: HomeNdviAnomalySignal | null | undefined,
  activeGrowth: boolean,
  now = new Date(),
): HomeDecisionEvent | null {
  if (
    !fieldId || signal?.fieldId !== fieldId || signal.status !== 'ready' ||
    signal.quality !== 'usable' || !signal.anomaly || signal.direction !== 'negative' ||
    signal.observationCount < 5 || signal.spanDays == null || signal.spanDays < 20 ||
    !activeGrowth || !isRecentSatelliteObservation(signal.latestDate, now)
  ) return null;

  const score = Number.isFinite(signal.robustScore) ? Math.abs(signal.robustScore as number) : null;
  const deviation = Number.isFinite(signal.deviation) ? signal.deviation as number : null;
  const evidence = [
    `${signal.observationCount} gerçek NDVI gözlemi, ${signal.spanDays} günlük dönem.`,
    deviation != null ? `Son gözlem tarla baz medyanından ${Math.abs(deviation).toFixed(3)} NDVI daha düşük.` : '',
    score != null ? `Robust anomali skoru: ${score.toFixed(2)}.` : '',
  ].filter(Boolean);

  return {
    id: `satellite:${fieldId}:ndvi-negative-anomaly:${signal.latestDate ?? 'latest'}`,
    group: 'satellite-anomaly',
    source: 'satellite',
    priority: 92,
    severity: 'warning',
    target: 'map_vegetation',
    channels: ['today', 'notification', 'pusula'],
    label: 'UYDU UYARISI',
    title: 'NDVI Anomalisi Tespit Edildi',
    detail: 'Son uydu gözlemi tarlanın kendi yakın geçmişinden belirgin biçimde düşük. Haritadaki alanları sahada kontrol et; bu sinyal tek başına hastalık, su veya besin eksikliği teşhisi değildir.',
    evidence,
    today: { tone: 'amber', visual: 'spraying', iconKey: 'leaf-green', iconClass: 'leaf' },
    notification: { iconKey: 'leaf', iconTone: 'green', dotTone: 'warning' },
  };
}
