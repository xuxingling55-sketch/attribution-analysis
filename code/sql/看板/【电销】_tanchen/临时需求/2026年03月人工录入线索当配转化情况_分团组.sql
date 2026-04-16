-- 2026年03月人工录入线索当配转化情况_分团组
-- 口径：领取月=成交月（当配），有订单即算转化
-- 维度：分团组

with t1 as (
  select 
    user_id
    ,min(substr(created_at, 1, 19)) as created_at
    ,regiment_id
  from aws.clue_info
  where substr(created_at, 1, 7) = '2026-03'
    and clue_source = 'manual'
    and user_sk > 0
    and workplace_id in (4, 400, 702)
    and regiment_id not in (0, 303, 546)
  group by user_id, regiment_id
)

, t2 as (
  select 
    user_id
    ,substr(pay_time, 1, 19) as pay_time
    ,order_id
    ,amount
  from aws.crm_order_info
  where substr(pay_time, 1, 7) = '2026-03'
    and workplace_id in (4, 400, 702)
    and regiment_id not in (0, 303, 546)
    and worker_id <> 0
    and in_salary = 1
    and is_test = false
)

select 
  d.regiment_name as `团组名称`
  ,count(distinct t1.user_id) as `领取量`
  ,count(distinct case when t2.order_id is not null then t1.user_id end) as `当配转化量`
  ,round(count(distinct case when t2.order_id is not null then t1.user_id end) / count(distinct t1.user_id) * 100, 2) as `当配转化率(%)`
  ,sum(t2.amount) as `当配转化金额`
from t1
left join t2 on t1.user_id = t2.user_id and t2.pay_time >= t1.created_at
left join dw.dim_crm_organization d on t1.regiment_id = d.id
group by d.regiment_name
order by count(distinct t1.user_id) desc
limit 100000
