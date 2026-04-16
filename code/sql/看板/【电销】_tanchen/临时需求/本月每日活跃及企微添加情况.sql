-- 本月每日活跃及企微添加情况
-- 2026-03-19

with active as (
  select distinct
    from_unixtime(unix_timestamp(cast(day as string), 'yyyyMMdd'), 'yyyy-MM-dd') as dt
    ,active_u_user
  from aws.crm_active_data_pool_day
  where day between 20260301 and 20260318
    and active_user_attribution in ('中学用户', '小学用户', 'c')
)

, wechat_add as (
  select distinct
    substr(created_at, 1, 10) as dt
    ,yc_user_id
  from crm.contact_log
  where source = 3
    and change_type = 'add_external_contact'
    and substr(created_at, 1, 10) between '2026-03-01' and '2026-03-18'
)

select
  a.dt as `日期`
  ,count(distinct a.active_u_user) as `活跃量`
  ,count(distinct case when b.yc_user_id is not null then a.active_u_user end) as `企微添加量`
  ,concat(round(count(distinct case when b.yc_user_id is not null then a.active_u_user end) / count(distinct a.active_u_user) * 100, 2), '%') as `企微添加率`
from active a
left join wechat_add b
  on a.dt = b.dt and a.active_u_user = b.yc_user_id
group by a.dt
order by a.dt
limit 100000
