-- =====================================================
-- 电销订单表 aws.crm_order_info
-- =====================================================
--

-- =====================================================
-- 【表粒度】
--   一个订单一条记录（电销域；无分区）
--
-- =====================================================

-- =====================================================
-- 【与全公司订单宽表 dws.topic_order_detail 的关系】
--
-- 【业务边界】（谭晨）
--   - 本表：仅电销业务订单。
--   - 宽表 dws.topic_order_detail：全公司所有业务订单（电销、新媒体、入校、体验营等）。
--
-- 【营收归属为何与宽表「筛电销」不一致】
--   - 宽表中 business_gmv_attribution 按**服务期优先级**归属到某一业务；双服务期用户的营收可能归属非电销。
--   - 因此：在宽表上增加 business_gmv_attribution = '电销' 等条件后的营收，**不等于**本表电销营收。
--
-- 【选表原则】
--   - 活跃转化分析、判断用户是否购买过某商品 → 用宽表。
--   - **电销营收分析、电销日度收入、线索归因** → 用本表 aws.crm_order_info。
--   - 全公司订单宽表与电销专用 aws.crm_order_info 区分，见 glossary「选表」。
--
-- 【宽表侧与电销表同名字段的校验结论】
--   以下字段在宽表与电销订单表之间已做一致性验证（用于理解两表联查时的可信字段）：
--   - workplace_id / regiment_id / worker_id：组织架构字段（谭晨文档：**100% 匹配**）
--   - is_clue_seat：线索是否在坐席名下（谭晨文档：**99.92% 匹配**）
--
-- =====================================================

-- =====================================================
-- 【业务定位】
--   - 电销营收、日度收入、线索归因 recent_info_uuid / modify_recent_info_uuid
--   - 与 dws.topic_order_detail 的详细区别与选表见上文「与全公司订单宽表的关系」及 `knowledge/glossary.md`
--
-- =====================================================

-- =====================================================
-- 【统计口径】
--   本表电销实收：SUM(amount)；常与 status = '支付成功' 联用（指标定义见 glossary）
--
--   ⚠️ 勿与宽表「筛电销」简单等同：若在宽表用 business_gmv_attribution = '电销' 汇总营收，
--   与在本表汇总电销营收**口径不同**，原因见上文「营收归属为何与宽表筛电销不一致」
--
-- =====================================================

-- =====================================================
-- 【常用关联】
--   - recent_info_uuid / modify_recent_info_uuid → aws.clue_info.info_uuid
--   - 与 dws.topic_order_detail：可按 order_id 对齐；对齐时注意两表粒度不同（宽表为子订单粒度）。
--
-- =====================================================

-- =====================================================
-- 【常用筛选条件】
--   ★必加条件：（按分析目的，电销产能/营收常见组合）
--   - is_test = false -- 排除测试订单
--   - worker_id <> 0 -- 排除无坐席（坐席产能分析时）
--   场景条件：
--   - workplace_id IN (4, 400, 702) -- 电销职场
--   - regiment_id NOT IN (0, 303, 546) -- 排除指定团
--   - in_salary = 1 -- 计薪口径
--   - status = '支付成功' -- 看营收时
--
-- =====================================================

-- =====================================================
-- 【注意事项】
--   - good_type 已弃用，推荐 good_kind_name_level_2 / 策略组类目字段（与宽表谭晨文档中「类目两套体系」表述一致：
--     good_kind_name_level_* 为商品 2.0 体系；business_good_kind_name_level_* 为策略组修正类目；以线上与 glossary 为准）
--   - 更新频率 T+1
--   - 知识库约定：取数与分析使用 business_user_pay_status_*；
--
-- =====================================================

