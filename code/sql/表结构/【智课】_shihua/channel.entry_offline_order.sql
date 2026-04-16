-- =====================================================
-- 订单- 线下付款订单表 channel.entry_offline_order
-- =====================================================
--
-- 【表粒度】
--   业务库同步 ORC 外表（以 LOCATION 为准）；一行一条业务记录，主键/唯一性见列 COMMENT
--
-- 【业务定位】
--   - 知识库归类：订单- 线下付款订单表。
--   - 入校线下付款订单主表
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
--   - 按 `agency_id` 与维表/事实表 JOIN；分区键与业务日期字段对齐后再聚合
--
-- 【常用筛选条件】
--   - 分区键区间；is_deleted / is_test；业务状态、时间范围；代理商/学校/用户 id 类筛选
--
-- 【注意事项】
--   - 以 LOCATION、库表名与调度任务为准；改字段或口径需同步下游 SQL 与看板
--
-- =====================================================
CREATE TABLE
  `channel`.`entry_offline_order` (
    `id` string COMMENT 'id',
    `sign_mainstay` string COMMENT '签约主体，代理商：agency、学校：school.',
    `school_code` bigint COMMENT '学校主体时候，学校的编号.',
    `school_region` string COMMENT '学校主体时候，学校的区域码.',
    `goods_type` bigint COMMENT '商品类型，1：同步课、2：总复习、3：同步课+总复习、4：云平台、5：洋葱星球、6：洋葱派采购.',
    `goods_id` string COMMENT '商品id.',
    `goods_name` string COMMENT '商品名',
    `device_model_no` string COMMENT '硬件型号.',
    `total_amount` double COMMENT '总打款金额.',
    `reason` string COMMENT '打款原因',
    `project_doc` string COMMENT '立项书文件.',
    `onion_users_xls` string COMMENT '洋葱账号开通申请表.',
    `payment_voucher_img` string COMMENT '打款凭证图片.',
    `payment_at` timestamp COMMENT '打款时间.',
    `payment_tail_no` string COMMENT '收款账号尾号.',
    `contract_doc` string COMMENT '合同文件',
    `created_user` string COMMENT '创建人id',
    `created_user_name` string COMMENT '创建人姓名',
    `updated_user` string COMMENT '最后更新人id',
    `updated_user_name` string COMMENT '最后更新人',
    `created_at` timestamp COMMENT '创建时间',
    `updated_at` timestamp COMMENT '最后更新时间',
    `deleted_at` timestamp COMMENT '删除时间',
    `entry_id` bigint COMMENT '工单id',
    `agency_name` string COMMENT '代理商名称',
    `school_name` string COMMENT '学校名称',
    `finance_confirm_at` timestamp COMMENT '财务确认时间',
    `school_province` string COMMENT '学校所在省',
    `school_city` string COMMENT '学校所在市',
    `school_area` string COMMENT '学校所在区',
    `buy_count` bigint COMMENT '当主体为学校时商品采购数量',
    `agency_id` string COMMENT '代理商id',
    `approval_instance_code` string COMMENT '审批流id',
    `need_distribution` bigint COMMENT '是否需要向代理商分账，1：不需要、2：需要',
    `has_repeated_amount` bigint COMMENT '是否有重复金额，1：无、2：有'
 ) COMMENT 'channel.entry_offline_order 表' ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/channel.db/entry_offline_order'

-- =====================================================
-- 枚举值（派生/标签列，便于与 part1 对照）
-- =====================================================
-- part1 指本文件顶部 DDL 注释块（首段 `-- =====…` 至 CREATE TABLE 之前）。本表卷入 `tmp.meishihua_allorders` 后由脚本派生的标签类枚举见同目录 `tmp.meishihua_allorders.sql` 文末同名段。
--
-- =====================================================
-- 枚举值
-- =====================================================
-- 字段取值提示（摘自列 COMMENT，完整以 Hive 元数据为准）：
-- `sign_mainstay`（列 COMMENT）：签约主体，代理商：agency、学校：school.
-- `goods_type`（列 COMMENT）：商品类型，1：同步课、2：总复习、3：同步课+总复习、4：云平台、5：洋葱星球、6：洋葱派采购.
-- `need_distribution`（列 COMMENT）：是否需要向代理商分账，1：不需要、2：需要
-- `has_repeated_amount`（列 COMMENT）：是否有重复金额，1：无、2：有
--
-- 布尔/数值状态位：0/1、true/false 等以列 COMMENT 为准；未在 COMMENT 展开的码表以业务库或维表为准
-- 与 `tmp.meishihua_allorders` 宽表派生标签、订单域枚举对齐：见同目录 `tmp.meishihua_allorders.sql` 文末「枚举值（派生/标签列，便于与 part1 对照）」段与紧接的「枚举值」段（该文件中 **part1** ＝顶部 DDL 注释块，**part3** ＝文末两节枚举说明）。
