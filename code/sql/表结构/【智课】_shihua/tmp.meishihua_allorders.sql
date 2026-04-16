-- =====================================================
-- 订单- 全量入校订单表 tmp.meishihua_allorders
-- =====================================================
--
-- 【表粒度】
--   Hive CTAS：`create table tmp.meishihua_allorders -- 全量入校订单 as`（正文约第 30 行起）+ 多层嵌套 SELECT / UNION；结果行粒度与最外层 `row_number() over(ORDER BY onion_order_id,id)` 及内层去重逻辑一致，宽字段含义以 SELECT 列表别名与行内注释为准
--
-- 【业务定位】
--   - 知识库归类：订单- 全量入校订单表。
--   - 入校子订单明细合并宽表；UNION 渠道入口订单与 go_channel_order 等，统一商品线与金额口径
--
-- 【统计口径】
--   - 聚合维度、去重规则、CASE 映射（商品线/活动/区域等）均在下方 SQL 中体现，改口径需全文排查
--   - 若脚本依赖 `tmp.meishihua_allorders`，商品线与金额口径应与该表文档头【汇总关系】保持一致
--
-- 【汇总关系】
--   - 上游（脚本内显式 FROM/JOIN，节选）：`channel.business_order`, `channel.business_order_refund_extra_info`, `channel.entry_business_order`, `channel.entry_offline_order`, `channel.entry_offline_order_item`, `channel.material_order`, `dw.dim_region`, `dw.dim_school`, `go_channel_order.order_info`, `go_channel_order.order_refund_info`
--   - 下游：智课看板、临时分析、`tmp.meishihua_*` 派生表等（以调度与引用脚本为准）
--
-- 【常用关联】
--   - 按 `onion_order_id`、`user_id`、`agency_id`、`school_id`、`class_ref` 与维表/事实表 JOIN；分区键与业务日期字段对齐后再聚合
--   - onion_order_id与dw.fact_order、dws.topic_order_detail的order_id对齐
--
-- 【常用筛选条件】
--   - 分区键区间；is_deleted / is_test；业务状态、时间范围；代理商/学校/用户 id 类筛选
--
-- 【注意事项】
--   - 以 LOCATION、库表名与调度任务为准；改字段或口径需同步下游 SQL 与看板
--   - 文档约定：**part1** ＝本文件顶部 DDL 注释块（至 `create table` 之前）；**part3** ＝文末「枚举值（派生/标签列，便于与 part1 对照）」与「枚举值」两节。同目录其它 `*.sql` 表结构脚注中的 part1/part3 与此对应
--
-- =====================================================
create table tmp.meishihua_allorders -- 全量入校订单
as

