-- =====================================================
-- 商品- 商品结构日表 tmp.meishihua_good_day
-- =====================================================
--
-- 【表粒度】
--   见建表sql，无分区字段
--
-- 【业务定位】
--   - 【归属】商品 / 商品结构日表。
--   - 商品结构日月报看板的底层表，来源于dws.topic_order_detail

-- 【统计口径】
--   见建表sql
--
-- 【常用关联】
--   - 建表无 JOIN；from tmp.meishihua_good_day_order_info a 单表聚合 group by

--
-- 【常用筛选条件】
--   见建表sql
--
-- 【注意事项】
--   - 更新频率 T+1
--
-- =====================================================

<!-- drop table if exists tmp.meishihua_good_day force; -->

create table tmp.meishihua_good_day as 


select 
date(a.paid_time) as paid_time
,a.paid_time_sk
,a.business_good_kind_name_level_1
,a.business_good_kind_name_level_2
,a.business_good_kind_name_level_3
,a.fix_good_year
,a.stage_name_day
,a.grade_name_day
,a.grade_stage_name_day 
,a.business_user_pay_status_statistics_day 
,a.business_user_pay_status_business_day 

,a.business_user_pay_status_business_month
-- 新增标签占位开始
,a.user_strategy_tag_day  
,a.user_strategy_eligibility_day  
,a.strategy_type 
,a.is_add_pad 
,a.big_vip_kind_day
,a.model_types
-- 新增标签占位结束

,a.business_gmv_attribution
,a.price_kind
,a.good_type_kind
,a.ceils_kind
,a.ceils
,a.buy_kind
,a.good_subject_cnt
,count(distinct order_id) orders 
,sum(sub_amount) as amount

from tmp.meishihua_good_day_order_info a
where u_user is not null 
and paid_time_sk is not null 
and original_amount >= 39

and date(paid_time) between '2023-01-01' and to_date(date(NOW())-1)
   


group by date(a.paid_time) 
,a.paid_time_sk
,a.business_good_kind_name_level_1
,a.business_good_kind_name_level_2
,a.business_good_kind_name_level_3
,a.fix_good_year
,a.stage_name_day
,a.grade_name_day
,a.grade_stage_name_day 
,a.business_user_pay_status_statistics_day 
,a.business_user_pay_status_business_day 
,a.business_user_pay_status_business_month
,a.user_strategy_tag_day  
,a.user_strategy_eligibility_day  
,a.strategy_type 
,a.is_add_pad 
,a.big_vip_kind_day
,a.model_types
,a.business_gmv_attribution
,a.price_kind
,a.good_type_kind
,a.ceils_kind
,a.ceils
,a.buy_kind
,a.good_subject_cnt;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 对应的帆软看板sql
SELECT 
'今年' as types
,paid_time
,paid_time_sk
,business_good_kind_name_level_1
,business_good_kind_name_level_2
,business_good_kind_name_level_3
,fix_good_year
,stage_name_day
,grade_name_day
,grade_stage_name_day
,business_user_pay_status_statistics_day
,business_user_pay_status_business_day
,business_user_pay_status_business_month

-- 新增标签占位开始
,user_strategy_tag_day  
,user_strategy_eligibility_day  
,strategy_type 
,is_add_pad 
,big_vip_kind_day
,model_types
,case when business_good_kind_name_level_1 = '组合品' then strategy_type else business_good_kind_name_level_1 end as fix_business_good_kind_name_level_1 -- 看板专用字段
-- 新增标签占位结束

,business_gmv_attribution
,price_kind
,buy_kind
,good_type_kind
,ceils_kind
,ceils
,good_subject_cnt
,orders
,amount
,year(paid_time) as year
from hive.tmp.meishihua_good_day
where paid_time between '${doris_begin_date}' and '${doris_end_date}'

union 

SELECT 
'去年' as types
,paid_time + INTERVAL 1 year as paid_time
,CAST(DATE_FORMAT(paid_time + INTERVAL 1 YEAR, '%Y%m%d') AS UNSIGNED) as paid_time_sk
,business_good_kind_name_level_1
,business_good_kind_name_level_2
,business_good_kind_name_level_3
,fix_good_year
,stage_name_day
,grade_name_day
,grade_stage_name_day
,business_user_pay_status_statistics_day
,business_user_pay_status_business_day
,business_user_pay_status_business_month

-- 新增标签占位开始
,user_strategy_tag_day  
,user_strategy_eligibility_day  
,strategy_type 
,is_add_pad 
,big_vip_kind_day
,model_types
,case when business_good_kind_name_level_1 = '组合品' then strategy_type else business_good_kind_name_level_1 end as fix_business_good_kind_name_level_1 -- 看板专用字段
-- 新增标签占位结束

,business_gmv_attribution
,price_kind
,buy_kind
,good_type_kind
,ceils_kind
,ceils
,good_subject_cnt
,orders
,amount
,year(paid_time) as year
from hive.tmp.meishihua_good_day
where paid_time between '${doris_begin_date}' +INTERVAL -1 year and '${doris_end_date}' +INTERVAL -1 year


