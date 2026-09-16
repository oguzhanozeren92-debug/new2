create table if not exists public.app_files (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  field_id uuid references public.fields(id) on delete cascade,
  provider text not null default 'cloudflare_r2' check (provider in ('cloudflare_r2')),
  bucket text not null,
  object_key text not null,
  category text not null,
  original_name text not null,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes >= 0),
  status text not null default 'pending' check (status in ('pending', 'ready', 'failed', 'deleted')),
  metadata jsonb not null default '{}'::jsonb,
  uploaded_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (bucket, object_key)
);

create index if not exists app_files_user_created_idx
  on public.app_files(user_id, created_at desc);

create index if not exists app_files_user_field_idx
  on public.app_files(user_id, field_id, created_at desc)
  where field_id is not null;

create index if not exists app_files_user_category_idx
  on public.app_files(user_id, category, created_at desc);

alter table public.app_files enable row level security;

-- The client can only list/read its own metadata. All mutations go through
-- the authenticated r2-files Edge Function, which uses the service role only
-- on the server and scopes every operation to the authenticated user id.
create policy "authenticated can select own app files"
  on public.app_files
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all on table public.app_files from anon, authenticated;
grant select on table public.app_files to authenticated;

alter table public.ai_image_analysis_jobs
  add column if not exists storage_provider text not null default 'cloudflare_r2';

alter table public.ai_image_analysis_jobs
  drop constraint if exists ai_image_analysis_jobs_storage_provider_check;

alter table public.ai_image_analysis_jobs
  add constraint ai_image_analysis_jobs_storage_provider_check
  check (storage_provider in ('cloudflare_r2'));
