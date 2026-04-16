-- =====================================================
-- 电销订单表 aws.crm_order_info
-- =====================================================
--
-- 【表粒度】
--   一个订单 = 一条记录（order_id 唯一）
--
-- 【业务定位】
--   仅电销业务订单，是电销业务营收的权威数据来源
--   与全公司订单宽表(dws.topic_order_detail)的区别：
--   - 本表：仅电销业务订单
--   - 全公司订单宽表：全公司所有业务订单（电销、新媒体、入校、体验营等）
--   营收归属差异：
--   - 用户可能同时存在多个服务期（如电销+新媒体）
--   - 全公司表的 business_gmv_attribution 按优先级归属，双服务期可能归新媒体
--   - 因此：本表营收 ≠ 全公司表筛选电销后的营收
--
--   选表原则：
--   - 单独只看电销营收、转化 → 用本表
--   - 活跃转化分析 / 判断用户是否购买过某商品 / gmv / 服务期营收 → 用全公司订单宽表
--
-- 【统计口径】
--   订单量 = COUNT(DISTINCT order_id)
--   营收金额 = SUM(amount)
--   转化用户量 = COUNT(DISTINCT user_id)
--   注意：业务指标的权威定义在 glossary.md，本段仅记录"用本表怎么算"
--
-- 【常用关联】
--   线索来源追溯：
--     本表.recent_info_uuid = aws.clue_info.info_uuid
--     · recent_info_uuid：成交前该坐席最近一次领取的线索id
--     · modify_recent_info_uuid：矫正后：成交前该坐席最近一次领取的非人工录入来源的线索id，若只有人工录入一条记录，则取的是这条记录
--     · first_clue_source：成单用户首次被领取时的线索来源
--
--   组织架构层级：
--     workplace_id(职场) → department_id(学部) → regiment_id(团)
--     → heads_id(主管组) → team_id(小组) → worker_id(坐席)
--     架构对应的名称通过dw.dim_crm_organization.id去取对应的名称
--
-- 【常用筛选条件】
--   ★必加条件：
--   - workplace_id IN (4, 400, 702)          -- 限定电销业务职场
--   - regiment_id NOT IN (0, 303, 546)       -- 排除无效/特殊团
--   - worker_id <> 0                         -- 排除无坐席订单
--   - in_salary = 1                          -- 排除不计入坐席业绩的特殊订单
--   - is_test = false                        -- 排除测试订单
--
--   场景条件：
--   - status = '支付成功'                    -- 看电销业务营收时加；看转化量时不加
--
-- 【注意事项】
--   ⚠️ amount 是营收统计字段，real_amount 是实付金额，original_amount 是原价，注意区分
--   ⚠️ good_type 已弃用，推荐使用 good_kind_name_level_2
--   ⚠️ 商品类目有两套体系：
--     · good_kind_name_level_1/2/3：商品 2.0 体系（2026-01-01 起生效）
--     · business_good_kind_name_level_1/2/3：策略组修正后的分类
--   ⚠️ 取用户年级优先用 mid_grade（中学修正年级），不要用 stage（下单年级）

--
-- =====================================================

