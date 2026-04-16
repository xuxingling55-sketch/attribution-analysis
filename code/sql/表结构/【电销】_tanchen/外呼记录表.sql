-- =====================================================
-- 外呼记录表-底表 dw.fact_call_history
-- =====================================================
-- 【表粒度】★必填
--   一次外呼 = 一条记录（action_id 唯一）
--   分区字段：day（int 类型，格式 yyyyMMdd）
--
-- 【业务定位】
--   外呼记录底表，需手动加职场/团组筛选条件
--   与 tmp 表(tmp.niyiqiao_crm_clue_call_record)的区别：
--   - 本表：原始底表，覆盖全部历史数据，需手动加筛选条件
--   - tmp 表：已内置职场/团组过滤，覆盖 2023-01-01 至昨日
--
--   选表原则：
--   - 2023-01-01 及之后 → 直接用 tmp 表
--   - 涉及 2023-01-01 之前 → 用本表或用逻辑脚本把时间起点往前改
--   - 逻辑脚本 → code/sql/外呼情况/外呼记录表_tmp.sql
--
-- 【常用关联】
--   线索领取记录：info_uuid = aws.clue_info.info_uuid
--   组织架构层级：
--     workplace_id(职场) → department_id(学部) → regiment_id(团)
--     → heads_id(主管组) → team_id(小组) → worker_id(坐席)
--     架构对应的名称通过dw.dim_crm_organization.id去取对应的名称
-- 【统计口径】
--   注意：业务指标的权威定义在 glossary.md，本段仅记录"用本表怎么算"
--   外呼次数 = COUNT(action_id)
--   外呼线索量 = COUNT(DISTINCT user_id)
--   接通量 = COUNT(CASE WHEN is_connect = 1 THEN action_id END)
--   有效接通量 = COUNT(CASE WHEN is_valid_connect = 1 THEN action_id END)
--
-- 【常用筛选条件】
--   ★必加条件（使用底表时必加）：
--   - workplace_id IN (4, 400, 702)          -- 限定电销业务职场
--   - regiment_id NOT IN (0, 303, 546)       -- 排除无效/特殊团
--
--   场景条件：
--   - day 或 created_at 按统计区间过滤   -- 分区格式 yyyyMMdd
--
-- 【注意事项】
--   ⚠️ 是否接通统一用 is_connect 字段，不用 call_state / call_status
--   ⚠️ 有效接通阈值：通话时长 ≥ 10 秒（is_valid_connect = 1）
--   ⚠️ call_state / call_status 默认不使用。call_status 由 call_state 及其他字段派生，部分渠道有值部分没有。特殊需求明确要用时用 call_status
--   ⚠️ user_type_name 底表为原始值，与 tmp 口径不同。使用时应按 tmp 表逻辑清洗
-- =====================================================

