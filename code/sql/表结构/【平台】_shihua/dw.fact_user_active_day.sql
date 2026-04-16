-- =====================================================
-- 活跃转化- 用户活跃日表 dw.fact_user_active_day
-- =====================================================
--
-- 【表粒度】
--   用户 × 活跃日一条（分区 day int；明细级活跃）
--
-- 【业务定位】
--   - 【归属】活跃转化 / 用户活跃日表。
--   - 明细活跃、行政班 is_admin_room 等；与汇总宽表 topic_user_active_detail_day 粒度不同
--
-- 【统计口径】
--   COUNT(DISTINCT u_user) 等按需求
--
-- 【常用关联】
--   - `date_sk` 与 `dw.dim_date`；`u_user` 与 `dw.dim_user`；汇总宽表为 `dws.topic_user_active_detail_day`（粒度不同，勿直接混加）
--
-- 【常用筛选条件】
--   场景条件：
--   - is_test_user、is_admin_room 等按场景
--
-- 【注意事项】
--   - 更新频率 T+1

CREATE EXTERNAL TABLE `dw`.`fact_user_active_day` (
  `role` string COMMENT '角色',
  `u_user` string COMMENT '用户id',
  `os` string COMMENT '用户活跃的os',
  `device` string COMMENT '设备号',
  `model` string COMMENT '设备类型',
  `d_app_version` string COMMENT '用户使用的App版本号',
  `date_id` string COMMENT '活跃日期',
  `platform` string COMMENT '用户活跃于app还是pc',
  `teaching_type` string COMMENT '教学类型',
  `user_sk` int COMMENT '用户id',
  `date_sk` int COMMENT '活跃日期',
  `product_id` string COMMENT '产品ID',
  `u_channel` string COMMENT '下载渠道',
  `d_os_version` string COMMENT '操作系统版本号',
  `net_config` string COMMENT '用户网络类型',
  `d_model_brand` string COMMENT '用户手机品牌',
  `d_model_name` string COMMENT '手机型号',
  `active_hour_arr` array < smallint > COMMENT '活跃的小时点',
  `active_time` timestamp COMMENT '活跃的时间戳',
  `grade` string COMMENT '用户填写年级',
  `mid_grade` string COMMENT '中学修正年级',
  `mid_stage_name` string COMMENT '中学修正学段',
  `gender` string COMMENT '用户性别',
  `regist_time` timestamp COMMENT '注册时间',
  `regist_time_sk` int COMMENT '注册时间sk',
  `channel` string COMMENT '注册渠道',
  `u_from` string COMMENT '系统平台',
  `type` string COMMENT '注册方式(枚举值)',
  `is_put_channel` smallint COMMENT '是否投放渠道',
  `province` string COMMENT '省',
  `province_code` string COMMENT '省code',
  `city` string COMMENT '市',
  `city_code` string COMMENT '市code',
  `area` string COMMENT '区',
  `area_code` string COMMENT '区code',
  `is_test_user` smallint COMMENT '是否测试用户',
  `is_teach_user` smallint COMMENT '是否教学班用户',
  `is_admin_room` smallint COMMENT '是否行政班用户',
  `is_room_user` smallint COMMENT '是否有班用户',
  `is_new_user` smallint COMMENT '是否新用户',
  `school_sk` int COMMENT '学校sk',
  `school_id` string COMMENT '学校id',
  `school_sk1` int COMMENT '学校sk1',
  `school_id1` string COMMENT '学校id1',
  `user_attribution` string COMMENT '用户活跃时归属',
  `regist_user_attribution` string COMMENT '用户注册当天归属',
  `room_id` string COMMENT '用户行政班id',
  `agent_id` string COMMENT '用户所在学校的代理商id',
  `ss_arr` array < string > COMMENT 'vip的学段学科数组',
  `is_vip_user` smallint COMMENT '是否是vip用户',
  `device_sk` bigint COMMENT '设备代理建',
  `study_book_info` string COMMENT '学生当前的教学版本和学期信息',
  `study_book_info_array` array < string > COMMENT '学生当前的教学版本和学期信息(数组)',
  `is_pad_device` smallint COMMENT '是否是pad设备',
  `sn_code` string COMMENT 'sn_code',
  `device_type` string COMMENT '设备类型',
  `user_allocation` array < string > COMMENT '用户全域服务期',
  `user_vip_tag` string COMMENT '会员身份标签',
  `user_identity` string COMMENT '用户身份：研究员：common，高级研究员：advanced，首席研究员：lead，体验版首席研究员：expLead'
) COMMENT 'null' PARTITIONED BY (`day` int) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dw.db/fact_user_active_day'

-- =====================================================
-- 枚举值
-- =====================================================
--
-- > 按 glossary【平台】规则 R34：本表为 **DW 明细层**用户×活跃日事实；用户属性、归属、年级学段等与活跃主题宽表可对齐。
-- > **与 `dws.topic_user_active_detail_day` / `dws.topic_user_info` 同名字段**（如 `role`、`grade`、`mid_grade`、`mid_stage_name`、`gender`、`user_attribution`、`regist_user_attribution`、`channel`、`user_allocation`、`user_vip_tag`、`user_identity`、`product_id` 等）：枚举与含义 **继承** `dws.topic_user_active_detail_day.sql` 或 `dws.topic_user_info.sql` 第三段「枚举值」对应小节（以实际 JOIN 键与字段集为准）。
-- > `real_identity` 等若在上述主题表中无列，参见 `dw.dim_user.sql` 第三段（若有）或 glossary「real_identity」。
-- > 布尔/计数、设备型号、自由文本等以列 **COMMENT** 为准，不在此重复。
--
