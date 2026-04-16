-- =====================================================
-- 用户活跃天表 dws.topic_user_active_detail_day
-- =====================================================
--
-- 【表粒度】★必填
--   用户 + 日期 + 下载渠道 + 产品 + 活跃端口 + 设备 = 一条记录
--   常用聚合：按 u_user + day 去重即为日活
--   分区字段：day（int 类型，格式 yyyyMMdd），T+1 更新
--
-- 【统计口径】
--   日活用户数 = COUNT(DISTINCT u_user)
--   学习活跃数 = COUNT(DISTINCT CASE WHEN is_learn_active_user = 1 THEN u_user END)
--   注意：业务指标的权威定义在 glossary.md，本段仅记录"用本表怎么算"
--
-- 【常用关联】
--   活跃转化分析：
--     本表.u_user = dws.topic_order_detail.u_user（关联全公司订单表计算转化率）
--
-- 【常用筛选条件】
--   ★必加条件（默认看 C 端活跃）：
--   - product_id = '01'                                     -- 洋葱学园主站
--   - client_os IN ('android', 'ios', 'harmony')            -- 移动端
--   - active_user_attribution IN ('中学用户', '小学用户', 'c') -- C 端用户
--
--   场景条件：
--   - is_learn_active_user = 1         -- 区分学习行为活跃 vs 普通活跃（打开APP即算）
--   - is_test_user = 0                 -- 排除测试用户
--
-- 【注意事项】
--   ⚠️ is_learn_active_user 区分"学习活跃"与"普通活跃"：
--     · 普通活跃：打开 APP 即算（不加此过滤），日活统计默认用普通活跃
--     · 学习活跃：需有学习行为（加 is_learn_active_user = 1）
--   ⚠️ user_allocation 字段：用户全域服务期，包含"电销"则表示在电销服务期
--   ⚠️ is_clue_seat = 1：表示当天线索在坐席名下（当天快照）
--
-- =====================================================