select * ,row_number() over(ORDER BY onion_order_id,id) new_id
from (
SELECT 
id,--订单表主ID唯一值
onion_order_id,--订单ID
sequence_id,--子订单ID
good_id,--商品id
good_name,--商品名称
'线上付款' as from,--订单来源
kind_name,--商品类型
null as buy_count,--商品数量
stage,--学段
subject,--学科
class_ref,--班级ID
class_name,--班级名称
class_type,--班级类型
is_test,--是否测试订单
status,--支付状态
region_code,--区域编码
(case when user_type='student' then user_id end) student_id,--付费学生ID
(case when user_type='teacher' then user_id end) teacher_id,--付费教师ID
(case when (agency_id is not null and  agency_id<>'') then '渠道回款'
      when  pad_sequence_id is not null then '渠道回款'
      else '非渠道回款'
      end) sequence_id_type,--子订单归属（不准确，废弃字段，使用本表下面修正后的agency_id 是否为null来判断是否是渠道回款）
paid_time,--付款时间
pad_type,--子订单类型
0 as refund_amount,--退款（对应GMV）
(sales_back_amount_of_com-finalcost) finalsales_back_amount_of_com,--区域口径回款
(reality_amount-cost1) reality_amount,--公司口径回款
sub_order_pay_amount,--GMV口径回款
sub_order_pay_amount as sub_order_pay_amount1,--区域口径-GMV回款
finalcost,--平板成本
--cost1,--区域成本
super_vise,--区总姓名
real_province as province ,--省
real_city as city,--市
real_area as area,--区
(case when (agency_id is null or agency_id='') then pad_agency_id else agency_id end) agency_id,--代理商ID
(case when (agency_id is null or agency_id='') then pad_agency_name else agency_name end) agency_name,--代理商名称
(case when (agency_id is null or agency_id='') then pad_agency_type else agency_type end) agency_type,--direct:直营代理商,agent:合作代理商
school_id,--学校ID
school_name,--学校名称

activity_type,
case
     when activity_type = 'buchajia' then '补差购买平板'
     when activity_type = 'activityRepurchase' then '活动续购'
     when activity_type = 'repurchase' then '普通续购'
     when activity_type = 'highActivity' then '高考版大会员续购'
     when activity_type = 'firstBuy' then '首购'
     when activity_type = 'diffPrice' then '补差'
     when activity_type = 'mulChild' then '多孩续购'
     when activity_type = 'hisMem' then '历史大会员续购'
     when activity_type = 'highHoardCourse' then '高中囤课续购'
     when activity_type = 'padAddPur' then '平板加购续购'
     ELSE ''
     END AS activity_type_name,
null as refund_time,
original_amount,
sub_order_amount_to_be_dsistributed,
distribution_amount_of_agents,
sales_back_amount_of_com,
distribution_amount_of_thirdparty,
kind
      
from (
SELECT DISTINCT
t1.*,
(case when t2.onion_order_id is not null and t1.kind in ('cost', 'pad') then t1.sequence_id end) pad_sequence_id,--平板子订单ID
(case when t2.onion_order_id is not null and t1.kind in ('cost', 'pad') then t2.agency_id end) pad_agency_id,--渠道平板子订单代理商ID
(case when t2.onion_order_id is not null and t1.kind in ('cost', 'pad') then t2.agency_name end) pad_agency_name,--渠道平板子订单代理商ID
(case when t2.onion_order_id is not null and t1.kind in ('cost', 'pad') then t2.agency_type end) pad_agency_type--渠道平板子订单代理商ID

from
(SELECT DISTINCT *, 
(case when kind  in ('cost', 'pad') then '平板' else '非平板' end) pad_type,--子订单类型
(case when kind not in ('cost','pad','virtualPad') then cost -- 新增虚拟平板成本
      when kind = 'cost' then 50 -- 管控费
      when date(paid_time) < '2026-04-01' and kind = 'virtualPad' then 1000 -- 虚拟平板原成本
      when date(paid_time) >= '2026-04-01' and kind = 'virtualPad' then 1300 -- 虚拟平板新成本
      when cost=1943.00 then 1943
      when cost=970.00 then 1050
      when cost=1100.00 then 1050
      when cost=736.00 then 1000
      when cost=1417.00 then 1500
      when date(paid_time) < '2026-02-15' and cost=760.00 then 900 -- Q20原成本
      when date(paid_time) >= '2026-02-15' and cost=760.00 then 1300 -- Q20新成本
      when cost=1200.00 then 1150
      when cost=1150.00 then 1250
      when date(paid_time) < '2026-02-15' and cost=890.00 then 1400 -- P30原成本
      when date(paid_time) >= '2026-02-15' and cost=890.00 then 1500 -- P30新成本
      end) as finalcost,-- 区域口径成本(20260401更新)
  (case when kind<>'cost' then cost else 50 end) cost1--公司口径成本
  
from (
	select distinct a.*,--必须要去重
(case when b.province is not null then b.province
      when c.province is not null then c.province
      when d.province is not null then d.province
      else a.province end) real_province,
(case when b.city is not null then b.city
      when c.city is not null then c.city
      else a.city end) real_city,
(case when b.area is not null then b.area
      else a.area end) real_area
from (select * from go_channel_order.order_info where is_deleted is false ) a
LEFT JOIN dw.dim_region b
on a.region_code=b.area_code
LEFT JOIN dw.dim_region c
on a.region_code=c.city_code
LEFT JOIN dw.dim_region d
on a.region_code=d.province_code
)

) t1
left join (
SELECT DISTINCT (case when (agency_id is not null and agency_id<>'' and agency_id<>'0' ) then onion_order_id end) onion_order_id,--有代理商的订单ID
(case when (agency_id is not null and agency_id<>'' and agency_id<>'0'  ) then agency_id end) agency_id,
(case when (agency_id is not null and agency_id<>'' and agency_id<>'0' ) then agency_name end) agency_name,
(case when (agency_id is not null and agency_id<>'' and agency_id<>'0' ) then agency_type end) agency_type,
row_number() over(partition by onion_order_id order by agency_id desc) rows --还原平板子订单所属代理商时，如果一个订单有2个代理商，则取代理商ID最大的一个
from go_channel_order.order_info
where 
--(to_date(paid_time) BETWEEN '${begin_time}' and '${end_time}') 
 is_deleted is false
--and locate('测试', school_name)=0 
--and locate('测试', agency_name)=0 
having rows=1
) t2
on t1.onion_order_id=t2.onion_order_id)

UNION ALL

SELECT 
order_info_pkey_id as id,--订单表主ID唯一值
onion_order_id,--订单ID
sequence_id,--子订单ID
good_id,--商品id
good_name,--商品名称
'线上退款' as from,--订单来源
kind_name,--商品类型
null as buy_count,--商品数量
stage,--学段
subject,--学科
class_ref,--班级ID
class_name,--班级名称
class_type,--班级类型
is_test,--是否测试订单
status,--支付状态
region_code,--区域编码
(case when user_type='student' then user_id end) student_id,--付费学生ID
(case when user_type='teacher' then user_id end) teacher_id,--付费教师ID
(case when  (agency_id is not null and  agency_id<>'') then '渠道回款'
      when  pad_sequence_id is not null then '渠道回款'
      else '非渠道回款'
      end) sequence_id_type,--子订单归属
refund_time paid_time,--付款时间(退款时间)
pad_type,--子订单类型
refund_amount,--退款（对应GMV）
(0-(company_refund_amount-finalcost)) finalsales_back_amount_of_com,--区域口径回款
(0-(refund_reality_amount-cost1)) reality_amount,--公司口径回款
0 as sub_order_pay_amount,--GMV口径回款
0 as sub_order_pay_amount1,--区域口径-GMV回款
0-finalcost finalcost,--平板成本
super_vise,--区总姓名
province,--省
city,--市
area,--区
(case when (agency_id is null or agency_id='') then pad_agency_id else agency_id end) agency_id,--代理商ID
(case when (agency_id is null or agency_id='') then pad_agency_name else agency_name end) agency_name,--代理商名称
(case when (agency_id is null or agency_id='') then pad_agency_type else agency_type end) agency_type,--direct:直营代理商,agent:合作代理商
school_id,--学校ID
school_name,--学校名称

activity_type,
case
     when activity_type = 'buchajia' then '补差购买平板'
     when activity_type = 'activityRepurchase' then '活动续购'
     when activity_type = 'repurchase' then '普通续购'
     when activity_type = 'highActivity' then '高考版大会员续购'
     when activity_type = 'firstBuy' then '首购'
     when activity_type = 'diffPrice' then '补差'
     when activity_type = 'mulChild' then '多孩续购'
     when activity_type = 'hisMem' then '历史大会员续购'
     when activity_type = 'highHoardCourse' then '高中囤课续购'
     when activity_type = 'padAddPur' then '平板加购续购'
     ELSE ''
     END AS activity_type_name,
refund_time,
original_amount,
0 - (agency_refund_amount + company_refund_amount) as sub_order_amount_to_be_dsistributed,
0 - agency_refund_amount as distribution_amount_of_agents,
0 - company_refund_amount as sales_back_amount_of_com,
0 - refund_amount_of_thirdparty as distribution_amount_of_thirdparty,
kind

from (

SELECT DISTINCT
t1.*,


(case when t2.onion_order_id is not null and t1.kind in ('cost', 'pad') then t1.sequence_id end) pad_sequence_id,--渠道平板子订单ID
(case when t2.onion_order_id is not null and t1.kind in ('cost', 'pad') then t2.agency_id end) pad_agency_id,--渠道平板子订单代理商ID
(case when t2.onion_order_id is not null and t1.kind in ('cost', 'pad') then t2.agency_name end) pad_agency_name,--渠道平板子订单代理商ID
(case when t2.onion_order_id is not null and t1.kind in ('cost', 'pad') then t2.agency_type end) pad_agency_type--渠道平板子订单代理商ID

from
(SELECT DISTINCT *, 
(case when company_refund_amount=0 then '非平板' when kind in ('cost', 'pad') then '平板' else '非平板' end) pad_type,
(case when company_refund_amount=0 then 0
      when kind not in ('cost','pad','virtualPad') then cost -- 新增虚拟平板成本
      when kind = 'cost' then 50 -- 管控费
      when date(paid_time) < '2026-04-01' and kind = 'virtualPad' then 1000 -- 虚拟平板原成本
      when date(paid_time) >= '2026-04-01' and kind = 'virtualPad' then 1300 -- 虚拟平板新成本
      when cost=1943.00 then 1943
      when cost=970.00 then 1050
      when cost=1100.00 then 1050
      when cost=736.00 then 1000
      when cost=1417.00 then 1500
      when date(paid_time) < '2026-02-15' and cost=760.00 then 900 -- Q20原成本
      when date(paid_time) >= '2026-02-15' and cost=760.00 then 1300 -- Q20新成本
      when cost=1200.00 then 1150
      when cost=1150.00 then 1250
      when date(paid_time) < '2026-02-15' and cost=890.00 then 1400 -- P30原成本
      when date(paid_time) >= '2026-02-15' and cost=890.00 then 1500 -- P30新成本
      end) as finalcost,-- 区域口径成本(20260401更新)
  (case when company_refund_amount=0 then 0 when kind<>'cost' then cost else 50 end) cost1--公司口径成本
from (
SELECT a.*,b.school_id,b.school_name,b.kind,b.kind_name,b.cost,b.good_name,b.income_type,b.kind,b.cost,b.real_province as province,b.real_city as city,b.real_area as area,b.user_type,b.user_id,b.good_id,
b.stage,b.subject,b.region_code,b.agency_type,b.is_test,b.class_ref,b.class_name,b.class_type,b.activity_type,b.original_amount,b.paid_time
from go_channel_order.order_refund_info a
LEFT JOIN (
	select distinct a.*,--必须要去重
(case when b.province is not null then b.province
      when c.province is not null then c.province
      when d.province is not null then d.province
      else a.province end) real_province,
(case when b.city is not null then b.city
      when c.city is not null then c.city
      else a.city end) real_city,
(case when b.area is not null then b.area
      else a.area end) real_area
from (select * from go_channel_order.order_info where is_deleted is false ) a
LEFT JOIN dw.dim_region b
on a.region_code=b.area_code
LEFT JOIN dw.dim_region c
on a.region_code=c.city_code
LEFT JOIN dw.dim_region d
on a.region_code=d.province_code
)  b
on a.order_info_pkey_id=b.id
where 
--(to_date(a.refund_time) BETWEEN '${begin_time}' and '${end_time}')
 a.is_deleted is false and b.is_deleted is false
--and locate('测试', b.school_name)=0 
--and locate('测试', b.agency_name)=0 
)

) t1
left join (
SELECT DISTINCT (case when (agency_id is not null and agency_id<>'' and agency_id<>'0' ) then onion_order_id end) onion_order_id,--有代理商的订单ID
(case when (agency_id is not null and agency_id<>'' and agency_id<>'0'  ) then agency_id end) agency_id,
(case when (agency_id is not null and agency_id<>'' and agency_id<>'0' ) then agency_name end) agency_name,
(case when (agency_id is not null and agency_id<>'' and agency_id<>'0' ) then agency_type end) agency_type,
row_number() over(partition by onion_order_id order by agency_id desc) rows --还原平板子订单所属代理商时，如果一个订单有2个代理商，则取代理商ID最大的一个
from go_channel_order.order_info
where 
--(to_date(paid_time) BETWEEN '${begin_time}' and '${end_time}') 
 is_deleted is false
--and locate('测试', school_name)=0 
--and locate('测试', agency_name)=0 
having rows=1
) t2
on t1.onion_order_id=t2.onion_order_id)
 
UNION ALL

SELECT
null as id,--订单表主ID唯一值
order_id as onion_order_id,--订单ID
null as sequence_id,--子订单ID
good_id,--商品id
good_name,--商品名称
'项目代付付款' as from,--订单来源
null as kind_name,--商品类型
null as buy_count,--商品数量
null as stage,--学段
null as subject,--学科
null as class_ref,--班级ID
null as class_name,--班级名称
null as class_type,--班级类型
is_test,--是否测试订单
status,--支付状态
region_code,--区域编码
null as student_id,
null as teacher_id,
'渠道回款' as sequence_id_type,--子订单归属
pay_time as paid_time,--付款时间
'项目代付' as pad_type,--子订单类型
0 as refund_amount,--退款（对应GMV）
settlement as finalsales_back_amount_of_com,--区域口径回款
settlement as reality_amount,--公司口径回款
settlement as sub_order_pay_amount,--GMV口径回款
settlement as sub_order_pay_amount1,--区域口径-GMV回款
0 as finalcost,--平板成本
null as super_vise,--区总姓名
province,--省
city,--市
area,--区
agency_id,--代理商ID
agency_name,--代理商名称
agency_type,--direct:直营代理商,agent:合作代理商
school_id,--学校ID
school_name,--学校名称

'' AS activity_type,
'' AS activity_type_name,
null as refund_time,
0 as original_amount,
0 as sub_order_amount_to_be_dsistributed,
0 as distribution_amount_of_agents,
0 as sales_back_amount_of_com,
0 as distribution_amount_of_thirdparty,
null as kind

from (

select
		e.*,o.status
	from (
	SELECT k.order_id,k.pay_time,k.settlement,k.agency_id,k.agency_name,k.region region_code,k.agency_type,k.is_test,
	substring_index(substring_index(substring_index(good_info,'goodInfo":{"_id":"',-1),'{"_id":"',-1),'"',1) good_id,
	substring_index(substring_index(k.good_info,'","description":',1),'"name":"',-1) good_name,
	if(k.province is null,l.agency_province,k.province) province,
	if(k.city is null,l.agency_city,k.city) city,
	if(k.area is null,l.agency_area,k.area) area,
	l.school_ref school_id,l.name school_name
	from (
	select a.*,
(case when b.province is not null then b.province
      when c.province is not null then c.province
      else d.province end) province,
(case when b.city is not null then b.city
      when c.city is not null then c.city
      else '' end) city,
(case when b.area is not null then b.area
      else '' end) area

from channel.entry_business_order a
LEFT JOIN dw.dim_region b
on a.region=b.area_code
LEFT JOIN dw.dim_region c
on a.region=c.city_code
LEFT JOIN dw.dim_region d
on a.region=d.province_code
	) k
	LEFT JOIN dw.dim_school l
	on k.school_id=l.school_id
	) e 
	left join channel.business_order o 
	on e.order_id =o.u_id 
	where
		e.pay_time is not null and o.status in ('支付成功', '退款成功') --and e.school_id  in ('58456ff1e00aecc58a9e42a9')  
		
		--and (to_date(e.pay_time) between '${begin_time}' and '${end_time}') --and e.agency_id in (291) 
		--group by e.school_id
)
 

 
UNION ALL

SELECT
null as id,--订单表主ID唯一值
order_id as onion_order_id,--订单ID
null as sequence_id,--子订单ID
good_id,--商品id
good_name,--商品名称
'项目代付退款' as from,--订单来源
null as kind_name,--商品类型
null as buy_count,--商品数量
null as stage,--学段
null as subject,--学科
null as class_ref,--班级ID
null as class_name,--班级名称
null as class_type,--班级类型
is_test,--是否测试订单
'退款成功' as status,--支付状态
region_code,--区域编码
null as student_id,
null as teacher_id,
'渠道回款' as sequence_id_type,--子订单归属
refunded_time as paid_time,--付款时间
'项目代付' as pad_type,--子订单类型
refund_amount,--退款（对应GMV）
(0-refund_amount) as finalsales_back_amount_of_com,--区域口径回款
(0-refund_amount) as reality_amount,--公司口径回款
0 as sub_order_pay_amount,--GMV口径回款
0 as sub_order_pay_amount1,--区域口径-GMV回款
0 as finalcost,--平板成本
null as super_vise,--区总姓名
province,--省
city,--市
area,--区
agency_id,--代理商ID
agency_name,--代理商名称
agency_type,--direct:直营代理商,agent:合作代理商
school_id,--学校ID
school_name,--学校名称

'' AS activity_type,
'' AS activity_type_name,
refunded_time as refund_time,
0 as original_amount,
0 as sub_order_amount_to_be_dsistributed,
0 as distribution_amount_of_agents,
0 as sales_back_amount_of_com,
0 as distribution_amount_of_thirdparty,
null as kind

from (

SELECT k.order_id,k.refunded_time,k.refund_amount,k.agency_id,k.agency_name,k.good_name,k.region region_code,k.agency_type,k.is_test,k.good_id,
	if(k.province is null,l.agency_province,k.province) province,
	if(k.city is null,l.agency_city,k.city) city,
	if(k.area is null,l.agency_area,k.area) area,
	l.school_ref school_id,l.name school_name
from (

select a.*,
(case when b.province is not null then b.province
      when c.province is not null then c.province
      else d.province end) province,
(case when b.city is not null then b.city
      when c.city is not null then c.city
      else '' end) city,
(case when b.area is not null then b.area
      else '' end) area
from (select
		e.*,o.school_id,o.agency_id,o.agency_name,o.region,o.agency_type,o.is_test,
		substring_index(substring_index(substring_index(good_info,'goodInfo":{"_id":"',-1),'{"_id":"',-1),'"',1) good_id,
		substring_index(substring_index(o.good_info,'","description":',1),'"name":"',-1) good_name
	from channel.business_order_refund_extra_info e 
	left join channel.entry_business_order o 
	on e.order_id =o.order_id
	where
		e.refunded_time is not null and o.pay_time is not null --and o.status in ('支付成功', '退款成功') and e.school_id  in ('58456ff1e00aecc58a9e42a9')  
		
		--and (to_date(e.refunded_time) between '${begin_time}' and '${end_time}') --and e.agency_id in (291) 
		--group by e.school_id
) a
LEFT JOIN dw.dim_region b
on a.region=b.area_code
LEFT JOIN dw.dim_region c
on a.region=c.city_code
LEFT JOIN dw.dim_region d
on a.region=d.province_code
) k	
LEFT JOIN dw.dim_school l
on k.school_id=l.school_id
)

UNION ALL

SELECT
null as id,--订单表主ID唯一值
id as onion_order_id,--订单ID
null as sequence_id,--子订单ID
good_id,--商品id
good_name,--商品名称
'周边付款' as from,--订单来源
null as kind_name,--商品类型
null as buy_count,--商品数量
null as stage,--学段
null as subject,--学科
null as class_ref,--班级ID
null as class_name,--班级名称
null as class_type,--班级类型
is_test,--是否测试订单
'支付成功' as status,--支付状态
region_code,--区域编码
null as student_id,
null as teacher_id,
'渠道回款' as sequence_id_type,--子订单归属
created_at as paid_time,--付款时间
'周边付款' as pad_type,--子订单类型
0 as refund_amount,--退款（对应GMV）
amount as finalsales_back_amount_of_com,--区域口径回款
amount as reality_amount,--公司口径回款
amount as sub_order_pay_amount,--GMV口径回款
amount as sub_order_pay_amount1,--区域口径-GMV回款
0 as finalcost,--平板成本
null as super_vise,--区总姓名
province,--省
city,--市
area,--区
agency_id,--代理商ID
agency_name,--代理商名称
agency_type,--direct:直营代理商,agent:合作代理商
null as school_id,--学校ID
null as school_name,--学校名称

'' AS activity_type,
'' AS activity_type_name,
null as refund_time,
0 as original_amount,
0 as sub_order_amount_to_be_dsistributed,
0 as distribution_amount_of_agents,
0 as sales_back_amount_of_com,
0 as distribution_amount_of_thirdparty,
null as kind

from (

select 
	*	
	from 
	(
	select a.*,
(case when b.province is not null then b.province
      when c.province is not null then c.province
      else d.province end) province,
(case when b.city is not null then b.city
      when c.city is not null then c.city
      else '' end) city,
(case when b.area is not null then b.area
      else '' end) area

from channel.material_order a
LEFT JOIN dw.dim_region b
on a.region_code=b.area_code
LEFT JOIN dw.dim_region c
on a.region_code=c.city_code
LEFT JOIN dw.dim_region d
on a.region_code=d.province_code
	)
	where 
		deleted_at is null

	--to_date(created_at) between '${begin_time}' and '${end_time}' )

)
 
 
 UNION ALL
 
 
 SELECT
