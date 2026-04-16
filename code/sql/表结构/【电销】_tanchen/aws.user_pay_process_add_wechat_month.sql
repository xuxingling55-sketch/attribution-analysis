-- =====================================================
-- 企微资源位曝光到线索到付费转化月表 aws.user_pay_process_add_wechat_month
-- =====================================================
-- 【表粒度】★必填
--   一个资源位(operate_id) × 一个场景(scene) × 一个渠道(task_id) × 一个曝光用户(get_entrance_user) 一条记录
--   按 month(int, 如 202603) 分区
--
-- 【业务定位】
--   企微线索的月度漏斗 + 转化表，追踪以下五层转化：
--   资源位曝光 → 点击入口 → 曝光坐席二维码 → 添加坐席微信 → 成功拉取入库(=企微线索)
--   在此基础上追踪拉取入库用户的当月付费转化
--
-- 【与日表(user_pay_process_add_wechat_day)的区别】
--   1. 转化窗口：日表有 7天/14天/当月 三个窗口，月表只有当月窗口
--   2. 用户属性：日表取当天值，月表取月末最后一天的值（按 DAY DESC 排序取第一条）
--   3. 添加/拉取时间窗口：日表=当天到次日凌晨1:00，月表=月初到月末次日凌晨1:00
--   4. 月表独立跑数（不是日表聚合），数据来源相同但范围为整月
--
-- 【数据来源】
--   events.frontend_event_orc         —— 埋点数据：曝光 + 点击（整月范围）
--   crm.new_user                      —— 企微添加记录（channel=3），时间窗口：月初到月末次日凌晨1:00
--   aws.clue_info                     —— 线索领取记录（clue_source IN ('WeCom','building_blocks_goods_wecom')）
--   dws.topic_user_active_detail_day  —— 用户属性（月末值，按 DAY DESC 取第一条）
--   dw.dim_grade                      —— 年级→学段映射维表
--   aws.crm_order_info                —— 电销订单（is_test=false, in_salary=1, worker_id<>0，当月范围）
--   user_allocation.user_allocation   —— 用户服务期归属
--   crm.qr_code_change_history        —— 渠道活码历史变更记录
--   线索领取表说明：dw.fact_clue_allocate_info 为线索领取底层表；aws.clue_info 为数仓加工后的线索领取表，BI 取数常用。
--
-- 【用户属性取值时点】
--   取当月最后一天活跃表数据（按 DAY DESC 排序取第一条）
--
-- 【常用筛选条件】
--   ★必加条件：
--   无
--
--   场景条件：
--   - month 按分区过滤（int 类型，格式 yyyyMM）
-- =====================================================

CREATE TABLE
  `aws`.`user_pay_process_add_wechat_month` (
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
    `grade` string COMMENT '【月末值】年级',
    `gender` string COMMENT '【月末值】性别',
    `regist_time` timestamp COMMENT '注册时间',
    `user_attribution` string COMMENT '用户注册当天归属',
    `active_user_attribution` string COMMENT '【月末值】用户活跃时归属',
    `city_class` string COMMENT '【月末值】用户城市分线',
    `province` string COMMENT '【月末值】省名称',
    `city` string COMMENT '【月末值】市名称',
    `user_pay_status_statistics` string COMMENT '【月末值】统计维度付费状态：新增、老未、付费',
    `user_pay_status_business` string COMMENT '【月末值】业务维度付费状态：新用户、老用户、付费用户',
    `paid_current_month_user` string COMMENT '【当月转化】当月拉取入库转化用户',
    `paid_current_month_order_cnt` bigint COMMENT '【当月转化】当月拉取入库转化订单量',
    `paid_current_month_amount` double COMMENT '【当月转化】当月拉取入库转化金额',
    `event_time` bigint COMMENT '曝光事件时间戳',
    `before_get_entrance_team_name` string COMMENT '曝光前用户所属服务期团队名称',
    `scene_name` string COMMENT '渠道活码场景名称',
    `clue_level_name` string COMMENT '渠道活码等级名称',
    `resource_entrance_name` string COMMENT '渠道活码入口名称',
    `type_name` string COMMENT '渠道活码类型名称',
    `stage_name` string COMMENT '【月末值】学段'
  ) COMMENT '一个资源位id一个资源位的场景一个资源位的渠道id一个资源位曝光用户一条记录' PARTITIONED BY (`month` int) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/user_pay_process_add_wechat_month' TBLPROPERTIES (
    'bucketing_version' = '2',
    'last_modified_by' = 'huaxiong',
    'last_modified_time' = '1763620256',
    'spark.sql.create.version' = '2.2 or prior',
    'transient_lastDdlTime' = '1770629431'
  )

-- =====================================================
-- 枚举值（与日表 user_pay_process_add_wechat_day 一致，属性取月末值）
-- =====================================================
--
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
-- > 取值来源 user_allocation.user_allocation，映射为团队名称
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
-- ## clue_level_name（渠道活码等级名称）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | A+级 | |
-- | S级 | |
-- | A级 | |
-- | B级 | |
-- | C级 | |
-- | NULL | 未分级 |
--
-- ## type_name（渠道活码类型）
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 阿拉丁 | |
-- | 电销私域 | |
-- | AI机器人 | |
-- | 研学 | |
-- | 测试类型 | 测试数据，分析时需排除 |
