-- =====================================================
-- 员工飞书系统入离职信息表 crm.staff_change
-- =====================================================
--
-- 【表粒度】★必填
--   一各员工一次信息改动一条记录 = 一条数据
--   同一员工(employment_no)可能有多条记录（调岗、转正、二次入职等），
--   取最新一条需 ROW_NUMBER() OVER(PARTITION BY employment_no ORDER BY created_at DESC) = 1
--
-- 【业务定位】
--   员工入离职信息的权威来源（来自飞书人事系统）
--   与 crm.worker 的区别：
--   - 本表：存入离职时间、雇佣状态，是"人事维度"的员工信息
--   - crm.worker：存坐席业务属性（工号、星级、销售类型），是"业务维度"的坐席信息
--   两表需组合使用：本表提供入离职时间，crm.worker 提供坐席 id 和业务属性
--
-- 【常用关联】
--   坐席信息（最常用）：
--     本表.email = crm.worker.mail
--     · 通过邮箱关联，获取坐席 id(crm.worker.id)、手机号(crm.worker.phone)等
--     · ⚠️ 关联后需 WHERE crm.worker.id IS NOT NULL（排除未匹配坐席的人事记录）
--
-- 【注意事项】
--   ⚠️ 入职时间需截取：SUBSTR(start_date, 1, 10)（原始字段为 timestamp）
--   ⚠️ stop_date 特殊值处理：
--     - '0001-01-01' 和 '0001-01-03' 表示在职，需转为 NULL：
--       IF(SUBSTR(stop_date,1,10) IN ('0001-01-01','0001-01-03'), NULL, SUBSTR(stop_date,1,10))
--   ⚠️ 同一员工多条记录时必须去重：
--     ROW_NUMBER() OVER(PARTITION BY employment_no ORDER BY created_at DESC) = 1
--
-- =====================================================

CREATE TABLE
  `crm`.`staff_change` (
    `id` bigint COMMENT '主键',
    `created_at` timestamp COMMENT '记录创建时间（去重排序用，取最新一条）',
    `updated_at` timestamp COMMENT '最近一次更新时间',
    `deleted_at` timestamp COMMENT '记录删除时间',
    `email` string COMMENT '邮箱（★关联 crm.worker.mail）',
    `department` string COMMENT '部门信息（飞书组织架构文本）',
    `user_name` string COMMENT '员工姓名',
    `start_date` timestamp COMMENT '入职时间（使用时 SUBSTR(,1,10) 取日期部分）',
    `stop_date` timestamp COMMENT '离职/停止时间（0001-01-01 和 0001-01-03 表示在职，需转 NULL）',
    `status` bigint COMMENT '任职状态',
    `user_id` string COMMENT '北森用户ID',
    `employment_id` string COMMENT '雇佣ID',
    `employment_no` string COMMENT '雇佣工号（★去重分组用，同一工号取 created_at 最新记录）',
    `job_data_id` string COMMENT '任职ID',
    `person_id` string COMMENT '飞书人事人员信息ID'
  ) ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH
  SERDEPROPERTIES ('field.delim' = '', 'serialization.format' = '') STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/crm.db/staff_change' TBLPROPERTIES (
    'STATS_GENERATED_VIA_STATS_TASK' = 'true',
    'bucketing_version' = '2',
    'transient_lastDdlTime' = '1739207843'
  )
