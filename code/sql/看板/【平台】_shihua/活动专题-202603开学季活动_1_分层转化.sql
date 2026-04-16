-- =====================================================
-- 看板名称：活动专题-202603开学季活动
-- 业务域：【平台】_shihua
-- 图表/组件：活动专题-202603开学季活动_1_分层转化
-- 工具与位置：FineBI（自 `.cursor/code/sql/临时文件` 迁入）
-- 刷新周期：T+1
-- 维护人：meishihua
-- 关联指标：→ glossary/【平台】_shihua.md#
-- 主用表：→ code/sql/表结构/【平台】_shihua/
-- 最后同步自看板日期：20260302
-- ⚠️ 注意：
-- =====================================================

-- 帆软-数据准备-sql 
-- with dingjin_user as (select
-- a.year
-- ,case 
--     when a.year = 2025 then type 
--     when type = '定金用户' then '定金用户'
--     when user_strategy_tag_day regexp '历史大会员' then '历史大会员'
--     when user_strategy_tag_day regexp '付费组合品' then '历史组合品'
--     when user_strategy_tag_day regexp '付费加购品|付费零售品' then '其它续费用户'
--     else ''
--     end as type
-- ,a.u_user
-- from (select cast(substr(day,1,4) as int) as year,u_user,user_strategy_tag_day,business_user_pay_status_statistics 
--   from dws.topic_user_info 
--   where day = 20260117 or day = 20250110 -- 截止正式期开始前一天
--   ) a 
-- left join hive.tmp.meishihua_target_user_detail_202601_tmp_all b on a.u_user = b.u_user and a.year = b.year 
-- group by 1,2,3
-- )


with dingjin_user as (select
  cast(substr(day,1,4) as int) as year
  ,u_user
  ,case 
        when user_strategy_tag_day regexp '历史大会员用户' then '历史大会员用户'
        else user_strategy_tag_day end as type 
  from dws.topic_user_info 
  where day = 20260301 or day = 20250301 -- 截止正式期开始前一天
  group by 1,2,3
)



,active_user as (
-- C端活跃
select 
day
,day_timestamp
,new_user_attribution
,year
,u_user
,max(is_first_active) is_first_active
from (
select
*
,case when row_number() over (partition by new_user_attribution,u_user,left(day,4) order by day) = 1  
      then 1 else 0 
      end as is_first_active -- 是否首次活跃，过滤掉用户为空的排名
from (
select
day
,day_timestamp
,'c' as new_user_attribution 
,u_user
,left(day,4) as year
from hive.aws.business_active_user_last_14_day
where u_user is NOT null and 
    (
      (day between 20260302 and 20260331 and day <= DATE_FORMAT(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), '%Y%m%d')) 
      or day between 20250302 and 20250331 -- and day <= DATE_FORMAT(DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 1 YEAR), '%Y%m%d') -- 后面有看同期全月还是截止同一天的指标，这里不卡
      )
group by 1,2,3,4,5


) a
) rn 
group by day
,day_timestamp
,new_user_attribution
,year
,u_user
)



,active_shuxing as (select 
stage_name_month,
grade_name_month,
grade_stage_name_month,
business_user_pay_status_statistics_month,
business_user_pay_status_business_month,
new_user_attribution,
u_user,
year
from (select *
,row_number() over(partition by new_user_attribution,u_user,left(day,4) order by day) ranks
from 
(
-- C端活跃
select 
stage_name_day as stage_name_month,-- 仅修改名称，与原来的看板字段名称匹配，非真实month标签，下同
grade_name_day as grade_name_month,
case when grade_name_day regexp '一年级|二年级' then '小初'
when grade_name_day regexp '三年级|四年级' then '小中'
when grade_name_day regexp '五年级|六年级' then '小高'
else grade_name_day
end as grade_stage_name_month, -- 用户年级段
business_user_pay_status_statistics_day as business_user_pay_status_statistics_month,
business_user_pay_status_business_day as business_user_pay_status_business_month,
u_user,
left(day,4) as year,
day,
'c' as new_user_attribution 
from hive.aws.business_active_user_last_14_day

where (
      (day between 20260302 and 20260331 and day <= DATE_FORMAT(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), '%Y%m%d')) 
      or day between 20250302 and 20250331  -- and day <= DATE_FORMAT(DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 1 YEAR), '%Y%m%d') -- 后面有看同期全月还是截止同一天的指标，这里不卡
      )
group by 1,2,3,4,5,6,7,8

) a 
) rn 
where ranks = 1 
)