CREATE EXTERNAL TABLE `dw`.`fact_call_history` (
  `info_uuid` string COMMENT '线索id',
  `action_id` string COMMENT '外呼记录唯一ID（主键），一次外呼一条',
  `call_sheet_id` string COMMENT '三方外呼系统唯一id',
  `channel_id` string COMMENT '呼叫渠道ID',
  `user_id` string COMMENT '用户id',
  `user_sk` int COMMENT '用户sk（数仓代理键）',
  `call_state` string COMMENT '外呼结果状态（原始），默认不用，判断接通用is_connect',
  `call_phone` string COMMENT '外呼号码，可能明文或base64，取数需解码',
  `called_phone` string COMMENT '被叫号码',
  `called_province` string COMMENT '被叫号码省份',
  `called_district` string COMMENT '被叫号码区县',
  `called_district_code` string COMMENT '被叫号码区县编码',
  `call_start_time` timestamp COMMENT '外呼开始时间',
  `call_end_time` timestamp COMMENT '外呼结束时间',
  `call_time_length` int COMMENT '呼叫时长（秒）',
  `record_file_url` string COMMENT '通话录音文件地址',
  `record_file_ip` string COMMENT '通话录音文件服务器ip',
  `exten` string COMMENT '销售工号',
  `worker_id` string COMMENT '销售/坐席id',
  `agent_name` string COMMENT '销售名称（底表快照）',
  `user_type` string COMMENT '用户类型（原始）',
  `user_type_name` string COMMENT '用户类型名称（原始）',
  `clue_stage` string COMMENT '线索学段',
  `hang_up_part` string COMMENT '挂断方',
  `is_connect` smallint COMMENT '是否接通 0否 1是',
  `is_valid_connect` smallint COMMENT '是否有效接通 0否 1是，口径：通话时长>=10秒',
  `department_id` string COMMENT '学部id',
  `regiment_id` string COMMENT '团id',
  `heads_id` string COMMENT '主管组id',
  `team_id` string COMMENT '小组id',
  `created_at` timestamp COMMENT '外呼创建/拨打时间',
  `updated_at` timestamp COMMENT '记录更新时间',
  `day` int COMMENT '分区字段，格式yyyyMMdd',
  `clue_created_at` timestamp COMMENT '线索领取时间，用于当日/当月领呼判断',
  `workplace_id` int COMMENT '销售职场id',
  `call_status` string COMMENT '呼叫状态（由call_state及其他字段派生，部分渠道无值），默认不用，特殊需求才用',
  `deal_times` int COMMENT '振铃时长（秒）；外呼异常时不计算，已接听时=call_start_time-created_at，其他状态=call_time_length-created_at'
) COMMENT '外呼记录底表：一次外呼一条。用底表需加workplace_id IN(4,400,702)、regiment_id NOT IN(0,303,546)；有效接通>=10s；call_state/call_status默认不用' ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dw.db/fact_call_history' TBLPROPERTIES (
  'alias' = '坐席呼叫表',
  'bucketing_version' = '2',
  'last_modified_by' = 'liuguanxiong',
  'last_modified_time' = '1727248622',
  'spark.sql.create.version' = '2.2 or prior',
  'spark.sql.sources.schema' = '{"type":"struct","fields":[{"name":"info_uuid","type":"string","nullable":true,"metadata":{"comment":"线索id"}},{"name":"action_id","type":"string","nullable":true,"metadata":{"comment":"唯一ID"}},{"name":"call_sheet_id","type":"string","nullable":true,"metadata":{"comment":"三方系统唯一id"}},{"name":"channel_id","type":"string","nullable":true,"metadata":{"comment":"呼叫渠道ID"}},{"name":"user_id","type":"string","nullable":true,"metadata":{"comment":"用户id"}},{"name":"user_sk","type":"integer","nullable":true,"metadata":{"comment":"用户sk"}},{"name":"call_state","type":"string","nullable":true,"metadata":{"comment":"外呼结果状态"}},{"name":"call_phone","type":"string","nullable":true,"metadata":{"comment":"外呼号码"}},{"name":"called_phone","type":"string","nullable":true,"metadata":{"comment":"被叫号码"}},{"name":"called_province","type":"string","nullable":true,"metadata":{"comment":"被叫号码省份"}},{"name":"called_district","type":"string","nullable":true,"metadata":{"comment":"被叫号码区县"}},{"name":"called_district_code","type":"string","nullable":true,"metadata":{"comment":"被叫号码区县编码"}},{"name":"call_start_time","type":"timestamp","nullable":true,"metadata":{"comment":"外呼开始时间"}},{"name":"call_end_time","type":"timestamp","nullable":true,"metadata":{"comment":"外呼结束时间"}},{"name":"call_time_length","type":"integer","nullable":true,"metadata":{"comment":"呼叫时长"}},{"name":"record_file_url","type":"string","nullable":true,"metadata":{"comment":"通话录音文件地址"}},{"name":"record_file_ip","type":"string","nullable":true,"metadata":{"comment":"通话录音文件服务器ip"}},{"name":"exten","type":"string","nullable":true,"metadata":{"comment":"销售工号"}},{"name":"worker_id","type":"string","nullable":true,"metadata":{"comment":"销售id"}},{"name":"agent_name","type":"string","nullable":true,"metadata":{"comment":"销售名称"}},{"name":"user_type","type":"string","nullable":true,"metadata":{"comment":"用户类型"}},{"name":"user_type_name","type":"string","nullable":true,"metadata":{"comment":"用户类型"}},{"name":"clue_stage","type":"string","nullable":true,"metadata":{"comment":"线索学段"}},{"name":"hang_up_part","type":"string","nullable":true,"metadata":{"comment":"挂断方"}},{"name":"is_connect","type":"short","nullable":true,"metadata":{"comment":"是否接通"}},{"name":"is_valid_connect","type":"short","nullable":true,"metadata":{"comment":"是否有效接通"}},{"name":"department_id","type":"string","nullable":true,"metadata":{"comment":"学部id"}},{"name":"regiment_id","type":"string","nullable":true,"metadata":{"comment":"团id"}},{"name":"heads_id","type":"string","nullable":true,"metadata":{"comment":"主管组id"}},{"name":"team_id","type":"string","nullable":true,"metadata":{"comment":"小组id"}},{"name":"created_at","type":"timestamp","nullable":true,"metadata":{"comment":"创建时间"}},{"name":"updated_at","type":"timestamp","nullable":true,"metadata":{"comment":"更新时间"}},{"name":"day","type":"integer","nullable":true,"metadata":{}},{"name":"clue_created_at","type":"timestamp","nullable":true,"metadata":{"comment":"线索领取时间"}}]}',
  'transient_lastDdlTime' = '1773769997'
)

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## call_state（拨打状态）
--
-- > ⚠️ 默认不使用。判断是否接通统一用 is_connect 字段。
-- > 特殊需求明确要用时，用 call_status（由 call_state 派生），不用 call_state。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | dealing | 已接通 |
-- | notDeal | 未接通 |
-- | abnormal | 异常 |
-- | blackList | 黑名单 |
-- | leak | IVR放弃 |
--
-- ## call_status（呼叫状态，由 call_state 及其他字段派生，默认不用）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 外呼异常 | 外呼异常 |
-- | 坐席放弃 | 坐席主动放弃 |
-- | 用户挂断 | 用户挂断 |
-- | 未接通 | 未接通 |
-- | 已接听 | 已接听 |
--
-- ## channel_id（外呼渠道）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 1 | 七陌 |
-- | 2 | 天眼 |
-- | 34 | 蘑谷云 |
-- | 38 | 百川 |
-- | 39 | 百悟 |
-- | 101 | 智鱼 |
-- | 102 | 天田 |

