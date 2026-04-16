-- =====================================================
-- 用户主题信息周表 dws.topic_user_info_week
-- =====================================================
--
-- 【表粒度】
--   每用户 × 周一条（分区 week；week_start/end_date_sk 见字段 COMMENT）
--
-- 【业务定位】
--   - 与 topic_user_info_month 同主题：周表用 week、active_type；月表含月初快照类字段
--   - 同族表：dws.topic_user_info_month（分区 month）
--
-- 【统计口径】
--   周期内活跃/付费标签含义见字段 COMMENT；本表仅有物理列 `user_pay_status_*`，知识库取数与口径统一使用 `business_user_pay_status_*`（见 `dws.topic_user_info` / glossary）
--
-- 【常用筛选条件】
--   场景条件：
--   - is_test_user 等按需求
--
-- 【注意事项】
--   - 更新频率：周更
--   - 【数据来源】code/sql/临时文件/dws.topic_user_info_week.md
--   - 知识库约定：取数与分析仅使用 business_user_pay_status_*；

-- =====================================================

CREATE EXTERNAL TABLE `dws`.`topic_user_info_week` (
  `week_start_date_sk` int COMMENT '周开始时间',
  `week_end_date_sk` int COMMENT '周结束时间',
  `user_sk` int COMMENT '数仓用户sk',
  `u_user` string COMMENT '用户id',
  `role` string COMMENT '身份',
  `grade_id` string COMMENT '年级id',
  `grade_name` string COMMENT '年级id',
  `stage_id` string COMMENT '学段id',
  `stage_name` string COMMENT '学段名称',
  `gender` string COMMENT '性别',
  `regist_time` timestamp COMMENT '注册时间',
  `regist_time_date_sk` int COMMENT '注册date_sk',
  `regist_user_attribution` string COMMENT '注册当天用户归属',
  `active_user_attribution` string COMMENT '活跃当天用户归属-数仓计算- 统计周期内最新的状态',
  `user_attribution` string COMMENT '用户归属-业务计算- 统计周期内最新的状态',
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
  `school_name` string COMMENT '学校名字',
  `school_sk` int COMMENT '学校sk',
  `real_school_id` string COMMENT '修正后的学校id',
  `real_school_name` string COMMENT '修正后的学校名字',
  `real_school_sk` int COMMENT '修正后的学校sk',
  `is_test_user` smallint COMMENT '是否为测试用户',
  `is_teach_user` smallint COMMENT '是否是有教学班用户',
  `is_admin_room_user` smallint COMMENT '是否行政班用户',
  `is_room_user` smallint COMMENT '是否是有班用户',
  `is_new_user` smallint COMMENT '是否新(周期内注册)用户（1:是，0:否）',
  `is_active_user` smallint COMMENT '是否周期内活跃',
  `is_learn_active_user` smallint COMMENT '是否周期内学习活跃',
  `is_vip_user` smallint COMMENT '是否VIP用户',
  `ss_arr` array < string > COMMENT '当前的vip的学段学科数组',
  `is_mid_active_user` smallint COMMENT '是否中学活跃用户',
  `is_regist_30day_user` smallint COMMENT '是否30天注册用户（包含30天， 注册时间-周期第一天<=30）',
  `active_type` string COMMENT '用户活跃类型-优先判断新增用户， 其他类型取统计周期内第一次活跃类型',
  `user_pay_status_statistics` string COMMENT '【知识库不引用】取数用 business_user_pay_status_statistics。原：付费标签：统计维度口径',
  `user_pay_status_business` string COMMENT '【知识库不引用】取数用 business_user_pay_status_business。原：付费标签：业务维度统计口径',
  `user_allocation` array < string > COMMENT '用户全域服务期',
  `user_vip_tag` string COMMENT '用户vip标签',
  `user_identity` string COMMENT '用户身份：研究员：common，高级研究员：advanced，首席研究员：lead，体验版首席研究员：expLead'
)
COMMENT '每周每个用户保留一条数据'
PARTITIONED BY (`week` string COMMENT '分区：week')

ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
LOCATION 'tos://yc-data-platform/user/hive/warehouse/dws.db/topic_user_info_week'

-- =====================================================
-- 枚举值
-- =====================================================
--
-- （待补充：按 `knowledge/SPEC.md` 与 `表结构模版.md`，将关键字段枚举从线上 COMMENT 或 `knowledge_old/enums.md` 整理至下表；布尔/二值字段仅在字段 COMMENT 说明，可不列本段。）
--
-- ## 示例字段名（字段说明）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | （待补充） | （待补充） |
