import { createClient } from 'npm:@supabase/supabase-js@2';
import {
  createR2DownloadUrl,
  createR2UploadUrl,
  deleteR2Object,
  getR2Config,
  headR2Object,
} from '../_shared/r2.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const MAX_IMAGE_BYTES = 15 * 1024 * 1024;
const MAX_PDF_BYTES = 20 * 1024 * 1024;
const MAX_BATCH = 50;
const allowedMimeTypes = new Set([
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function safeFileName(value: string) {
  const cleaned = value
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(-100);
  return cleaned || 'file';
}

function safeCategory(value: unknown) {
  const category = String(value ?? '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9-]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 50);
  return category || 'generic';
}

function validateFile(mimeType: string, sizeBytes: number) {
  if (!allowedMimeTypes.has(mimeType)) {
    throw new Error('Bu dosya türü desteklenmiyor. PDF, JPG, PNG, WebP, HEIC veya HEIF kullan.');
  }

  if (!Number.isFinite(sizeBytes) || sizeBytes <= 0) {
    throw new Error('Dosya boyutu geçersiz.');
  }

  const limit = mimeType === 'application/pdf' ? MAX_PDF_BYTES : MAX_IMAGE_BYTES;
  if (sizeBytes > limit) {
    throw new Error(
      mimeType === 'application/pdf'
        ? 'PDF en fazla 20 MB olabilir.'
        : 'Fotoğraf en fazla 15 MB olabilir.',
    );
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return json({ error: 'Sadece POST isteği kullanılabilir.' }, 405);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  const authorization = req.headers.get('Authorization') ?? '';
  const token = authorization.replace(/^Bearer\s+/i, '').trim();

  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: 'Supabase sunucu yapılandırması eksik.' }, 500);
  }
  if (!token) return json({ error: 'Oturum gerekli.' }, 401);

  // Service role never leaves this server-side Edge Function. The caller is
  // authenticated first and every metadata query is explicitly user-scoped.
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userError } = await admin.auth.getUser(token);
  if (userError || !userData.user) {
    return json({ error: 'Geçersiz oturum.' }, 401);
  }

  const userId = userData.user.id;

  try {
    const body = await req.json().catch(() => ({}));
    const action = String(body?.action ?? '').trim();
    const { bucket } = getR2Config();

    if (action === 'create-upload') {
      const fieldId = body?.fieldId ? String(body.fieldId).trim() : null;
      const originalName = String(body?.fileName ?? '').trim();
      const mimeType = String(body?.mimeType ?? '').trim().toLowerCase();
      const sizeBytes = Number(body?.sizeBytes);
      const category = safeCategory(body?.category);

      if (!originalName) throw new Error('Dosya adı gerekli.');
      validateFile(mimeType, sizeBytes);

      if (fieldId) {
        const { data: field, error: fieldError } = await admin
          .from('fields')
          .select('id')
          .eq('id', fieldId)
          .eq('user_id', userId)
          .maybeSingle();
        if (fieldError) throw fieldError;
        if (!field) throw new Error('Bu tarlaya dosya ekleme yetkin yok.');
      }

      const objectKey = [
        'users',
        userId,
        fieldId ? `fields/${fieldId}` : 'account',
        category,
        `${crypto.randomUUID()}-${safeFileName(originalName)}`,
      ].join('/');

      const { data: fileRow, error: insertError } = await admin
        .from('app_files')
        .insert({
          user_id: userId,
          field_id: fieldId,
          provider: 'cloudflare_r2',
          bucket,
          object_key: objectKey,
          category,
          original_name: originalName,
          mime_type: mimeType,
          size_bytes: sizeBytes,
          status: 'pending',
        })
        .select('*')
        .single();

      if (insertError) throw insertError;

      try {
        const uploadUrl = await createR2UploadUrl(objectKey, mimeType, 600);
        return json({
          file: fileRow,
          uploadUrl,
          requiredHeaders: { 'Content-Type': mimeType },
          expiresIn: 600,
        });
      } catch (error) {
        await admin
          .from('app_files')
          .update({ status: 'failed', updated_at: new Date().toISOString() })
          .eq('id', fileRow.id)
          .eq('user_id', userId);
        throw error;
      }
    }

    if (action === 'complete-upload') {
      const fileId = String(body?.fileId ?? '').trim();
      if (!fileId) throw new Error('fileId gerekli.');

      const { data: fileRow, error: readError } = await admin
        .from('app_files')
        .select('*')
        .eq('id', fileId)
        .eq('user_id', userId)
        .maybeSingle();
      if (readError) throw readError;
      if (!fileRow) throw new Error('Dosya kaydı bulunamadı.');

      const head = await headR2Object(fileRow.object_key);
      const actualSize = Number(head.ContentLength ?? 0);
      if (actualSize <= 0) throw new Error('R2 yüklemesi doğrulanamadı.');
      if (actualSize !== Number(fileRow.size_bytes)) {
        await deleteR2Object(fileRow.object_key).catch(() => undefined);
        await admin
          .from('app_files')
          .update({ status: 'failed', updated_at: new Date().toISOString() })
          .eq('id', fileId)
          .eq('user_id', userId);
        throw new Error('Yüklenen dosyanın boyutu beklenen değerle uyuşmuyor.');
      }

      const now = new Date().toISOString();
      const { data: ready, error: updateError } = await admin
        .from('app_files')
        .update({ status: 'ready', uploaded_at: now, updated_at: now })
        .eq('id', fileId)
        .eq('user_id', userId)
        .select('*')
        .single();
      if (updateError) throw updateError;
      return json({ file: ready });
    }

    if (action === 'read') {
      const objectKey = String(body?.objectKey ?? '').trim();
      if (!objectKey) throw new Error('objectKey gerekli.');

      const { data: fileRow, error: readError } = await admin
        .from('app_files')
        .select('id,object_key,mime_type,original_name,status')
        .eq('user_id', userId)
        .eq('object_key', objectKey)
        .eq('status', 'ready')
        .maybeSingle();
      if (readError) throw readError;
      if (!fileRow) throw new Error('Dosya bulunamadı veya erişim yetkin yok.');

      const signedUrl = await createR2DownloadUrl(fileRow.object_key, 900);
      return json({ file: fileRow, signedUrl, expiresIn: 900 });
    }

    if (action === 'read-many') {
      const objectKeys = Array.isArray(body?.objectKeys)
        ? [...new Set(body.objectKeys.map((value: unknown) => String(value ?? '').trim()).filter(Boolean))]
        : [];
      if (!objectKeys.length) return json({ files: [] });
      if (objectKeys.length > MAX_BATCH) throw new Error(`Tek istekte en fazla ${MAX_BATCH} dosya açılabilir.`);

      const { data: rows, error: readError } = await admin
        .from('app_files')
        .select('id,object_key,mime_type,original_name,status')
        .eq('user_id', userId)
        .eq('status', 'ready')
        .in('object_key', objectKeys);
      if (readError) throw readError;

      const files = await Promise.all(
        (rows ?? []).map(async (row: any) => ({
          ...row,
          signedUrl: await createR2DownloadUrl(row.object_key, 900),
        })),
      );
      return json({ files, expiresIn: 900 });
    }

    if (action === 'delete') {
      const objectKey = String(body?.objectKey ?? '').trim();
      if (!objectKey) throw new Error('objectKey gerekli.');

      const { data: fileRow, error: readError } = await admin
        .from('app_files')
        .select('id,object_key,status')
        .eq('user_id', userId)
        .eq('object_key', objectKey)
        .maybeSingle();
      if (readError) throw readError;
      if (!fileRow) throw new Error('Dosya bulunamadı veya erişim yetkin yok.');

      await deleteR2Object(fileRow.object_key);
      const now = new Date().toISOString();
      const { error: updateError } = await admin
        .from('app_files')
        .update({ status: 'deleted', deleted_at: now, updated_at: now })
        .eq('id', fileRow.id)
        .eq('user_id', userId);
      if (updateError) throw updateError;
      return json({ success: true });
    }

    return json({ error: 'Geçersiz dosya işlemi.' }, 400);
  } catch (error) {
    console.error('r2-files error', error);
    return json(
      { error: error instanceof Error ? error.message : 'Dosya işlemi tamamlanamadı.' },
      400,
    );
  }
});
