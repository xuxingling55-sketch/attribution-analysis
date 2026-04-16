-- =====================================================
-- 体验营投放渠道维表 training_camp.tm_channel
-- =====================================================
--
-- 【表粒度】
--   一个体验营投放渠道一条记录；维表。
--
-- 【使用场景】
--   - 配置体验营投放渠道时的主数据
--   - 与线索表 `channel` 对齐后，查看 `channel_name`、`channel_type`、`channel_grade`（渠道级别）
--
-- 【常用关联】
--   - `training_camp.tm_extra` / `dw.dim_user_training_camp`：`tm_channel.channel = 线索表.channel`
--
-- 【常用筛选条件】
--   - 按渠道编码：`channel IN (...)` 或等值匹配
--
-- 【注意事项】
--   ⚠️ 非分区明细表；Text 存储；更新频率 T+1。
--   ⚠️ `channel_grade` 枚举会随业务扩展，以下档为当前已知范围。
--
-- =====================================================

CREATE TABLE training_camp.tm_channel (
    id BIGINT COMMENT '主键ID',
    channel STRING COMMENT '渠道（与线索表 channel 一致）',
    channel_name STRING COMMENT '渠道名称',
    channel_type STRING COMMENT '渠道类别',
    channel_grade STRING COMMENT '渠道级别',
    con_str BIGINT COMMENT '起始转换率',
    con_end BIGINT COMMENT '终止转换率',
    doc STRING COMMENT '备注',
    created_at TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP COMMENT '更新时间',
    deleted_at TIMESTAMP COMMENT '删除时间',
    non_service_undertaker_qw_user_ids STRING COMMENT '非服承接人员qw_user_id列表(JSON数组)'
) USING text
TBLPROPERTIES (
    'STATS_GENERATED_VIA_STATS_TASK' = 'true',
    'bucketing_version' = '2',
    'transient_lastDdlTime' = '1750008443'
);

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## channel_grade（渠道级别）
--
-- > 当前维护到 `i`，后续可能继续扩充新档位。
--
-- | 枚举值 | 说明 |
-- |--------|------|
-- | a | 级别档 a |
-- | b | 级别档 b |
-- | c | 级别档 c |
-- | d | 级别档 d |
-- | e | 级别档 e |
-- | f | 级别档 f |
-- | g | 级别档 g |
-- | h | 级别档 h |
-- | i | 级别档 i（截至文档编写时最后一档） |
