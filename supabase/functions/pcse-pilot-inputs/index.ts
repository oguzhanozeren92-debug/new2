import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.112.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const REQUIRED = ['daily_weather', 'crop_parameters', 'soil_parameters', 'site_parameters', 'agromanagement'] as const;
const ARCHIVE_LAG_DAYS = 5;
const WEATHER_VALIDATION_DAYS = 7;
const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' },
  });
}

function finite(value: unknown): number | null {
  if (value === null || value === undefined || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function normalizeText(value: unknown) {
  return String(value ?? '')
    .trim()
    .toLocaleLowerCase('tr-TR')
    .replace(/\s+/g, ' ');
}

function isoDateDaysAgo(days: number) {
  return new Date(Date.now() - days * 86400000).toISOString().slice(0, 10);
}

function validIsoDate(value: unknown) {
  const text = String(value ?? '').trim();
  return ISO_DATE.test(text) && Number.isFinite(Date.parse(`${text}T00:00:00Z`));
}

function resolveLocation(field: Record<string, unknown>) {
  const latitude = finite(field.parcel_centroid_lat ?? field.latitude);
  const longitude = finite(field.parcel_centroid_lng ?? field.longitude);
  if (latitude === null || longitude === null) return null;
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) return null;
  return { latitude, longitude };
}

function resolveCropReference(rows: any[], crop: unknown) {
  const normalizedCrop = normalizeText(crop);
  if (!normalizedCrop) return null;
  return rows.find((row) => {
    if (!row?.verified) return false;
    if (normalizeText(row.crop_name) === normalizedCrop) return true;
    return Array.isArray(row.crop_aliases) && row.crop_aliases.some((alias: unknown) => normalizeText(alias) === normalizedCrop);
  }) ?? null;
}

function resolveVerifiedVarietyMapping(rows: any[], cropName: string, localVariety: unknown) {
  const normalizedVariety = normalizeText(localVariety);
  if (!normalizedVariety) return null;
  return rows.find((row) =>
    row?.verified === true &&
    String(row.crop_name ?? '') === cropName &&
    normalizeText(row.normalized_local_variety_name) === normalizedVariety
  ) ?? null;
}

function deriveCropParameters(season: any, cropReference: any, varietyMapping: any) {
  const localVarietyName = String(season?.variety_name ?? '').trim();
  if (!cropReference) {
    return {
      available: false,
      source: null,
      parameters: null,
      detail: 'Bu ürün için doğrulanmış WOFOST 7.2 ürün eşlemesi yok.',
    };
  }
  if (!localVarietyName) {
    return {
      available: false,
      source: cropReference.source_label,
      sourceReference: cropReference.source_url,
      parameters: {
        wofost_crop_key: cropReference.wofost_crop_key,
        local_variety_name: null,
        wofost_variety_key: null,
        model_family: cropReference.model_family,
        model_version: cropReference.model_version,
      },
      detail: 'Çiftçinin gerçek çeşit adı henüz kayıtlı değil; WOFOST variety seçimi yapılmadı.',
    };
  }
  if (!varietyMapping) {
    return {
      available: false,
      source: cropReference.source_label,
      sourceReference: cropReference.source_url,
      parameters: {
        wofost_crop_key: cropReference.wofost_crop_key,
        local_variety_name: localVarietyName,
        wofost_variety_key: null,
        model_family: cropReference.model_family,
        model_version: cropReference.model_version,
      },
      detail: 'Gerçek çeşit adı kayıtlı; fakat bu çeşit için doğrulanmış WOFOST variety eşlemesi henüz yok.',
    };
  }
  return {
    available: true,
    source: 'pcse_upstream',
    sourceReference: varietyMapping.source_url,
    verifiedAt: varietyMapping.updated_at ?? varietyMapping.created_at ?? null,
    parameters: {
      wofost_crop_key: varietyMapping.wofost_crop_key,
      wofost_variety_key: varietyMapping.wofost_variety_key,
      local_variety_name: localVarietyName,
      model_family: varietyMapping.model_family,
      model_version: varietyMapping.model_version,
      provider: 'PCSE YAMLCropDataProvider',
    },
    detail: 'Ürün ve model variety anahtarı doğrulanmış eşleme kaydından çözüldü; varsayılan variety seçilmedi.',
  };
}

function deriveAgromanagement(season: any, cropReference: any, varietyMapping: any) {
  const plantingDate = String(season?.planting_date ?? '').trim();
  const harvestDate = String(season?.harvest_date ?? '').trim();
  const crop = String(season?.crop ?? '').trim();

  if (!season?.id || !crop || !validIsoDate(plantingDate)) {
    return {
      available: false,
      source: 'field_seasons',
      sourceReference: season?.id ? `field_seasons:${season.id}` : null,
      parameters: null,
      detail: 'PCSE agromanagement için gerçek sezon, ürün ve ekim tarihi gerekli.',
    };
  }

  const cropName = String(cropReference?.wofost_crop_key ?? crop);
  const varietyName = varietyMapping?.wofost_variety_key ? String(varietyMapping.wofost_variety_key) : null;
  const baseCalendar = {
    local_crop_name: crop,
    local_variety_name: String(season?.variety_name ?? '').trim() || null,
    crop_name: cropName,
    variety_name: varietyName,
    crop_start_date: plantingDate,
    crop_start_type: 'sowing',
    crop_end_date: validIsoDate(harvestDate) ? harvestDate : null,
    crop_end_type: 'harvest',
  };

  if (!validIsoDate(harvestDate)) {
    return {
      available: false,
      source: 'field_seasons',
      sourceReference: `field_seasons:${season.id}`,
      parameters: {
        campaign_start_date: plantingDate,
        crop_calendar: baseCalendar,
      },
      detail: 'Ekim tarihi var; gerçek/planlanan hasat tarihi olmadığı için agromanagement tamamlanmış sayılmıyor.',
    };
  }

  if (Date.parse(`${harvestDate}T00:00:00Z`) < Date.parse(`${plantingDate}T00:00:00Z`)) {
    return {
      available: false,
      source: 'field_seasons',
      sourceReference: `field_seasons:${season.id}`,
      parameters: null,
      detail: 'Hasat tarihi ekim tarihinden önce olamaz.',
    };
  }

  return {
    available: true,
    source: 'field_seasons',
    sourceReference: `field_seasons:${season.id}`,
    verifiedAt: season.created_at ?? null,
    parameters: {
      campaign_start_date: plantingDate,
      crop_calendar: baseCalendar,
    },
    detail: 'Agromanagement gerçek TarlaPusula sezon kaydındaki ekim ve hasat tarihinden üretildi.',
  };
}

async function authenticatedClients(req: Request) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  const authorization = req.headers.get('Authorization') ?? '';
  if (!supabaseUrl || !anonKey || !serviceRoleKey || !authorization) {
    throw new Error('PCSE pilot girdileri için sunucu kimlik bilgileri veya oturum eksik.');
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) throw new Error('PCSE pilot girdileri için geçerli kullanıcı oturumu gerekli.');
  return { user: data.user, serviceClient };
}

