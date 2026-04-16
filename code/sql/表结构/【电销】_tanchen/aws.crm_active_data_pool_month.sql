-- =====================================================
-- C端活跃用户推送公海池触发漏斗月表 aws.crm_active_data_pool_month
-- =====================================================
-- 【表粒度】★必填
--   一个用户一条记录，按 month(int, 如 202603) 分区
--   月维度数据：由日表 aws.crm_active_data_pool_day 按月聚合而来
--
-- 【业务定位】
--   电话线索（系统线索）的月度漏斗表，追踪 活跃→推送→入库→领取 四层漏斗
--   漏斗术语定义（活跃量/推送量/入库量/入库领取量/活跃领取量）→ glossary.md #电话线索漏斗指标
--
-- 【数据来源】
--   aws.crm_active_data_pool_day  —— 日表按月聚合，提供漏斗数据 + 用户属性
--   dw.fact_telesale_clue_day     —— 公海池拒绝原因（deny_reason / deny_index）
--   dw.fact_clue_allocate_info    —— 坐席领取信息（含线索来源 clue_source，用于区分两个领取口径）
--   线索领取表说明：dw.fact_clue_allocate_info 为线索领取底层表；aws.clue_info 为数仓加工后的线索领取表，BI 取数常用。
--
-- 【属性取值时点】（月维度特有逻辑）
--   用户统计属性（月末值）：grade、mid_stage_name、gender、active_user_attribution、
--                          attribution、u_from、regist_os、city_class、省市区、real_identity
--     → 取当月最后一天的数据（按 DAY DESC 排序取第一条）
--   业务状态属性（月初值）：user_pay_status_*、business_user_pay_status_*、
--                          mid_active_type、user_allocation、phone_range、level、before_sum_amount
--     → 取当月第一天的数据（按 DAY ASC 排序取第一条）
--
-- 【常用筛选条件】
--   ★必加条件：
--   无
--
--   场景条件：
--   - month 按分区过滤（int 类型，格式 yyyyMM）
-- =====================================================

CREATE TABLE
  `aws`.`crm_active_data_pool_month` (
    `active_u_user` string COMMENT '当月活跃用户ID',
    `push_u_user` string COMMENT '当月被数仓推送到电销的用户',
    `enter_datapool_u_user` string COMMENT '当月通过公海池过滤规则并进入公海池的用户',
    `recieve_u_user` string COMMENT '【当月被坐席从公海池领取的用户',
    `grade` string COMMENT '【月末值】年级',
    `mid_stage_name` string COMMENT '【月末值】中学修正学段',
    `gender` string COMMENT '【月末值】性别',
    `active_user_attribution` string COMMENT '【月末值】用户活跃时归属（中学用户/小学用户/c）',
    `attribution` string COMMENT '【月末值】用户归属',
    `u_from` string COMMENT '【月末值】系统平台',
    `regist_os` string COMMENT '【月末值】操作系统',
    `city_class` string COMMENT '【月末值】用户城市分线',
    `province` string COMMENT '【月末值】省名称',
    `province_code` string COMMENT '【月末值】省code',
    `city` string COMMENT '【月末值】市名称',
    `city_code` string COMMENT '【月末值】市code',
    `area` string COMMENT '【月末值】区名称',
    `area_code` string COMMENT '【月末值】区code',
    `real_identity` string COMMENT '【月末值】用户真实身份',
    `user_pay_status_statistics` string COMMENT '【月初值】统计维度付费状态：新增、老未、付费',
    `user_pay_status_business` string COMMENT '【月初值】业务维度付费状态：新用户、老用户、付费用户',
    `business_user_pay_status_statistics` string COMMENT '【月初值】商业化统计维度：高净值用户、续费用户、新增、老未',
    `business_user_pay_status_business` string COMMENT '【月初值】商业化业务维度：高净值用户、续费用户、新用户、老用户',
    `mid_active_type` string COMMENT '【月初值】活跃类型（新增/回流/持续）',
    `user_allocation` array < string > COMMENT '【月初值】用户全域服务期，如["电销/网销"]',
    `phone_range` string COMMENT '【月初值】用户号段（手机号前3位）',
    `level` int COMMENT '【月初值】用户星阶等级',
    `regist_time` timestamp COMMENT '注册时间',
    `user_attribution` string COMMENT '用户注册当天归属',
    `channel` string COMMENT '注册渠道',
    `regist_app_version` string COMMENT '注册时的app版本号',
    `regist_type` string COMMENT '注册方式',
    `regist_duration` int COMMENT '注册时长（天），距注册日的天数，取当月最小值',
    `first_deny_reason` string COMMENT '当月首次被公海池过滤规则拒绝的原因文本（按 created_at 排序取第一条），空字符串表示未被拒绝',
    `first_deny_index` smallint COMMENT '当月首次被公海池拒绝的编号（0表示未被拒绝）',
    `deny_index_reason_arr` array < string > COMMENT '当月所有被拒绝的编号去重排序数组（仅含 deny_index > 0 的记录）',
    `push_cnt` smallint COMMENT '当月累计被推送的次数',
    `datepool_cnt` smallint COMMENT '当月累计进入公海池的次数',
    `all_user_clue_cnt` int COMMENT '截止活跃日期前，用户历史累计被销售领取的总次数',
    `all_add_wechat_cnt` int COMMENT '截止活跃日期前，用户历史累计添加过企微的总次数',
    `before_sum_amount` double COMMENT '【月初值】截止活跃前一天，用户历史累计成功付费金额',
    `recieve_u_user_all` string COMMENT '【活跃领取量】当月被坐席领取的用户，不限线索来源（含mid_school、WeCom等所有渠道），不限是否经过公海池'
  ) COMMENT '一个用户一条记录' PARTITIONED BY (`month` int) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/crm_active_data_pool_month' TBLPROPERTIES (
    'alias' = 'C端活跃用户推送公海池触发漏斗月表',
    'bucketing_version' = '2',
    'last_modified_by' = 'finebi',
    'last_modified_time' = '1734489163',
    'transient_lastDdlTime' = '1734489163'
  )