,act_user_shuxing as (
select distinct 
COALESCE(b.stage_name_month, '未知') as stage_name_month
,COALESCE(b.grade_name_month, '未知') as grade_name_month
,COALESCE(b.grade_stage_name_month, '未知') as grade_stage_name_month
,COALESCE(b.business_user_pay_status_statistics_month, '未知') as business_user_pay_status_statistics_month
,COALESCE(b.business_user_pay_status_business_month, '未知') as business_user_pay_status_business_month
,a.u_user
,a.day
,a.day_timestamp
-- ,a.new_user_attribution
,a.year
,a.is_first_active
from active_user a 
left join active_shuxing b 
on a.u_user = b.u_user and a.year = b.year and a.new_user_attribution = b.new_user_attribution 
)




,dingjin_act_user as (
select 
b.stage_name_month
,b.grade_name_month
,b.grade_stage_name_month
,b.business_user_pay_status_statistics_month
,b.business_user_pay_status_business_month
,case 
      when a.type is not null and a.type not in ('新用户','老用户') then a.type
      when b.business_user_pay_status_statistics_month = '新增' then '新增' 
      else '老未' 
      end as type
,a.u_user
,b.year
,b.u_user as act_user
,b.day
,b.day_timestamp
,b.is_first_active
from dingjin_user a 
right join act_user_shuxing b 
on a.u_user = b.u_user and a.year = b.year
group by 1,2,3,4,5,6,7,8,9,10,11,12
)



,dingjin_act_user1 as (
select
year,day,day_timestamp,u_user,act_user,is_first_active,type
from dingjin_act_user
where act_user is not null 

<parameter> 
and `stage_name_month` in ('${doris_increase_stage_name_day}')
</parameter>
<parameter> 
and `grade_name_month` in ('${doris_increase_grade_name_day}')
</parameter>
<parameter> 
and `grade_stage_name_month` in ('${doris_increase_grade_stage_name_day}')
</parameter>
<parameter> 
and `business_user_pay_status_statistics_month` in ('${doris_increase_business_user_pay_status_statistics_day}')
</parameter>
<parameter> 
and `business_user_pay_status_business_month` in ('${doris_increase_business_user_pay_status_business_day}')
</parameter>


group by year,day,day_timestamp,u_user,act_user,is_first_active,type
)


,zuhepin_user as (select
u_user
,paid_time_sk
,year
,is_first_pay
,business_gmv_attribution
,sum(amount) amount
from (
select *
,case when row_number() over (partition by business_gmv_attribution,u_user,year order by paid_time_sk) = 1  
      then 1 else 0 
end as is_first_pay -- 是否首次付费，过滤掉用户为空的排名
from (select 
u_user
,paid_time_sk
,year
,business_gmv_attribution
,sum(amount) as amount
from (select
u_user
,paid_time_sk
,left(paid_time_sk,4) as year
,business_gmv_attribution
,case when business_good_kind_name_level_1 = '组合品' then '主推品' else '非主推品' 
end as good_kind
,sum(sub_amount) amount
from dws.topic_order_detail
where u_user is NOT null and 
(
  (paid_time_sk between 20260302 and 20260331 and paid_time_sk <= DATE_FORMAT(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), '%Y%m%d')) 
  or paid_time_sk between 20250302 and 20250331 -- and paid_time_sk <= DATE_FORMAT(DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 1 YEAR), '%Y%m%d') -- 后面有看同期全月还是截止同一天的指标，这里不卡
)
and original_amount >= 39
and business_gmv_attribution in ('电销','商业化') 

group by 1,2,3,4,5
) a 

where u_user is not null 
<parameter> 
and `business_gmv_attribution` in ('${doris_increase_zuhepin_business_gmv_attribution}')
</parameter>
<parameter> 
and `good_kind` in ('${doris_increase_good_kind}')
</parameter>

group by 1,2,3,4

) b 
) rn 
group by 1,2,3,4,5
)





