-- =====================================================
-- 订单- 财务对账口径订单表 tmp.meishihua_caiwu_orders_2month
-- =====================================================
--
-- 【表粒度】
--   CTAS 结果表；粒度与下方 SELECT / GROUP BY / DISTINCT 一致，列注释以 SELECT 内联注释与别名为准
--
-- 【业务定位】
--   - 知识库归类：订单- 财务对账口径订单表。
--   - 财务侧近月订单汇总临时表；用于财务GMV对账
--
-- 【统计口径】
--   - 聚合维度、去重规则、CASE 映射（商品线/活动/区域等）均在下方 SQL 中体现，改口径需全文排查
--   - 若脚本依赖 `tmp.meishihua_allorders`，商品线与金额口径应与该表文档头【汇总关系】保持一致
--
-- 【汇总关系】
--   - 上游（脚本内显式 FROM/JOIN，节选）：`aws.teacher_school_finance_settle_orders`, `channel.entry_offline_order`, `channel.entry_offline_order_item`, `dw.dim_region`, `dw.fact_order_detail`, `dw.fact_order_detail_refund`, `tmp.meishihua_allorders`
--   - 下游：智课看板、临时分析、`tmp.meishihua_*` 派生表等（以调度与引用脚本为准）
--
-- 【常用关联】
--   - 按 `onion_order_id`、`agency_id`、`school_id` 与维表/事实表 JOIN；分区键与业务日期字段对齐后再聚合
--
-- 【常用筛选条件】
--   - 分区键区间；is_deleted / is_test；业务状态、时间范围；代理商/学校/用户 id 类筛选
--
-- 【注意事项】
--   - 以 LOCATION、库表名与调度任务为准；改字段或口径需同步下游 SQL 与看板
--
-- =====================================================
DROP TABLE IF EXISTS tmp.meishihua_caiwu_orders_2month;

create table tmp.meishihua_caiwu_orders_2month STORED AS ORC AS 

--【2024.12-至今】财务口径GMV-线上（包含项目代付+周边）
SELECT date(final_time) final_time,
  order_type,
  order_id,
  payment_platform,
  sum(amount) amount
  from ( --非三方-非体验机订单
  (SELECT DISTINCT '非三方' as order_type, order_id,amount,payment_platform,'非体验机订单' as tiyanji_type,case when date(paid_time)>date(binding_time) then paid_time else binding_time end final_time --非三方订单-财务gmv口径
  from dw.fact_order_detail 
  where cast(correct_team_names as string) REGEXP '入校'
  and left(paid_time,7)>='2024-02'
  and payment_platform not in ('jd','shipinhaoxiaodian','xiaohongshu','tmall','doudian','pinduoduo')
  and order_id not in (select distinct order_id from aws.teacher_school_finance_settle_orders)
  and order_id not in (select distinct order_id from dw.fact_order_detail where pre_order_id is null and array_contains(group, 'tiyanji') ) --24年8月之后的体验机首单过滤掉
  )
  
  UNION 
  
   ( --非三方-体验机订单
   select DISTINCT '非三方' as order_type, b1.order_id,b1.amount,b1.payment_platform,
    case when datediff(b2.refund_time,b1.final_time) <= 30 then '体验机首单30天内退款'
         when datediff(b2.refund_time,b3.final_time) = 0 then '体验机尾单付费与首单退款在同一天'
         when datediff(now(),b1.final_time) <= 30 then '体验机首单至今不满30天'
         when b3.final_time is not null then '已付尾款'
         else '未付尾款'
         end tiyanji_type,
     case when datediff(b2.refund_time,b1.final_time) <= 30 then b2.refund_time
         when datediff(b2.refund_time,b3.final_time) = 0 then b2.refund_time
         when datediff(now(),b1.final_time) <= 30 then b1.final_time
         when b3.final_time is not null then b3.final_time
         else date(b1.final_time)+30 
         end final_time
    from 
    (SELECT DISTINCT order_id,amount,payment_platform,case when date(paid_time)>date(binding_time) then paid_time else binding_time end final_time 
    from dw.fact_order_detail 
    where array_contains(group, 'tiyanji') and pre_order_id is null AND paid_time >= '2024-08-01'--体验机首单
    and cast(correct_team_names as string) REGEXP '入校' 
    and payment_platform not in ('jd','shipinhaoxiaodian','xiaohongshu','tmall','doudian','pinduoduo')
    and order_id not in (select distinct order_id from aws.teacher_school_finance_settle_orders)
    ) b1 --体验机首单
    left join (select distinct order_id,refund_time from dw.fact_order_detail_refund) b2 --体验机首单退款
    on b1.order_id=b2.order_id 
    left join (SELECT DISTINCT pre_order_id,case when date(paid_time)>date(binding_time) then paid_time else binding_time end final_time 
    from dw.fact_order_detail 
    where paid_time >= '2024-08-01'
    ) b3 --体验机尾单
    on b3.pre_order_id=b1.order_id
    having tiyanji_type in ('已付尾款','未付尾款') ) 
  
  UNION 
  
  (--三方订单
  SELECT distinct '三方' as order_type,order_id,gmv_amount,payment_platform,'非体验机订单' as tiyanji_type,gmv_time from aws.teacher_school_finance_settle_orders where gmv_type='increase')  
  
  UNION 
  
  (--项目代付+周边订单
  SELECT '非三方' as order_type,onion_order_id,sum(sub_order_pay_amount) sub_order_pay_amount,from,from as tiyanji_type,paid_time 
  from tmp.meishihua_allorders 
  where is_test is FALSE  and from in ('项目代付付款','周边付款') 
  GROUP BY onion_order_id,from,paid_time )
  
  )
