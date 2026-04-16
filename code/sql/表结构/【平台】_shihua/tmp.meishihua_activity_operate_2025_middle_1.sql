-- =====================================================
-- 资源位转化- 活动资源位看板底层表 tmp.meishihua_activity_operate_2025_middle_1
-- =====================================================
--
-- 【表粒度】
--   - 一个活动id一条数据，无分区字段
--
-- 【业务定位】
--   - 【归属】资源位转化 / 活动资源位看板底层表。
--   - 活动资源位看板底层表，活动配置位

-- 【统计口径】
--   - 活动资源位看板底层表

-- 【常用关联】
--   - 建表：activity_info join dw.dim_date b on b.day between a.start_day and a.end_day
--   - 下游 middle_2～middle_10 多按 activity_id、day 与本表对齐

-- 【注意事项】
--   - 更新频率 T+1
--   - 表更新顺序：
--     - tmp.meishihua_activity_operate_2025_middle_1
--     - tmp.meishihua_activity_operate_2025_middle_2
--     - tmp.meishihua_activity_operate_2025_middle_3
--     - tmp.meishihua_activity_operate_2025_middle_4
--     - tmp.meishihua_activity_operate_2025_middle_5
--     - tmp.meishihua_activity_operate_2025_middle_6
--     - tmp.meishihua_activity_operate_2025_middle_7
--     - tmp.meishihua_activity_operate_2025_middle_8
--     - tmp.meishihua_activity_operate_2025_middle_9
--     - tmp.meishihua_activity_operate_2025_middle_10
--     - tmp.meishihua_activity_operate_2025_middle_11

-- =====================================================

-- step1：创建临时的中间表，每天更新有效期内的全量活动数据
-- step1-1：创建临时的中间表1-1
<!-- drop table if exists tmp.meishihua_activity_operate_2025_middle_1 force; -->
create table tmp.meishihua_activity_operate_2025_middle_1 as 
-- # 活动期配置位。活动期与自定义活动创建规则：
-- 1.提前告知「活动期起止日期」、「活动期名称」、「活动期关键词」。如果两个活动期的活动期起止日期有交叉，必须有两个不一样的「活动期关键词」作为区分；
-- 2.活动的起止日期必须在「活动期起止日期」内；
-- 3.活动的名称必须包含「活动期关键词」。如果两个活动期的「活动期起止日期」有交叉，活动的名称必须只能包含一个「活动期关键词」作为区分。
with activity_info as (
select 
*
from (
select 
20250603 as start_day,20250622 as end_day,1 as activity_id,'暑促-蓄水活动（20250603-20250622）' as activity_name,'暑促' as keyword -- 通过关键词来抓取运营新建的自定义活动名称
union 
select 
20250625 as start_day,20250630 as end_day,2 as activity_id,'暑促-预热期（20250625-20250630）' as activity_name,'暑促' as keyword
union 
select 
20250701 as start_day,20250731 as end_day,3 as activity_id,'暑促-正式期（20250701-20250731）' as activity_name,'方案型商品' as keyword
union 
select 
20250801 as start_day,20250814 as end_day,4 as activity_id,'暑促-空窗期（20250801-20250814）' as activity_name,'方案型商品' as keyword -- 历史创建了活动，补充一个新的活动名称留存
union 
select 
20250812 as start_day,20250831 as end_day,5 as activity_id,'25暑期规划蓄水品（20250812-20250831）' as activity_name,'25暑期规划蓄水品' as keyword
union 
select 
20250815 as start_day,20250831 as end_day,6 as activity_id,'暑促-开学蓄力期（20250815-20250831）' as activity_name,'方案型商品' as keyword
union 
select 
20250901 as start_day,20250930 as end_day,7 as activity_id,'暑促-开学季（20250901-20250930）' as activity_name,'方案型商品' as keyword
union 
select 
20251014 as start_day,20251016 as end_day,8 as activity_id,'25双11-预热期（20251014-20251016）-仅资源位曝光+资源位点击是有效数据' as activity_name,'双11预热期' as keyword
union 
select 
20251017 as start_day,20251111 as end_day,9 as activity_id,'25双11-正式期（20251017-20251111）' as activity_name,'方案型商品' as keyword
union 
select 
20251010 as start_day,20251024 as end_day,10 as activity_id,'从小学物理（20251010-20251024）' as activity_name,'从小学物理' as keyword
union 
select 
20251121 as start_day,20251130 as end_day,11 as activity_id,'从小学物理（20251121-20251130）' as activity_name,'从小学物理' as keyword
union 
select 
20251127 as start_day,20251212 as end_day,12 as activity_id,'高中课程上新（20251127-20251212）' as activity_name,'高中课程上新' as keyword
union 
select 
20260114 as start_day,20260117 as end_day,13 as activity_id,'26寒促启元-预热期（20260114-20260117）' as activity_name,'寒促预热期' as keyword
union 
select 
20260117 as start_day,20260301 as end_day,14 as activity_id,'26寒促启元-正式期（20260117-20260301）' as activity_name,'方案型商品' as keyword
union 
select 
20260302 as start_day,20260331 as end_day,15 as activity_id,'202603开学季（20260302-20260331）' as activity_name,'方案型商品' as keyword


) a 
where start_day <= DATE_FORMAT(date_sub(current_date(), 1), '%Y%m%d') and end_day >= DATE_FORMAT(date_sub(current_date(), 1), '%Y%m%d') -- 只更新截止昨天已经开始且未结束的活动，历史数据存档

-- where activity_id = 12 -- 历史刷数，需要单个id单刷

)

,date_range as (SELECT
    activity_id,
    activity_name,
    b.day,  
    start_day,
    end_day,
    keyword
FROM activity_info a 
join dw.dim_date b on b.day between a.start_day and a.end_day
)

select * from date_range;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
