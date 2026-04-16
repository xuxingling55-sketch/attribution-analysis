-- =====================================================
-- 二维码曝光添加表 crm.new_user
-- =====================================================
-- 【表粒度】★必填
--   当channel=3时，一个自然日内，一个用户在一个渠道曝光一个销售一条记录，当日重复曝光不记录，无分区字段，全量表；
--   当channel=2时，转介绍业务，一次成功转介绍就是一条记录，无分区字段，全量表；
--   一个用户对同一坐席可曝光多次，因此同一用户会有多条记录
--
-- 【业务定位】
--   ⚠️ 本表通过 channel 字段区分不同业务场景，使用时必须先按 channel 筛选：
--     · channel = 3：企微渠道活码曝光添加（电销业务主用）
--     · channel = 2：转介绍曝光添加（转介绍业务主用）
--     · channel = 1：短信（极少使用）
--
--   企微场景（channel=3）：
--     单看坐席二维码曝光→添加率时用本表，不用于统计企微添加量
--     如需资源位曝光/点击等前置漏斗，用企微漏斗宽表（aws.user_pay_process_add_wechat_day/month）
--     两者因埋点数据损耗，计算结果会有差异
--
--   转介绍场景（channel=2）：
--     记录转介绍活动中老用户分享二维码的曝光和新用户添加事件
--     核心字段：topic_id（活动ID）、old_user_id（推荐人）、platform_id（平台）、user_id(在转介绍场景下这里指被推荐用户，在企微场景下只被曝光坐席二维码的用户)
--
-- 【统计口径】
--   企微（channel=3）：
--     曝光次数 = COUNT(channel_id)（注意是次数，不是用户数）
--     添加用户数 = COUNT(DISTINCT CASE WHEN length(external_user_id) > 0 THEN external_user_id END)
--     坐席二维码曝光添加率 = 添加用户数 / 曝光次数
--   注意：业务指标的权威定义在 glossary.md，本段仅记录"用本表怎么算"
--
-- 【常用筛选条件】
--   ★必加条件（企微场景）：
--   - channel = 3                     -- 渠道活码
--   - group_id0 IN (4, 400, 702)      -- 电销职场
--
--   ★必加条件（转介绍场景）：
--   - channel = 2                     -- 转介绍
--   - group_id0 IN (4, 400, 702)      -- 电销职场
--   - group_id2 not in (303,546,0)
--   场景条件：
--   - created_at 按时间范围过滤
--
-- 【常用关联】
--   渠道维度：channel_id = tmp.wuhan_wecom_channel_id.id（获取渠道名称/类型/等级，仅 channel=3）
--   坐席信息：worker_id = crm.worker.id
--   组织架构：group_id1~group_id4 关联 dw.dim_crm_organization
--
-- 【注意事项】
-- ⚠️ 表虽然叫企微二维码曝光添加表，但是里面加入了转介绍的业务，侧重的字段也不一样，涉及转介绍的优先以业务术语中的定义为准
-- ⚠️ 企微坐席二维码曝光添加率→ glossary.md #企微坐席二维码曝光添加率
-- ⚠️ 转介绍相关：→ glossary.md #转介绍相关
-- ⚠️ status字段含义：0=未添加，1=已添加，但是不能当做已添加的判断，因为删除企微之后这个值会变
-- ⚠️ is_repeated_exposure是否多次曝光，2025-07-26起有值，表示是否多次曝光，用于判断是否重复曝光
-- =====================================================

CREATE TABLE crm.new_user (
  `created_at` TIMESTAMP COMMENT '二维码曝光时间，按此字段统计日期',
  `id` BIGINT COMMENT '主键',
  `updated_at` TIMESTAMP COMMENT '最近一次更新时间',
  `topic_id` BIGINT COMMENT '转介绍活动ID(转介绍专属)',
  `old_user_id` STRING COMMENT '转介绍老用户(转介绍专属)',
  `worker_id` BIGINT COMMENT '坐席ID，关联 crm.worker.id',
  `open_id` STRING COMMENT '用户在微信小程序的ID',
  `status` BIGINT COMMENT '添加企业微信的状态：0=未添加，1=已添加',
  `channel` BIGINT COMMENT '渠道：1=短信，2=转介绍，3=渠道活码',
  `external_user_id` STRING COMMENT '用户企微ID，length>0 表示已添加，用于计算添加用户数',
  `user_id` STRING COMMENT '洋葱用户ID',
  `phone` STRING COMMENT '用户手机号',
  `channel_id` BIGINT COMMENT '渠道活码ID',
  `rule_template_id` BIGINT COMMENT '渠道活码规则模板ID',
  `site_id` BIGINT COMMENT '站点id',
  `union_id` STRING COMMENT '用户企业微信union_id',
  `account_id` BIGINT COMMENT '企业微信账号id',
  `is_belong_worker` BOOLEAN COMMENT '是否有归属坐席，true=是 false=否',
  `info_uuid` STRING COMMENT '线索ID',
  `ph` STRING COMMENT '加密手机号',
  `platform_id` BIGINT COMMENT '转介绍平台id',
  `follow_id` BIGINT COMMENT '助教人工号',
  `is_repeated_exposure` BOOLEAN COMMENT '是否多次曝光：true=是，false=否，2025-07-26起有值',
  `group_id1` BIGINT COMMENT '学部ID',
  `group_id2` BIGINT COMMENT '团ID',
  `group_id3` BIGINT COMMENT '主管组ID',
  `group_id4` BIGINT COMMENT '小组ID',
  `group_id0` BIGINT COMMENT '职场ID)
USING orc TBLPROPERTIES (
  'STATS_GENERATED_VIA_STATS_TASK' = 'true',
  'bucketing_version' = '2',
  'creation_platform' = 'coral',
  'is_core' = 'false',
  'is_starred' = 'false',
  'status' = '3',
  'transient_lastDdlTime' = '1752655288')
