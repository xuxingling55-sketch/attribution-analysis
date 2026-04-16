-- =====================================================
-- 看板名称：目标商品分层表
-- 业务域：【平台】_shihua
-- 图表/组件：目标商品分层表_1_分层
-- 工具与位置：FineBI（自 `.cursor/code/sql/临时文件` 迁入）
-- 刷新周期：T+1
-- 维护人：meishihua
-- 关联指标：→ glossary/【平台】_shihua.md#
-- 主用表：→ code/sql/表结构/【平台】_shihua/
-- 最后同步自看板日期：2026
-- ⚠️ 注意：
-- =====================================================

-- 帆软-数据准备-sql 
with order_info as (select 
stage_name_day -- 日用户学段
,grade_name_day -- 日用户年级
,grade_stage_name_day -- 日用户年级段
,business_user_pay_status_statistics_day -- 日统计分层
,business_user_pay_status_business_day -- 日业务分层
,grade_name_month -- 月用户学段
,stage_name_month -- 月用户年级
,grade_stage_name_month -- 月用户年级段
,business_user_pay_status_statistics_month --  月统计分层
,business_user_pay_status_business_month --  月业务分层
,business_gmv_attribution -- gmv归属
,business_good_kind_name_level_1
,business_good_kind_name_level_2
,business_good_kind_name_level_3
,subject_name
,stage_name
,good_name
,price_kind
,fix_good_year 
,paid_time
,paid_time_sk
,add_time_day
,a.order_id
,u_user
,sub_amount
,good_subject_cnt
,order_amount
,original_amount
,buy_kind
,is_zuhe
,ceils
,ceils_kind
,good_type_kind -- 策略分层-历史商品的商品分类标签
,b.type
,b.is_zaiqi_type
,b.max_is_zaiqi_type
,b.is_zaiqi_all 
,b.max_is_zaiqi
,b.zaiqi_all_info
,b.is_subject
,b.is_zaiqi_subject
,b.max_is_zaiqi_subject
,b.zaiqi_subject_info
from hive.tmp.meishihua_good_day_order_info a   -- 底层表不限制，原因是统计分层等标签没限制，追溯历史订单进行归类时如果限制了就会对不上
left join hive.tmp.meishihua_good_day_historyordertegs b on a.order_id = b.order_id
)

,new_orders as (
select
paid_time
,paid_time_sk
,order_id
,u_user
,is_zuhe
,good_type_kind
,buy_kind
,sum(sub_amount) as amount
from order_info 
where u_user is not null 
and paid_time_sk is not null 
and original_amount >= 39
group by paid_time
,paid_time_sk
,order_id
,u_user
,is_zuhe
,good_type_kind
,buy_kind
)


,orders as (select * from 
(select *
,row_number() over(partition by u_user,buy_kind order by paid_time) as ranks
from order_info 
where date(paid_time) between '${doris_paid_begin}' and '${doris_paid_end}' -- 动态参数
) n
where ranks = 1 
)


select 
stage_name_day
,grade_name_day
,grade_stage_name_day
,business_user_pay_status_statistics_day
,business_user_pay_status_business_day
,business_gmv_attribution
,buy_kind
,case 
    when type is not null then type 
    when business_user_pay_status_statistics_month not in ('新增','老未') then '20160916前商品'
    when business_user_pay_status_statistics_month is not null then business_user_pay_status_statistics_month
    else '月统计分层标签缺失' 
    end as old_type
,business_user_pay_status_statistics_month
,count(distinct u_user) as users
from orders
group by stage_name_day
,grade_name_day
,grade_stage_name_day
,business_user_pay_status_statistics_day
,business_user_pay_status_business_day
,business_gmv_attribution
,buy_kind
,case 
    when type is not null then type 
    when business_user_pay_status_statistics_month not in ('新增','老未') then '20160916前商品'
    when business_user_pay_status_statistics_month is not null then business_user_pay_status_statistics_month
    else '月统计分层标签缺失' 
    end 
,business_user_pay_status_statistics_month