null as id,--订单表主ID唯一值
id as onion_order_id,--订单ID
null as sequence_id,--子订单ID
good_id,--商品id
good_name,--商品名称
'周边退款' as from,--订单来源
null as kind_name,--商品类型
null as buy_count,--商品数量
null as stage,--学段
null as subject,--学科
null as class_ref,--班级ID
null as class_name,--班级名称
null as class_type,--班级类型
is_test,--是否测试订单
'支付成功' as status,--支付状态
region_code,--区域编码
null as student_id,
null as teacher_id,
'渠道回款' as sequence_id_type,--子订单归属
refund_time as paid_time,--付款时间
'周边退款' as pad_type,--子订单类型
amount as refund_amount,--退款（对应GMV）
0-amount as finalsales_back_amount_of_com,--区域口径回款
0-amount as reality_amount,--公司口径回款
0 as sub_order_pay_amount,--GMV口径回款
0 as sub_order_pay_amount1,--区域口径-GMV回款
0 as finalcost,--平板成本
null as super_vise,--区总姓名
province,--省
city,--市
area,--区
agency_id,--代理商ID
agency_name,--代理商名称
agency_type,--direct:直营代理商,agent:合作代理商
null as school_id,--学校ID
null as school_name,--学校名称

'' AS activity_type,
'' AS activity_type_name,
refund_time,
0 as original_amount,
0 as sub_order_amount_to_be_dsistributed,
0 as distribution_amount_of_agents,
0 as sales_back_amount_of_com,
0 as distribution_amount_of_thirdparty,
null as kind

