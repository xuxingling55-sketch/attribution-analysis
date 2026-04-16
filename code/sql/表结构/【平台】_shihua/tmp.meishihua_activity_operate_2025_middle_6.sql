-- =====================================================
-- 资源位转化- 活动资源位看板底层表 tmp.meishihua_activity_operate_2025_middle_6
-- =====================================================
--
-- 【表粒度】
--   见建表sql
--
-- 【业务定位】
--   - 【归属】资源位转化 / 活动资源位看板底层表。
--   - 同tmp.meishihua_activity_operate_2025_middle_1，过程处理表

-- 【统计口径】
--   - 同tmp.meishihua_activity_operate_2025_middle_1

-- 【常用关联】
--   - middle_4 a left join middle_2 b on a.day = b.day and a.u_user = b.get_entrance_user and a.activity_id = b.activity_id
--   - left join middle_5 c on a.u_user = c.u_user and a.activity_id = c.activity_id

-- 【注意事项】
--   - 同tmp.meishihua_activity_operate_2025_middle_1
--
-- =====================================================

-- step1-6：创建临时的中间表1-6
<!-- drop table if exists tmp.meishihua_activity_operate_2025_middle_6 force; -->
create table tmp.meishihua_activity_operate_2025_middle_6 as 

with final_act_user_app_c2 as (
select
a.day
,a.activity_id
,a.activity_name
,a.u_user
,max(case 
      when b.business_user_pay_status_statistics_activity is not null then b.business_user_pay_status_statistics_activity 
      else c.business_user_pay_status_statistics_day 
      end) over(partition by a.activity_id,a.u_user) as business_user_pay_status_statistics_activity
,max(case 
      when b.business_user_pay_status_business_activity is not null then b.business_user_pay_status_business_activity 
      else c.business_user_pay_status_business_day
      end) over(partition by a.activity_id,a.u_user) as business_user_pay_status_business_activity
,max(case 
      when b.grade_name_activity is not null then b.grade_name_activity 
      else c.grade_name_day
      end) over(partition by a.activity_id,a.u_user) as grade_name_activity
,max(case 
      when b.stage_name_activity is not null then b.stage_name_activity 
      else c.stage_name_day
      end) over(partition by a.activity_id,a.u_user) as stage_name_activity
,max(case 
      when b.grade_stage_name_activity is not null then b.grade_stage_name_activity 
      else c.grade_stage_name_day
      end) over(partition by a.activity_id,a.u_user) as grade_stage_name_activity
from tmp.meishihua_activity_operate_2025_middle_4 a 
left join tmp.meishihua_activity_operate_2025_middle_2 b on a.day = b.day and a.u_user = b.get_entrance_user and a.activity_id = b.activity_id 
left join tmp.meishihua_activity_operate_2025_middle_5 c on a.u_user = c.u_user and a.activity_id = c.activity_id 
)

select 
day
,activity_id
,activity_name
,business_user_pay_status_statistics_activity
,business_user_pay_status_business_activity
,grade_name_activity
,stage_name_activity
,grade_stage_name_activity
,count(distinct u_user) as active_uv
from final_act_user_app_c2
group by 1,2,3,4,5,6,7,8
;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
