import { createClient } from 'npm:@supabase/supabase-js@2';
import { createR2DownloadUrl } from '../_shared/r2.ts';

const NVIDIA_API_URL = 'https://integrate.api.nvidia.com/v1/chat/completions';
const PUSULA_VISION_MODEL = 'meta/muse-glimmer-30b';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type AccessRow = {
  allowed: boolean;
  usage_id: number | null;
  access_source: string | null;
  plan: string;
  daily_free_used: boolean;
  free_remaining: number;
  reward_credits: number;
  unlimited: boolean;
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

const accessPayload = (row: AccessRow | null) =>
  row
    ? {
        plan: row.plan,
        dailyFreeUsed: row.daily_free_used,
        freeRemaining: row.free_remaining,
        rewardCredits: row.reward_credits,
        unlimited: row.unlimited,
      }
    : null;

function cleanJson(raw: string) {
  let content = raw
    .trim()
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/\s*```$/, '')
    .trim();
  const first = content.indexOf('{');
  const last = content.lastIndexOf('}');
  if (first >= 0 && last > first) content = content.slice(first, last + 1);
  return content;
}

function normalizeAnalysis(value: any) {
  const statuses = new Set(['normal', 'attention', 'urgent', 'uncertain']);
  const types = new Set([
    'disease',
    'pest',
    'nutrition',
    'environmental',
    'physical',
    'uncertain',
  ]);

  return {
    status: statuses.has(value?.status) ? value.status : 'uncertain',
    issueType: types.has(value?.issueType) ? value.issueType : 'uncertain',
    headline:
      typeof value?.headline === 'string'
        ? value.headline.slice(0, 180)
        : 'Fotoğraf için ön değerlendirme',
    possibleIssue:
      typeof value?.possibleIssue === 'string'
        ? value.possibleIssue.slice(0, 250)
        : 'Belirsiz',
    confidence: Math.max(
      0,
      Math.min(100, Number.isFinite(Number(value?.confidence)) ? Number(value.confidence) : 0),
    ),
    observations: Array.isArray(value?.observations)
      ? value.observations.filter((x: unknown) => typeof x === 'string').slice(0, 5)
      : [],
    recommendations: Array.isArray(value?.recommendations)
      ? value.recommendations.filter((x: unknown) => typeof x === 'string').slice(0, 5)
      : [],
    followUpPhoto:
      typeof value?.followUpPhoto === 'string' ? value.followUpPhoto.slice(0, 240) : '',
    disclaimer:
      typeof value?.disclaimer === 'string'
        ? value.disclaimer.slice(0, 350)
        : 'Bu sonuç fotoğraf ve kayıtlı tarla bağlamına dayalı bir ön değerlendirmedir; kesin teşhis değildir.',
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Sadece POST isteği kullanılabilir.' }, 405);

  const url = Deno.env.get('SUPABASE_URL');
  const anon = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const nvidiaKey = Deno.env.get('NVIDIA_API_KEY');

  if (!url || !anon || !serviceRole || !nvidiaKey) {
    return json(
      {
        error: 'Pusula AI sunucu yapılandırması eksik.',
        userMessage: 'Pusula AI şu anda kullanılamıyor. Analiz hakkın kullanılmadı.',
      },
      500,
    );
  }

  const authorization = req.headers.get('Authorization') ?? '';
  const token = authorization.replace(/^Bearer\s+/i, '').trim();
  if (!token) return json({ error: 'Oturum gerekli.' }, 401);

  const userClient = createClient(url, anon, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const admin = createClient(url, serviceRole, { auth: { persistSession: false } });

  const { data: userData, error: userError } = await userClient.auth.getUser(token);
  if (userError || !userData.user) return json({ error: 'Geçersiz oturum.' }, 401);

  const userId = userData.user.id;
  let jobId = '';

  try {
    const body = await req.json();
    jobId = String(body?.jobId ?? '').trim();
    if (!jobId) return json({ error: 'jobId gerekli.' }, 400);

    const { data: job, error: jobError } = await admin
      .from('ai_image_analysis_jobs')
      .select(
        'id,user_id,field_id,storage_provider,storage_path,mime_type,notes,crop,field_name,status,attempt_count,climate_context,task_type,analysis,access_usage_id',
      )
      .eq('id', jobId)
      .eq('user_id', userId)
      .maybeSingle();

    if (jobError) throw jobError;
    if (!job) return json({ error: 'Analiz işi bulunamadı.' }, 404);
    if (job.status === 'completed' && job.analysis) {
      return json({ analysis: job.analysis, modelUsed: PUSULA_VISION_MODEL, reused: true });
    }
    if (job.status === 'processing') {
      return json(
        { error: 'Analiz zaten işleniyor.', userMessage: 'Pusula AI fotoğrafı zaten inceliyor.' },
        409,
      );
    }
    if (job.storage_provider !== 'cloudflare_r2') {
      throw new Error('Bu analiz işi Cloudflare R2 dosyasına bağlı değil.');
    }

    const { data: fileRow, error: fileError } = await admin
      .from('app_files')
      .select('id,object_key,status,mime_type')
      .eq('user_id', userId)
      .eq('object_key', String(job.storage_path))
      .eq('status', 'ready')
      .maybeSingle();
    if (fileError) throw fileError;
    if (!fileRow) throw new Error('Analiz fotoğrafı bulunamadı veya henüz yüklenmedi.');

    const { data: checkData, error: checkError } = await userClient.rpc('check_ai_access');
    if (checkError) throw checkError;
    const checked = (Array.isArray(checkData) ? checkData[0] : checkData) as AccessRow | null;

    if (!checked?.allowed) {
      await admin
        .from('ai_image_analysis_jobs')
        .update({
          status: 'failed',
          error_message: 'AI kullanım hakkı bulunmuyor.',
          updated_at: new Date().toISOString(),
        })
        .eq('id', jobId)
        .eq('user_id', userId);
      return json({
        limitReached: true,
        message: 'Bugünkü ücretsiz AI analiz hakkını kullandın.',
        access: accessPayload(checked),
      });
    }

    const startedAt = new Date().toISOString();
    const { error: startError } = await admin
      .from('ai_image_analysis_jobs')
      .update({
        status: 'processing',
        started_at: startedAt,
        attempt_count: Number(job.attempt_count ?? 0) + 1,
        error_message: null,
        updated_at: startedAt,
      })
      .eq('id', jobId)
      .eq('user_id', userId);
    if (startError) throw startError;

    const signedImageUrl = await createR2DownloadUrl(String(job.storage_path), 300);
    const climate =
      job.climate_context && typeof job.climate_context === 'object' ? job.climate_context : null;

    const prompt = `Sen TarlaPusula uygulamasındaki Pusula AI Görsel Teşhis Motorusun. Tarımsal bitki/ağaç fotoğrafında hastalık ve zararlı belirtilerini ön değerlendir. Tarla: ${job.field_name || 'Bilinmiyor'}. Ürün: ${job.crop || 'Bilinmiyor'}. Not: ${job.notes || 'Yok'}. Bağlam: ${climate ? JSON.stringify(climate) : 'Yok'}. Yalnız görünür kanıta dayan; hastalık, zararlı, beslenme, çevresel stres ve fiziksel hasarı ayır; kesin teşhis uydurma; yetersizse uncertain kullan; bağlamı yalnız destekleyici kullan; doz/reçete verme; gerekirse followUpPhoto ile ek fotoğraf iste. Türkçe ve kısa yaz. Sadece JSON döndür: {"status":"normal|attention|urgent|uncertain","issueType":"disease|pest|nutrition|environmental|physical|uncertain","headline":"kısa sonuç","possibleIssue":"en olası sorun veya Belirsiz","confidence":0,"observations":["görsel kanıt"],"recommendations":["güvenli sonraki adım"],"followUpPhoto":"ek fotoğraf veya boş string","disclaimer":"kısa uyarı"}`;

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 90000);
    let providerResponse: Response;

    try {
      providerResponse = await fetch(NVIDIA_API_URL, {
        method: 'POST',
        signal: controller.signal,
        headers: {
          Authorization: `Bearer ${nvidiaKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: PUSULA_VISION_MODEL,
          messages: [
            {
              role: 'user',
              content: [
                { type: 'text', text: prompt },
                { type: 'image_url', image_url: { url: signedImageUrl } },
              ],
            },
          ],
          temperature: 0.2,
          top_p: 0.9,
          max_tokens: 1000,
          stream: false,
        }),
      });
    } finally {
      clearTimeout(timer);
    }

    if (!providerResponse.ok) {
      const providerText = await providerResponse.text();
      throw new Error(
        `Pusula Vision sağlayıcısı ${providerResponse.status}: ${providerText.slice(0, 500)}`,
      );
    }

    const providerData = await providerResponse.json();
    const raw = providerData?.choices?.[0]?.message?.content;
    if (!raw || typeof raw !== 'string') throw new Error('Pusula Vision boş sonuç döndürdü.');

    let parsed: any;
    try {
      parsed = JSON.parse(cleanJson(raw));
    } catch {
      throw new Error('Pusula Vision sonucu işlenemedi.');
    }

    const analysis = normalizeAnalysis(parsed);
    if (!analysis.headline || analysis.observations.length === 0) {
      throw new Error('Pusula Vision yeterli analiz kanıtı üretmedi.');
    }

    const { data: consumeData, error: consumeError } = await userClient.rpc('consume_ai_access');
    if (consumeError) throw consumeError;
    const consumed = (Array.isArray(consumeData) ? consumeData[0] : consumeData) as AccessRow | null;

    if (!consumed?.allowed) {
      await admin
        .from('ai_image_analysis_jobs')
        .update({
          status: 'failed',
          error_message: 'Analiz tamamlandı ancak kullanım hakkı eşzamanlı olarak tükendi.',
          updated_at: new Date().toISOString(),
        })
        .eq('id', jobId)
        .eq('user_id', userId);
      return json({
        limitReached: true,
        message: 'Bu sırada kullanılabilir AI analiz hakkın kalmadı. Analiz kaydedilmedi.',
        access: accessPayload(consumed),
      });
    }

    const completedAt = new Date().toISOString();
    const { error: completeError } = await admin
      .from('ai_image_analysis_jobs')
      .update({
        status: 'completed',
        analysis,
        provider: 'nvidia',
        model: PUSULA_VISION_MODEL,
        access_usage_id: consumed.usage_id,
        completed_at: completedAt,
        updated_at: completedAt,
        error_message: null,
      })
      .eq('id', jobId)
      .eq('user_id', userId);

    if (completeError) {
      if (consumed.usage_id) {
        await userClient.rpc('refund_ai_access', { p_usage_id: consumed.usage_id });
      }
      throw completeError;
    }

    return json({ analysis, modelUsed: PUSULA_VISION_MODEL, access: accessPayload(consumed) });
  } catch (error) {
    console.error('Pusula Vision analysis error', error);
    if (jobId) {
      await admin
        .from('ai_image_analysis_jobs')
        .update({
          status: 'failed',
          error_message: error instanceof Error ? error.message.slice(0, 1000) : 'Bilinmeyen hata',
          updated_at: new Date().toISOString(),
        })
        .eq('id', jobId)
        .eq('user_id', userId);
    }

    return json({
      error: error instanceof Error ? error.message : 'Pusula AI analizi tamamlanamadı.',
      userMessage:
        'Pusula AI fotoğrafı şu anda analiz edemedi. Analiz hakkın kullanılmadı; aynı fotoğrafla tekrar deneyebilirsin.',
    });
  }
});
