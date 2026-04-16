-- =====================================================
-- 资源位转化- 活动资源位看板底层表 tmp.meishihua_activity_operate_2025_middle_10
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
--   - middle_9 a left join（middle_6 union day_avg）b on a.day = b.day and a.activity_id = b.activity_id and 统计/年级等五维与 b 对齐（见建表 on 子句）

-- 【注意事项】
--   - 同tmp.meishihua_activity_operate_2025_middle_1
--
-- =====================================================

-- step1-10：创建临时的中间表最终
<!-- drop table if exists tmp.meishihua_activity_operate_2025_middle force; -->
create table tmp.meishihua_activity_operate_2025_middle as 

with final_data as (select 
a.operation_position
,a.business_user_pay_status_statistics_activity
,a.business_user_pay_status_business_activity
,a.grade_name_activity
,a.stage_name_activity
,a.grade_stage_name_activity
,a.get_entrance_user
,a.click_entrance_user
,a.enter_good_page_user
,a.click_good_page_user
,a.enter_order_page_user
,a.click_order_page_user
,a.paid_order_user
,a.amount
,b.active_uv
,a.activity_name
,a.day
,a.activity_id
from tmp.meishihua_activity_operate_2025_middle_9 a 

left join (select * from tmp.meishihua_activity_operate_2025_middle_6 
union 
select 
'day_avg' as day
,activity_id
,activity_name
,business_user_pay_status_statistics_activity
,business_user_pay_status_business_activity
,grade_name_activity
,stage_name_activity
,grade_stage_name_activity
,avg(active_uv) as active_uv
from tmp.meishihua_activity_operate_2025_middle_6
group by 1,2,3,4,5,6,7,8
) b on a.day=b.day and a.activity_id = b.activity_id 
        and a.business_user_pay_status_statistics_activity = b.business_user_pay_status_statistics_activity 
        and a.business_user_pay_status_business_activity = b.business_user_pay_status_business_activity 
        and a.grade_name_activity = b.grade_name_activity
        and a.stage_name_activity = b.stage_name_activity 
        and a.grade_stage_name_activity = b.grade_stage_name_activity 
)

select * from final_data ;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
