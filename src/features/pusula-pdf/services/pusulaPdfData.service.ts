import { supabase } from '../../../supabaseClient';
import { fetchHistoricalSatellite, listSatelliteDates } from '../../map-data/services/satelliteHistory';
import type { PusulaPdfSatellitePoint, PusulaPdfSnapshot, WeeklyPusulaReport } from '../types';

const FIELD_COLUMNS = ['id','name','city','district','village','area_decare','crop','crop_subtype','season','irrigation_status','irrigation_method','parcel_geometry','latitude','longitude','parcel_centroid_lat','parcel_centroid_lng'].join(',');
const isoDate = (d: Date) => d.toISOString().slice(0, 10);
const num = (v: unknown) => v === null || v === undefined || v === '' || !Number.isFinite(Number(v)) ? null : Number(v);

export function getWeeklyReportPeriod(now = new Date()) {
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const day = d.getUTCDay(); d.setUTCDate(d.getUTCDate() + (day === 0 ? -6 : 1 - day));
  const end = new Date(d); end.setUTCDate(d.getUTCDate() + 6);
  return { start: isoDate(d), end: isoDate(end) };
}

async function user() {
  const { data, error } = await supabase.auth.getUser(); if (error) throw error;
  if (!data.user) throw new Error('PUSULAPDF için oturum bulunamadı.'); return data.user;
}

async function rows(table: string, fieldId: string, order = 'created_at') {
  const { data, error } = await supabase.from(table).select('*').eq('field_id', fieldId).order(order, { ascending: false });
  if (error) { console.warn(`[PUSULAPDF] ${table}:`, error.message); return []; } return data ?? [];
}

function indexValue(r: any, key: string) {
  for (const v of [r?.[`${key}Average`], r?.[`${key}Avg`], r?.[key], r?.indices?.[key]?.average, r?.indices?.[key]?.avg, r?.indexValues?.[key], r?.statistics?.[key]?.mean]) {
    const n = num(v); if (n !== null) return n;
  } return null;
}

async function satellite(geometry: unknown) {
  if (!geometry) return { points: [] as PusulaPdfSatellitePoint[], availableDates: [] as string[] };
  const all = await listSatelliteDates(geometry); const cutoff = new Date(); cutoff.setUTCDate(cutoff.getUTCDate() - 30);
  const dates = all.filter(d => new Date(`${d}T00:00:00Z`) >= cutoff).slice(0, 8); const points: PusulaPdfSatellitePoint[] = [];
  for (const date of dates) try {
    const r: any = await fetchHistoricalSatellite(geometry, date);
    points.push({ date, ndvi:indexValue(r,'ndvi'), ndmi:indexValue(r,'ndmi'), ndre:indexValue(r,'ndre'), savi:indexValue(r,'savi'), gndvi:indexValue(r,'gndvi'), ndviImage:typeof r?.ndviImage==='string'?r.ndviImage:null, trueColorImage:typeof r?.trueColorImage==='string'?r.trueColorImage:null });
  } catch (e) { console.warn('[PUSULAPDF] Uydu:', date, e); }
  return { points: points.sort((a,b)=>a.date.localeCompare(b.date)), availableDates: all };
}

async function weather(field: any) {
  const lat=num(field.parcel_centroid_lat ?? field.latitude), lng=num(field.parcel_centroid_lng ?? field.longitude); if(lat===null||lng===null)return null;
  const { data,error }=await supabase.from('weather_cache').select('payload,provider_count,updated_at,latitude,longitude').gte('latitude',lat-.03).lte('latitude',lat+.03).gte('longitude',lng-.03).lte('longitude',lng+.03).order('updated_at',{ascending:false}).limit(1).maybeSingle();
  if(error){console.warn('[PUSULAPDF] Hava:',error.message);return null;} return data??null;
}

export async function buildPusulaPdfSnapshot(fieldIdInput:string):Promise<PusulaPdfSnapshot>{
  const fieldId=String(fieldIdInput??'').trim(); if(!fieldId)throw new Error('Tarla seçilmedi.'); const u=await user();
  const {data:field,error}=await supabase.from('fields').select(FIELD_COLUMNS).eq('id',fieldId).eq('user_id',u.id).single(); if(error)throw error;
  const period=getWeeklyReportPeriod();
  const [sat,w,activities,soil,diagnoses,kc]=await Promise.all([satellite(field.parcel_geometry).catch(()=>({points:[],availableDates:[]})),weather(field),rows('activities',fieldId,'activity_date'),rows('soil_analyses',fieldId),rows('ai_diagnosis_sessions',fieldId,'updated_at'),rows('field_irrigation_kc_snapshots',fieldId,'snapshot_date')]);
  const missing:string[]=[]; if(!field.parcel_geometry)missing.push('parcel_geometry'); if(!sat.points.length)missing.push('satellite_30d'); if(!w)missing.push('weather'); if(!activities.length)missing.push('activities'); if(!soil.length)missing.push('soil_analysis'); if(!diagnoses.some((d:any)=>d.status==='resolved'))missing.push('resolved_diagnosis'); if(!kc.length)missing.push('irrigation_kc');
  return {schemaVersion:1,field:{id:String(field.id),name:field.name??'Tarla',city:field.city??null,district:field.district??null,village:field.village??null,areaDecare:num(field.area_decare),crop:field.crop??null,cropSubtype:field.crop_subtype??null,season:num(field.season),irrigationStatus:field.irrigation_status??null,irrigationMethod:field.irrigation_method??null,geometry:field.parcel_geometry??null,latitude:num(field.parcel_centroid_lat??field.latitude),longitude:num(field.parcel_centroid_lng??field.longitude)},period:{start:period.start,end:period.end,createdAt:new Date().toISOString()},satellite:sat,weather:w,irrigation:{kcSnapshots:kc},activities,soilAnalyses:soil,diagnoses:diagnoses.filter((d:any)=>d.status==='resolved'),missing};
}

export async function getOrCreateWeeklyPusulaReport(fieldId:string):Promise<WeeklyPusulaReport>{
  const u=await user(), p=getWeeklyReportPeriod();
  const {data:old,error:oldError}=await supabase.from('weekly_field_reports').select('*').eq('user_id',u.id).eq('field_id',fieldId).eq('period_start',p.start).maybeSingle(); if(oldError)throw oldError; if(old)return old as WeeklyPusulaReport;
  const snapshot=await buildPusulaPdfSnapshot(fieldId); const {data,error}=await supabase.from('weekly_field_reports').insert({user_id:u.id,field_id:fieldId,period_start:p.start,period_end:p.end,status:'snapshot',report_data:snapshot}).select('*').single();
  if(error){if((error as any).code==='23505'){const {data:raced,error:e}=await supabase.from('weekly_field_reports').select('*').eq('user_id',u.id).eq('field_id',fieldId).eq('period_start',p.start).single();if(e)throw e;return raced as WeeklyPusulaReport;}throw error;} return data as WeeklyPusulaReport;
}