-- =====================================================
-- 枚举值
-- =====================================================
-- ## grade（年级）
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
--
-- ## mid_stage_name（中学修正学段）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 启蒙 | |
-- | 小学 | |
-- | 初中 | |
-- | 高中 | |
-- | 中职 | |
-- | NULL | 未填写 |
--
-- ## gender（性别）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | male | 男 |
-- | female | 女 |
--
-- ## active_user_attribution（用户活跃时归属）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | c | C端用户 |
-- | b | B端用户 |
--
-- ## city_class（城市分线）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 一线 | |
-- | 二线 | |
-- | 三线 | |
-- | 四线 | |
-- | 五线 | |
-- | NULL | 未填写 |
--
-- ## real_identity（用户真实身份）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | student | 学生 |
-- | parents | 家长 |
-- | student_parents | 学生家长共用 |
-- | teacher | 老师 |
-- | NULL | 未填写 |
--
-- ## user_attribution（用户注册当天归属）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | c | C端用户 |
-- | b | B端用户 |
-- | 中学用户 | C端用户 |
-- | 小学用户 | C端用户 |
-- | B端用户 | B端用户 |
-- | NULL | 未填写 |
--
-- ## u_from（系统平台）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | android | 安卓 |
-- | ios | iOS |
-- | pc | PC端 |
-- | mobile | 移动端 |
-- | h5 | H5页面 |
-- | applet | 小程序 |
-- | harmony | 鸿蒙 |
-- | windows | Windows |
-- | shadow | |
-- | teacher-android | 教师端-安卓 |
-- | teacher-ios | 教师端-iOS |
-- | O5-android | |
-- | 06-android | |
-- | other | 其他 |
--
-- ## regist_os（操作系统）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | android | 安卓 |
-- | ios | iOS |
-- | pc | PC端 |
-- | mobile | 移动端 |
-- | h5 | H5页面 |
-- | applet | 小程序 |
-- | harmony | 鸿蒙 |
-- | windows | Windows |
-- | shadow | |
-- | teacher-android | 教师端-安卓 |
-- | teacher-ios | 教师端-iOS |
-- | O5-android | |
-- | 06-android | |
-- | other | 其他 |
--
-- ## regist_type（注册方式）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | signup | 自主注册 |
-- | batch | 批量导入 |
-- | weixin | 微信 |
-- | qq | QQ |
-- | ios | iOS |
-- | huawei | 华为 |
-- | oppo | OPPO |
-- | bubugao | 步步高 |
-- | youxuepai | 优学派 |
-- | dushulang | 读书郎 |
-- | dawan | 大碗 |
-- | telesale-mp | 电销小程序 |
-- | quickRegister | 快捷注册 |
-- | parentApplet | 家长端小程序 |
-- | newParentApplet | |
-- | ParentHBShop | |
-- | channel-platform | |
