-- 质检场景：最近3个完整月(2025-12~2026-02)，成交账号被非成交坐席用系统外呼>5分钟
-- 粒度：(订单, 外呼坐席) — 同一订单被多个非成交坐席外呼则出多行，同一用户多笔成交也分别输出
with orders as (
  select
    order_id
    ,user_id
    ,worker_id
    ,worker_name
    ,amount
    ,pay_time
    ,regiment_id
  from aws.crm_order_info
  where substr(cast(pay_time as string), 1, 7) between '2025-12' and '2026-02'
    and workplace_id in (4, 400, 702)
    and regiment_id not in (0, 303, 546)
    and worker_id <> 0
    and in_salary = 1
    and is_test = false
    and status = '支付成功'
)
,long_calls as (
  select
    user_id
    ,worker_id as call_worker_id
    ,worker_name as call_worker_name
    ,department_name as call_department_name
    ,regiment_name as call_regiment_name
    ,heads_name as call_heads_name
    ,count(action_id) as call_cnt
    ,round(sum(call_time_length) / 60.0, 1) as total_minutes
  from tmp.niyiqiao_crm_clue_call_record
  where call_created_at >= '2025-12-01'
    and call_created_at < '2026-03-01'
    and is_connect = 1
    and call_time_length > 300
  group by user_id, worker_id, worker_name, department_name, regiment_name, heads_name
)
select
  substr(cast(o.pay_time as string), 1, 19) as `订单时间`
  ,o.amount as `订单金额`
  ,o.order_id as `订单号`
  ,o.user_id as `用户id`
  ,o.worker_name as `成交坐席名称`
  ,d.regiment_name as `成交坐席所属团`
  ,c.call_worker_name as `外呼坐席名称`
  ,c.call_department_name as `外呼坐席学部`
  ,c.call_regiment_name as `外呼坐席所属团`
  ,c.call_heads_name as `外呼坐席主管组`
  ,c.call_cnt as `超5分钟通话次数`
  ,c.total_minutes as `超5分钟通话总时长_分钟`
from orders o
inner join long_calls c
  on c.user_id = o.user_id
  and c.call_worker_id <> cast(o.worker_id as string)
left join dw.dim_crm_organization d on o.regiment_id = d.id
order by o.user_id, o.pay_time
limit 100000
