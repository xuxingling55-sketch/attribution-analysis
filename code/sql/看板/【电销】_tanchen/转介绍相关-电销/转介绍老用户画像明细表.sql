# 转介绍老用户画像明细表
sql01 = '''
DROP TABLE IF EXISTS tmp.niyiqiao_referral_paid_user_portrait
'''
sql02 = '''
CREATE TABLE  IF NOT EXISTS tmp.niyiqiao_referral_paid_user_portrait as 
with t1 as (
select * from (
  select 
    substr(a.pay_time,1,19) pay_date
    ,a.city_class
    ,a.city
    ,a.province
    ,case when a.gender = 'male' then '男生' when a.gender = 'female' then '女生' else '未知' end gender
    ,a.mid_stage_name
    ,a.mid_grade
    ,case when a.interest_subsidy_method is null then '未分期' else '分期' end interest_subsidy_method
    ,case when course_group_kind = '公域主推品' then '公域主推品' 
          when string(strategy_type) regexp '多孩策略' then '多孩策略'  
          when string(strategy_type) regexp '历史大会员续购策略' then '历史大会员续购策略'  
          when business_good_kind_name_level_1 = '其他' then business_good_kind_name_level_3 
      else business_good_kind_name_level_1 end good_kind_name
    ,c.department_name
    ,d.regiment_name
    ,e.heads_name
    ,f.team_name
    ,a.user_id
    ,a.order_id
    ,a.amount
    ,case when a.amount <= 1000 then '1-1000'
          when a.amount <= 2000 then '1001-2000'
          when a.amount <= 3000 then '2001-3000'
          when a.amount <= 4000 then '3001-4000'
          when a.amount <= 5000 then '4001-5000'
          when a.amount <= 6000 then '5001-6000'
          when a.amount <= 7000 then '6001-7000'
          when a.amount <= 8000 then '7001-8000'
          when a.amount <= 9000 then '8001-9000'
          when a.amount <= 10000 then '9001-10000'
        else '10000+' end amounts
    ,count(a.order_id) over(partition by a.user_id) ord_cnt --全局累计：每行均显示该用户的总订单数
    ,row_number()over(partition by a.user_id order by a.pay_time ) pay_rn -- 按金额降序排名（用户维度内）
  from aws.crm_order_info a
  left join dw.dim_crm_organization as c on a.department_id = c.id
  left join dw.dim_crm_organization as d on a.regiment_id = d.id
  left join dw.dim_crm_organization as e on a.heads_id = e.id
  left join dw.dim_crm_organization as f on a.team_id = f.id
  where 1=1
    and substr(a.pay_time,1,10) between '2021-01-01' and date_sub(current_date,1)
    and a.workplace_id in (4,400,702)
    and a.regiment_id  not in (303,0,546)
    and a.worker_name is not null
    and a.in_salary = 1
    and a.worker_id <> 0 
    and a.is_test = false
    and a.status = '支付成功'
  )
where pay_rn = 1
)

, t2 as (
  select 
    t1.*
    ,t2.old_user_id
    ,t2.user_id as new_user_id  -- 裂变新用户ID（用于去重）
    ,t2.created_at  -- 绑定时间（需保留）
    ,case when created_at is null then '无拉新'
        when datediff(t2.created_at, t1.pay_date) < 31 then '[0,30]'
        when datediff(t2.created_at, t1.pay_date) < 61 then '[31,60]'
        when datediff(t2.created_at, t1.pay_date) < 91 then '[61,90]'
        when datediff(t2.created_at, t1.pay_date) < 121 then '[91,120]'
        when datediff(t2.created_at, t1.pay_date) < 151 then '[121,150]'
        when datediff(t2.created_at, t1.pay_date) < 181 then '[151,180]'
        when datediff(t2.created_at, t1.pay_date) < 211 then '[181,210]'
        when datediff(t2.created_at, t1.pay_date) < 241 then '[211,240]'
        when datediff(t2.created_at, t1.pay_date) < 271 then '[241,270]'
        when datediff(t2.created_at, t1.pay_date) < 301 then '[271,300]'
        when datediff(t2.created_at, t1.pay_date) < 331 then '[301,330]'
        when datediff(t2.created_at, t1.pay_date) < 366 then '[331,365]'
      else '1年以上' end as diff_type  -- 拉新周期
  ,datediff(t2.created_at, t1.pay_date) dates
  ,case when old_user_id is null then '' else row_number()over(partition by old_user_id order by created_at) end created_rn
from t1
left join crm.new_user t2 on t1.user_id = t2.old_user_id and t2.channel = 2 and t2.created_at > t1.pay_date
)



select 
  substr(pay_date,1,7)pay_date
  ,department_name
  ,regiment_name
  ,heads_name
  ,team_name
  ,city_class
  ,province
  ,city
  ,gender
  ,mid_stage_name
  ,mid_grade
  ,interest_subsidy_method
  ,good_kind_name
  ,amounts
  ,case when ord_cnt = 1 then '复购-0'
        when ord_cnt = 2 then '复购-1'
        when ord_cnt = 3 then '复购-2'
        when ord_cnt = 4 then '复购-3'
      else  '复购-4及以上' end ord_type
  ,case when new_user_id is null then '无拉新' else '有拉新' end as is_new_flag
  ,case when count(distinct new_user_id) = 0 then '未拉新'
        when count(distinct new_user_id) = 1 then '拉新-1人'
        when count(distinct new_user_id) = 2 then '拉新-2人'
        when count(distinct new_user_id) = 3 then '拉新-3人'
        when count(distinct new_user_id) > 3 then '拉新-4人以上' 
      end new_type
  ,count(distinct user_id) pay_cnt
  ,count(distinct case when old_user_id is not null then user_id end ) old_cnt
  ,count(distinct new_user_id) new_cnt
  ,avg( dates  ) dates
  ,avg( case when diff_type in ('[0,30]' ) then dates end ) 1_mon
  ,avg( case when diff_type in ('[31,60]') then dates end ) 2_mon
  ,avg( case when diff_type in ('[61,90]') then dates end ) 3_mon
  ,avg( case when diff_type in ('[91,120]') then dates end ) 4_mon
  ,avg( case when diff_type in ('[121,150]') then dates end ) 5_mon
  ,avg( case when diff_type in ('[151,180]') then dates end ) 6_mon
  ,avg( case when diff_type in ('[181,210]') then dates end ) 7_mon
  ,avg( case when diff_type in ('[211,240]') then dates end ) 8_mon
  ,avg( case when diff_type in ('[241,270]') then dates end ) 9_mon
  ,avg( case when diff_type in ('[271,300]') then dates end ) 10_mon
  ,avg( case when diff_type in ('[301,330]') then dates end ) 11_mon
  ,avg( case when diff_type in ('[331,365]') then dates end ) 12_mon
  ,avg( case when diff_type in ('1年以上') then dates end ) 1_year
  ,avg( case when created_rn = 1 then dates end ) 1new_dates
  ,avg( case when created_rn = 2 then dates end ) 2new_dates
from t2
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16