async function validateDailyWeather(location: { latitude: number; longitude: number } | null) {
  if (!location) return { available: false, source: null, days: 0, detail: 'Tarla koordinatı eksik.' };
  const end = isoDateDaysAgo(ARCHIVE_LAG_DAYS);
  const start = isoDateDaysAgo(ARCHIVE_LAG_DAYS + WEATHER_VALIDATION_DAYS - 1);
  const url = new URL('https://archive-api.open-meteo.com/v1/archive');
  url.searchParams.set('latitude', String(location.latitude));
  url.searchParams.set('longitude', String(location.longitude));
  url.searchParams.set('start_date', start);
  url.searchParams.set('end_date', end);
  url.searchParams.set('daily', 'temperature_2m_min,temperature_2m_max,precipitation_sum,et0_fao_evapotranspiration');
  url.searchParams.set('timezone', 'UTC');
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20_000);
  try {
    const response = await fetch(url, { signal: controller.signal, headers: { 'User-Agent': 'TarlaPusula-PCSE-Pilot/1.0' } });
    const payload = await response.json().catch(() => null);
    if (!response.ok || !payload?.daily) return { available: false, source: 'Open-Meteo Archive', days: 0, detail: `Weather HTTP ${response.status}` };
    const d = payload.daily;
    const dates = Array.isArray(d.time) ? d.time : [];
    const tmin = Array.isArray(d.temperature_2m_min) ? d.temperature_2m_min : [];
    const tmax = Array.isArray(d.temperature_2m_max) ? d.temperature_2m_max : [];
    const rain = Array.isArray(d.precipitation_sum) ? d.precipitation_sum : [];
    const et0 = Array.isArray(d.et0_fao_evapotranspiration) ? d.et0_fao_evapotranspiration : [];
    const valid = dates.length === WEATHER_VALIDATION_DAYS && [tmin, tmax, rain, et0].every((a) => a.length === dates.length) && dates.every((_: string, i: number) => {
      const lo = Number(tmin[i]); const hi = Number(tmax[i]); const p = Number(rain[i]); const e = Number(et0[i]);
      return Number.isFinite(lo) && Number.isFinite(hi) && hi >= lo && Number.isFinite(p) && p >= 0 && Number.isFinite(e) && e >= 0;
    });
    return { available: valid, source: 'Open-Meteo Archive', days: valid ? dates.length : 0, start, end, detail: valid ? 'Gerçek günlük hava serisi server tarafında doğrulandı.' : 'Günlük hava serisi eksik veya geçersiz.' };
  } catch (error) {
    return { available: false, source: 'Open-Meteo Archive', days: 0, detail: error instanceof Error ? error.message : 'Weather validation failed' };
  } finally { clearTimeout(timeout); }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ ok: false, error: 'Yalnız POST desteklenir.' }, 405);
  try {
    const body = await req.json().catch(() => ({}));
    const fieldId = String(body?.field_id ?? '').trim();
    if (!fieldId) return json({ ok: false, error: 'field_id gerekli.' }, 400);
    const { user, serviceClient } = await authenticatedClients(req);

    const { data: field, error: fieldError } = await serviceClient
      .from('fields')
      .select('id,user_id,crop,season,latitude,longitude,parcel_centroid_lat,parcel_centroid_lng')
      .eq('id', fieldId)
      .eq('user_id', user.id)
      .maybeSingle();
    if (fieldError) throw fieldError;
    if (!field) return json({ ok: false, error: 'Tarla bulunamadı veya bu kullanıcıya ait değil.' }, 404);

    const [seasonResult, paramsResult, cropRefsResult, varietyMappingsResult, weather] = await Promise.all([
      serviceClient
        .from('field_seasons')
        .select('id,year,crop,variety_name,planting_date,harvest_date,created_at')
        .eq('user_id', user.id)
        .eq('field_id', fieldId)
        .order('year', { ascending: false })
        .limit(1)
        .maybeSingle(),
      serviceClient
        .from('field_pcse_parameter_sets')
        .select('id,parameter_kind,parameters,source,source_reference,verified_at,updated_at')
        .eq('user_id', user.id)
        .eq('field_id', fieldId),
      serviceClient
        .from('pcse_crop_reference_mappings')
        .select('crop_name,crop_aliases,wofost_crop_key,model_family,model_version,source_label,source_url,verified'),
      serviceClient
        .from('pcse_variety_mappings')
        .select('crop_name,local_variety_name,normalized_local_variety_name,wofost_crop_key,wofost_variety_key,model_family,model_version,source_label,source_url,verified,created_at,updated_at')
        .eq('verified', true),
      validateDailyWeather(resolveLocation(field as Record<string, unknown>)),
    ]);

    for (const result of [seasonResult, paramsResult, cropRefsResult, varietyMappingsResult]) {
      if (result.error) throw result.error;
    }

    const season = seasonResult.data;
    const cropIdentity = season?.crop ?? field.crop ?? null;
    const cropReference = resolveCropReference(Array.isArray(cropRefsResult.data) ? cropRefsResult.data : [], cropIdentity);
    const varietyMapping = cropReference
      ? resolveVerifiedVarietyMapping(
          Array.isArray(varietyMappingsResult.data) ? varietyMappingsResult.data : [],
          String(cropReference.crop_name),
          season?.variety_name,
        )
      : null;

    const records = Array.isArray(paramsResult.data) ? paramsResult.data : [];
    const byKind = new Map(records.map((row: any) => [String(row.parameter_kind), row]));
    const availableInputs: string[] = [];
    if (weather.available) availableInputs.push('daily_weather');

    const adapters: Record<string, unknown> = { daily_weather: weather };
    const derivedCropParameters = deriveCropParameters(season, cropReference, varietyMapping);
    const derivedAgromanagement = deriveAgromanagement(season, cropReference, varietyMapping);

    for (const kind of ['crop_parameters', 'soil_parameters', 'site_parameters', 'agromanagement']) {
      const row = byKind.get(kind) as any;
      const validObject = row?.parameters && typeof row.parameters === 'object' && !Array.isArray(row.parameters) && Object.keys(row.parameters).length > 0;

      if (validObject) {
        availableInputs.push(kind);
        adapters[kind] = {
          available: true,
          source: row.source,
          sourceReference: row.source_reference ?? null,
          verifiedAt: row.verified_at,
          parameters: row.parameters,
        };
        continue;
      }

      if (kind === 'crop_parameters') {
        if (derivedCropParameters.available) availableInputs.push('crop_parameters');
        adapters.crop_parameters = derivedCropParameters;
        continue;
      }

      if (kind === 'agromanagement') {
        if (derivedAgromanagement.available) availableInputs.push('agromanagement');
        adapters.agromanagement = derivedAgromanagement;
        continue;
      }

      adapters[kind] = {
        available: false,
        source: null,
        parameters: null,
        detail: `${kind} için doğrulanmış gerçek PCSE parametre kaydı yok.`,
      };
    }

    const missingInputs = REQUIRED.filter((key) => !availableInputs.includes(key));
    return json({
      ok: true,
      engine: 'pcse',
      mode: 'pilot-input-adapter',
      field_id: fieldId,
      rollout: 'pilot',
      production_authority: false,
      input_authority: 'server-derived',
      client_supplied_agricultural_values_accepted: false,
      ready: missingInputs.length === 0,
      available_inputs: availableInputs,
      missing_inputs: missingInputs,
      adapters,
      context: {
        season_id: season?.id ?? null,
        crop_identity: cropIdentity,
        farmer_variety_name: season?.variety_name ?? null,
        wofost_crop_key: cropReference?.wofost_crop_key ?? null,
        wofost_variety_key: varietyMapping?.wofost_variety_key ?? null,
        planting_date: season?.planting_date ?? null,
        harvest_date: season?.harvest_date ?? null,
        season_year: season?.year ?? field.season ?? null,
      },
      note: missingInputs.length === 0
        ? 'PCSE/WOFOST pilot girdileri doğrulanmış server-side kaynaklarla hazır.'
        : 'Eksik PCSE/WOFOST girdileri için sentetik veya varsayılan variety üretilmedi; pilot bloklu kalır.',
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'PCSE pilot input hazırlığı başarısız oldu.';
    console.error('[pcse-pilot-inputs]', message);
    const status = /oturum|kullanıcı/i.test(message) ? 401 : 500;
    return json({ ok: false, error: message, production_authority: false }, status);
  }
});
