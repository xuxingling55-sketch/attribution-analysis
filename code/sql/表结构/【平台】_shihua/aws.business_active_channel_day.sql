-- =====================================================
-- 活跃转化- C端活跃收入日表 aws.business_active_channel_day
-- =====================================================
--
-- 【表粒度】
--   渠道 × 日 × 用户分层 × 年级/学段等聚合一条记录（分区 day int）
--
-- 【业务定位】
--   - 【归属】活跃转化 / C端活跃收入日表。
--   - 与 aws.business_active_channel_month 同指标体系：日分区用 day，字段含 *_day 分层、yoy_* 同比
--   - 新方案型/组合品/续购拆解营收与 UV
--
-- 【统计口径】
-- 上游事实表：`aws.business_active_user_last_14_day`（下称 last_14）。日期窗一般为 day ∈ [before_15_day, day] 及同比 day-10000 对齐，参数以调度为准。
--   加工：先按渠道分支在用户×日粒度汇总金额（四路 UNION ALL：商业化 / 电销 / 整体 / APP实际成单），再按维度切片聚合；最后与「去年同日同切片」FULL JOIN 得 yoy_*。
-- 商业化/电销/整体：金额 = sum(if(business_gmv_attribution in (...), last_14 对应金额列, 0))；APP实际成单：sum(nvl(fix_* 列,0))，不按 business_gmv_attribution 拆。
-- 一行 = 分区 day × channel × 分层 × 年级学段 × channel_allocation × 坐席归属 × 策略标签等；active_uv、pay_uv 为该切片内去重人数。须先固定 channel（四路之一），同一 day 分区内再对其余维度行 SUM(active_uv)、SUM(amount) 等为该渠道分支在该日的合计；勿将四路 channel 的 active_uv 直接相加。跨多个 day 分区再 SUM 会跨日重复计人（见 glossary #active-conversion-uv-dedup）。
--   衍生（本表无列）：转化率=pay_uv/active_uv；客单价=amount/pay_uv；ARPU=amount/active_uv；见 knowledge/glossary.md「活跃转化大盘」。
--   逐字段取数口径：
--   | 字段 | 口径 |
--   |------|------|
--   | day（分区） | 业务日 yyyyMMdd；同比结果里 coalesce(当年日, concat(去年年, 去年月日))。 |
--   | year / month / year_month / month_day | 由 day 解析：年=left(day,4)，年月=left(day,6)，月日=right(day,4)。 |
-- | business_user_pay_status_statistics_day | last_14 当日 `business_user_pay_status_statistics_day`；源导出 COMMENT 与「统计/业务」命名可能对调，以线上为准。 |
--   | business_user_pay_status_business_day | last_14 `business_user_pay_status_business_day`。 |
--   | channel | 加工枚举：'商业化'、'电销'、'整体'、'APP实际成单'（整体=商业化+电销归因合并）。 |
--   | grade / stage_name / grade_stage_name | last_14 `grade_name_day`、`stage_name_day`、`grade_stage_name_day`。 |
--   | active_uv | 切片内 count(distinct u_user)。 |
--   | amount | 切片内 sum(用户日 total_amount)；total_amount 来自 normal_price_amount 或 APP 的 fix_normal_price_amount。 |
-- | pb_amount | 切片 sum(用户日 pb_amount)；来自 normal_price_scheme_amount 或 fix_normal_price_scheme_amount（DDL COMMENT 可能写「大会员」，业务常作方案型，以脚本为准）。 |
-- | non_pb_amount | 切片 sum(用户日 non_pb_amount)；来自 normal_price_non_scheme_amount 或 fix_normal_price_non_scheme_amount。 |
--   | pay_uv | count(distinct if(total_amount>0, u_user, null))。 |
--   | pb_paid_uv / non_pb_paid_uv | count(distinct if(pb_amount>0 / non_pb_amount>0, u_user, null))。 |
--   | channel_allocation | user_allocation：含「电销/网销」→含电销归属；null→无归属；否则非电销归属。 |
--   | is_tele_belong_day | last_14 `is_tele_belong_day`。 |
--   | user_strategy_tag_day / user_strategy_eligibility_day / big_vip_kind_day | last_14 同名列。 |
--   | new_normal_price_*_amount | 用户日内对 last_14 同名金额列（APP 为 fix_new_normal_price_*）按渠道 sum 后再切片 sum。 |
--   | new_normal_price_*_uv | count(distinct if(该子列金额>0, u_user, null))。 |
--   | yoy_*（含 yoy_new_normal_price_*） | coalesce(a2.对应列,0)，a2 为去年同日、同 channel 与全部分析维度对齐的切片。 |
--
-- 【常用关联】
--   - 加工逻辑（见【统计口径】）：当年切片与「去年同日同 channel 及全部分析维度」FULL JOIN 得 yoy_*；上游聚合自 `aws.business_active_user_last_14_day`（字段级对齐见该段表格）
--
-- 【常用筛选条件】
--   场景条件：
--   - day、channel、business_user_pay_status_*_day 等按分析目的选加
--
-- 【注意事项】
-- - 源导出中 business_user_pay_status_statistics_day 与 business_user_pay_status_business_day 的 COMMENT 与常见「统计/业务」命名可能对调，以线上表为准
--   - 更新频率 T+1
--   - 【数据来源】code/sql/临时文件/aws.business_active_channel_day.md（导出转 Hive）
-- - ⚠️ active_uv / pay_uv 为本行切片（日×渠道×分层×…）内人数；同一 day 分区内 SUM 为分区合计；跨多个 day 分区勿混加人数/金额，见 knowledge/glossary.md 锚点 #active-conversion-uv-dedup

