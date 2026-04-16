-- =====================================================
-- 用户习题练习记录表 dw.fact_user_exercise_day
-- =====================================================
--
-- 【表粒度】★必填
--  一次练习=一条记录（exercise_id+user_sk唯一标识） 
--  同一个用户（u_user）会对应多条观看视频id（exercise_id）	
--  可能不同人看练习的exercise_id会上报重复
--   
-- 【统计口径】
-- 做题道数=sum(problem_cnt) 
--
-- 【常用筛选条件】
--   ★必加条件（任何查询都必须带）：
--   ★day between 开始时间 and  结束时间     --分区表，需要选时间区间，格式yyyymmdd
--
-- =====================================================

CREATE TABLE
  `dw`.`fact_user_exercise_day` (
    `exercise_id` string COMMENT '测试对应的id，每次参与测试，即使测试内容一样，这个id也不同。整合后的测试ID，将专项练习、天梯测试等信息集合在一起',
    `exercise_type` string COMMENT '测试类型中文',
    `user_sk` int COMMENT '数仓中的用户id',
    `u_user` string COMMENT '用户id',
    `term_sk` int COMMENT '学段学科学期教材版本维度(学期)',
    `date_sk` int COMMENT '测试的日期',
    `hour_sk` int COMMENT '测试的时间，精确到小时',
    `test_id` string COMMENT '练习类型id:如果是章节检测，就是章节id；如果是大节检测，就是大节id，如果是小节检测就是小节id',
    `client_os` string COMMENT '观看视频的客户端os（android/ios/pc）',
    `start_time` timestamp COMMENT '开始测试时间',
    `learn_duration` double COMMENT '本次测试时长（秒）',
    `problem_cnt` int COMMENT '测试中的问题总数',
    `correct_cnt` int COMMENT '答题正确数，未答记为错误',
    `problem_load_error_cnt` int COMMENT '题目加载失败次数',
    `problem_submit_error_cnt` int COMMENT '题目提交失败次数',
    `is_finish` boolean COMMENT '本次测试是否完成',
    `result_sk` int COMMENT '测试的结果id（是否通过、是否降级、定级结果、获得的经验等）',
    `result_type` string COMMENT '测试结果的中文',
    `rank_code` int COMMENT '测试完成后的段位代码',
    `rank_name` string COMMENT '测试完成后的段位名称',
    `role` string COMMENT '客户分类（Student、Teacher、Parent）',
    `product_id` string COMMENT '产品id',
    `app_version` string COMMENT '"客户端版本号3.4.0"',
    `create_time` timestamp COMMENT '源系统创建条目的时间',
    `update_time` timestamp COMMENT '源系统修改条目的时间',
    `dw_insert_time` timestamp COMMENT 'ETL插入记录的时间',
    `dw_update_time` timestamp COMMENT 'ETL修改记录的时间',
    `new_group_type` string COMMENT '习题解析优化项目',
    `course_package_id` string COMMENT '课程包字段',
    `u_channel` string COMMENT '下载渠道',
    `device` string COMMENT '设备ID',
    `d_os_version` string COMMENT '系统版本',
    `net_config` string COMMENT '网络类型',
    `d_model_name` string COMMENT '手机型号',
    `d_model_brand` string COMMENT '用户手机品牌',
    `publisher_id` int COMMENT '版本',
    `semester_id` int COMMENT '学期',
    `subject_id` int COMMENT '学科',
    `stage_id` int COMMENT '学段',
    `stem_cnt` int COMMENT '题干数-大题数',
    `event_id` string COMMENT '事件ID',
    `practice_scene` string COMMENT '入口类型',
    `difficulty_level` string COMMENT '练习难度',
    `sn_code` string COMMENT '洋葱星球sn码',
    `is_pad_device` boolean COMMENT '是否pad设备',
    `study_card_learn_time` double COMMENT '学习卡片学习时长',
    `score` int COMMENT '分数'
  ) COMMENT '一次练习一条数据。exercise_type_code对应文档：https://guanghe.feishu.cn/sheets/shtcnZQNqYqvB7HLOCfCGXoHe7g' PARTITIONED BY (`day` int, `exercise_type_code` string) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dw.db/fact_user_exercise_day' TBLPROPERTIES (
    'alias' = '用户习题练习记录表',
    'bucketing_version' = '2',
    'spark.sql.partitionProvider' = 'catalog',
    'transient_lastDdlTime' = '1774411659'
  )


-- =====================================================
-- 枚举值
-- =====================================================
-- 暂时没有用到
