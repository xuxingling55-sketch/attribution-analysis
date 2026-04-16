-- =====================================================
-- 学科- 学科底层维日表 tmp.meishihua_product_kind_day
-- =====================================================
--
-- 【表粒度】
--   见建表sql，无分区字段
--
-- 【业务定位】
--   - 【归属】学科 / 学科底层维日表。
--   - 学科底层维表看板的底层表，来源于dws.topic_order_detail

-- 【统计口径】
--   见建表sql
--
-- 【常用关联】
--   - left join peiyou_sku_names b on a.order_id = b.order_id（主表 a = tmp.meishihua_good_day_order_info）

--
-- 【常用筛选条件】
--   见建表sql
--
-- 【注意事项】
--   - 更新频率 T+1
--
-- =====================================================


<!-- drop table if exists tmp.meishihua_product_kind_day force; -->

create table tmp.meishihua_product_kind_day as 


with peiyou_sku_names as (select order_id
,case 
    when group_concat(distinct sku_name) regexp '重难点' and group_concat(distinct sku_name) not regexp '一轮复习|二轮复习|真题精讲' then '重难点培优课'
    when group_concat(distinct sku_name) regexp '一轮复习' and group_concat(distinct sku_name) not regexp '重难点|二轮复习|真题精讲' then '一轮复习培优课'
    when group_concat(distinct sku_name) regexp '二轮复习' and group_concat(distinct sku_name) not regexp '重难点|一轮复习|真题精讲' then '二轮复习培优课'
    when group_concat(distinct sku_name) regexp '真题精讲' and group_concat(distinct sku_name) not regexp '重难点|一轮复习|二轮复习' then '真题精讲培优课'
    else '其它'
    end as peiyou_kind
from dws.topic_order_detail 
where paid_time_sk >= 20230101 
and good_kind_name_level_2 = '培优课' 
and good_subject_cnt = 1
and kind REGEXP 'specialCourse|SpecialCourse'
and sku_name regexp '重难点|一轮复习|二轮复习|真题精讲'
and stage_name = '高中'
group by 1
)


select 
date(paid_time) as paid_time
,paid_time_sk
,product_kind -- 产品系列
,subjects_kind 
,stage_name_day
,grade_name_day
,grade_stage_name_day 
,business_user_pay_status_statistics_day 
,business_user_pay_status_business_day 
,business_gmv_attribution
,fix_good_year
,coalesce(peiyou_kind,'其它') as peiyou_kind
,coalesce(subject_name,'整体') as subject_name
,coalesce(stage_name,'整体') as stage_name
,count(distinct a.order_id) orders 
,sum(sub_amount) as amount

from tmp.meishihua_good_day_order_info a 
left join peiyou_sku_names b on a.order_id = b.order_id 

where u_user is not null 
and paid_time_sk is not null 
and original_amount >= 39

and date(paid_time) between '2023-01-01' and to_date(date(NOW())-1)

group by 
grouping sets (
  (
  date(paid_time)
  ,paid_time_sk
  ,product_kind -- 产品系列
  ,subjects_kind 
  ,stage_name_day
  ,grade_name_day
  ,grade_stage_name_day 
  ,business_user_pay_status_statistics_day 
  ,business_user_pay_status_business_day 
  ,business_gmv_attribution
  ,fix_good_year
  ,coalesce(peiyou_kind,'其它')
  ,subject_name
  ,stage_name
  ),
  (
  date(paid_time)
  ,paid_time_sk
  ,product_kind -- 产品系列
  ,subjects_kind 
  ,stage_name_day
  ,grade_name_day
  ,grade_stage_name_day 
  ,business_user_pay_status_statistics_day 
  ,business_user_pay_status_business_day 
  ,business_gmv_attribution
  ,fix_good_year
  ,coalesce(peiyou_kind,'其它')
  ),
  (
  date(paid_time)
  ,paid_time_sk
  ,product_kind -- 产品系列
  ,subjects_kind 
  ,stage_name_day
  ,grade_name_day
  ,grade_stage_name_day 
  ,business_user_pay_status_statistics_day 
  ,business_user_pay_status_business_day 
  ,business_gmv_attribution
  ,fix_good_year
  ,coalesce(peiyou_kind,'其它')
  ,stage_name
  ),
  (
  date(paid_time)
  ,paid_time_sk
  ,product_kind -- 产品系列
  ,subjects_kind 
  ,stage_name_day
  ,grade_name_day
  ,grade_stage_name_day 
  ,business_user_pay_status_statistics_day 
  ,business_user_pay_status_business_day 
  ,business_gmv_attribution
  ,fix_good_year
  ,coalesce(peiyou_kind,'其它')
  ,subject_name
  )
)


;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
