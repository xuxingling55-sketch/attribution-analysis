-- =====================================================
-- 公用- 用户活跃日表 dws.topic_user_active_detail_day
-- =====================================================
--
-- 【表粒度】
--   一个用户一个下载渠道一个产品id一个活跃端口一个手机品牌一个手机型号一个sn_code一条记录(分区 day int，yyyyMMdd)
--
-- 【业务定位】
--   - 【归属】公用 / 用户活跃日表。
--   - 全量用户日活/学习行为：叠加 product_id、client_os、active_user_attribution（见 glossary「C 端活跃默认筛选」）
--   - 寒假/大盘流量：仅用 is_active_user、is_test_user（不加 C 端三件套）
--   - 付费分层、地域、线索在席等直接选列
--   - 按需区分C端和B端活跃用户

--
-- 【统计口径】
--   活跃 UV = COUNT(DISTINCT u_user)；学习活跃等同理
--   智课用户学校归属：school_sk1
--
-- 【常用关联】
--   - tmp.meishihua_good_day_order_info：与 u_user + day(paid_time_sk) 对齐（见该 tmp 表【业务定位】）
--   - 多 aws 埋点/活跃表层：u_user、day 对齐（见 aws.business_active_user_last_14_day 等【常用关联】）
--
-- 【常用筛选条件】
--   ★必加条件：（依分析场景二选一，勿混用）
--   - day分区日期：yyyyMMdd
--   - 产品id：product_id
--   - 客户端：client_os
--   - 用户归属：active_user_attribution
--
-- 【注意事项】
--   - 更新频率 T+1
--   - 知识库约定：取数与分析仅使用 business_user_pay_status_*；user_pay_status_*（无 business_ 前缀）列不在知识库维护口径

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
  `active_user_attribution` string COMMENT '用户活跃时归属',
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
  `mid_grade` string COMMENT '中学修正年级',
  `mid_stage_name` string COMMENT '中学修正学段',
  `mid_active_type` string COMMENT '(中学)活跃类型：1新增 2 持续 3回流',
  `category` array < string > COMMENT '用户活跃功能',
  `stage_id` int COMMENT '学段id',
  `subject_id` int COMMENT '学科id',
  `client_os` string COMMENT '用户活跃的os',
  `product_id` string COMMENT '产品ID',
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
 `user_pay_status_statistics` string COMMENT '【知识库不引用】取数用 business_user_pay_status_statistics。原：新增(统计日期当天注册的)、付费(统计日期之前买过正价课)、老未(统计日期之前注册的)',
 `user_pay_status_business` string COMMENT '【知识库不引用】取数用 business_user_pay_status_business。原：付费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)',
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
 `business_user_pay_status_statistics` string COMMENT '新增(统计日期当天注册的)、大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、老未(统计日期之前注册的)',
  `regist_user_allocation` array < string > COMMENT '用户注册当天服务期归属',
  `user_vip_tag` string COMMENT '会员身份标签',
 `business_user_pay_status_business` string COMMENT '大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)',
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
) COMMENT '一个用户一个下载渠道一个产品id一个活跃端口一个手机品牌一个手机型号一个sn_code一条记录' PARTITIONED BY (`day` int COMMENT '日期分区') ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dws.db/topic_user_active_detail_day'

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 以下取值经跳板机 Impala 查询 `dws.topic_user_active_detail_day`，条件 `WHERE day = 20260325`（昨日分区，取数日对齐 2026-03-26）；其它分区或历史日期可能存在未列出取值。
-- 「含义」列：自 `code/sql/表结构` 内既有 DDL / 枚举段与 `knowledge/glossary.md` 可对应则填，否则空。`business_user_pay_status_*` 线上枚举为「高净值用户」等，与部分字段 COMMENT 中「大会员」表述若不一致，以落表取值为准。
--
-- ## role（用户角色）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | student | 学生（注册时角色；见 `knowledge/glossary.md`「role / real_identity」） |
-- | teacher | 老师（注册时角色；见 `knowledge/glossary.md`「role / real_identity」） |
--
-- ## mid_grade（中学修正年级）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `dw.dim_user`「grade」枚举段口径一致） |
-- | 一年级 | 一年级 |
-- | 二年级 | 二年级 |
-- | 三年级 | 三年级 |
-- | 四年级 | 四年级 |
-- | 五年级 | 五年级 |
-- | 六年级 | 六年级 |
-- | 七年级 | 七年级 |
-- | 八年级 | 八年级 |
-- | 九年级 | 九年级 |
-- | 高一 | 高一 |
-- | 高二 | 高二 |
-- | 高三 | 高三 |
-- | 学龄前 | 学龄前 |
-- | 职一 | 职一 |
-- | 职二 | 职二 |
-- | 职三 | 职三 |
--
-- ## mid_stage_name（中学修正学段）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `dws.topic_user_info`「stage_name」枚举段一致） |
-- | 启蒙 | 启蒙 |
-- | 小学 | 小学 |
-- | 初中 | 初中 |
-- | 高中 | 高中 |
-- | 中职 | 中职 |
--
-- ## attribution（用户归属）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | b | b端用户，智课团队的用户（见 `dw.dim_user` / `dws.topic_user_info` 枚举段） |
-- | c | c端用户，非智课团队的用户（见 `dw.dim_user` / `dws.topic_user_info` 枚举段） |
--
-- ## active_user_attribution（用户活跃时归属）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | b | b端用户，智课团队的用户（与 `attribution` 枚举含义对齐；C 端默认筛选见 `knowledge/glossary.md`「C 端活跃默认筛选」） |
-- | c | c端用户，非智课团队的用户（与 `attribution` 枚举含义对齐；C 端默认筛选见 `knowledge/glossary.md`「C 端活跃默认筛选」） |
--
-- ## product_id（产品ID）
--
-- > product_id 名称与备注由数仓与业务维护；与 `knowledge/glossary.md`「C 端活跃默认筛选」中 `product_id = '01'` 口径可对照使用。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | (空字符串) | 数仓可能出现的空产品编码 |
-- | 01 | 原app；支付；包含教师容器 |
-- | 02 | 教师独立app |
-- | 03 | 小学容器 |
-- | 04 | 学生校园版app 1.0；支持教育局报备 |
-- | 05 | M2(课程4.0) |
-- | 06 | 小学独立APP |
-- | 07 | 洋葱星球app |
-- | 08 | 洋葱学园PICO版 |
-- | 09 | 预习神器 |
-- | 10 | 个性化学习系统 |
-- | 11 | 小学小程序 |
-- | 12 | 家长小程序；家长业务群 |
-- | 13 | 小程序成长版 |
-- | 14 | 洋葱应用市场 |
-- | 21 | 电销小程序-洋葱学园 |
-- | 22 | 2023武汉电销春节福利卡 |
-- | 31 | 原教师pc（洋葱学院PC端） |
-- | 32 | 小学pc |
-- | 33 | PC校园版（解决方案2.0） |
-- | 34 | 运营后台；运营后台创建"校园版"订单 |
-- | 36 | B端运营后台 |
-- | 37 | 个性化学习系统 |
-- | 38 | 电销CRM系统 |
-- | 41 | 站外h5；弃用，站外h5用更小的分类替代，编码101开始 |
-- | 42 | 线下渠道；渠道系统订单 |
-- | 101 | 阿里云OS |
-- | 102 | QQ浏览器 |
-- | 103 | 有赞商城；家长业务群 |
-- | 110 | 小学数学营销小程序 |
-- | 111 | 小学数学学习体验小程序 |
-- | 112 | 洋葱星球小程序授权 |
-- | 120 | 家长洋葱商城；家长业务群（H5 商城）支付 |
-- | 121 | 京东商城；暂未接入订单系统；付缺 |
-- | 122 | 华为教育中心 |
-- | 123 | 百度小程序 |
-- | 124 | 洋葱星球家长课堂小程序授权 |
-- | 201 | 麦莉妈妈（分销商）；小学渠道分销 |
-- | 202 | 妈妈心选 |
-- | 203 | 花生日记 |
-- | 204 | ahaschool |
-- | 205 | 妈觅精选 |
-- | 206 | 枣妈与恺摩 |
-- | 207 | 萌状元 |
-- | 208 | 爸妈严选 |
-- | 209 | 向日葵妈妈分销 |
-- | 210 | 分销合作平台-习惯熊 |
-- | 211 | 分销合作平台公众号订单导入运营后台 |
-- | 300 | H5投放订单；打开H5投放支付的订单，复制链接支付 |
-- | 410 | 寒假课程礼包H5 |
-- | 411 | 企业微信h5 |
-- | 414 | 微店 |
-- | 415 | 抖音app h5页面 |
-- | 416 | 微信app 小程序 |
-- | 417 | 抖店商城 h5页面 |
-- | 418 | 洋葱教辅书二维码 |
-- | 419 | 智能客服系统 |
-- | 421 | 京东商城导入订单or未来接订单使用的h5页面 |
-- | 422 | 社区站外分享 |
-- | 423 | 奥德赛_直播 |
-- | 424 | 企微站外引流-H5登录 |
-- | 425 | 天猫商城h5页面注册 |
-- | 500 | 入校项目的希沃合作 |
-- | 501 | 洋葱学院APP-mac版 |
-- | 700 | 视频号小店导入订单 |
--
-- ## is_admin_user（是否在行政班）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 否（见字段 COMMENT） |
-- | 1 | 是（见字段 COMMENT） |
--
-- ## business_user_pay_status_business（见 `dws.topic_user_info` 同名字段 COMMENT；取值对齐线上）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 新用户 | 统计日期30天内注册的（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 续费用户 | 统计日期之前买过正价课（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 老用户 | 统计日期30以前注册的（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 高净值用户 | 统计日期之前方案型商品（不包括商品二级分类 id 为一年积木块、体验机、到期型培优课积木块等）（见 `dws.topic_user_info` 字段 COMMENT） |
--
-- ## business_user_pay_status_statistics（见 `dws.topic_user_info` 同名字段 COMMENT；取值对齐线上）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 新增 | 统计日期当天注册的（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 续费用户 | 统计日期之前买过正价课（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 老未 | 统计日期之前注册的（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 高净值用户 | 统计日期之前方案型商品（不包括商品二级分类 id 为一年积木块、体验机、到期型培优课积木块等）（见 `dws.topic_user_info` 字段 COMMENT） |
--
-- ## user_strategy_tag_day（用户策略标签）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 付费加购品用户 | 付费加购品用户（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
-- | 付费组合品用户 | 付费组合品用户（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
-- | 付费零售品用户 | 付费零售品用户（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
-- | 历史大会员用户_不可续购 | 历史大会员用户_不可续购（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
-- | 历史大会员用户_可续购 | 历史大会员用户_可续购（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
-- | 新用户 | 新用户（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
-- | 老用户 | 老用户（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
--
-- ## user_strategy_eligibility_day（用户策略资格）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | (空字符串) | 无策略资格（见 `dws.topic_user_info` 枚举段） |
-- | 历史大会员续购策略资格;学习机加购策略资格 | 历史大会员续购策略资格;学习机加购策略资格（见 `dws.topic_user_info` 枚举段） |
-- | 历史大会员续购策略资格;学习机加购策略资格;小学品升级补差至小初品资格 | 历史大会员续购策略资格;学习机加购策略资格;小学品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格 | 学习机加购策略资格;高中囤课策略资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;小学品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;小学品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 小初同步品升级补差至小初品资格 | 小初同步品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 小学品升级补差至小初品资格 | 小学品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
