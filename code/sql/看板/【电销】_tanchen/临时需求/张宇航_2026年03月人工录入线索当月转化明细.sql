-- 张宇航小组_2026年03月人工录入线索当月转化明细
-- 口径：人工录入线索，当月转化（领取月=成交月），status='支付成功'

with t1 as (
  select 
    a.user_id
    ,substr(a.created_at, 1, 19) as created_at
    ,a.worker_name
    ,a.team_id
  from aws.clue_info a
  left join dw.dim_crm_organization d on a.team_id = d.id
  where substr(a.created_at, 1, 7) = '2026-03'
    and a.clue_source = 'manual'
    and a.user_sk > 0
    and a.workplace_id in (4, 400, 702)
    and a.regiment_id not in (0, 303, 546)
    and d.team_name like '%张宇航%'
)

, t_phone as (
  select 
    u_user
    ,if(phone is null, phone, if(phone rlike '^\\d+$', phone, cast(unbase64(phone) as string))) as phone
  from dw.dim_user
  where length(phone) > 0
)

, t2 as (
  select 
    user_id
    ,substr(pay_time, 1, 19) as pay_time
    ,order_id
    ,amount
    ,good_name
  from aws.crm_order_info
  where substr(pay_time, 1, 7) = '2026-03'
    and worker_id <> 0
    and in_salary = 1
    and is_test = false
    and status = '支付成功'
)

select 
  t1.worker_name as `员工姓名`
  ,t1.created_at as `录入时间`
  ,t1.user_id as `用户id`
  ,p.phone as `用户手机号`
  ,t2.pay_time as `转化时间`
  ,t2.order_id as `转化订单号`
  ,t2.amount as `转化金额`
  ,t2.good_name as `转化商品名称`
from t1
left join t_phone p on t1.user_id = p.u_user
left join t2 on t1.user_id = t2.user_id and t2.pay_time >= t1.created_at
order by t1.created_at
limit 100000
