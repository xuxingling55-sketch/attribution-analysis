-- =====================================================
-- 订单- 项目代付订单日志 channel.business_order
-- =====================================================
--
-- 【表粒度】
--   业务库同步 ORC 外表（以 LOCATION 为准）；一行一条业务记录，主键/唯一性见列 COMMENT
--
-- 【业务定位】
--   - 知识库归类：订单- 项目代付订单日志。
--   - 入校项目代付订单日志
--
-- 【统计口径】
--   - 删除标记、有效区间、历史拉链等以列 COMMENT 为准；`is_deleted` 类字段取数前需明确是否过滤
--   - 时间字段（创建/更新/生效）与数仓 `day` 分区并存时，先确认业务语义再关联
--
-- 【汇总关系】
--   - 上游：本文件未检出 `db.table` 形式引用（或仅为子查询别名）；以实际 SQL 为准
-- - 下游：`tmp.meishihua_allorders`（`create table tmp.meishihua_allorders -- 全量入校订单 as`，见同目录 `tmp.meishihua_allorders.sql`）；与同脚本 UNION/JOIN 并列的上游还包括 `channel.business_order`、`channel.business_order_refund_extra_info`、`channel.entry_business_order`、`channel.entry_offline_order`、`channel.entry_offline_order_item`、`channel.material_order`、`dw.dim_region`、`dw.dim_school`、`go_channel_order.order_info`、`go_channel_order.order_refund_info`（以该脚本为准）
--   - 再下游：智课看板、临时分析、`tmp.meishihua_*` 派生表等（以调度与引用脚本为准）
--
-- 【常用关联】
--   - 按 主键/外键见列 COMMENT 与维表/事实表 JOIN；分区键与业务日期字段对齐后再聚合
--
-- 【常用筛选条件】
--   - 分区键区间；is_deleted / is_test；业务状态、时间范围；代理商/学校/用户 id 类筛选
--
-- 【注意事项】
--   - 以 LOCATION、库表名与调度任务为准；改字段或口径需同步下游 SQL 与看板
--
-- =====================================================
CREATE TABLE
  `channel`.`business_order` (
    `u_id` string COMMENT 'undefined',
    `status` string COMMENT '支付状态',
    `good_list` string COMMENT '商品列表',
    `amount` string COMMENT '订单实付总金额',
    `payment_platform` string COMMENT 'undefined',
    `payment_credentials` string COMMENT '支付信息',
    `paid_time` timestamp COMMENT '订单支付成功的时间',
    `manually_refunded_by` string COMMENT '手动退款操作者的ID',
    `refund_info_list` string COMMENT '退款信息',
    `buyer_id` string COMMENT '下单用户ID',
    `buyer_type` string COMMENT 'undefined',
    `created_at` timestamp COMMENT '订单创建时间-订单服务记录的创建时间',
    `updated_at` timestamp COMMENT '订单修改时间-订单服务记录的更新时间',
    `created_date` timestamp COMMENT '这里记录的创建时间',
    `updated_date` timestamp COMMENT '这里记录的更新时间'
 ) COMMENT 'channel.business_order 表' ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/channel.db/business_order'

-- =====================================================
-- 枚举值（派生/标签列，便于与 part1 对照）
-- =====================================================
-- part1 指本文件顶部 DDL 注释块（首段 `-- =====…` 至 CREATE TABLE 之前）。本表卷入 `tmp.meishihua_allorders` 后由脚本派生的标签类枚举见同目录 `tmp.meishihua_allorders.sql` 文末同名段。
--
-- =====================================================
-- 枚举值
-- =====================================================
-- 字段取值提示（摘自列 COMMENT，完整以 Hive 元数据为准）：
-- `status`（列 COMMENT）：支付状态
--
-- 布尔/数值状态位：0/1、true/false 等以列 COMMENT 为准；未在 COMMENT 展开的码表以业务库或维表为准
-- 与 `tmp.meishihua_allorders` 宽表派生标签、订单域枚举对齐：见同目录 `tmp.meishihua_allorders.sql` 文末「枚举值（派生/标签列，便于与 part1 对照）」段与紧接的「枚举值」段（该文件中 **part1** ＝顶部 DDL 注释块，**part3** ＝文末两节枚举说明）。
