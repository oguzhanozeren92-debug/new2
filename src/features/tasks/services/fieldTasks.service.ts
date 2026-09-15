import { supabase } from '../../../supabaseClient';

export type FieldTask = {
  id: string;
  fieldId: string;
  title: string;
  description: string | null;
  source: string;
  actionTarget: string | null;
  priority: number;
  rewardPoints: number;
  dueDate: string | null;
  taskKey: string | null;
  metadata: Record<string, unknown>;
  completed: boolean;
  createdAt: string | null;
};

type RawFieldTask = {
  id?: unknown;
  field_id?: unknown;
  title?: unknown;
  description?: unknown;
  source?: unknown;
  action_target?: unknown;
  priority?: unknown;
  reward_rule_key?: unknown;
  metadata?: unknown;
  due_date?: unknown;
  task_key?: unknown;
  completed?: unknown;
  created_at?: unknown;
};

function text(value: unknown) {
  return String(value ?? '').trim();
}

function metadataObject(metadata: unknown): Record<string, unknown> {
  if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) {
    return {};
  }

  return metadata as Record<string, unknown>;
}

function rewardPoints(metadata: unknown) {
  const value = Number(metadataObject(metadata).rewardPoints ?? 0);
  return Number.isFinite(value) ? Math.max(0, Math.round(value)) : 0;
}

function normalizeTask(row: RawFieldTask): FieldTask {
  return {
    id: text(row.id),
    fieldId: text(row.field_id),
    title: text(row.title) || 'Görev',
    description: text(row.description) || null,
    source: text(row.source) || 'user',
    actionTarget: text(row.action_target) || null,
    priority: Number.isFinite(Number(row.priority)) ? Number(row.priority) : 0,
    rewardPoints: rewardPoints(row.metadata),
    dueDate: text(row.due_date) || null,
    taskKey: text(row.task_key) || null,
    metadata: metadataObject(row.metadata),
    completed: Boolean(row.completed),
    createdAt: text(row.created_at) || null,
  };
}

function emitTasksChanged(fieldId: string) {
  if (typeof window === 'undefined') return;
  window.dispatchEvent(
    new CustomEvent('tp:tasks-changed', {
      detail: { fieldId },
    }),
  );
}

async function synchronizeGeneratedTasks(fieldId: string) {
  if (!supabase) {
    throw new Error('Supabase bağlantısı hazır değil.');
  }

  const results = await Promise.allSettled([
    supabase.rpc('tp_sync_field_tasks', { p_field_id: fieldId }),
    supabase.rpc('tp_sync_model_readiness_tasks', { p_field_id: fieldId }),
    supabase.rpc('tp_sync_growth_stage_observation_task', { p_field_id: fieldId }),
    supabase.rpc('tp_sync_irrigation_amount_task', { p_field_id: fieldId }),
    supabase.rpc('tp_refresh_action_tasks', { p_field_id: fieldId }),
  ]);

  for (const result of results) {
    if (result.status === 'fulfilled' && result.value?.error) {
      console.warn('[tasks] Görev senkronizasyonu:', result.value.error.message);
    }
  }
}

export async function getFieldTasks(fieldId: string): Promise<FieldTask[]> {
  const id = text(fieldId);
  if (!id) return [];
  if (!supabase) {
    throw new Error('Supabase bağlantısı hazır değil.');
  }

  await synchronizeGeneratedTasks(id);

  const { data, error } = await supabase
    .from('field_todos')
    .select(
      'id,field_id,title,description,source,action_target,priority,reward_rule_key,metadata,due_date,task_key,completed,created_at',
    )
    .eq('field_id', id)
    .eq('completed', false)
    .eq('dismissed', false)
    .order('priority', { ascending: false })
    .order('created_at', { ascending: true });

  if (error) throw error;
  return (data ?? []).map((row) => normalizeTask(row as RawFieldTask));
}

export async function dismissFieldTask(task: FieldTask) {
  if (!supabase) {
    throw new Error('Supabase bağlantısı hazır değil.');
  }

  const taskId = text(task.id);
  if (!taskId) throw new Error('Görev kimliği bulunamadı.');

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError) throw userError;
  if (!user) throw new Error('Görevi ertelemek için oturum gerekli.');

  const { data, error } = await supabase
    .from('field_todos')
    .update({
      dismissed: true,
      updated_at: new Date().toISOString(),
    })
    .eq('id', taskId)
    .eq('user_id', user.id)
    .select('id,field_id')
    .maybeSingle();

  if (error) throw error;
  if (!data) throw new Error('Görev bulunamadı veya güncellenemedi.');

  emitTasksChanged(text(data.field_id) || task.fieldId);

  return {
    dismissed: true,
    message: 'Şimdilik gizledim. İlgili veriyi daha sonra yine ekleyebilirsin.',
  };
}

export async function completeFieldTask(task: FieldTask) {
  if (!supabase) {
    throw new Error('Supabase bağlantısı hazır değil.');
  }

  if (task.taskKey) {
    const actionTask =
      task.taskKey === 'notification:soil-analysis' ||
      task.taskKey.startsWith('pusula-field-check:');

    const { data, error } = await supabase.rpc(
      actionTask ? 'tp_complete_action_task' : 'tp_complete_field_task',
      { p_task_id: task.id },
    );

    if (error) throw error;

    const result = Array.isArray(data) ? data[0] : data;
    const completed = Boolean((result as any)?.completed);

    if (!completed) {
      return {
        completed: false,
        message:
          (result as any)?.reason === 'completion_not_verified'
            ? 'Bu görev, ilgili bilgiyi gerçekten tamamladığında otomatik kapanacak.'
            : 'Görev henüz tamamlanmış görünmüyor.',
      };
    }

    emitTasksChanged(task.fieldId);

    return {
      completed: true,
      awardedPoints: Number((result as any)?.awarded_points ?? 0),
      message: Number((result as any)?.awarded_points ?? 0) > 0
        ? `+${Number((result as any)?.awarded_points ?? 0)} Pusula kazandın.`
        : 'Görev tamamlandı.',
    };
  }

  const { error } = await supabase
    .from('field_todos')
    .update({
      completed: true,
      completed_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', task.id);

  if (error) throw error;

  emitTasksChanged(task.fieldId);

  return {
    completed: true,
    awardedPoints: 0,
    message: 'Görev tamamlandı.',
  };
}
