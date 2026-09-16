alter table public.ai_image_analysis_jobs
  add column if not exists climate_context jsonb,
  add column if not exists task_type text not null default 'disease_pest_diagnosis';

alter table public.ai_image_analysis_jobs
  drop constraint if exists ai_image_analysis_jobs_task_type_check;
alter table public.ai_image_analysis_jobs
  add constraint ai_image_analysis_jobs_task_type_check
  check (task_type in ('disease_pest_diagnosis','field_observation','pusula_lens'));

drop policy if exists "Users can update own ai image analysis jobs" on public.ai_image_analysis_jobs;
drop policy if exists "authenticated can update own ai image analysis jobs" on public.ai_image_analysis_jobs;
revoke update on table public.ai_image_analysis_jobs from authenticated;
grant select, insert on table public.ai_image_analysis_jobs to authenticated;

create unique index if not exists ai_image_analysis_jobs_one_active_per_user_idx
  on public.ai_image_analysis_jobs(user_id)
  where status in ('pending','processing');