from (

select 
	*	
	from 
	(
	select a.*,
(case when b.province is not null then b.province
      when c.province is not null then c.province
      else d.province end) province,
(case when b.city is not null then b.city
      when c.city is not null then c.city
      else '' end) city,
(case when b.area is not null then b.area
      else '' end) area

from channel.material_order a
LEFT JOIN dw.dim_region b
on a.region_code=b.area_code
LEFT JOIN dw.dim_region c
on a.region_code=c.city_code
LEFT JOIN dw.dim_region d
on a.region_code=d.province_code
	)
	where 
		deleted_at is null and refund_time is not null 

	--to_date(created_at) between '${begin_time}' and '${end_time}' )
)


 UNION ALL
 
 
SELECT
null as id,--订单表主ID唯一值
id as onion_order_id,--订单ID
null as sequence_id,--子订单ID
good_id,--商品id
good_name,--商品名称
'线下流水' as from,--订单来源
goods_type as kind_name,--商品类型
buy_count,--商品数量（用于获取线下大会员数量）
null as stage,--学段
null as subject,--学科
null as class_ref,--班级ID
null as class_name,--班级名称
null as class_type,--班级类型
is_test,--是否测试订单
'支付成功' as status,--支付状态
region_code,--区域编码
null as student_id,
null as teacher_id,
(case when (agency_id is not null and  agency_id<>'') then '渠道回款'
      else '非渠道回款'
      end) sequence_id_type,--子订单归属
