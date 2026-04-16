-- =====================================================
-- 大盘营收- 大盘营收日月报-用户服务期归属周表 aws.business_allocation_week
-- =====================================================
--
-- 【表粒度】
--   一个服务期归属渠道一个年级一个学段一个年级段一个统计分层一个业务分层一周一条数据，分区字段：week
--
-- 【业务定位】
--   - 【归属】大盘营收 / 大盘营收日月报-用户服务期归属周表。
--   - 帆软看板「大盘营收日月报-用户服务期归属-周数据」的底层表
--
-- 【数据来源】
--   - 见建表sql
--
-- 【常用关联】
--   - 与日表 `aws.business_allocation_detail_day` 同属「服务期归属」系列，周 rollup；上游逻辑见临时文件/调度，本域看板 SQL 未见显式 JOIN 到别表
--
-- 【常用筛选条件】
--   - 分区 week
--
-- 【注意事项】
--   - 更新频率 T+1
--
-- =====================================================

CREATE TABLE
  `aws`.`business_allocation_week` (
    `active_user_num` int(11) DEFAULT NULL COMMENT '活跃用户数量',
    `user_allocation` array<varchar(1073741824)> DEFAULT NULL COMMENT '用户归属',
    `grade_name_week` varchar(1073741824) DEFAULT NULL COMMENT '年级（周）',
    `stage_name_week` varchar(1073741824) DEFAULT NULL COMMENT '学段（周）',
    `grade_stage_name_week` varchar(1073741824) DEFAULT NULL COMMENT '年级段（周）',
    `business_user_pay_status_statistics_week` varchar(1073741824) DEFAULT NULL COMMENT '统计分层（周）',
    `business_user_pay_status_business_week` varchar(1073741824) DEFAULT NULL COMMENT '业务分层（周）',
    `week` int(11) DEFAULT NULL COMMENT '分区字段'
 ) PARTITION BY (week) PROPERTIES ("location" = "tos://yc-data-platform/user/hive/warehouse/aws.db/business_allocation_week");

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 看板sql：
select 
	to_date(from_unixtime(unix_timestamp(string(week),'yyyyMMdd'),'yyyy-MM-dd')) as `日期`
	,if(string(user_allocation) regexp '其他','无归属',string(user_allocation)) as `服务期归属渠道`
    ,grade_name_week as `年级（周）`
    ,stage_name_week as `学段（周）`
    ,grade_stage_name_week as `年级段（周）`
    ,business_user_pay_status_statistics_week as `统计分层（周）`
    ,business_user_pay_status_business_week as `业务分层（周）`
	,active_user_num  as `活跃人数`
from aws.business_allocation_week


