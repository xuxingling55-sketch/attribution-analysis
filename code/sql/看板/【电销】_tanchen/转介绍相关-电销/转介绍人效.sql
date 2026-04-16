# 转介绍人效
sql3 = '''
DROP TABLE IF EXISTS tmp.niyiqiao_referral_per_amount_month
'''

sql4 = '''
CREATE TABLE  IF NOT EXISTS tmp.niyiqiao_referral_per_amount_month AS 
with  t0 as (
select distinct
  a.user_id
  ,order_id
  ,amount 
  ,substr(pay_time,1,19) pay_time
  ,substr(pay_time,1,7) pay_month
  ,case when substr(current_date(),1,7) > substr(pay_time,1,7)  then last_day(pay_time)  else date_sub(current_date,1) end pay_month_cutoff
  ,trunc(to_date(substr(pay_time, 1, 10)), 'MM') AS pay_month_firstday
  ,worker_id
  ,worker_name
  ,substr(c.start_date,1,10) in_date
  ,if(substr(c.stop_date,1,3) ='000',null,substr(stop_date,1,10)) end_date
from aws.crm_order_info a
left join crm.worker b on a.worker_id = b.id
left join crm.staff_change c on b.mail = c.email
where a.status = '支付成功' 
  and is_test = false
  and in_salary = 1
  and worker_id <> 0
  and substr(pay_time,1,10) between '2023-01-01'and date_sub(current_date,1) 
)


, t1 as (
select * from (
  select  
    t0.*
    ,case when substr(a.created_at,1,7)  is null then '其他用户'
          when substr(pay_time,1,7) = substr(a.created_at,1,7)  then '当月转介绍新用户'
          else '非当月转介绍用户' 
    end referral  
    ,a.created_at
    ,row_number()over(partition by t0.user_id,order_id order by a.created_at desc) rn
  from t0
  left join crm.new_user a
    on a.user_id = t0.user_id 
    and t0.pay_time > a.created_at and t0.pay_time <= add_months(a.created_at,6)
    and a.channel = 2
  )
where rn = 1
)

, t2 as (
select 
  pay_month
  ,pay_month_firstday
  ,pay_month_cutoff
  ,worker_id
  ,worker_name
  ,in_date
  ,end_date
  ,referral
  ,sum(amount) amount
  ,count(distinct user_id ) users
from t1 
group by 1,2,3,4,5,6,7,8
)



, t3 as (
select 
*
,CASE when tenure_days is null then '其他'
        WHEN tenure_days < 31 THEN '30天以内'
        WHEN tenure_days < 61 THEN '(30,60]'
        WHEN tenure_days < 91 THEN '(60,90]'
        WHEN tenure_days < 121 THEN '(90,120]'
        WHEN tenure_days < 181 THEN '(120,180]'
        WHEN tenure_days < 366 THEN '(180,365]'
      ELSE '一年以上'
    END AS tenure_range
from (
  select 
    pay_month
    ,pay_month_firstday
    ,pay_month_cutoff
    ,worker_id
    ,worker_name
    ,in_date
    ,end_date
    ,referral
    ,amount
    ,users
    ,case when in_date is null then null  -- 无入职时间为null
          when end_date is not null and end_date < in_date then null -- 已离职，离职早于入职为null
          when end_date is not null and end_date < pay_month_firstday then null -- 已离职，离职日早于支付月月初为null空
          when end_date is not null and end_date <= pay_month_cutoff then datediff(end_date, in_date) -- 当月内离职且离职日早于成单日→ 离职-入职
        else datediff(pay_month_cutoff, in_date) -- 未离职 或 离职日>承担日 → 统计终点-入职日（如10月未离职，按前一天算）
      end as tenure_days
    -- 2. 月初是否在职（定义：入职时间≤月初）
    ,case when in_date is null then null --入职日期为空 取空
          when end_date is not null and end_date < pay_month_firstday then null -- 已离职 离职时间 < 支付月月初
          when in_date <= pay_month_firstday then '是' --入职时间小于等于付费月月初 在职
        else '否' --当月在职或当月离职→月初在职
      end as is_working_at_month_start
  -- 3. 截止日是否在职
    ,case when in_date is null then null --入职日期为空 取空
          when end_date is not null and end_date < pay_month_firstday then null -- 跨月离职→空
          when end_date is null then '是'  -- 未离职→在职
          when end_date >= pay_month_cutoff then '是'  -- 离职日≥统计月月末→在职
        else '否'  -- 其他→不在职
      end as is_working_at_cutoff
  from t2 
  )
)

,t4 as (
select 
  a.worker_id
  ,worker_name
  ,org_level
  ,org_high_level
  ,start_time
  ,end_time
  ,b.team_name,b.regiment_name,b.department_name,b.workplace_name
  ,row_number()over(partition by worker_id,substr(a.start_time,1,7) order by a.start_time desc) rn
from dw.bridge_worker_organization a
left join dw.dim_crm_organization b on a.org_id = b.id
where 
  split(full_org_id, ',')[2]  in ( 4,400,702)
)



select  distinct
  pay_month,pay_month_firstday,pay_month_cutoff,referral
  ,t3.worker_id,t3.worker_name,t4.team_name,t4.regiment_name,t4.department_name,t4.workplace_name
  ,t3.tenure_range,t3.is_working_at_month_start,t3.is_working_at_cutoff
  ,amount,users
from t3
left join (select* from t4 where rn = 1) t4
  on t3.worker_id = t4.worker_id and t3.pay_month >= substr(t4.start_time,1,7) and t3.pay_month < substr(t4.end_time,1,7) 
where workplace_name is not null