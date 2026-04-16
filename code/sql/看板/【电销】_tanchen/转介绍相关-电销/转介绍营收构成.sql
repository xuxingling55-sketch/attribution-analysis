# 转介绍营收构成
sql1 = '''
DROP TABLE IF EXISTS tmp.niyiqiao_referral_amount_day
'''

sql2 = '''
CREATE TABLE  IF NOT EXISTS tmp.niyiqiao_referral_amount_day AS 
with  t1 as (
select distinct
  user_id
  ,order_id
  ,amount 
  ,substr(pay_time,1,19) pay_time
  ,CASE WHEN order_type = 1 then '新增' WHEN order_type = 2 THEN '续费' END AS order_type
  ,case 
        when course_group_kind = '公域主推品' then '公域品' 
        when string(strategy_type) regexp '多孩策略|历史大会员续购策略' then '续购'
      else business_good_kind_name_level_1 end business_good_kind_name_level_1_modify
  ,a.worker_id
  ,a.worker_name
  ,f.team_name
  ,d.regiment_name
  ,c.department_name
  ,b.workplace_name
from aws.crm_order_info a
left join dw.dim_crm_organization as b on a.workplace_id = b.id
left join dw.dim_crm_organization as c on a.department_id = c.id
left join dw.dim_crm_organization as d on a.regiment_id = d.id
left join dw.dim_crm_organization as f on a.team_id = f.id
where status = '支付成功' 
  and a.is_test = false
  and a.in_salary = 1
  and a.worker_id <> 0
  and substr(pay_time,1,10) between '2022-04-21'and date_sub(current_date,1) 
  and a.workplace_id in (4,400,702)
  and a.regiment_id not in (303,546,0)
)

, t2 as (
select * from (
  select  
    t1.*
    ,case when substr(a.created_at,1,7)  is null then '其他用户'
          when substr(pay_time,1,7) = substr(a.created_at,1,7)  then '当月转介绍新用户'
          else '非当月转介绍用户' 
    end referral  
    ,a.created_at
    ,row_number()over(partition by t1.user_id,order_id order by a.created_at desc) rn
  from t1
  left join crm.new_user a
    on a.user_id = t1.user_id 
    and t1.pay_time > a.created_at and t1.pay_time <= add_months(a.created_at,6)
    and a.channel = 2
  )
where rn = 1
)


select 
  substr(pay_time,1,10)pay_time
  ,order_type
  ,business_good_kind_name_level_1_modify
  ,worker_id
  ,worker_name
  ,team_name
  ,regiment_name
  ,department_name
  ,workplace_name
  ,referral
  ,sum(amount) amount
  ,count(distinct user_id ) users
from t2
group by 1,2,3,4,5,6,7,8,9,10
