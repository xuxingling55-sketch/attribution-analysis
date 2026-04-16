-- =====================================================
-- 资源位转化- 活动资源位看板底层表 tmp.meishihua_activity_operate_2025_middle_3
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
--   - dw.dim_operate a join tmp.meishihua_activity_operate_2025_middle_1 b on date_format(a.start_time,'%Y%m%d') = b.day（另有 activity_name、日期区间等条件见建表 where）
--   - course_shop.treasure_card join middle_1 b on date_format(a.effective_start_time,'%Y%m%d') = b.day
--   - 末段：operate a join (select activity_id from middle_1 group by activity_id) b on a.activity_id = b.activity_id

-- 【注意事项】
--   - 同tmp.meishihua_activity_operate_2025_middle_1
--
-- =====================================================

-- step1-3：创建临时的中间表1-3
<!-- drop table if exists tmp.meishihua_activity_operate_2025_middle_3 force; -->
create table tmp.meishihua_activity_operate_2025_middle_3 as 

with operate as (
select 
case when position_name regexp '-宝藏页' then '宝藏页'
      else position_name end as position_name
,case when position_name regexp '-宝藏页' then 'banner'
      when position_name regexp '通知' then ''
      else operate_type end as operate_type
,operate_id
,b.activity_id 
,b.activity_name
from dw.dim_operate a 
join tmp.meishihua_activity_operate_2025_middle_1 b on DATE_FORMAT(a.start_time, '%Y%m%d') = b.day  
where department_name regexp '商业化|市场策略'
and a.activity_name REGEXP b.keyword 
and DATE_FORMAT(a.start_time, '%Y%m%d') >= b.start_day and DATE_FORMAT(a.start_time, '%Y%m%d') <= b.end_day 
and DATE_FORMAT(start_time, '%Y%m%d') <= DATE_FORMAT(date_sub(current_date(), 1), '%Y%m%d')
group by 1,2,3,4,5

union 

select 
'' as position_name
,'发现页卡片' as operate_type
,id
,b.activity_id
,b.activity_name
from course_shop.treasure_card a 
join tmp.meishihua_activity_operate_2025_middle_1 b on DATE_FORMAT(a.effective_start_time, '%Y%m%d') = b.day  
WHERE user_attribution = 'c' AND status = '上线' AND is_deleted = 'false' AND application_department regexp '商业化|市场策略' 
  and a.activity_name REGEXP b.keyword 
  and DATE_FORMAT(effective_start_time, '%Y%m%d')  >= b.start_day and DATE_FORMAT(effective_start_time, '%Y%m%d') <= b.end_day 
	and DATE_FORMAT(effective_start_time, '%Y%m%d') <= DATE_FORMAT(date_sub(current_date(), 1), '%Y%m%d')
group by 1,2,3,4,5

union 

select 
case when position_name regexp '-宝藏页' then '宝藏页'
      else position_name end as position_name
,case when position_name regexp '-宝藏页' then 'banner'
      when position_name regexp '通知' then ''
      else operate_type end as operate_type
,operate_id
,10 as activity_id
,'从小学物理（20251010-20251024）' as activity_name
from dw.dim_operate a 
where activity_id = '4a83f08d-da8f-480c-bea2-b758f8c532db' -- 从小学物理第一期特殊处理,因为这个活动在第二期的时候更改了活动展示起止日期，追溯不到了，另外活动创建部门不是市场策略，写死

union 

select 
'' as position_name
,'发现页卡片' as operate_type
,id
,10 as activity_id
,'从小学物理（20251010-20251024）' as activity_name
from course_shop.treasure_card 
WHERE activity_id = '4a83f08d-da8f-480c-bea2-b758f8c532db' -- 从小学物理第一期特殊处理,因为这个活动在第二期的时候更改了活动展示起止日期，追溯不到了，另外活动创建部门不是市场策略，写死
group by 1,2,3,4,5

union 

select 
case when position_name regexp '-宝藏页' then '宝藏页'
      else position_name end as position_name
,case when position_name regexp '-宝藏页' then 'banner'
      when position_name regexp '通知' then ''
      else operate_type end as operate_type
,operate_id
,11 as activity_id
,'从小学物理（20251121-20251130）' as activity_name
from dw.dim_operate a 
where activity_id = '4a83f08d-da8f-480c-bea2-b758f8c532db' -- 从小学物理第二期特殊处理,因为这个活动创建部门不是市场策略，写死

union 

select 
'' as position_name
,'发现页卡片' as operate_type
,id
,11 as activity_id
,'从小学物理（20251121-20251130）' as activity_name
from course_shop.treasure_card 
WHERE activity_id = '4a83f08d-da8f-480c-bea2-b758f8c532db' -- 从小学物理第二期特殊处理,因为这个活动创建部门不是市场策略，写死
group by 1,2,3,4,5
)

select a.* from operate a 
join (select activity_id from tmp.meishihua_activity_operate_2025_middle_1 group by activity_id) b on a.activity_id = b.activity_id;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
