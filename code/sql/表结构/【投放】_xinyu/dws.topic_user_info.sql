-- =====================================================
-- 用户宽表（按日快照） dws.topic_user_info
-- =====================================================
--
-- 【表粒度】
--   每个用户每个自然日一条记录；`u_user` + `day` 定位一行。
--
-- 【业务定位】
--   按日汇总用户在「统计日当天」的付费分层、VIP/权益、活跃与学习行为、地理与学校、策略标签等宽表字段；用于某日截面分析或日环比对比。
--   与 `dws.topic_user_active_detail_day` 区分：活跃表侧重活跃明细与当日行为；本表侧重**用户状态宽表**，字段更多、分区同为按日。
--
-- 【使用场景】
--   - 某日用户的付费分层（`user_pay_status_*`、`business_user_pay_status_*`，枚举定义 → glossary.md「一、用户分层」）
--   - 某日是否活跃 / VIP / 新用户、学习时长与做题等行为指标
--   - 与业务事件表按 `u_user` 关联时，**必须**同时限定本表 `day`，避免笛卡尔膨胀与全分区扫描
--
-- 【常用关联】
--   - 其他按用户维度的表：`ON info.u_user = x.u_user` **且** `info.day IN (...)` 或单 `day = ${yyyyMMdd}`
--
-- 【常用筛选条件】
--   ★必加条件（任何查询都必须带）：
--   - `day = ${yyyyMMdd}` 或 `day BETWEEN ${start} AND ${end}`  -- 分区裁剪；不带会导致数据量与扫描范围极大
--
--   典型场景条件：
--   - `is_test_user = 0`  -- 排除测试用户（默认分析常用）
--
-- 【注意事项】
--   ⚠️ ORC 分区表，`PARTITIONED BY (day)`，`day` 格式为字符串 `yyyymmdd`（与字段 COMMENT 一致）。
--   ⚠️ 更新频率 T+1。
--   ⚠️ `user_pay_status_*` / `business_user_pay_status_*` 口径以 glossary.md 为准，勿与订单表字段混用含义。
--
-- =====================================================

