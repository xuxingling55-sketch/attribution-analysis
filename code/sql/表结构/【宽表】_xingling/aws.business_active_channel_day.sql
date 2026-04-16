-- =====================================================
-- 渠道活跃商业化日汇总表 aws.business_active_channel_day
-- =====================================================
--
-- 【表粒度】
--   渠道 × 日 × 用户分层 × 年级/学段等聚合一条记录（分区 day int）
--
-- 【业务定位】
--   - 与 aws.business_active_channel_month 同指标体系：日分区用 day，字段含 *_day 分层、yoy_* 同比
--   - 新方案型/组合品/续购拆解营收与 UV
--
-- 【统计口径】
--   上游事实表：`aws.business_active_user_last_14_day`（下称 last_14）。日期窗一般为 day ∈ [before_15_day, day] 及同比 day-10000 对齐，参数以调度为准。
--   加工：先按渠道分支在用户×日粒度汇总金额（四路 UNION ALL：商业化 / 电销 / 整体 / APP实际成单），再按维度切片聚合；最后与「去年同日同切片」FULL JOIN 得 yoy_*。
--   商业化/电销/整体：金额 = sum(if(business_gmv_attribution in (...), last_14 对应金额列, 0))；APP实际成单：sum(nvl(fix_* 列,0))，不按 business_gmv_attribution 拆。
--   一行 = 分区 day × channel × 分层 × 年级学段 × channel_allocation × 坐席归属 × 策略标签等；active_uv、pay_uv 为该切片内去重人数；同一 day 分区内对所有维度行 SUM(active_uv)（及 amount、yoy_* 等）为该日分区合计；跨多个 day 分区再 SUM 会跨日重复计人（见 glossary #active-conversion-uv-dedup）。
--   衍生（本表无列）：转化率=pay_uv/active_uv；客单价=amount/pay_uv；ARPU=amount/active_uv；见 knowledge/glossary.md「活跃转化大盘」。
--   逐字段取数口径：
--   | 字段 | 口径 |
--   |------|------|
--   | day（分区） | 业务日 yyyyMMdd；同比结果里 coalesce(当年日, concat(去年年, 去年月日))。 |
--   | year / month / year_month / month_day | 由 day 解析：年=left(day,4)，年月=left(day,6)，月日=right(day,4)。 |
--   | business_user_pay_status_statistics_day | last_14 当日 `business_user_pay_status_statistics_day`；源导出 COMMENT 与「统计/业务」命名可能对调，以线上为准。 |
--   | business_user_pay_status_business_day | last_14 `business_user_pay_status_business_day`。 |
--   | channel | 加工枚举：'商业化'、'电销'、'整体'、'APP实际成单'（整体=商业化+电销归因合并）。 |
--   | grade / stage_name / grade_stage_name | last_14 `grade_name_day`、`stage_name_day`、`grade_stage_name_day`。 |
--   | active_uv | 切片内 count(distinct u_user)。 |
--   | amount | 切片内 sum(用户日 total_amount)；total_amount 来自 normal_price_amount 或 APP 的 fix_normal_price_amount。 |
--   | pb_amount | 切片 sum(用户日 pb_amount)；来自 normal_price_scheme_amount 或 fix_normal_price_scheme_amount（DDL COMMENT 可能写「大会员」，业务常作方案型，以脚本为准）。 |
--   | non_pb_amount | 切片 sum(用户日 non_pb_amount)；来自 normal_price_non_scheme_amount 或 fix_normal_price_non_scheme_amount。 |
--   | pay_uv | count(distinct if(total_amount>0, u_user, null))。 |
--   | pb_paid_uv / non_pb_paid_uv | count(distinct if(pb_amount>0 / non_pb_amount>0, u_user, null))。 |
--   | channel_allocation | user_allocation：含「电销/网销」→含电销归属；null→无归属；否则非电销归属。 |
--   | is_tele_belong_day | last_14 `is_tele_belong_day`。 |
--   | user_strategy_tag_day / user_strategy_eligibility_day / big_vip_kind_day | last_14 同名列。 |
--   | new_normal_price_*_amount | 用户日内对 last_14 同名金额列（APP 为 fix_new_normal_price_*）按渠道 sum 后再切片 sum。 |
--   | new_normal_price_*_uv | count(distinct if(该子列金额>0, u_user, null))。 |
--   | yoy_*（含 yoy_new_normal_price_*） | coalesce(a2.对应列,0)，a2 为去年同日、同 channel 与全部分析维度对齐的切片。 |
--
-- 【常用筛选条件】
--   场景条件：
--   - day、channel、business_user_pay_status_*_day 等按分析目的选加
--
-- 【注意事项】
--   - 源导出中 business_user_pay_status_statistics_day 与 business_user_pay_status_business_day 的 COMMENT 与常见「统计/业务」命名可能对调，以线上表为准
--   - 更新频率 T+1
--   - 【数据来源】code/sql/临时文件/aws.business_active_channel_day.md（导出转 Hive）
--   - ⚠️ active_uv / pay_uv 为本行切片（日×渠道×分层×…）内人数；同一 day 分区内 SUM 为分区合计；跨多个 day 分区勿混加人数/金额，见 knowledge/glossary.md 锚点 #active-conversion-uv-dedup