CREATE EXTERNAL TABLE `aws`.`business_active_channel_day` (
  `year` string COMMENT '年',
  `month` string COMMENT '月',
  `year_month` string COMMENT '年月',
  `month_day` string COMMENT '月日',
  `business_user_pay_status_statistics_day` string COMMENT '业务分层',
  `business_user_pay_status_business_day` string COMMENT '统计分层',
  `channel` string COMMENT '渠道',
  `grade` string COMMENT '年级',
  `stage_name` string COMMENT '学段',
  `grade_stage_name` string COMMENT '年级段',
  `active_uv` int COMMENT '活跃人数',
  `amount` double COMMENT '正价总营收',
  `pb_amount` double COMMENT '正价大会员商品营收',
  `non_pb_amount` double COMMENT '正价常规商品营收',
  `pay_uv` int COMMENT '正价付费人数',
  `pb_paid_uv` int COMMENT '正价大会员商品付费人数',
  `non_pb_paid_uv` int COMMENT '正价常规商品付费人数',
  `yoy_active_uv` int COMMENT '去年同一天的活跃人数',
  `yoy_amount` double COMMENT '去年同一天的正价总营收',
  `yoy_pb_amount` double COMMENT '去年同一天的正价大会员商品营收',
  `yoy_non_pb_amount` double COMMENT '去年同一天的正价常规商品营收',
  `yoy_pay_uv` int COMMENT '去年同一天的正价付费人数',
  `yoy_pb_paid_uv` int COMMENT '去年同一天的正价大会员商品付费人数',
  `yoy_non_pb_paid_uv` int COMMENT '去年同一天的正价常规商品付费人数',
  `channel_allocation` string COMMENT '渠道归属',
  `is_tele_belong_day` string COMMENT '已废弃或待确认（源导出缺注）',
  `user_strategy_tag_day` string COMMENT '用户策略标签',
  `user_strategy_eligibility_day` string COMMENT '用户策略资格',
  `big_vip_kind_day` string COMMENT '历史大会员标签-日',
  `new_normal_price_scheme_amount` double COMMENT '新方案型商品营收',
  `new_normal_price_scheme_zuhepin_amount` double COMMENT '新方案型-组合品营收',
  `new_normal_price_scheme_zuhepin_buchajia_amount` double COMMENT '新方案型-组合品-补差策略营收',
  `new_normal_price_scheme_zuhepin_mulchild_amount` double COMMENT '新方案型-组合品-多孩策略营收',
  `new_normal_price_scheme_zuhepin_highhoardcourse_amount` double COMMENT '新方案型-组合品-高中囤课策略营收',
  `new_normal_price_scheme_zuhepin_padaddpur_amount` double COMMENT '新方案型-组合品-学习机加购策略营收',
  `new_normal_price_scheme_zuhepin_hismem_amount` double COMMENT '新方案型-组合品-历史大会员续购策略营收',
  `new_normal_price_scheme_zuhepin_non_singular_amount` double COMMENT '新方案型-组合品-无策略-单学段营收',
  `new_normal_price_scheme_zuhepin_non_plural_amount` double COMMENT '新方案型-组合品-无策略-多学段营收',
  `new_normal_price_scheme_xugou_common_amount` double COMMENT '新方案型-续购-普通续购营收',
  `new_normal_price_scheme_xugou_stageaddpeiyou_amount` double COMMENT '新方案型-续购-学段加购+培优课加购营收',
  `new_normal_price_scheme_xugou_pad_amount` double COMMENT '新方案型-续购-学习机加购营收',
  `new_normal_price_non_scheme_amount` double COMMENT '新常规型商品营收',
  `new_normal_price_scheme_uv` int COMMENT '新方案型商品付费用户数',
  `new_normal_price_scheme_zuhepin_uv` int COMMENT '新方案型-组合品付费用户数',
  `new_normal_price_scheme_zuhepin_buchajia_uv` int COMMENT '新方案型-组合品-补差策略付费用户数',
  `new_normal_price_scheme_zuhepin_mulchild_uv` int COMMENT '新方案型-组合品-多孩策略付费用户数',
  `new_normal_price_scheme_zuhepin_highhoardcourse_uv` int COMMENT '新方案型-组合品-高中囤课策略付费用户数',
  `new_normal_price_scheme_zuhepin_padaddpur_uv` int COMMENT '新方案型-组合品-学习机加购策略付费用户数',
  `new_normal_price_scheme_zuhepin_hismem_uv` int COMMENT '新方案型-组合品-历史大会员续购策略付费用户数',
  `new_normal_price_scheme_zuhepin_non_singular_uv` int COMMENT '新方案型-组合品-无策略-单学段付费用户数',
  `new_normal_price_scheme_zuhepin_non_plural_uv` int COMMENT '新方案型-组合品-无策略-多学段付费用户数',
  `new_normal_price_scheme_xugou_common_uv` int COMMENT '新方案型-续购-普通续购付费用户数',
  `new_normal_price_scheme_xugou_stageaddpeiyou_uv` int COMMENT '新方案型-续购-学段加购+培优课加购付费用户数',
  `new_normal_price_scheme_xugou_pad_uv` int COMMENT '新方案型-续购-学习机加购付费用户数',
  `new_normal_price_non_scheme_uv` int COMMENT '新常规型商品付费用户数',
  `yoy_new_normal_price_scheme_amount` double COMMENT '去年同期新方案型商品营收',
  `yoy_new_normal_price_scheme_zuhepin_amount` double COMMENT '去年同期新方案型-组合品营收',
  `yoy_new_normal_price_scheme_zuhepin_buchajia_amount` double COMMENT '去年同期新方案型-组合品-补差策略营收',
  `yoy_new_normal_price_scheme_zuhepin_mulchild_amount` double COMMENT '去年同期新方案型-组合品-多孩策略营收',
  `yoy_new_normal_price_scheme_zuhepin_highhoardcourse_amount` double COMMENT '去年同期新方案型-组合品-高中囤课策略营收',
  `yoy_new_normal_price_scheme_zuhepin_padaddpur_amount` double COMMENT '去年同期新方案型-组合品-学习机加购策略营收',
  `yoy_new_normal_price_scheme_zuhepin_hismem_amount` double COMMENT '去年同期新方案型-组合品-历史大会员续购策略营收',
  `yoy_new_normal_price_scheme_zuhepin_non_singular_amount` double COMMENT '去年同期新方案型-组合品-无策略-单学段营收',
  `yoy_new_normal_price_scheme_zuhepin_non_plural_amount` double COMMENT '去年同期新方案型-组合品-无策略-多学段营收',
  `yoy_new_normal_price_scheme_xugou_common_amount` double COMMENT '去年同期新方案型-续购-普通续购营收',
  `yoy_new_normal_price_scheme_xugou_stageaddpeiyou_amount` double COMMENT '去年同期新方案型-续购-学段加购+培优课加购营收',
  `yoy_new_normal_price_scheme_xugou_pad_amount` double COMMENT '去年同期新方案型-续购-学习机加购营收',
  `yoy_new_normal_price_non_scheme_amount` double COMMENT '去年同期新常规型商品营收',
  `yoy_new_normal_price_scheme_uv` int COMMENT '去年同期新方案型商品付费用户数',
  `yoy_new_normal_price_scheme_zuhepin_uv` int COMMENT '去年同期新方案型-组合品付费用户数',
  `yoy_new_normal_price_scheme_zuhepin_buchajia_uv` int COMMENT '去年同期新方案型-组合品-补差策略付费用户数',
  `yoy_new_normal_price_scheme_zuhepin_mulchild_uv` int COMMENT '去年同期新方案型-组合品-多孩策略付费用户数',
  `yoy_new_normal_price_scheme_zuhepin_highhoardcourse_uv` int COMMENT '去年同期新方案型-组合品-高中囤课策略付费用户数',
  `yoy_new_normal_price_scheme_zuhepin_padaddpur_uv` int COMMENT '去年同期新方案型-组合品-学习机加购策略付费用户数',
  `yoy_new_normal_price_scheme_zuhepin_hismem_uv` int COMMENT '去年同期新方案型-组合品-历史大会员续购策略付费用户数',
  `yoy_new_normal_price_scheme_zuhepin_non_singular_uv` int COMMENT '去年同期新方案型-组合品-无策略-单学段付费用户数',
  `yoy_new_normal_price_scheme_zuhepin_non_plural_uv` int COMMENT '去年同期新方案型-组合品-无策略-多学段付费用户数',
  `yoy_new_normal_price_scheme_xugou_common_uv` int COMMENT '去年同期新方案型-续购-普通续购付费用户数',
  `yoy_new_normal_price_scheme_xugou_stageaddpeiyou_uv` int COMMENT '去年同期新方案型-续购-学段加购+培优课加购付费用户数',
  `yoy_new_normal_price_scheme_xugou_pad_uv` int COMMENT '去年同期新方案型-续购-学习机加购付费用户数',
  `yoy_new_normal_price_non_scheme_uv` int COMMENT '去年同期新常规型商品付费用户数'
)
PARTITIONED BY (`day` int COMMENT '分区：day')

ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/business_active_channel_day'

