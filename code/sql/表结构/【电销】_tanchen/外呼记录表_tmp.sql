-- =====================================================
-- 外呼记录表-tmp tmp.niyiqiao_crm_clue_call_record
-- =====================================================
-- 【表粒度】★必填
--   一次外呼 = 一条记录（action_id 唯一，与底表一致）
--
--   数据范围：2023-01-01 至昨日
--   更新频率：每日更新一次
--   已内置过滤：workplace_id IN (4,400,702)、regiment_id NOT IN (0,303,546)
--
-- 【业务定位】
--   外呼记录宽表，已内置职场/团组过滤，无需再加筛选条件
--   数据范围：2023-01-01 至昨日，每日更新
--   与底表(dw.fact_call_history)的区别：
--   - 本表：已内置 workplace_id/regiment_id 过滤 + 组织/渠道维表 JOIN
--   - 底表：原始数据，需手动加筛选条件
--
--   选表原则：
--   - 2023-01-01 及之后 → 直接用本表
--   - 涉及 2023-01-01 之前 → 用逻辑脚本将时间起点往前改
--   - 逻辑脚本 → code/sql/外呼情况/外呼记录表_tmp.sql
--
-- 【数据来源】
--   逻辑脚本 → code/sql/外呼情况/外呼记录表_tmp.sql
--   由底表(dw.fact_call_history) + 组织/线索/渠道等 JOIN 产出
--
-- 【统计口径】
--   注意：业务指标的权威定义在 glossary.md，本段仅记录"用本表怎么算"
--   外呼次数 = COUNT(action_id)
--   接通量 = SUM(CASE WHEN is_connect = 1 THEN 1 ELSE 0 END)
--   有效接通量 = SUM(CASE WHEN is_valid_connect = 1 THEN 1 ELSE 0 END)
--
-- 【常用筛选条件】
--   ★必加条件：
--   无（本表已内置职场、团组过滤）
--
--   场景条件：
--   - call_created_at >= '${start_date}'    -- 按时间范围筛选
--
-- 【注意事项】
--   ⚠️ 是否接通统一用 is_connect；有效接通阈值：通话时长 ≥ 10 秒（is_valid_connect = 1）
--   ⚠️ call_status 默认不使用，特殊需求明确要用时再用
--   ⚠️ user_type_name 已按本表逻辑清洗，与底表原始值口径不同
-- =====================================================

