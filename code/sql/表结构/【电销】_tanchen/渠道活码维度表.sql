-- =====================================================
-- 渠道活码维度表 crm.qr_code_change_history
-- =====================================================
--
-- 【表粒度】★必填
--   渠道活码每次变更 = 一条记录（变更历史）；同一 qr_code_id 可有多条
--   无分区字段，全量表；分析渠道属性时通常按活码取「最新一条」有效记录
--
-- 【业务定位】
--   企微侧渠道活码核心维度表。涉及 qr_code_id 的渠道信息（场景名、等级、资源位等）应通过本表解析；
--   渠道信息变更会新增一行，业务上以最新有效记录为准。
--   漏斗维度层级（从粗到细）：
--     资源位入口等级 clue_level_id → clue_level_name
--       └─ 场景名称 resource_entrance_id → resource_entrance_name
--            └─ 场景名称细分(渠道活码名称) qr_code_id → scene_name

--
-- 【常用关联】
--   企微漏斗：task_id = qr_code_id
--   企微线索 aws.clue_info：qr_code_channel_id = qr_code_id
--
-- 【常用筛选条件】
--   ★必加条件（按活码取当前有效维度时）：
--   - deleted_at IS NULL           -- 排除软删
--   - type_name <> '测试类型'      -- 排除测试类型（与业务确认口径一致时使用）
--   取最新有效记录示例,按qr_code_id分组：
--   SELECT *
--   FROM (
--     SELECT *, ROW_NUMBER() OVER (PARTITION BY qr_code_id ORDER BY effective_time DESC) rn
--     FROM crm.qr_code_change_history
--     WHERE deleted_at IS NULL
--       AND type_name <> '测试类型'
--   ) t
--   WHERE rn = 1
--   场景条件：
--   - status = 1  -- 仅上线活码；status = 2 为下线，按需选用

-- =====================================================

CREATE TABLE
  `crm`.`qr_code_change_history` (
    `id` bigint COMMENT '主键ID',
    `created_at` timestamp COMMENT '记录创建时间（本条变更记录的写入时间）',
    `updated_at` timestamp COMMENT '记录更新时间',
    `deleted_at` timestamp COMMENT '软删除时间，NULL表示未删除，查询时需过滤 deleted_at IS NULL',
    `qr_code_id` bigint COMMENT '渠道活码ID，核心关联字段，关联企微漏斗表的 task_id 或线索表的 qr_code_channel_id',
    `resource_entrance_id` bigint COMMENT '资源位入口ID',
    `resource_entrance_name` string COMMENT '资源位入口名称',
    `clue_level_id` bigint COMMENT '线索等级ID',
    `clue_level_name` string COMMENT '线索等级名称（渠道的等级分类，核心筛选/分组字段）',
    `scene_name` string COMMENT '场景名称（渠道活码ID对应的名字）',
    `status` bigint COMMENT '状态：1=上线，2=下线',
    `type` bigint COMMENT '类型ID',
    `type_name` string COMMENT '类型名称',
    `effective_time` timestamp COMMENT '本条记录生效时间，取最新有效记录时按此字段 DESC 排序',
    `invalid_time` timestamp COMMENT '本条记录失效时间，默认 2099-01-01 表示当前仍生效',
    `operator_id` bigint COMMENT '操作人ID',
    `qr_code_created_at` timestamp COMMENT '渠道活码首次创建时间（非本条记录创建时间，是活码本身的创建时间）'
  ) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/crm.db/qr_code_change_history' TBLPROPERTIES (
    'STATS_GENERATED_VIA_STATS_TASK' = 'true',
    'bucketing_version' = '2',
    'creation_platform' = 'coral',
    'is_core' = 'false',
    'is_starred' = 'false',
    'status' = '3',
    'transient_lastDdlTime' = '1769755215'
  )

-- =====================================================
-- 枚举值
-- =====================================================
-- ## status（活码上下线状态）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 1 | 上线 |
-- | 2 | 下线 |
--
-- ## type_name（类型名称）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 阿拉丁 | |
-- | 电销私域 | |
-- | AI机器人 | |
-- | 研学 | |
-- | 测试类型 | 测试数据，分析时需排除 |
