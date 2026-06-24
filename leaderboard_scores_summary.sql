create or replace view public.leaderboard_scores_summary
with (security_invoker = true)
as
select
  l.user_id,
  u.full_name,
  u.role,
  u.avatar_url,
  coalesce(
    sum(l.points) filter (
      where l.created_at >= now() - interval '7 days'
    ),
    0
  )::int as weekly_score,
  coalesce(
    sum(l.points) filter (
      where l.created_at >= date_trunc('month', now())
    ),
    0
  )::int as monthly_score,
  coalesce(sum(l.points), 0)::int as lifetime_score,
  max(l.created_at) as updated_at
from public.leaderboard_scores_log l
join public.users u on u.id = l.user_id
group by l.user_id, u.full_name, u.role, u.avatar_url
order by lifetime_score desc;
