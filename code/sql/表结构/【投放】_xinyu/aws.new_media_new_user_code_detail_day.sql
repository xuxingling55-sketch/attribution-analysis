-- =====================================================
-- 新媒体口令激活明细表 aws.new_media_new_user_code_detail_day
-- =====================================================
--
-- 【表粒度】
--   一个口令 × 一个用户一条记录；`day` 分区表（分区字段为 INT）；T+1。
--
-- 【业务背景】
--   新媒体在站外平台（直播/视频/账号等）以发放口令/兑换码的方式引流用户到站内注册。
--   若用户激活口令/兑换兑换码的时间发生在**注册后 24 小时内**，则归为「新媒体口令」带来的用户。
--   本表保存满足「注册 24h 内激活/兑换了新媒体口令/兑换码的用户」，并**仅保留首次激活/兑换记录**。
--
-- 【业务定位】
--   本表为未核减版本，包含所有激活了新媒体口令的新用户；
--   计算「新媒体口令拉新量」结算口径时需进一步核减，核减结果见 `tmp.xmt_hejian_user_detail`（核减逻辑见该表文档）。
--
-- 【使用场景】
--   - 查看新媒体口令激活的原始用户明细（未核减）
--   - 与口令主数据表 `aws.new_media_code_info` 通过 `batch_id` 或 `code` 关联取口令类型/项目名
--
-- 【核心字段】
--   `redeem_time`、`batch_id`、`u_user`、`project_name`
--
-- 【统计口径】（查询激活明细）
--
-- ```sql
-- SELECT *
-- FROM aws.new_media_new_user_code_detail_day
-- WHERE redeem_month >= '202301'
-- ```
--
-- 【常用筛选条件】
--   场景条件：
--   - 按兑换月份：`redeem_month >= 'yyyyMM'`
--   - 按分区：`day >= ${yyyyMMdd}`（分区为 INT）
--   - 按项目：`project_name = '${project}'`
--
-- 【常用关联】
--   - `aws.new_media_code_info`：`batch_id` 或 `code` 与 `new_media_code_info.code` 关联，取 `code_type`、`group_name` 等
--   - `tmp.xmt_hejian_user_detail`：`u_user` 关联，查看核减后状态（`is_fission_first`、`is_link_deliver`、`device_user_nums`）
--
-- 【注意事项】
--   ⚠️ ORC 分区表；`PARTITIONED BY (day)`，`day` 为 INT 格式（如 20260101）；T+1。
--   ⚠️ 本表每个用户**仅保留首次激活口令记录**，不含重复激活。
--   ⚠️ 结算口径（核减后）需用 `tmp.xmt_hejian_user_detail`，详见该表文档。
--
-- =====================================================

CREATE TABLE aws.new_media_new_user_code_detail_day (
    redeem_date STRING COMMENT '兑换日期（yyyyMMdd 字符串）',
    redeem_month STRING COMMENT '兑换月份（yyyyMM）',
    redeem_time TIMESTAMP COMMENT '兑换时间',
    u_user STRING COMMENT '用户ID',
    batch_id STRING COMMENT '兑换码批次',
    add_code_month STRING COMMENT '兑换码入库月份',
    channel STRING COMMENT '注册渠道',
    project_name STRING COMMENT '口令所属项目名称',
    u_from STRING COMMENT '系统平台',
    day INT COMMENT '分区字段（yyyyMMdd，INT格式）'
) USING orc
PARTITIONED BY (day)
COMMENT '一个用户一条记录'
LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/new_media_new_user_code_detail_day'
TBLPROPERTIES (
    'alias' = '新媒体新用户兑换码统计表',
    'bucketing_version' = '2',
    'discover.partitions' = 'true',
    'last_modified_by' = 'master',
    'last_modified_time' = '1765282269',
    'transient_lastDdlTime' = '1765282269'
);
