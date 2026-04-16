-- =====================================================
-- 大盘营收- 大盘营收日月报-用户服务期归属日表 aws.business_allocation_detail_day
-- =====================================================
--
-- 【表粒度】
--   一个服务期归属渠道一个年级一个学段一个年级段一个统计分层一个业务分层一天一条数据，分区字段：day
--
-- 【业务定位】
--   - 【归属】大盘营收 / 大盘营收日月报-用户服务期归属。
--   - 帆软看板「大盘营收日月报-用户服务期归属-日数据」的底层表
--
-- 【数据来源】
--   - 见建表sql
--
-- 【常用关联】
--   - tmp.lidanping_channel_amount_fuwuqi_month1：服务期金额子查询来自 `dws.topic_order_detail` + `lateral view explode(team_names)` 按 channel 聚合；本表为大盘服务期归属独立落表，看板多为直接 select 分区
--
-- 【常用筛选条件】
--   - 分区 day
--
-- 【注意事项】
--   - 更新频率 T+1
--
-- =====================================================

CREATE TABLE
  `aws`.`business_allocation_detail_day` (
    `grade_name_day` varchar(1073741824) DEFAULT NULL COMMENT '年级（日)',
    `user_allocation` array<varchar(1073741824)> DEFAULT NULL COMMENT '用户归属',
    `stage_name_day` varchar(1073741824) DEFAULT NULL COMMENT '学段（日',
    `grade_stage_name_day` varchar(1073741824) DEFAULT NULL COMMENT '年级段（日)',
    `business_user_pay_status_statistics_day` varchar(1073741824) DEFAULT NULL COMMENT '统计分层（日）',
    `business_user_pay_status_business_day` varchar(1073741824) DEFAULT NULL COMMENT '统计分层（日）',
    `active_user_num` int(11) DEFAULT NULL COMMENT '活跃用户数量',
    `day` int(11) DEFAULT NULL COMMENT '分区字段'
 ) PARTITION BY (day) PROPERTIES ("location" = "tos://yc-data-platform/user/hive/warehouse/aws.db/business_allocation_detail_day");

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 看板sql：
select 
	to_date(from_unixtime(unix_timestamp(string(day),'yyyyMMdd'),'yyyy-MM-dd')) as `日期`
	,if(string(user_allocation) regexp '其他','无归属',string(user_allocation)) as `服务期归属渠道`
	,grade_name_day as `年级`
	,stage_name_day as `学段`
	,grade_stage_name_day as `年级段`
	,business_user_pay_status_statistics_day as `统计分层`
	,business_user_pay_status_business_day as `业务分层`
	,active_user_num  as `活跃人数`
from aws.business_allocation_detail_day 