CREATE TABLE
  `tmp`.`niyiqiao_crm_clue_call_record` (
    `info_uuid` string COMMENT '线索id',
    `user_id` string COMMENT '用户id',
    `user_type_name` string COMMENT '用户类型：续费/老未/新增-当月注册/新增-非当月注册，须按本表逻辑清洗使用',
    `clue_stage` string COMMENT '线索学段',
    `clue_source_name` string COMMENT '线索来源名称，JOIN维表tmp.wuhan_clue_soure_name',
    `clue_source_name_level_1` string COMMENT '线索来源一级分类',
    `clue_grade` string COMMENT '年级',
    `city_class` string COMMENT '客户所在城市线级',
    `province` string COMMENT '省',
    `city` string COMMENT '市',
    `business_user_pay_status_business` string COMMENT '付费分层：大会员付费用户、续费用户、新用户、老用户等（领取时快照）',
    `action_id` string COMMENT '外呼记录唯一ID（主键）',
    `channel_id` string COMMENT '外呼渠道中文：七陌/天眼/蘑谷云/智鱼/百川/百悟/天田',
    `call_phone` string COMMENT '脱敏：11位取前3位号段、无号码、非11位手机号',
    `call_created_at` string COMMENT '外呼创建时间，substr(created_at,1,19)',
    `call_status` string COMMENT '呼叫状态（由call_state派生，部分渠道无值），默认不用，特殊需求才用',
    `deal_times` int COMMENT '振铃时长（秒）',
    `call_time_length` int COMMENT '呼叫时长（秒）',
    `is_connect` smallint COMMENT '是否接通 0否 1是',
    `is_valid_connect` smallint COMMENT '是否有效接通 0否 1是，口径：通话时长>=10秒',
    `worker_id` string COMMENT '销售/坐席id',
    `worker_name` string COMMENT '销售名称，优先crm.worker否则底表agent_name',
    `department_name` string COMMENT '学部名称，已JOIN组织架构',
    `regiment_name` string COMMENT '团名称',
    `heads_name` string COMMENT '主管组名称',
    `team_name` string COMMENT '小组名称',
    `clue_created_type` string COMMENT '是否当日领当日呼：线索领取日=外呼日则为是否则否',
    `clue_created_type_mon` string COMMENT '是否当月领当月呼：同月则为是否则否'
  ) COMMENT '外呼记录宽表：由fact_call_history+组织/线索/渠道等JOIN产出，2023-01-01起，已含职场团组过滤；每日更新。涉及2023年前用逻辑脚本将时间筛选往前改' ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe' STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/tmp.db/niyiqiao_crm_clue_call_record' TBLPROPERTIES (
    'spark.sql.create.version' = '3.3.3',
    'spark.sql.sources.schema' = '{"type":"struct","fields":[{"name":"info_uuid","type":"string","nullable":true,"metadata":{"comment":"线索id"}},{"name":"user_id","type":"string","nullable":true,"metadata":{"comment":"用户id"}},{"name":"user_type_name","type":"string","nullable":true,"metadata":{}},{"name":"clue_stage","type":"string","nullable":true,"metadata":{"comment":"线索学段"}},{"name":"clue_source_name","type":"string","nullable":true,"metadata":{}},{"name":"clue_source_name_level_1","type":"string","nullable":true,"metadata":{}},{"name":"clue_grade","type":"string","nullable":true,"metadata":{"comment":"年级"}},{"name":"city_class","type":"string","nullable":true,"metadata":{"comment":"客户所在城市线级"}},{"name":"province","type":"string","nullable":true,"metadata":{"comment":"省"}},{"name":"city","type":"string","nullable":true,"metadata":{"comment":"市"}},{"name":"business_user_pay_status_business","type":"string","nullable":true,"metadata":{"comment":"大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)"}},{"name":"action_id","type":"string","nullable":true,"metadata":{"comment":"唯一ID"}},{"name":"channel_id","type":"string","nullable":false,"metadata":{}},{"name":"call_phone","type":"string","nullable":true,"metadata":{}},{"name":"call_created_at","type":"string","nullable":true,"metadata":{}},{"name":"call_status","type":"string","nullable":true,"metadata":{"comment":"呼叫状态"}},{"name":"deal_times","type":"integer","nullable":true,"metadata":{"comment":"振铃时长（秒）"}},{"name":"call_time_length","type":"integer","nullable":true,"metadata":{"comment":"呼叫时长"}},{"name":"is_connect","type":"short","nullable":true,"metadata":{"comment":"是否接通"}},{"name":"is_valid_connect","type":"short","nullable":true,"metadata":{"comment":"是否有效接通"}},{"name":"worker_id","type":"string","nullable":true,"metadata":{"comment":"销售id"}},{"name":"worker_name","type":"string","nullable":true,"metadata":{}},{"name":"department_name","type":"string","nullable":true,"metadata":{"comment":"学部名称"}},{"name":"regiment_name","type":"string","nullable":true,"metadata":{}},{"name":"heads_name","type":"string","nullable":true,"metadata":{}},{"name":"team_name","type":"string","nullable":true,"metadata":{}},{"name":"clue_created_type","type":"string","nullable":false,"metadata":{}},{"name":"clue_created_type_mon","type":"string","nullable":false,"metadata":{}}]}',
    'transient_lastDdlTime' = '1773785118'
  )

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## user_type_name（用户类型）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 新增-当月注册 | 当月注册的新用户 |
-- | 新增-非当月注册 | 非当月注册的新用户 |
-- | 续费 | 续费用户 |
-- | 老未 | 老未付费用户 |
--
-- ## channel_id（外呼渠道）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 七陌 | |
-- | 天眼 | |
-- | 蘑谷云 | |
-- | 智鱼 | |
-- | 百川 | |
-- | 百悟 | |
-- | 天田 | |