CREATE TABLE
  `aws`.`crm_order_info` (
    `order_id` string COMMENT '订单id',
    `user_id` string COMMENT '用户id',
    `user_sk` string COMMENT '用户sk',
    `worker_id` int COMMENT '坐席id',
    `order_created_time` timestamp COMMENT '订单创建时间',
    `pay_time` timestamp COMMENT '支付时间',
    `order_type` smallint COMMENT '订单类型：1-新增 2-付费',
    `amount` double COMMENT '订单金额',
    `sync_type` smallint COMMENT '同步方式：1-自动判单，2-申诉, 3-七陌导入, 4-专属链接，5-端内推送，6-app内购买',
    `sync_status` smallint COMMENT '同步状态：1-正常，2-异常',
    `status` string COMMENT '订单状态：支付成功、退款成功',
    `stage` string COMMENT '下单年级',
    `department_id` int COMMENT '学部id',
    `regiment_id` int COMMENT '团id',
    `heads_id` int COMMENT '主管组id',
    `team_id` int COMMENT '小组id',
    `sell_from` string COMMENT '商品售卖来源',
    `created_at` timestamp COMMENT '创建日期',
    `updated_at` timestamp COMMENT '更新日期',
    `is_pad` int COMMENT '是否包含pad的订单：1-包含，2-不包含',
    `pad_name` string COMMENT '订单包含pad的名字',
    `business_attribution` string COMMENT '业务群归属：b 端营收、小学网课营收、轻课营收',
    `worker_name` string COMMENT '坐席名称',
    `good_id` string COMMENT '商品id',
    `good_name` string COMMENT '商品名称',
    `is_pad_price_difference_order` smallint COMMENT '是否体验机补差价订单：1-是，0-否',
    `first_clue_source` string COMMENT '成单用户首次被领取时线索来源',
    `recent_info_uuid` string COMMENT '成交前该坐席最近一次领取的线索id（关联 aws.clue_info.info_uuid）',
    `workplace_id` int COMMENT '销售职场id',
    `business_gmv_attribution` string COMMENT '业务GMV归属划分',
    `real_amount` double COMMENT '订单实付金额',
    `good_sell_kind` string COMMENT '商品售卖类型',
    `good_year` string COMMENT '商品时长',
    `model_type_array` array < string > COMMENT '订单平板型号',
    `original_amount` double COMMENT '订单原价',
    `xugou_order_kind` string COMMENT '续购订单类型',
    `xugou_pre_order_id` string COMMENT '续购前序订单id',
    `dynamic_diff_price_type` string COMMENT '补差价类型',
    `good_original_amount` double COMMENT '商品原价',
    `modify_recent_info_uuid` string COMMENT '矫正线索id：成交前该坐席最近一次非人工录入来源领取的记录，若只有人工录入则取人工录入',
    `team_ids` array < string > COMMENT '全域业绩归属',
    `team_names` array < string > COMMENT '全域业绩归属',
    `good_category` string COMMENT '商品类别',
    `sku_group_good_id` string COMMENT 'sku商品组id',
    `group` array < string > COMMENT '商品标签',
    `in_salary` smallint COMMENT '是否计入一线业绩：1-计入，2-不计入',
    `salary_threshold` string COMMENT '订单计入工资的金额阈值',
    `good_type` string COMMENT '商品类型(已弃用,推荐使用 good_kind_name_level_2)',
    `pad_type` string COMMENT '平板类型',
    `kind_array` array < string > COMMENT '子商品的类型-数组',
    `good_biz_type` string COMMENT '商品业务类型',
    `mid_grade` string COMMENT '中学修正年级（详见文件末尾枚举值）',
    `mid_stage_name` string COMMENT '中学修正学段（详见文件末尾枚举值）',
    `gender` string COMMENT '用户性别：male-男，female-女',
    `regist_time` timestamp COMMENT '注册时间',
    `province` string COMMENT '省',
    `city` string COMMENT '市',
    `city_class` string COMMENT '城市分线',
    `interest_subsidy_method` string COMMENT '贴息方式',
    `hire_purchase_commission` double COMMENT '分期手续费',
    `user_pay_status_statistics` string COMMENT '付费标签：统计维度口径（详见文件末尾枚举值）',
    `user_pay_status_business` string COMMENT '付费标签：业务维度口径（详见文件末尾枚举值）',
    `business_user_pay_status_statistics` string COMMENT '付费标签：商业化统计维度口径（详见文件末尾枚举值）',
    `business_user_pay_status_business` string COMMENT '付费标签：商业化业务维度口径 ⭐默认字段（详见文件末尾枚举值）',
    `good_kind_name_level_1` string COMMENT '商品类目-一级（详见文件末尾枚举值）',
    `good_kind_name_level_2` string COMMENT '商品类目-二级（详见文件末尾枚举值）',
    `good_kind_name_level_3` string COMMENT '商品类目-三级（详见文件末尾枚举值）',
    `good_kind_id_level_1` string COMMENT '商品类目-一级id',
    `good_kind_id_level_2` string COMMENT '商品类目-二级id',
    `good_kind_id_level_3` string COMMENT '商品类目-三级id',
    `fix_good_kind_id_level_2` string COMMENT '修正-商品类目-二级id(积木块抵扣「升单商品」专用)',
    `fix_good_kind_name_level_2` string COMMENT '修正-商品类目-二级(积木块抵扣「升单商品」专用)',
    `is_clue_seat` smallint COMMENT '线索是否在坐席名下：0-否，1-是',
    `business_good_kind_name_level_1` string COMMENT '策略组修正-商品类目-一级（详见文件末尾枚举值）',
    `business_good_kind_name_level_2` string COMMENT '策略组修正-商品类目-二级（详见文件末尾枚举值）',
    `business_good_kind_name_level_3` string COMMENT '策略组修正-商品类目-三级（详见文件末尾枚举值）',
    `fix_deductible_price` double COMMENT '修正-补差价总金额',
    `is_test` boolean COMMENT '是否是测试订单：true-是，false-否）',
    `fix_good_year` string COMMENT '修正的商品时长',
    `course_timing_kind` string COMMENT '商品分类标签：到期型、时长型',
    `course_group_kind` string COMMENT '商品分组标签：私域主推品、公域主推品',
    `strategy_type` string COMMENT '策略类型（20260101上线以后为业务数据，之前按规则清洗）',
    `strategy_detail` string COMMENT '策略明细：策略及对应的金额明细'
  ) COMMENT '一个订单一条记录'
  ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
  STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
  LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/crm_order_info'
  TBLPROPERTIES (
    'alias' = '电销订单表',
    'last_modified_by' = 'finebi',
    'last_modified_time' = '1749699283',
    'transient_lastDdlTime' = '1770065714'
  )

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## pad_name（订单包含pad的名字）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 实体-Pad-洋葱星球-领航3（S30） | |
-- | 实体-Pad-洋葱星球-远航3（Q20） | |
-- | 实体-PAD-洋葱星球P30 | |
-- | 实体-Pad-洋葱星球Q10 | |
-- | 实体-Pad-洋葱星球S20 | |
-- | 实体-Pad-学习平板 | |
-- | 实体-Pad-入校华为pad | |
-- | 实体-Pad-入校联想pad | |
--
-- ## model_type_array（订单平板型号）
-- > 数组类型，一个订单可能包含多个型号。查询时用 array_contains 或 explode。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | Q10 | 洋葱星球Q10 |
-- | Q20 | 洋葱星球远航3（Q20） |
-- | S20 | 洋葱星球S20 |
-- | S30 | 洋葱星球领航3（S30） |
-- | P30 | 洋葱星球P30 |
-- | QH01 | |
-- | HUAWEIC3 | 入校华为pad |
-- | RXHUAWEIC3 | 入校华为pad |
-- | LIANXIANG306 | 入校联想pad |
--
-- ## business_gmv_attribution（可以看电销的订单在gmv口径下归属哪些业务线）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 新媒体变现 | |
-- | 商业化 | |
-- | 体验营 | |
-- | 奥德赛 | |
-- | 新媒体视频 | |
-- | 入校 | |
-- | 电销 | |
-- | 商业化-电商 | |
--
-- ## user_pay_status_statistics（付费标签-统计维度口径）
--
-- > "新增"以注册当天为界
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 付费 | 购买过任一正价商品用户 |
-- | 新增 | 注册当天未正价付费用户 |
-- | 老未 | 注册非当天未正价付费用户 |
-- | *(空)* | 无用户归属订单 |
--
-- ## user_pay_status_business（付费标签-业务维度口径）
--
-- > "新用户"以注册30天为界
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 付费用户 | 购买过任一正价商品用户 |
-- | 新用户 | 注册30天内（≤30天）未正价付费用户 |
-- | 老用户 | 注册30天以上（>30天）未正价付费用户 |
-- | *(空)* | 无用户归属订单 |
--
-- ## business_user_pay_status_statistics（付费标签-商业化统计维度口径）
--
-- > 在统计维度口径基础上细分高净值用户
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 高净值用户 | 购买过任一高净值商品用户（大会员、组合品） |
-- | 续费用户 | 购买过任一正价商品且非高净值用户 |
-- | 新增 | 注册当天未正价付费用户 |
-- | 老未 | 注册非当天未正价付费用户 |
-- | *(空)* | 无用户归属订单 |
--
-- ## business_user_pay_status_business（付费标签-商业化业务维度口径）⭐默认字段
--
-- > 在业务维度口径基础上细分高净值用户
-- > 字段选择指南：
-- >   默认/无特殊说明 → business_user_pay_status_business ⭐
-- >   需求明确"新用户=当日注册" → business_user_pay_status_statistics
-- >   不需要区分高净值用户 → user_pay_status_statistics 或 user_pay_status_business
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 高净值用户 | 购买过任一高净值商品用户（大会员、组合品） |
-- | 续费用户 | 购买过任一正价商品且非高净值用户 |
-- | 新用户 | 注册30天内（≤30天）未正价付费用户 |
-- | 老用户 | 注册30天以上（>30天）未正价付费用户 |
-- | *(空)* | 无用户归属订单 |
--
-- ## mid_stage_name（中学修正学段）
--
-- | 枚举值 | 说明 |
-- |--------|------|
-- | 启蒙 | |
-- | 小学 | |
-- | 初中 | |
-- | 高中 | |
-- | 中职 | |
-- | NULL | 未填写 |
--
-- ## mid_grade（中学修正年级）
--
-- | 学段 | 年级枚举值 |
-- |------|-----------|
-- | 启蒙 | 学龄前 |
-- | 小学 | 一年级、二年级、三年级、四年级、五年级、六年级 |
-- | 初中 | 七年级、八年级、九年级 |
-- | 高中 | 高一、高二、高三 |
-- | 中职 | 职一、职二、职三 |
-- | 未知 | NULL |
--
-- ## good_kind_name_level_1（商品一级类目）
--
-- > 商品 2.0 体系（2026-01-01 起生效）
--
-- | 枚举值 | 说明 |
-- |--------|------|
-- | 方案型商品 | 组合商品，主力营收来源 |
-- | 零售商品 | 单课程零售 |
-- | 体验品 | 低价体验产品 |
-- | 研学商品 | 研学相关 |
-- | AI课堂 | AI 课程 |
-- | 其他商品 | 其他 |
--
-- ## good_kind_name_level_2（商品二级类目）
--
-- | 枚举值 | 说明 |
-- |--------|------|
-- | 组合商品 | 主力产品（初中品、高中品、小学品等） |
-- | 同步课 | 零售同步课 |
-- | 培优课 | 零售培优课 |
-- | 同步课加培优课 | 组合 |
-- | 升单后加购 | 学段加购 |
-- | 学习机加购 | 平板加购 |
-- | 一年积木块 | 千元品2.0 |
-- | 拓展课 | 拓展课程 |
-- | 活动定金 | 定金 |
-- | 学习机单售 | 学习机单独售卖 |
-- | 学习方法课 | 学习方法 |
-- | 学前启蒙 | 学前 |
-- | 衔接课 | 衔接 |
-- | 试卷库 | 试卷 |
-- | 研学商品 | 研学 |
-- | 体验版组合商品 | 体验版 |
-- | AI课堂 | AI |
-- | 其他体验品 | 体验品 |
-- | 实物商品 | 周边等 |
-- | 未分类课程商品 | 未分类 |
-- | 其他综合类商品 | 其他 |
-- | 其他辅助学习产品 | 辅助产品 |
--
-- ## good_kind_name_level_3（商品三级类目）
--
-- | 一级 | 二级 | 三级枚举值 |
-- |------|------|-----------|
-- | 方案型商品 | 组合商品 | 初中品-3年同步课加培优课、初中品-2年同步课加培优课、初中品-1年同步课加培优课、高中品-3年同步课加培优课、高中品-2年同步课加培优课、高中品-1年同步课加培优课、小学品-6年同步课、小初品-6年同步课加培优课、小初品-5年同步课加培优课、小初品-4年同步课加培优课、小初品-4年同步课、组合商品-4年时长型同步课加到期培优课、组合商品-4年时长型同步课、组合商品-6年时长型 |
-- | 方案型商品 | 一年积木块 | 千元品2.0 |
-- | 方案型商品 | 升单后加购 | 升单后加购-学段加购 |
-- | 方案型商品 | 学习机加购 | 学习机加购-平板加购 |
-- | 零售商品 | 同步课 | 同步课-12个月、同步课-3个月、同步课-智课特殊品 |
-- | 零售商品 | 同步课加培优课 | 同步课加培优课流量品、同步课加培优课 |
-- | 零售商品 | 培优课 | 培优课-到期型、培优课-12个月、培优课-3个月 |
-- | 零售商品 | 拓展课 | 拓展课 |
-- | 零售商品 | 学习机单售 | 全价购买 |
-- | 零售商品 | 学习方法课 | 学习方法课、AI通识课 |
-- | 零售商品 | 学前启蒙 | 学前启蒙 |
-- | 零售商品 | 衔接课 | 衔接课 |
-- | 零售商品 | 试卷库 | 试卷库 |
-- | 零售商品 | 未分类课程商品 | 未分类课程商品 |
-- | 零售商品 | 其他辅助学习产品 | 升学志愿 |
-- | 体验品 | 活动定金 | 活动定金 |
-- | 体验品 | 体验版组合商品 | 体验版组合商品 |
-- | 体验品 | 其他体验品 | 其他体验品 |
-- | 研学商品 | 研学商品 | 寒暑假营、研学商品 |
-- | AI课堂 | AI课堂 | 软件采购、硬件+软件采购、硬件采购 |
-- | 其他商品 | 实物商品 | 周边 |
-- | 其他商品 | 其他综合类商品 | 单后赠品 |
--
-- ## business_good_kind_name_level_1（策略组一级）
--
-- | 枚举值 | 说明 |
-- |--------|------|
-- | 组合品 | 方案型主力产品 |
-- | 零售商品 | 单课程零售 |
-- | 续购 | 加购类（学段加购、学习机加购） |
-- | 其他 | 定金、研学、体验品等 |
--
-- ## business_good_kind_name_level_2（策略组二级）
--
-- | 枚举值 | 说明 |
-- |--------|------|
-- | 单学段商品 | 初中品、高中品、小学品 |
-- | 多学段商品 | 小初品、小初同步品 |
-- | 零售商品 | 同步课、培优课、拓展课等 |
-- | 续购 | 学段加购、学习机加购 |
-- | 其他 | 定金、研学、体验品 |
--
-- ## business_good_kind_name_level_3（策略组三级）
--
-- | 枚举值 | 说明 |
-- |--------|------|
-- | 初中品 | 初中组合商品 |
-- | 高中品 | 高中组合商品 |
-- | 小学品 | 小学组合商品 |
-- | 小初品 | 小初跨学段商品 |
-- | 小初同步品 | 小初同步组合 |
-- | 同步课 | 零售同步课 |
-- | 培优课 | 零售培优课 |
-- | 拓展课 | 零售拓展课 |
-- | 学段加购 | 升单后学段加购 |
-- | 学习机加购 | 平板加购 |
-- | 定金 | 活动定金 |
-- | 研学 | 研学商品 |
-- | 体验品 | 体验类商品 |
-- | 其他 | 其他 |
--
-- ## strategy_type（策略类型）
--
-- > 2026-01-01 上线后为业务数据，之前按规则清洗。{无策略}表示该订单未命中任何策略。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | {历史大会员续购策略} | |
-- | {多孩策略} | |
-- | {高中围课策略} | |
-- | {无策略} | 未命中任何策略 |
-- | {补差策略} | |
-- | {学习机加购策略} | |

