-- =====================================================
-- 资源位转化- 活动资源位看板底层表 tmp.meishihua_activity_operate_2025_middle_5
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
--   - 建表无 JOIN；来源于 tmp.meishihua_activity_operate_2025_middle_4 子查询（row_number 去重）

-- 【注意事项】
--   - 同tmp.meishihua_activity_operate_2025_middle_1
--
-- =====================================================

-- step1-5：创建临时的中间表1-5
<!-- drop table if exists tmp.meishihua_activity_operate_2025_middle_5 force; -->
create table tmp.meishihua_activity_operate_2025_middle_5 as 

with final_act_user_app_c_teg AS (
select 
u_user
,activity_id
,activity_name
,stage_name_day
,grade_name_day
,grade_stage_name_day
,business_user_pay_status_statistics_day
,business_user_pay_status_business_day
from ( 
  SELECT  u_user
         ,activity_id
         ,activity_name
         ,stage_name_day
         ,grade_name_day
         ,grade_stage_name_day
         ,business_user_pay_status_statistics_day
         ,business_user_pay_status_business_day
         ,row_number() over(partition by activity_id,u_user order by day) as ranks
  FROM tmp.meishihua_activity_operate_2025_middle_4
  ) a 
where ranks = 1 
group by u_user
,activity_id
,activity_name
,stage_name_day
,grade_name_day
,grade_stage_name_day
,business_user_pay_status_statistics_day
,business_user_pay_status_business_day
) 

select * from final_act_user_app_c_teg;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
