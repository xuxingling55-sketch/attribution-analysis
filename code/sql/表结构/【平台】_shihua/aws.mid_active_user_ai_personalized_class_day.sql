-- =====================================================
-- APP- AI私教班学习日表 aws.mid_active_user_ai_personalized_class_day
-- =====================================================
--
-- 【表粒度】
--   一用户一班级一行（分区字段：day）
--
-- 【业务定位】
--   - 【归属】APP / AI私教班学习日表。
-- - 与 dws.topic_user_active_detail_day 按 u_user + day 关联；含 *_day 后缀分层字段（与活跃日表同名字段语义不完全等同，见 table-relations）；与 dw.dim_user 可按 u_user 对齐
--   - C端活跃用户中AI定制班的学习数据

-- 【统计口径】
--   study_duration > 0 表示学习AI定制班

-- 【常用关联】
--   - u_user、day 对齐 dws.topic_user_active_detail_day

-- 【常用筛选条件】
--   - day、分层字段

-- 【注意事项】
--   - 更新频率 T+1

-- =====================================================

CREATE TABLE
  `aws`.`mid_active_user_ai_personalized_class_day` (
    `week` varchar(1073741824) DEFAULT NULL COMMENT '统计周',
    `month` varchar(1073741824) DEFAULT NULL COMMENT '统计月',
    `user_sk` int(11) DEFAULT NULL COMMENT '数仓用户sk',
    `u_user` varchar(1073741824) DEFAULT NULL COMMENT '用户id',
    `mid_active_type` varchar(1073741824) DEFAULT NULL COMMENT '中学活跃类型',
    `user_pay_status_statistics` varchar(1073741824) DEFAULT NULL COMMENT '新增(统计日期当天注册的)、付费(统计日期之前买过正价课)、老未(统计日期之前注册的)',
 `user_pay_status_business` varchar(1073741824) DEFAULT NULL COMMENT '付费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)',
 `business_user_pay_status_statistics` varchar(1073741824) DEFAULT NULL COMMENT '新增(统计日期当天注册的)、大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、老未(统计日期之前注册的)',
    `user_stage_name` varchar(1073741824) DEFAULT NULL COMMENT '学段',
    `user_grade_name` varchar(1073741824) DEFAULT NULL COMMENT '年级',
    `user_vip_tag` varchar(1073741824) DEFAULT NULL COMMENT '会员身份标签',
    `class_id` bigint(20) DEFAULT NULL COMMENT '班id',
    `class_name` varchar(1073741824) DEFAULT NULL COMMENT '班级名称',
    `class_grade_name` varchar(1073741824) DEFAULT NULL COMMENT '班课年级',
    `class_subject_name` varchar(1073741824) DEFAULT NULL COMMENT '班课学科',
    `class_level_name` varchar(1073741824) DEFAULT NULL COMMENT '班课水平分级',
    `user_level_label` varchar(1073741824) DEFAULT NULL COMMENT '用户当前成绩水平',
    `ai_personalized_class_user_sk` int(11) DEFAULT NULL COMMENT 'AI定制班用户sk(大会员在期)',
    `non_ai_personalized_class_user_sk` int(11) DEFAULT NULL COMMENT '非AI定制班用户sk(大会员在期)',
    `study_duration` int(11) DEFAULT NULL COMMENT '学习时长',
    `finsh_flows_cnt` int(11) DEFAULT NULL COMMENT '完成的学习内容个数',
 `click_study_page_subtab_user_sk` int(11) DEFAULT NULL COMMENT '进入AI定制班tab页用户sk(clickStudyPageSubTab和enterAIPersonalizedClassHomePage)',
    `enter_ai_personalized_class_start_page_user_sk` int(11) DEFAULT NULL COMMENT '曝光AI定制班开启页用户sk-首次定制',
    `enter_ai_personalized_class_process_step_identity_user_sk` int(11) DEFAULT NULL COMMENT '进入身份选择步骤用户sk-首次定制',
    `enter_ai_personalized_class_process_step_grade_user_sk` int(11) DEFAULT NULL COMMENT '进入年级选择步骤用户sk-首次定制',
    `enter_ai_personalized_class_process_step_subject_user_sk` int(11) DEFAULT NULL COMMENT '进入学科选择步骤用户sk-首次定制',
    `enter_ai_personalized_class_process_step_score_user_sk` int(11) DEFAULT NULL COMMENT '进入成绩水平选择步骤用户sk-首次定制',
    `enter_ai_personalized_class_process_step_rank_user_sk` int(11) DEFAULT NULL COMMENT '进入排名选择步骤用户sk-首次定制',
    `enter_ai_personalized_class_process_step_textbook_user_sk` int(11) DEFAULT NULL COMMENT '进入教材选择步骤用户sk-首次定制',
    `enter_ai_personalized_class_process_step_plan_user_sk` int(11) DEFAULT NULL COMMENT '进入时间安排选择步骤用户sk-首次定制',
    `enter_ai_personalized_class_process_step_exam_type_user_sk` int(11) DEFAULT NULL COMMENT '进入考试类型选择步骤用户sk-首次定制',
    `enter_ai_personalized_class_process_step_exam_target_user_sk` int(11) DEFAULT NULL COMMENT '进入考试目标选择步骤用户sk-首次定制',
    `enter_ai_personalized_class_process_step_exam_date_user_sk` int(11) DEFAULT NULL COMMENT '进入考试日期选择步骤用户sk-首次定制',
    `enter_ai_personalized_class_process_finish_page_user_sk` int(11) DEFAULT NULL COMMENT '进入定制结果页用户sk-首次定制',
    `popup_ai_personalized_class_npc_dialog_1_user_sk` int(11) DEFAULT NULL COMMENT '进入首次引导1用户sk-首次定制',
    `popup_ai_personalized_class_npc_dialog_2_user_sk` int(11) DEFAULT NULL COMMENT '进入首次引导2用户sk-首次定制',
    `popup_ai_personalized_class_npc_dialog_3_user_sk` int(11) DEFAULT NULL COMMENT '进入首次引导3用户sk-首次定制',
    `popup_ai_personalized_class_npc_dialog_4_user_sk` int(11) DEFAULT NULL COMMENT '进入首次引导4用户sk-首次定制',
    `popup_ai_personalized_class_npc_dialog_5_user_sk` int(11) DEFAULT NULL COMMENT '进入首次引导5用户sk-首次定制',
    `enter_ai_personalized_class_home_page_user_sk` int(11) DEFAULT NULL COMMENT '进入定制班主页用户sk-首次定制',
    `status` varchar(1073741824) DEFAULT NULL COMMENT '用户完成度状态',
    `process` varchar(1073741824) DEFAULT NULL COMMENT '用户完成度',
    `today_process` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，用户当天的学习完成度',
    `non_today_max_process` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，用户学习非当天内容的最高完成度',
    `before_today_max_process` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，用户学习当天之前内容的最高完成度',
    `after_today_process` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，用户学习当天之后内容的最高完成度',
    `term` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，首次定制时用户选择的学习周期',
 `enter_ai_personalized_class_process_step_study_period_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，首次定制进入学习周期选择步骤的用户sk',
 `enter_ai_personalized_class_process_step_study_days_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，首次定制进入学习天数选择步骤的用户sk',
 `enter_ai_personalized_class_process_step_study_goal_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，首次定制进入学习目标选择步骤的用户sk',
 `enter_ai_personalized_class_process_step_end_date_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，首次定制进入结束日期选择步骤的用户sk',
 `click_ai_personalized_class_course_adjust_confirm_dialog_button_reconfirm_cnt` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，完成调整班课的次数',
 `click_ai_personalized_class_course_adjust_confirm_dialog_button_quit_cnt` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，提前退出班课的次数',
 `click_ai_personalized_class_home_switch_tab_button_study_status_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，点击学习动态tab的用户sk',
 `click_ai_personalized_class_home_switch_tab_button_my_class_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，点击全部班课tab的用户sk',
 `click_ai_personalized_class_course_module_class_recommend_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，点击班课推荐模块的用户sk',
 `click_ai_personalized_class_course_module_class_arrange_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，点击班课安排模块的用户sk',
 `click_ai_personalized_class_course_module_class_learning_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，点击进行中的班课模块的用户sk',
 `click_ai_personalized_class_course_module_class_record_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，点击班课记录模块的用户sk',
 `click_ai_personalized_class_course_module_class_all_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，点击所有班课模块的用户sk',
 `enter_ai_personalized_class_process_finish_page_class_recommend_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，通过班课推荐进入定制结果页的用户sk',
 `click_ai_personalized_class_join_button_user_sk` varchar(1073741824) DEFAULT NULL COMMENT '统计周期内，通过手动加入进入定制结果页的用户sk',
    `user_attribution` varchar(1073741824) DEFAULT NULL COMMENT '用户归属',
    `real_identity` varchar(1073741824) DEFAULT NULL COMMENT '用户真实身份',
    `day` int(11) DEFAULT NULL
 ) PARTITION BY (day) COMMENT ("ai定制版监控表") PROPERTIES ("location" = "tos://yc-data-platform/user/hive/warehouse/aws.db/mid_active_user_ai_personalized_class_day");

-- =====================================================
-- 枚举值
-- =====================================================
--
-- > 按 glossary【平台】规则 R34：本表为 **AWS** AI 定制班学习监控应用表；分层与身份类字段与活跃/用户主题链路同源。
-- > `user_pay_status_statistics`、`user_pay_status_business`、`business_user_pay_status_statistics`：语义见列 **COMMENT**；取数口径以知识库约定为准（优先 `business_user_pay_status_*` 系列时可对照 `dws.topic_user_info.sql` / `aws.business_active_user_last_14_day.sql` 第三段）。
-- > `user_stage_name`、`user_grade_name`、`user_attribution`、`real_identity`、`user_vip_tag`：**继承** `dws.topic_user_active_detail_day.sql` 或 `dws.topic_user_info.sql` 第三段同主题字段说明（以落表 JOIN 为准）。
-- > `status`、`process`、`today_process` 等完成度相关字符串：以线上取值与 **COMMENT** 为准；海量埋点漏斗列以指标含义理解，不穷举。
-- > 布尔/时长/次数类列不在此段展开。
--
