import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.112.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const ENGINE_CONFIG = {
  pyfao56: {
    adapter: 'pyfao56-water-balance-inputs',
    rollout: 'shadow',
    required: ['validated_basal_kcb', 'surface_evaporation_layer', 'current_soil_water_state'],
  },
  pcse: {
    adapter: 'pcse-pilot-inputs',
    rollout: 'pilot',
    required: ['daily_weather', 'crop_parameters', 'soil_parameters', 'site_parameters', 'agromanagement'],
  },
  aquacrop: {
    adapter: 'aquacrop-pilot-inputs',
    rollout: 'pilot',
    required: ['crop_parameters', 'soil_profile', 'initial_water_content', 'irrigation_management'],
  },
} as const;

type Engine = keyof typeof ENGINE_CONFIG;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  });
}

function presentFinite(value: unknown) {
  return value !== null && value !== undefined && value !== '' && Number.isFinite(Number(value));
}

async function authenticatedClients(req: Request) {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  const authorization = req.headers.get('Authorization') ?? '';

  if (!supabaseUrl || !anonKey || !serviceRoleKey || !authorization) {
    throw new Error('Model readiness için sunucu kimlik bilgileri veya kullanıcı oturumu eksik.');
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) throw new Error('Model readiness için geçerli kullanıcı oturumu gerekli.');

  return { user: data.user, serviceClient, supabaseUrl, anonKey, authorization };
}

async function callAdapter(
  supabaseUrl: string,
  anonKey: string,
  authorization: string,
  slug: string,
  fieldId: string,
) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 75_000);
  try {
    const response = await fetch(`${supabaseUrl}/functions/v1/${slug}`, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        Authorization: authorization,
        apikey: anonKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ field_id: fieldId }),
    });
    const payload = await response.json().catch(() => null);
    if (!response.ok || !payload || payload.ok === false) {
      const failure = new Error(String(payload?.error ?? `${slug} HTTP ${response.status}`));
      (failure as any).status = response.status;
      throw failure;
    }
    if (payload.production_authority !== false || payload.input_authority !== 'server-derived') {
      throw new Error(`${slug} trust boundary doğrulanamadı.`);
    }
    return payload;
  } finally {
    clearTimeout(timeout);
  }
}

function normalizeStandardAdapter(engine: 'pcse' | 'aquacrop', payload: any) {
  const required = [...ENGINE_CONFIG[engine].required] as string[];
  const adapterAvailable = new Set(
    Array.isArray(payload?.available_inputs) ? payload.available_inputs.map(String) : [],
  );
  const availableInputs = required.filter((key) => adapterAvailable.has(key));
  const missingInputs = required.filter((key) => !adapterAvailable.has(key));
  return {
    availableInputs,
    missingInputs,
    evidence: payload?.adapters ?? {},
    context: payload?.context ?? {},
    adapterMissingInputs: Array.isArray(payload?.missing_inputs)
      ? payload.missing_inputs.map(String)
      : [],
  };
}

function normalizePyFao56(payload: any, irrigationBalance: any) {
  const required = [...ENGINE_CONFIG.pyfao56.required] as string[];
  const availableInputs: string[] = [];

  if (payload?.basal_kcb?.status === 'validated') {
    availableInputs.push('validated_basal_kcb');
  }

  const measuredCurrentState =
    presentFinite(payload?.root_zone?.current_water_vol) &&
    presentFinite(payload?.root_zone?.current_depletion_mm);

  const estimatedCurrentState =
    irrigationBalance?.ready === true &&
    irrigationBalance?.status === 'estimated' &&
    presentFinite(irrigationBalance?.root_zone?.current_depletion_mm) &&
    presentFinite(irrigationBalance?.root_zone?.total_available_water_mm);

  if (measuredCurrentState || estimatedCurrentState) {
    availableInputs.push('current_soil_water_state');
  }

  if (
    presentFinite(payload?.surface_evaporation?.tew_mm) &&
    presentFinite(payload?.surface_evaporation?.de_mm) &&
    presentFinite(payload?.surface_evaporation?.rew_mm)
  ) {
    availableInputs.push('surface_evaporation_layer');
  }

  const missingInputs = required.filter((key) => !availableInputs.includes(key));
  return {
    availableInputs,
    missingInputs,
    evidence: {
      basal_kcb: payload?.basal_kcb ?? null,
      root_zone_measurement: payload?.root_zone ?? null,
      root_zone_water_balance: irrigationBalance ?? null,
      current_soil_water_state_source: measuredCurrentState
        ? 'field_water_measurements'
        : estimatedCurrentState
          ? 'irrigation-water-balance-state'
          : null,
      surface_evaporation: payload?.surface_evaporation ?? null,
      soil_profile: payload?.soil_profile ?? null,
    },
    context: {
      field: payload?.field ?? irrigationBalance?.field ?? null,
      adapter_full_water_balance_ready: Boolean(payload?.full_water_balance_ready),
      estimated_water_balance_ready: Boolean(estimatedCurrentState),
      estimated_water_balance_confidence: estimatedCurrentState
        ? irrigationBalance?.confidence ?? null
        : null,
    },
    adapterMissingInputs: [
      ...(Array.isArray(payload?.missing_inputs) ? payload.missing_inputs.map(String) : []),
      ...(Array.isArray(irrigationBalance?.missing_inputs) ? irrigationBalance.missing_inputs.map(String) : []),
    ],
  };
}

