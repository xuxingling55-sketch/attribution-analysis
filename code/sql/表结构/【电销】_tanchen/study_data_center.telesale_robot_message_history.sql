-- =====================================================
-- 企微AI机器人消息记录表 study_data_center.telesale_robot_message_history
-- =====================================================
--
-- 【表粒度】★必填
--   一条消息 = 一条记录（id 唯一）
--   分区字段：day（int 类型，格式 yyyyMMdd，对应 created_at）
--
-- 【业务定位】
--   企微AI机器人与用户的消息交互明细表，记录AI触达、用户回复、人工消息等全部会话内容。
--   私域1.0项目核心数据源，用于计算 AI首触覆盖量、用户开口量、互动消息条数等指标。
--
-- 【统计口径】
--   注意：业务指标的权威定义在 glossary.md，本段仅记录"用本表怎么算"
--   AI首触判断：is_ai_message = true，按 (external_user_id, worker_id, send_date) 去重取首条
--   用户开口量：sender_type = 'external' 的消息数 >= 3 则算开口
--   用户发消息条数：COUNT(DISTINCT CASE WHEN sender_type = 'external' THEN message_id END)
--   AI用户互动消息条数：COUNT(DISTINCT CASE WHEN sender_type = 'external' OR is_ai_message = true THEN message_id END)
--
-- 【常用筛选条件】
--   ★必加条件：
--   无
--
--   场景条件：
--   - day BETWEEN '20260209' AND date_format(date_sub(current_date,1), 'yyyyMMdd')  -- 2026-02-09 上线
--
-- 【常用关联】
--   企微添加日志：regexp_extract(coze_user_id, ':(.*)$', 1) = crm.contact_log.external_user_id
--   坐席信息：CAST(worker_id AS BIGINT) = crm.contact_log.worker_id
--     ⚠️ 本表 worker_id 为 string，关联 contact_log 时需 CAST 为 BIGINT
--
-- 【注意事项】
--   ⚠️ 本表无 external_user_id 字段，需从 coze_user_id 提取：
--     regexp_extract(coze_user_id, ':(.*)$', 1) AS external_user_id
--   ⚠️ send_time 格式需处理：concat(substr(send_time, 1, 10), ' ', substr(send_time, 12, 8))
--   ⚠️ raw_content 为 JSON，解析方式：
--     消息回调类型：get_json_object(raw_content, '$.type')  -- 11041文本/11042图片/11043视频/11044语音
--     消息内容类型：get_json_object(raw_content, '$.data.content.contentType')  -- TEXT/IMAGE/VOICE/VIDEO/FILE
--     文本内容：get_json_object(raw_content, '$.data.content.content')（contentType=TEXT 时）
-- =====================================================

