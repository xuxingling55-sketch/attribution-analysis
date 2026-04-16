-- =====================================================
-- 订单- 线上退款订单 go_channel_order.order_refund_info
-- =====================================================
--
-- 【表粒度】
--   出单库 ORC 外表；一个id（主键）一条；通常无 Hive 分区
--
-- 【业务定位】
--   - 知识库归类：订单- 线上退款订单。
--   - 入校线上退款订单表；与 order_info 主键/外键关联，拼入 tmp 宽表退款支
--
-- 【统计口径】
--   - 退款金额、状态、部分退与全退等以列 COMMENT 为准；与订单支付时间对齐时注意业务时点
--   - 与 `tmp.meishihua_allorders` 对齐时参见该脚本 UNION 中退款分支字段映射
--
-- 【汇总关系】
--   - 上游：本文件未检出 `db.table` 形式引用（或仅为子查询别名）；以实际 SQL 为准
-- - 下游：`tmp.meishihua_allorders`（`create table tmp.meishihua_allorders -- 全量入校订单 as`，见同目录 `tmp.meishihua_allorders.sql`）；与同脚本 UNION/JOIN 并列的上游还包括 `channel.business_order`、`channel.business_order_refund_extra_info`、`channel.entry_business_order`、`channel.entry_offline_order`、`channel.entry_offline_order_item`、`channel.material_order`、`dw.dim_region`、`dw.dim_school`、`go_channel_order.order_info`、`go_channel_order.order_refund_info`（以该脚本为准）
--   - 再下游：智课看板、临时分析、`tmp.meishihua_*` 派生表等（以调度与引用脚本为准）
--
-- 【常用关联】
--   - 按 `onion_order_id`、`agency_id` 与维表/事实表 JOIN；分区键与业务日期字段对齐后再聚合
--
-- 【常用筛选条件】
--   - 分区键区间；is_deleted / is_test；业务状态、时间范围；代理商/学校/用户 id 类筛选
--
-- 【注意事项】
--   - 以 LOCATION、库表名与调度任务为准；改字段或口径需同步下游 SQL 与看板
--
-- =====================================================
CREATE TABLE
  `go_channel_order`.`order_refund_info` (
    `id` string COMMENT '主键id',
    `onion_order_id` string COMMENT '订单id',
    `status` string COMMENT '订单状态-退款成功/部分退款',
    `sequence_id` string COMMENT '子订单id',
    `refund_amount` string COMMENT '子订单退款金额',
    `agency_refund_amount` string COMMENT '子订单代理商退款金额',
    `company_refund_amount` string COMMENT '子订单公司退款金额',
    `refund_time` timestamp COMMENT '退款时间',
    `created_date` timestamp COMMENT '创建时间',
    `delete_date` timestamp COMMENT '删除时间',
    `is_deleted` boolean COMMENT '是否删除',
    `agency_manager_refund_amount` string COMMENT '城市经理退款金额',
    `operation_manager_refund_amount` string COMMENT '运营经理退款金额',
    `agency_id` string COMMENT '代理商id',
    `agency_name` string COMMENT '代理商名称',
    `contract_id` string COMMENT '合同id',
    `distribution_ratio_of_agents` string COMMENT '代理商分账比例',
    `refund_total` string COMMENT '退款总金额',
    `refund_status` bigint COMMENT '退款状态-1：分账退款，2：取消分账退款',
    `super_vise_refund_amount` string COMMENT '大区经理退款金额',
    `key_person_refund_amount` string COMMENT '关键人退款金额',
    `refund_arrival_amount` string COMMENT '子订单公司和代理应退',
    `refund_reality_amount` string COMMENT '子订单公司实际退款',
    `refund_way` bigint COMMENT '退款方式-1：系统退款，2：人工退款',
    `order_info_pkey_id` string COMMENT '关联订单表id',
    `super_vise_id` string COMMENT '大区经理id',
    `super_vise` string COMMENT '大区经理名称',
    `regional_manager_id` string COMMENT '城市经理id',
    `regional_manager` string COMMENT '城市经理名称',
    `operation_manager_id` string COMMENT '运营经理id',
    `operation_manager` string COMMENT '运营经理名称',
    `refund_amount_of_thirdparty` string COMMENT '第三方退款金额',
    `distribution_ratio_of_thirdparty` string COMMENT '第三方分账比例',
    `original_purchase_amount` string COMMENT '应退原购课款金额',
    `recharge_amount` string COMMENT '应退消耗充值金额',
    `refund_reason` string COMMENT '退款原因'
 ) COMMENT 'go_channel_order.order_refund_info 表' ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/go_channel_order.db/order_refund_info'

-- =====================================================
-- 枚举值（派生/标签列，便于与 part1 对照）
-- =====================================================
-- part1 指本文件顶部 DDL 注释块（首段 `-- =====…` 至 CREATE TABLE 之前）。本表卷入 `tmp.meishihua_allorders` 后由脚本派生的标签类枚举见同目录 `tmp.meishihua_allorders.sql` 文末同名段。
--
-- =====================================================
-- 枚举值
-- =====================================================
-- 字段取值提示（摘自列 COMMENT，完整以 Hive 元数据为准）：
-- `status`（列 COMMENT）：订单状态-退款成功/部分退款
-- `is_deleted`（列 COMMENT）：是否删除
-- `refund_status`（列 COMMENT）：退款状态-1：分账退款，2：取消分账退款
-- `refund_way`（列 COMMENT）：退款方式-1：系统退款，2：人工退款
--
-- 布尔/数值状态位：0/1、true/false 等以列 COMMENT 为准；未在 COMMENT 展开的码表以业务库或维表为准
-- 与 `tmp.meishihua_allorders` 宽表派生标签、订单域枚举对齐：见同目录 `tmp.meishihua_allorders.sql` 文末「枚举值（派生/标签列，便于与 part1 对照）」段与紧接的「枚举值」段（该文件中 **part1** ＝顶部 DDL 注释块，**part3** ＝文末两节枚举说明）。
