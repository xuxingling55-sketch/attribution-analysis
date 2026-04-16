-- =====================================================
-- 学情作战地图学生月表 aws.battle_map_student_month
-- =====================================================

-- 【表粒度】
--   用户 × 月 × 班级/学校等维度一条记录（分区 month）

-- =====================================================
-- 【业务定位】
--   - 入校学情、作业完成与活跃（作战地图专题）

-- =====================================================
-- 【统计口径】
--   学习时长、完成率等见字段 COMMENT
--   来源：诗华
--
-- =====================================================

-- =====================================================
-- 【常用筛选条件】
--   场景条件：
--   - 按 school_ref、room_ref、month 筛选
--   来源：诗华
--
-- =====================================================

-- =====================================================
-- 【注意事项】
--   - 更新频率：月更（以调度为准）
--   来源：诗华
--
-- =====================================================

CREATE EXTERNAL TABLE `aws`.`battle_map_student_month` (
  `user_id` string COMMENT '用户id',
  `room_ref` string COMMENT '班级短id',
  `school_ref` string COMMENT '学校短id',
  `is_watch_video_user` int COMMENT '是否观看视频用户',
  `onion_id` int COMMENT '洋葱id',
  `is_learn_active_user` int COMMENT '用户是否学习活跃',
  `learn_duration` double COMMENT '学习时长(分钟)',
  `assigned_homework_num` int COMMENT '被布置作业数量',
  `finish_homework_num` int COMMENT '完成作业数量',
  `is_active_user` int COMMENT '用户是否活跃',
  `school_name` string COMMENT '学校名称',
  `realname` string COMMENT '用户真实名称',
  `room_name` string COMMENT '班级名称',
  `assigned_accurate_exam_num` int COMMENT '查漏补缺布置作业数量',
  `assigned_synchronized_practice_num` int COMMENT '同步练习布置作业数量',
  `assigned_test_paper_num` int COMMENT '试卷/考试真题布置作业数量',
  `assigned_preview_num` int COMMENT '微课作业布置作业数量',
  `assigned_review_num` int COMMENT '同步复习布置作业数量',
  `assigned_vacation_num` int COMMENT '暑假作业布置作业数量',
  `finish_accurate_exam_num` int COMMENT '查漏补缺完成作业数量',
  `finish_synchronized_practice_num` int COMMENT '同步练习完成作业数量',
  `finish_test_paper_num` int COMMENT '试卷/考试真题完成作业数量',
  `finish_preview_num` int COMMENT '微课作业完成作业数量',
  `finish_review_num` int COMMENT '同步复习完成作业数量',
  `finish_vacation_num` int COMMENT '暑假作业完成作业数量',
  `synchronized_practice_correct_problem_num` int COMMENT '同步练习正确题数',
  `synchronized_practice_problem_num` int COMMENT '同步练习题目数',
  `finish_homework_rate` double COMMENT '作业完成率',
  `finish_preview_rate` double COMMENT '微课作业完成率',
  `finish_synchronized_practice_rate` double COMMENT '同步练习完成率',
  `synchronized_practice_correct_rate` double COMMENT '同步练习正确率',
  `finish_review_rate` double COMMENT '同步复习完成率',
  `finish_accurate_exam_rate` double COMMENT '查漏补缺完成率',
  `finish_test_paper_rate` double COMMENT '试卷完成率',
  `finish_vacation_rate` double COMMENT '暑假作业完成率'
) PARTITIONED BY (`month` int) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/battle_map_student_month'
