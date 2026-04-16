-- =====================================================
-- 坐席信息表 crm.worker
-- =====================================================
--
-- 【表粒度】★必填
--   一个坐席 = 一条记录（id 唯一）
--
-- 【业务定位】
--   电销坐席的业务属性主表，存坐席 id、姓名、手机号、销售类型等
--   与 crm.staff_change 的区别：
--   - 本表：业务维度，是其他业务表(订单/线索/外呼)中 worker_id 的关联目标
--   - crm.staff_change：人事维度，存入离职时间（飞书人事系统来源，离职审批会有延迟）
--   两表组合使用时，本表提供 id（即 worker_id）和业务属性，staff_change 提供入离职时间
--
-- 【常用关联】
--   入离职信息：
--     本表.mail = crm.staff_change.email
--     · 获取入职时间(start_date)、离职时间(stop_date)
--     · staff_change 同一员工可能多条，需先去重再关联
--
--   业务表关联（订单/线索/外呼等）：
--     本表.id = aws.crm_order_info.worker_id
--     本表.id = aws.clue_info.worker_id（注意 clue_info 的 worker_id 是 string，需类型转换）
--     本表.id = dw.fact_call_history.worker_id（string 类型）
--
--   业绩目标：
--     本表.mail = crm.worker_goal.mail（获取个人目标时关联坐席姓名）
--
-- 【注意事项】
--   ⚠️ id 即其他表的 worker_id，是关联订单/线索/外呼的核心字段
--   ⚠️ phone 不可用
--   ⚠️ ph 字段可用于判断"购课账号是否为坐席本人"（与 dw.dim_user.phone 匹配）
--   ⚠️ join_at/leave_at 是 CRM 系统人为记录的时间，与 staff_change 的 start_date/stop_date 可能有差异，
--      人效计算以 staff_change 为准
--   ⚠️ status: 1=在职, 2=离职（CRM 系统状态，非实时，以 staff_change 为准）
--
-- =====================================================

CREATE TABLE
  `crm`.`worker` (
    `id` bigint COMMENT '坐席id',
    `created_at` timestamp COMMENT '记录创建时间',
    `updated_at` timestamp COMMENT '最近一次更新时间',
    `mail` string COMMENT '邮箱',
    `name` string COMMENT '坐席姓名',
    `phone` string COMMENT '手机号',
    `username` string COMMENT '姓名拼音',
    `customer_type` bigint COMMENT '',
    `qm_exten` string COMMENT '七陌工号',
    `call_type` bigint COMMENT '外呼方式：1-固话 ，2-小号',
    `wechat` string COMMENT '微信号',
    `avatar` string COMMENT '头像地址',
    `stage` string COMMENT '负责学段',
    `star` bigint COMMENT '坐席星级',
    `label` string COMMENT '已弃用-指定售卖商品',
    `tag` string COMMENT '已弃用-指定领取标签',
    `status` bigint COMMENT '在离职状态：1-在职，2-离职',
    `user_id` string COMMENT '企业微信id',
    `join_at` timestamp COMMENT '加入时间',
    `sale_type` bigint COMMENT '销售类型：1-电销，2-网销',
    `fetch_customer_url` string COMMENT '获客助手链接',
    `fetch_customer_url_id` string COMMENT '获客助手链接ID',
    `leave_at` timestamp COMMENT '离职时间',
    `base` bigint COMMENT '员工所属base地',
    `site_id` bigint COMMENT '站点ID',
    `feishu_open_id` string COMMENT '飞书OpenID',
    `position` bigint COMMENT '岗位：1-销售，2-其他',
    `account_id` bigint COMMENT '企业微信账号id',
    `ph` string COMMENT '加密手机号',
    `wechat_avatar` string COMMENT '企微头像'
  ) ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH
  SERDEPROPERTIES ('field.delim' = '', 'serialization.format' = '') STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/crm.db/worker' TBLPROPERTIES (
    'STATS_GENERATED_VIA_STATS_TASK' = 'true',
    'bucketing_version' = '2',
    'transient_lastDdlTime' = '1739205057'
  )

