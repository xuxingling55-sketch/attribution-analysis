-- =====================================================
-- 大盘营收- 订单明细表 dw.fact_order_detail
-- =====================================================
--
-- 【表粒度】
--   一笔订单的一个子商品一条记录（支付成功/退款成功等非测试，见表 COMMENT）
--   无分区（本导出；以线上为准）
--
-- 【业务定位】
--   - 【归属】大盘营收 / 订单明细表。
--   - 数仓底层订单事实；dws.topic_order_detail 上游之一
--   - 与 dw.dim_date 等按 date_sk 关联
--
-- 【统计口径】
--   金额类见 COMMENT；正价与营收展示多在宽表 glossary 口径
--
-- 【常用关联】
--   - `date_sk` 与 `dw.dim_date` 对齐；`u_user` 与 `dw.dim_user` / 订单宽表 `dws.topic_order_detail` 对齐（宽表上游之一）
--
-- 【常用筛选条件】
--   场景条件：
--   - status、is_test_user 等在本表或下游宽表按需求
--
-- 【注意事项】
--   - 更新频率 T+1
--   - 【数据来源】code/sql/临时文件/dw.fact_order_detail.md

CREATE EXTERNAL TABLE `dw`.`fact_order_detail` (
  `order_id` string COMMENT '订单业务id',
  `good_sk` int COMMENT '商品代理键',
  `good_name` string COMMENT '商品名',
  `sub_good_cnt` int COMMENT '子商品的个数',
  `sub_good_sk` int COMMENT '子商品代理键',
  `user_sk` int COMMENT '用户代理键',
  `u_user` string COMMENT '用户ID',
  `date_sk` int COMMENT '订单创建日期代理键',
  `update_time_sk` int COMMENT '订单修改日期代理键',
  `status` string COMMENT '当前订单状态',
  `kind` string COMMENT '子商品的类型，英文[vip',
  `stage_id` int COMMENT '学段',
  `stage_name` string COMMENT '学段名',
  `subject_id` int COMMENT '学科',
  `subject_name` string COMMENT '学科名',
  `semester_id` int COMMENT '学期',
  `semester_name` string COMMENT '学期名',
  `good_original_amount` double COMMENT '商品原价',
  `original_amount` double COMMENT '订单原价',
  `amount` double COMMENT '订单实收金额',
  `discount_amount` double COMMENT '优惠金额',
  `sub_amount` double COMMENT '子商品实收金额',
  `add_time_ms` bigint COMMENT '增加的服务时长',
  `add_time_day` int COMMENT '增加的服务时长（天）',
  `client_os` string COMMENT '设备类型',
  `payment_platform` string COMMENT '支付平台[ping++',
  `platform_id` string COMMENT '平台ID',
  `business_id` string COMMENT '商户ID',
  `role` string COMMENT '用户角色',
  `business_group` string COMMENT '业务群',
  `activate_time_sk` int COMMENT '激活时间',
  `create_time` timestamp COMMENT '源系统创建条目的时间',
  `update_time` timestamp COMMENT '源系统修改条目的时间',
  `dw_insert_time` timestamp COMMENT 'ETL插入记录的时间',
  `dw_update_time` timestamp COMMENT 'ETL修改记录的时间',
  `publisher_id` int COMMENT '版本',
  `publisher_name` string COMMENT '教材版本名',
  `product_id` string COMMENT '产品id',
  `is_group_buy` boolean COMMENT '是否线下渠道团购订单',
  `app_version` string COMMENT 'APP版本号',
  `service_amount` double COMMENT '服务费',
  `procedures_amount` double COMMENT '手续费',
  `arrival_amount` double COMMENT '到账金额',
  `payment_channel` string COMMENT '支付渠道，微信支付、支付宝支付、银联',
  `coupon` string COMMENT '业务系统中代金券id，未使用代金券时统一为 unused',
  `app_channel` string COMMENT '创建订单的App的下载渠道，苹果是appstore',
  `transaction_no` string COMMENT '支付平台生成的交易流水号',
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
  `paid_time` timestamp COMMENT '支付时间',
  `paid_time_sk` int COMMENT '支付时间sk',
  `recalled` boolean COMMENT '权限是否收回',
  `total_refund_amt` double COMMENT '总退款金额',
  `refund_info_list` array < string > COMMENT '退款详情',
  `remain_amt` double COMMENT '剩余金额',
  `shop_detail_id` string COMMENT '推广来源明细id',
  `shop_detail_name` string COMMENT '推广来源明细名称',
  `os` string COMMENT '端口',
  `is_by_manual_opertion` boolean COMMENT '是否手工标记订单',
  `activate_time` timestamp COMMENT '激活时间',
  `good_id` string COMMENT '商品id',
  `attribution` string COMMENT 'B/C订单归属',
  `check_attribution` string COMMENT '数据中台计算B/C订单归属',
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
  `missed_order` boolean COMMENT '是否掉单',
  `group` array < string > COMMENT '标签',
  `real_add_time_day` int COMMENT '真实服务时长',
  `real_activate_time` timestamp COMMENT '真实激活时间',
  `sell_from` string COMMENT '商品售卖来源',
  `new_media_revenue_finance_amount` double COMMENT '新媒体财务营收',
  `institution_revenue_finance_amount` double COMMENT '机构财务营收',
  `business_attribution` string COMMENT '业务群归属：b 端营收、小学网课营收、轻课营收',
  `yc_from` string COMMENT '机构名称',
  `sku_amount` double COMMENT 'sku 价格',
  `sku_name` string COMMENT 'sku名字',
  `procedures_rate` double COMMENT '手续费率',
  `sn` string COMMENT 'pad sn',
  `good_sell_kind` string COMMENT '商品售卖类型',
  `is_pad_price_difference_order` boolean COMMENT '是否体验机补差价订单',
  `new_media_type` string COMMENT '新媒体营收类型',
  `model_type` string COMMENT '平板型号',
  `insurance_category` string COMMENT '保险类别',
  `dynamic_diff_price_type` string COMMENT '补差价类型',
  `binding_time` timestamp COMMENT '绑定时间',
  `binding_time_sk` int COMMENT '绑定时间sk',
  `good_year` string COMMENT '商品时长',
  `good_content` string COMMENT '内容标识',
  `business_gmv_attribution` string COMMENT '业务GMV归属划分',
  `xugou_order_kind` string COMMENT '续购订单类型',
  `xugou_pre_order_id` string COMMENT '续购前序订单id',
  `discount_id` string COMMENT '优惠券id',
  `discount_note` string COMMENT '优惠券note',
  `discount_price` double COMMENT '优惠券金额（元）',
  `special_course_type` string COMMENT '课程包类型',
  `discount_order_id` string COMMENT '尾款订单的优惠券订单id',
  `team_ids` array < string > COMMENT '全域业绩归属',
  `team_names` array < string > COMMENT '全域业绩归属',
  `good_category` string COMMENT '商品类别',
  `sku_group_good_id` string COMMENT 'sku商品组id',
  `good_type` string COMMENT '商品类型(已弃用,推荐使用good_kind_name_level_2)',
  `correct_team_names` array < string > COMMENT '修正后业绩归属',
  `first_order_type` string COMMENT '前序订单类型',
  `last_order_type` string COMMENT '尾单类型',
  `coupon_order_id` string COMMENT '前序优惠券订单id',
  `pad_type` string COMMENT '平板类型',
  `pre_order_id` string COMMENT '前序订单id',
  `live_platform_tag` string COMMENT '直播平台标签',
  `good_kind_name_level_1` string COMMENT '商品类目-一级',
  `good_kind_name_level_2` string COMMENT '商品类目-二级',
  `good_kind_name_level_3` string COMMENT '商品类目-三级',
  `good_kind_id_level_1` string COMMENT '商品类目-一级id',
  `good_kind_id_level_2` string COMMENT '商品类目-二级id',
  `good_kind_id_level_3` string COMMENT '商品类目-三级id',
  `auth_time_sk` int COMMENT '授权赋予时间',
  `good_type_src` string COMMENT '业务系统：售后方式:\"Duration\"时长型,\"Timing\"到期型',
  `strategy_type` string COMMENT '策略类型:20260101上线以后为业务数据，之前按规则清洗',
  `strategy_detail` string COMMENT '策略明细：策略及对应的金额明细'
)
COMMENT '一笔订单一个子商品一条记录 根据子商品拆分的子订单，只包含支付成功和退款成功的非测试订单'

ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
LOCATION 'tos://yc-data-platform/user/hive/warehouse/dw.db/fact_order_detail'

-- =====================================================
-- 枚举值
-- =====================================================
--
-- > 按 glossary【平台】规则 R34：本表为 **DW 明细层**订单事实；下游 `dws.topic_order_detail` 等在宽表上沉淀了与取数强相关的完整枚举。
-- > **与宽表同名字段**（如 `status`、`good_kind_name_level_*`、`business_user_pay_status_*`、`user_strategy_tag_*`、`client_os`、`payment_channel`、`attribution`、`role`、`grade` / `mid_stage_name` 等）：码值与业务含义 **继承** `dws.topic_order_detail.sql` 第三段「枚举值」对应小节；本表不重复罗列。
-- > 若某字段仅在事实表出现、宽表无同名说明，以本表字段 **COMMENT** 与线上数据为准。
-- > 布尔、金额、时间、数组等无离散业务枚举的列不在此段展开。
--
