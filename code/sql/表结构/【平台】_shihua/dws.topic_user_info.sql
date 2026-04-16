-- =====================================================
-- 公用- 用户宽表 dws.topic_user_info
-- =====================================================
--
-- 【表粒度】
--   一用户一天一行（用户主题累计画像；分区字段：day）
--
-- 【业务定位】
--   - 【归属】公用 / 用户宽表。
--   - 用户宽表、累计订单/VIP JSON 等主题字段；与 dw.dim_user 可按 u_user 对齐
--
-- 【统计口径】
--   见字段 COMMENT；与 dw.dim_user 口径一致
--
-- 【常用关联】
--   - 看板「活动专题-202603开学季活动_1_分层转化」：from dws.topic_user_info 作 CTE；与 active_shuxing / act_user_shuxing / zuhepin_user 等 CTE 间有 `left join` / `right join`（见该看板 SQL）
--
-- 【常用筛选条件】
--   场景条件：
--   - is_test_user 等按需求
--
-- 【注意事项】
--   - 更新频率 T+1（以调度为准）
--   - 知识库约定：取数与分析仅使用 business_user_pay_status_*；user_pay_status_*（无 business_ 前缀）列不在知识库维护口径，列仍可能存在于线上表

CREATE TABLE
  `dws`.`topic_user_info` (
    `user_sk` int COMMENT '数仓用户sk',
    `u_user` string COMMENT '用户id',
    `role` string COMMENT '身份',
    `grade` string COMMENT '年级',
    `stage_name` string COMMENT '学段',
    `gender` string COMMENT '性别',
    `regist_time` timestamp COMMENT '注册时间',
    `regist_time_sk` int COMMENT '注册date_sk',
    `regist_user_attribution` string COMMENT '注册当天用户归属',
    `active_user_attribution` string COMMENT '用户归属',
    `channel` string COMMENT '注册渠道',
    `u_from` string COMMENT '系统平台',
    `type` string COMMENT '注册方式(枚举值)',
    `regist_entrance_id` string COMMENT '注册入口',
    `city_class` string COMMENT '城市分线',
    `province` string COMMENT '省',
    `province_code` string COMMENT '省代码',
    `city` string COMMENT '市',
    `city_code` string COMMENT '市代码',
    `area` string COMMENT '地区',
    `area_code` string COMMENT '区',
    `region_source` string COMMENT '区域数据来源',
    `school_id` string COMMENT '学校id',
    `school_sk` int COMMENT '学校sk',
    `school_id1` string COMMENT '学校id',
    `school_sk1` int COMMENT '学校sk1',
    `is_test_user` int COMMENT '是否为测试用户',
    `is_teach_user` int COMMENT '是否是有教学班用户',
    `is_admin_room` int COMMENT '是否为维护班级',
    `is_room_user` int COMMENT '是否是有班用户',
    `is_new_user` int COMMENT '是否新(当天注册)用户（1:是，0:否）',
    `is_active_user` int COMMENT '是否当日活跃',
    `is_learn_active_user` int COMMENT '是否当日学习活跃',
    `is_vip_user` int COMMENT '是否VIP用户',
    `ss_arr` array < string > COMMENT '当前的vip的学段学科数组',
    `buy_user_vip_status_json` string COMMENT '已付费用户的权限状态',
    `subject_vip_duration_json` string COMMENT '各个学段学科下的当前权益用户在期时长数组',
    `total_order_expired_date_json` string COMMENT '各个学科过期时间数组',
    `recent_active_day` int COMMENT '最近一次访问活跃时间',
    `recent_learn_active_day` int COMMENT '最近一次学习活跃时间',
    `recent_active_days` int COMMENT '距离上次访问活跃天数',
    `recent_learn_active_days` int COMMENT '距离上次学习活跃天数',
    `app_use_cnt` bigint COMMENT 'app使用次数',
    `app_use_duration` double COMMENT 'app使用时长(秒)',
    `finish_topic_num` bigint COMMENT '当天完成知识点个数',
    `finish_topic_cnt` bigint COMMENT '当天完成知识点次数',
    `subject_first_order_pay_time_info` string COMMENT '各个科目首次购买时间',
    `subject_full_first_order_pay_time_info` string COMMENT '各个科目首次正价订单支付时间',
    `total_order_buy_type_cnt` string COMMENT '累计是否购买课程包的正价课和小课（分学段学科统计）',
    `total_order_cnt` string COMMENT '各个科目累计购买次数',
    `total_order_amount` string COMMENT '各个科目累计购买金额',
    `pay_amount` double COMMENT '累计实际支付金额',
    `pay_order_cnt` int COMMENT '累计支付订单量',
    `max_original_amount` double COMMENT '累计最大订单原价金额',
    `max_amount` double COMMENT '累计最大订单实付金额',
    `min_original_amount` double COMMENT '累计最小订单原价金额',
    `min_amount` double COMMENT '累计最小订单实付金额',
    `remain_coupon_num` bigint COMMENT '剩余优惠券数',
    `expired_coupon_num` bigint COMMENT '已过期优惠券个数',
    `using_coupon_num` bigint COMMENT '优惠券使用个数',
    `trial_coupon_cnt` string COMMENT '各个类型下的体验券的使用数',
    `remain_trial_coupon_cnt` string COMMENT '各个类型下的体验券的剩余数',
    `watch_course_video_num` bigint COMMENT '课程视频观看个数',
    `watch_course_video_cnt` bigint COMMENT '课程视频观看次数',
    `finish_watch_course_video_num` bigint COMMENT '课程视频完播个数',
    `finish_watch_course_video_cnt` bigint COMMENT '课程视频完播次数',
    `serious_watch_course_video_num` bigint COMMENT '课程视频认真观看个数',
    `serious_watch_course_video_cnt` bigint COMMENT '课程视频认真观看次数',
    `watch_course_video_duration` bigint COMMENT '课程观看视频时长',
    `mid_total_exercise_cnt` string COMMENT '自主学习练习次数',
    `mid_finish_total_exercise_cnt` string COMMENT '自主学习完成练习次数',
    `mid_total_exercise_duration` string COMMENT '自主学习练习时长',
    `mid_total_problem_cnt` string COMMENT '自主学习做题次数',
    `mid_total_correct_problem_cnt` string COMMENT '自主学习题目做对次数',
    `mid_total_problem_explain_duration` string COMMENT '自主学习做题时查看解析时长',
    `mid_active_type` string COMMENT '中学活跃类型',
 `user_pay_status_statistics` string COMMENT '【知识库不引用】取数用 business_user_pay_status_statistics。原：新增(统计日期当天注册的)、付费(统计日期之前买过正价课)、老未(统计日期之前注册的)',
 `user_pay_status_business` string COMMENT '【知识库不引用】取数用 business_user_pay_status_business。原：付费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)',
    `regist_duration` smallint COMMENT '距离注册时间时长（天数）',
    `attribution` string COMMENT '业务中台-用户归属',
    `total_watch_duration` double COMMENT '总观看时长',
    `total_watch_cnt` double COMMENT '总观看次数',
    `total_serious_watch_cnt` double COMMENT '总认真观看次数',
    `total_watch_course_duration` double COMMENT '总课程视频观看时长',
    `total_watch_course_cnt` double COMMENT '总课程视频观看次数',
    `total_serious_watch_course_cnt` double COMMENT '总认真观看课程视频次数',
    `school_tag` int COMMENT '用户学校标签',
    `total_subject_watch_video_cnt` string COMMENT '各学科观看视频次数',
    `friend_cnt` int COMMENT '用户当天好友个数',
    `friend_arry` array < string > COMMENT '好友列表-数组',
    `is_mid_active_user` int COMMENT '是否中学活跃用户',
    `user_nickname` string COMMENT '昵称',
    `onion_coins_cnt` double COMMENT '洋葱币数量',
    `user_level` int COMMENT '等级',
    `regist_grade` string COMMENT '注册时年级',
    `is_regist_30day_user` smallint COMMENT '用户注册30天内， 包含30天。当前日期-注册日期<=30',
    `user_allocation` array < string > COMMENT '用户全域服务期',
    `user_vip_tag` string COMMENT '会员身份标签',
 `business_user_pay_status_statistics` string COMMENT '新增(统计日期当天注册的)、高净值用户(统计日期之前方案型商品 不包括"商品二级分类id=[一年积木块]id、[体验机]id、[到期型培优课积木块]id)、续费用户(统计日期之前买过正价课)、老未(统计日期之前注册的)',
    `regist_user_allocation` array < string > COMMENT '用户注册当天服务期归属',
 `business_user_pay_status_business` string COMMENT '高净值用户(统计日期之前方案型商品 不包括"商品二级分类id=[一年积木块]id、[体验机]id、[到期型培优课积木块]id)、续费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)',
    `total_active_day_num` int COMMENT '用户累计活跃天数',
    `user_risk` string COMMENT '用户风险',
    `is_clue_seat` smallint COMMENT '线索是否在坐席名下',
    `user_identity` string COMMENT '用户身份：研究员：common，高级研究员：advanced，首席研究员：lead，体验版首席研究员：expLead',
    `user_lifecycle_stage` string COMMENT '生命周期阶段  引入期：注册天数 <= 13 （注册当天是0）成长期：14 <= 注册天数 <= 30 成熟期：注册天数31天及以上',
    `active_recency_status` string COMMENT ' 用户近期活跃状态',
    `today_active_depth_level` string COMMENT '今日活跃深度层级',
    `real_identity` string COMMENT '用户真实身',
    `is_app_active_user` string COMMENT '是否app活跃',
    `user_strategy_tag_day` string COMMENT '用户策略标签',
    `user_strategy_eligibility_day` string COMMENT '用户策略资格'
 ) COMMENT '每个用户每天保存一条数据' PARTITIONED BY (`day` string COMMENT '分区字段yyyymmdd') ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dws.db/topic_user_info'

