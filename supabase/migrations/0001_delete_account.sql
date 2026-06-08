-- 회원 탈퇴 RPC.  앱에서 supabase.rpc('delete_account') 로 호출.
-- 현재 로그인 사용자(auth.uid())의 소유 데이터 + auth 계정을 삭제한다.
--
-- ⚠️ 적용: Supabase 대시보드 → SQL Editor 에 아래 전체를 붙여넣고 Run.
--    (스키마 실측: events/user_data/theme_subscribers/theme_contributed_events/
--     user_backups 는 user_id, theme_shares 는 created_by 로 소유 판별)

create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;

  delete from public.events                   where user_id = uid;
  delete from public.user_data                where user_id = uid;
  delete from public.theme_subscribers        where user_id = uid;
  delete from public.theme_contributed_events where user_id = uid;
  delete from public.user_backups             where user_id = uid;
  delete from public.theme_shares             where created_by = uid;

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
