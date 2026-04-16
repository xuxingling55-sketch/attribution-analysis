-- =====================================================
-- 体验营期数配置表 training_camp.tm_number
-- =====================================================
--
-- 【表粒度】
--   一个期数一条记录；维表；业务上每期一行，可直接按 `periods` 关联取 `str_at` / `end_at` / `operate_at`。
--
-- 【使用场景】
--   - `str_at`：期数起始时间（开营）
--   - `end_at`：期数结束时间（本期停止投放等口径）
--   - `operate_at`：经营时间，即**结营时间**（超过后销售一般不再对本期做主动转化）
--
-- 【核心字段】
--   `periods`, `str_at`, `end_at`, `operate_at`
--
-- 【统计口径】（期数时间窗）
--
-- ```sql
-- SELECT periods, str_at, end_at, operate_at
-- FROM training_camp.tm_number
-- ```
--
-- 【常用关联】
--   - `training_camp.tm_extra` / `dw.dim_user_training_camp`：`trim(cast(periods as string))` 与线索侧 `periods` 对齐（注意类型一致）
--
-- 【常用筛选条件】
--   - 指定期次：`cast(periods as bigint) IN (...)` 或 `periods IN ('166','167')`（按实际类型）
--   - 有效数据：`deleted_at IS NULL`（若分析需要排除逻辑删除）
--
-- 【注意事项】
--   ⚠️ 非分区明细表；Text 存储；更新频率 T+1。
--   ⚠️ 若出现异常多行同一 `periods`，需 `GROUP BY periods` 并与业务确认聚合方式（如 `max(operate_at)`）。
--
-- =====================================================

CREATE TABLE training_camp.tm_number (
    id BIGINT COMMENT '主键ID',
    doc STRING COMMENT '备注信息',
    str_at TIMESTAMP COMMENT '期数起始时间',
    end_at TIMESTAMP COMMENT '期数结束时间（本期停止投放等）',
    periods STRING COMMENT '期数',
    created_at TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP COMMENT '更新时间',
    deleted_at TIMESTAMP COMMENT '删除时间',
    expects BIGINT COMMENT '预期数量',
    operate_at TIMESTAMP COMMENT '经营时间（结营时间）',
    clue_config STRING COMMENT '线索配置',
    new_clue_config STRING COMMENT '新版线索配置',
    open_type BIGINT COMMENT '开课方式 1手动 2定时开课',
    track_plan_range STRING COMMENT '定时开课范围',
    track_plan_time TIMESTAMP COMMENT '定时开课时间'
) USING text
TBLPROPERTIES (
    'STATS_GENERATED_VIA_STATS_TASK' = 'true',
    'bucketing_version' = '2',
    'transient_lastDdlTime' = '1743611276'
);

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## open_type
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 1 | 手动开课 |
-- | 2 | 定时开课 |
