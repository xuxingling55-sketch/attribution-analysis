-- =====================================================
-- 资源位转化- 活动资源位看板底层表 tmp.meishihua_activity_operate_2025_middle_7
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
--   - middle_2 a join middle_4 c on a.day = c.day and a.get_entrance_user = c.u_user and a.activity_id = c.activity_id
--   - left join middle_3 b on a.operate_id = b.operate_id and a.activity_id = b.activity_id

-- 【注意事项】
--   - 同tmp.meishihua_activity_operate_2025_middle_1
--
-- =====================================================

-- step1-7：创建临时的中间表1-7
<!-- drop table if exists tmp.meishihua_activity_operate_2025_middle_7 force; -->
create table tmp.meishihua_activity_operate_2025_middle_7 as 

with process_operate as (select
a.day 
,a.activity_id
,a.activity_name
,COALESCE(case when b.operate_id is not null then concat(b.position_name,b.operate_type) 
    else a.position_name 
 end,'全部') as operation_position
,a.business_user_pay_status_statistics_activity
,a.business_user_pay_status_business_activity
,a.grade_name_activity
,a.stage_name_activity
,a.grade_stage_name_activity
,count(distinct get_entrance_user) as get_entrance_user
,count(distinct if(click_entrance_user>0,get_entrance_user,null)) as click_entrance_user
,count(distinct if(click_entrance_user>0 and enter_good_page_user>0,get_entrance_user,null)) as enter_good_page_user
,count(distinct if(click_entrance_user>0 and enter_good_page_user>0 and click_good_page_user>0,get_entrance_user,null)) as click_good_page_user
,count(distinct if(click_entrance_user>0 and enter_good_page_user>0 and click_good_page_user>0 and enter_order_page_user>0,get_entrance_user,null)) as enter_order_page_user
,count(distinct if(click_entrance_user>0 and enter_good_page_user>0 and click_good_page_user>0 and enter_order_page_user>0 and click_order_page_user>0,get_entrance_user,null)) as click_order_page_user
,count(distinct if(click_entrance_user>0 and enter_good_page_user>0 and click_good_page_user>0 and enter_order_page_user>0 and click_order_page_user>0 and paid_order_user>0,get_entrance_user,null)) as paid_order_user
,sum(if(click_entrance_user>0 and enter_good_page_user>0 and click_good_page_user>0 and enter_order_page_user>0 and click_order_page_user>0 and paid_order_user>0,amount,0)) as amount

from tmp.meishihua_activity_operate_2025_middle_2 a 

join tmp.meishihua_activity_operate_2025_middle_4 c on a.day = c.day and a.get_entrance_user = c.u_user and a.activity_id = c.activity_id

left join tmp.meishihua_activity_operate_2025_middle_3 b on a.operate_id = b.operate_id and a.activity_id = b.activity_id 

where (b.operate_id is not null or a.position_name is not null) 

group by 
 grouping sets (
 (a.day,a.activity_id,a.activity_name,case when b.operate_id is not null then concat(b.position_name,b.operate_type) else a.position_name end
    ,a.business_user_pay_status_statistics_activity,a.business_user_pay_status_business_activity,a.grade_name_activity,a.stage_name_activity,a.grade_stage_name_activity),
 (a.day,a.activity_id,a.activity_name,a.business_user_pay_status_statistics_activity,a.business_user_pay_status_business_activity,a.grade_name_activity,a.stage_name_activity,a.grade_stage_name_activity)
 )
)

select * from process_operate;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
