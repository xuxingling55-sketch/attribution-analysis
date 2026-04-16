# 团组转介绍线索领取及转化
sql1='''
DROP TABLE IF EXISTS tmp.niyiqiao_crm_referral_tuanzu_mm 
'''
sql2='''
CREATE TABLE  IF NOT EXISTS tmp.niyiqiao_crm_referral_tuanzu_mm AS
with t0 as (
-- 转介绍用户入库时间，同一用户当月仅保留第一条记录（去重）
select 
  user_id,
  worker_id,
  substr(t.created_at,1,19) created_at,
  case when d0.regist_time > t.created_at  -- 绑定时尚未注册
          or d0.regist_time >= from_unixtime(unix_timestamp(t.created_at) - 12 * 60 * 60) then '新用户' -- 转介绍时间减12小时（秒级计算）
    else '老用户' end user_type,-- 老用户：注册超过12小时后才绑定
  d4.team_name,d3.heads_name ,d2.regiment_name ,d1.department_name,
  month_end,next_month_end
from (
  select 
    old_user_id,created_at,user_id
    ,worker_id,group_id1,group_id2,group_id3,group_id4
    ,last_day(created_at) as month_end --当月月底
    ,last_day(add_months(created_at,1)) as next_month_end --次月月底
    ,row_number() over(partition by user_id, substr(created_at,1,7) order by created_at) as rn  -- 同一用户按入库时间排序，取当月第一条记录
  from crm.new_user
  where substr(created_at,1,10) between '2022-04-21'and date_sub(current_date,1) 
    and channel = 2  --转介绍
    and group_id0 in (4,400,702)
    and group_id2 not in (303,546,0)
) t
left join dw.dim_user d0 on t.user_id = d0.u_user
left join dw.dim_crm_organization d1 on t.group_id1 = d1.id
left join dw.dim_crm_organization d2 on t.group_id2 = d2.id
left join dw.dim_crm_organization d3 on t.group_id3 = d3.id
left join dw.dim_crm_organization d4 on t.group_id4 = d4.id
where rn = 1  -- 仅保留当月第一条转介绍记录（视为唯一新线索）
)

, t1 as(
select 
  a.user_id userid
  ,a.order_id
  ,a.amount 
  ,case when course_group_kind = '公域主推品' then '公域主推品' 
          when string(strategy_type) regexp '多孩策略' then '多孩策略'  
          when string(strategy_type) regexp '历史大会员续购策略' then '历史大会员续购策略'  
      else business_good_kind_name_level_1 end business_good_kind_name_level_2_modify
  ,substr(a.pay_time,1,19) pay_time
  ,CASE WHEN a.order_type = 1 then '新增' WHEN order_type = 2 THEN '续费' END AS order_type
from aws.crm_order_info a 
where status = '支付成功' 
  and substr(pay_time,1,10) between '2022-04-21'and date_sub(current_date,1) 
  and a.workplace_id in (4,400,702)
  and a.regiment_id not in (303,546,0)
  and a.is_test = false
  and a.in_salary = 1
)

, t2 as (
select  
  t0.*
  ,t1.*
  -- 14天内转化(1=是)
  ,case when t1.pay_time > t0.created_at and t1.pay_time <= date_add(t0.created_at,14) then 1 else 0 end as flag_14d
  -- 当月月底前转化(包含14天内,1=是)
  ,case when t1.pay_time > t0.created_at and t1.pay_time <= t0.month_end then 1 else 0 end as flag_month
  -- 次月月底前转化(包含前两者,1=是)
  ,case when t1.pay_time > t0.created_at and t1.pay_time <= t0.next_month_end then 1 else 0 end as flag_next_month
from t0 
left join t1 on t0.user_id = t1.userid 
  and t1.pay_time > t0.created_at -- 支付晚于线索创建
  and t1.pay_time <= t0.next_month_end  -- 支付不晚于线索次月月底
)

select 
  substr(t2.created_at,1,7)created_at
  ,order_type
  ,team_name
  ,heads_name 
  ,regiment_name 
  ,department_name
  ,user_type
  ,count(distinct user_id) new_user

  ,count(distinct case when t2.flag_14d = 1 then t2.user_id end) 14d_paid_user
  ,count(distinct case when t2.flag_14d = 1 then t2.order_id end) 14d_paid_ord
  ,sum( case when t2.flag_14d = 1 then t2.amount end) 14d_paid_amount

  ,count(distinct case when t2.flag_month = 1 then t2.user_id end) mon_paid_user
  ,count(distinct case when t2.flag_month = 1 then t2.order_id end) mon_paid_ord
  ,sum( case when t2.flag_month = 1 then t2.amount end) mon_paid_amount

  ,count(distinct case when t2.flag_next_month = 1 then t2.user_id end) next_mon_paid_user
  ,count(distinct case when t2.flag_next_month = 1 then t2.order_id end) next_mon_paid_ord
  ,sum( case when t2.flag_next_month = 1 then t2.amount end) next_mon_paid_amount

from t2
group by   
  substr(t2.created_at,1,7)
  ,order_type
  ,team_name
  ,heads_name 
  ,regiment_name 
  ,department_name
  ,user_type