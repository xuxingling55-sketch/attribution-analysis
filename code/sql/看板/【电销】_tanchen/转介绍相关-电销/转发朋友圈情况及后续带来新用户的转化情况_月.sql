# 付费用户6个月内转发朋友圈监控
sql1='''
DROP TABLE IF EXISTS tmp.niyiqiao_paid_user_point_mm
'''

sql2 = '''
CREATE TABLE  IF NOT EXISTS tmp.niyiqiao_paid_user_point_mm AS (
with t1 as (
-- 付费用户
select distinct
  substr(pay_time,1,7) paid_month
  ,date_add(last_day(add_months(pay_time,-1)),1) pay_begin
  ,business_good_kind_name_level_1_modify
  ,business_good_kind_name_level_2_modify
  ,user_id
  ,worker_id,worker_name,team_name,heads_name,regiment_name,department_name,workplace_name
from (
  select 
    substr(pay_time,1,19) pay_time
    ,case when course_group_kind = '公域主推品' then '公域品' 
        when string(strategy_type) regexp '多孩策略|历史大会员续购策略' then '续购'
      else business_good_kind_name_level_1 end business_good_kind_name_level_1_modify
    ,case when course_group_kind = '公域主推品' then '公域主推品' 
        when string(strategy_type) regexp '多孩策略' then '多孩策略'  
        when string(strategy_type) regexp '历史大会员续购策略' then '历史大会员续购策略'  
      else business_good_kind_name_level_2 end business_good_kind_name_level_2_modify
    ,user_id
    ,a.worker_id
    ,a.worker_name
    ,case when b.org_id is not null then  b.org_id else a.team_id end org_id
    ,row_number()over(partition by user_id,substr(pay_time,1,7) order by pay_time ) rk
  from  aws.crm_order_info a
  left join dw.bridge_worker_organization b 
    on a.worker_id = b.worker_id and substr(pay_time,1,19) >= substr(start_time,1,19) and substr(pay_time,1,19) <= substr(end_time,1,19)
  where in_salary = 1 
      and status = '支付成功'
      and workplace_id in (4,400,702) 
      and regiment_id  not in (303,546,0) 
      and a.worker_id > 0
      and a.is_test = false
      and substr(pay_time,1,10) between '2022-04-21' and  date_sub(current_date,1) 
  )a
  left join dw.dim_crm_organization b on a.org_id = b.id
where team_name is not null
and rk = 1  
)

, t2 as (
select distinct 
substr(created_at,1,7) point_month
,date_add(last_day(add_months(created_at,-1)),1) point_begin
, user_id point_user_id
from crm.point_log_all 
where substr(created_at,1,10) between '2022-05-01' and date_sub(current_date,1)
  and point_type=1
)


select  
  paid_month
  ,business_good_kind_name_level_1_modify
  ,business_good_kind_name_level_2_modify
  ,team_name
  ,heads_name
  ,regiment_name
  ,department_name
  ,workplace_name
  ,count(distinct t1.user_id )  paid_cnt
  ,count(distinct case when pay_begin = point_begin and t2.point_user_id is not null then t1.user_id end )  0_point_cnt
  ,count(distinct case when add_months(pay_begin,1) = point_begin and t2.point_user_id is not null then t1.user_id end )  1_point_cnt
  ,count(distinct case when add_months(pay_begin,2) = point_begin and t2.point_user_id is not null then t1.user_id end )  2_point_cnt
  ,count(distinct case when add_months(pay_begin,3) = point_begin and t2.point_user_id is not null then t1.user_id end )  3_point_cnt
  ,count(distinct case when add_months(pay_begin,4) = point_begin and t2.point_user_id is not null then t1.user_id end )  4_point_cnt
  ,count(distinct case when add_months(pay_begin,5) = point_begin and t2.point_user_id is not null then t1.user_id end )  5_point_cnt
  ,count(distinct case when add_months(pay_begin,6) = point_begin and t2.point_user_id is not null then t1.user_id end )  6_point_cnt
from t1 
left join t2 on t1.user_id = t2.point_user_id 
group by 1,2,3,4,5,6,7,8
order by 1 desc 

)
'''


#发朋友圈用户后续带来新用户的转化

sql3 = '''
DROP TABLE IF EXISTS tmp.niyiqiao_pointuser_newuser_paid
'''

