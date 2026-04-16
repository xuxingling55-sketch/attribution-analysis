-- =====================================================
-- 【宏观】活跃-企微添加-拉取入库-转化-月表
-- aws.crm_active_user_wechat_paid_month
-- =====================================================
-- 【表粒度】★必填
--   一个活跃用户一条记录，按 month(int, 如 202603) 分区
--
-- 【业务定位】
--   宏观层面的企微业务月度表：活跃 → 企微添加 → 拉取入库 → 转化
--   不分企微活码渠道，不含中间漏斗环节（无资源位曝光/点击/二维码曝光数据）
--   用于看整体月度企微添加率、拉取入库率、转化情况
--
-- 【与其他企微表的定位区别】
--   | 需求场景                          | 使用表                                  |
--   |----------------------------------|----------------------------------------|
--   | 整体月度企微添加率（不分渠道）       | 本表 aws.crm_active_user_wechat_paid_month |
--   | 分渠道添加量/添加转化               | crm.contact_log + aws.clue_info         |
--   | 渠道活码五层漏斗（定位异常/调优）    | aws.user_pay_process_add_wechat_day/month |
--   | 坐席二维码曝光→添加率              | crm.new_user                            |
--
-- 【用户属性取值时点】
--   所有用户属性取"本月第一次活跃时"的值
--
-- 【转化窗口】
--   截止当月月底
--
-- 【业务术语】→ glossary.md #常规企微业务指标
--
-- 【常用筛选条件】
--   ★必加条件：
--   无
--
--   场景条件：
--   - month 按分区过滤（int 类型，格式 yyyyMM）
-- =====================================================

CREATE TABLE
  `aws`.`crm_active_user_wechat_paid_month` (
    `active_first_date_month` int COMMENT '当月首次活跃日期',
    `user_sk` int COMMENT '用户代理键',
    `active_u_user` string COMMENT '活跃用户id',
    `grade_name_month` string COMMENT '本月第一次活跃当天的年级',
    `stage_name_month` string COMMENT '本月第一次活跃当天的学段',
    `user_pay_status_statistics_month` string COMMENT '本月第一次活跃当天的统计维度：新增、老未、付费的标签',
    `user_pay_status_business_month` string COMMENT '本月第一次活跃当天的策略维度：新用户、老用户、付费用户',
    `business_user_pay_status_statistics_month` string COMMENT '本月第一次活跃当天的统计维度：新增、老未、大会员付费、非大会员付费',
    `business_user_pay_status_business_month` string COMMENT '本月第一次活跃时付费分层-业务维度-拆分付费',
    `is_tele_belong_first_month` int COMMENT '本月第一次活跃时是否归属电销坐席名下',
    `user_allocation_month` array < string > COMMENT '本月第一次活跃时用户服务期归属',
    `add_wechat_u_user` string COMMENT '添加企微用户id，非NULL表示当月有企微添加行为',
    `recieve_u_user` string COMMENT '拉取入库用户id，线索来源=WeCom，非NULL表示当月被拉取入库',
    `recieve_paid_u_user` string COMMENT '截止当月月底拉取入库转化用户id，非NULL表示入库后当月有转化',
    `recieve_paid_amount` double COMMENT '截止当月月底拉取入库转化金额'
  ) COMMENT '【宏观】活跃-企微添加-拉取入库-转化-月表' PARTITIONED BY (`month` int COMMENT '分区字段') ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/crm_active_user_wechat_paid_month' TBLPROPERTIES (
    'bucketing_version' = '2',
    'transient_lastDdlTime' = '1751961367'
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
-- | 启蒙 | 学龄前 |
-- | 小学 | 一年级~六年级 |
-- | 初中 | 七年级~九年级 |
-- | 高中 | 高一~高三 |
-- | 中职 | 职一~职三 |
-- | NULL | 未填写 |
--
-- ## is_tele_belong_first_month（是否归属电销坐席名下）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 1 | 在坐席名下 |
-- | 0 | 不在坐席名下 |
