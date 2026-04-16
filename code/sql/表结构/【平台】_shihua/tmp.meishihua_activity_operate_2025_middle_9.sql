-- =====================================================
-- 资源位转化- 活动资源位看板底层表 tmp.meishihua_activity_operate_2025_middle_9
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
--   - middle_8 派生子查询 a left join middle_7 派生子查询 b on a.day = b.day and a.activity_id = b.activity_id and a.activity_name = b.activity_name and a.operation_position = b.operation_position and 分层维度五字段分别相等（见建表 on 子句）

-- 【注意事项】
--   - 同tmp.meishihua_activity_operate_2025_middle_1
--
-- =====================================================

-- step1-9：创建临时的中间表1-9
<!-- drop table if exists tmp.meishihua_activity_operate_2025_middle_9 force; -->
create table tmp.meishihua_activity_operate_2025_middle_9 as 

with final_teg2 as (
select 
a.operation_position
,a.business_user_pay_status_statistics_activity
,a.business_user_pay_status_business_activity
,a.grade_name_activity
,a.stage_name_activity
,a.grade_stage_name_activity
,b.get_entrance_user
,b.click_entrance_user
,b.enter_good_page_user
,b.click_good_page_user
,b.enter_order_page_user
,b.click_order_page_user
,b.paid_order_user
,b.amount
,a.activity_name
,a.day
,a.activity_id
from (select * from tmp.meishihua_activity_operate_2025_middle_8
union 
select 
'day_avg' as day
,activity_id
,activity_name
,operation_position
,business_user_pay_status_statistics_activity
,business_user_pay_status_business_activity
,grade_name_activity
,stage_name_activity
,grade_stage_name_activity
from tmp.meishihua_activity_operate_2025_middle_8 
GROUP by 1,2,3,4,5,6,7,8,9
) a 

left join (select * from tmp.meishihua_activity_operate_2025_middle_7 
union 
select 
'day_avg' as day
,activity_id
,activity_name
,operation_position
,business_user_pay_status_statistics_activity
,business_user_pay_status_business_activity
,grade_name_activity
,stage_name_activity
,grade_stage_name_activity
,avg(get_entrance_user) as get_entrance_user
,avg(click_entrance_user) as click_entrance_user
,avg(enter_good_page_user) as enter_good_page_user
,avg(click_good_page_user) as click_good_page_user
,avg(enter_order_page_user) as enter_order_page_user
,avg(click_order_page_user) as click_order_page_user
,avg(paid_order_user) as paid_order_user
,avg(amount) as amount
from tmp.meishihua_activity_operate_2025_middle_7
GROUP by 1,2,3,4,5,6,7,8,9
) b on a.day = b.day and a.activity_id = b.activity_id and a.activity_name = b.activity_name and a.operation_position = b.operation_position 
      and a.business_user_pay_status_statistics_activity = b.business_user_pay_status_statistics_activity 
      and a.business_user_pay_status_business_activity = b.business_user_pay_status_business_activity 
      and a.grade_name_activity = b.grade_name_activity 
      and a.stage_name_activity = b.stage_name_activity 
      and a.grade_stage_name_activity = b.grade_stage_name_activity 
)


select * from final_teg2;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
