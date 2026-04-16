-- =====================================================
-- 资源位转化- 活动资源位看板底层表 tmp.meishihua_activity_operate_2025_middle_4
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
--   - aws.business_active_user_last_14_day a join tmp.meishihua_activity_operate_2025_middle_1 b on a.day = b.day（且 a.day between b.start_day and b.end_day）

-- 【注意事项】
--   - 同tmp.meishihua_activity_operate_2025_middle_1
--
-- =====================================================

-- step1-4：创建临时的中间表1-4
<!-- drop table if exists tmp.meishihua_activity_operate_2025_middle_4 force; -->
create table tmp.meishihua_activity_operate_2025_middle_4 as 

-- APP C端活跃
with final_act_user_app_c AS ( 
SELECT  a.u_user
       ,a.day
       ,b.activity_id
       ,b.activity_name
       ,stage_name_day
       ,grade_name_day
       ,grade_stage_name_day
       ,business_user_pay_status_statistics_day
       ,business_user_pay_status_business_day
FROM aws.business_active_user_last_14_day a 
join tmp.meishihua_activity_operate_2025_middle_1 b on a.day = b.day  
where a.day >= b.start_day and a.day <= b.end_day 
  and a.day <= DATE_FORMAT(date_sub(current_date(), 1), '%Y%m%d')

GROUP BY 1,2,3,4,5,6,7,8,9
)

select * from final_act_user_app_c;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql