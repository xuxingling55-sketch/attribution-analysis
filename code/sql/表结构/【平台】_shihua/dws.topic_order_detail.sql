-- =====================================================
-- 大盘营收- 订单宽表 dws.topic_order_detail
-- =====================================================
--
-- 【表粒度】
--   一笔子订单一条记录（order_id + sub_good_sk 区分粒度；全渠道订单宽表）
--   无 Hive 分区（以线上 Metastore 为准）；分析/取数常用 `paid_time_sk` 收窄；第三段枚举为基于 `paid_time_sk` 窗口的实查快照（见该段文首）
--
-- 【业务定位】
--   - 【归属】大盘营收 / 订单宽表。
--   - 全渠道 GMV、商品类目、用户购买历史、策略标签（2.0）等的主表之一
--   - 与 aws.crm_order_info 可按 order_id 对齐；电销专属营收优先用 crm 表，见 `knowledge/glossary.md`
--
-- 【统计口径】
--   营收：SUM(order_amount)（订单去重口径）或 SUM(sub_amount)（子订单）；正价等见 `knowledge/glossary.md`
--
-- 【常用关联】
--   - tmp.meishihua_good_day_order_info：`join first_order_info b on a.order_id = b.order_id`（a 为本表）
--   - tmp.meishihua_product_kind_day / good_day：from 本表聚合（无与别表 JOIN）
--   - tmp.lidanping_channel_amount_fuwuqi1 / month1：from 本表子查询聚合（无 JOIN）
--   - 看板「新品销量表现_*」：`left join peiyou_sku_names b on a.order_id = b.order_id`（a 为本表）
--   - 看板「活动专题-实物赠品」：`join sub_good_sk b on a.sub_good_sk = b.sub_good_sk`
--
-- 【常用筛选条件】

--   场景条件：
--   - status = '支付成功' -- 看退款后实收/GMV 时
--   - order_amount >= 39 / sum(sub_amount) >= 39 -- 正价订单
--   - 商业化平台的[正价订单]原口径一般是 original_amount >= 39
--
-- 【注意事项】
--   - 更新频率 T+1（以调度为准）
--   - 知识库约定：取数与分析仅使用 business_user_pay_status_*；user_pay_status_*（无 business_ 前缀）列不在知识库维护口径