CREATE TABLE
  `study_data_center`.`telesale_robot_message_history` (
    `ai_request_id` string COMMENT 'AI请求ID',
    `badge` string COMMENT '消息标识：0=人工消息，1=AI消息，2=触发器消息',
    `channel_id` string COMMENT '渠道ID',
    `corp_id_str` string COMMENT '企业ID字符串',
    `coze_user_id` string COMMENT '企业ID:企微用户ID，提取 external_user_id 用 regexp_extract(coze_user_id, ":(.*)$", 1)',
    `created_at` string COMMENT '创建时间',
    `id` string COMMENT '消息记录ID（主键）',
    `is_ai_message` string COMMENT '是否AI消息：true/false',
    `media_url` string COMMENT '媒体文件URL',
    `message_id` string COMMENT '消息ID，用于消息级别去重和计数',
    `raw_content` string COMMENT '原始消息JSON，需用 get_json_object 解析',
    `send_time` string COMMENT '发送时间，格式需处理：concat(substr(send_time,1,10)," ",substr(send_time,12,8))',
    `sender_type` string COMMENT '发送者类型：internal=内部销售，external=外部客户',
    `trace_id` string COMMENT '链路追踪ID',
    `user_id` string COMMENT '用户ID',
    `voice_text` string COMMENT '语音转文字内容',
    `worker_acc_id` string COMMENT '坐席企微账号ID',
    `worker_id` string COMMENT '坐席ID（string类型，关联 contact_log 时需 CAST 为 BIGINT）',
    `worker_user_id` string COMMENT '坐席用户ID'
  ) PARTITIONED BY (`day` int) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/study_data_center.db/telesale_robot_message_history' TBLPROPERTIES (
    'spark.sql.create.version' = '3.3.3',
    'spark.sql.sources.schema' = '{"type":"struct","fields":[{"name":"ai_request_id","type":"string","nullable":true,"metadata":{"comment":"AI请求ID"}},{"name":"badge","type":"string","nullable":true,"metadata":{"comment":"徽章标识"}},{"name":"channel_id","type":"string","nullable":true,"metadata":{"comment":"渠道ID"}},{"name":"corp_id_str","type":"string","nullable":true,"metadata":{"comment":"企业ID字符串"}},{"name":"coze_user_id","type":"string","nullable":true,"metadata":{"comment":"Coze用户ID"}},{"name":"created_at","type":"string","nullable":true,"metadata":{"comment":"创建时间"}},{"name":"id","type":"string","nullable":true,"metadata":{"comment":"消息记录ID"}},{"name":"is_ai_message","type":"string","nullable":true,"metadata":{"comment":"是否AI消息"}},{"name":"media_url","type":"string","nullable":true,"metadata":{"comment":"媒体文件URL"}},{"name":"message_id","type":"string","nullable":true,"metadata":{"comment":"消息ID"}},{"name":"raw_content","type":"string","nullable":true,"metadata":{"comment":"原始消息内容"}},{"name":"send_time","type":"string","nullable":true,"metadata":{"comment":"发送时间"}},{"name":"sender_type","type":"string","nullable":true,"metadata":{"comment":"发送者类型"}},{"name":"trace_id","type":"string","nullable":true,"metadata":{"comment":"链路追踪ID"}},{"name":"user_id","type":"string","nullable":true,"metadata":{"comment":"用户ID"}},{"name":"voice_text","type":"string","nullable":true,"metadata":{"comment":"语音转文字内容"}},{"name":"worker_acc_id","type":"string","nullable":true,"metadata":{"comment":"坐席账号ID"}},{"name":"worker_id","type":"string","nullable":true,"metadata":{"comment":"坐席ID"}},{"name":"worker_user_id","type":"string","nullable":true,"metadata":{"comment":"坐席用户ID"}},{"name":"day","type":"integer","nullable":true,"metadata":{}}]}',
    'spark.sql.sources.schema.numPartCols' = '1',
    'spark.sql.sources.schema.partCol.0' = 'day',
    'transient_lastDdlTime' = '1776062538'
  )

-- =====================================================
-- 枚举值
-- =====================================================
-- ## badge（消息标识）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 人工消息 |
-- | 1 | AI消息 |
-- | 2 | 触发器消息（ai_request_id、coze_user_id 为空） |
--
-- ## sender_type（发送者类型）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | internal | 内部销售 |
-- | external | 外部客户 |
--
-- ## raw_content 解析 - type（消息回调类型）
-- > 提取方式：get_json_object(raw_content, '$.type')
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 11041 | 文本 |
-- | 11042 | 图片 |
-- | 11043 | 视频 |
-- | 11044 | 语音 |
--
-- ## raw_content 解析 - contentType（消息内容类型）
-- > 提取方式：get_json_object(raw_content, '$.data.content.contentType')
-- | 枚举值 | 含义 |
-- |--------|------|
-- | TEXT | 文本，内容取 $.data.content.content |
-- | IMAGE | 图片，内容取 $.data.content.fileInfo.fileId |
-- | VOICE | 语音，内容取 $.data.content.fileId |
-- | VIDEO | 视频，内容取 $.data.content.fileId |
-- | FILE | 文件，内容取 $.data.content.fileName |