reality_amount_at as paid_time,--付款时间
'线下流水' as pad_type,--子订单类型
0 as refund_amount,--退款（对应GMV）
(case when goods_type1 not in (10) then reality_amount ELSE 0 end) as finalsales_back_amount_of_com,--区域口径回款
reality_amount as reality_amount,--公司口径回款
amount as sub_order_pay_amount,--GMV口径回款
(case when goods_type1 not in (10) then amount ELSE 0 end) as sub_order_pay_amount1,--区域口径-GMV回款
0 as finalcost,--平板成本
super_vise_name as super_vise,--区总姓名
province,--省
city,--市
area,--区
agency_id,--代理商ID
agency_name,--代理商名称
agency_type,--direct:直营代理商,agent:合作代理商
school_code as school_id,--学校ID
school_name as school_name,--学校名称

'' AS activity_type,
'' AS activity_type_name,
null as refund_time,
0 as original_amount,
0 as sub_order_amount_to_be_dsistributed,
0 as distribution_amount_of_agents,
0 as sales_back_amount_of_com,
0 as distribution_amount_of_thirdparty,
null as kind

from (
select DISTINCT
		e.*,
		o.goods_type,o.goods_type1,o.goods_id as good_id,
		concat(o.goods_type,'-',o.goods_name) good_name
	from (
	select a.*,
(case when b.province is not null then b.province
      when c.province is not null then c.province
      when d.province is not null then d.province
      else a.school_province end) province,
(case when b.city is not null then b.city
      when c.city is not null then c.city
      else a.school_city end) city,
(case when b.area is not null then b.area
      else a.school_area end) area
from channel.entry_offline_order_item a
LEFT JOIN dw.dim_region b
on a.region_code=b.area_code
LEFT JOIN dw.dim_region c
on a.region_code=c.city_code
LEFT JOIN dw.dim_region d
on a.region_code=d.province_code
	) e 
	left join (
	select entry_id,deleted_at,goods_name,goods_type goods_type1,goods_id,
	(case when goods_type=1 then '线下-同步课'
	      when goods_type=2 then '线下-总复习'
	      when goods_type=3 then '线下-同步课+总复习'
	      when goods_type=4 then '线下-云平台'
	      when locate('样机',reason)>0 then '线下-样机'--临时使用备注，历史订单无异常，风险：可能会出现样机+非样机一起录入的问题
	      when goods_type=5 then '线下-洋葱星球'
	      when goods_type=6 then '线下-洋葱派采购'
	      when goods_type=7 then '线下-派单费'
	      when goods_type=8 then '线下-培优'
	      when goods_type=9 then '线下-代理商退出抵扣商品'
	      when goods_type=10 then '线下-罚款'
	      end) goods_type
	from channel.entry_offline_order
	
	) o 
	on e.entry_id = o.entry_id
	where
		e.reality_amount > 0 and e.deleted_at is null and o.deleted_at is null  
		
		--and (to_date(e.reality_amount_at) between '${begin_time}' and '${end_time}' )
)


)
;