where left(final_time,7) between left(add_months(date(now())-1,-1),7) and left(date(now())-1,7) --8月之后的体验机，12月及之后的最新口径

group by 1,2,3,4

UNION 


--财务口径GMV(线下订单，不包含toG)
SELECT 
date(paid_time) final_time,
case when kind_name='线下-代理商退出抵扣商品' then '线下-抵扣' else '线下-打款' end  kinds,
onion_order_id,
case when kind_name='线下-代理商退出抵扣商品' then '线下-抵扣' else '线下-打款' end  kinds,
sum(sub_order_pay_amount) sub_order_pay_amount
--entry_id
from  
(SELECT
null as id,--订单表主ID唯一值
id as onion_order_id,--订单ID
entry_id,--工单ID
null as sequence_id,--子订单ID
good_name,--商品名称
'线下流水' as from,--订单来源
goods_type as kind_name,--商品类型
buy_count,--商品数量（用于获取线下大会员数量）
null as stage,--学段
null as subject,--学科
is_test,--是否测试订单
'支付成功' as status,--支付状态
region_code,--区域编码
null as student_id,
null as teacher_id,
(case when (agency_id is not null and  agency_id<>'') then '渠道回款'
      else '非渠道回款'
      end) sequence_id_type,--子订单归属
real_time as paid_time,--付款时间
'线下流水' as pad_type,--子订单类型
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
school_name as school_name--学校名称

from (
select DISTINCT
		e.*,
		o.goods_type,o.goods_type1,o.real_time,
		concat(o.goods_type,'-',o.goods_name) good_name
	from (
	select a.*,
(case when b.province is not null then b.province
      when c.province is not null then c.province
      when d.province is not null then d.province
      else a.school_province end) province,
(case when b.city is not null then b.city
      when c.city is not null then c.city
      when d.city is not null then d.city
      else a.school_city end) city,
(case when b.area is not null then b.area
      when c.area is not null then c.area
      when d.area is not null then d.area
      else a.school_area end) area
from channel.entry_offline_order_item a
LEFT JOIN dw.dim_region b
on a.region_code=b.area_code
LEFT JOIN dw.dim_region c
on a.region_code=c.city_code
LEFT JOIN dw.dim_region d
on a.region_code=d.province_code
	) e 
	join (
	select entry_id,deleted_at,goods_name,goods_type goods_type1,finance_confirm_at,
	case when goods_type=9 then finance_confirm_at else payment_at end real_time,
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
		e.reality_amount > 0 and finance_confirm_at is not null and --财务在统计日审批通过且中台已录入回款的订单，根据类型按照打款时间/财务审批通过时间统计，中台未录入的还未录入回款金额，无法统计
		e.deleted_at is null and o.deleted_at is null  
		
		--and (to_date(e.reality_amount_at) between '${begin_time}' and '${end_time}' )
)
)
where is_test is false and left(paid_time,7) between left(add_months(date(now())-1,-1),7) and left(date(now())-1,7)
group by 1,2,3,4;

-- =====================================================
-- 枚举值（与 UNION 分支、派生列对照）
-- =====================================================
-- order_type（线上段）：非三方、三方
-- tiyanji_type（线上子查询内）：非体验机订单；体验机支下为体验机首单30天内退款、体验机尾单付费与首单退款在同一天、体验机首单至今不满30天、已付尾款、未付尾款 等
-- 来自 tmp.meishihua_allorders 的聚合支：保留原表「订单来源」列（别名为 from）参与 group by，典型取值含 项目代付付款、周边付款（见 tmp.meishihua_allorders DDL）
-- 线下段 kinds：线下-抵扣（对应 kind_name 线下-代理商退出抵扣商品）、线下-打款
-- =====================================================
-- 枚举值
-- =====================================================
-- CASE/THEN 派生标签（摘自本脚本字符串常量，合并去重；业务若有新增取值以库内为准）：
--   体验机首单30天内退款、体验机尾单付费与首单退款在同一天、体验机首单至今不满30天、已付尾款、线下-抵扣、渠道回款、线下-同步课、线下-总复习、线下-同步课+总复习、线下-云平台、线下-样机、线下-洋葱星球、线下-洋葱派采购、线下-派单费、线下-培优、线下-代理商退出抵扣商品、线下-罚款
--
-- 布尔/数值状态位：0/1、true/false 等以列 COMMENT 为准；未在 COMMENT 展开的码表以业务库或维表为准
-- 与 `tmp.meishihua_allorders` / 订单域对齐的枚举，优先参见对应脚本 part3 与列映射
