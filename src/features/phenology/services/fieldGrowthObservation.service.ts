import {
  supabase,
} from '../../../supabaseClient';

import type {
  CreateFieldGrowthObservationInput,
  FieldGrowthObservation,
} from '../types/fieldGrowthObservation';

const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

const CANONICAL_STAGES = new Set([
  'pre_sowing',
  'establishment',
  'vegetative',
  'reproductive',
  'maturation',
  'harvest_window',
  'post_harvest',
  'dormancy',
  'bud_swell',
  'bud_break',
  'flowering',
  'fruit_set',
  'fruit_growth',
  'veraison',
  'leaf_fall',
]);

function mapRow(row: any): FieldGrowthObservation {
  return {
    id: String(row.id),
    fieldId: String(row.field_id),
    seasonId: String(row.season_id),
    observedOn: String(row.observed_on),
    stage: row.stage,
    notes: row.notes == null ? null : String(row.notes),
    createdAt: String(row.created_at),
  };
}

function validateInput(input: CreateFieldGrowthObservationInput) {
  const fieldId = String(input.fieldId ?? '').trim();
  const seasonId = String(input.seasonId ?? '').trim();
  const observedOn = String(input.observedOn ?? '').trim();
  const stage = String(input.stage ?? '').trim();
  const notes = String(input.notes ?? '').trim();

  if (!fieldId) throw new Error('Gelişim gözlemi için tarla kimliği gerekli.');
  if (!seasonId) throw new Error('Gelişim gözlemi için sezon kimliği gerekli.');
  if (!DATE_PATTERN.test(observedOn) || !Number.isFinite(Date.parse(`${observedOn}T00:00:00Z`))) {
    throw new Error('Gelişim gözlemi tarihi YYYY-MM-DD biçiminde olmalı.');
  }
  if (!CANONICAL_STAGES.has(stage)) {
    throw new Error('Gelişim gözlemi yalnız tanımlı fenoloji evrelerinden biri olabilir.');
  }
  if (notes.length > 500) {
    throw new Error('Gelişim gözlemi notu 500 karakteri geçemez.');
  }

  return {
    fieldId,
    seasonId,
    observedOn,
    stage,
    notes: notes || null,
  };
}

export async function recordFieldGrowthObservation(
  input: CreateFieldGrowthObservationInput,
): Promise<FieldGrowthObservation> {
  const validated = validateInput(input);

  const {
    data: userResult,
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) throw userError;
  const user = userResult.user;
  if (!user) throw new Error('Gelişim gözlemi kaydı için oturum gerekli.');

  const {
    data: season,
    error: seasonError,
  } = await supabase
    .from('field_seasons')
    .select('id,field_id,user_id')
    .eq('id', validated.seasonId)
    .eq('field_id', validated.fieldId)
    .eq('user_id', user.id)
    .maybeSingle();

  if (seasonError) throw seasonError;
  if (!season) {
    throw new Error('Sezon bu tarlaya ait değil veya erişim yok.');
  }

  const {
    data,
    error,
  } = await supabase
    .from('field_growth_observations')
    .insert({
      user_id: user.id,
      field_id: validated.fieldId,
      season_id: validated.seasonId,
      observed_on: validated.observedOn,
      stage: validated.stage,
      notes: validated.notes,
    })
    .select('id,field_id,season_id,observed_on,stage,notes,created_at')
    .single();

  if (error) {
    if (error.code === '23505') {
      throw new Error('Bu sezon, tarih ve gelişim evresi için gözlem zaten kayıtlı.');
    }
    throw error;
  }

  return mapRow(data);
}

export async function listFieldGrowthObservations(
  fieldId: string,
  limit = 30,
): Promise<FieldGrowthObservation[]> {
  const normalizedFieldId = String(fieldId ?? '').trim();
  if (!normalizedFieldId) throw new Error('Gelişim gözlemleri için tarla kimliği gerekli.');

  const safeLimit = Math.max(1, Math.min(100, Math.floor(limit)));
  const {
    data,
    error,
  } = await supabase
    .from('field_growth_observations')
    .select('id,field_id,season_id,observed_on,stage,notes,created_at')
    .eq('field_id', normalizedFieldId)
    .order('observed_on', { ascending: false })
    .order('created_at', { ascending: false })
    .limit(safeLimit);

  if (error) throw error;
  return (Array.isArray(data) ? data : []).map(mapRow);
}

export async function deleteFieldGrowthObservation(
  observationId: string,
) {
  const id = String(observationId ?? '').trim();
  if (!id) throw new Error('Silinecek gelişim gözlemi kimliği gerekli.');

  const { error } = await supabase
    .from('field_growth_observations')
    .delete()
    .eq('id', id);

  if (error) throw error;
}