async function persistSnapshot(serviceClient: any, values: Record<string, unknown>) {
  const { error } = await serviceClient
    .from('model_engine_readiness_snapshots')
    .upsert(values, { onConflict: 'user_id,field_id,engine' });
  if (error) {
    console.warn('[model-engine-readiness] snapshot persistence failed', error.message);
    return false;
  }
  return true;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ ok: false, error: 'Yalnız POST desteklenir.' }, 405);

  try {
    const body = await req.json().catch(() => ({}));
    const engine = String(body?.engine ?? '').trim() as Engine;
    const fieldId = String(body?.field_id ?? body?.payload?.field_id ?? '').trim();

    if (!(engine in ENGINE_CONFIG)) {
      return json({ ok: false, error: 'Yalnız pyfao56, pcse veya aquacrop readiness desteklenir.' }, 400);
    }
    if (!fieldId) return json({ ok: false, error: 'field_id gerekli.' }, 400);

    if (
      'available_inputs' in body || 'missing_inputs' in body ||
      'latitude' in body || 'longitude' in body || 'crop' in body ||
      'parameters' in body
    ) {
      return json({
        ok: false,
        error: 'Readiness girdileri istemciden kabul edilmez; kanıtlar sunucu adapterlarından üretilir.',
      }, 400);
    }

    const { user, serviceClient, supabaseUrl, anonKey, authorization } = await authenticatedClients(req);
    const config = ENGINE_CONFIG[engine];

    let adapterPayload: any;
    let irrigationBalance: any = null;

    if (engine === 'pyfao56') {
      const [pyfaoResult, balanceResult] = await Promise.allSettled([
        callAdapter(supabaseUrl, anonKey, authorization, config.adapter, fieldId),
        callAdapter(supabaseUrl, anonKey, authorization, 'irrigation-water-balance-state', fieldId),
      ]);

      if (pyfaoResult.status === 'rejected') throw pyfaoResult.reason;
      adapterPayload = pyfaoResult.value;
      irrigationBalance = balanceResult.status === 'fulfilled'
        ? balanceResult.value
        : {
            ok: true,
            ready: false,
            status: 'unavailable',
            production_authority: false,
            input_authority: 'server-derived',
            missing_inputs: ['irrigation_water_balance_unavailable'],
          };
    } else {
      adapterPayload = await callAdapter(
        supabaseUrl,
        anonKey,
        authorization,
        config.adapter,
        fieldId,
      );
    }

    const normalized = engine === 'pyfao56'
      ? normalizePyFao56(adapterPayload, irrigationBalance)
      : normalizeStandardAdapter(engine, adapterPayload);

    const ready = normalized.missingInputs.length === 0;
    const checkedAt = new Date().toISOString();
    const snapshotPersisted = await persistSnapshot(serviceClient, {
      user_id: user.id,
      field_id: fieldId,
      engine,
      rollout: config.rollout,
      ready,
      available_inputs: normalized.availableInputs,
      missing_inputs: normalized.missingInputs,
      evidence: normalized.evidence,
      context: {
        ...normalized.context,
        adapter: config.adapter,
        adapter_missing_inputs: normalized.adapterMissingInputs,
      },
      input_authority: 'server-derived',
      checked_at: checkedAt,
    });

    return json({
      ok: true,
      engine,
      field_id: fieldId,
      ready,
      available_inputs: normalized.availableInputs,
      missing_inputs: normalized.missingInputs,
      evidence: normalized.evidence,
      context: normalized.context,
      adapter_missing_inputs: normalized.adapterMissingInputs,
      adapter: config.adapter,
      rollout: config.rollout,
      production_authority: false,
      input_authority: 'server-derived',
      client_supplied_available_inputs_ignored: true,
      checked_at: checkedAt,
      snapshot_persisted: snapshotPersisted,
      note: ready
        ? 'Motor girdileri ilgili server-side adapter sözleşmesini karşılıyor; rollout seviyesi yine production otoritesi değildir.'
        : 'Eksik girdiler sentetik değerle doldurulmadı; motor rollout kapısı açıkça bloklu kalır.',
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Model readiness isteği başarısız oldu.';
    console.error('[model-engine-readiness]', message);
    const explicitStatus = Number((error as any)?.status);
    const status = Number.isFinite(explicitStatus) && explicitStatus >= 400 && explicitStatus < 600
      ? explicitStatus
      : /oturum|kullanıcı/i.test(message)
        ? 401
        : 500;
    return json({ ok: false, error: message }, status);
  }
});
