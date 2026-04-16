-- =====================================================
-- 订单- 线上付款订单 go_channel_order.order_info
-- =====================================================
--
-- 【表粒度】
--   出单库 ORC 外表；一个id（主键）一条；同一 onion_order_id 可多条，通常无 Hive 分区
--
-- 【业务定位】
--   - 知识库归类：订单- 线上付款订单。
--   - 入校线上付款订单主表：用户/学校/商品/分账金额、活动类型 activity_type、sku 类型 kind 等
--   - 在 tmp.meishihua_allorders 中作为「线上付款」支的主来源；并与子查询按 onion_order_id 关联，还原平板子订单对应代理商（kind in ('cost','pad') 时用订单层代理商）
--
-- 【统计口径】
--   - 订单金额、退款、活动类型等口径以列 COMMENT 为准；与 tmp 宽表对齐时参见 `tmp.meishihua_allorders` 内 UNION/CASE
--   - 关联退款表 `go_channel_order.order_refund_info` 时注意 id / pkey 映射（见 order_info.sql 头说明）
--
-- 【汇总关系】
--   - 上游：本文件未检出 `db.table` 形式引用（或仅为子查询别名）；以实际 SQL 为准
-- - 下游：`tmp.meishihua_allorders`（`create table tmp.meishihua_allorders -- 全量入校订单 as`，见同目录 `tmp.meishihua_allorders.sql`）；与同脚本 UNION/JOIN 并列的上游还包括 `channel.business_order`、`channel.business_order_refund_extra_info`、`channel.entry_business_order`、`channel.entry_offline_order`、`channel.entry_offline_order_item`、`channel.material_order`、`dw.dim_region`、`dw.dim_school`、`go_channel_order.order_info`、`go_channel_order.order_refund_info`（以该脚本为准）
--   - 再下游：智课看板、临时分析、`tmp.meishihua_*` 派生表等（以调度与引用脚本为准）
--
-- 【常用关联】
--   - 按 `onion_order_id`、`user_id`、`agency_id`、`school_id`、`class_ref` 与维表/事实表 JOIN；分区键与业务日期字段对齐后再聚合
--
-- 【常用筛选条件】
--   - 分区键区间；is_deleted / is_test；业务状态、时间范围；代理商/学校/用户 id 类筛选
--
-- 【注意事项】
--   - 以 LOCATION、库表名与调度任务为准；改字段或口径需同步下游 SQL 与看板
--
-- =====================================================
CREATE TABLE
  `go_channel_order`.`order_info` (
    `id` string COMMENT '主键id',
    `order_type` string COMMENT '订单类型：线上/线下',
    `onion_order_id` string COMMENT '订单id',
    `sequence_id` string COMMENT '子订单id',
    `status` string COMMENT '订单状态：支付成功/部分退款/退款成功',
    `good_name` string COMMENT '商品名称',
    `semester` string COMMENT '学期',
    `publisher` string COMMENT '版本',
    `platform` string COMMENT '支付方式',
    `real_platform` string COMMENT '支付渠道',
    `user_id` string COMMENT '用户长id',
    `kind` string COMMENT 'sku类型',
    `stage` string COMMENT '学段',
    `subject` string COMMENT '学科',
    `user_type` string COMMENT '用户类型：teacher/student',
    `real_name` string COMMENT '用户真实姓名',
    `nick_name` string COMMENT '用户昵称',
    `phone` string COMMENT '用户手机号',
    `onion_id` string COMMENT '用户洋葱id',
    `school_id` bigint COMMENT '用户所在学校短id',
    `school_name` string COMMENT '用户所在学校名称',
    `enrollment_year` string COMMENT '用户入学年份',
    `class_name` string COMMENT '班级名称',
    `class_ref` string COMMENT '班级id',
    `class_type` string COMMENT '班级类型-教学班：teaching，行政班：admin',
    `province` string COMMENT '省份名',
    `city` string COMMENT '城市名',
    `area` string COMMENT '区县名',
    `region_code` string COMMENT '区域编码',
    `agency_name` string COMMENT '代理商名称',
    `agency_id` string COMMENT '代理商id',
    `contract_id` string COMMENT '合同id',
    `regional_manager` string COMMENT '城市经理名称',
    `regional_manager_id` string COMMENT '城市经理id',
    `operation_manager` string COMMENT '运营经理名称',
    `operation_manager_id` string COMMENT '运营经理id',
    `employee` string COMMENT '员工名称',
    `employee_id` string COMMENT '员工id',
    `add_time` bigint COMMENT '课程时长',
    `is_group_buying` boolean COMMENT '是否为线上团购订单',
    `distribution_ratio_of_agents` string COMMENT '代理商分账比例',
    `distribution_amount_of_agents` string COMMENT '代理商分账金额',
    `sales_back_ratio_of_com` string COMMENT '公司分账比例',
    `sales_back_amount_of_com` string COMMENT '公司分账金额',
    `consumption_of_the_original_purchase_amount` string COMMENT '代付消耗原购课款金额',
    `consumption_of_the_desposit_amount` string COMMENT '代付消耗充值金额',
    `original_amount` string COMMENT '商品原价',
    `order_pay_amount` string COMMENT '订单实付金额',
    `order_discount_amount_old` string COMMENT '订单优惠金额',
    `sub_order_pay_amount` string COMMENT '子订单实付金额',
    `sub_order_amount_to_be_dsistributed` string COMMENT '子订单代分账金额',
    `created_date` timestamp COMMENT '创建时间',
    `paid_time` timestamp COMMENT '订单支付时间',
    `update_date` timestamp COMMENT '更新时间',
    `agency_manager_proportion` string COMMENT '城市经理分佣比例',
    `agency_manager_amount` string COMMENT '城市经理提成金额',
    `operation_manager_proportion` string COMMENT '运营经理分佣比例',
    `operation_manager_amount` string COMMENT '运营经理提成金额',
    `is_deleted` boolean COMMENT '是否被删除',
    `delete_date` timestamp COMMENT '删除时间',
    `platform_order_id` string COMMENT '平台订单号',
    `out_order_id` string COMMENT '商户订单号',
    `sku_id` string COMMENT 'sku id',
    `super_vise` string COMMENT '大区经理名称',
    `super_vise_id` string COMMENT '大区经理id',
    `super_vise_amount` string COMMENT '大区经理提成金额',
    `key_person` string COMMENT '关键人',
    `key_person_amount` string COMMENT '关键人提成金额',
    `core_sale_count` string COMMENT '核销数',
    `arrival_amount` string COMMENT '公司到账金额；扣除手续费后的金额',
    `reality_amount` string COMMENT '实际公司收入金额；分账后公司实际收入',
    `income_type` string COMMENT '收入类型-渠道回款/非渠道回款',
    `income_sub_type` string COMMENT '收入类型细分',
    `distribution_amount_of_thirdparty` string COMMENT '第三方分账金额',
    `distribution_ratio_of_thirdparty` string COMMENT '第三方分账比例',
    `kind_name` string COMMENT 'sku类型名称',
    `activity_type` string COMMENT '活动类型',
    `des_original_amount` string COMMENT '目标商品售价',
    `des_order_pay_amount` string COMMENT '目标商品优惠实付',
    `des_sub_order_pay_amount` string COMMENT '目标商品子订单优惠实付',
    `deduct_agency_amount` string COMMENT '扣除代理金额',
    `deduct_company_amount` string COMMENT '扣除公司金额',
    `deduct_thirdparty_amount` string COMMENT '扣除第三方金额',
    `good_id` string COMMENT '商品id',
    `course_id` string COMMENT '专项课id',
    `cost` string COMMENT '成本价',
    `user_paid_time` timestamp COMMENT '用户支付时间',
    `agency_type` string COMMENT 'direct:直营代理商,agent:合作代理商',
    `is_test` boolean COMMENT '是否测试订单',
    `order_discount_amount` string,
    `good_kind` string COMMENT '商品类型',
    `custom_pay_channel` string COMMENT '支付渠道',
    `parent_good_id` string COMMENT '父商品id',
    `parent_good_kind` string COMMENT '源商品类型',
    `big_member_label` string COMMENT '大会员标签，空/有平板大会员/无平板大会员',
    `agency_level` string COMMENT '代理商级别',
    `good_kind_id_level2` string COMMENT '商品二级类目分类',
    `ph` string COMMENT '加密后的手机号'
 ) COMMENT 'go_channel_order.order_info 表' ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/go_channel_order.db/order_info'

