import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.112.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

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

function finite(value: unknown): number | null {
  if (value === null || value === undefined || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function round(value: number, digits = 3) {
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}

function normalizeText(value: unknown) {
  return String(value ?? '')
    .trim()
    .toLocaleLowerCase('tr-TR')
    .replace(/\s+/g, ' ');
}

function normalizeSubtype(value: unknown): 'table' | 'wine' | null {
  const normalized = normalizeText(value);
  if (['table', 'sofralık', 'sofralik'].includes(normalized)) return 'table';
  if (['wine', 'şaraplık', 'saraplik'].includes(normalized)) return 'wine';
  return null;
}

function resolveReferenceProfile(profiles: any[], crop: unknown, subtype: unknown) {
  const normalizedCrop = normalizeText(crop);
  if (!normalizedCrop) return null;
  const normalizedSubtype = normalizeSubtype(subtype);
  const candidates = profiles.filter((profile) => {
    if (normalizeText(profile.display_name) === normalizedCrop) return true;
    return Array.isArray(profile.aliases) &&
      profile.aliases.some((alias: unknown) => normalizeText(alias) === normalizedCrop);
  });
  if (!candidates.length) return null;

  const grape = ['üzüm', 'uzum', 'grape', 'grapes'].includes(normalizedCrop);
  if (grape) {
    if (!normalizedSubtype) return null;
    return candidates.find((profile) => profile.crop_subtype === normalizedSubtype) ?? null;
  }
  return candidates.find((profile) => profile.crop_subtype == null) ?? candidates[0] ?? null;
}

type StageResolution = {
  mode: 'initial' | 'mid' | 'end' | 'initial_to_mid' | 'mid_to_end';
  weight: number;
};

function resolveStage(stage: unknown): StageResolution | null {
  switch (normalizeText(stage)) {
    case 'dormancy':
    case 'pre_sowing':
      return { mode: 'initial', weight: 0 };
    case 'bud_swell':
    case 'bud_break':
    case 'establishment':
      return { mode: 'initial_to_mid', weight: 0.30 };
    case 'flowering':
      return { mode: 'initial_to_mid', weight: 0.55 };
    case 'fruit_set':
    case 'reproductive':
      return { mode: 'initial_to_mid', weight: 0.80 };
    case 'vegetative':
    case 'fruit_growth':
    case 'veraison':
      return { mode: 'mid', weight: 1 };
    case 'maturation':
      return { mode: 'mid_to_end', weight: 0.50 };
    case 'harvest_window':
      return { mode: 'mid_to_end', weight: 0.85 };
    case 'leaf_fall':
    case 'post_harvest':
      return { mode: 'end', weight: 1 };
    default:
      return null;
  }
}

function interpolateKcb(profile: any, stage: StageResolution | null) {
  if (!profile || !stage) return null;
  const initial = finite(profile.kcb_initial);
  const mid = finite(profile.kcb_mid);
  const end = finite(profile.kcb_end);
  if (initial === null || mid === null || end === null) return null;

  switch (stage.mode) {
    case 'initial': return initial;
    case 'mid': return mid;
    case 'end': return end;
    case 'initial_to_mid': return initial + (mid - initial) * stage.weight;
    case 'mid_to_end': return mid + (end - mid) * stage.weight;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ ok: false, error: 'Yalnız POST desteklenir.' }, 405);

  try {
    const authorization = req.headers.get('Authorization') ?? '';
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    if (!authorization || !supabaseUrl || !anonKey || !serviceRoleKey) {
      return json({ ok: false, error: 'Sunucu kimlik bilgileri veya oturum eksik.' }, 401);
    }

    const body = await req.json().catch(() => ({}));
    const fieldId = String(body?.field_id ?? '').trim();
    if (!fieldId) return json({ ok: false, error: 'field_id gerekli.' }, 400);
    if (['crop', 'crop_subtype', 'stage', 'kcb'].some((key) => key in body)) {
      return json({ ok: false, error: 'Kcb girdileri istemciden kabul edilmez.' }, 400);
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: authData, error: authError } = await userClient.auth.getUser();
    if (authError || !authData.user) return json({ ok: false, error: 'Geçerli kullanıcı oturumu gerekli.' }, 401);

    const { data: field, error: fieldError } = await serviceClient
      .from('fields')
      .select('id,user_id,crop,crop_subtype')
      .eq('id', fieldId)
      .eq('user_id', authData.user.id)
      .maybeSingle();
    if (fieldError) throw fieldError;
    if (!field) return json({ ok: false, error: 'Tarla bulunamadı veya kullanıcıya ait değil.' }, 404);

    const [profilesResult, snapshotResult, observationResult] = await Promise.all([
      serviceClient
        .from('crop_water_reference_profiles')
        .select('crop_key,display_name,crop_subtype,aliases,kcb_initial,kcb_mid,kcb_end,kcb_source_label,kcb_source_url,reference_version'),
      serviceClient
        .from('field_irrigation_kc_snapshots')
        .select('snapshot_date,phenology_stage,stage_label,coefficient_confidence,source_label,calculated_at')
        .eq('field_id', fieldId)
        .eq('user_id', authData.user.id)
        .order('snapshot_date', { ascending: false })
        .order('calculated_at', { ascending: false })
        .limit(1)
        .maybeSingle(),
      serviceClient
        .from('field_growth_observations')
        .select('id,season_id,observed_on,stage,notes,created_at')
        .eq('field_id', fieldId)
        .eq('user_id', authData.user.id)
        .order('observed_on', { ascending: false })
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle(),
    ]);

    for (const result of [profilesResult, snapshotResult, observationResult]) {
      if (result.error) throw result.error;
    }

    const profile = resolveReferenceProfile(
      Array.isArray(profilesResult.data) ? profilesResult.data : [],
      field.crop,
      field.crop_subtype,
    );
    const snapshot = snapshotResult.data;
    const observation = observationResult.data;
    const stageResolution = resolveStage(snapshot?.phenology_stage);
    const kcb = interpolateKcb(profile, stageResolution);

    const sameDay = Boolean(
      snapshot?.snapshot_date &&
      observation?.observed_on &&
      String(snapshot.snapshot_date) === String(observation.observed_on),
    );
    const sameStage = Boolean(
      snapshot?.phenology_stage &&
      observation?.stage &&
      normalizeText(snapshot.phenology_stage) === normalizeText(observation.stage),
    );
    const observedStageIsCanonical = resolveStage(observation?.stage) !== null;
    const validated = Boolean(
      profile && kcb !== null && sameDay && sameStage && observedStageIsCanonical,
    );

    const missingInputs: string[] = [];
    if (!profile) missingInputs.push('fao56_basal_kcb_reference');
    if (!snapshot || !stageResolution || kcb === null) missingInputs.push('current_phenology_stage');
    if (!observation) missingInputs.push('same_day_field_growth_observation');
    else {
      if (!sameDay) missingInputs.push('same_day_field_growth_observation');
      if (!observedStageIsCanonical) missingInputs.push('canonical_field_growth_stage');
      if (!sameStage) missingInputs.push('field_observation_stage_match');
    }

    return json({
      ok: true,
      field_id: fieldId,
      production_authority: false,
      input_authority: 'server-derived',
      status: validated
        ? 'validated'
        : kcb !== null
          ? 'shadow_candidate'
          : 'blocked',
      validated,
      crop_key: profile?.crop_key ?? null,
      kcb: kcb === null ? null : round(kcb, 3),
      reference_profile: profile ? {
        initial: Number(profile.kcb_initial),
        mid: Number(profile.kcb_mid),
        end: Number(profile.kcb_end),
      } : null,
      phenology: snapshot ? {
        stage: snapshot.phenology_stage ?? null,
        stage_label: snapshot.stage_label ?? null,
        snapshot_date: snapshot.snapshot_date ?? null,
        coefficient_confidence: snapshot.coefficient_confidence ?? null,
        source: snapshot.source_label ?? null,
      } : null,
      field_observation: observation ? {
        id: observation.id,
        observed_on: observation.observed_on,
        stage: observation.stage,
        same_day_as_snapshot: sameDay,
        same_stage_as_snapshot: sameStage,
        canonical_stage: observedStageIsCanonical,
      } : null,
      source: profile ? {
        label: profile.kcb_source_label,
        url: profile.kcb_source_url,
        reference_version: profile.reference_version,
      } : null,
      missing_inputs: [...new Set(missingInputs)],
      validation_rule: 'FAO-56 basal Kcb reference + same-day canonical field growth observation matching the current phenology snapshot.',
      caution: validated
        ? 'Kcb girdisi saha gözlemiyle doğrulandı; model yine shadow rollout seviyesindedir ve production sulama otoritesi değildir.'
        : 'Otomatik/orta güvenli fenoloji tek başına basal Kcb doğrulaması sayılmaz.',
      generated_at: new Date().toISOString(),
    });
  } catch (error) {
    console.error('[pyfao56-kcb-context]', error);
    return json({
      ok: false,
      error: error instanceof Error ? error.message : 'PyFAO56 Kcb bağlamı hazırlanamadı.',
      production_authority: false,
    }, 500);
  }
});