CREATE EXTERNAL TABLE `dws`.`topic_order_detail` (
  `order_id` string COMMENT '订单业务id',
  `create_time` timestamp COMMENT '源系统创建条目的时间',
  `create_time_sk` string COMMENT '创建时间 sk（字符串存储，与 paid_time_sk 等同理）',
  `paid_time` timestamp COMMENT '支付时间',
  `paid_time_sk` int COMMENT '支付时间sk',
  `is_normal_price` smallint COMMENT '是否正价订单',
  `is_group_buy` smallint COMMENT '是否团购订单',
  `is_by_manual` smallint COMMENT '是否是手工订单',
  `business_group` string COMMENT '业务群',
  `add_time_ms` bigint COMMENT '增加的服务时长',
  `add_time_day` int COMMENT '增加的服务时长（天）',
  `product_id` string COMMENT '产品id',
  `payment_channel` string COMMENT '支付渠道，微信支付、支付宝支付、银联',
  `app_channel` string COMMENT '创建订单的App的下载渠道，苹果是appstore',
  `payment_platform` string COMMENT '支付平台[ping++',
  `client_os` string COMMENT '设备类型',
  `is_recalled` smallint COMMENT '退款后是否回收权益',
  `shop_name` string COMMENT '推广来源',
  `shop_id` string COMMENT '推广来源id',
  `shop_detail_id` string COMMENT '推广来源明细id',
  `shop_detail_name` string COMMENT '推广来源明细名称',
  `discount_amount` double COMMENT '优惠金额',
  `service_amount` double COMMENT '服务费',
  `procedures_amount` double COMMENT '手续费',
  `arrival_amount` double COMMENT '到账金额',
  `register_pay_duration` int COMMENT '付费周期 （支付日期-注册日期）',
  `order_sn` int COMMENT '用户在当前下单属于第几次购买',
  `normal_price_order_sn` int COMMENT '用户在当前下单属于第几次正价购买',
  `channel_normal_price_order_sn` int COMMENT '用户在当前下单渠道属于第几次正价购买',
  `good_sk` int COMMENT '商品代理键',
  `good_name` string COMMENT '商品名',
  `good_stage_subject` string COMMENT '商品【学科-学段-类型】数组',
  `sub_good_cnt` int COMMENT '子商品的个数',
  `good_subject_cnt` int COMMENT '学科数',
  `sub_good_sk` int COMMENT '子商品代理键',
  `kind` string COMMENT '子商品的类型，英文[vip',
  `stage_id` int COMMENT '学段',
  `stage_name` string COMMENT '学段名',
  `subject_id` int COMMENT '学科',
  `subject_name` string COMMENT '学科名',
  `semester_id` int COMMENT '学期',
  `semester_name` string COMMENT '学期名',
  `good_original_amount` double COMMENT '商品原价',
  `sub_amount` double COMMENT '子商品实收金额',
  `ss_order_sn` int COMMENT '用户当前学段学科在当前下单属于第几次购买',
  `ss_normal_price_order_sn` int COMMENT '用户当前学段学科在当前下单属于第几次正价购买',
  `before_order_last_end_time` timestamp COMMENT '购买订单前权限到期日期',
  `end_pay_duration` int COMMENT '用户当前学段学科订单支付日期和权益截止日期差值（天数）',
  `stage_order_sn` int COMMENT '用户当前学段在当前下单属于第几次购买',
  `stage_normal_price_order_sn` int COMMENT '用户当前学段在当前下单属于第几次正价购买',
  `user_sk` int COMMENT '用户代理键',
  `u_user` string COMMENT '用户id',
  `role` string COMMENT '用户角色',
  `grade` string COMMENT '用户填写年级',
  `mid_stage_name` string COMMENT '中学修正学段',
  `gender` string COMMENT '用户性别',
  `user_attribution` string COMMENT '用户活跃时归属',
  `attribution` string COMMENT 'B/C订单归属',
  `city_class` string COMMENT '城市分线',
  `province` string COMMENT '省',
  `province_code` string COMMENT '省code',
  `city` string COMMENT '市',
  `city_code` string COMMENT '市code',
  `area` string COMMENT '区',
  `area_code` string COMMENT '区code',
  `school_id` string COMMENT '学校id',
  `school_sk` int COMMENT '学校sk',
  `school_id1` string COMMENT '学校id1',
  `school_sk1` int COMMENT '学校sk1',
  `is_test_user` smallint COMMENT '是否测试用户',
  `is_teach_user` smallint COMMENT '是否教学班用户',
  `is_room_user` smallint COMMENT '是否有班用户',
  `is_new_user` smallint COMMENT '是否新用户',
  `is_telemarketing_user` smallint COMMENT '是否是电销触达',
  `regist_time` timestamp COMMENT '用户注册时间',
  `is_parent_telemarketing` smallint COMMENT '是否属于家长电销订单',
  `group` array < string > COMMENT '标签',
  `good_sell_kind` string COMMENT '商品售卖类型',
  `sell_from` string COMMENT '商品售卖来源',
  `is_pad_price_difference_order` smallint COMMENT '是否体验机补差价订单',
  `light_class_before_sum_amount` int COMMENT '轻课营收之前的金额',
  `light_class_sum_amount` int COMMENT '轻课营收加上本次的金额',
  `before_sum_amount` int COMMENT '订单之前的金额',
  `sum_amount` int COMMENT '订单加上这次的金额',
  `user_pay_status_statistics` string COMMENT '【知识库不引用】取数用 business_user_pay_status_statistics。原：付费标签：统计维度口径 ',
  `user_pay_status_business` string COMMENT '【知识库不引用】取数用 business_user_pay_status_business。原：付费标签：业务维度口径',
  `business_attribution` string COMMENT '业务群归属：b 端营收、小学网课营收、轻课营收',
  `original_amount` double COMMENT '订单原价',
  `mid_grade` string COMMENT '中学年级',
  `status` string COMMENT '当前订单状态',
  `good_id` string COMMENT '商品id',
  `dynamic_diff_price_type` string COMMENT '补差价类型',
  `good_year` string COMMENT '商品时长',
  `good_content` string COMMENT '内容标识',
  `xugou_order_kind` string COMMENT '续购订单类型',
  `xugou_pre_order_id` string COMMENT '续购前序订单id',
  `discount_id` string COMMENT '优惠券id',
  `discount_note` string COMMENT '优惠券note',
  `discount_price` double COMMENT '优惠券金额（元）',
  `special_course_type` string COMMENT '课程包类型',
  `business_gmv_attribution` string COMMENT '业务GMV归属划分',
  `sync_type` smallint COMMENT '同步方式：1-自动判单>，2-申诉, 3-七陌导入, 4-专属链接',
  `sync_status` smallint COMMENT '同步状态：1->正常，2->异常',
  `model_type` string COMMENT '平板型号',
  `order_amount` double COMMENT '订单实收金额',
  `order_first_refund_time` timestamp COMMENT '订单首次退费时间',
  `sku_amount` double COMMENT 'sku 价格',
  `sku_name` string COMMENT 'sku名字',
  `procedures_rate` double COMMENT '手续费率',
  `workplace_id` int COMMENT '销售职场id',
  `department_id` int COMMENT '学部id',
  `regiment_id` int COMMENT '团id',
  `heads_id` int COMMENT '主管组id',
  `team_id` int COMMENT '小组id',
  `worker_id` int COMMENT '坐席id',
  `worker_name` string COMMENT '坐席名称',
  `insurance_category` string COMMENT '保险类别',
  `sn` string COMMENT 'pad sn',
  `yc_from` string COMMENT '机构名称',
  `total_refund_amt` double COMMENT '总退款金额',
  `team_ids` array < string > COMMENT '全域业绩归属',
  `team_names` array < string > COMMENT '全域业绩归属',
  `good_category` string COMMENT '商品类别',
  `platform_id` string COMMENT '平台ID',
  `business_id` string COMMENT '商户ID',
  `tiktok_author_id` string COMMENT '抖音订单直播主播id',
  `tiktok_author_name` string COMMENT '抖音订单直播主播名称',
  `tiktok_first_author_name` string COMMENT '抖音订单直播主播首次名称',
  `good_type` string COMMENT '商品类型(已弃用,推荐使用good_kind_name_level_2)',
  `phone` string COMMENT '手机号',
  `hire_purchase_num` int COMMENT '分期数',
  `interest_subsidy_method` string COMMENT '贴息方式',
  `hire_purchase_commission` double COMMENT '分期手续费',
  `real_deductible_price` double COMMENT '补差总金额',
  `deduct_category` string COMMENT '补差类型',
  `business_user_pay_status_statistics` string COMMENT '商业化付费会员拆分为大会员付费、非大会员付费',
  `regist_user_allocation` array < string > COMMENT '用户注册当天服务期归属',
  `business_user_pay_status_business` string COMMENT '付费分层-业务维度',
  `correct_team_names` array < string > COMMENT '修正后业绩归属',
  `pad_type` string COMMENT '平板类型',
  `live_platform_tag` string COMMENT '直播平台标签',
  `actual_deduct_amount` double COMMENT '用户实际的抵扣金额，单位：元',
  `max_deduct_amount` double COMMENT '该策略的最高抵扣金额，单位：元',
  `grade_stage_name_day` string COMMENT '付费当天年级学段',
  `grade_name_month` string COMMENT '付费当月年级',
  `stage_name_month` string COMMENT '付费当月学段',
  `grade_stage_name_month` string COMMENT '付费当月年级学段',
 `user_pay_status_statistics_month` string COMMENT '【知识库不引用】取数用 business_user_pay_status_statistics_month。原：付费当月首次标签新增(统计日期当天注册的)、付费(统计日期之前买过正价课)、老未(统计日期之前注册的)',
 `user_pay_status_business_month` string COMMENT '【知识库不引用】取数用 business_user_pay_status_business_month。原：付费当月首次付费标签 付费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)',
 `business_user_pay_status_statistics_month` string COMMENT '付费当月首次付费标签新增(统计日期当天注册的)、大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、老未(统计日期之前注册的)',
 `business_user_pay_status_business_month` string COMMENT '付费当月首次付费标签大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)',
  `grade_name_year` string COMMENT '付费当年年级',
  `stage_name_year` string COMMENT '付费当年学段',
  `grade_stage_name_year` string COMMENT '付费当年年级学段',
 `user_pay_status_statistics_year` string COMMENT '【知识库不引用】取数用 business_user_pay_status_statistics_year。原：付费当年首次付费标签：新增(统计日期当天注册的)、付费(统计日期之前买过正价课)、老未(统计日期之前注册的)',
 `user_pay_status_business_year` string COMMENT '【知识库不引用】取数用 business_user_pay_status_business_year。原：付费当年首次付费标签：付费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)',
 `business_user_pay_status_statistics_year` string COMMENT '付费当年首次付费标签： 新增(统计日期当天注册的)、大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、老未(统计日期之前注册的)',
 `business_user_pay_status_business_year` string COMMENT '付费当年首次付费标签：大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)',
  `good_stage_subject_cnt` int COMMENT '学段学科个数',
  `sku_group_good_id` string COMMENT 'sku商品组id',
  `good_kind_name_level_1` string COMMENT '商品类目-一级',
  `good_kind_name_level_2` string COMMENT '商品类目-二级',
  `good_kind_name_level_3` string COMMENT '商品类目-三级',
  `good_kind_id_level_1` string COMMENT '商品类目-一级id',
  `good_kind_id_level_2` string COMMENT '商品类目-二级id',
  `good_kind_id_level_3` string COMMENT '商品类目-三级id',
  `fix_good_kind_id_level_2` string COMMENT '修正-商品类目-二级id(积木块抵扣「升单商品」专用)',
  `fix_good_kind_name_level_2` string COMMENT '修正-商品类目-二级(积木块抵扣「升单商品」专用)',
  `is_clue_seat` smallint COMMENT '线索是否在坐席名下',
  `fix_good_year` string COMMENT '修正的商品时长',
  `business_good_kind_name_level_1` string COMMENT '策略组修正-商品类目-一级',
  `business_good_kind_name_level_2` string COMMENT '策略组修正-商品类目-二级',
  `business_good_kind_name_level_3` string COMMENT '策略组修正-商品类目-三级',
  `fix_deductible_price` double COMMENT '修正-补差价总金额',
  `course_timing_kind` string COMMENT '商品分类标签',
  `course_group_kind` string COMMENT '商品分组标签',
  `strategy_type` string COMMENT '策略类型:20260101上线以后为业务数据，之前按规则清洗',
  `strategy_detail` string COMMENT '策略明细：策略及对应的金额明细',
  `userauth_exchange_time` timestamp COMMENT '授权转换时间',
  `delay_vip_activation_time` timestamp COMMENT '囤课品激活时间',
  `multi_child_refund_time` timestamp COMMENT '多孩策略退差价时间',
  `user_strategy_tag_day` string COMMENT '策略用户分层-日',
  `big_vip_kind_day` string COMMENT '历史大会员标签-日',
  `user_strategy_eligibility_day` string COMMENT '用户策略资格-日',
  `user_strategy_tag_month` string COMMENT '策略用户分层-月',
  `big_vip_kind_month` string COMMENT '历史大会员标签-月',
  `user_strategy_eligibility_month` string COMMENT '用户策略资格-月',
  `user_strategy_tag_year` string COMMENT '策略用户分层-年',
  `big_vip_kind_year` string COMMENT '历史大会员标签-年',
  `user_strategy_eligibility_year` string COMMENT '用户策略资格-年'
) COMMENT '一笔子订单一条记录' ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dws.db/topic_order_detail'

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 本表无 Hive 分区；以下为跳板机 Impala 查询 `dws.topic_order_detail`，`paid_time_sk BETWEEN 20260209 AND 20260326`（以 `MAX(paid_time_sk)=20260326` 为锚向前 45 自然日，避免仅截单日导致枚举过窄）；全历史或其它窗口可能存在未列出取值。
-- 「含义」自 `code/sql/表结构` 及 `knowledge/glossary.md` 可对照处已填，其余空；`good_kind_*` / `fix_*` id 类无其它 DDL 逐 id 释义。
--
-- ## is_group_buy（是否团购订单）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 否（见字段 COMMENT） |
-- | 1 | 是（见字段 COMMENT） |
--
-- ## sell_from（商品售卖来源）
--
-- > 窗口内 DISTINCT 共 891 条（高基数字段）；下列为全量枚举。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL |  |
-- | (空字符串) |  |
-- | app |  |
-- | app_ study-studyPlanEntrance-upgradeCourse_初中物理培优课_聚合页 |  |
-- | app_AI私教付费介绍页 |  |
-- | app_AI私教付费介绍页_AI定制结果页面 |  |
-- | app_AI私教付费介绍页_app-zuheshangping-tenon |  |
-- | app__app-zuheshangping-tenon |  |
-- | app__多孩续购会场 |  |
-- | app__首购会场 |  |
-- | app__首购会场_ruxiao |  |
-- | app__首购会场_zhibojian |  |
-- | app_achievement_付费介绍页-初中数学 |  |
-- | app_achievement_付费介绍页-初中数学_ruxiao |  |
-- | app_achievement_付费介绍页-小学数学 |  |
-- | app_ad-learntab-banner_app-zuheshangping-tenon |  |
-- | app_ad-learntab-banner_首购会场 |  |
-- | app_ad-learntab-banner_首购会场_ruxiao |  |
-- | app_ad-learntab-banner_首购会场_zhibojian |  |
-- | app_ad-learntab-banner_首购会场_zhibojian_首购会场 |  |
-- | app_ad-learntab-npcDialogue_首购会场 |  |
-- | app_ad-learntab-npcDialogue_首购会场_ruxiao |  |
-- | app_ad-learntab-npcDialogue_首购会场_zhibojian |  |
-- | app_ad-learntab-npcDialogue_首购会场_zhibojian_首购会场 |  |
-- | app_ad-learntab-openScreen_首购会场 |  |
-- | app_ad-learntab-openScreen_首购会场_ruxiao |  |
-- | app_ad-learntab-openScreen_首购会场_zhibojian |  |
-- | app_ad-learntab-openScreen_首购会场_zhibojian_首购会场 |  |
-- | app_ad-mytab-notification_首购会场 |  |
-- | app_ad-mytab-notification_首购会场_ruxiao |  |
-- | app_ad-mytab-notification_首购会场_zhibojian |  |
-- | app_ad-mytab-notification_首购会场_zhibojian_首购会场 |  |
-- | app_app_zhibojian_shuxueZhiboA_付费介绍页-初中数学 |  |
-- | app_app_zhibojian_shuxueZhiboA_付费介绍页-数学 |  |
-- | app_baozang_付费介绍页-初中化学 |  |
-- | app_baozang_付费介绍页-初中化学_ruxiao |  |
-- | app_baozang_付费介绍页-初中地理 |  |
-- | app_baozang_付费介绍页-初中数学 |  |
-- | app_baozang_付费介绍页-初中数学_ruxiao |  |
-- | app_baozang_付费介绍页-初中物理 |  |
-- | app_baozang_付费介绍页-初中物理_ruxiao |  |
-- | app_baozang_付费介绍页-初中生物 |  |
-- | app_baozang_付费介绍页-初中生物_ruxiao |  |
-- | app_baozang_付费介绍页-化学 |  |
-- | app_baozang_付费介绍页-化学_ruxiao |  |
-- | app_baozang_付费介绍页-地理 |  |
-- | app_baozang_付费介绍页-小学数学 |  |
-- | app_baozang_付费介绍页-小学数学_ruxiao |  |
-- | app_baozang_付费介绍页-小学英语 |  |
-- | app_baozang_付费介绍页-小学英语_ruxiao |  |
-- | app_baozang_付费介绍页-数学 |  |
-- | app_baozang_付费介绍页-数学_ruxiao |  |
-- | app_baozang_付费介绍页-物理 |  |
-- | app_baozang_付费介绍页-物理_ruxiao |  |
-- | app_baozang_付费介绍页-生物 |  |
-- | app_baozang_付费介绍页-科学 |  |
-- | app_baozang_付费介绍页-英语 |  |
-- | app_baozang_付费介绍页-语文 |  |
-- | app_baozang_付费介绍页-高中数学 |  |
-- | app_baozang_付费介绍页-高中数学_ruxiao |  |
-- | app_baozang_付费介绍页-高中语文 |  |
-- | app_baozang_初中数学培优课_聚合页 |  |
-- | app_baozang_小学思维_聚合页 |  |
-- | app_baozang_首购会场 |  |
-- | app_baozang_首购会场_zhibojian_首购会场 |  |
-- | app_faxian-auto_首购会场 |  |
-- | app_faxian-auto_首购会场_zhibojian |  |
-- | app_hancupush_首购会场_zhibojian |  |
-- | app_kefu |  |
-- | app_kefu_ruxiao |  |
-- | app_learn-popup_首购会场 |  |
-- | app_learn-popup_首购会场_ruxiao |  |
-- | app_learn-popup_首购会场_zhibojian |  |
-- | app_learn-popup_首购会场_zhibojian_首购会场 |  |
-- | app_member-mytab-afterSalesService-assistantService_首购会场 |  |
-- | app_member-mytab-afterSalesService-mulChildService_多孩续购会场 |  |
-- | app_member-mytab-afterSalesService-mulChildService_多孩续购会场_ruxiao |  |
-- | app_member-mytab-afterSalesService-padAddPurchaseService |  |
-- | app_member-mytab-afterSalesService-padAddPurchaseService_首购会场 |  |
-- | app_member-mytab-afterSalesService-padAddPurchaseService_首购会场_zhibojian |  |
-- | app_member-mytab-afterSalesService-upgradeCourseDiscount_首购会场 |  |
-- | app_member-mytab-afterSalesService-upgradeCourseDiscount_首购会场_zhibojian |  |
-- | app_member-mytab-afterSalesService-xugouOldBigVip_大会员续购会场 |  |
-- | app_member-mytab-afterSalesService-xugouOldBigVip_大会员续购会场_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_app-zuheshangping-tenon |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-中职数学 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-中职数学_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-中职英语 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中化学 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中化学_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中地理 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中地理_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中数学 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中数学_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中物理 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中物理_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中生物 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中生物_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中英语 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中英语_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中语文 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-初中语文_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-化学 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-化学_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-历史 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-启蒙课 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-地理 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-地理_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-小学数学 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-小学数学_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-小学英语 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-小学英语_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-小学语文 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-小学语文_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-思想政治 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-思想政治_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-数学 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-数学_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-物理 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-物理_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-生物 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-生物_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-科学 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-英语 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-英语_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-语文 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-语文_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中化学 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中化学_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中历史 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中历史_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中地理 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中地理_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中思想政治 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中思想政治_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中数学 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中数学_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中物理 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中物理_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中生物 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中生物_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中英语 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中英语_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中语文 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_付费介绍页-高中语文_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_初中化学培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_初中地理培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_初中数学培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_初中物理培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_初中生物培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_初中英语培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_初中语文培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_小学地球_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_小学思维_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_小学数学培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_小学自然_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_小学语文_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_首购会场 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_首购会场_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_首购会场_zhibojian |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_首购会场_zhibojian_首购会场 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高中化学重难点_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高中数学重难点_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高中数学高三一轮_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高中数学高三二轮_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高中物理二轮培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高中物理重难点_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高中生物一轮培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高中生物重难点_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高中英语一轮培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高考数学真题讲解_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高考物理真题精讲_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseIntroPay_高考生物真题精讲_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-初中数学 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-初中数学_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-化学 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-启蒙课 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-地理 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-小学数学 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-小学数学_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-数学 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-物理 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-物理_ruxiao |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-生物 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-科学 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-英语 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-语文 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_付费介绍页-高中数学 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_初中化学培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_初中数学培优课_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_小学思维_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_首购会场 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_高中数学重难点_聚合页 |  |
-- | app_member-mytab-courseAuthIntro-courseValueSellingPoint_高中物理重难点_聚合页 |  |
-- | app_member-mytab-coursePromotion |  |
-- | app_member-mytab-coursePromotion_app-zuheshangping-tenon |  |
-- | app_member-mytab-coursePromotion_付费介绍页-中职数学 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-初中数学 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-初中数学_ruxiao |  |
-- | app_member-mytab-coursePromotion_付费介绍页-化学 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-化学_ruxiao |  |
-- | app_member-mytab-coursePromotion_付费介绍页-历史 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-启蒙课 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-地理 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-地理_ruxiao |  |
-- | app_member-mytab-coursePromotion_付费介绍页-小学数学 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-小学数学_ruxiao |  |
-- | app_member-mytab-coursePromotion_付费介绍页-思想政治 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-数学 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-数学_ruxiao |  |
-- | app_member-mytab-coursePromotion_付费介绍页-物理 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-物理_ruxiao |  |
-- | app_member-mytab-coursePromotion_付费介绍页-生物 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-生物_ruxiao |  |
-- | app_member-mytab-coursePromotion_付费介绍页-科学 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-科学_ruxiao |  |
-- | app_member-mytab-coursePromotion_付费介绍页-英语 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-英语_ruxiao |  |
-- | app_member-mytab-coursePromotion_付费介绍页-语文 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-语文_ruxiao |  |
-- | app_member-mytab-coursePromotion_付费介绍页-高中数学 |  |
-- | app_member-mytab-coursePromotion_付费介绍页-高中数学_ruxiao |  |
-- | app_member-mytab-coursePromotion_初中化学培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_初中地理培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_初中数学培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_初中物理培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_初中生物培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_初中英语培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_初中语文培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_大会员续购会场 |  |
-- | app_member-mytab-coursePromotion_大会员续购会场_ruxiao |  |
-- | app_member-mytab-coursePromotion_小学思维_聚合页 |  |
-- | app_member-mytab-coursePromotion_小学数学培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_小学自然_聚合页 |  |
-- | app_member-mytab-coursePromotion_小学语文_聚合页 |  |
-- | app_member-mytab-coursePromotion_首购会场 |  |
-- | app_member-mytab-coursePromotion_首购会场_ruxiao |  |
-- | app_member-mytab-coursePromotion_首购会场_zhibojian |  |
-- | app_member-mytab-coursePromotion_首购会场_zhibojian_首购会场 |  |
-- | app_member-mytab-coursePromotion_高中化学一轮培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_高中化学重难点_聚合页 |  |
-- | app_member-mytab-coursePromotion_高中数学重难点_聚合页 |  |
-- | app_member-mytab-coursePromotion_高中数学高三一轮_聚合页 |  |
-- | app_member-mytab-coursePromotion_高中数学高三二轮_聚合页 |  |
-- | app_member-mytab-coursePromotion_高中物理一轮培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_高中物理二轮培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_高中物理重难点_聚合页 |  |
-- | app_member-mytab-coursePromotion_高中生物一轮培优课_聚合页 |  |
-- | app_member-mytab-coursePromotion_高中生物重难点_聚合页 |  |
-- | app_member-mytab-coursePromotion_高考数学真题讲解_聚合页 |  |
-- | app_member-mytab-identityAuthIntro-identityUpgrade_付费介绍页-初中数学 |  |
-- | app_member-mytab-identityAuthIntro-identityUpgrade_付费介绍页-初中数学_ruxiao |  |
-- | app_member-mytab-identityAuthIntro-identityUpgrade_付费介绍页-化学 |  |
-- | app_member-mytab-identityAuthIntro-identityUpgrade_付费介绍页-地理 |  |
-- | app_member-mytab-identityAuthIntro-identityUpgrade_付费介绍页-小学数学 |  |
-- | app_member-mytab-identityAuthIntro-identityUpgrade_付费介绍页-数学 |  |
-- | app_member-mytab-identityAuthIntro-identityUpgrade_付费介绍页-物理 |  |
-- | app_member-mytab-identityAuthIntro-identityUpgrade_付费介绍页-语文 |  |
-- | app_member-mytab-identityAuthIntro-identityUpgrade_首购会场_zhibojian |  |
-- | app_member-mytab-identityAuthIntro-identityUpgrade_首购会场_zhibojian_首购会场 |  |
-- | app_member-mytab-square_付费介绍页-初中化学 |  |
-- | app_member-mytab-square_付费介绍页-初中数学 |  |
-- | app_member-mytab-square_付费介绍页-初中数学_ruxiao |  |
-- | app_member-mytab-square_付费介绍页-初中物理 |  |
-- | app_member-mytab-square_付费介绍页-初中英语 |  |
-- | app_member-mytab-square_付费介绍页-化学 |  |
-- | app_member-mytab-square_付费介绍页-化学_ruxiao |  |
-- | app_member-mytab-square_付费介绍页-地理 |  |
-- | app_member-mytab-square_付费介绍页-小学数学 |  |
-- | app_member-mytab-square_付费介绍页-数学 |  |
-- | app_member-mytab-square_付费介绍页-数学_ruxiao |  |
-- | app_member-mytab-square_付费介绍页-物理 |  |
-- | app_member-mytab-square_付费介绍页-物理_ruxiao |  |
-- | app_member-mytab-square_付费介绍页-英语 |  |
-- | app_member-mytab-square_付费介绍页-语文 |  |
-- | app_member-mytab-square_付费介绍页-高中化学 |  |
-- | app_member-mytab-square_付费介绍页-高中数学 |  |
-- | app_member-mytab-square_付费介绍页-高中物理 |  |
-- | app_member-mytab-square_首购会场_zhibojian_首购会场 |  |
-- | app_my_tab_treehole_nuannuan_portraitRight_app-zuheshangping-tenon |  |
-- | app_shop-baozang-commonCard |  |
-- | app_shop-baozang-commonCard_app-zuheshangping-tenon |  |
-- | app_shop-baozang-commonCard_付费介绍页-中职数学 |  |
-- | app_shop-baozang-commonCard_付费介绍页-初中数学 |  |
-- | app_shop-baozang-commonCard_付费介绍页-初中数学_ruxiao |  |
-- | app_shop-baozang-commonCard_付费介绍页-化学 |  |
-- | app_shop-baozang-commonCard_付费介绍页-化学_ruxiao |  |
-- | app_shop-baozang-commonCard_付费介绍页-历史 |  |
-- | app_shop-baozang-commonCard_付费介绍页-启蒙课 |  |
-- | app_shop-baozang-commonCard_付费介绍页-地理 |  |
-- | app_shop-baozang-commonCard_付费介绍页-小学数学 |  |
-- | app_shop-baozang-commonCard_付费介绍页-小学数学_ruxiao |  |
-- | app_shop-baozang-commonCard_付费介绍页-数学 |  |
-- | app_shop-baozang-commonCard_付费介绍页-数学_ruxiao |  |
-- | app_shop-baozang-commonCard_付费介绍页-物理 |  |
-- | app_shop-baozang-commonCard_付费介绍页-物理_ruxiao |  |
-- | app_shop-baozang-commonCard_付费介绍页-生物 |  |
-- | app_shop-baozang-commonCard_付费介绍页-生物_ruxiao |  |
-- | app_shop-baozang-commonCard_付费介绍页-科学 |  |
-- | app_shop-baozang-commonCard_付费介绍页-英语 |  |
-- | app_shop-baozang-commonCard_付费介绍页-英语_ruxiao |  |
-- | app_shop-baozang-commonCard_付费介绍页-语文 |  |
-- | app_shop-baozang-commonCard_付费介绍页-语文_ruxiao |  |
-- | app_shop-baozang-commonCard_付费介绍页-高中数学 |  |
-- | app_shop-baozang-commonCard_付费介绍页-高中数学_ruxiao |  |
-- | app_shop-baozang-commonCard_初中化学培优课_聚合页 |  |
-- | app_shop-baozang-commonCard_初中地理培优课_聚合页 |  |
-- | app_shop-baozang-commonCard_初中数学培优课_聚合页 |  |
-- | app_shop-baozang-commonCard_初中物理培优课_聚合页 |  |
-- | app_shop-baozang-commonCard_初中生物培优课_聚合页 |  |
-- | app_shop-baozang-commonCard_初中英语培优课_聚合页 |  |
-- | app_shop-baozang-commonCard_初中语文培优课_聚合页 |  |
-- | app_shop-baozang-commonCard_小学地球_聚合页 |  |
-- | app_shop-baozang-commonCard_小学思维_聚合页 |  |
-- | app_shop-baozang-commonCard_小学数学培优课_聚合页 |  |
-- | app_shop-baozang-commonCard_首购会场 |  |
-- | app_shop-baozang-commonCard_首购会场_ruxiao |  |
-- | app_shop-baozang-commonCard_首购会场_zhibojian |  |
-- | app_shop-baozang-commonCard_首购会场_zhibojian_首购会场 |  |
-- | app_shop-baozang-commonCard_高中化学一轮培优课_聚合页 |  |
-- | app_shop-baozang-commonCard_高中化学重难点_聚合页 |  |
-- | app_shop-baozang-commonCard_高中数学重难点_聚合页 |  |
-- | app_shop-baozang-commonCard_高中数学高三二轮_聚合页 |  |
-- | app_shop-baozang-commonCard_高中物理一轮培优课_聚合页 |  |
-- | app_shop-baozang-commonCard_高中物理二轮培优课_聚合页 |  |
-- | app_shop-baozang-commonCard_高中物理重难点_聚合页 |  |
-- | app_shop-baozang-courseCard |  |
-- | app_shop-baozang-courseCard__聚合页 |  |
-- | app_shop-baozang-courseCard_app-zuheshangping-tenon |  |
-- | app_shop-baozang-courseCard_付费介绍页- |  |
-- | app_shop-baozang-courseCard_付费介绍页-中职数学 |  |
-- | app_shop-baozang-courseCard_付费介绍页-中职数学_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-中职英语 |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中化学 |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中化学_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中地理 |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中地理_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中数学 |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中数学_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中物理 |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中物理_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中生物 |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中生物_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中英语 |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中英语_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-初中语文 |  |
-- | app_shop-baozang-courseCard_付费介绍页-化学 |  |
-- | app_shop-baozang-courseCard_付费介绍页-化学_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-历史 |  |
-- | app_shop-baozang-courseCard_付费介绍页-启蒙课 |  |
-- | app_shop-baozang-courseCard_付费介绍页-地理 |  |
-- | app_shop-baozang-courseCard_付费介绍页-地理_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-小学数学 |  |
-- | app_shop-baozang-courseCard_付费介绍页-小学数学_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-小学英语 |  |
-- | app_shop-baozang-courseCard_付费介绍页-小学英语_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-小学语文 |  |
-- | app_shop-baozang-courseCard_付费介绍页-小学语文_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-思想政治 |  |
-- | app_shop-baozang-courseCard_付费介绍页-数学 |  |
-- | app_shop-baozang-courseCard_付费介绍页-数学_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-物理 |  |
-- | app_shop-baozang-courseCard_付费介绍页-物理_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-生物 |  |
-- | app_shop-baozang-courseCard_付费介绍页-生物_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-科学 |  |
-- | app_shop-baozang-courseCard_付费介绍页-科学_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-英语 |  |
-- | app_shop-baozang-courseCard_付费介绍页-语文 |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中化学 |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中化学_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中历史 |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中地理 |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中地理_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中思想政治 |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中数学 |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中数学_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中物理 |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中物理_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中生物 |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中生物_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中英语 |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中英语_ruxiao |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中语文 |  |
-- | app_shop-baozang-courseCard_付费介绍页-高中语文_ruxiao |  |
-- | app_shop-baozang-courseCard_初中化学培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_初中数学培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_初中物理培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_初中生物培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_初中英语培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_初中语文培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_小学地球_聚合页 |  |
-- | app_shop-baozang-courseCard_小学思维_聚合页 |  |
-- | app_shop-baozang-courseCard_小学数学培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_小学自然_聚合页 |  |
-- | app_shop-baozang-courseCard_小学语文_聚合页 |  |
-- | app_shop-baozang-courseCard_首购会场 |  |
-- | app_shop-baozang-courseCard_首购会场_ruxiao |  |
-- | app_shop-baozang-courseCard_首购会场_zhibojian |  |
-- | app_shop-baozang-courseCard_首购会场_zhibojian_首购会场 |  |
-- | app_shop-baozang-courseCard_高中化学二轮培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_高中化学重难点_聚合页 |  |
-- | app_shop-baozang-courseCard_高中数学重难点_聚合页 |  |
-- | app_shop-baozang-courseCard_高中数学高三一轮_聚合页 |  |
-- | app_shop-baozang-courseCard_高中数学高三二轮_聚合页 |  |
-- | app_shop-baozang-courseCard_高中物理一轮培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_高中物理二轮培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_高中物理重难点_聚合页 |  |
-- | app_shop-baozang-courseCard_高中生物一轮培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_高中生物二轮培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_高中生物重难点_聚合页 |  |
-- | app_shop-baozang-courseCard_高中英语一轮培优课_聚合页 |  |
-- | app_shop-baozang-courseCard_高考数学真题讲解_聚合页 |  |
-- | app_shop-baozang-courseCard_高考物理真题精讲_聚合页 |  |
-- | app_shuxueB_付费介绍页-初中数学 |  |
-- | app_shuxueB_付费介绍页-初中数学_ruxiao |  |
-- | app_shuxueB_付费介绍页-化学 |  |
-- | app_shuxueB_付费介绍页-地理 |  |
-- | app_shuxueB_付费介绍页-数学 |  |
-- | app_shuxueB_付费介绍页-物理 |  |
-- | app_shuxueB_付费介绍页-生物 |  |
-- | app_shuxueB_付费介绍页-科学 |  |
-- | app_shuxueB_付费介绍页-英语 |  |
-- | app_shuxueB_初中数学培优课_聚合页 |  |
-- | app_shuxueB_初中英语培优课_聚合页 |  |
-- | app_sijiaoban_zhibojian_app-zuheshangping-tenon |  |
-- | app_social-AnnualSummaryActivityPage-CharacterCardPage-surpriseButton_首购会场 |  |
-- | app_social-AnnualSummaryActivityPage-CharacterCardPage-surpriseButton_首购会场_ruxiao |  |
-- | app_social-AnnualSummaryActivityPage-CharacterCardPage-surpriseButton_首购会场_zhibojian_首购会场 |  |
-- | app_study-AIPersonalizedClass-classPromotion_app-zuheshangping-tenon |  |
-- | app_study-SpecialCourse-chapterList_app-zuheshangping-tenon |  |
-- | app_study-SpecialCourse-chapterList_付费介绍页-初中数学 |  |
-- | app_study-SpecialCourse-chapterList_付费介绍页-启蒙课 |  |
-- | app_study-SpecialCourse-chapterList_付费介绍页-启蒙课_ruxiao |  |
-- | app_study-SpecialCourse-chapterList_付费介绍页-小学数学 |  |
-- | app_study-SpecialCourse-chapterList_付费介绍页-小学数学_ruxiao |  |
-- | app_study-SpecialCourse-chapterList_付费介绍页-小学英语 |  |
-- | app_study-SpecialCourse-chapterList_付费介绍页-小学英语_ruxiao |  |
-- | app_study-SpecialCourse-chapterList_付费介绍页-数学 |  |
-- | app_study-SpecialCourse-chapterList_付费介绍页-英语 |  |
-- | app_study-SpecialCourse-chapterList_付费介绍页-语文 |  |
-- | app_study-SpecialCourse-chapterList_小学思维_聚合页 |  |
-- | app_study-SpecialCourse-chapterList_小学数学培优课_聚合页 |  |
-- | app_study-SpecialCourse-chapterList_小学语文_聚合页 |  |
-- | app_study-SpecialCourse-chapterList_首购会场 |  |
-- | app_study-SpecialCourse-chapterList_首购会场_zhibojian |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-初中化学 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-初中地理 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-初中数学 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-初中数学_ruxiao |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-初中物理 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-初中生物 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-初中生物_ruxiao |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-初中英语 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-初中语文 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-化学 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-地理 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-数学 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-物理 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-生物 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-科学 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-英语 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-高中化学 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-高中数学 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-高中数学_ruxiao |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-高中物理 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-高中生物 |  |
-- | app_study-communityQA-upgradeCourse_付费介绍页-高中英语 |  |
-- | app_study-communityQA-upgradeCourse_初中化学培优课_聚合页 |  |
-- | app_study-communityQA-upgradeCourse_初中数学培优课_聚合页 |  |
-- | app_study-communityQA-upgradeCourse_初中物理培优课_聚合页 |  |
-- | app_study-communityQA-upgradeCourse_高中数学重难点_聚合页 |  |
-- | app_study-communityQA-upgradeCourse_高中英语一轮培优课_聚合页 |  |
-- | app_study-learntab-aiClassEntrance_AI定制结果页面 |  |
-- | app_study-studyPlanEntrance-upgradeCourse_付费介绍页-初中英语 |  |
-- | app_study-studyPlanEntrance-upgradeCourse_付费介绍页-初中英语_ruxiao |  |
-- | app_study-studyPlanEntrance-upgradeCourse_付费介绍页-小学语文 |  |
-- | app_study-studyPlanEntrance-upgradeCourse_付费介绍页-英语 |  |
-- | app_study-studyPlanEntrance-upgradeCourse_付费介绍页-高中生物 |  |
-- | app_study-studyPlanEntrance-upgradeCourse_初中数学培优课_聚合页 |  |
-- | app_study-studyPlanEntrance-upgradeCourse_小学思维_聚合页 |  |
-- | app_study-studyPlanEntrance-upgradeCourse_高中数学高三一轮_聚合页 |  |
-- | app_study-studyPlanEntrance-upgradeCourse_高中生物一轮培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-初中化学 |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-初中数学 |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-初中数学_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-初中物理 |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-初中英语 |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-初中语文 |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-小学数学 |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-小学英语 |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-小学语文 |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-数学 |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-生物 |  |
-- | app_study-synchronousChapter-chapaterList-downloadVideo_付费介绍页-高中生物 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页- |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-中职数学 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-中职数学_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-中职英语 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-中职英语_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中化学 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中化学_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中地理 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中地理_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中数学 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中数学_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中物理 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中物理_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中生物 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中生物_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中英语 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中英语_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中语文 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-初中语文_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-化学 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-化学_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-历史 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-启蒙课 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-地理 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-地理_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-小学数学 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-小学数学_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-小学英语 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-小学英语_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-小学语文 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-小学语文_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-思想政治 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-数学 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-数学_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-物理 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-物理_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-生物 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-生物_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-科学 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-科学_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-英语 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-英语_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-语文 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-语文_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中化学 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中化学_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中历史 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中地理 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中地理_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中思想政治 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中数学 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中数学_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中物理 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中物理_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中生物 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中生物_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中英语 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中英语_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中语文 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_付费介绍页-高中语文_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_初中化学培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_初中地理培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_初中数学培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_初中物理培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_初中英语培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_初中语文培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_小学地球_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_小学思维_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_小学数学培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_小学语文_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_首购会场 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_首购会场_ruxiao |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_首购会场_zhibojian |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_首购会场_zhibojian_首购会场 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_高中化学一轮培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_高中化学重难点_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_高中数学重难点_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_高中数学高三一轮_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_高中数学高三二轮_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_高中物理一轮培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_高中物理重难点_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_高中生物一轮培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_高中生物二轮培优课_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_高中生物重难点_聚合页 |  |
-- | app_study-synchronousChapter-chapaterList-upgradeCourse_高中英语一轮培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-downloadVideo_高中数学高三一轮_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse |  |
-- | app_study-totalReview-chapterList-upgradeCourse__聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_app-zuheshangping-tenon |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-初中数学 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-化学 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-地理 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-小学数学 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-数学 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-物理 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-物理_ruxiao |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-生物 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-科学_ruxiao |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-英语 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-语文 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_付费介绍页-高中数学 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_初中化学培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_初中地理培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_初中数学培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_初中物理培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_初中生物培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_初中英语培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_初中语文培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_小学思维_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_小学数学培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_首购会场 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_首购会场_ruxiao |  |
-- | app_study-totalReview-chapterList-upgradeCourse_首购会场_zhibojian |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中化学一轮培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中化学二轮培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中化学重难点_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中数学重难点_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中数学高三一轮_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中数学高三二轮_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中物理一轮培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中物理二轮培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中物理重难点_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中生物一轮培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中生物重难点_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高中英语一轮培优课_聚合页 |  |
-- | app_study-totalReview-chapterList-upgradeCourse_高考数学真题讲解_聚合页 |  |
-- | app_study-totalReviewNew-chapterList-downloadVideo_高中物理重难点_聚合页 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-初中化学 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-初中地理 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-初中数学 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-初中物理 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-初中生物 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-初中语文 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-化学 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-小学英语_ruxiao |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-数学 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-物理 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-高中化学 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-高中数学 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-高中物理 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-高中生物 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_付费介绍页-高中英语 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_初中化学培优课_聚合页 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_初中数学培优课_聚合页 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_初中物理培优课_聚合页 |  |
-- | app_study-videoPlayer-membershipFunction-upgradeCourse_首购会场 |  |
-- | app_study-videoPlayer-payBlockDialog |  |
-- | app_study-videoPlayer-payBlockDialog_app-zuheshangping-tenon |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-中职数学 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-中职英语 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-中职英语_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中化学 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中化学_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中地理 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中地理_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中数学 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中数学_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中物理 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中物理_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中生物 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中生物_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中英语 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中语文 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-初中语文_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-化学 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-化学_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-历史 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-历史_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-启蒙课 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-启蒙课_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-地理 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-小学数学 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-小学数学_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-小学英语 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-小学英语_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-小学语文 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-小学语文_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-思想政治 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-数学 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-数学_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-物理 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-物理_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-生物 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-生物_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-科学 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-英语 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-英语_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-语文 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-语文_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中化学 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中化学_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中历史 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中地理 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中思想政治 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中思想政治_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中数学 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中数学_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中物理 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中物理_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中生物 |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中生物_ruxiao |  |
-- | app_study-videoPlayer-payBlockDialog_付费介绍页-高中英语 |  |
-- | app_study-videoPlayer-payBlockDialog_初中化学培优课_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_初中地理培优课_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_初中数学培优课_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_初中物理培优课_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_初中生物培优课_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_初中英语培优课_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_小学思维_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_小学数学培优课_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_小学自然_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_小学语文_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_首购会场 |  |
-- | app_study-videoPlayer-payBlockDialog_首购会场_zhibojian |  |
-- | app_study-videoPlayer-payBlockDialog_首购会场_zhibojian_首购会场 |  |
-- | app_study-videoPlayer-payBlockDialog_高中化学重难点_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_高中数学重难点_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_高中数学高三一轮_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_高中数学高三二轮_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_高中物理一轮培优课_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_高中物理重难点_聚合页 |  |
-- | app_study-videoPlayer-payBlockDialog_高中生物重难点_聚合页 |  |
-- | app_study-videoPlayer-payVideo |  |
-- | app_study-videoPlayer-payVideo__聚合页 |  |
-- | app_study-videoPlayer-payVideo_app-zuheshangping-tenon |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-中职数学 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-初中化学 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-初中地理 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-初中数学 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-初中数学_ruxiao |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-初中物理 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-初中物理_ruxiao |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-初中生物 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-初中英语 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-初中英语_ruxiao |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-初中语文 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-化学 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-历史 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-启蒙课 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-地理 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-小学数学 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-小学数学_ruxiao |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-小学英语 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-小学语文 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-数学 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-数学_ruxiao |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-物理 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-物理_ruxiao |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-生物 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-科学 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-英语 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-语文 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-高中化学 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-高中化学_ruxiao |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-高中历史 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-高中地理 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-高中数学 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-高中数学_ruxiao |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-高中物理 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-高中生物 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-高中英语 |  |
-- | app_study-videoPlayer-payVideo_付费介绍页-高中语文 |  |
-- | app_study-videoPlayer-payVideo_初中化学培优课_聚合页 |  |
-- | app_study-videoPlayer-payVideo_初中数学培优课_聚合页 |  |
-- | app_study-videoPlayer-payVideo_初中物理培优课_聚合页 |  |
-- | app_study-videoPlayer-payVideo_初中生物培优课_聚合页 |  |
-- | app_study-videoPlayer-payVideo_初中英语培优课_聚合页 |  |
-- | app_study-videoPlayer-payVideo_小学地球_聚合页 |  |
-- | app_study-videoPlayer-payVideo_小学思维_聚合页 |  |
-- | app_study-videoPlayer-payVideo_小学数学培优课_聚合页 |  |
-- | app_study-videoPlayer-payVideo_小学自然_聚合页 |  |
-- | app_study-videoPlayer-payVideo_小学语文_聚合页 |  |
-- | app_study-videoPlayer-payVideo_首购会场 |  |
-- | app_study-videoPlayer-payVideo_首购会场_zhibojian |  |
-- | app_study-videoPlayer-payVideo_首购会场_zhibojian_首购会场 |  |
-- | app_study-videoPlayer-payVideo_高中化学一轮培优课_聚合页 |  |
-- | app_study-videoPlayer-payVideo_高中数学重难点_聚合页 |  |
-- | app_study-videoPlayer-payVideo_高中数学高三一轮_聚合页 |  |
-- | app_study-videoPlayer-payVideo_高中数学高三二轮_聚合页 |  |
-- | app_study-videoPlayer-payVideo_高中物理二轮培优课_聚合页 |  |
-- | app_tabStudy_app-zuheshangping-tenon |  |
-- | app_tenon_AI定制结果页面 |  |
-- | app_tmp |  |
-- | app_tmp_付费介绍页-中职数学_ruxiao |  |
-- | app_tmp_付费介绍页-初中化学_ruxiao |  |
-- | app_tmp_付费介绍页-初中地理_ruxiao |  |
-- | app_tmp_付费介绍页-初中数学 |  |
-- | app_tmp_付费介绍页-初中数学_ruxiao |  |
-- | app_tmp_付费介绍页-初中物理_ruxiao |  |
-- | app_tmp_付费介绍页-初中生物_ruxiao |  |
-- | app_tmp_付费介绍页-初中英语_ruxiao |  |
-- | app_tmp_付费介绍页-初中语文_ruxiao |  |
-- | app_tmp_付费介绍页-化学 |  |
-- | app_tmp_付费介绍页-化学_ruxiao |  |
-- | app_tmp_付费介绍页-地理 |  |
-- | app_tmp_付费介绍页-地理_ruxiao |  |
-- | app_tmp_付费介绍页-小学数学_ruxiao |  |
-- | app_tmp_付费介绍页-小学英语_ruxiao |  |
-- | app_tmp_付费介绍页-小学语文_ruxiao |  |
-- | app_tmp_付费介绍页-数学 |  |
-- | app_tmp_付费介绍页-数学_ruxiao |  |
-- | app_tmp_付费介绍页-物理 |  |
-- | app_tmp_付费介绍页-物理_ruxiao |  |
-- | app_tmp_付费介绍页-生物 |  |
-- | app_tmp_付费介绍页-生物_ruxiao |  |
-- | app_tmp_付费介绍页-科学 |  |
-- | app_tmp_付费介绍页-科学_ruxiao |  |
-- | app_tmp_付费介绍页-英语_ruxiao |  |
-- | app_tmp_付费介绍页-语文 |  |
-- | app_tmp_付费介绍页-语文_ruxiao |  |
-- | app_tmp_付费介绍页-高中化学_ruxiao |  |
-- | app_tmp_付费介绍页-高中数学_ruxiao |  |
-- | app_tmp_付费介绍页-高中物理_ruxiao |  |
-- | app_tmp_付费介绍页-高中生物_ruxiao |  |
-- | app_tmp_付费介绍页-高中语文_ruxiao |  |
-- | app_tmp_初中数学培优课_聚合页 |  |
-- | app_tmp_初中物理培优课_聚合页 |  |
-- | app_tmp_小学数学培优课_聚合页 |  |
-- | app_tmp_高中化学重难点_聚合页 |  |
-- | app_zhibojian_sijiaoban |  |
-- | app_初中化学培优课_聚合页 |  |
-- | app_初中物理培优课_聚合页 |  |
-- | app_初中英语培优课_聚合页 |  |
-- | app_发现页__聚合页 |  |
-- | app_发现页_app-zuheshangping-tenon |  |
-- | app_发现页_付费介绍页-初中数学 |  |
-- | app_发现页_付费介绍页-化学 |  |
-- | app_发现页_付费介绍页-启蒙课 |  |
-- | app_发现页_付费介绍页-启蒙课_ruxiao |  |
-- | app_发现页_付费介绍页-地理 |  |
-- | app_发现页_付费介绍页-小学数学 |  |
-- | app_发现页_付费介绍页-小学数学_ruxiao |  |
-- | app_发现页_付费介绍页-小学英语 |  |
-- | app_发现页_付费介绍页-数学 |  |
-- | app_发现页_付费介绍页-物理 |  |
-- | app_发现页_付费介绍页-生物 |  |
-- | app_发现页_付费介绍页-英语 |  |
-- | app_发现页_付费介绍页-高中数学 |  |
-- | app_发现页_初中化学培优课_聚合页 |  |
-- | app_发现页_初中地理培优课_聚合页 |  |
-- | app_发现页_初中数学培优课_聚合页 |  |
-- | app_发现页_初中物理培优课_聚合页 |  |
-- | app_发现页_初中生物培优课_聚合页 |  |
-- | app_发现页_初中英语培优课_聚合页 |  |
-- | app_发现页_初中语文培优课_聚合页 |  |
-- | app_发现页_小学思维_聚合页 |  |
-- | app_发现页_小学数学培优课_聚合页 |  |
-- | app_发现页_小学语文_聚合页 |  |
-- | app_发现页_首购会场 |  |
-- | app_发现页_首购会场_zhibojian_首购会场 |  |
-- | app_发现页_高中化学一轮培优课_聚合页 |  |
-- | app_发现页_高中化学重难点_聚合页 |  |
-- | app_发现页_高中数学重难点_聚合页 |  |
-- | app_发现页_高中数学高三一轮_聚合页 |  |
-- | app_发现页_高中数学高三二轮_聚合页 |  |
-- | app_发现页_高中物理一轮培优课_聚合页 |  |
-- | app_发现页_高中物理二轮培优课_聚合页 |  |
-- | app_发现页_高中物理重难点_聚合页 |  |
-- | app_发现页_高中生物一轮培优课_聚合页 |  |
-- | app_发现页_高中生物重难点_聚合页 |  |
-- | app_发现页_高考数学真题讲解_聚合页 |  |
-- | app_心理倾听-平板_app-zuheshangping-tenon |  |
-- | app_心理倾听_app-zuheshangping-tenon |  |
-- | app_报志愿首页_app-zuheshangping-tenon |  |
-- | app_洋葱私教班｜4周特训_app-zuheshangping-tenon |  |
-- | app_洋葱私教班｜4周特训_付费介绍页-初中数学 |  |
-- | app_视频播放购买入口_付费介绍页-初中物理 |  |
-- | gongzhonghao_shangyehua |  |
-- | ruxiao |  |
-- | ruxiao_ruxiao |  |
-- | shangyehua |  |
-- | shangyehua_jd |  |
-- | shangyehua_pinduoduo |  |
-- | shangyehua_tmall |  |
-- | smarthardware |  |
-- | telesale |  |
-- | telesale_app |  |
-- | telesale_app1312 |  |
-- | telesale_app_ruxiao |  |
-- | telesale_ruxiao |  |
-- | tiyanying |  |
-- | tiyanying_doudian |  |
-- | tiyanying_ruxiao |  |
-- | tiyanying_shipinhaoxiaodian |  |
-- | xinmeiti |  |
-- | xinmeiti_doudian |  |
-- | xinmeiti_shipin_shipinhaoxiaodian |  |
-- | xinmeiti_weidian |  |
-- | xinmeiti_xiaohongshu |  |
-- | xinmeiti_youzan |  |
-- | xinmeitishipin_kwai |  |
-- | xinmeitishipin_weidian |  |
-- | yanxue |  |
-- | yanxue_ruxiao |  |
-- | zhibojian |  |
--
-- ## mid_stage_name（中学修正学段）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `dws.topic_user_info`「stage_name」枚举段一致） |
-- | 中职 | 中职 |
-- | 初中 | 初中 |
-- | 启蒙 | 启蒙 |
-- | 小学 | 小学 |
-- | 高中 | 高中 |
--
-- ## stage_name_month（付费当月学段）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `dws.topic_user_info`「stage_name」枚举段一致） |
-- | 中职 | 中职 |
-- | 初中 | 初中 |
-- | 启蒙 | 启蒙 |
-- | 小学 | 小学 |
-- | 高中 | 高中 |
--
-- ## stage_name_year（付费当年学段）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `dws.topic_user_info`「stage_name」枚举段一致） |
-- | 中职 | 中职 |
-- | 初中 | 初中 |
-- | 启蒙 | 启蒙 |
-- | 小学 | 小学 |
-- | 高中 | 高中 |
--
-- ## mid_grade（中学年级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `dw.dim_user`「grade」及商业化日表 `mid_grade` 口径类似） |
-- | 一年级 | 一年级 |
-- | 七年级 | 七年级 |
-- | 三年级 | 三年级 |
-- | 九年级 | 九年级 |
-- | 二年级 | 二年级 |
-- | 五年级 | 五年级 |
-- | 八年级 | 八年级 |
-- | 六年级 | 六年级 |
-- | 四年级 | 四年级 |
-- | 学龄前 | 学龄前 |
-- | 职一 | 职一 |
-- | 职三 | 职三 |
-- | 职二 | 职二 |
-- | 高一 | 高一 |
-- | 高三 | 高三 |
-- | 高二 | 高二 |
--
-- ## grade_name_month（付费当月年级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `dw.dim_user`「grade」及商业化日表 `mid_grade` 口径类似） |
-- | (空字符串) |  |
-- | 一年级 | 一年级 |
-- | 七年级 | 七年级 |
-- | 三年级 | 三年级 |
-- | 九年级 | 九年级 |
-- | 二年级 | 二年级 |
-- | 五年级 | 五年级 |
-- | 八年级 | 八年级 |
-- | 六年级 | 六年级 |
-- | 四年级 | 四年级 |
-- | 学龄前 | 学龄前 |
-- | 职一 | 职一 |
-- | 职三 | 职三 |
-- | 职二 | 职二 |
-- | 高一 | 高一 |
-- | 高三 | 高三 |
-- | 高二 | 高二 |
--
-- ## grade_name_year（付费当年年级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `dw.dim_user`「grade」及商业化日表 `mid_grade` 口径类似） |
-- | (空字符串) |  |
-- | 一年级 | 一年级 |
-- | 七年级 | 七年级 |
-- | 三年级 | 三年级 |
-- | 九年级 | 九年级 |
-- | 二年级 | 二年级 |
-- | 五年级 | 五年级 |
-- | 八年级 | 八年级 |
-- | 六年级 | 六年级 |
-- | 四年级 | 四年级 |
-- | 学龄前 | 学龄前 |
-- | 职一 | 职一 |
-- | 职三 | 职三 |
-- | 职二 | 职二 |
-- | 高一 | 高一 |
-- | 高三 | 高三 |
-- | 高二 | 高二 |
--
-- ## grade_stage_name_day（付费当天年级学段）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `aws.business_active_user_last_14_day`「grade_stage_*」列举口径类似） |
-- | 七年级 | 七年级 |
-- | 九年级 | 九年级 |
-- | 八年级 | 八年级 |
-- | 学龄前 | 学龄前 |
-- | 小中 | 小中 |
-- | 小初 | 小初 |
-- | 小高 | 小高 |
-- | 职一 | 职一 |
-- | 职三 | 职三 |
-- | 职二 | 职二 |
-- | 高一 | 高一 |
-- | 高三 | 高三 |
-- | 高二 | 高二 |
--
-- ## grade_stage_name_month（付费当月年级学段）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `aws.business_active_user_last_14_day`「grade_stage_*」列举口径类似） |
-- | (空字符串) |  |
-- | 七年级 | 七年级 |
-- | 九年级 | 九年级 |
-- | 八年级 | 八年级 |
-- | 学龄前 | 学龄前 |
-- | 小中 | 小中 |
-- | 小初 | 小初 |
-- | 小高 | 小高 |
-- | 职一 | 职一 |
-- | 职三 | 职三 |
-- | 职二 | 职二 |
-- | 高一 | 高一 |
-- | 高三 | 高三 |
-- | 高二 | 高二 |
--
-- ## grade_stage_name_year（付费当年年级学段）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `aws.business_active_user_last_14_day`「grade_stage_*」列举口径类似） |
-- | (空字符串) |  |
-- | 七年级 | 七年级 |
-- | 九年级 | 九年级 |
-- | 八年级 | 八年级 |
-- | 学龄前 | 学龄前 |
-- | 小中 | 小中 |
-- | 小初 | 小初 |
-- | 小高 | 小高 |
-- | 职一 | 职一 |
-- | 职三 | 职三 |
-- | 职二 | 职二 |
-- | 高一 | 高一 |
-- | 高三 | 高三 |
-- | 高二 | 高二 |
--
-- ## role（用户角色）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | student | 学生（见 `knowledge/glossary.md`「role」） |
-- | teacher | 老师（同上） |
--
-- ## attribution（B/C订单归属）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | b | B 端（见 `dw.dim_user` / 订单宽表字段 COMMENT） |
-- | c | C 端（同上） |
--
-- ## status（当前订单状态）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 支付成功 | 见字段 COMMENT |
-- | 退款成功 | 见字段 COMMENT |
--
-- ## business_gmv_attribution（业务GMV归属划分）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 体验营 | 体验营（见 aws 表枚举段） |
-- | 入校 | 入校（见 aws 表枚举段） |
-- | 商业化 | 商业化（见 aws 表枚举段） |
-- | 商业化-电商 | 商业化-电商（见 aws 表枚举段） |
-- | 新媒体变现 | 新媒体变现（见 aws 表枚举段） |
-- | 新媒体视频 | 新媒体视频（见 aws 表枚举段） |
-- | 电销 | 电销（见 aws 表枚举段） |
--
-- ## business_user_pay_status_statistics（商业化付费-统计维度）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | 新增 | 统计口径见 `dws.topic_user_info`「business_user_pay_status_statistics」COMMENT |
-- | 续费用户 | 同上 |
-- | 老未 | 同上 |
-- | 高净值用户 | 同上（与 DDL「大会员」表述可能不一致，以落表为准） |
--
-- ## business_user_pay_status_statistics_month（付费当月首次-统计维度）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | 新增 | 统计口径见 `dws.topic_user_info`「business_user_pay_status_statistics」COMMENT |
-- | 续费用户 | 同上 |
-- | 老未 | 同上 |
-- | 高净值用户 | 同上（与 DDL「大会员」表述可能不一致，以落表为准） |
--
-- ## business_user_pay_status_statistics_year（付费当年首次-统计维度）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 新增 | 统计口径见 `dws.topic_user_info`「business_user_pay_status_statistics」COMMENT |
-- | 续费用户 | 同上 |
-- | 老未 | 同上 |
-- | 高净值用户 | 同上（与 DDL「大会员」表述可能不一致，以落表为准） |
--
-- ## business_user_pay_status_business（商业化付费-业务维度）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL |  |
-- | 新用户 | 统计口径见 `dws.topic_user_info`「business_user_pay_status_business」COMMENT |
-- | 续费用户 | 同上 |
-- | 老用户 | 同上 |
-- | 高净值用户 | 同上 |
--
-- ## business_user_pay_status_business_month（付费当月首次-业务维度）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL |  |
-- | 新用户 | 统计口径见 `dws.topic_user_info`「business_user_pay_status_business」COMMENT |
-- | 续费用户 | 同上 |
-- | 老用户 | 同上 |
-- | 高净值用户 | 同上 |
--
-- ## business_user_pay_status_business_year（付费当年首次-业务维度）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 新用户 | 统计口径见 `dws.topic_user_info`「business_user_pay_status_business」COMMENT |
-- | 续费用户 | 同上 |
-- | 老用户 | 同上 |
-- | 高净值用户 | 同上 |
--
-- ## good_kind_id_level_1（商品类目一级 id）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | 2f1ae7f3-f15b-4023-b4fb-d53876e9f1d4 | 与good_kind_name_level_1（商品类目一级）对应，下同 |
-- | 508f7bb6-2f45-46bb-8e3f-fcab8fa00afb |  |
-- | b2bc7e16-4d83-40e5-ac51-b0e574b55d6c |  |
-- | bb7d9849-57e0-4838-a35a-cb4e6ca4ddba |  |
-- | cd445957-06eb-4cd9-afeb-0ded1c4677a7 |  |
-- | d76c5526-e4cb-4e9f-adfe-662db4dc7cb9 |  |
-- | f76be748-e94c-453d-a3d7-9800113bcb7b |  |
--
-- ## good_kind_id_level_2（商品类目二级 id）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | 00123a28-1e6b-4760-b36f-7e9c2c37df51 | 与good_kind_name_level_2（商品类目一级）对应，下同 |
-- | 04418594-744a-4bab-a6cf-da504c1576ef |  |
-- | 329c024c-9c8a-4e53-95a2-b751d9dec9c8 |  |
-- | 3aa9d1fb-0c47-407e-9d5b-35c73768ec14 |  |
-- | 4983b21c-d39d-452f-8c43-6a02928f1c4c |  |
-- | 5e42f66c-0376-41b6-860b-9e437662283a |  |
-- | 6f5c4942-48f5-403b-96a1-4890dc823f02 |  |
-- | 7ecdf8da-0a44-4dec-a546-73a10acad159 |  |
-- | 7f3623ad-b603-4a36-a69e-7cacd8f48022 |  |
-- | 815fa8a3-544f-404f-bf23-112a940758a5 |  |
-- | 87d1816a-ad3b-4f87-bb77-44e16f088d5f |  |
-- | 88fad460-6c3e-496a-86aa-53c355b6961c |  |
-- | 90a3dbee-fe78-4201-9ee5-3641de6c586f |  |
-- | 9e8f37e5-ac35-4103-b811-fe1b502e39d3 |  |
-- | 9eb79b68-99f2-4bd0-a9c7-061af50a186a |  |
-- | a3ef9ba6-1bdd-4699-9eaa-0cfd2408b76c |  |
-- | b606a730-196c-4328-9e04-899424f21cb5 |  |
-- | b6a07a14-b0d0-430e-8a30-60f8200c6bdb |  |
-- | c1b648f0-052c-4817-a0b9-37258d4986e5 |  |
-- | ca753faf-5a48-4f05-8676-73f38e7cb5f4 |  |
-- | d7aef21f-79a6-42e0-bd2e-fb8fd1f2e025 |  |
-- | d99f155b-c0e7-4ee6-9833-39a6eadbab58 |  |
-- | f5463f28-9e13-465e-a428-34618d8ddae0 |  |
-- | f7b52708-905f-4ebe-850a-1d8846ca8f73 |  |
--
-- ## good_kind_id_level_3（商品类目三级 id）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | 012179f4-2381-4041-960e-daed9e93b4e9 | 与good_kind_name_level_3（商品类目一级）对应，下同 |
-- | 0c25143c-9ea1-483e-b36f-9694f13a2ade |  |
-- | 0dcd12f7-c6a5-4fc7-8c86-5e69099cbb09 |  |
-- | 15428ca9-20ef-4202-93af-75c22255854e |  |
-- | 2438bcab-6da8-4aa4-98a8-7b47b6ed7cfc |  |
-- | 2c8a6d55-3071-4165-8617-4bef0055ccca |  |
-- | 31b7ea04-1c16-452c-9922-720226471c4b |  |
-- | 3644c522-5fda-49af-8cff-6e0c66402b97 |  |
-- | 3798125e-e1a6-4f97-81cf-def49a792ee3 |  |
-- | 3bf5762c-f9a6-4a04-b6e8-506f097474e4 |  |
-- | 4f8f8990-f64c-4424-9110-e58c2eb47f6f |  |
-- | 54893be5-68ce-4562-b6f9-c4c77987a8e3 |  |
-- | 5ac31a9d-9707-4bac-809d-34947db2ce3f |  |
-- | 5f1ece35-9cb1-48be-b399-6d25bf302b60 |  |
-- | 5f57b8fc-adaf-45c6-b339-7d86f60d43a4 |  |
-- | 7670f291-f16f-463a-962a-68f18c8cdfa9 |  |
-- | 7cf62e78-b244-41d3-b3a5-9490b87dfef2 |  |
-- | 80eb15bb-2d3d-49a5-9ff5-0a03de254ed2 |  |
-- | 848229e6-4ba3-4f04-ae4c-494939276ca5 |  |
-- | 864412e6-ed59-4eae-a972-36f628926e09 |  |
-- | 8d599f9c-ef85-439a-a4dd-e0e4c1f4faa2 |  |
-- | 931ce422-2b2c-4bb7-b0bb-2cb8d42d3601 |  |
-- | 93804163-4872-4a3e-b260-a25bba3fd2da |  |
-- | 955696d3-6b4e-445b-afa7-0f94cfccc3ef |  |
-- | 9f229cef-b80a-4fa6-b772-f0acb2d9db3e |  |
-- | a0ef9569-61b0-42b4-af38-2d357d076902 |  |
-- | a7829379-eb75-4681-86c8-168e38c5b130 |  |
-- | a8bef5b4-17de-456a-9b4d-b9881d469f38 |  |
-- | a9af0cfc-96ba-4bf3-bca8-3122a7381a37 |  |
-- | adb16bbe-2b0f-4674-bc6d-08282e410af8 |  |
-- | b5c1c6c5-30f6-41e5-87de-ee3d494c4358 |  |
-- | b8702f87-87ab-4f4d-aa15-0fc475ad75a0 |  |
-- | c190551a-e86d-4ad1-9a3f-80a276765ddc |  |
-- | cad7b43f-3177-4984-b84d-21b7bda55396 |  |
-- | cf1b6fa1-781d-4c63-b8ea-324ead84a2cb |  |
-- | d17f46d8-3e4f-45f8-9d11-9db38f5e5ad9 |  |
-- | d20bec59-cf5c-422d-bb66-baa8040747b0 |  |
-- | d30b4bd2-51be-4352-a043-89181322c019 |  |
-- | d63b5ea7-47d3-465e-8acb-147526d6231a |  |
-- | d8563061-2a7a-4f9e-b404-431e2663db53 |  |
-- | dad67779-4f78-4c6e-86db-1b2681687268 |  |
-- | dc23ef8b-1491-40a8-8e2b-a4cee361f065 |  |
-- | dd39a485-2504-4c5d-b373-a0e366c746cd |  |
-- | ec30550b-60d1-4554-9b01-6f095b2b97cd |  |
-- | ee8e64d4-b43e-4858-a6cd-81c8c94fc055 |  |
-- | efee4e99-35c9-4b26-951d-8592bac8d90a |  |
-- | f2444f2f-105c-43dd-8f81-f81ea347de96 |  |
-- | f31eb29a-3fd4-4336-83d0-0f1b48efdfa2 |  |
-- | f6f781ef-b49e-4e63-89a9-8b8bd4e0dfbc |  |
--
-- ## good_kind_name_level_1（商品类目一级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | AI课堂 |  |
-- | 体验品 |  |
-- | 其他商品 |  |
-- | 方案型商品 |  |
-- | 测试使用一级类目 |  |
-- | 研学商品 |  |
-- | 零售商品 |  |
--
-- ## good_kind_name_level_2（商品类目二级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | AI课堂 |  |
-- | 一年积木块 |  |
-- | 体验版组合商品 |  |
-- | 其他体验品 |  |
-- | 其他综合类商品 |  |
-- | 其他辅助学习产品 |  |
-- | 升单后加购 |  |
-- | 同步课 |  |
-- | 同步课加培优课 |  |
-- | 培优课 |  |
-- | 学习方法课 |  |
-- | 学习机加购 |  |
-- | 学习机单售 |  |
-- | 学前启蒙 |  |
-- | 实物商品 |  |
-- | 心理咨询 |  |
-- | 拓展课 |  |
-- | 未分类课程商品 |  |
-- | 测试使用二级类目改名字测试 |  |
-- | 研学商品 |  |
-- | 硬件配件 |  |
-- | 组合商品 |  |
-- | 衔接课 |  |
-- | 试卷库 |  |
--
-- ## good_kind_name_level_3（商品类目三级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | AI通识课 |  |
-- | 书籍 |  |
-- | 体验版组合商品 |  |
-- | 全价购买 |  |
-- | 其他体验品 |  |
-- | 初中品-1年同步课加培优课 |  |
-- | 初中品-2年同步课加培优课 |  |
-- | 初中品-3年同步课加培优课 |  |
-- | 千元品2.0 |  |
-- | 升单后加购-学段加购 |  |
-- | 升学志愿 |  |
-- | 单后赠品 |  |
-- | 单日营 |  |
-- | 同步课-12个月 |  |
-- | 同步课-3个月 |  |
-- | 同步课-智课特殊品 |  |
-- | 同步课加培优课 |  |
-- | 同步课加培优课-智课特殊品 |  |
-- | 同步课加培优课流量品 |  |
-- | 周边 |  |
-- | 培优课-12个月 |  |
-- | 培优课-3个月 |  |
-- | 培优课-到期型 |  |
-- | 学习方法课 |  |
-- | 学习机加购-平板加购 |  |
-- | 学前启蒙 |  |
-- | 寒暑假营 |  |
-- | 小初品-4年同步课 |  |
-- | 小初品-4年同步课加培优课 |  |
-- | 小初品-5年同步课加培优课 |  |
-- | 小初品-6年同步课加培优课 |  |
-- | 小学品-6年同步课 |  |
-- | 心理咨询 |  |
-- | 拓展同步 |  |
-- | 拓展课 |  |
-- | 教师vip |  |
-- | 文创 |  |
-- | 未分类课程商品 |  |
-- | 测试使用三级类目 |  |
-- | 研学商品 |  |
-- | 硬件+软件采购 |  |
-- | 硬件商城 |  |
-- | 硬件采购 |  |
-- | 衔接课 |  |
-- | 试卷库 |  |
-- | 软件采购 |  |
-- | 高中品-1年同步课加培优课 |  |
-- | 高中品-2年同步课加培优课 |  |
-- | 高中品-3年同步课加培优课 |  |
--
-- ## fix_good_kind_id_level_2（修正二级类目 id,积木块抵扣「升单商品」专用,使用这个字段前要确认用途）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | 00123a28-1e6b-4760-b36f-7e9c2c37df51 | 与fix_good_kind_name_level_2（修正二级类目）对应，下同 |
-- | 04418594-744a-4bab-a6cf-da504c1576ef |  |
-- | 0d63071c-a690-4b51-ba2d-c9387c69026c |  |
-- | 329c024c-9c8a-4e53-95a2-b751d9dec9c8 |  |
-- | 3aa9d1fb-0c47-407e-9d5b-35c73768ec14 |  |
-- | 4983b21c-d39d-452f-8c43-6a02928f1c4c |  |
-- | 5e42f66c-0376-41b6-860b-9e437662283a |  |
-- | 6f5c4942-48f5-403b-96a1-4890dc823f02 |  |
-- | 7ecdf8da-0a44-4dec-a546-73a10acad159 |  |
-- | 7f3623ad-b603-4a36-a69e-7cacd8f48022 |  |
-- | 815fa8a3-544f-404f-bf23-112a940758a5 |  |
-- | 87d1816a-ad3b-4f87-bb77-44e16f088d5f |  |
-- | 88fad460-6c3e-496a-86aa-53c355b6961c |  |
-- | 90a3dbee-fe78-4201-9ee5-3641de6c586f |  |
-- | 9e8f37e5-ac35-4103-b811-fe1b502e39d3 |  |
-- | 9eb79b68-99f2-4bd0-a9c7-061af50a186a |  |
-- | a3ef9ba6-1bdd-4699-9eaa-0cfd2408b76c |  |
-- | b606a730-196c-4328-9e04-899424f21cb5 |  |
-- | b6a07a14-b0d0-430e-8a30-60f8200c6bdb |  |
-- | c1b648f0-052c-4817-a0b9-37258d4986e5 |  |
-- | ca753faf-5a48-4f05-8676-73f38e7cb5f4 |  |
-- | d7aef21f-79a6-42e0-bd2e-fb8fd1f2e025 |  |
-- | d99f155b-c0e7-4ee6-9833-39a6eadbab58 |  |
-- | f5463f28-9e13-465e-a428-34618d8ddae0 |  |
-- | f7b52708-905f-4ebe-850a-1d8846ca8f73 |  |
--
-- ## fix_good_kind_name_level_2（修正二级类目）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | AI课堂 |  |
-- | 一年积木块 |  |
-- | 体验版组合商品 |  |
-- | 其他体验品 |  |
-- | 其他综合类商品 |  |
-- | 其他辅助学习产品 |  |
-- | 升单后加购 |  |
-- | 升单商品 |  |
-- | 同步课 |  |
-- | 同步课加培优课 |  |
-- | 培优课 |  |
-- | 学习方法课 |  |
-- | 学习机加购 |  |
-- | 学习机单售 |  |
-- | 学前启蒙 |  |
-- | 实物商品 |  |
-- | 心理咨询 |  |
-- | 拓展课 |  |
-- | 未分类课程商品 |  |
-- | 测试使用二级类目改名字测试 |  |
-- | 研学商品 |  |
-- | 硬件配件 |  |
-- | 组合商品 |  |
-- | 衔接课 |  |
-- | 试卷库 |  |
--
-- ## fix_good_year（修正的商品时长）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0天 |  |
-- | 10天 |  |
-- | 124天 |  |
-- | 12年 |  |
-- | 186天 |  |
-- | 1天 |  |
-- | 1年 |  |
-- | 2026年03月到期 |  |
-- | 2026年04月到期 |  |
-- | 2026年06月到期 |  |
-- | 2026年07月到期 |  |
-- | 2027年06月到期 |  |
-- | 2028年06月到期 |  |
-- | 2年 |  |
-- | 30天 |  |
-- | 31天 |  |
-- | 3天 |  |
-- | 3年 |  |
-- | 4年 |  |
-- | 5年 |  |
-- | 62天 |  |
-- | 6年 |  |
-- | 7天 |  |
-- | 93天 |  |
--
-- ## business_good_kind_name_level_1（策略组修正类目一级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 其他 | 其他商品 |
-- | 组合品 | 组合品 |
-- | 续购 | 续购 |
-- | 零售商品 | 零售商品 |
--
-- ## business_good_kind_name_level_2（策略组修正类目二级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 其他 | 其他商品 |
-- | 单学段商品 | 单学段商品 |
-- | 多学段商品 | 多学段商品 |
-- | 续购 | 续购 |
-- | 零售商品 | 零售商品 |
--
-- ## business_good_kind_name_level_3（策略组修正类目三级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 体验品 | 体验品 |
-- | 其他 | 其他商品 |
-- | 初中品 | 初中品 |
-- | 同步课 | 同步课 |
-- | 培优课 | 培优课 |
-- | 学习机加购 | 学习机加购 |
-- | 学段加购 | 学段加购 |
-- | 小初同步品 | 小初同步品 |
-- | 小初品 | 小初品 |
-- | 小学品 | 小学品 |
-- | 拓展课 | 拓展课 |
-- | 研学 | 研学 |
-- | 高中品 | 高中品 |
--
-- ## course_timing_kind（商品分类标签，到期型/时长型）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | 到期型 | 见 `knowledge/glossary.md`「course_timing_kind」 |
-- | 时长型 | 见 `knowledge/glossary.md`「course_timing_kind」 |
--
-- ## course_group_kind（商品分组标签，公私域主推等）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未知 |
-- | 公域主推品 | 见 `knowledge/glossary.md`「course_group_kind」 |
-- | 私域主推品 | 见 `knowledge/glossary.md`「course_group_kind」 |
--
-- ## strategy_type（策略类型，组合品场景）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | {历史大会员续购策略} | 见 `knowledge/glossary.md`「strategy_type」；宜在组合品子集上使用 |
-- | {多孩策略} | 同上 |
-- | {学习机加购策略} | 同上 |
-- | {无策略} | 同上 |
-- | {补差策略} | 同上 |
-- | {高中囤课策略} | 同上 |
--
-- ## user_strategy_tag_day（策略用户分层-日）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 付费加购品用户 | 见 `dws.topic_user_active_detail_day` / `dws.topic_user_info` 第三段 |
-- | 付费组合品用户 | 同上 |
-- | 付费零售品用户 | 同上 |
-- | 历史大会员用户_不可续购 | 同上 |
-- | 历史大会员用户_可续购 | 同上 |
-- | 新用户 | 同上 |
-- | 老用户 | 同上 |
--
-- ## big_vip_kind_day（历史大会员标签-日）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 历史大会员用户_不可续购 | 同上，对应user_strategy_tag_day="历史大会员用户_不可续购" |
-- | 历史大会员用户_可续购 | 同上，对应user_strategy_tag_day="历史大会员用户_可续购" |
-- | 非历史大会员用户 | 同上，对应user_strategy_tag_day非以上两类的其他用户 |
--
-- ## user_strategy_eligibility_day（用户策略资格-日）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | (空字符串) | 无策略资格（见 `dws.topic_user_info`「user_strategy_eligibility_day」） |
-- | 历史大会员续购策略资格;学习机加购策略资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 历史大会员续购策略资格;学习机加购策略资格;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
--
-- ## user_strategy_tag_month（策略用户分层-月）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 付费加购品用户 | 见 `dws.topic_user_active_detail_day` / `dws.topic_user_info` 第三段 |
-- | 付费组合品用户 | 同上 |
-- | 付费零售品用户 | 同上 |
-- | 历史大会员用户_不可续购 | 同上 |
-- | 历史大会员用户_可续购 | 同上 |
-- | 新用户 | 同上 |
-- | 老用户 | 同上 |
--
-- ## big_vip_kind_month（历史大会员标签-月）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 历史大会员用户_不可续购 | 同上 |
-- | 历史大会员用户_可续购 | 同上 |
-- | 非历史大会员用户 | 见活跃日表 / `aws.business_active_user_last_14_day` |
--
-- ## user_strategy_eligibility_month（用户策略资格-月）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | (空字符串) | 无策略资格（见 `dws.topic_user_info`「user_strategy_eligibility_day」） |
-- | 历史大会员续购策略资格;学习机加购策略资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 历史大会员续购策略资格;学习机加购策略资格;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
--
-- ## user_strategy_tag_year（策略用户分层-年）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 付费加购品用户 | 见 `dws.topic_user_active_detail_day` / `dws.topic_user_info` 第三段 |
-- | 付费组合品用户 | 同上 |
-- | 付费零售品用户 | 同上 |
-- | 历史大会员用户_不可续购 | 同上 |
-- | 历史大会员用户_可续购 | 同上 |
-- | 新用户 | 同上 |
-- | 老用户 | 同上 |
--
-- ## big_vip_kind_year（历史大会员标签-年）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 历史大会员用户_不可续购 | 同上 |
-- | 历史大会员用户_可续购 | 同上 |
-- | 非历史大会员用户 | 见活跃日表 / `aws.business_active_user_last_14_day` |
--
-- ## user_strategy_eligibility_year（用户策略资格-年）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | (空字符串) | 无策略资格（见 `dws.topic_user_info`「user_strategy_eligibility_day」） |
-- | 历史大会员续购策略资格;学习机加购策略资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 历史大会员续购策略资格;学习机加购策略资格;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 学习机加购策略资格;高中囤课策略资格;小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
-- | 小学品升级补差至小初品资格 | 组合策略资格串（见 `dws.topic_user_info`「user_strategy_eligibility_*」列举） |
--
