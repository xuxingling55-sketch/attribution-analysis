-- =====================================================
-- 用户活跃月表 dws.topic_user_active_detail_month
-- =====================================================

-- =====================================================
-- 【表粒度】
--   用户 + 下载渠道 + 产品 + 活跃端口 + 设备 = 一条记录（与日表相同粒度）
--   分区字段：month（int 类型，格式 yyyyMM）

--
-- =====================================================

-- =====================================================
-- 【统计口径】
--   月活用户数 = COUNT(DISTINCT u_user)
--   学习活跃月活 = COUNT(DISTINCT CASE WHEN learn_active_cnt > 0 THEN u_user END)
--   注意：业务指标的权威定义在 glossary.md，本段仅记录"用本表怎么算"

--
-- =====================================================

-- =====================================================
-- 【常用关联】
--   活跃转化分析：
--     本表.u_user = dws.topic_order_detail.u_user（关联全公司订单表计算转化率）

--
-- =====================================================

-- =====================================================
-- 【常用筛选条件】
--   ★必加条件（默认看 C 端活跃）：
--   - product_id = '01'                                     -- 洋葱学园主站
--   - client_os IN ('android', 'ios', 'harmony')            -- 移动端
--   - active_user_attribution IN ('中学用户', '小学用户', 'c') -- C 端用户
--
--   场景条件：
--   - month 按分区过滤（int 类型，格式 yyyyMM）

-- =====================================================

-- =====================================================
-- 【注意事项】

--
--   ⚠️ 活跃层级（门槛从低到高）：
--     1. 活跃(active_cnt > 0)：打开 APP 即算活跃
--     2. 学习活跃(learn_active_cnt > 0)：触发知识点完成页，仅看视频退出不算
--
--   ⚠️ user_allocation 字段：用户全域服务期
--     · 包含"电销" → 电销服务期（如["电销/网销"]）
--     · 不含"电销" → 非电销服务期（如["体验营"]、["入校"]）
--     · NULL 或空数组 → 无服务期
--
--   ⚠️ 属性取值时点：当月第一次活跃时的值
--
--
--   ⚠️ is_learn_active_user 区分"学习活跃"与"普通活跃"：
--     · 普通活跃：打开 APP 即算（不加此过滤），日活统计默认用普通活跃
--     · 学习活跃：需有学习行为（加 is_learn_active_user = 1）
--
-- =====================================================

