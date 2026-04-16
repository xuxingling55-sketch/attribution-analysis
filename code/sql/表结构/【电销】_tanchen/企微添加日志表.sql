-- =====================================================
-- 企微添加日志表 crm.contact_log
-- =====================================================
-- 【表粒度】★必填
--   每次企微添加删除变更事件生成一条记录（添加/删除等），无分区字段，全量表
--
-- 【业务定位】
--   企微业务的核心事实表，记录用户与坐席之间的企微添加删除变更事件
--   常规企微业务指标（企微添加量、拉取入库量）均以本表为基础计算
--   → glossary.md #常规企微业务指标
--
-- 【常用筛选条件】
--   ★必加条件（企微添加场景）：
--   - source = 3                                  -- 渠道活码
--   - change_type = 'add_external_contact'        -- 添加外部联系人
--   - group_id0 IN (4, 400, 702)                  -- 限定电销职场(如果非电销的需要单独强调一下)
--   - length(yc_user_id) = 24 
--   - yc_user_id <> '000000000000000000000001'  -- 排除无效洋葱ID
--
-- 【常用关联】
--   渠道维度：channel_id = crm.qr_code_change_history.qr_code_id
--   拉取入库：external_user_id = aws.clue_info.we_com_open_id AND worker_id = aws.clue_info.worker_id
--   组织架构：group_id1~group_id4 分别关联 dw.dim_crm_organization 获取 department/regiment/heads/team 名称
--   坐席信息：worker_id = crm.worker.id
--
-- 【去重逻辑】
--   企微添加去重（取首次添加）：
--   - 不分组织架构：PARTITION BY (external_user_id, worker_id, channel_id, yc_user_id) ORDER BY created_at
--   - 分组织架构：PARTITION BY (external_user_id, worker_id, channel_id) ORDER BY created_at
--
-- 【is_repeated_exposure 说明】
--   2025-07-26 起有值，之前的历史数据无法区分是否重复曝光坐席的渠道活码
-- =====================================================

CREATE TABLE `crm.contact_log`(
  `id` bigint COMMENT '主键',
  `created_at` timestamp COMMENT '事件发生时间，企微添加指标按此字段统计日期',
  `updated_at` timestamp COMMENT '最近一次更新时间',
  `event` string COMMENT '触发事件',
  `change_type` string COMMENT '变更类型',
  `userid` string COMMENT '坐席企微userid（企微体系内的ID）',
  `external_user_id` string COMMENT '用户企微userid',
  `worker_id` bigint COMMENT '坐席ID',
  `channel_id` bigint COMMENT '渠道活码ID',
  `source` bigint COMMENT '来源：-1=未知, 0=海报, 1=短信, 3=渠道活码',
  `topic_id` bigint,
  `rule_template_id` bigint COMMENT '渠道活码规则ID',
  `account_id` bigint COMMENT '企业微信账号id',
  `yc_user_id` string COMMENT '洋葱用户id',
  `add_way` bigint COMMENT '客户来源',
  `group_id1` bigint COMMENT '学部ID',
  `group_id2` bigint COMMENT '团ID',
  `group_id3` bigint COMMENT '主管组ID',
  `group_id4` bigint COMMENT '小组ID',
  `group_id0` bigint COMMENT '职场ID',
  `is_repeated_exposure` boolean COMMENT '是否多次曝光，true=是 false=否')
ROW FORMAT SERDE
  'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES (
  'field.delim'='',
  'serialization.format'='')
STORED AS INPUTFORMAT
  'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION
  'tos://yc-data-platform/user/hive/warehouse/crm.db/contact_log'
TBLPROPERTIES (
  'STATS_GENERATED_VIA_STATS_TASK'='true',
  'bucketing_version'='2',
  'transient_lastDdlTime'='1739204879')

-- =====================================================
-- 枚举值
-- =====================================================
-- ## change_type（变更类型）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | add_external_contact | 添加联系人 |
-- | del_external_contact | 删除联系人 |
-- | del_follow_user |  |

-- ## source（来源）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | -1 | 未知 |
-- | 0 | 海报 |
-- | 1 | 短信 |
-- | 3 | 渠道活码 |
