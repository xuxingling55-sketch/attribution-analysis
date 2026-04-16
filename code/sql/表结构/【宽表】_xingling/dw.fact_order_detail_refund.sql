-- =====================================================
-- {订单退款表} {dw}.{fact_order_detail_refund}
-- =====================================================
--
-- 【表粒度】★必填
--  每笔子订单的每次退款=一条记录（refund_id+sub_good_sk+order_id 唯一标识） --一个订单，数仓拆到了子订单粒度
--  一个订单会出现多条的情况（如：一个订单分两次退款就会出现两条）
--
-- 【业务定位】
--   看一个订单具体的退款时间使用
--   与全公司订单宽表(dws.topic_order_detail)中总退款金额（total_refund_amt）的区别：
--   -退款总金额是一样的，本表可拆分时间段看具体时间对应的退款金额，全公司订单宽表(dws.topic_order_detail)只能看总退款金额

-- 【常用关联】
--  具体时间退款金额
--  -本表.order_id=dw.dws.topic_order_detail.order_id

-- 【注意事项】
--  一个订单会出现多条的情况（如：一个订单分两次退款就会出现两条），与其他表关联时请注意
--
-- =====================================================

CREATE EXTERNAL TABLE `dw`.`fact_order_detail_refund` (
  `refund_id` string COMMENT '退款ID',
  `is_recalled` string COMMENT '是否收回权益',
  `refund_time` timestamp COMMENT '退款时间',
  `refund_time_sk` string COMMENT '退款时间sk',
  `refund_amount` double COMMENT '退款金额',
  `remain_amount` double COMMENT '剩余金额',
  `order_id` string COMMENT '订单业务id',
  `good_sk` int COMMENT '商品代理键',
  `good_name` string COMMENT '商品名',
  `sub_good_sk` int COMMENT '子商品代理键',
  `sub_good_cnt` int COMMENT '子商品的个数',
  `user_sk` int COMMENT '用户代理键',
  `u_user` string COMMENT '用户ID',
  `order_date_sk` int COMMENT '订单创建日期代理键',
  `status` string COMMENT '订单状态',
  `kind` string COMMENT '子商品的类型',
  `stage_id` int COMMENT '学段',
  `stage_name` string COMMENT '学段名称',
  `subject_id` int COMMENT '学科',
  `subject_name` string COMMENT '学科名称',
  `semester_id` int COMMENT '学期',
  `semester_name` string COMMENT '学期名称',
  `publisher_id` int COMMENT '版本',
  `publisher_name` string COMMENT '版本名称',
  `amount` double COMMENT '订单实收金额',
  `sub_amount` double COMMENT '子商品实收金额',
  `add_time_ms` bigint COMMENT '增加的服务时长',
  `add_time_day` int COMMENT '增加的服务时长（天）',
  `client_os` string COMMENT '设备类型',
  `payment_platform` string COMMENT '支付平台[ping++',
  `activate_time_sk` int COMMENT '激活时间',
  `role` string COMMENT '用户角色',
  `business_group` string COMMENT '业务群',
  `business_id` string COMMENT '商户ID',
  `platform_id` string COMMENT '平台ID',
  `product_id` string COMMENT '产品id',
  `is_group_buy` boolean COMMENT '是否线下渠道团购订单',
  `app_version` string COMMENT 'APP版本号',
  `payment_channel` string COMMENT '支付渠道，微信支付、支付宝支付、银联',
  `coupon` string COMMENT '业务系统中代金券id',
  `app_channel` string COMMENT '创建订单的App的下载渠道，苹果是appstore',
  `is_by_manual` boolean COMMENT '是否是手工订单',
  `account_id` string COMMENT '账户id',
  `shop_id` string COMMENT '推广来源id',
  `shop_name` string COMMENT '推广来源',
  `is_parent_telemarketing` smallint COMMENT '是否属于家长电销订单',
  `seat_no` string COMMENT '坐席号',
  `mid_revenue_amount` double COMMENT '中学营收',
  `mid_revenue_finance_amount` double COMMENT '中学营收-财务',
  `teacher_school_revenue_amount` double COMMENT '教师和线下营收',
  `teacher_school_revenue_finance_amount` double COMMENT '教师和线下营收-财务',
  `parent_revenue_amount` double COMMENT '家长营收',
  `parent_revenue_finance_amount` double COMMENT '家长营收-财务',
  `primary_revenue_amount` double COMMENT '小学营收',
  `primary_revenue_finance_amount` double COMMENT '小学营收-财务',
  `other_revenue_amount` double COMMENT '其他营收（不归属于四大业务群）',
  `dw_insert_time` timestamp COMMENT '插入时间',
  `service_amount` double COMMENT '服务费',
  `procedures_amount` double COMMENT '手续费',
  `return_amount` double COMMENT '退回金额',
  `is_by_manual_opertion` boolean COMMENT '是否是手工操作',
  `good_id` string COMMENT '商品id',
  `deficit_amount` double COMMENT '亏损金额',
  `procedures_deficit_amount` double COMMENT '手续费亏损金额',
  `platform_deficit_amount` double COMMENT '平台亏损金额',
  `activate_time` timestamp COMMENT '激活时间',
  `grade` string COMMENT '用户填写年级',
  `mid_grade` string COMMENT '中学修正年级',
  `mid_stage_name` string COMMENT '中学修正学段',
  `gender` string COMMENT '用户性别',
  `regist_time` timestamp COMMENT '注册时间',
  `regist_time_sk` int COMMENT '注册时间sk',
  `regist_channel` string COMMENT '注册渠道',
  `u_from` string COMMENT '系统平台',
  `regist_type` string COMMENT '注册方式(枚举值)',
  `is_put_channel` smallint COMMENT '是否投放渠道',
  `province` string COMMENT '省',
  `province_code` string COMMENT '省code',
  `city` string COMMENT '市',
  `city_code` string COMMENT '市code',
  `area` string COMMENT '区',
  `area_code` string COMMENT '区code',
  `is_test_user` smallint COMMENT '是否测试用户',
  `is_teach_user` smallint COMMENT '是否教学班用户',
  `is_admin_room` smallint COMMENT '是否行政班用户',
  `is_room_user` smallint COMMENT '是否有班用户',
  `is_new_user` smallint COMMENT '是否新用户',
  `school_sk` int COMMENT '学校sk',
  `school_id` string COMMENT '学校id',
  `school_sk1` int COMMENT '学校sk1',
  `school_id1` string COMMENT '学校id1',
  `user_attribution` string COMMENT '用户活跃时归属',
  `regist_user_attribution` string COMMENT '用户注册当天归属',
  `refund_reason` string COMMENT '退款原因，多个原因由"="隔开',
  `check_attribution` string COMMENT '数据中台计算B/C订单归属',
  `new_media_revenue_finance_amount` double COMMENT '新媒体财务营收',
  `original_amount` double COMMENT '订单原价',
  `business_attribution` string COMMENT '业务群营收归属',
  `sku_name` string COMMENT 'sku名字',
  `model_type` string COMMENT '平板型号',
  `team_ids` array < string > COMMENT '全域业绩归属',
  `team_names` array < string > COMMENT '全域业绩归属',
  `good_category` string COMMENT '商品类别'
) COMMENT '基于订单明细表的退款表，每笔子订单的每次退款一条记录' ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dw.db/fact_order_detail_refund' TBLPROPERTIES (
  'alias' = '订单退款表',
  'bucketing_version' = '2',
  'discover.partitions' = 'true',
  'is_core' = 'true',
  'last_modified_by' = 'finebi',
  'last_modified_time' = '1740454797',
  'primary_key' = 'refund_id',
  'transient_lastDdlTime' = '1774379938'
)


-- =====================================================
-- 枚举值
-- =====================================================
-- 暂时没有用到