CREATE TABLE dws.topic_user_info (
    user_sk INT COMMENT '数仓用户sk',
    u_user STRING COMMENT '用户id',
    role STRING COMMENT '身份',
    grade STRING COMMENT '年级',
    stage_name STRING COMMENT '学段',
    gender STRING COMMENT '性别',
    regist_time TIMESTAMP COMMENT '注册时间',
    regist_time_sk INT COMMENT '注册date_sk',
    regist_user_attribution STRING COMMENT '注册当天用户归属',
    active_user_attribution STRING COMMENT '用户归属',
    channel STRING COMMENT '注册渠道',
    u_from STRING COMMENT '系统平台',
    type STRING COMMENT '注册方式(枚举值)',
    regist_entrance_id STRING COMMENT '注册入口',
    city_class STRING COMMENT '城市分线',
    province STRING COMMENT '省',
    province_code STRING COMMENT '省代码',
    city STRING COMMENT '市',
    city_code STRING COMMENT '市代码',
    area STRING COMMENT '地区',
    area_code STRING COMMENT '区',
    region_source STRING COMMENT '区域数据来源',
    school_id STRING COMMENT '学校id',
    school_sk INT COMMENT '学校sk',
    school_id1 STRING COMMENT '学校id',
    school_sk1 INT COMMENT '学校sk1',
    is_test_user INT COMMENT '是否为测试用户',
    is_teach_user INT COMMENT '是否是有教学班用户',
    is_admin_room INT COMMENT '是否为维护班级',
    is_room_user INT COMMENT '是否是有班用户',
    is_new_user INT COMMENT '是否新(当天注册)用户 1是 0否',
    is_active_user INT COMMENT '是否当日活跃',
    is_learn_active_user INT COMMENT '是否当日学习活跃',
    is_vip_user INT COMMENT '是否VIP用户',
    ss_arr ARRAY<STRING> COMMENT '当前的vip的学段学科数组',
    buy_user_vip_status_json STRING COMMENT '已付费用户的权限状态',
    subject_vip_duration_json STRING COMMENT '各个学段学科下的当前权益用户在期时长数组',
    total_order_expired_date_json STRING COMMENT '各个学科过期时间数组',
    recent_active_day INT COMMENT '最近一次访问活跃时间',
    recent_learn_active_day INT COMMENT '最近一次学习活跃时间',
    recent_active_days INT COMMENT '距离上次访问活跃天数',
    recent_learn_active_days INT COMMENT '距离上次学习活跃天数',
    app_use_cnt BIGINT COMMENT 'app使用次数',
    app_use_duration DOUBLE COMMENT 'app使用时长(秒)',
    finish_topic_num BIGINT COMMENT '当天完成知识点个数',
    finish_topic_cnt BIGINT COMMENT '当天完成知识点次数',
    subject_first_order_pay_time_info STRING COMMENT '各个科目首次购买时间',
    subject_full_first_order_pay_time_info STRING COMMENT '各个科目首次正价订单支付时间',
    total_order_buy_type_cnt STRING COMMENT '累计是否购买课程包的正价课和小课（分学段学科统计）',
    total_order_cnt STRING COMMENT '各个科目累计购买次数',
    total_order_amount STRING COMMENT '各个科目累计购买金额',
    pay_amount DOUBLE COMMENT '累计实际支付金额',
    pay_order_cnt INT COMMENT '累计支付订单量',
    max_original_amount DOUBLE COMMENT '累计最大订单原价金额',
    max_amount DOUBLE COMMENT '累计最大订单实付金额',
    min_original_amount DOUBLE COMMENT '累计最小订单原价金额',
    min_amount DOUBLE COMMENT '累计最小订单实付金额',
    remain_coupon_num BIGINT COMMENT '剩余优惠券数',
    expired_coupon_num BIGINT COMMENT '已过期优惠券个数',
    using_coupon_num BIGINT COMMENT '优惠券使用个数',
    trial_coupon_cnt STRING COMMENT '各个类型下的体验券的使用数',
    remain_trial_coupon_cnt STRING COMMENT '各个类型下的体验券的剩余数',
    watch_course_video_num BIGINT COMMENT '课程视频观看个数',
    watch_course_video_cnt BIGINT COMMENT '课程视频观看次数',
    finish_watch_course_video_num BIGINT COMMENT '课程视频完播个数',
    finish_watch_course_video_cnt BIGINT COMMENT '课程视频完播次数',
    serious_watch_course_video_num BIGINT COMMENT '课程视频认真观看个数',
    serious_watch_course_video_cnt BIGINT COMMENT '课程视频认真观看次数',
    watch_course_video_duration BIGINT COMMENT '课程观看视频时长',
    mid_total_exercise_cnt STRING COMMENT '自主学习练习次数',
    mid_finish_total_exercise_cnt STRING COMMENT '自主学习完成练习次数',
    mid_total_exercise_duration STRING COMMENT '自主学习练习时长',
    mid_total_problem_cnt STRING COMMENT '自主学习做题次数',
    mid_total_correct_problem_cnt STRING COMMENT '自主学习题目做对次数',
    mid_total_problem_explain_duration STRING COMMENT '自主学习做题时查看解析时长',
    mid_active_type STRING COMMENT '中学活跃类型',
    user_pay_status_statistics STRING COMMENT '新增/付费/老未(统计口径) 详见glossary',
    user_pay_status_business STRING COMMENT '付费用户/新用户/老用户(业务口径) 详见glossary',
    regist_duration SMALLINT COMMENT '距离注册时间时长（天数）',
    attribution STRING COMMENT '业务中台-用户归属',
    total_watch_duration DOUBLE COMMENT '总观看时长',
    total_watch_cnt DOUBLE COMMENT '总观看次数',
    total_serious_watch_cnt DOUBLE COMMENT '总认真观看次数',
    total_watch_course_duration DOUBLE COMMENT '总课程视频观看时长',
    total_watch_course_cnt DOUBLE COMMENT '总课程视频观看次数',
    total_serious_watch_course_cnt DOUBLE COMMENT '总认真观看课程视频次数',
    school_tag INT COMMENT '用户学校标签',
    total_subject_watch_video_cnt STRING COMMENT '各学科观看视频次数',
    friend_cnt INT COMMENT '用户当天好友个数',
    friend_arry ARRAY<STRING> COMMENT '好友列表-数组',
    is_mid_active_user INT COMMENT '是否中学活跃用户',
    user_nickname STRING COMMENT '昵称',
    onion_coins_cnt DOUBLE COMMENT '洋葱币数量',
    user_level INT COMMENT '等级',
    regist_grade STRING COMMENT '注册时年级',
    is_regist_30day_user SMALLINT COMMENT '注册30天内(含30天) 当前日期-注册日期<=30',
    user_allocation ARRAY<STRING> COMMENT '用户全域服务期',
    user_vip_tag STRING COMMENT '会员身份标签',
    business_user_pay_status_statistics STRING COMMENT '商业化统计口径分层 详见glossary',
    regist_user_allocation ARRAY<STRING> COMMENT '用户注册当天服务期归属',
    business_user_pay_status_business STRING COMMENT '商业化业务口径分层 详见glossary',
    total_active_day_num INT COMMENT '用户累计活跃天数',
    user_risk STRING COMMENT '用户风险',
    is_clue_seat SMALLINT COMMENT '线索是否在坐席名下',
    user_identity STRING COMMENT '用户身份等级 common/advanced/lead/expLead',
    user_lifecycle_stage STRING COMMENT '生命周期阶段 引入期/成长期/成熟期',
    active_recency_status STRING COMMENT '用户近期活跃状态',
    today_active_depth_level STRING COMMENT '今日活跃深度层级',
    real_identity STRING COMMENT '用户真实身份 判断家长见glossary R08',
    is_app_active_user STRING COMMENT '是否app活跃',
    user_strategy_tag_day STRING COMMENT '用户策略标签',
    user_strategy_eligibility_day STRING COMMENT '用户策略资格',
    day STRING COMMENT '分区字段 yyyymmdd'
) USING orc
PARTITIONED BY (day)
COMMENT '每个用户每天保存一条数据'
TBLPROPERTIES (
    'alias' = '用户宽表数据',
    'bucketing_version' = '2',
    'is_core' = 'true',
    'last_modified_by' = 'huaxiong',
    'last_modified_time' = '1763109430',
    'transient_lastDdlTime' = '1767952904'
);

-- =====================================================
-- 枚举值（节选；分层类字段完整定义见 glossary.md「一、用户分层」）
-- =====================================================
--
-- ## user_identity（用户身份等级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | common | 研究员 |
-- | advanced | 高级研究员 |
-- | lead | 首席研究员 |
-- | expLead | 体验版首席研究员 |
--
-- ## user_lifecycle_stage（生命周期阶段）
--
-- | 阶段 | 含义（注册天数从注册当天计为0） |
-- |------|----------------------------------|
-- | 引入期 | 注册天数 <= 13 |
-- | 成长期 | 14 <= 注册天数 <= 30 |
-- | 成熟期 | 注册天数 >= 31 |
--
-- ## is_test_user / is_new_user / is_active_user / is_vip_user / is_learn_active_user（常用 0/1）
--
-- | 值 | 含义 |
-- |----|------|
-- | 0 | 否 |
-- | 1 | 是 |
--
-- ## user_pay_status_statistics / user_pay_status_business / business_user_pay_status_statistics / business_user_pay_status_business
--
-- > 完整枚举与定义 → glossary.md「一、用户分层」字段1～4；默认业务分层字段为 `business_user_pay_status_business`。