sql4 = '''
CREATE TABLE  IF NOT EXISTS tmp.niyiqiao_pointuser_newuser_paid AS (
with  t0 as (
--用户每月首次发朋友圈时间
  select 
    substr(created_at,1,7)point_month,user_id point_user_id
    ,min(substr(created_at,1,19))point_day 
  from crm.point_log_all 
  where substr(created_at,1,10) between '2022-05-01' and date_sub(current_date,1)
    and point_type = 1
  group by 1,2
)

, t1 as (
--用户每笔订单的商品状态和坐席归属
 select 
    a.u_user paid_user_id,substr(paid_time,1,19)pay_time
    ,ifnull(a.worker_name,"无坐席") worker_name
    ,ifnull(team_name,"") team_name
    ,ifnull(heads_name,"") heads_name
    ,ifnull(regiment_name,"") regiment_name
    ,ifnull(department_name,"") department_name
    ,ifnull(workplace_name,"") workplace_name
    ,case when course_group_kind = '公域主推品' then '公域品' 
        when string(strategy_type) regexp '多孩策略|历史大会员续购策略' then '续购'
      else business_good_kind_name_level_1 end business_good_kind_name_level_1_modify
    ,case when course_group_kind = '公域主推品' then '公域主推品' 
        when string(strategy_type) regexp '多孩策略' then '多孩策略'  
        when string(strategy_type) regexp '历史大会员续购策略' then '历史大会员续购策略'  
      else business_good_kind_name_level_2 end business_good_kind_name_level_2_modify
    ,sum(a.sub_amount) amount
  from dws.topic_order_detail a
  left join dw.bridge_worker_organization c 
    on a.worker_id = c.worker_id and substr(paid_time,1,19) >= substr(start_time,1,19) and substr(paid_time,1,19) <= substr(end_time,1,19)
  left join dw.dim_crm_organization d on c.org_id = d.id
  where a.status = '支付成功'  and a.u_user in (select point_user_id from t0)
  group by 1,2,3,4,5,6,7,8,9,10
  having sum(a.sub_amount) > 100

)


, t2 as (
-- 每月用户发朋友圈的架构及次数
select 
  point_month,point_user_id,point_day,worker_name,team_name,heads_name,regiment_name,department_name,workplace_name
  ,business_good_kind_name_level_1_modify
  ,business_good_kind_name_level_2_modify
  ,count(c.user_id) point_cnt
from(
select 
  point_month,point_user_id,point_day,worker_name,team_name,heads_name,regiment_name,department_name,workplace_name
  ,business_good_kind_name_level_1_modify
  ,business_good_kind_name_level_2_modify
  ,row_number()over(partition by point_month,point_user_id order by pay_time desc ) rk
from t0
left join t1 on point_user_id = paid_user_id and pay_time < point_day
) a
left join (select * from crm.point_log_all where point_type = 1) c on a.point_user_id = c.user_id and point_month = substr(c.created_at,1,7)
where rk = 1 
group by point_month,point_user_id,point_day,worker_name,team_name,heads_name,regiment_name,department_name,workplace_name,business_good_kind_name_level_1_modify,business_good_kind_name_level_2_modify
)




-- -- 发朋友圈用户中转介绍带来的转介绍新用户及后续6个月内的转化
,t3 AS (
select
  point_month,point_user_id
  ,count(distinct old_user_id) old_user
  ,count(distinct new_user_id) new_user
  ,count(distinct user_id) paid_user
  ,count(distinct order_id)cnt
  ,sum(amount) amount
from (
  select 
    point_month
    ,point_user_id
    ,point_day
    ,old_user_id
    ,user_id new_user_id
    ,substr(created_at,1,19) referral_day
    ,row_number() over (partition by user_id order by point_day desc)  rn
  from t0
  left join (
    select * from crm.new_user where channel = 2 
  ) a on point_user_id = old_user_id and point_day < SUBSTR(created_at, 1, 19)
  ) a
left join (
  select * from aws.crm_order_info where in_salary = 1 and status = '支付成功'  and is_test = false
) b on new_user_id = user_id  and referral_day < substr(pay_time,1,19)  and add_months(referral_day,6) > substr(pay_time,1,19)
where rn = 1 
group by 1,2
)


select 
t2.point_month
,business_good_kind_name_level_1_modify
,business_good_kind_name_level_2_modify
,worker_name,team_name,heads_name,regiment_name,department_name,workplace_name
,count(distinct t2.point_user_id) point_user
,sum( point_cnt ) point_cnt
,sum( old_user ) olduser_cnt
,sum( new_user ) newuser_cnt
,sum( paid_user )  paiduser_cnt
,sum( cnt ) cnt
,sum( amount ) amount
from t2
left join t3 on t2.point_user_id = t3.point_user_id  and t2.point_month = t3.point_month
group by t2.point_month,business_good_kind_name_level_1_modify,business_good_kind_name_level_2_modify
    ,worker_name,team_name,heads_name,regiment_name,department_name,workplace_name
order by t2.point_month desc
)