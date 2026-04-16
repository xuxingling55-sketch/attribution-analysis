-- =====================================================
-- 企微资源位曝光到线索到付费转化日表 aws.user_pay_process_add_wechat_day
-- =====================================================
-- 【表粒度】★必填
--   一个资源位(operate_id) × 一个场景(scene) × 一个渠道(task_id) × 一个曝光用户(get_entrance_user) 一条记录
--   按 day(int, 如 20260311) 分区
--
-- 【业务定位】
--   企微线索的完整漏斗 + 转化表，追踪以下五层转化：
--   资源位曝光 → 点击入口 → 曝光坐席二维码 → 添加坐席微信 → 成功拉取入库(=企微线索)
--   在此基础上追踪拉取入库用户的付费转化（7天/14天/当月三个窗口）
--
-- 【数据来源】
--   events.frontend_event_orc         —— 埋点数据：曝光(get_PaySceneEntrance) + 点击(click_PaySceneEntrance)
--   crm.new_user                      —— 企微添加记录（channel=3），时间窗口：当天到次日凌晨1:00
--   aws.clue_info                     —— 线索领取记录，通过 we_com_open_id 关联判断是否成功拉取入库
--   dws.topic_user_active_detail_day  —— 用户属性（当天值）
--   dw.dim_grade                      —— 年级→学段映射维表
--   aws.crm_order_info                —— 电销订单（is_test=false, in_salary=1, worker_id<>0）
--   user_allocation.user_allocation   —— 用户服务期归属（曝光前服务期）
--   crm.qr_code_change_history        —— 渠道活码历史变更记录（场景名称、渠道等级、渠道入口名称）
--   线索领取表说明：dw.fact_clue_allocate_info 为线索领取底层表；aws.clue_info 为数仓加工后的线索领取表，BI 取数常用。
--
-- 【企微漏斗五层】
--   第1层 get_entrance_user   资源位曝光用户
--   第2层 click_entrance_user 点击资源位用户（曝光用户的子集）
--   第3层 get_wechat_user     曝光坐席二维码的用户（点击用户的子集）
--   第4层 add_wechat_user     添加坐席微信的用户（曝光二维码用户的子集）
--   第5层 pull_wechat_user    被成功拉取入库的用户 = 企微线索（添加微信用户的子集）
--
-- 【转化窗口（基于 pull_wechat_user，仅拉取入库用户才计算转化）】
--   7天转化:  pay_time BETWEEN day AND day+7（共8天，含当天）
--   14天转化: pay_time BETWEEN day AND day+14（共15天，含当天）
--   当月转化: pay_time BETWEEN day AND last_day(day)（截止当月月底）
--
-- 【用户属性取值时点】
--   取当天(day)的活跃表数据
--
-- 【添加/拉取微信时间窗口】
--   当天 00:00:00 到次日 01:00:00（多延1小时，覆盖跨天添加场景）
--
-- 【常用筛选条件】
--   ★必加条件：
--   无
--
--   场景条件：
--   - day 按分区过滤（int 类型，格式 yyyyMMdd）
-- =====================================================