CREATE EXTERNAL TABLE `aws`.`business_active_channel_day` (
  `day` int COMMENT '日期分区',
  `province` string COMMENT '省',
  `city` string COMMENT '市',
  `city_code` string COMMENT '市code',
  `area` string COMMENT '区',
  `area_code` string COMMENT '区code',
  `new_media_cnt` bigint COMMENT '新媒体新增注册数',
  `new_media_pay_user_cnt` bigint COMMENT '新媒体付费用户数',
  `new_media_pay_amount` double COMMENT '新媒体付费金额',
  `new_media_free_course_cnt` bigint COMMENT '新媒体免费课程观看数',
  `new_media_free_course_duration` bigint COMMENT '新媒体免费课程观看时长',
  `new_media_free_course_user_cnt` bigint COMMENT '新媒体免费课程观看用户数',
  `new_media_free_course_watch_duration` bigint COMMENT '新媒体免费课程观看时长',
  `new_media_free_course_video_cnt` bigint COMMENT '新媒体免费课程完播次数',
  `new_media_free_course_video_watch_duration` bigint COMMENT '新媒体免费课程完播时长',
  `new_media_free_course_video_cnt` bigint COMMENT '新媒体免费课程视频完播次数',
  `new_media_free_course_video_watch_duration` bigint COMMENT '新媒体免费课程视频完播时长',
  `new_media_online_course_cnt` bigint COMMENT '新媒体在线课程观看数',
  `new_media_online_course_duration` bigint COMMENT '新媒体在线课程观看时长',
  `new_media_online_course_user_cnt` bigint COMMENT '新媒体在线课程观看用户数',
  `new_media_online_course_watch_duration` bigint COMMENT '新媒体在线课程观看时长',
  `new_media_online_course_video_cnt` bigint COMMENT '新媒体在线课程完播次数',
  'new_media_online_course_video_watch_duration` bigint COMMENT '新媒体在线课程视频完播时长',
  `old_user_cnt` bigint COMMENT '老用户数',
  `old_user_pay_user_cnt` bigint COMMENT '老用户付费用户数',
  `old_user_pay_amount` double COMMENT '老用户付费金额',
  `old_user_free_course_cnt` bigint COMMENT '老用户免费课程观看数',
  `old_user_free_course_duration` bigint COMMENT '老用户免费课程观看时长',
  `old_user_free_course_user_cnt` bigint COMMENT '老用户免费课程观看用户数',
  `old_user_free_course_watch_duration` bigint COMMENT '老用户免费课程观看时长',
  `old_user_free_course_video_cnt` bigint COMMENT '老用户免费课程完播次数',
  `old_user_free_course_video_watch_duration` bigint COMMENT '老用户免费课程视频完播时长',
  `old_user_online_course_cnt` bigint COMMENT '老用户在线课程观看数',
  `old_user_online_course_duration` bigint COMMENT '老用户在线课程观看时长',
  `old_user_online_course_user_cnt` bigint COMMENT '老用户在线课程观看用户数',
  `old_user_online_course_video_cnt` bigint COMMENT '老用户在线课程完播次数',
  `old_user_online_course_video_watch_duration` bigint COMMENT '老用户在线课程视频完播时长',
  `free_course_cnt` bigint COMMENT '免费课程观看数',
  `free_course_duration` bigint COMMENT '免费课程观看时长',
  `free_course_user_cnt` bigint COMMENT '免费课程观看用户数',
  `free_course_video_cnt` bigint COMMENT '免费课程完播次数',
  free_course_video_watch_duration bigint COMMENT '免费课程视频完播时长',
  `online_course_cnt` bigint COMMENT '在线课程观看数',
  `online_course_duration` bigint COMMENT '在线课程观看时长',
  `online_course_user_cnt` bigint COMMENT '在线课程观看用户数',
  `online_course_video_cnt` bigint COMMENT '在线课程完播次数',
  `online_course_video_watch_duration` bigint COMMENT '在线课程视频完播时长'
) COMMENT '渠道活跃商业化日汇总表'
PARTITIONED BY (`day` int) STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.com.hadoop.mapred.ParquetHiveSerDe' STORED AS OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.com.hadoop.mapred.ParquetOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/business_active_channel_day'