CREATE EXTERNAL TABLE `dws`.`topic_user_active_detail_day` (
  `user_sk` int COMMENT '用户代理键',
  `u_user` string COMMENT '用户id',
  `role` string COMMENT '用户角色',
  `grade` string COMMENT '年级',
  `gender` string COMMENT '性别',
  `regist_time` timestamp COMMENT '注册时间',
  `regist_time_sk` int COMMENT '注册时间sk',
  `activate_date` timestamp COMMENT '激活时间',
  `activate_date_sk` int COMMENT '激活时间sk',
  `user_attribution` string COMMENT '用户注册当天归属',
  `active_user_attribution` string COMMENT '用户活跃时归属（★必加条件：中学用户/小学用户/c 为C端，详见文件末尾枚举值）',
  `attribution` string COMMENT '用户归属',
  `channel` string COMMENT '注册渠道',
  `u_from` string COMMENT '系统平台',
  `regist_app_version` string COMMENT '注册时的app版本号',
  `school_tag` smallint COMMENT '学校标签：0:非维护学校，1普通维护学校，2、重点维护学校',
  `regist_entrance_id` string COMMENT '注册入口',
  `regist_os` string COMMENT '操作系统',
  `regist_type` string COMMENT '注册方式',
  `city_class` string COMMENT '用户城市分线',
  `province` string COMMENT '省名称',
  `province_code` string COMMENT '省code',
  `city` string COMMENT '市名称',
  `city_code` string COMMENT '市code',
  `area` string COMMENT '区名称',
  `area_code` string COMMENT '区code',
  `school_id` string COMMENT '学校id',
  `school_sk` int COMMENT '学校sk',
  `school_id1` string COMMENT '学校id1',
  `school_sk1` int COMMENT '学校sk1',
  `admin_room_id` string COMMENT '用户行政班id',
  `school_agent_id` string COMMENT '用户所在学校的代理商id',
  `is_bind_parent` smallint COMMENT '是否绑定家长用户',
  `is_test_user` smallint COMMENT '是否测试用户',
  `is_teach_user` smallint COMMENT '是否教学班用户',
  `is_admin_user` smallint COMMENT '是否在行政班',
  `is_room_user` smallint COMMENT '是否有班',
  `is_put_channel` smallint COMMENT '是否投放渠道',
  `is_new_user` smallint COMMENT '是否新注册用户',
  `is_vip_user` smallint COMMENT '是否是vip用户',
  `ss_arr` array < string > COMMENT 'vip的学段学科数组',
  `mid_grade` string COMMENT '中学修正年级（详见文件末尾枚举值）',
  `mid_stage_name` string COMMENT '中学修正学段（详见文件末尾枚举值）',
  `mid_active_type` string COMMENT '(中学)活跃类型：1新增 2 持续 3回流',
  `category` array < string > COMMENT '用户活跃功能',
  `stage_id` int COMMENT '学段id',
  `subject_id` int COMMENT '学科id',
  `client_os` string COMMENT '用户活跃的os（★必加条件：android/ios/harmony 为移动端）',
  `product_id` string COMMENT '产品ID（★必加条件：= 01 为主站）',
  `download_channel` string COMMENT '下载渠道',
  `is_learn_active_user` smallint COMMENT '是否学习活跃用户',
  `is_active_user` smallint COMMENT '是否活跃用户',
  `learn_active_cnt` int COMMENT '学习活跃次数',
  `active_cnt` int COMMENT '活跃次数',
  `topic_finish_cnt` int COMMENT '完成知识点数',
  `app_use_duration` int COMMENT 'app使用时长(秒)',
  `app_user_cnt` int COMMENT 'app使用次数',
  `is_watch_course_video_user` smallint COMMENT '是否课程视频活跃用户',
  `watch_course_video_cnt` int COMMENT '课程视频开始次数',
  `watch_course_video_duration` int COMMENT '课程视频活跃时长（秒）',
  `serious_watch_course_video_cnt` int COMMENT '课程视频认真观看次数',
  `finish_watch_course_video_cnt` int COMMENT '课程视频完播次数',
  `is_valid_watch_course_video_user` smallint COMMENT '是否课程视频活跃用户（观看时长>0）',
  `valid_watch_course_video_cnt` int COMMENT '课程视频开始次数（观看时长>0）',
  `valid_watch_course_video_duration` int COMMENT '课程视频活跃时长（观看时长>0）',
  `valid_serious_watch_course_video_cnt` int COMMENT '课程视频认真观看次数（观看时长>0）',
  `valid_finish_watch_course_video_cnt` int COMMENT '课程视频完播次数（观看时长>0）',
  `total_exercise_cnt` int COMMENT '所有模块练习次数',
  `total_exercise_user_sk` int COMMENT '所有模块练习学生sk',
  `total_exercise_finish_cnt` int COMMENT '所有模块练习完成次数',
  `total_exercise_finish_user_sk` int COMMENT '所有模块练习完成学生sk',
  `total_problem_cnt` int COMMENT '所有模块练习做题次数',
  `total_problem_user_sk` int COMMENT '所有模块练习做题学生sk',
  `total_exercise_duration` double COMMENT '练习时长',
  `total_problem_duration` double COMMENT '做题目的时长',
  `total_problem_correct_rate` double COMMENT '做题目的正确率',
  `total_problem_explain_duration` double COMMENT '解析总时长',
  `total_video_explain_duration` int COMMENT '视频解析总时长',
  `user_pay_status_statistics` string COMMENT '付费标签：统计维度口径（详见文件末尾枚举值）',
  `user_pay_status_business` string COMMENT '付费标签：业务维度口径（详见文件末尾枚举值）',
  `click_pad_app_tab_cnt` int COMMENT '点击pad第三发app次数',
  `click_pad_app_tab_duration` int COMMENT 'pad第三方app使用时长',
  `enter_scene_chapter_user_sk` int COMMENT '教材同步进入用户user_sk',
  `enter_scene_problem_user_sk` int COMMENT '题库进入用户user_sk',
  `enter_scene_homework_user_sk` int COMMENT '进入作业场景user_sk',
  `enter_scene_homework_valid_user_sk` int COMMENT '作业场景里，进入过作业题型详情页的user_sk',
  `enter_scene_before_test_user_sk` int COMMENT '进入备考场景user_sk',
  `enter_scene_before_test_valid_user_sk` int COMMENT '备考场景里，完成过至少一个专题的user_sk',
  `enter_total_review_user_sk` int COMMENT '进入总复习场景user_sk',
  `enter_scene_lt_user_sk` int COMMENT '进入试炼场user_sk',
  `enter_wrong_book_user_sk` int COMMENT '进入错题本user_sk',
  `enter_wrong_book_valid_user_sk` int COMMENT '至少作答一次错题用户user_sk',
  `pad_enter_test_paper_user_sk` int COMMENT '(pad入口)进入试卷用户user_sk',
  `pad_enter_report_tab_learn_report_user_sk` int COMMENT '(pad入口)进入学情报告user_sk',
  `pad_enter_report_tab_puch_user_sk` int COMMENT '(pad入口)进入学习打卡user_sk',
  `pad_enter_report_tab_daily_task_user_sk` int COMMENT '(pad入口)进入每日任务user_sk',
  `pad_enter_learn_style_page_user_sk` int COMMENT '(pad入口)进入学习风格user_sk',
  `pad_finish_learn_style_test_user_sk` int COMMENT '(pad入口)当日完成学习风格测评user_sk',
  `pad_enter_learn_goal_page_user_sk` int COMMENT '(pad入口)进入学习目标user_sk',
  `pad_finish_learn_goal_page_user_sk` int COMMENT '(pad入口)当日完成学习目标设定user_sk',
  `pad_enter_learn_method_page_user_sk` int COMMENT '(pad入口)进入学习方法user_sk',
  `pad_click_learn_method_page_user_sk` int COMMENT '(pad入口)点击任意学习方法user_sk',
  `pad_enter_learn_feature_exercise_explain_user_sk` int COMMENT '(pad入口)进入题型精讲user_sk',
  `pad_enter_learn_feature_student_note_user_sk` int COMMENT '(pad入口)进入学霸笔记user_sk',
  `pad_enter_learn_feature_review_book_user_sk` int COMMENT '(pad入口)进入复习宝典user_sk',
  `pad_enter_learn_feature_synthetical_note_user_sk` int COMMENT '(pad入口)进入综合提示user_sk',
  `enter_variant_questions_show_page_user_sk` int COMMENT '变式题进入user_sk',
  `enter_variant_questions_results_page_user_sk` int COMMENT '变式题有效学习user_sk',
  `d_model_brand` string COMMENT '手机品牌',
  `d_model_name` string COMMENT '手机型号',
  `enter_pad_scene_task_user_sk` int COMMENT 'pad任务进入用户user_sk',
  `finish_pad_task_claim_user_sk` int COMMENT 'pad任务有效完成用户user_sk',
  `enter_pad_scene_finaltreat_user_sk` int COMMENT 'pad体检表进入用户user_sk',
  `finsh_pad_scene_finaltreat_user_sk` int COMMENT 'pad体检表有效学习用户user_sk',
  `sn_code` string COMMENT 'sn_code',
  `user_allocation` array < string > COMMENT '用户全域服务期',
  `business_user_pay_status_statistics` string COMMENT '付费标签：商业化统计维度口径（详见文件末尾枚举值）',
  `regist_user_allocation` array < string > COMMENT '用户注册当天服务期归属',
  `user_vip_tag` string COMMENT '会员身份标签',
  `business_user_pay_status_business` string COMMENT '付费标签：商业化业务维度口径 ⭐默认字段（详见文件末尾枚举值）',
  `enter_chapter_list_cnt` int COMMENT '进入章节列表也次数',
  `enter_payment_page_cnt` int COMMENT '进入付费落地页次数',
  `click_discovery_cnt` int COMMENT '点击切换宝藏tab次数',
  `click_learn_cnt` int COMMENT '点击切换学习tab次数',
  `click_learn_together_cnt` int COMMENT '点击切换共学tab次数',
  `click_growup_cnt` int COMMENT '点击切换成长tab次数',
  `click_myzone_cnt` int COMMENT '点击切换我的tab次数',
  `click_operate_cnt` int COMMENT '触发资源位弹窗次数',
  `is_clue_seat` smallint COMMENT '线索是否在坐席名下',
  `user_identity` string COMMENT '用户身份：研究员：common，高级研究员：advanced，首席研究员：lead，体验版首席研究员：expLead',
  `is_c_student_active` int COMMENT '是否C端学生活跃',
  `user_strategy_tag_day` string COMMENT '用户策略标签',
  `user_strategy_eligibility_day` string COMMENT '用户策略资格'
) COMMENT '一个用户一个下载渠道一个产品id一个活跃端口一个手机品牌一个手机型号一个sn_code一条记录' PARTITIONED BY (`day` int COMMENT '日期分区') ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dws.db/topic_user_active_detail_day' TBLPROPERTIES (
  'alias' = '用户活跃天表汇总',
  'bucketing_version' = '2',
  'is_core' = 'true',
  'last_modified_by' = 'finebi',
  'last_modified_time' = '1755162822',
  'spark.sql.create.version' = '2.3.0.2.6.5.0-292',
  'spark.sql.sources.schema.numPartCols' = '1',
  'spark.sql.sources.schema.numParts' = '4',
  'spark.sql.sources.schema.part.0' = '{"type":"struct","fields":[{"name":"user_sk","type":"integer","nullable":true,"metadata":{"comment":"用户代理键"}},{"name":"u_user","type":"string","nullable":true,"metadata":{"comment":"用户id"}},{"name":"role","type":"string","nullable":true,"metadata":{"comment":"用户角色"}},{"name":"grade","type":"string","nullable":true,"metadata":{"comment":"年级"}},{"name":"gender","type":"string","nullable":true,"metadata":{"comment":"性别"}},{"name":"regist_time","type":"timestamp","nullable":true,"metadata":{"comment":"注册时间"}},{"name":"regist_time_sk","type":"integer","nullable":true,"metadata":{"comment":"注册时间sk"}},{"name":"activate_date","type":"timestamp","nullable":true,"metadata":{"comment":"激活时间"}},{"name":"activate_date_sk","type":"integer","nullable":true,"metadata":{"comment":"激活时间sk"}},{"name":"user_attribution","type":"string","nullable":true,"metadata":{"comment":"用户注册当天归属"}},{"name":"active_user_attribution","type":"string","nullable":true,"metadata":{"comment":"用户活跃时归属"}},{"name":"attribution","type":"string","nullable":true,"metadata":{"comment":"用户归属"}},{"name":"channel","type":"string","nullable":true,"metadata":{"comment":"注册渠道"}},{"name":"u_from","type":"string","nullable":true,"metadata":{"comment":"系统平台"}},{"name":"regist_app_version","type":"string","nullable":true,"metadata":{"comment":"注册时的app版本号"}},{"name":"school_tag","type":"short","nullable":true,"metadata":{"comment":"学校标签：0:非维护学校，1普通维护学校，2、重点维护学校"}},{"name":"regist_entrance_id","type":"string","nullable":true,"metadata":{"comment":"注册入口"}},{"name":"regist_os","type":"string","nullable":true,"metadata":{"comment":"操作系统"}},{"name":"regist_type","type":"string","nullable":true,"metadata":{"comment":"注册方式"}},{"name":"city_class","type":"string","nullable":true,"metadata":{"comment":"用户城市分线"}},{"name":"province","type":"string","nullable":true,"metadata":{"comment":"省名称"}},{"name":"province_code","type":"string","nullable":true,"metadata":{"comment":"省code"}},{"name":"city","type":"string","nullable":true,"metadata":{"comment":"市名称"}},{"name":"city_code","type":"string","nullable":true,"metadata":{"comment":"市code"}},{"name":"area","type":"string","nullable":true,"metadata":{"comment":"区名称"}},{"name":"area_code","type":"string","nullable":true,"metadata":{"comment":"区code"}},{"name":"school_id","type":"string","nullable":true,"metadata":{"comment":"学校id"}},{"name":"school_sk","type":"integer","nullable":true,"metadata":{"comment":"学校sk"}},{"name":"school_id1","type":"string","nullable":true,"metadata":{"comment":"学校id1"}},{"name":"school_sk1","type":"integer","nullable":true,"metadata":{"comment":"学校sk1"}},{"name":"admin_room_id","type":"string","nullable":true,"metadata":{"comment":"用户行政班id"}},{"name":"school_agent_id","type":"string","nullable":true,"metadata":{"comment":"用户所在学校的代理商id"}},{"name":"is_bind_parent","type":"short","nullable":true,"metadata":{"comment":"是否绑定家长用户"}},{"name":"is_test_user","type":"short","nullable":true,"metadata":{"comment":"是否测试用户"}},{"name":"is_teach_user","type":"short","nullable":true,"metadata":{"comment":"是否教学班用户"}},{"name":"is_admin_user","type":"short","nullable":true,"metadata":{"comment":"是否在行政班"}},{"name":"is_room_user","type":"short","nullable":true,"metadata":{"comment":"是否有班"}},{"name":"is_put_channel","type":"short","nullable":true,"metadata":{"comment":"是否投放渠道"}},{"name":"is_new_user","type":"short","nullable":true,"metadata":{"comment":"是否新注册用户"}},{"name":"is_vip_user","type":"short","nullable":true,"metadata":{"comment":"是否是vip用户"}},{"name":"ss_arr","type":{"type":"array","elementType":"string","containsNull":true},"nullable":true,"metadata":{"comment":"vip的学段学科数组"}},{"name":"mid_grade","type":"string","nullable":true,"metadata":{"comment":"中学修正年级"}},{"name":"mid_stage_name","type":"string","nullable":true,"metadata":{"comment":"中学修正学段"}},{"name":"mid_active_type","type":"string","nullable":true,"metadata":{"comment":"(中学)活跃类型：1新增 2 持续 3回流"}},{"name":"category","type":{"type":"array","elementType":"string","containsNull":true}',
  'spark.sql.sources.schema.part.1' = ',"nullable":true,"metadata":{"comment":"用户活跃功能"}},{"name":"stage_id","type":"integer","nullable":true,"metadata":{"comment":"学段id"}},{"name":"subject_id","type":"integer","nullable":true,"metadata":{"comment":"学科id"}},{"name":"client_os","type":"string","nullable":true,"metadata":{"comment":"用户活跃的os"}},{"name":"product_id","type":"string","nullable":true,"metadata":{"comment":"产品ID"}},{"name":"download_channel","type":"string","nullable":true,"metadata":{"comment":"下载渠道"}},{"name":"is_learn_active_user","type":"short","nullable":true,"metadata":{"comment":"是否学习活跃用户"}},{"name":"is_active_user","type":"short","nullable":true,"metadata":{"comment":"是否活跃用户"}},{"name":"learn_active_cnt","type":"integer","nullable":true,"metadata":{"comment":"学习活跃次数"}},{"name":"active_cnt","type":"integer","nullable":true,"metadata":{"comment":"活跃次数"}},{"name":"topic_finish_cnt","type":"integer","nullable":true,"metadata":{"comment":"完成知识点数"}},{"name":"app_use_duration","type":"integer","nullable":true,"metadata":{"comment":"app使用时长(秒)"}},{"name":"app_user_cnt","type":"integer","nullable":true,"metadata":{"comment":"app使用次数"}},{"name":"is_watch_course_video_user","type":"short","nullable":true,"metadata":{"comment":"是否课程视频活跃用户"}},{"name":"watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"课程视频开始次数"}},{"name":"watch_course_video_duration","type":"integer","nullable":true,"metadata":{"comment":"课程视频活跃时长（秒）"}},{"name":"serious_watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"课程视频认真观看次数"}},{"name":"finish_watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"课程视频完播次数"}},{"name":"is_valid_watch_course_video_user","type":"short","nullable":true,"metadata":{"comment":"是否课程视频活跃用户（观看时长>0）"}},{"name":"valid_watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"课程视频开始次数（观看时长>0）"}},{"name":"valid_watch_course_video_duration","type":"integer","nullable":true,"metadata":{"comment":"课程视频活跃时长（观看时长>0）"}},{"name":"valid_serious_watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"课程视频认真观看次数（观看时长>0）"}},{"name":"valid_finish_watch_course_video_cnt","type":"integer","nullable":true,"metadata":{"comment":"课程视频完播次数（观看时长>0）"}},{"name":"total_exercise_cnt","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习次数"}},{"name":"total_exercise_user_sk","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习学生sk"}},{"name":"total_exercise_finish_cnt","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习完成次数"}},{"name":"total_exercise_finish_user_sk","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习完成学生sk"}},{"name":"total_problem_cnt","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习做题次数"}},{"name":"total_problem_user_sk","type":"integer","nullable":true,"metadata":{"comment":"所有模块练习做题学生sk"}},{"name":"total_exercise_duration","type":"double","nullable":true,"metadata":{"comment":"练习时长"}},{"name":"total_problem_duration","type":"double","nullable":true,"metadata":{"comment":"做题目的时长"}},{"name":"total_problem_correct_rate","type":"double","nullable":true,"metadata":{"comment":"做题目的正确率"}},{"name":"total_problem_explain_duration","type":"double","nullable":true,"metadata":{"comment":"解析总时长"}},{"name":"total_video_explain_duration","type":"integer","nullable":true,"metadata":{"comment":"视频解析总时长"}},{"name":"user_pay_status_statistics","type":"string","nullable":true,"metadata":{"comment":"新增(统计日期当天注册的)、付费(统计日期之前买过正价课)、老未(统计日期之前注册的)"}},{"name":"user_pay_status_business","type":"string","nullable":true,"metadata":{"comment":"付费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)"}},{"name":"click_pad_app_tab_cnt","type":"integer","nullable":true,"metadata":{"comment":"点击pad第三发app次数"}},{"name":"click_pad_app_tab_duration","type":"integer","nullable":true,"metadata":{"comment":"pad第三方app使用时长"}},{"name":"enter_scene_chapter_user_sk","type":"integer","nullable":true,"metadata":{"comment":"教材同步进入用户user_sk"}},{"',
  'spark.sql.sources.schema.part.2' = 'name":"enter_scene_problem_user_sk","type":"integer","nullable":true,"metadata":{"comment":"题库进入用户user_sk"}},{"name":"enter_scene_homework_user_sk","type":"integer","nullable":true,"metadata":{"comment":"进入作业场景user_sk"}},{"name":"enter_scene_homework_valid_user_sk","type":"integer","nullable":true,"metadata":{"comment":"作业场景里，进入过作业题型详情页的user_sk"}},{"name":"enter_scene_before_test_user_sk","type":"integer","nullable":true,"metadata":{"comment":"进入备考场景user_sk"}},{"name":"enter_scene_before_test_valid_user_sk","type":"integer","nullable":true,"metadata":{"comment":"备考场景里，完成过至少一个专题的user_sk"}},{"name":"enter_total_review_user_sk","type":"integer","nullable":true,"metadata":{"comment":"进入总复习场景user_sk"}},{"name":"enter_scene_lt_user_sk","type":"integer","nullable":true,"metadata":{"comment":"进入试炼场user_sk"}},{"name":"enter_wrong_book_user_sk","type":"integer","nullable":true,"metadata":{"comment":"进入错题本user_sk"}},{"name":"enter_wrong_book_valid_user_sk","type":"integer","nullable":true,"metadata":{"comment":"至少作答一次错题用户user_sk"}},{"name":"pad_enter_test_paper_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)进入试卷用户user_sk"}},{"name":"pad_enter_report_tab_learn_report_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)进入学情报告user_sk"}},{"name":"pad_enter_report_tab_puch_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)进入学习打卡user_sk"}},{"name":"pad_enter_report_tab_daily_task_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)进入每日任务user_sk"}},{"name":"pad_enter_learn_style_page_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)进入学习风格user_sk"}},{"name":"pad_finish_learn_style_test_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)当日完成学习风格测评user_sk"}},{"name":"pad_enter_learn_goal_page_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)进入学习目标user_sk"}},{"name":"pad_finish_learn_goal_page_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)当日完成学习目标设定user_sk"}},{"name":"pad_enter_learn_method_page_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)进入学习方法user_sk"}},{"name":"pad_click_learn_method_page_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)点击任意学习方法user_sk"}},{"name":"pad_enter_learn_feature_exercise_explain_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)进入题型精讲user_sk"}},{"name":"pad_enter_learn_feature_student_note_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)进入学霸笔记user_sk"}},{"name":"pad_enter_learn_feature_review_book_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)进入复习宝典user_sk"}},{"name":"pad_enter_learn_feature_synthetical_note_user_sk","type":"integer","nullable":true,"metadata":{"comment":"(pad入口)进入综合提示user_sk"}},{"name":"enter_variant_questions_show_page_user_sk","type":"integer","nullable":true,"metadata":{"comment":"变式题进入user_sk"}},{"name":"enter_variant_questions_results_page_user_sk","type":"integer","nullable":true,"metadata":{"comment":"变式题有效学习user_sk"}},{"name":"d_model_brand","type":"string","nullable":true,"metadata":{"comment":"手机品牌"}},{"name":"d_model_name","type":"string","nullable":true,"metadata":{"comment":"手机型号"}},{"name":"enter_pad_scene_task_user_sk","type":"integer","nullable":true,"metadata":{"comment":"pad任务进入用户user_sk"}},{"name":"finish_pad_task_claim_user_sk","type":"integer","nullable":true,"metadata":{"comment":"pad任务有效完成用户user_sk"}},{"name":"enter_pad_scene_finaltreat_user_sk","type":"integer","nullable":true,"metadata":{"comment":"pad体检表进入用户user_sk"}},{"name":"finsh_pad_scene_finaltreat_user_sk","type":"integer","nullable":true,"metadata":{"comment":"pad体检表有效学习用户user_sk"}},{"name":"sn_code","type":"string","nullable":true,"metadata":{"comment":"sn_code"}},{"name":"user_allocation","type":{"type":"array","elementType":"string","containsNull":true},"nullable":true,"metadata":{"comment":"用户全域服务期"}},{"name":"business',
  'spark.sql.sources.schema.part.3' = '_user_pay_status_statistics","type":"string","nullable":true,"metadata":{"comment":"新增(统计日期当天注册的)、大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、老未(统计日期之前注册的)"}},{"name":"regist_user_allocation","type":{"type":"array","elementType":"string","containsNull":true},"nullable":true,"metadata":{"comment":"用户注册当天服务期归属"}},{"name":"user_vip_tag","type":"string","nullable":true,"metadata":{"comment":"会员身份标签"}},{"name":"business_user_pay_status_business","type":"string","nullable":true,"metadata":{"comment":"大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)"}},{"name":"enter_chapter_list_cnt","type":"integer","nullable":true,"metadata":{"comment":"进入章节列表也次数"}},{"name":"enter_payment_page_cnt","type":"integer","nullable":true,"metadata":{"comment":"进入付费落地页次数"}},{"name":"click_discovery_cnt","type":"integer","nullable":true,"metadata":{"comment":"点击切换宝藏tab次数"}},{"name":"click_learn_cnt","type":"integer","nullable":true,"metadata":{"comment":"点击切换学习tab次数"}},{"name":"click_learn_together_cnt","type":"integer","nullable":true,"metadata":{"comment":"点击切换共学tab次数"}},{"name":"click_growup_cnt","type":"integer","nullable":true,"metadata":{"comment":"点击切换成长tab次数"}},{"name":"click_myzone_cnt","type":"integer","nullable":true,"metadata":{"comment":"点击切换我的tab次数"}},{"name":"click_operate_cnt","type":"integer","nullable":true,"metadata":{"comment":"触发资源位弹窗次数"}},{"name":"is_clue_seat","type":"short","nullable":true,"metadata":{"comment":"线索是否在坐席名下"}},{"name":"user_identity","type":"string","nullable":true,"metadata":{"comment":"用户身份：研究员：common，高级研究员：advanced，首席研究员：lead，体验版首席研究员：expLead"}},{"name":"is_c_student_active","type":"integer","nullable":true,"metadata":{"comment":"是否C端学生活跃"}},{"name":"user_strategy_tag_day","type":"string","nullable":true,"metadata":{"comment":"用户策略标签"}},{"name":"user_strategy_eligibility_day","type":"string","nullable":true,"metadata":{"comment":"用户策略资格"}},{"name":"day","type":"integer","nullable":true,"metadata":{"comment":"日期分区"}}]}',
  'spark.sql.sources.schema.partCol.0' = 'day',
  'transient_lastDdlTime' = '1768534929'
)

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## product_id（产品ID）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 01 | 主产品（★默认筛选） |
--
-- ## client_os（客户端操作系统）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | android | 安卓 |
-- | ios | 苹果 |
-- | harmony | 鸿蒙 |
--
-- ## active_user_attribution（活跃用户归属）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 中学用户 | C 端中学 |
-- | 小学用户 | C 端小学 |
-- | c | C 端其他 |
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
-- | 学龄前 | |
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
-- | 学龄前 | 学龄前 |
-- | 小学 | 一年级、二年级、三年级、四年级、五年级、六年级 |
-- | 初中 | 七年级、八年级、九年级 |
-- | 高中 | 高一、高二、高三、十年级 |
-- | 中职 | 职一、职二、职三 |
-- | 其他 | 其他、unavailable、NULL |
--
-- ## role（注册时选择的角色）
--
-- > ⚠️ 不能用于判断是否家长，判断家长身份必须使用 real_identity（仅用户表有）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | student | 学生 |
-- | teacher | 老师 |
-- | parents | 历史小程序注册用户默认给的家长身份 |
-- | youzan | 有赞 |
--
-- ## user_identity（用户身份等级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | common | 研究员 |
-- | advanced | 高级研究员 |
-- | lead | 首席研究员 |
-- | expLead | 体验版首席研究员 |