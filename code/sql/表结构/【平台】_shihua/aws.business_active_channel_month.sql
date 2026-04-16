-- =====================================================
-- 活跃转化- C端活跃收入月表 aws.business_active_channel_month
-- =====================================================
--
-- 【表粒度】
--   渠道 × 月 × 用户分层 × 年级/学段等聚合一条记录（分区 month int）
--
-- 【业务定位】
--   - 【归属】活跃转化 / C端活跃收入月表。
--   - 与日表同指标体系：月分区用 month，分层字段 *_month
--   - 同族表：aws.business_active_channel_day（分区 day）；列语义对齐，禁止混用分区键含义
--
-- 【统计口径】
-- 与日表 `aws.business_active_channel_day` 指标体系一致，粒度为**自然月**：分区 month（常为 YYYYMM）、维度用 `*_month`；**人数为当月本切片内去重**，非日表 active_uv 简单相加。
-- 上游仍为 `aws.business_active_user_last_14_day`；金额与日表同源（商业化/电销/整体/APP 四路分支逻辑同首部日表【统计口径】）；月加工为用户×日 rollup 到月或月粒度直接 group by。
--   `channel_allocation` 在月表可能取月内规则行（如 `max(case when rn=1 ...)`），以线上落表为准。
--   衍生指标（转化率、ARPU、客单价）分母为当月本切片去重人数；见 glossary。
--   逐字段取数口径：
--   | 字段 | 口径 |
--   |------|------|
--   | month（分区） | 自然月键，与业务统计月一致。 |
--   | month_time | 月初日期或字符串，以导出为准。 |
--   | year / month_num | 由统计月解析。 |
-- | business_user_pay_status_statistics_month | last_14 `business_user_pay_status_statistics_month`；COMMENT 可能与统计/业务命名对调。 |
--   | business_user_pay_status_business_month | last_14 `business_user_pay_status_business_month`。 |
--   | channel | 同日表四路渠道。 |
--   | grade / stage_name / grade_stage_name | last_14 `grade_name_month`、`stage_name_month`、`grade_stage_name_month`。 |
--   | active_uv | 当月本切片 count(distinct u_user)。 |
--   | amount / pb_amount / non_pb_amount | 当月本切片 rollup，定义同日表 amount、pb、non_pb。 |
--   | pay_uv / pb_paid_uv / non_pb_paid_uv | 同日表判定，统计期为当月。 |
--   | channel_allocation | 月内归属规则，以线上为准。 |
--   | is_tele_belong_month | last_14 坐席归属-月。 |
--   | big_vip_kind_month / user_strategy_tag_month / user_strategy_eligibility_month | last_14 同名列。 |
--   | new_normal_price_*_amount / *_uv | 与日表同名列，聚合期为自然月。 |
--   | yoy_* | 去年**同月**同 channel 与全部分析维度对齐的 coalesce(去年切片,0)。 |
--   （说明：CREATE 中 yoy 字段 COMMENT 若为「去年同一天」系源导出表述，月表取数以「去年同月」为准。）
--
-- 【常用关联】
--   - 加工逻辑（见【统计口径】）：与日表同源，同比为去年**同月**同 channel 与全维度对齐；上游 `aws.business_active_user_last_14_day` rollup 至月
--
-- 【常用筛选条件】
--   场景条件：
--   - month、channel、分层字段按分析选加
--
-- 【注意事项】
--   - 更新频率：月更
--   - 【数据来源】code/sql/临时文件/aws.business_active_channel_month.md
-- - ⚠️ active_uv / pay_uv 为「月 × 渠道 × 分层 × …」切片内、**当月自然月**下去重人数。须先固定 channel（四路之一），同一 month 分区内再对其余维度行 SUM(active_uv)、SUM(amount)、SUM(yoy_*) 等为该渠道分支在该月的合计；勿将四路 channel 的 active_uv 直接相加。**跨多个 month 分区**再 SUM 会跨月重复计人，见 knowledge/glossary.md 锚点 #active-conversion-uv-dedup

CREATE EXTERNAL TABLE `aws`.`business_active_channel_month` (
  `month_time` string COMMENT '月初第一天',
  `year` string COMMENT '年',
  `month_num` string COMMENT '月',
  `business_user_pay_status_statistics_month` string COMMENT '业务分层',
  `business_user_pay_status_business_month` string COMMENT '统计分层',
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
  `is_tele_belong_month` string COMMENT '已废弃或待确认（源导出缺注）',
  `big_vip_kind_month` string COMMENT '历史大会员标签',
  `user_strategy_eligibility_month` string COMMENT '用户策略资格',
  `user_strategy_tag_month` string COMMENT '用户策略标签',
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
PARTITIONED BY (`month` int COMMENT '分区：month')

ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/business_active_channel_month'

-- =====================================================
-- 枚举值
-- =====================================================
--
-- > 按 glossary【平台】规则 R34：与 `aws.business_active_channel_day` 指标体系一致，粒度为**自然月**分区；`channel` 取值逻辑与日表相同。
--
-- ## channel（渠道分支，本表加工）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 商业化 | 见该族表日表【统计口径】 |
-- | 电销 | 同上 |
-- | 整体 | 同上 |
-- | APP实际成单 | 同上 |
--
-- > `business_user_pay_status_*_month`、`grade`、`stage_name`、`grade_stage_name`、`channel_allocation`、`user_strategy_tag_*_month`、`big_vip_kind_month`、`user_strategy_eligibility_month` 及 `new_normal_price_*`、`yoy_*`：**继承** `aws.business_active_user_last_14_day.sql` 第三段中带 `_month` 或语义对应的「##」小节；与日表后缀 `_day` 对照阅读。
-- > UV/金额类为聚合结果，无数值枚举。

-- =====================================================
-- 附：APP 子集验证 SQL（节选）
-- =====================================================
-- APP 渠道用户日汇总：last_14 上 sum(fix_normal_price_*)，group by day,u_user,分层,年级,channel_allocation。
-- 月表 APP 子集：验证脚本中 `from base_info` + group by 年月,u_user,*_month,年级 + `max(case when rn=1 ...)` 得 channel_allocation。
-- 与全量月表关系：验证用；全量口径见首部【统计口径】及 `knowledge/glossary.md` #active-conversion-channel-build。
