create or replace function public.check_ai_access()
returns table(allowed boolean, usage_id bigint, access_source text, plan text, daily_free_used boolean, free_remaining integer, reward_credits integer, unlimited boolean)
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user uuid := auth.uid();
  v_plan text;
  v_date date := (now() at time zone 'Europe/Istanbul')::date;
  v_free_used boolean := false;
  v_credits integer := 0;
begin
  if v_user is null then raise exception 'Not authenticated'; end if;
  select coalesce(p.subscription_plan, 'free') into v_plan from public.profiles p where p.id = v_user;
  v_plan := coalesce(v_plan, 'free');
  if v_plan <> 'free' then
    return query select true, null::bigint, 'paid'::text, v_plan, false, 1, 0, true;
    return;
  end if;
  select exists(select 1 from public.ai_usage u where u.user_id = v_user and u.usage_date = v_date and u.access_source = 'daily_free') into v_free_used;
  select coalesce(c.balance, 0) into v_credits from public.ai_reward_credits c where c.user_id = v_user;
  v_credits := coalesce(v_credits, 0);
  if not v_free_used then
    return query select true, null::bigint, 'daily_free'::text, v_plan, false, 1, v_credits, false;
  elsif v_credits > 0 then
    return query select true, null::bigint, 'rewarded_ad'::text, v_plan, true, 0, v_credits, false;
  else
    return query select false, null::bigint, null::text, v_plan, true, 0, v_credits, false;
  end if;
end;
$$;

revoke all on function public.check_ai_access() from public, anon;
grant execute on function public.check_ai_access() to authenticated;