CREATE TABLE
  `aws`.`crm_order_info` (
    `order_id` string COMMENT '订单id',
    `user_id` string COMMENT '用户id',
    `user_sk` string COMMENT '用户sk',
    `worker_id` int COMMENT '坐席id',
    `order_created_time` timestamp COMMENT '订单创建时间',
    `pay_time` timestamp COMMENT '支付时间',
    `order_type` smallint COMMENT '订单类型 1新增 2付费',
    `amount` double COMMENT '订单金额',
    `sync_type` smallint COMMENT '同步方式：1-自动判单>，2-申诉, 3-七陌导入, 4-专属链接',
    `sync_status` smallint COMMENT '同步状态：1-正常，2->异常',
    `status` string COMMENT '订单状态',
    `stage` string COMMENT '下单年级',
    `department_id` int COMMENT '学部id',
    `regiment_id` int COMMENT '团id',
    `heads_id` int COMMENT '主管组id',
    `team_id` int COMMENT '小组id',
    `sell_from` string COMMENT '商品售卖来源',
    `created_at` timestamp COMMENT '创建日期',
    `updated_at` timestamp COMMENT '更新日期',
    `is_pad` int COMMENT '是否包含pad的订单',
    `pad_name` string COMMENT '订单包含pad的名字',
    `business_attribution` string COMMENT '业务群归属：b 端营收、小学网课营收、轻课营收',
    `worker_name` string COMMENT '坐席名称',
    `good_id` string COMMENT '商品id',
    `good_name` string COMMENT '商品名称',
    `is_pad_price_difference_order` smallint COMMENT '是否体验机补差价订单',
    `first_clue_source` string COMMENT '成单用户首次被领取时线索来源',
    `recent_info_uuid` string COMMENT '成单用户最近一次被领取的info_uuid',
    `workplace_id` int COMMENT '销售职场id',
    `business_gmv_attribution` string COMMENT '业务GMV归属划分',
    `real_amount` double COMMENT '订单实付金额',
    `good_sell_kind` string COMMENT '商品售卖类型',
    `good_year` string COMMENT '商品时长',
    `model_type_array` array < string > COMMENT '订单平板型号',
    `original_amount` double COMMENT '订单原价',
    `xugou_order_kind` string COMMENT '续购订单类型',
    `xugou_pre_order_id` string COMMENT '续购前序订单id',
    `dynamic_diff_price_type` string COMMENT '补差价类型',
    `good_original_amount` double COMMENT '商品原价',
    `modify_recent_info_uuid` string COMMENT '矫正成单用户最近一次被领取的info_uuid',
    `team_ids` array < string > COMMENT '全域业绩归属',
    `team_names` array < string > COMMENT '全域业绩归属',
    `good_category` string COMMENT '商品类别',
    `sku_group_good_id` string COMMENT 'sku商品组id',
    `group` array < string > COMMENT '商品标签',
    `in_salary` smallint COMMENT '是否计入工资',
    `salary_threshold` string COMMENT '订单计入工资的金额阈值',
    `good_type` string COMMENT '商品类型(已弃用,推荐使用dw.fact_order_detail:good_kind_name_level_2)',
    `pad_type` string COMMENT '平板类型',
    `kind_array` array < string > COMMENT '子商品的类型-数组',
    `good_biz_type` string COMMENT '商品业务类型',
    `mid_grade` string COMMENT '中学修正年级',
    `mid_stage_name` string COMMENT '中学修正年级',
    `gender` string COMMENT '用户性别',
    `regist_time` timestamp COMMENT '注册时间',
    `province` string COMMENT '省',
    `city` string COMMENT '市',
    `city_class` string COMMENT '城市分线',
    `interest_subsidy_method` string COMMENT '贴息方式',
    `hire_purchase_commission` double COMMENT '分期手续费',
    `user_pay_status_statistics` string COMMENT '【知识库不引用】取数用 business_user_pay_status_statistics。原：付费标签：统计维度口径',
    `user_pay_status_business` string COMMENT '【知识库不引用】取数用 business_user_pay_status_business。原：付费标签：业务维度口径',
    `business_user_pay_status_statistics` string COMMENT '商业化付费会员拆分为大会员付费、非大会员付费',
    `business_user_pay_status_business` string COMMENT '付费分层-业务维度',
    `good_kind_name_level_1` string COMMENT '商品类目-一级',
    `good_kind_name_level_2` string COMMENT '商品类目-二级',
    `good_kind_name_level_3` string COMMENT '商品类目-三级',
    `good_kind_id_level_1` string COMMENT '商品类目-一级id',
    `good_kind_id_level_2` string COMMENT '商品类目-二级id',
    `good_kind_id_level_3` string COMMENT '商品类目-三级id',
    `fix_good_kind_id_level_2` string COMMENT '修正-商品类目-二级id(积木块抵扣「升单商品」专用)',
    `fix_good_kind_name_level_2` string COMMENT '修正-商品类目-二级(积木块抵扣「升单商品」专用)',
    `is_clue_seat` smallint COMMENT '线索是否在坐席名下',
    `business_good_kind_name_level_1` string COMMENT '策略组修正-商品类目-一级',
    `business_good_kind_name_level_2` string COMMENT '策略组修正-商品类目-二级',
    `business_good_kind_name_level_3` string COMMENT '策略组修正-商品类目-三级',
    `fix_deductible_price` double COMMENT '修正-补差价总金额',
    `is_test` boolean COMMENT '是否是测试订单',
    `fix_good_year` string COMMENT '修正的商品时长',
    `course_timing_kind` string COMMENT '商品分类标签',
    `course_group_kind` string COMMENT '商品分组标签',
    `strategy_type` string COMMENT '策略类型:20260101上线以后为业务数据，之前按规则清洗',
    `strategy_detail` string COMMENT '策略明细：策略及对应的金额明细'
  ) COMMENT '一个订单一条记录' ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/crm_order_info'

-- =====================================================
-- 枚举值
-- =====================================================
--
-- （待补充：按 `knowledge/SPEC.md` 与 `表结构模版.md`，将关键字段枚举从线上 COMMENT 或 `knowledge_old/enums.md` 整理至下表；布尔/二值字段仅在字段 COMMENT 说明，可不列本段。）
-- 宽表谭晨文档中含大量与订单、付费标签相关的枚举节选，若本表需与宽表字段对齐展示，可从 glossary / 谭晨「全公司订单宽表」枚举段交叉引用。
--
-- ## 示例字段名（字段说明）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | （待补充） | （待补充） |