-- =====================================================
-- 枚举值
-- =====================================================
--
-- > 以下取值为线上 `SELECT DISTINCT <字段> FROM dws.topic_user_info WHERE day = '20260325'` 结果（单分区快照，全表 DISTINCT 较慢；历史曾出现值若不在本列表，以实际查询为准）。
--
-- ## grade（年级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 学龄前 |学龄前 |
-- | 一年级 |一年级 |
-- | 二年级 |二年级 |
-- | 三年级 |三年级 |
-- | 四年级 |四年级 |
-- | 五年级 |五年级 |
-- | 六年级 |六年级 |
-- | 七年级 |七年级 |
-- | 八年级 |八年级 |
-- | 九年级 |九年级 |
-- | 高一 |高一 |
-- | 高二 |高二 |
-- | 高三 |高三 |
-- | 职一 |职一 |
-- | 职二 |职二 |
-- | 职三 |职三 |
-- | NULL |未归类 |
--
-- ## stage_name（学段）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 启蒙 |启蒙 |
-- | 小学 |小学 |
-- | 初中 |初中 |
-- | 高中 |高中 |
-- | 中职 |中职 |
-- | NULL |未归类 |
--
-- ## city_class（城市分线）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 一线 |一线 |
-- | 二线 |二线 |
-- | 三线 |三线 |
-- | 四线 |四线 |
-- | 五线 |五线 |
-- | NULL |未归类 |
--
-- ## attribution（业务中台-用户归属）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL |未归类 |
-- | b | b端用户，智课团队的用户 |
-- | c | c端用户，非智课团队的用户 |
--
-- ## business_user_pay_status_statistics（商业化+统计分层）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 新增 |新增 |
-- | 续费用户 |续费用户 |
-- | 老未 |老未 |
-- | 高净值用户 |高净值用户 |
--
-- ## business_user_pay_status_business（商业化+业务分层）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 新用户 |新用户 |
-- | 续费用户 |续费用户 |
-- | 老用户 |老用户 |
-- | 高净值用户 |高净值用户 |
--
-- ## user_strategy_tag_day（策略用户分层-日）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 付费加购品用户 |付费加购品用户 |
-- | 付费组合品用户 |付费组合品用户 |
-- | 付费零售品用户 |付费零售品用户 |
-- | 历史大会员用户_不可续购 |历史大会员用户_不可续购 |
-- | 历史大会员用户_可续购 |历史大会员用户_可续购 |
-- | 新用户 |新用户 |
-- | 老用户 |老用户 |
--
-- ## user_strategy_eligibility_day（用户策略资格-日）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | (空字符串) |无策略资格 |
-- | 历史大会员续购策略资格;学习机加购策略资格 |历史大会员续购策略资格;学习机加购策略资格 |
-- | 历史大会员续购策略资格;学习机加购策略资格;小学品升级补差至小初品资格 |历史大会员续购策略资格;学习机加购策略资格;小学品升级补差至小初品资格 |
-- | 学习机加购策略资格;高中囤课策略资格 |学习机加购策略资格;高中囤课策略资格 |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版 |学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版 |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 |学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 |学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格 |学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格 |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版 |学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版 |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 |学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 |学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格 |学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格 |
-- | 学习机加购策略资格;高中囤课策略资格;小学品升级补差至小初品资格 |学习机加购策略资格;高中囤课策略资格;小学品升级补差至小初品资格 |
-- | 小初同步品升级补差至小初品资格 |小初同步品升级补差至小初品资格 |
-- | 小学品升级补差至小初品资格 |小学品升级补差至小初品资格 |
-- | NULL |未归类 |