-- =====================================================
-- 枚举值（派生/标签列，便于与 part1 对照）
-- =====================================================
-- 订单来源标签（最外层 SELECT 中别名为 from）：线上付款、线上退款、项目代付付款、项目代付退款、周边付款、周边退款、线下流水
-- pad_type（子订单类型标签）：平板、非平板、项目代付、周边付款、周边退款、线下流水 等（各支常量不同，见 UNION 内注释）
-- sequence_id_type（脚本内部分支用于渠道/非渠道回款，另有列注释提示以 agency_id 为准）：渠道回款、非渠道回款
-- activity_type → activity_type_name（仅线上支有值）：buchajia、activityRepurchase、repurchase、highActivity、firstBuy、diffPrice、mulChild、hisMem、highHoardCourse、padAddPur 等
-- entry_offline_order.goods_type 数值与中文映射：见 channel.entry_offline_order DDL 枚举段
-- =====================================================
-- 枚举值
-- =====================================================
-- CASE/THEN 派生标签（摘自本脚本字符串常量，合并去重；业务若有新增取值以库内为准）：
--   渠道回款、补差购买平板、活动续购、普通续购、高考版大会员续购、首购、补差、多孩续购、历史大会员续购、高中囤课续购、平板加购续购、平板、非平板、线下-同步课、线下-总复习、线下-同步课+总复习、线下-云平台、线下-样机、线下-洋葱星球、线下-洋葱派采购、线下-派单费、线下-培优、线下-代理商退出抵扣商品、线下-罚款
--
-- 布尔/数值状态位：0/1、true/false 等以列 COMMENT 为准；未在 COMMENT 展开的码表以业务库或维表为准
-- 宽表列映射与 CASE 派生值以正文 SELECT 为准；part1/part3 含义见顶部【注意事项】
