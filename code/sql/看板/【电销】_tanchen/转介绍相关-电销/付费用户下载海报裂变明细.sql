#付费用户下载海报裂变明细
sql01='''
DROP TABLE IF EXISTS tmp.niyiqiao_good_level2_referral_dd
'''
sql02='''
CREATE TABLE  IF NOT EXISTS tmp.niyiqiao_good_level2_referral_dd AS(

with t0 as (
select 
  pay_time,business_good_kind_name_level_1_modify,business_good_kind_name_level_2_modify
  ,user_id,order_id,good_name,amount,rk
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
    ,order_id
    ,good_name
    ,amount
    ,a.worker_id
    ,a.worker_name
    ,case when b.org_id is not null then  b.org_id else a.team_id end org_id
    ,row_number()over(partition by user_id,substr(pay_time,1,7) order by pay_time desc ) rk
  from  aws.crm_order_info a
  left join dw.bridge_worker_organization b 
    on a.worker_id = b.worker_id and substr(pay_time,1,19) >= substr(start_time,1,19) and substr(pay_time,1,19) <= substr(end_time,1,19)
  where amount >= 39
      and is_test = false
      and status = '支付成功'
      and workplace_id in (4,400,702) 
      and regiment_id  not in (303,546,0) 
      and a.worker_id > 0
      and substr(pay_time,1,10) between '2022-04-21' and  date_sub(current_date,1) 
  )a
  left join dw.dim_crm_organization b on a.org_id = b.id
where team_name is not null
and rk = 1
)

, t1 as (
select distinct
a.old_user_id,a.user_id,a.worker_id,substr(a.created_at,1,19) created_at
from crm.new_user a
left join aws.crm_order_info b on a.worker_id = b.worker_id and a.old_user_id = b.user_id and is_test = false and in_salary = 1
where 
  a.channel = 2  
  and substr(a.created_at,1,10) between '2022-04-21'and date_sub(current_date,1) 
  and b.workplace_id in (4,400,702) 
  and b.regiment_id  not in (303,546,0) 
)

, t2 as (
select user_id,amount,order_id,substr(pay_time,1,19) pay_time from aws.crm_order_info 
  where is_test = false
      and substr(pay_time,1,10)  between '2022-04-21' and  date_sub(current_date,1) 
      and workplace_id in (4,400,702) 
      and regiment_id  not in (303,546,0) 
      and worker_id > 0
      and in_salary = 1
)

select distinct
  substr(t0.pay_time,1,7) pay_time
  ,business_good_kind_name_level_1_modify
  ,business_good_kind_name_level_2_modify
  ,t0.worker_id
  ,worker_name
  ,team_name
  ,heads_name
  ,regiment_name
  ,department_name
  ,workplace_name
  ,count(distinct t0.user_id ) paid_user_cnt--当月付费用户数
  ,count(distinct case when substr(t0.pay_time,1,7) = substr(t3.created_at,1,7) and t3.created_at is not null then t0.user_id end ) mm_down_user_cnt --当月下载海报用户数
  ,count(distinct case when substr(t0.pay_time,1,7) = substr(t1.created_at,1,7) then t1.old_user_id end ) mm_old_user_cnt-- --当月转介绍用户数
  ,count(distinct case when substr(t0.pay_time,1,7) = substr(t1.created_at,1,7) then t1.user_id end ) mm_new_user_cnt --裂变新用户数
  ,count(distinct case when substr(t0.pay_time,1,7) = substr(t1.created_at,1,7) then t2.user_id end ) mm_converted_user_cnt--转化用户数
  ,count(distinct case when substr(t0.pay_time,1,7) = substr(t1.created_at,1,7) then t2.order_id end ) mm_ord_cnt -- 转化订单量
  ,ifnull(sum( case when substr(t0.pay_time,1,7) = substr(t1.created_at,1,7) then t2.amount end  ),0) mm_amount--转化金额
  
  ,count(distinct case when substr(t3.created_at,1,10) <= DATE_ADD(substr(t0.pay_time,1,10),30) and t3.created_at is not null then t0.user_id end ) 30d_down_user_cnt  --30天内下载海报用户数
  ,count(distinct case when substr(t1.created_at,1,10) <= DATE_ADD(substr(t0.pay_time,1,10),30) then t1.old_user_id end ) 30d_old_user_cnt --30天内转介绍用户数
  ,count(distinct case when substr(t1.created_at,1,10) <= DATE_ADD(substr(t0.pay_time,1,10),30) then t1.user_id end ) 30d_new_user_cnt --30天内裂变新用户数
  ,count(distinct case when substr(t1.created_at,1,10) <= DATE_ADD(substr(t0.pay_time,1,10),30) then t2.user_id end ) 30d_converted_user_cnt --30天内转化用户数
  ,count(distinct case when substr(t1.created_at,1,10) <= DATE_ADD(substr(t0.pay_time,1,10),30) then t2.order_id end ) 30d_ord_cnt -- 30天内转化订单量
  ,ifnull( sum ( case when substr(t1.created_at,1,10) <= DATE_ADD(substr(t0.pay_time,1,10),30) then t2.amount end ),0) 30d_amount--30天内转化金额

from t0 
left join t1 on t1.old_user_id = t0.user_id and t1.created_at >= t0.pay_time and t1.worker_id = t0.worker_id
left join t2 on t1.user_id = t2.user_id and t2.pay_time >= t1.created_at 
left join crm.promotion_poster t3 on t0.user_id = t3.user_id and t0.pay_time < t3.created_at and  t0.worker_id = t3.worker_id
group by 1,2,3,4,5,6,7,8,9,10

)