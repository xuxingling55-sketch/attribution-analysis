-- =====================================================
-- 看板名称：活动专题-202603开学季活动
-- 业务域：【平台】_shihua
-- 图表/组件：活动专题-202603开学季活动_4_实物赠品商品销量
-- 工具与位置：FineBI（自 `.cursor/code/sql/临时文件` 迁入）
-- 刷新周期：T+1
-- 维护人：meishihua
-- 关联指标：→ glossary/【平台】_shihua.md#
-- 主用表：→ code/sql/表结构/【平台】_shihua/
-- 最后同步自看板日期：20260302
-- ⚠️ 注意：
-- =====================================================

-- 帆软-数据准备-sql 
with sub_good_sk as (select sub_good_sk,sku_id from hive.dw.dim_sub_good
where sku_id in ('694ce6b9ac254299532c2e10')
group by 1,2
) -- sku_id 在订单表的映射



SELECT 
coalesce(paid_time_sk,'总计') as paid_time_sk
,count(DISTINCT case when sku_id = '68cbc8a55cfe8a206f76028b' then order_id end) as orders1 -- '双肩包+吧唧'
,count(DISTINCT case when sku_id = '68398584eddb5a873f0e4a1b' then order_id end) as orders2 -- '汉印S2错题打印机'
,count(DISTINCT case when sku_id = '68cbc86c227dff9fe8f14085' then order_id end) as orders3 -- '小度智能屏Mini'
,count(DISTINCT case when sku_id = '7fbe17e5-14d8-4f76-aa49-56b282e704f7' then order_id end) as orders4 -- '好习惯提分笔记本套装'
,count(DISTINCT order_id) as zuhe_orders -- '组合品'
from (SELECT *
from dws.topic_order_detail
where paid_time_sk BETWEEN 20260302 AND 20260331 and date(paid_time) <= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
and business_good_kind_name_level_1 = '组合品'

<parameter> 
and `business_gmv_attribution` in ('${doris_increase_zengpin_business_gmv_attribution}')
</parameter>
<parameter> 
and `stage_name_month` in ('${doris_increase_stage_name_day}')
</parameter>
<parameter> 
and `grade_name_month` in ('${doris_increase_grade_name_day}')
</parameter>
<parameter> 
and `grade_stage_name_month` in ('${doris_increase_grade_stage_name_day}')
</parameter>
<parameter> 
and `business_user_pay_status_statistics_month` in ('${doris_increase_business_user_pay_status_statistics_day}')
</parameter>
<parameter> 
and `business_user_pay_status_business_month` in ('${doris_increase_business_user_pay_status_business_day}')
</parameter>
) a 
join sub_good_sk b on a.sub_good_sk = b.sub_good_sk

GROUP BY 
grouping sets(
(paid_time_sk),
()
)