,dingjin_act_zuhepin_user as (select 
a.*,b.u_user as zuhe_user,b.amount,b.is_first_pay
from dingjin_act_user1 a 
left join zuhepin_user b 
on a.act_user = b.u_user and a.day = b.paid_time_sk and a.year = b.year 
where a.act_user is not null 

<parameter> 
and `type` in ('${doris_increase_type}')
</parameter>

)



,dingjin_act_zuhepin_user_cnt as (select 
day,case when type is null then '合计' else type end as type,act_users,first_act_users,zuhe_users,first_pay_users,zuhe_amount,
24_act_users,24_first_act_users,24_zuhe_users,24_first_pay_users,24_zuhe_amount,24_all_act_users,24_all_first_act_users,24_all_zuhe_users,24_all_first_pay_users,
24_all_zuhe_amount,dingjin_users,24_dingjin_users
from (
select 
-- day_timestamp
right(day,4) day
,count(distinct case when year = 2026 then u_user end) dingjin_users 
,count(distinct case when year = 2025 then u_user end) 24_dingjin_users
,a.type
,count(distinct case when a.year = 2026 then act_user end) act_users -- 活跃总人数
,count(distinct case when a.year = 2026 and is_first_active = 1 then act_user end) first_act_users -- 首次活跃人数
,count(distinct case when a.year = 2026 then zuhe_user end) zuhe_users -- 活跃且转组合总人数
,count(distinct case when a.year = 2026 and is_first_pay = 1 then zuhe_user end) first_pay_users -- 首次转组合人数
,sum(case when a.year = 2026 then amount else 0 end) zuhe_amount -- 活跃且转组合总金额

,count(distinct case when day <= DATE_FORMAT(DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 1 year), '%Y%m%d') then act_user end) 24_act_users -- 活跃总人数
,count(distinct case when day <= DATE_FORMAT(DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 1 year), '%Y%m%d') and is_first_active = 1 then act_user end) 24_first_act_users -- 首次活跃人数
,count(distinct case when day <= DATE_FORMAT(DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 1 year), '%Y%m%d') then zuhe_user end) 24_zuhe_users -- 活跃且转组合总人数
,count(distinct case when day <= DATE_FORMAT(DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 1 year), '%Y%m%d') and is_first_pay = 1 then zuhe_user end) 24_first_pay_users -- 首次转组合人数
,sum(case when day <= DATE_FORMAT(DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 1 year), '%Y%m%d') then amount else 0 end) 24_zuhe_amount -- 活跃且转组合总金额
,count(distinct case when a.year = 2025 then act_user end) 24_all_act_users -- 活跃总人数
,count(distinct case when a.year = 2025 and is_first_active = 1 then act_user end) 24_all_first_act_users -- 首次活跃人数
,count(distinct case when a.year = 2025 then zuhe_user end) 24_all_zuhe_users -- 活跃且转组合总人数
,count(distinct case when a.year = 2025 and is_first_pay = 1 then zuhe_user end) 24_all_first_pay_users -- 首次转组合人数
,sum(case when a.year = 2025 then amount else 0 end) 24_all_zuhe_amount -- 活跃且转组合总金额

from dingjin_act_zuhepin_user a 

group by 
  grouping sets(
  (right(day,4),a.type),
  (right(day,4))
  )
) a 

)




