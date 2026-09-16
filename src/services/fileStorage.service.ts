import { supabase } from '../supabaseClient';

export type AppFileCategory =
  | 'soil-report'
  | 'soil-analysis-pdf'
  | 'field-observation-photo'
  | 'field-activity-photo'
  | 'pesticide-label-photo'
  | 'warehouse-photo'
  | 'report'
  | 'user-document'
  | string;

export type AppFileRecord = {
  id: string;
  user_id: string;
  field_id: string | null;
  provider: 'cloudflare_r2';
  bucket: string;
  object_key: string;
  category: string;
  original_name: string;
  mime_type: string;
  size_bytes: number;
  status: 'pending' | 'ready' | 'failed' | 'deleted';
  metadata?: Record<string, unknown>;
  uploaded_at?: string | null;
  deleted_at?: string | null;
  created_at: string;
  updated_at: string;
};

type UploadOptions = {
  category: AppFileCategory;
  fieldId?: string | null;
};

async function invokeStorage<T>(body: Record<string, unknown>): Promise<T> {
  const { data, error } = await supabase.functions.invoke('r2-files', { body });
  if (error) throw new Error(error.message || 'Dosya servisine ulaşılamadı.');
  if (data?.error) throw new Error(String(data.error));
  return data as T;
}

export async function uploadAppFile(
  file: File,
  options: UploadOptions,
): Promise<AppFileRecord> {
  if (!file) throw new Error('Yüklenecek dosya bulunamadı.');

  const ticket = await invokeStorage<{
    file: AppFileRecord;
    uploadUrl: string;
    requiredHeaders?: Record<string, string>;
  }>({
    action: 'create-upload',
    category: options.category,
    fieldId: options.fieldId ?? null,
    fileName: file.name,
    mimeType: file.type || 'application/octet-stream',
    sizeBytes: file.size,
  });

  try {
    const uploadResponse = await fetch(ticket.uploadUrl, {
      method: 'PUT',
      headers: {
        'Content-Type': file.type,
        ...(ticket.requiredHeaders ?? {}),
      },
      body: file,
    });

    if (!uploadResponse.ok) {
      throw new Error(`R2 yükleme hatası (${uploadResponse.status}).`);
    }

    const completed = await invokeStorage<{ file: AppFileRecord }>({
      action: 'complete-upload',
      fileId: ticket.file.id,
    });

    return completed.file;
  } catch (error) {
    // Pending kayıt sunucuda kalır; R2 lifecycle/temizlik görevi ile güvenle temizlenebilir.
    throw error;
  }
}

export async function getAppFileUrl(objectKey: string): Promise<string> {
  const key = String(objectKey ?? '').trim();
  if (!key) throw new Error('Dosya yolu bulunamadı.');

  const data = await invokeStorage<{ signedUrl: string }>({
    action: 'read',
    objectKey: key,
  });

  if (!data.signedUrl) throw new Error('Dosya bağlantısı oluşturulamadı.');
  return data.signedUrl;
}

export async function getAppFileUrls(
  objectKeys: string[],
): Promise<Map<string, string>> {
  const keys = [...new Set(objectKeys.map((key) => String(key ?? '').trim()).filter(Boolean))];
  if (!keys.length) return new Map();

  const data = await invokeStorage<{
    files: Array<{ object_key: string; signedUrl: string }>;
  }>({
    action: 'read-many',
    objectKeys: keys,
  });

  return new Map(
    (data.files ?? [])
      .filter((file) => file.object_key && file.signedUrl)
      .map((file) => [file.object_key, file.signedUrl]),
  );
}

export async function deleteAppFile(objectKey: string): Promise<void> {
  const key = String(objectKey ?? '').trim();
  if (!key) return;

  await invokeStorage({
    action: 'delete',
    objectKey: key,
  });
}
