-- =====================================================
-- 公用- 用户基础信息历史表 dw.dim_user_his
-- =====================================================
--
-- 【表粒度】
--   一个用户一天一条记录（维度表；u_user / user_sk；分区字段：day）
--
-- 【业务定位】
--   - 【归属】公用 / 用户基础信息历史表。
--   - 全库用户主数据；事实表/活跃/订单宽表 JOIN 键 u_user
--
-- 【数据来源】
--  底层

-- 【统计口径】
--   去重用户数：COUNT(DISTINCT u_user)
--
-- 【常用关联】
--   - u_user = 各事实/汇总表.u_user（或 aws 侧 user_id 对照见 `knowledge/table-relations.md`）
--
-- 【常用筛选条件】
--   - day = 日期 - 分区字段，必须存在

--   场景条件：
--   - attribution — 区分用户归属（按需求）
--   - ARRAY_CONTAINS(user_allocation, '电销') 等 — 服务期分析
--   - real_identity — 家长判断见 `knowledge/glossary.md`
--
-- 【注意事项】
--   - phone 等可能为 Base64，解码见 `knowledge/glossary.md` 附录「通用规则」R01
--   - 更新频率 T+1

CREATE EXTERNAL TABLE `dw`.`dim_user_his` (
  `user_sk` int COMMENT '数仓用户sk',
  `u_user` string COMMENT '用户id',
  `system_id` string COMMENT '系统id',
  `onion_id` string COMMENT '洋葱id',
  `name` string COMMENT '姓名',
  `nickname` string COMMENT '昵称',
  `gender` string COMMENT '性别',
  `role` string COMMENT '身份',
  `school_id` string COMMENT '学校id',
  `school_sk` int COMMENT '学校sk',
  `school_sk1` int COMMENT '学校sk1',
  `channel` string COMMENT '注册渠道',
  `is_put_channel` boolean COMMENT '是否投放渠道',
  `is_room` boolean COMMENT '是否有班',
  `u_from` string COMMENT '系统平台',
  `grade` string COMMENT '年级',
  `type` string COMMENT '注册方式(枚举值)',
  `province` string COMMENT '省',
  `province_code` string COMMENT '省代码',
  `city` string COMMENT '市',
  `city_code` string COMMENT '市代码',
  `area` string COMMENT '地区',
  `area_code` string COMMENT '区',
  `region_source` string COMMENT '区域数据来源',
  `learning_time` double COMMENT '学习时长',
  `teaching_type` string COMMENT '教学类型',
  `teacher_organization` string COMMENT '教师用户的单位属性',
  `regist_time` timestamp COMMENT '注册时间',
  `activate_date` timestamp COMMENT '激活时间',
  `regist_time_sk` int COMMENT '注册date_sk',
  `activate_date_sk` int COMMENT '激活date_sk',
  `level` int COMMENT '等级',
  `coins` double COMMENT '洋葱币数量',
  `points` double COMMENT '经验值数',
  `scores` double COMMENT '23个技能总分',
  `verified_by_phone` boolean COMMENT '手机号是否经过验证',
  `is_parents` boolean COMMENT '是否家长',
  `tenant` string COMMENT '校园版id',
  `trial_type` int COMMENT '是否为新商品实验组',
  `is_test_user` boolean COMMENT '是否为测试用户',
  `is_agent_user` boolean COMMENT '是否归属代理商',
  `realname` string COMMENT '用户真实姓名',
  `auth_type` array < string > COMMENT '认证方式列表',
  `stage_id` int COMMENT '学段id',
  `subject_id` int COMMENT '学科id',
  `is_admin_room` boolean COMMENT '是否为维护班级',
  `regist_app_version` string COMMENT '注册app版本',
  `school_tag` int COMMENT '学校标签：0:非维护学校，1普通维护学校，2、重点维护学校',
  `is_room_user` boolean COMMENT '是否是有班用户',
  `is_teach_user` boolean COMMENT '是否是有教学班用户',
  `regist_entrance_id` string COMMENT '注册入口',
  `os` string COMMENT '操作系统',
  `is_bind_parent` boolean COMMENT '是否绑定家长用户',
  `ladder_info_list` array < string > COMMENT '天梯试炼场数据',
  `skills` array < int > COMMENT '用户能力值',
  `attribution` string COMMENT '用户归属',
  `user_attribution` string COMMENT '数仓计算用户当天归属',
  `regist_user_attribution` string COMMENT '数仓计算用户注册时归属',
  `study_book_info` string COMMENT '学生当前的教学版本和学期信息',
  `study_book_info_array` array < string > COMMENT '学生当前的教学版本和学期信息(数组)',
  `phone` string COMMENT '手机号',
  `email` string COMMENT '邮箱',
  `qq_no` string COMMENT 'qq号',
  `user_allocation` array < string > COMMENT '用户全域服务期',
  `user_vip_tag` string COMMENT '会员身份标签',
  `regist_user_allocation` array < string > COMMENT '用户注册当天服务期归属',
  `real_identity` string COMMENT '用户真实身份',
  `user_risk` string COMMENT '用户风险',
  `user_identity` string COMMENT '用户身份：研究员：common，高级研究员：advanced，首席研究员：lead，体验版首席研究员：expLead',
  `core_first_activated_date` timestamp COMMENT '首次激活洋葱学园app产品时间',
  `user_lifecycle_stage` string COMMENT '引入期：注册天数 <= 13 （注册当天是0） 成长期：14 <= 注册天数 <= 30  成熟期：注册天数31天及以上',
  `is_provost_teacher` int COMMENT '是否确认老师',
  `is_ai_room_user` int COMMENT '是否ai班级用户'
) COMMENT '一个用户一条记录' PARTITIONED BY (`day` int) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dw.db/dim_user_his'

-- =====================================================
-- 枚举值
-- =====================================================

-- ## attribution（用户归属）
--
-- > 用户归属：用户归属，用于用户归属分析。与user_attribution字段含义相同。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | b | b端用户，智课团队的用户 |
-- | c | c端用户，非智课团队的用户 |
-- | null | 未知用户 |
--
-- ## stage_id（学段）
--
-- > 线上 `SELECT DISTINCT stage_id FROM dw.dim_user ORDER BY stage_id`（经跳板机查询，取值以库为准）。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类 |
-- | -1 | 未归类 |
-- | 0 | 学龄前 |
-- | 1 | 小学 |
-- | 2 | 初中 |
-- | 3 | 高中 |
-- | 4 | 中职 |
-- | 5 | 未归类 |
--
-- ## grade（年级）
--
-- > 线上 `SELECT DISTINCT grade FROM dw.dim_user ORDER BY grade`（经跳板机查询，取值以库为准）。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 学龄前 | 学龄前 |
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
-- | 职一 | 职一 |
-- | 职二 | 职二 |
-- | 职三 | 职三 |
-- | NULL | 未归类 |

