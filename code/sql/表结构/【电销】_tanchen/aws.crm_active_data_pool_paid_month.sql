-- =====================================================
-- C端活跃用户推送公海池触发漏斗转化月表 aws.crm_active_data_pool_paid_month
-- =====================================================
-- 【表粒度】★必填
--   一个用户一条记录，按 month(int, 如 202603) 分区
--
-- 【业务定位】
--   在漏斗表(crm_active_data_pool_month)基础上增加转化结果：
--   漏斗表看过程（活跃→推送→入库→领取），本表看结果（领取后转化了多少用户、多少金额）
--   漏斗术语定义 → glossary.md #电话线索漏斗指标
--
-- 【与 crm_active_data_pool_month 的区别】
--   1. 本表增加了 3 组转化字段（转化用户 + 转化金额），漏斗表没有
--   2. 用户属性全部取月初值（首次活跃日），漏斗表区分月初/月末值
--   3. 本表有 3 个领取口径（漏斗表只有 2 个），且 recieve_u_user_all 含义不同：
--      漏斗表 recieve_u_user_all = 不限来源的领取（无公海池前置条件）
--      本表   recieve_u_user_all = 进入公海池 + 不限来源的领取（有公海池前置条件）
--      本表   active_recieve_u_user_all = 不限来源的领取（无公海池前置条件）← 等价于漏斗表的 recieve_u_user_all
--
-- 【数据来源】
--   aws.business_active_user_last_14_day —— 用户属性（年级、学段、付费状态）
--   dws.topic_user_active_detail_day     —— 活跃用户 + 首次活跃日期 + 服务期
--   aws.clue_info                        —— 判断是否在坐席名下 + 当月领取记录（来源、领取时间）
--   ods_rt.telesale_clue_rt              —— 推送记录 + 首次公海池拒绝原因
--   crm.info_produce_log_all             —— 进入公海池记录
--   aws.crm_order_info                   —— 当月电销订单（标准五条件过滤），构建付费时间线
--   线索领取表说明：dw.fact_clue_allocate_info 为线索领取底层表；aws.clue_info 为数仓加工后的线索领取表，BI 取数常用。
--
-- 【属性取值时点】
--   全部取当月首次活跃日的值（按 DAY ASC 排序取第一条），无月末值
--
-- 【转化金额计算逻辑】
--   1. 从 aws.crm_order_info 提取当月所有订单，构建用户付费时间线（pay_timeline）
--   2. 对每个领取口径，取领取时间之后的付费记录，计算领取后到月底的累计付费金额
--   3. 转化用户：领取后有付费则非NULL；转化金额：领取后的累计付费金额
--
-- 【三个领取口径与对应的转化字段】
--   口径1-限制入库+电话线索：recieve_u_user       → recieve_paid_u_user     / recieve_paid_amount
--   口径2-限制入库+所有来源：recieve_u_user_all    → recieve_all_paid_u_user / recieve_all_paid_amount
--   口径3-活跃+所有来源：active_recieve_u_user_all → active_paid_u_user_all / active_paid_amount_all
--
-- 【常用筛选条件】
--   ★必加条件：
--   无
--
--   场景条件：
--   - month 按分区过滤（int 类型，格式 yyyyMM）
-- =====================================================

CREATE EXTERNAL TABLE `aws`.`crm_active_data_pool_paid_month` (
  `active_first_date_month` string COMMENT '当月首次活跃日期',
  `user_sk` int COMMENT '数仓用户sk',
  `active_u_user` string COMMENT '当月活跃用户ID',
  `grade_name_month` string COMMENT '【月初值】当月首次活跃日的年级',
  `stage_name_month` string COMMENT '【月初值】当月首次活跃日的学段',
  `user_pay_status_statistics_month` string COMMENT '【月初值】统计维度付费状态：新增、老未、付费',
  `user_pay_status_business_month` string COMMENT '【月初值】业务维度付费状态：新用户、老用户、付费用户',
  `business_user_pay_status_statistics_month` string COMMENT '【月初值】商业化统计维度：新增、老未、大会员付费、非大会员付费',
  `business_user_pay_status_business_month` string COMMENT '【月初值】商业化业务维度：高净值用户、续费用户、新用户、老用户',
  `is_tele_belong_first_month` string COMMENT '【月初值】当月首次活跃日是否在坐席名下（1=在库，0=不在库）',
  `user_allocation_month` string COMMENT '【月初值】当月首次活跃日的用户服务期归属',
  `push_u_user` string COMMENT '当月被推送到电销的用户',
  `enter_datapool_u_user` string COMMENT '当月进入公海池的用户',
  `recieve_u_user` string COMMENT '入库电话线索领取用户',
  `recieve_u_user_all` string COMMENT '入库领取用户',
  `active_recieve_u_user_all` string COMMENT '活跃领取用户',
  `first_deny_reason` string COMMENT '当月首次被公海池拒绝的原因',
  `first_deny_index` string COMMENT '当月首次被公海池拒绝的编号',
  `recieve_paid_u_user` string COMMENT '入库电话线索领取转化用户',
  `recieve_paid_amount` double COMMENT '入库电话线索领取转化金额',
  `recieve_all_paid_u_user` string COMMENT '入库领取转化用户',
  `recieve_all_paid_amount` double COMMENT '入库领取转化金额',
  `active_paid_u_user_all` string COMMENT '活跃领取转化用户',
  `active_paid_amount_all` double COMMENT '活跃领取转化金额'
) PARTITIONED BY (`month` int) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/crm_active_data_pool_paid_month' TBLPROPERTIES (
  'bucketing_version' = '2',
  'discover.partitions' = 'true',
  'spark.sql.partitionProvider' = 'catalog',
  'transient_lastDdlTime' = '1752740817'
)

-- =====================================================
-- 枚举值
-- =====================================================
-- ## grade_name_month（年级）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 学龄前 | 启蒙 |
-- | 一年级 | 小学 |
-- | 二年级 | 小学 |
-- | 三年级 | 小学 |
-- | 四年级 | 小学 |
-- | 五年级 | 小学 |
-- | 六年级 | 小学 |
-- | 七年级 | 初中 |
-- | 八年级 | 初中 |
-- | 九年级 | 初中 |
-- | 高一 | 高中 |
-- | 高二 | 高中 |
-- | 高三 | 高中 |
-- | 职一 | 中职 |
-- | 职二 | 中职 |
-- | 职三 | 中职 |
-- | NULL | 未填写 |
--
-- ## stage_name_month（学段）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 启蒙 | |
-- | 小学 | |
-- | 初中 | |
-- | 高中 | |
-- | 中职 | |
-- | NULL | 未填写 |
--
-- ## user_allocation_month（用户服务期归属）
-- > string 类型，值为数组格式的字符串；多服务期用逗号分隔
-- | 枚举值 | 含义 |
-- |--------|------|
-- | [电销/网销] | |
-- | [体验营] | |
-- | [新媒体视频] | |
-- | [入校] | |
-- | [研学] | |
-- | [入校, 电销/网销] | 多服务期 |
-- | [体验营, 入校] | 多服务期 |
-- | [新媒体视频, 入校] | 多服务期 |
-- | NULL | 无服务期 |
