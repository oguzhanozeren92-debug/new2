create table if not exists public.ai_image_analysis_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  field_id uuid not null references public.fields(id) on delete cascade,
  storage_bucket text not null default 'field-activity-photos',
  storage_path text not null,
  mime_type text not null default 'image/jpeg',
  notes text,
  crop text,
  field_name text,
  status text not null default 'pending' check (status in ('pending','processing','completed','failed')),
  attempt_count integer not null default 0,
  analysis jsonb,
  provider text,
  model text,
  error_message text,
  access_usage_id bigint references public.ai_usage(id) on delete set null,
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists ai_image_analysis_jobs_user_created_idx on public.ai_image_analysis_jobs(user_id, created_at desc);
create index if not exists ai_image_analysis_jobs_status_created_idx on public.ai_image_analysis_jobs(status, created_at);
create index if not exists ai_image_analysis_jobs_field_created_idx on public.ai_image_analysis_jobs(field_id, created_at desc);

alter table public.ai_image_analysis_jobs enable row level security;

create policy "authenticated can select own ai image analysis jobs" on public.ai_image_analysis_jobs for select to authenticated using ((select auth.uid()) = user_id);
create policy "authenticated can insert own ai image analysis jobs" on public.ai_image_analysis_jobs for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "authenticated can update own ai image analysis jobs" on public.ai_image_analysis_jobs for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

revoke all on table public.ai_image_analysis_jobs from anon;
grant select, insert, update on table public.ai_image_analysis_jobs to authenticated;