CREATE TABLE
  `dws`.`topic_user_active_detail_month` (
    `u_user` string COMMENT '用户id',
    `user_sk` int COMMENT '数仓用户sk',
    `grade` string COMMENT '年级',
    `stage_name` string COMMENT '学段',
    `role` string COMMENT '身份',
    `is_parents` boolean COMMENT '是否家长',
    `gender` string COMMENT '性别',
    `regist_time` timestamp COMMENT '注册时间',
    `u_from` string COMMENT '系统平台',
    `channel` string COMMENT '注册渠道',
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
    `real_school_id` string COMMENT '学校id',
    `is_teach_user` smallint COMMENT '是否是有教学班用户',
    `is_room_user` smallint COMMENT '是否是有班用户',
    `is_new_user` smallint COMMENT '是否是本月新增用户',
    `is_vip_user` smallint COMMENT '是否是vip用户',
    `level` int COMMENT '等级',
    `regist_user_allocation` array < string > COMMENT '用户注册当天服务期归属',
    `business_user_pay_status_statistics` string COMMENT '付费标签：商业化统计维度口径（详见文件末尾枚举值）',
    `business_user_pay_status_business` string COMMENT '付费标签：商业化业务维度口径 ⭐默认字段（详见文件末尾枚举值）',
    `active_user_attribution` string COMMENT '用户活跃时归属（★必加条件：中学用户/小学用户/c 为C端，详见文件末尾枚举值）',
    `user_allocation` array < string > COMMENT '用户全域服务期，枚举值：电销/网销、体验营、入校、新媒体视频。包含"电销"为电销服务期，其他为非电销服务期，NULL为无服务期',
    `user_vip_tag` string COMMENT '会员身份标签',
    `download_channel` string COMMENT '下载渠道',
    `product_id` string COMMENT '产品ID（★必加条件：= 01 为主站）',
    `client_os` string COMMENT '用户活跃的os（★必加条件：android/ios/harmony 为移动端）',
    `d_model_brand` string COMMENT '手机品牌',
    `d_model_name` string COMMENT '手机型号',
    `sn_code` string COMMENT 'sn_code',
    `learn_active_cnt` int COMMENT '学习活跃次数。来源：dw.fact_user_learn_active_detail_day。判断逻辑：用户触发知识点完成页才算学习活跃，仅看视频退出不计入',
    `active_cnt` int COMMENT '活跃次数。判断逻辑：打开APP即算活跃，门槛低于学习活跃',
    `topic_finish_cnt` int COMMENT '完成知识点次数',
    `app_use_duration` int COMMENT 'app使用时长',
    `app_user_cnt` int COMMENT 'app使用次数',
    `watch_course_video_cnt` int COMMENT '观看课程视频次数',
    `serious_watch_course_video_cnt` int COMMENT '认真观看课程视频次数',
    `finish_watch_course_video_cnt` int COMMENT '完成观看课程视频次数',
    `watch_course_video_duration` int COMMENT '观看课程视频时长',
    `total_exercise_cnt` int COMMENT '所有模块练习次数',
    `total_exercise_finish_cnt` int COMMENT '所有模块练习完成次数',
    `total_problem_cnt` int COMMENT '所有模块练习完成次数',
    `total_exercise_duration` double COMMENT '练习时长',
    `total_problem_duration` double COMMENT '做题目的时长',
    `total_regist_days` int COMMENT '累计注册天数',
    `sub_amount` double COMMENT '统计周期付费金额',
    `order_cnt` int COMMENT '统计周期付费次数',
    `d_app_version` string COMMENT '统计周期最后一次活跃app版本',
    `d_os_version` string COMMENT '统计周期最后一次活跃手机系统版本',
    `active_day_cnt` int COMMENT '统计周期活跃天数',
    `not_deal_cnt` int COMMENT '统计周期电销打电话次数-未接通',
    `dealing_cnt` int COMMENT '统计周期电销打电话次数-已接通',
    `customer_leak_cnt` int COMMENT '统计周期电销打电话次数-用户放弃',
    `agent_leak_cnt` int COMMENT '统计周期电销打电话次数-坐席放弃 ',
    `black_list_cnt` int COMMENT '统计周期电销打电话次数-外呼异常',
    `enter_chapter_list_cnt` int COMMENT '统计周期进入章节列表页面次数',
    `enter_payment_page_cnt` int COMMENT '统计周期进入付费落地页次数',
    `click_discovery_cnt` int COMMENT '统计周期点击宝藏tab次数',
    `click_learn_cnt` int COMMENT '统计周期点击学习tab次数',
    `click_learn_together_cnt` int COMMENT '统计周期点击共学tab次数',
    `click_growup_cnt` int COMMENT '统计周期点击成长tab次数',
    `click_myzone_cnt` int COMMENT '统计周期点击我的tab次数',
    `click_operate_cnt` int COMMENT '触发资源位次数',
    `user_identity` string COMMENT '用户身份：研究员：common，高级研究员：advanced，首席研究员：lead，体验版首席研究员：expLead',
    `user_strategy_tag_month` string COMMENT '用户策略标签',
    `user_strategy_eligibility_month` string COMMENT '用户策略资格',
    `mid_stage_name` string COMMENT '中学修正学段（详见文件末尾枚举值）',
    `user_pay_status_statistics` string COMMENT '付费标签：统计维度口径（详见文件末尾枚举值）',
    `user_pay_status_business` string COMMENT '付费标签：业务维度口径（详见文件末尾枚举值）'
  ) COMMENT '一个用户一个下载渠道一个产品id一个活跃端口一个手机品牌一个手机型号一个sn_code一条记录https://guanghe.feishu.cn/sheets/IMQ5sYxhyhVUrItjifvcFmnInoe?sheet=a6d7e6' PARTITIONED BY (`month` int) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dws.db/topic_user_active_detail_month' TBLPROPERTIES (
    'alias' = '用户活跃月表汇总',
    'bucketing_version' = '2',
    'last_modified_by' = 'huaxiong',
    'last_modified_time' = '1768818963',
    'spark.sql.create.version' = '2.2 or prior',
    'spark.sql.sources.schema.numPartCols' = '1',
    'spark.sql.sources.schema.numParts' = '2',
    'spark.sql.sources.schema.part.0' = '{"type":"struct","fields":[{"name":"u_user","type":"string","nullable":true,"metadata":{"comment":"用户id"}},{"name":"user_sk","type":"integer","nullable":true,"metadata":{"comment":"数仓用户sk"}},{"name":"grade","type":"string","nullable":true,"metadata":{"comment":"年级"}},{"name":"stage_name","type":"string","nullable":true,"metadata":{"comment":"学段"}},{"name":"role","type":"string","nullable":true,"metadata":{"comment":"身份"}},{"name":"is_parents","type":"boolean","nullable":true,"metadata":{"comment":"是否家长"}},{"name":"gender","type":"string","nullable":true,"metadata":{"comment":"性别"}},{"name":"regist_time","type":"timestamp","nullable":true,"metadata":{"comment":"注册时间"}},{"name":"u_from","type":"string","nullable":true,"metadata":{"comment":"系统平台"}},{"name":"channel","type":"string","nullable":true,"metadata":{"comment":"注册渠道"}},{"name":"type","type":"string","nullable":true,"metadata":{"comment":"注册方式(枚举值)"}},{"name":"regist_entrance_id","type":"string","nullable":true,"metadata":{"comment":"注册入口"}},{"name":"city_class","type":"string","nullable":true,"metadata":{"comment":"城市分线"}},{"name":"province","type":"string","nullable":true,"metadata":{"comment":"省"}},{"name":"province_code","type":"string","nullable":true,"metadata":{"comment":"省代码"}},{"name":"city","type":"string","nullable":true,"metadata":{"comment":"市"}},{"name":"city_code","type":"string","nullable":true,"metadata":{"comment":"市代码"}},{"name":"area","type":"string","nullable":true,"metadata":{"comment":"地区"}},{"name":"area_code","type":"string","nullable":true,"metadata":{"comment":"区"}},{"name":"region_source","type":"string","nullable":true,"metadata":{"comment":"区域数据来源"}},{"name":"real_school_id","type":"string","nullable":true,"metadata":{"comment":"学校id"}},{"name":"is_teach_user","type":"short","nullable":true,"metadata":{"comment":"是否是有教学班用户"}},{"name":"is_room_user","type":"short","nullable":true,"metadata":{"comment":"是否是有班用户"}},{"name":"is_new_user","type":"short","nullable":true,"metadata":{"comment":"是否是本月新增用户"}},{"name":"is_vip_user","type":"short","nullable":true,"metadata":{"comment":"是否是vip用户"}},{"name":"level","type":"integer","nullable":true,"metadata":{"comment":"等级"}},{"name":"regist_user_allocation","type":{"type":"array","elementType":"string","containsNull":true},"nullable":true,"metadata":{"comment":"用户注册当天服务期归属"}},{"name":"business_user_pay_status_statistics","type":"string","nullable":true,"metadata":{"comment":"新增(统计日期当天注册的)、大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、老未(统计日期之前注册的)"}},{"name":"business_user_pay_status_business","type":"string","nullable":true,"metadata":{"comment":"大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)"}},{"name":"active_user_attribution","type":"string","nullable":true,"metadata":{"comment":"用户活跃时归属"}},{"name":"user_allocation","type":{"type":"array","elementType":"string","containsNull":true},"nullable":true,"metadata":{"comment":"用户全域服务期"}},{"name":"user_vip_tag","type":"string","nullable":true,"metadata":{"comment":"会员身份标签"}},{"name":"download_channel","type":"string","nullable":true,"metadata":{"comment":"下载渠道"}},{"name":"product_id","type":"string","nullable":true,"metadata":{"comment":"产品ID"}},{"name":"client_os","type":"string","nullable":true,"metadata":{"comment":"用户活跃的os"}},{"name":"d_model_brand","type":"string","nullable":true,"metadata":{"comment":"手机品牌"}},{"name":"d_model_name","type":"string","nullable":true,"metadata":{"comment":"手机型号"}},{"name":"sn_code","type":"string","nullable":true,"metadata":{"comment":"sn_code"}},{"name":"learn_active_cnt","type":"integer","nullable":true,"metadata":{"comment":"学习活跃次数"}},{"name":"active_cnt","type":"integer","nullable":true,"metadata":{"comment":"活跃次数"}},{"name":"topic_finish_cnt","type":"integer","nullable":true,"metadata":{"comment":"完成知识点次数"}},{"name":"app_use_duration","type":"integer","nullable":true,"metadata":{"comment":"app使用时长"}},{"name":"app_user_cnt","type":"integer","nullable":true,"metadata":{"comment":"app使用次数"}},{"name":"watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"观看课程视频次数"}},{"name":"serious_watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"认真观看课程视频次数"}},{"name":"finish_watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"完成观看课程视频次数"}},{"name":"watch_course_video_duration","type":"integer","nullable":true,"metadata":{"comment":"观看课程视频时长"}},{"name":"total_exercise_cnt","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习次数"}},{"name":"total_exercise_finish_cnt","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习完成次数"}},{"name":"total_problem_cnt","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习完成次数"}},{"name":"total_exercise_duration","type":"double","nullable":true,"metadata":{"comment":"练习时长"}},{"name":"total_problem_duration","type":"double","nullable":true,"metadata":{"comment":"做题目的时长"}},{"name":"total_regist_days","type":"integer","nullable":true,"metadata":{"comment":"累计注册天数"}},{"name":"sub_amount","type":"double","nullable":true,"metadata":{"comment":"统计周期付费金额"}},{"name":"order_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期付费次数"}},{"name":"d_app_version","type":"string","nullable":true,"metadata":{"comment":"统计周期最后一次活跃app版本"}},{"name":"d_os_version","type":"string","nullable":true,"metadata":{"comment":"统计周期最后一次活跃手机系统版本"}},{"name":"active_day_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期活跃天数"}},{"name":"not_deal_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期电销打电话次数-未接通"}},{"name":"dealing_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期电销打电话次数-已接通"}},{"name":"customer_leak_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期电销打电话次数-用户放弃"}},{"name":"agent_leak_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期电销打电话次数-坐席放弃 "}},{"name":"black_list_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期电销打电话次数-外呼异常"}},{"name":"enter_chapter_list_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期进入章节列表页面次数"}},{"name":"enter_payment_page_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期进入付费落地页次数"}},{"name":"click_discovery_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期点击宝藏tab次数"}},{"name":"click_learn_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期点击学习tab次数"}},{"name":"click_learn_together_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期点击共学tab次数"}},{"name":"click_growup_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期点击成长tab次数"}},{"name":"click_myzone_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期点击我的tab次数"}},{"name":"click_operate_cnt","type":"integer","nullable":true,"metadata":{"comment":"触发资源位次数"}},{"name":"user_identity","type":"string","nullable":true,"metadata":{"comment":"用户身份：研究员：common，高级研究员：advanced，首席研究员：lead，体验版首席研究员：expLead"}},{"name":"user_strategy_tag_day","type":"string","nullable":true,"metadata":{"comment":"用户策略标签"}},{"name":"user_strategy_eligibility_day","type":"string","nullable":true,"metadata":{"comment":"用户策略资格"}},{"name":"mid_stage_name","type":"string","nullable":true,"metadata":{"comment":"中学修正学段"}},{"name":"user_pay_status_statistics","type":"string","nullable":true,"metadata":{"comment":"新增、付费、老未（当月第一次活跃时的状态）"}},{"name":"user_pay_status_business","type":"string","nullable":true,"metadata":{"comment":"付费用户、新用、老用户（当月第一次活跃时的状态）"}},{"name":"month","type":"integer","nullable":true,"metadata":{}}]}',
    'spark.sql.sources.schema.part.1' = ',"metadata":{"comment":"用户数仓sk"}},{"name":"u_user","type":"string","nullable":true,"metadata":{"comment":"用户id"}},{"name":"grade","type":"string","nullable":true,"metadata":{"comment":"年级"}},{"name":"stage_name","type":"string","nullable":true,"metadata":{"comment":"学段"}},{"name":"role","type":"string","nullable":true,"metadata":{"comment":"身份"}},{"name":"is_parents","type":"boolean","nullable":true,"metadata":{"comment":"是否家长"}},{"name":"gender","type":"string","nullable":true,"metadata":{"comment":"性别"}},{"name":"regist_time","type":"timestamp","nullable":true,"metadata":{"comment":"注册时间"}},{"name":"u_from","type":"string","nullable":true,"metadata":{"comment":"系统平台"}},{"name":"channel","type":"string","nullable":true,"metadata":{"comment":"注册渠道"}},{"name":"type","type":"string","nullable":true,"metadata":{"comment":"注册方式(枚举值)"}},{"name":"regist_entrance_id","type":"string","nullable":true,"metadata":{"comment":"注册入口"}},{"name":"city_class","type":"string","nullable":true,"metadata":{"comment":"城市分线"}},{"name":"province","type":"string","nullable":true,"metadata":{"comment":"省"}},{"name":"province_code","type":"string","nullable":true,"metadata":{"comment":"省代码"}},{"name":"city","type":"string","nullable":true,"metadata":{"comment":"市"}},{"name":"city_code","type":"string","nullable":true,"metadata":{"comment":"市代码"}},{"name":"area","type":"string","nullable":true,"metadata":{"comment":"地区"}},{"name":"area_code","type":"string","nullable":true,"metadata":{"comment":"区"}},{"name":"region_source","type":"string","nullable":true,"metadata":{"comment":"区域数据来源"}},{"name":"real_school_id","type":"string","nullable":true,"metadata":{"comment":"学校id"}},{"name":"is_teach_user","type":"short","nullable":true,"metadata":{"comment":"是否是有教学班用户"}},{"name":"is_room_user","type":"short","nullable":true,"metadata":{"comment":"是否是有班用户"}},{"name":"is_new_user","type":"short","nullable":true,"metadata":{"comment":"是否是本月新增用户"}},{"name":"is_vip_user","type":"short","nullable":true,"metadata":{"comment":"是否是vip用户"}},{"name":"level","type":"integer","nullable":true,"metadata":{"comment":"等级"}},{"name":"regist_user_allocation","type":{"type":"array","elementType":"string","containsNull":true},"nullable":true,"metadata":{"comment":"用户注册当天服务期归属"}},{"name":"business_user_pay_status_statistics","type":"string","nullable":true,"metadata":{"comment":"新增(统计日期当天注册的)、大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、老未(统计日期之前注册的)"}},{"name":"business_user_pay_status_business","type":"string","nullable":true,"metadata":{"comment":"大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)"}},{"name":"active_user_attribution","type":"string","nullable":true,"metadata":{"comment":"用户活跃时归属"}},{"name":"user_allocation","type":{"type":"array","elementType":"string","containsNull":true},"nullable":true,"metadata":{"comment":"用户全域服务期"}},{"name":"user_vip_tag","type":"string","nullable":true,"metadata":{"comment":"会员身份标签"}},{"name":"download_channel","type":"string","nullable":true,"metadata":{"comment":"下载渠道"}},{"name":"product_id","type":"string","nullable":true,"metadata":{"comment":"产品ID"}},{"name":"client_os","type":"string","nullable":true,"metadata":{"comment":"用户活跃的os"}},{"name":"d_model_brand","type":"string","nullable":true,"metadata":{"comment":"手机品牌"}},{"name":"d_model_name","type":"string","nullable":true,"metadata":{"comment":"手机型号"}},{"name":"sn_code","type":"string","nullable":true,"metadata":{"comment":"sn_code"}},{"name":"learn_active_cnt","type":"integer","nullable":true,"metadata":{"comment":"学习活跃次数"}},{"name":"active_cnt","type":"integer","nullable":true,"metadata":{"comment":"活跃次数"}},{"name":"topic_finish_cnt","type":"integer","nullable":true,"metadata":{"comment":"完成知识点次数"}},{"name":"app_use_duration","type":"integer","nullable":true,"metadata":{"comment":"app使用时长"}},{"name":"app_user_cnt","type":"integer","nullable":true,"metadata":{"comment":"app使用次数"}},{"name":"watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"观看课程视频次数"}},{"name":"serious_watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"认真观看课程视频次数"}},{"name":"finish_watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"完成观看课程视频次数"}},{"name":"watch_course_video_duration","type":"integer","nullable":true,"metadata":{"comment":"观看课程视频时长"}},{"name":"total_exercise_cnt","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习次数"}},{"name":"total_exercise_finish_cnt","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习完成次数"}},{"name":"total_problem_cnt","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习完成次数"}},{"name":"total_exercise_duration","type":"double","nullable":true,"metadata":{"comment":"练习时长"}},{"name":"total_problem_duration","type":"double","nullable":true,"metadata":{"comment":"做题目的时长"}},{"name":"total_regist_days","type":"integer","nullable":true,"metadata":{"comment":"累计注册天数"}},{"name":"sub_amount","type":"double","nullable":true,"metadata":{"comment":"统计周期付费金额"}},{"name":"order_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期付费次数"}},{"name":"d_app_version","type":"string","nullable":true,"metadata":{"comment":"统计周期最后一次活跃app版本"}},{"name":"d_os_version","type":"string","nullable":true,"metadata":{"comment":"统计周期最后一次活跃手机系统版本"}},{"name":"active_day_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期活跃天数"}},{"name":"not_deal_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期电销打电话次数-未接通"}},{"name":"dealing_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期电销打电话次数-已接通"}},{"name":"customer_leak_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期电销打电话次数-用户放弃"}},{"name":"agent_leak_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期电销打电话次数-坐席放弃 "}},{"name":"black_list_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期电销打电话次数-外呼异常"}},{"name":"enter_chapter_list_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期进入章节列表页面次数"}},{"name":"enter_payment_page_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期进入付费落地页次数"}},{"name":"click_discovery_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期点击宝藏tab次数"}},{"name":"click_learn_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期点击学习tab次数"}},{"name":"click_learn_together_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期点击共学tab次数"}},{"name":"click_growup_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期点击成长tab次数"}},{"name":"click_myzone_cnt","type":"integer","nullable":true,"metadata":{"comment":"统计周期点击我的tab次数"}},{"name":"click_operate_cnt","type":"integer","nullable":true,"metadata":{"comment":"触发资源位次数"}},{"name":"user_identity","type":"string","nullable":true,"metadata":{"comment":"用户身份：研究员：common，高级研究员：advanced，首席研究员：lead，体验版首席研究员：expLead"}},{"name":"user_strategy_tag_day","type":"string","nullable":true,"metadata":{"comment":"用户策略标签"}},{"name":"user_strategy_eligibility_day","type":"string","nullable":true,"metadata":{"comment":"用户策略资格"}},{"name":"mid_stage_name","type":"string","nullable":true,"metadata":{"comment":"中学修正学段"}},{"name":"user_pay_status_statistics","type":"string","nullable":true,"metadata":{"comment":"新增、付费、老未（当月第一次活跃时的状态）"}},{"name":"user_pay_status_business","type":"string","nullable":true,"metadata":{"comment":"付费用户、新用、老用户（当月第一次活跃时的状态）"}},{"name":"month","type":"integer","nullable":true,"metadata":{}}]}',
    'spark.sql.sources.schema.partCol.0' = 'month',
    'transient_lastDdlTime' = '1768818963'
  )

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## active_user_attribution（活跃用户归属）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 中学用户 | C 端中学 |
-- | 小学用户 | C 端小学 |
-- | c | C 端其他 |
--
-- ## business_user_pay_status_statistics（付费标签-商业化统计维度口径）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 高净值用户 | 购买过任一高净值商品用户（大会员、组合品） |
-- | 续费用户 | 购买过任一正价商品且非高净值用户 |
-- | 新增 | 注册当天未正价付费用户 |
-- | 老未 | 注册非当天未正价付费用户 |
--
-- ## business_user_pay_status_business（付费标签-商业化业务维度口径）⭐默认字段
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 高净值用户 | 购买过任一高净值商品用户（大会员、组合品） |
-- | 续费用户 | 购买过任一正价商品且非高净值用户 |
-- | 新用户 | 注册30天内（≤30天）未正价付费用户 |
-- | 老用户 | 注册30天以上（>30天）未正价付费用户 |
--
-- ## user_pay_status_statistics（付费标签-统计维度口径）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 付费 | 购买过任一正价商品用户 |
-- | 新增 | 注册当天未正价付费用户 |
-- | 老未 | 注册非当天未正价付费用户 |
--
-- ## user_pay_status_business（付费标签-业务维度口径）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 付费用户 | 购买过任一正价商品用户 |
-- | 新用户 | 注册30天内（≤30天）未正价付费用户 |
-- | 老用户 | 注册30天以上（>30天）未正价付费用户 |
--
-- ## mid_stage_name（中学修正学段）
--
-- | 枚举值 | 说明 |
-- |--------|------|
-- | 学龄前 | |
-- | 小学 | |
-- | 初中 | |
-- | 高中 | |
-- | 中职 | |
-- | NULL | 未填写 |
--
