-- 质检场景：2月最后3天(2/26-2/28)，金额>2000，且用户从未在该成交坐席名下有过线索记录
with feb_orders as (
  select
    order_id
    ,user_id
    ,worker_id
    ,worker_name
    ,amount
    ,pay_time
    ,good_name
    ,mid_stage_name
    ,regiment_id
  from aws.crm_order_info
  where substr(cast(pay_time as string), 1, 10) between '2026-02-26' and '2026-02-28'
    and workplace_id in (4, 400, 702)
    and regiment_id not in (0, 303, 546)
    and worker_id <> 0
    and in_salary = 1
    and is_test = false
    and status = '支付成功'
    and amount > 2000
)
,has_clue as (
  select distinct
    o.order_id
  from feb_orders o
  inner join aws.clue_info c
    on c.user_id = o.user_id
    and c.worker_id = cast(o.worker_id as string)
    and c.created_at < o.pay_time
  where c.workplace_id in (4, 400, 702)
)
select
  o.order_id as `订单id`
  ,o.user_id as `用户id`
  ,o.worker_id as `坐席id`
  ,o.worker_name as `坐席名称`
  ,d.regiment_name as `团名称`
  ,o.amount as `订单金额`
  ,substr(cast(o.pay_time as string), 1, 19) as `支付时间`
  ,o.good_name as `商品名称`
  ,o.mid_stage_name as `学段`
from feb_orders o
left join has_clue hc on o.order_id = hc.order_id
left join dw.dim_crm_organization d on o.regiment_id = d.id
where hc.order_id is null
order by o.pay_time
limit 100000