-- =====================================================
-- 枚举值（派生/标签列，便于与 part1 对照）
-- =====================================================
-- part1 指本文件顶部 DDL 注释块（首段 `-- =====…` 至 CREATE TABLE 之前）。本表卷入 `tmp.meishihua_allorders` 后由脚本派生的标签类枚举见同目录 `tmp.meishihua_allorders.sql` 文末同名段。
--
-- =====================================================
-- 枚举值
-- =====================================================
-- 字段取值提示（摘自列 COMMENT，完整以 Hive 元数据为准）：
-- `order_type`（列 COMMENT）：订单类型：线上/线下
-- `status`（列 COMMENT）：订单状态：支付成功/部分退款/退款成功
-- `kind`（列 COMMENT）：sku类型
-- `user_type`（列 COMMENT）：用户类型：teacher/student
-- `class_type`（列 COMMENT）：班级类型-教学班：teaching，行政班：admin
-- `is_group_buying`（列 COMMENT）：是否为线上团购订单
-- `is_deleted`（列 COMMENT）：是否被删除
-- `income_type`（列 COMMENT）：收入类型-渠道回款/非渠道回款
-- `income_sub_type`（列 COMMENT）：收入类型细分
-- `kind_name`（列 COMMENT）：sku类型名称
-- `activity_type`（列 COMMENT）：活动类型
-- `is_test`（列 COMMENT）：是否测试订单
-- `good_kind`（列 COMMENT）：商品类型
-- `parent_good_kind`（列 COMMENT）：源商品类型
-- `big_member_label`（列 COMMENT）：大会员标签，空/有平板大会员/无平板大会员
--
-- order_type：线上、线下
-- status：支付成功、部分退款、退款成功
-- user_type：teacher、student
-- agency_type：direct（直营代理商）、agent（合作代理商）
-- activity_type：与 tmp.meishihua_allorders 中 activity_type_name 映射一致；常见 buchajia、activityRepurchase、repurchase、firstBuy、diffPrice 等（空则映射为空串）
-- kind / big_member_label 等与平板、sku 线相关，详见 tmp.meishihua_allorders 脚本内 CASE
-- 布尔/数值状态位：0/1、true/false 等以列 COMMENT 为准；未在 COMMENT 展开的码表以业务库或维表为准
-- 与 `tmp.meishihua_allorders` 宽表派生标签、订单域枚举对齐：见同目录 `tmp.meishihua_allorders.sql` 文末「枚举值（派生/标签列，便于与 part1 对照）」段与紧接的「枚举值」段（该文件中 **part1** ＝顶部 DDL 注释块，**part3** ＝文末两节枚举说明）。