CREATE EXTERNAL TABLE `aws`.`user_pay_process_add_wechat_day` (
  `scene` string COMMENT '资源位对应的场景标识',
  `option` string COMMENT '点击场景后跳转的页面类型',
  `operate_id` string COMMENT '资源位ID',
  `page_type` string COMMENT '页面类型，固定值"引流"',
  `task_id` string COMMENT '资源位对应的渠道活码ID',
  `get_entrance_user` string COMMENT '资源位曝光的用户ID',
  `click_entrance_user` string COMMENT '点击资源位的用户ID',
  `get_wechat_user` string COMMENT '曝光了坐席二维码的用户ID',
  `add_wechat_user` string COMMENT '添加了坐席微信的用户ID',
  `pull_wechat_user` string COMMENT '被坐席成功拉取入库的用户ID',
  `info_uuid` string COMMENT '拉取入库对应的线索领取记录ID',
  `grade` string COMMENT '【当天值】年级',
  `gender` string COMMENT '【当天值】性别',
  `regist_time` timestamp COMMENT '注册时间',
  `user_attribution` string COMMENT '用户注册当天归属',
  `active_user_attribution` string COMMENT '【当天值】用户活跃时归属',
  `city_class` string COMMENT '【当天值】用户城市分线',
  `province` string COMMENT '【当天值】省名称',
  `city` string COMMENT '【当天值】市名称',
  `user_pay_status_statistics` string COMMENT '【当天值】统计维度付费状态：新增、老未、付费',
  `user_pay_status_business` string COMMENT '【当天值】业务维度付费状态：新用户、老用户、付费用户',
  `paid_7d_user` string COMMENT '拉取入库后7天内转化用户ID',
  `paid_7d_order_cnt` bigint COMMENT '拉取入库后7天内转化订单量',
  `paid_7d_amount` double COMMENT '拉取入库后7天内转化付费金额',
  `paid_14d_user` string COMMENT '拉取入库后14天内转化用户ID',
  `paid_14d_order_cnt` bigint COMMENT '拉取入库后14天内转化订单量',
  `paid_14d_amount` double COMMENT '拉取入库后14天内转化金额',
  `paid_current_month_user` string COMMENT '拉取入库后截止当月月底转化用户ID',
  `paid_current_month_order_cnt` bigint COMMENT '拉取入库后截止当月月底转化订单量',
  `paid_current_month_amount` double COMMENT '拉取入库后截止当月月底转化金额',
  `event_time` bigint COMMENT '曝光事件时间戳（毫秒级）',
  `before_get_entrance_team_name` string COMMENT '曝光前用户所属服务期团队名称',
  `scene_name` string COMMENT '渠道活码场景名称',
  `clue_level_name` string COMMENT '渠道活码等级名称',
  `resource_entrance_name` string COMMENT '渠道活码入口名称',
  `type_name` string COMMENT '渠道活码类型名称（排除"测试类型"）',
  `stage_name` string COMMENT '【当天值】学段'
) COMMENT '一个资源位id一个资源位的场景一个资源位的渠道id一个资源位曝光用户一条记录' PARTITIONED BY (`day` int) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/user_pay_process_add_wechat_day' TBLPROPERTIES (
  'alias' = '资源位曝光到线索到企业微信到付费的转化表',
  'bucketing_version' = '2',
  'discover.partitions' = 'true',
  'is_core' = 'true',
  'last_modified_by' = 'master',
  'last_modified_time' = '1765281184',
  'spark.sql.create.version' = '2.2 or prior',
  'transient_lastDdlTime' = '1770629437'
)

-- =====================================================
-- 枚举值
-- =====================================================
-- ## grade（年级）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 学龄前 | 启蒙 |
-- | 一年级 | 小学 |
-- | 二年级 | 小学 |
-- | 三年级 | 小学 |
-- | 四年级 | 小学 |
-- | 五年级 | 小学 |
-- | 六年级 | 小学 |
-- | 七年级 | 初中 |
-- | 八年级 | 初中 |
-- | 九年级 | 初中 |
-- | 高一 | 高中 |
-- | 高二 | 高中 |
-- | 高三 | 高中 |
-- | 职一 | 中职 |
-- | 职二 | 中职 |
-- | 职三 | 中职 |
-- | NULL | 未填写 |
--
-- ## stage_name（学段）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 启蒙 | 学龄前 |
-- | 小学 | 一年级~六年级 |
-- | 初中 | 七年级~九年级 |
-- | 高中 | 高一~高三 |
-- | 中职 | 职一~职三 |
-- | NULL | 未填写 |
--
-- ## gender（性别）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | male | 男 |
-- | female | 女 |
--
-- ## user_attribution（用户注册当天归属）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | c | C端用户 |
-- | b | B端用户 |
-- | 中学用户 | C端用户 |
-- | 小学用户 | C端用户 |
-- | B端用户 | B端用户 |
-- | NULL | 未填写 |
--
-- ## active_user_attribution（用户活跃时归属）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | c | C端用户 |
-- | b | B端用户 |
--
-- ## city_class（城市分线）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 一线 | |
-- | 二线 | |
-- | 三线 | |
-- | 四线 | |
-- | 五线 | |
-- | NULL | 未填写 |
--
-- ## before_get_entrance_team_name（曝光前服务期团队）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 入校 | |
-- | 电销/网销 | |
-- | 体验营 | |
-- | 新媒体视频 | |
-- | 研学 | |
-- | 本地化 | |
-- | 商业化-公域 | |
-- | 商业化-APP | |
-- | 伴学团队 | |
-- | 无服务期 | 用户曝光时不在任何服务期内 |
--
-- ## type_name（渠道活码类型）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 阿拉丁 | |
-- | 电销私域 | |
-- | AI机器人 | |
-- | 研学 | |
-- | 测试类型 | 测试数据，分析时需排除 |
--
-- ## clue_level_name（渠道活码等级名称）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | A+级 | |
-- | S级 | |
-- | A级 | |
-- | B级 | |
-- | C级 | |
-- | NULL | 未分级 |

