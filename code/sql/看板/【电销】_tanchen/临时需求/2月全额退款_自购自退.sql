-- 质检场景：2月全额退款中，购买到退款>30天，且购课账号为坐席本人（自购自退）
-- 多条退款取第一次退款时间；坐席手机号用 crm.worker.ph 解码，用户手机号用 dw.dim_user.phone 解码
-- ⚠️ 仅聚合2月退款记录判断全额，若存在跨月分批退款可能遗漏，实际自购自退场景下极少见
with feb_refunds as (
  select
    order_id
    ,u_user
    ,min(refund_time) as first_refund_time
    ,sum(refund_amount) as total_refund_amount
    ,max(amount) as order_amount
  from dw.fact_order_detail_refund
  where substr(cast(refund_time as string), 1, 7) = '2026-02'
    and is_test_user = 0
  group by order_id, u_user
  having sum(refund_amount) >= max(amount)
)
,orders as (
  select
    order_id
    ,user_id
    ,worker_id
    ,worker_name
    ,pay_time
    ,amount
    ,regiment_id
  from aws.crm_order_info
  where workplace_id in (4, 400, 702)
    and regiment_id not in (0, 303, 546)
    and worker_id <> 0
    and in_salary = 1
    and is_test = false
    and status = '支付成功'
)
,worker_phones as (
  select
    id as worker_id
    ,if(ph is null, null, if(ph rlike '^\\d+$', ph, cast(unbase64(ph) as string))) as worker_phone
  from crm.worker
)
,user_phones as (
  select
    u_user
    ,if(phone is null, null, if(phone rlike '^\\d+$', phone, cast(unbase64(phone) as string))) as user_phone
  from dw.dim_user
)
select
  substr(cast(o.pay_time as string), 1, 19) as `购买时间`
  ,substr(cast(r.first_refund_time as string), 1, 19) as `首次退款时间`
  ,datediff(r.first_refund_time, o.pay_time) as `购买到退款天数`
  ,o.order_id as `订单号`
  ,r.u_user as `用户id`
  ,o.worker_name as `坐席名称`
  ,d.regiment_name as `所属团`
  ,o.amount as `订单金额`
  ,r.total_refund_amount as `退款总金额`
  ,up.user_phone as `用户手机号`
  ,wp.worker_phone as `坐席手机号`
from feb_refunds r
inner join orders o on r.order_id = o.order_id
inner join worker_phones wp on o.worker_id = wp.worker_id
inner join user_phones up on r.u_user = up.u_user
left join dw.dim_crm_organization d on o.regiment_id = d.id
where datediff(r.first_refund_time, o.pay_time) > 30
  and wp.worker_phone is not null
  and up.user_phone is not null
  and wp.worker_phone = up.user_phone
order by o.pay_time
limit 100000
