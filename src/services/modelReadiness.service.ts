import {
  supabase,
} from '../supabaseClient';

export type ModelEngine =
  | 'pyfao56'
  | 'pcse'
  | 'aquacrop';

export type ModelReadinessRefreshResult = {
  ok: boolean;
  engine: ModelEngine;
  fieldId: string;
  ready: boolean | null;
  missingInputs: string[];
  error: string | null;
};

export async function refreshModelReadiness(
  fieldId: string,
  engine: ModelEngine,
): Promise<ModelReadinessRefreshResult> {
  const normalizedFieldId = String(fieldId ?? '').trim();
  if (!normalizedFieldId) {
    return {
      ok: false,
      engine,
      fieldId: normalizedFieldId,
      ready: null,
      missingInputs: [],
      error: 'Model readiness için tarla kimliği gerekli.',
    };
  }

  try {
    const {
      data,
      error,
    } = await supabase.functions.invoke(
      'model-engine-readiness',
      {
        body: {
          engine,
          field_id: normalizedFieldId,
        },
      },
    );

    if (error) throw error;
    if (!data?.ok) {
      throw new Error(
        String(
          data?.error ??
          'Model readiness yenilenemedi.',
        ),
      );
    }

    return {
      ok: true,
      engine,
      fieldId: normalizedFieldId,
      ready:
        typeof data.ready === 'boolean'
          ? data.ready
          : null,
      missingInputs:
        Array.isArray(data.missing_inputs)
          ? data.missing_inputs.map(String)
          : [],
      error: null,
    };
  } catch (error) {
    return {
      ok: false,
      engine,
      fieldId: normalizedFieldId,
      ready: null,
      missingInputs: [],
      error:
        error instanceof Error
          ? error.message
          : 'Model readiness yenilenemedi.',
    };
  }
}

export function refreshPyFao56ReadinessBestEffort(
  fieldId: string,
) {
  void refreshModelReadiness(
    fieldId,
    'pyfao56',
  ).then((result) => {
    if (!result.ok) {
      console.warn(
        '[model-readiness] pyfao56 refresh failed',
        result.error,
      );
    }
  });
}
