-- =====================================================
-- 资源位转化- 活动资源位看板底层表 tmp.meishihua_activity_operate_2025_middle_8
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
--   - middle_7 派生维 a cross join（middle_7 分组 concat 的）b1、b2 生成笛卡尔组合

-- 【注意事项】
--   - 同tmp.meishihua_activity_operate_2025_middle_1
--
-- =====================================================

-- step1-8：创建临时的中间表1-8
drop table if exists tmp.meishihua_activity_operate_2025_middle_8 force;
<!-- create table tmp.meishihua_activity_operate_2025_middle_8 as  -->

with final_teg1 as (select  -- 获取所有不同的维度值，并生成它们的全部真实组合
a.day
,a.activity_id
,a.activity_name
,a.operation_position 
,substring_index(b1.col1,'--',1) as business_user_pay_status_statistics_activity
,substring_index(b1.col1,'--',-1) as business_user_pay_status_business_activity
,substring_index(b2.col2,'--',1) as grade_name_activity
,substring_index(substring_index(b2.col2,'--',2),'--',-1) as stage_name_activity
,substring_index(b2.col2,'--',-1) as grade_stage_name_activity
from (select 
day
,activity_id
,activity_name
,operation_position
from tmp.meishihua_activity_operate_2025_middle_7 
group by 1,2,3,4 ) a 
cross join (select concat(business_user_pay_status_statistics_activity,'--',business_user_pay_status_business_activity) as col1 from tmp.meishihua_activity_operate_2025_middle_7 group by 1 ) b1
cross join (select concat(grade_name_activity,'--',stage_name_activity,'--',grade_stage_name_activity) as col2 from tmp.meishihua_activity_operate_2025_middle_7 group by 1 ) b2
)


select * from final_teg1 ;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
