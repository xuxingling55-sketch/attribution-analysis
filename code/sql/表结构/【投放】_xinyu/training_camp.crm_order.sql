-- =====================================================
-- 体验营 CRM 订单表 training_camp.crm_order
-- =====================================================
--
-- 【表粒度】
--   一条订单一条记录；业务表述为「一个体验营用户一笔订单一条」（订单粒度）。
--
-- 【使用场景】
--   - 查询体验营线索用户的付费转化、订单金额、商品类目
--   - 与 `training_camp.tm_extra` 通过 `userid_leads` ↔ `yc_user_id` 关联，分析「成为线索之后」的成交
--
-- 【常用关联】
--   - `training_camp.tm_extra`：`crm_order.userid_leads = tm_extra.yc_user_id`（转化分析时常加 `crm_order.paid_time >= tm_extra.created_at`）
--   - `dw.fact_order_detail`：`crm_order.orderid = fact_order_detail.order_id`（取 `good_kind_name_level_2` 等）
--
-- 【统计口径】（付费转化 + 服务期内高客单标记示例）
--
-- > 主表应为 `crm_order`；原业务稿中误写 `tm_extra` 作主表，以下已按字段归属纠正。`good_kind_name_level_2` 来自订单明细聚合。
--
-- ```sql
-- SELECT o.paid_time,
--        o.userid_leads,
--        o.orderid,
--        o.amount / 100.0 AS amount_yuan,
--        o.realycfrom,
--        fd.good_kind_name_level_2,
--        CASE
--            WHEN te.team_status = '1'
--                 AND (
--                     o.order_type IN ('全价平板', '样机')
--                     OR (o.category = 'big_vip' AND o.order_type <> '样机补差')
--                     OR fd.good_kind_name_level_2 LIKE '%积木块%'
--                 )
--            THEN 1
--            ELSE 0
--        END AS is_high_value_order_in_service
-- FROM training_camp.crm_order o
-- LEFT JOIN (
--     SELECT order_id, good_kind_name_level_2
--     FROM dw.fact_order_detail
--     GROUP BY order_id, good_kind_name_level_2
-- ) fd ON o.orderid = fd.order_id
-- LEFT JOIN training_camp.tm_extra te ON o.userid_leads = te.yc_user_id
-- WHERE o.realycfrom NOT IN ('无坐席', '李文雅')
--   AND o.status IN ('支付成功', '退款成功')
--   AND o.userid_leads <> ''
-- ```
--
-- 【常用筛选条件】
--   ★看「线索的付费转化」时（保证成交发生在成为体验营线索之后）：
--   - `crm_order.paid_time >= tm_extra.created_at`（与 `tm_extra` 关联后）
--
--   场景条件：
--   - `o.status IN ('支付成功', '退款成功')` — 与业务示例一致
--   - `o.realycfrom NOT IN ('无坐席', '李文雅')` — 排除指定坐席口径时
--   - `o.userid_leads <> ''` — 需绑定线索用户时
--
-- 【注意事项】
--   ⚠️ 非分区明细表；Text 存储；更新频率 T+1。
--   ⚠️ 金额字段 `amount` / `order_amount` 单位为分，展示为元需 `/100`。
--
-- =====================================================

CREATE TABLE training_camp.crm_order (
    id BIGINT COMMENT '主键ID',
    orderid STRING COMMENT '订单ID',
    userid STRING COMMENT '用户ID',
    goodid STRING COMMENT '商品ID',
    sku_group_id STRING COMMENT 'sku组ID',
    pay_form STRING COMMENT '支付来源',
    paid_time TIMESTAMP COMMENT '支付时间',
    ycfrom STRING COMMENT '订单坐席来源',
    sellfrom STRING COMMENT '订单来源',
    crm_name STRING COMMENT '坐席名字',
    status STRING COMMENT '订单状态',
    order_amount BIGINT COMMENT '订单金额(单位分)',
    amount BIGINT COMMENT '订单实付金额(单位分)',
    refund_amount BIGINT COMMENT '退款金额(单位分)',
    created_at TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP COMMENT '更新时间',
    deleted_at TIMESTAMP COMMENT '删除时间',
    name STRING COMMENT '订单名',
    qw_user_id_extra STRING COMMENT '企业微信关系',
    qw_user_id STRING COMMENT '坐席企业微信id',
    realycfrom STRING COMMENT '真实ycfrom可编辑',
    unionid STRING COMMENT '微信unionid',
    phone STRING COMMENT 'userId对应的手机号',
    mobiles STRING COMMENT '收货地址手机号',
    province STRING COMMENT '省份',
    pad BIGINT COMMENT '是否含有平板',
    doc STRING COMMENT '备注信息',
    order_type STRING COMMENT '订单类型',
    tags STRING COMMENT '探马标签',
    wechat_nickname STRING COMMENT '微信昵称',
    channel_tag STRING COMMENT '渠道标签',
    phone_leads STRING COMMENT '线索手机号',
    userid_leads STRING COMMENT '线索用户id',
    periods STRING COMMENT '期数',
    is_complement STRING COMMENT '是否已补差',
    refunded_at TIMESTAMP COMMENT '退款时间',
    source STRING COMMENT '线索来源',
    channel STRING COMMENT '渠道',
    channel_id STRING COMMENT '渠道Id',
    channel_account STRING COMMENT '区分账号',
    channel_plan STRING COMMENT '区分计划',
    sale_type STRING COMMENT '商品类型',
    team_status STRING COMMENT '所属团队是否为体验 0不是 1是',
    circulation_id STRING COMMENT '关联流转记录id',
    ph STRING COMMENT '洋葱加密手机号',
    mb STRING COMMENT '洋葱加密收货地址手机号',
    phl STRING COMMENT '洋葱加密线索手机号',
    category STRING COMMENT '商品类别',
    category_remark STRING COMMENT '商品类别备注信息',
    kind_name_first STRING COMMENT '商品一级类目名称',
    kind_level_first STRING COMMENT '商品一级类目id',
    kind_name_second STRING COMMENT '商品二级类目名称',
    kind_level_second STRING COMMENT '商品二级类目id',
    kind_name_third STRING COMMENT '商品三级类目名称',
    kind_level_third STRING COMMENT '商品三级类目id',
    channel_grade STRING COMMENT '渠道年级等',
    order_type_new BIGINT COMMENT '订单类型（新）- int类型，基于OrderCategoryData映射'
) USING text
TBLPROPERTIES (
    'STATS_GENERATED_VIA_STATS_TASK' = 'true',
    'bucketing_version' = '2',
    'transient_lastDdlTime' = '1743611241'
);

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## status（常用）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 支付成功 | 已支付 |
-- | 退款成功 | 已退款（业务示例中与支付成功并列筛选时使用） |
--
-- ## team_status
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 非体验营服务期口径 |
-- | 1 | 体验营服务期内 |
