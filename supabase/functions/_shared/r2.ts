import {
  DeleteObjectCommand,
  GetObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
} from 'npm:@aws-sdk/client-s3@3';
import { getSignedUrl } from 'npm:@aws-sdk/s3-request-presigner@3';

type R2Config = {
  accountId: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucket: string;
};

let cachedClient: S3Client | null = null;
let cachedConfig: R2Config | null = null;

export function getR2Config(): R2Config {
  if (cachedConfig) return cachedConfig;

  const accountId = Deno.env.get('R2_ACCOUNT_ID')?.trim() ?? '';
  const accessKeyId = Deno.env.get('R2_ACCESS_KEY_ID')?.trim() ?? '';
  const secretAccessKey = Deno.env.get('R2_SECRET_ACCESS_KEY')?.trim() ?? '';
  const bucket = Deno.env.get('R2_BUCKET')?.trim() ?? '';

  if (!accountId || !accessKeyId || !secretAccessKey || !bucket) {
    throw new Error('Cloudflare R2 sunucu yapılandırması eksik.');
  }

  cachedConfig = { accountId, accessKeyId, secretAccessKey, bucket };
  return cachedConfig;
}

export function getR2Client() {
  if (cachedClient) return cachedClient;

  const config = getR2Config();
  cachedClient = new S3Client({
    region: 'auto',
    endpoint: `https://${config.accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
    },
  });

  return cachedClient;
}

export async function createR2UploadUrl(
  objectKey: string,
  contentType: string,
  expiresIn = 600,
) {
  const { bucket } = getR2Config();
  return await getSignedUrl(
    getR2Client(),
    new PutObjectCommand({
      Bucket: bucket,
      Key: objectKey,
      ContentType: contentType,
    }),
    { expiresIn },
  );
}

export async function createR2DownloadUrl(
  objectKey: string,
  expiresIn = 900,
) {
  const { bucket } = getR2Config();
  return await getSignedUrl(
    getR2Client(),
    new GetObjectCommand({ Bucket: bucket, Key: objectKey }),
    { expiresIn },
  );
}

export async function headR2Object(objectKey: string) {
  const { bucket } = getR2Config();
  return await getR2Client().send(
    new HeadObjectCommand({ Bucket: bucket, Key: objectKey }),
  );
}

export async function getR2Object(objectKey: string) {
  const { bucket } = getR2Config();
  return await getR2Client().send(
    new GetObjectCommand({ Bucket: bucket, Key: objectKey }),
  );
}

export async function deleteR2Object(objectKey: string) {
  const { bucket } = getR2Config();
  await getR2Client().send(
    new DeleteObjectCommand({ Bucket: bucket, Key: objectKey }),
  );
}

export async function r2BodyToUint8Array(body: unknown) {
  const stream = body as { transformToByteArray?: () => Promise<Uint8Array> } | null;
  if (!stream?.transformToByteArray) {
    throw new Error('R2 dosya gövdesi okunamadı.');
  }
  return await stream.transformToByteArray();
}
