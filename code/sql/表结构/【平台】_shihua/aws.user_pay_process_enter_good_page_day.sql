-- =====================================================
-- 商品页转化- 从曝光商品介绍页到付费转化日表 aws.user_pay_process_enter_good_page_day
-- =====================================================
--
--
-- -- 【表粒度】
-- - 一个用户一个from_page_name一个operate_id一个section_id一个sessionid一条数据，分区字段：day
--
-- 【业务定位】
--   - 【归属】商品页转化 / 从曝光商品介绍页到付费转化日表。
-- - 与 dws.topic_user_active_detail_day 按 u_user + day 关联；含 *_day 后缀分层字段（与活跃日表同名字段语义不完全等同，见 table-relations）；与 dw.dim_user 可按 u_user 对齐
--   - 埋点商品介绍页到付费的漏斗数据，来源于events.frontend_event_orc
--   - 与 aws.business_user_pay_process_enter_good_page_day 区别：本表的商品曝光页面不包含直播间的曝光数据，且少了live_id等几个新维度字段

-- 【统计口径】
--   - 见part3
--
-- 【常用关联】
--   - u_user、day 对齐 dws.topic_user_active_detail_day
--
-- 【常用筛选条件】
--   - day
--
-- 【注意事项】
--   - 更新频率 T+1
--
-- =====================================================

CREATE TABLE
  `aws`.`user_pay_process_enter_good_page_day` (
    `u_user` varchar(1073741824) DEFAULT NULL COMMENT '用户 id',
    `session_id` varchar(1073741824) DEFAULT NULL COMMENT 'sessionid',
    `page_name` varchar(1073741824) DEFAULT NULL COMMENT '页面名称',
    `session_public` varchar(1073741824) DEFAULT NULL COMMENT 'session_public',
    `type` varchar(1073741824) DEFAULT NULL COMMENT '类别',
    `page_type` varchar(1073741824) DEFAULT NULL COMMENT '页面类别',
    `task_id` varchar(1073741824) DEFAULT NULL COMMENT '任务id',
    `section_id` varchar(1073741824) DEFAULT NULL COMMENT 'section_id',
    `from_page_name` varchar(1073741824) DEFAULT NULL COMMENT '来源页面',
    `operate_id` varchar(1073741824) DEFAULT NULL COMMENT 'operate_id',
    `status` varchar(1073741824) DEFAULT NULL COMMENT '状态',
    `event_time` varchar(1073741824) DEFAULT NULL COMMENT '进入商品页时间',
    `good_id` varchar(1073741824) DEFAULT NULL COMMENT '商品id',
    `position` varchar(1073741824) DEFAULT NULL COMMENT '位置',
    `order_id` varchar(1073741824) DEFAULT NULL COMMENT '订单id',
    `amount` double DEFAULT NULL COMMENT '订单 金额',
    `button_info` array<varchar(1073741824)> DEFAULT NULL COMMENT '商品页按钮点击信息',
    `click_good_intro_page_user` varchar(1073741824) DEFAULT NULL COMMENT '点进商品页用户id',
    `enter_payment_page_user` varchar(1073741824) DEFAULT NULL COMMENT '进入支付页用户id',
    `click_payment_confirm_user` varchar(1073741824) DEFAULT NULL COMMENT '点击支付用户id',
    `get_create_order_user` varchar(1073741824) DEFAULT NULL COMMENT '创建订单用户id',
    `pay_order_user` varchar(1073741824) DEFAULT NULL COMMENT '支付订单用户id',
    `click_good_intro_page_button_user` varchar(1073741824) DEFAULT NULL COMMENT '点击按钮用户id',
    `order_sell_from` varchar(1073741824) DEFAULT NULL COMMENT '商品售卖来源',
    `suit_id` array<varchar(1073741824)> DEFAULT NULL COMMENT '商品ID或sku商品组ID',
    `product_id` varchar(1073741824) DEFAULT NULL COMMENT '产品ID',
    `day` int(11) DEFAULT NULL
 ) PARTITION BY (day) COMMENT ("null") PROPERTIES ("location" = "tos://yc-data-platform/user/hive/warehouse/aws.db/user_pay_process_enter_good_page_day");

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见aws.business_user_pay_process_day的枚举值内容