-- =====================================================
-- 枚举值
-- =====================================================
--
-- > 按 glossary【平台】规则 R34：本表为 **AWS 应用层**渠道活跃商业化汇总；**本层新增**加工维度见下，`channel` 取值见首部【统计口径】。
--
-- ## channel（渠道分支，本表加工）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 商业化 | 见【统计口径】四路 UNION 之一 |
-- | 电销 | 见【统计口径】 |
-- | 整体 | 商业化+电销归因合并 |
-- | APP实际成单 | APP 成单子查询分支 |
--
-- > `business_user_pay_status_statistics_day`、`business_user_pay_status_business_day`、`grade`、`stage_name`、`grade_stage_name`、`channel_allocation`、`is_tele_belong_day`、`user_strategy_tag_day`、`user_strategy_eligibility_day`、`big_vip_kind_day` 及各类 `new_normal_price_*`、`yoy_*`：自上游 `aws.business_active_user_last_14_day` 聚合而来，**同名列**枚举与含义 **继承** `aws.business_active_user_last_14_day.sql` 第三段对应「##」小节（日维度字段）。
-- > UV/金额类为聚合结果，无数值枚举；布尔以 COMMENT 为准。

-- =====================================================
-- 附：脚本别名与补充说明
-- =====================================================
-- 子查询名 `bussiness_active_channel`、FULL JOIN 当年 a / 去年 a2、`ALTER` 增量列等见首部【统计口径】及加工脚本；
-- 与首部【统计口径】一致。全文加工链路见 `knowledge/glossary.md` #active-conversion-channel-build。
