-- =====================================================
-- 点击归因少回传表 thirdparty.register_callback_record
-- =====================================================
--
-- 【表粒度】
--   一个注册用户一条记录（`traffic_id` 唯一幂等键，对应 `thirdparty.traffic.id`）；非分区表；T+1。
--
-- 【业务背景】
--   4.8 上线「少回传」业务：运营在后台按渠道（`channel`）配置回传比例；用户请求注册接口时向本表写入一条记录。
--   `callback_ratio` 是运营配置的渠道回传比例（如 50 表示 50% 概率回传）。
--
--   ⚠️ 历史遗留问题：少量注册走旧接口未能写入本表（量级约 40 条/天，正在修复中）；
--   这些用户不在本表，但已正常回传给媒体，统计时需注意。
--
-- 【使用场景】
--   - 统计少回传前/后的注册用户数（区分「命中回传 sample_hit=1」与「未命中 sample_hit=0」）
--   - 核查各渠道的实际回传比例与配置一致性
--   - 与 `thirdparty.traffic` 通过 `traffic_id = id` 关联，拼接渠道/来源/注册时间等上游字段
--
-- 【统计口径】（少回传前中后用户数拆分）
--
-- > 注意：原始业务 SQL 中主表为 `thirdparty.traffic`，关联本表；`sample_hit IS NULL` 情况对应「走旧接口未写入本表」的用户（正常回传）。
--
-- ```sql
-- SELECT  a.regist_date
--       , a.source
--       , a.channel
--       , COUNT(DISTINCT a.userid)                                                              AS `少回传前用户数`
--       , COUNT(DISTINCT CASE WHEN b.sample_hit = 0 THEN a.userid END)                          AS `少回传用户数`
--       , COUNT(DISTINCT CASE WHEN (b.sample_hit IS NULL OR b.sample_hit = 1) THEN a.userid END) AS `少回传后用户数（回传）`
-- FROM (
--     SELECT id, userid, source, channel, date(registertime) AS regist_date
--     FROM thirdparty.traffic
--     WHERE date(registertime) BETWEEN date '${day1}' AND date '${day2}'
--       AND status >= 2   -- 已注册
-- ) a
-- LEFT JOIN thirdparty.register_callback_record b ON a.id = b.traffic_id
-- GROUP BY a.regist_date, a.source, a.channel
-- ```
--
-- 【常用关联】
--   - `thirdparty.traffic`：`register_callback_record.traffic_id = traffic.id`（取注册时间、渠道等上游字段）
--
-- 【常用筛选条件】
--   场景条件：
--   - 仅看命中（实际回传）：`sample_hit = 1`
--   - 仅看未命中（压制回传）：`sample_hit = 0`
--   - 注意 `sample_hit IS NULL` 为走旧接口的用户（已正常回传，约 40 条/天）
--
-- 【注意事项】
--   ⚠️ 非分区明细表；Text 存储；T+1。
--   ⚠️ 旧接口注册的用户不在本表，但已正常回传，统计「少回传后」用户时 IS NULL 应归入「回传」口径。
--
-- =====================================================

CREATE TABLE thirdparty.register_callback_record (
    id STRING COMMENT '主键ID',
    traffic_id BIGINT COMMENT '注册归因的 traffic 记录ID（关联 thirdparty.traffic.id，唯一幂等键）',
    user_id STRING COMMENT '注册用户ID',
    channel STRING COMMENT '最终归因的 traffic.channel',
    source STRING COMMENT '最终归因的 traffic.source',
    callback_ratio INT COMMENT '命中的回传比例，未命中配置时默认为100',
    sample_value INT COMMENT '抽样值，未抽样时为0',
    sample_hit SMALLINT COMMENT '抽样是否命中 0未命中(不回传) 1命中(回传)',
    decision_reason STRING COMMENT '判定原因',
    callback_status SMALLINT COMMENT '回传状态 0待回传 1已跳过 2回传成功 3回传失败',
    callback_error STRING COMMENT '回传失败错误信息',
    callback_request STRING COMMENT '回传请求快照',
    callback_response STRING COMMENT '回传响应快照',
    callback_at TIMESTAMP COMMENT '首次回传时间',
    created_at TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP COMMENT '更新时间'
) USING text
TBLPROPERTIES (
    'bucketing_version' = '2',
    'transient_lastDdlTime' = '1775673889'
);

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## sample_hit（抽样是否命中）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 1 | 命中，正常回传给媒体 |
-- | 0 | 未命中，压制不回传 |
-- | NULL | 走旧接口注册，未写入本表（已正常回传，每日约 40 条，修复中） |
--
-- ## callback_status（回传状态）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 待回传 |
-- | 1 | 已跳过（sample_hit=0，不需回传） |
-- | 2 | 回传成功 |
-- | 3 | 回传失败（callback_error 记录原因） |
