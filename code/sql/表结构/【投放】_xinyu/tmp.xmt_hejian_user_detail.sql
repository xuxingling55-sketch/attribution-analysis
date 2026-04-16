-- =====================================================
-- 核减后的新媒体口令激活表 tmp.xmt_hejian_user_detail
-- =====================================================
--
-- 【表粒度】
--   一个口令 × 一个用户一条记录；非分区表；T+1。
--
-- 【业务背景】
--   新媒体口令激活用户的**投放部门结算口径**来源表。
--   在 `aws.new_media_new_user_code_detail_day` 原始激活明细的基础上，按以下三条规则核减：
--   1. **同一设备重复注册**的用户（`device_user_nums > 2`）
--   2. 激活新媒体口令**前**已激活裂变口令的用户（`is_fission_first = 1`）
--   3. 通过**投放点击归因渠道**注册的用户（`is_link_deliver = 1`）
--
-- 【使用场景】
--   - 新媒体口令拉新量（结算/日报口径），需加三个核减筛选条件
--   - 判断某用户是否属于「纯新媒体口令」带来的新用户
--
-- 【核心字段】
--   `u_user`、`redeem_date`、`is_fission_first`、`is_link_deliver`、`device_user_nums`
--
-- 【统计口径】（核减后新媒体口令拉新量）
--
-- ```sql
-- SELECT COUNT(DISTINCT u_user) AS `新媒体口令拉新量`
-- FROM tmp.xmt_hejian_user_detail
-- WHERE device_user_nums <= 2   -- 排除同一设备重复注册
--   AND is_fission_first = 0    -- 排除先激活裂变口令的用户
--   AND is_link_deliver = 0     -- 排除投放点击归因用户
--   AND redeem_date BETWEEN date '${day1}' AND date '${day2}'
-- ```
--
-- 【常用筛选条件】
--   ★结算必加（三个条件同时加）：
--   - `device_user_nums <= 2`
--   - `is_fission_first = 0`
--   - `is_link_deliver = 0`
--
--   场景条件：
--   - 限日期：`redeem_date BETWEEN date '${day1}' AND date '${day2}'`
--
-- 【常用关联】
--   - `aws.new_media_new_user_code_detail_day`：`u_user` 关联，取兑换码批次、项目名等原始明细
--
-- 【注意事项】
--   ⚠️ Text 存储；非分区表；T+1。
--   ⚠️ 本表是结算口径来源，**不带三个核减条件的数据量 > 结算量**，汇报时需加齐条件。
--   ⚠️ `redeem_date` 为 DATE 类型，日期比较时使用 `date '${day}'` 或等价写法。
--
-- =====================================================

CREATE TABLE tmp.xmt_hejian_user_detail (
    redeem_month STRING COMMENT '兑换月份（yyyyMM）',
    channel STRING COMMENT '注册渠道',
    u_user STRING COMMENT '用户ID',
    redeem_date DATE COMMENT '兑换日期',
    device_user_nums BIGINT NOT NULL COMMENT '注册时的设备绑定用户数（> 2 则为同一设备重复注册，需核减）',
    is_fission_first INT NOT NULL COMMENT '是否先激活了裂变口令 0否 1是（1需核减）',
    is_link_deliver INT NOT NULL COMMENT '是否投放渠道点击归因用户 0否 1是（1需核减）'
) USING text
TBLPROPERTIES (
    'bucketing_version' = '2',
    'last_modified_by' = 'liuguanxiong',
    'last_modified_time' = '1727329993',
    'transient_lastDdlTime' = '1727329993'
);

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## is_fission_first（是否先激活裂变口令）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 否（先激活了新媒体口令，保留） |
-- | 1 | 是（先激活了裂变口令，结算口径需核减） |
--
-- ## is_link_deliver（是否投放归因用户）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 否（非投放渠道点击归因，保留） |
-- | 1 | 是（投放点击归因注册，结算口径需核减） |
