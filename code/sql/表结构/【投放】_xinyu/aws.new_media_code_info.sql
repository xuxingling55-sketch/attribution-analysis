-- =====================================================
-- 新媒体口令/兑换码主数据表 aws.new_media_code_info
-- =====================================================
--
-- 【表粒度】
--   一个口令/兑换码一条记录；非分区表；T+1。
--
-- 【业务背景】
--   新媒体在站外平台（直播/视频/账号等）以发放口令/兑换码的方式引流用户到站内注册。
--   若用户激活口令/兑换兑换码的时间发生在**注册后 24 小时内**，则归为「新媒体口令」带来的用户。
--   本表存放所有新媒体已发放/维护的口令与兑换码的基本信息（口令主数据）。
--
-- 【使用场景】
--   - 查询口令/兑换码的归属项目（`project_name`）、类型（`code_type`）、分组（`group_name`）等元信息
--   - 与激活明细表 `aws.new_media_new_user_code_detail_day` 通过 `code` 关联
--
-- 【核心字段】
--   `code_type`、`code`（口令/兑换码）、`group_name`
--
-- 【常用关联】
--   - `aws.new_media_new_user_code_detail_day`：`batch_id` 或 `code` 与本表 `code` 关联，取 `code_type`、`project_name` 等元信息
--
-- 【注意事项】
--   ⚠️ ORC 存储；非分区表；T+1。
--   ⚠️ `group_name` 字段无 COMMENT，含义为口令所属分组（业务自定义）。
--
-- =====================================================

CREATE TABLE aws.new_media_code_info (
    add_code_month STRING COMMENT '兑换码入库时间（月份格式）',
    code_type STRING COMMENT '兑换码类型',
    code STRING COMMENT '口令/兑换码',
    password_name STRING COMMENT '口令名称',
    project_name STRING COMMENT '项目名称',
    is_valid BOOLEAN COMMENT '是否生效',
    add_code_time INT COMMENT '兑换码添加时间',
    group_name STRING COMMENT '口令所属分组'
) USING orc
LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/new_media_code_info'
TBLPROPERTIES (
    'alias' = 'null',
    'bucketing_version' = '2',
    'discover.partitions' = 'true',
    'transient_lastDdlTime' = '1775466236'
);
