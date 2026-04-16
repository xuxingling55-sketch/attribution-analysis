-- =====================================================
-- 大盘营收- 实时订单表 ods_rt.order_processing_orders_rt
-- =====================================================
--
-- -- 【表粒度】
-- - 一个id一条数据，无分区字段
--
-- 【业务定位】
--   - 【归属】大盘营收 / 实时订单表。
--   - 与 dw.fact_order_detail 可按 order_id(id) 对齐
--   - 业务实时订单数据，区别于dw.fact_order_detail（t-1更新）

-- 【统计口径】
--   - 与dw.fact_order_detail相同
--
-- 【常用关联】
--   - 与dw.fact_order_detail相同
--
-- 【注意事项】
--   - 更新频率 T
--
-- =====================================================

CREATE TABLE
  `ods_rt`.`order_processing_orders_rt` (
    `_hoodie_commit_time` varchar(1073741824) DEFAULT NULL,
    `_hoodie_commit_seqno` varchar(1073741824) DEFAULT NULL,
    `_hoodie_record_key` varchar(1073741824) DEFAULT NULL,
    `_hoodie_partition_path` varchar(1073741824) DEFAULT NULL,
    `_hoodie_file_name` varchar(1073741824) DEFAULT NULL,
    `id` varchar(1073741824) DEFAULT NULL,
    `user_id` varchar(1073741824) DEFAULT NULL,
    `paid_user_id` varchar(1073741824) DEFAULT NULL,
    `status` varchar(1073741824) DEFAULT NULL,
    `sn` varchar(1073741824) DEFAULT NULL,
    `good_id` varchar(1073741824) DEFAULT NULL,
    `sku_group_good_id` varchar(1073741824) DEFAULT NULL,
    `good_snap_id` varchar(1073741824) DEFAULT NULL,
    `promotion_kind` varchar(1073741824) DEFAULT NULL,
    `promotion_snap_id` varchar(1073741824) DEFAULT NULL,
    `amount` double DEFAULT NULL,
    `payment_platform` varchar(1073741824) DEFAULT NULL,
    `payment_credentials` varchar(1073741824) DEFAULT NULL,
    `creation_way` varchar(1073741824) DEFAULT NULL,
    `is_test` boolean DEFAULT NULL,
    `changed` boolean DEFAULT NULL,
    `paid_time` datetime DEFAULT NULL,
    `extra` varchar(1073741824) DEFAULT NULL,
    `refund_info_list` varchar(1073741824) DEFAULT NULL,
    `recalled` boolean DEFAULT NULL,
    `manually_refunded_by` varchar(1073741824) DEFAULT NULL,
    `manually_paid_by` varchar(1073741824) DEFAULT NULL,
    `attribution` varchar(1073741824) DEFAULT NULL,
    `binding_time` datetime DEFAULT NULL,
    `missed_order` boolean DEFAULT NULL,
    `address` varchar(1073741824) DEFAULT NULL,
    `version` varchar(1073741824) DEFAULT NULL,
    `platform_order_id` varchar(1073741824) DEFAULT NULL,
    `channel_order_id` varchar(1073741824) DEFAULT NULL,
    `created_at` datetime DEFAULT NULL,
    `updated_at` datetime DEFAULT NULL,
    `aim_order_id` varchar(1073741824) DEFAULT NULL,
    `be_settled` boolean DEFAULT NULL,
    `pre_order_ids` varchar(1073741824) DEFAULT NULL,
    `pre_redeem_ids` varchar(1073741824) DEFAULT NULL
  ) PROPERTIES ("location" = "tos://yc-data-platform/user/hive/warehouse/ods_rt.db/order_processing_orders");

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见dw.fact_order_detail的枚举值内容