,dingjin_act_zuhepin_user_cnt2 as (select 
day
,dingjin_users -- 定金总人数
,act_users -- as `当日活跃人数`
,type
,sum(first_act_users) over(partition by type order by day) as cumulative_sum_actusers -- as `累计活跃人数`
,zuhe_users -- 当日转组合人数
,sum(first_pay_users) over(partition by type  order by day) as cumulative_sum_payusers -- as `累计活跃人数`
,zuhe_amount -- as `当日金额`
,sum(zuhe_amount) over(partition by type  order by day) as cumulative_sum_amount -- as `累计金额`

,24_dingjin_users
,24_act_users -- as `当日活跃人数`
,sum(24_first_act_users) over(partition by type  order by day) as 24_cumulative_sum_actusers -- as `累计活跃人数`
,24_zuhe_users -- 当日转组合人数
,sum(24_first_pay_users) over(partition by type  order by day) as 24_cumulative_sum_payusers -- as `累计活跃人数`
,24_zuhe_amount -- as `当日金额`
,sum(24_zuhe_amount) over(partition by type  order by day) as 24_cumulative_sum_amount -- as `累计金额`

,24_all_act_users
,sum(24_all_first_act_users) over(partition by type  order by day) as 24_all_cumulative_sum_actusers -- as `累计活跃人数`
,24_all_zuhe_users -- 当日转组合人数
,sum(24_all_first_pay_users) over(partition by type  order by day) as 24_all_cumulative_sum_payusers -- as `累计活跃人数`
,24_all_zuhe_amount -- as `当日金额`
,sum(24_all_zuhe_amount) over(partition by type  order by day) as 24_all_cumulative_sum_amount -- as `累计金额`

from dingjin_act_zuhepin_user_cnt 
) 



select day
,str_to_date(cast(CONCAT('2026', LPAD(day, 4, '0')) AS VARCHAR), '%Y%m%d') as date
,type
,COALESCE(dingjin_users, 0) as dingjin_users-- as `当日定金人数`
,COALESCE(act_users, 0) as act_users-- as `当日活跃人数`
,COALESCE(cumulative_sum_actusers, 0) as cumulative_sum_actusers -- 获取前一日累计值（按类别分区）
,COALESCE(zuhe_users, 0) as zuhe_users-- as `当日转组合人数`
,COALESCE(cumulative_sum_payusers, 0) as cumulative_sum_payusers -- 获取前一日累计值（按类别分区）
,COALESCE(zuhe_amount, 0) as zuhe_amount-- as `当日付费人数`
,COALESCE(cumulative_sum_amount, 0) as cumulative_sum_amount -- 获取前一日累计值（按类别分区）

,COALESCE(24_dingjin_users, 0) as 24_dingjin_users-- as `当日定金人数`
,COALESCE(24_act_users, 0) as 24_act_users-- as `当日活跃人数`
,COALESCE(24_cumulative_sum_actusers, 0) as 24_cumulative_sum_actusers -- 获取前一日累计值（按类别分区）
,COALESCE(24_zuhe_users, 0) as 24_zuhe_users-- as `当日转组合人数`
,COALESCE(24_cumulative_sum_payusers, 0) as 24_cumulative_sum_payusers -- 获取前一日累计值（按类别分区）
,COALESCE(24_zuhe_amount, 0) as 24_zuhe_amount-- as `当日付费人数`
,COALESCE(24_cumulative_sum_amount, 0) as 24_cumulative_sum_amount -- 获取前一日累计值（按类别分区）

,COALESCE(24_all_act_users, 0) as 24_all_act_users-- as `当日活跃人数`
,COALESCE(24_all_cumulative_sum_actusers, 0) as 24_all_cumulative_sum_actusers -- 获取前一日累计值（按类别分区）
,COALESCE(24_all_zuhe_users, 0) as 24_all_zuhe_users-- as `当日转组合人数`
,COALESCE(24_all_cumulative_sum_payusers, 0) as 24_all_cumulative_sum_payusers -- 获取前一日累计值（按类别分区）
,COALESCE(24_all_zuhe_amount, 0) as 24_all_zuhe_amount-- as `当日付费人数`
,COALESCE(24_all_cumulative_sum_amount, 0) as 24_all_cumulative_sum_amount -- 获取前一日累计值（按类别分区）

from dingjin_act_zuhepin_user_cnt2
where day is not null
