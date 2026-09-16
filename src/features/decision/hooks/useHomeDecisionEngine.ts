import { useMemo } from 'react';
import { HOME_REFERENCE_ASSETS } from '../../home/homeAssets';
import { useRecentFieldOperations } from '../../field-operations/hooks/useRecentFieldOperations';
import { buildNdviAnomalyDecision } from '../../satellite/services/buildNdviAnomalyDecision';
import { getCachedNdviAnomaly } from '../../satellite/services/ndviAnomaly.service';
import { buildHomeDecisionEvents } from '../services/homeDecisionEngine';
import { buildRiskRadarDecision } from '../services/buildRiskRadarDecision';
import type { HomeDecisionEngineInput, HomeDecisionEvent, HomeSystemNotification, HomeTodayDecision, HomeTodayIconKey } from '../types/homeDecision';

function todayIconSrc(iconKey: HomeTodayIconKey): string {
  if (iconKey === 'water') return HOME_REFERENCE_ASSETS.iconWater;
  if (iconKey === 'rain') return HOME_REFERENCE_ASSETS.iconRain;
  if (iconKey === 'document') return HOME_REFERENCE_ASSETS.iconDocument;
  if (iconKey === 'leaf-green') return HOME_REFERENCE_ASSETS.iconLeafGreen;
  return HOME_REFERENCE_ASSETS.iconLeafGold;
}
function selectTodayEvents(events: HomeDecisionEvent[]): HomeDecisionEvent[] {
  const seenGroups = new Set<string>();
  return events.filter(event => event.channels.includes('today') && event.today).filter(event => { if (seenGroups.has(event.group)) return false; seenGroups.add(event.group); return true; }).slice(0, 2);
}
function makeAllClearEvent(fieldKey: string): HomeDecisionEvent {
  return { id: `status:${fieldKey || 'home'}:all-clear`, group: 'status', source: 'field', priority: 1, severity: 'info', target: 'home', channels: ['today'], label: 'BUGÜN', title: 'Acil İşlem Görünmüyor', detail: 'Yeni veri geldikçe burası otomatik güncellenecek', today: { tone: 'green', visual: 'irrigation', iconKey: 'leaf-green', iconClass: 'leaf' } };
}
function toTodayDecision(event: HomeDecisionEvent): HomeTodayDecision | null {
  if (!event.today) return null;
  return { id: event.id, group: event.group, priority: event.priority, label: event.label, title: event.title, detail: event.detail, tone: event.today.tone, visual: event.today.visual, iconSrc: todayIconSrc(event.today.iconKey), iconClass: event.today.iconClass, target: event.target };
}
function toNotification(event: HomeDecisionEvent): HomeSystemNotification | null {
  if (!event.notification || !event.channels.includes('notification')) return null;
  return { id: event.id, priority: event.priority, severity: event.severity, source: event.source, title: event.title, detail: event.detail, iconKey: event.notification.iconKey, iconTone: event.notification.iconTone, dotTone: event.notification.dotTone, target: event.target, task: event.task };
}

export function useHomeDecisionEngine(input: HomeDecisionEngineInput) {
  const recentOperations = useRecentFieldOperations(input.homeFieldId, 30);
  const resolvedInput = useMemo<HomeDecisionEngineInput>(() => ({ ...input, recentFieldOperations: recentOperations.operations }), [input, recentOperations.operations]);
  const cachedAnomaly = getCachedNdviAnomaly(input.homeFieldId);
  const events = useMemo(() => {
    const baseEvents = buildHomeDecisionEvents(resolvedInput); const now = input.now ?? new Date();
    const riskEvent = buildRiskRadarDecision(input.homeFieldId, input.fieldSynthesis?.riskRadar ?? null, now);
    const activeGrowth = Boolean(input.phenology?.dataStatus === 'usable' && input.phenology?.stage && input.phenology.stage !== 'unknown' && input.phenology.stage !== 'post_harvest');
    const anomalySignal = cachedAnomaly ? { ...cachedAnomaly, fieldId: String(input.homeFieldId ?? ''), status: 'ready' as const } : null;
    const anomalyEvent = buildNdviAnomalyDecision(String(input.homeFieldId ?? ''), anomalySignal, activeGrowth, now);
    let merged = baseEvents;
    if (riskEvent) { const hasSpatialAlert = Boolean(String(input.fieldSynthesis?.importantArea?.area ?? '').trim()); merged = hasSpatialAlert ? merged : merged.filter(event => !(event.group === 'pusula' && event.source === 'pusula')); }
    if (anomalyEvent) merged = merged.filter(event => event.group !== 'satellite-trend');
    return [riskEvent, anomalyEvent, ...merged].filter((event): event is HomeDecisionEvent => Boolean(event)).sort((a, b) => b.priority - a.priority);
  }, [resolvedInput, input.homeFieldId, input.fieldSynthesis, input.now, input.phenology, cachedAnomaly]);
  const todayDecisions = useMemo(() => { const selected = selectTodayEvents(events); const source = selected.length > 0 ? selected : [makeAllClearEvent(input.fieldKey)]; return source.map(toTodayDecision).filter((item): item is HomeTodayDecision => Boolean(item)); }, [events, input.fieldKey]);
  const notifications = useMemo(() => events.map(toNotification).filter((item): item is HomeSystemNotification => Boolean(item)).slice(0, 12), [events]);
  const primaryDecision = useMemo(() => events.find(event => event.channels.includes('today')) ?? events[0] ?? null, [events]);
  const pusulaDecision = useMemo(() => events.find(event => event.channels.includes('pusula')) ?? null, [events]);
  return { events, todayDecisions, notifications, primaryDecision, pusulaDecision, recentFieldOperations: recentOperations.operations, recentFieldOperationsReady: !recentOperations.loading && !recentOperations.error };
}
