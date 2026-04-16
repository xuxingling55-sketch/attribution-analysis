-- =====================================================
-- 公用- 用户活跃周表 dws.topic_user_active_detail_week
-- =====================================================
--
-- 【表粒度】
-- 一个用户一个下载渠道一个产品id一个活跃端口一个手机品牌一个手机型号一个sn_code一条记录，按自然周汇总（分区 week int；周标识以库内约定为准）；本表无日表中的 `attribution`（仅注册口径）、`mid_grade`（月表有 `mid_grade`）
--
-- 【业务定位】
--   - 【归属】公用 / 用户活跃周表。
-- - 与日表 `dws.topic_user_active_detail_day` 同族：周粒度行为汇总；全量/C 端学习行为叠加 `product_id`、`client_os`、`active_user_attribution`（见 glossary「C 端活跃默认筛选」）
--   - 寒假/大盘流量仍以日表 `is_active_user`、`is_test_user` 为主；周表侧重周期内汇总（活跃天数、次数、付费、电销外呼等）
-- - 同族：`topic_user_active_detail_month`（月分区、`user_strategy_*_month`）；策略字段本表为 `user_strategy_tag_week`、`user_strategy_eligibility_week`
--
-- 【统计口径】
--   周期内汇总类指标（*_cnt、duration、`active_day_cnt` 等）见字段 COMMENT；UV 类按分析场景对 `u_user` 去重
--
-- 【常用关联】
--   - 与日表 `dws.topic_user_active_detail_day` 同族：`u_user` + `week` 分区与周区间维关联（与日表对齐时筛选口径见【常用筛选条件】）
--
-- 【常用筛选条件】
--   ★必加条件：（与日表 C 端切片对齐时，条件口径一致）
--   - week 分区
--   - 产品：`product_id`
--   - 客户端：`client_os`
--   - 用户归属：`active_user_attribution`
--
-- 【注意事项】
--   - 更新频率：周更（以调度为准）
--   - 数据来源：`code/sql/临时文件/dws.topic_user_active_detail_week.md`（若与线上一致则以库为准）
--   - 知识库约定：取数与分析仅使用 business_user_pay_status_*；user_pay_status_*（无 business_ 前缀）列不在知识库维护口径

CREATE EXTERNAL TABLE `dws`.`topic_user_active_detail_week` (
  `u_user` string COMMENT '用户id',
  `user_sk` int COMMENT '数仓用户sk',
  `grade` string COMMENT '年级',
  `stage_name` string COMMENT '学段',
  `role` string COMMENT '身份',
  `is_parents` boolean COMMENT '是否家长',
  `gender` string COMMENT '性别',
  `regist_time` timestamp COMMENT '注册时间',
  `u_from` string COMMENT '系统平台',
  `channel` string COMMENT '注册渠道',
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
  `real_school_id` string COMMENT '学校id',
  `is_teach_user` smallint COMMENT '是否是有教学班用户',
  `is_room_user` smallint COMMENT '是否是有班用户',
  `is_new_user` smallint COMMENT '是否是本周新增用户',
  `is_vip_user` smallint COMMENT '是否是vip用户',
  `level` int COMMENT '等级',
  `regist_user_allocation` array < string > COMMENT '用户注册当天服务期归属',
 `business_user_pay_status_statistics` string COMMENT '新增(统计日期当天注册的)、大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、老未(统计日期之前注册的)',
 `business_user_pay_status_business` string COMMENT '大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)',
  `active_user_attribution` string COMMENT '用户活跃时归属',
  `user_allocation` array < string > COMMENT '用户全域服务期',
  `user_vip_tag` string COMMENT '会员身份标签',
  `download_channel` string COMMENT '下载渠道',
  `product_id` string COMMENT '产品ID',
  `client_os` string COMMENT '用户活跃的os',
  `d_model_brand` string COMMENT '手机品牌',
  `d_model_name` string COMMENT '手机型号',
  `sn_code` string COMMENT 'sn_code',
  `learn_active_cnt` int COMMENT '学习活跃次数',
  `active_cnt` int COMMENT '活跃次数',
  `topic_finish_cnt` int COMMENT '完成知识点次数',
  `app_use_duration` int COMMENT 'app使用时长',
  `app_user_cnt` int COMMENT 'app使用次数',
  `watch_course_video_cnt` int COMMENT '观看课程视频次数',
  `serious_watch_course_video_cnt` int COMMENT '认真观看课程视频次数',
  `finish_watch_course_video_cnt` int COMMENT '完成观看课程视频次数',
  `watch_course_video_duration` int COMMENT '观看课程视频时长',
  `total_exercise_cnt` int COMMENT '所有模块练习次数',
  `total_exercise_finish_cnt` int COMMENT '所有模块练习完成次数',
  `total_problem_cnt` int COMMENT '所有模块练习完成次数',
  `total_exercise_duration` double COMMENT '练习时长',
  `total_problem_duration` double COMMENT '做题目的时长',
  `total_regist_days` int COMMENT '累计注册天数',
  `sub_amount` double COMMENT '统计周期付费金额',
  `order_cnt` int COMMENT '统计周期付费次数',
  `d_app_version` string COMMENT '统计周期最后一次活跃app版本',
  `d_os_version` string COMMENT '统计周期最后一次活跃手机系统版本',
  `active_day_cnt` int COMMENT '统计周期活跃天数',
  `not_deal_cnt` int COMMENT '统计周期电销打电话次数-未接通',
  `dealing_cnt` int COMMENT '统计周期电销打电话次数-已接通',
  `customer_leak_cnt` int COMMENT '统计周期电销打电话次数-用户放弃',
  `agent_leak_cnt` int COMMENT '统计周期电销打电话次数-坐席放弃 ',
  `black_list_cnt` int COMMENT '统计周期电销打电话次数-外呼异常',
  `enter_chapter_list_cnt` int COMMENT '统计周期进入章节列表页面次数',
  `enter_payment_page_cnt` int COMMENT '统计周期进入付费落地页次数',
  `click_discovery_cnt` int COMMENT '统计周期点击宝藏tab次数',
  `click_learn_cnt` int COMMENT '统计周期点击学习tab次数',
  `click_learn_together_cnt` int COMMENT '统计周期点击共学tab次数',
  `click_growup_cnt` int COMMENT '统计周期点击成长tab次数',
  `click_myzone_cnt` int COMMENT '统计周期点击我的tab次数',
  `click_operate_cnt` int COMMENT '触发资源位次数',
  `user_identity` string COMMENT '用户身份：研究员：common，高级研究员：advanced，首席研究员：lead，体验版首席研究员：expLead',
  `user_strategy_tag_week` string COMMENT '用户策略标签',
  `user_strategy_eligibility_week` string COMMENT '用户策略资格',
  `mid_stage_name` string COMMENT '中学修正学段',
  `user_pay_status_statistics` string COMMENT '【知识库不引用】取数用 business_user_pay_status_statistics。原：新增、付费、老未（当月第一次活跃时的状态）',
  `user_pay_status_business` string COMMENT '【知识库不引用】取数用 business_user_pay_status_business。原：付费用户、新用、老用户（当月第一次活跃时的状态）'
)
COMMENT '一个用户一个下载渠道一个产品id一个活跃端口一个手机品牌一个手机型号一个sn_code一条记录'
PARTITIONED BY (`week` int COMMENT '分区：week')

ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
LOCATION 'tos://yc-data-platform/user/hive/warehouse/dws.db/topic_user_active_detail_week'

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 以下取值含义与 `dws.topic_user_active_detail_day` 第三段对齐（同一业务枚举）；本表策略字段为 `user_strategy_tag_week`、`user_strategy_eligibility_week`。`business_user_pay_status_*` 若与字段 COMMENT「大会员」表述不一致，以落表为准。本表无 `attribution`、`mid_grade`、`is_admin_user` 列，相关含义见日表枚举。
--
-- ## role（身份）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | student | 学生（注册时角色；见 `knowledge/glossary.md`「role / real_identity」） |
-- | teacher | 老师（注册时角色；见 `knowledge/glossary.md`「role / real_identity」） |
--
-- ## mid_stage_name（中学修正学段）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | NULL | 未归类（与 `dws.topic_user_info`「stage_name」枚举段一致） |
-- | 启蒙 | 启蒙 |
-- | 小学 | 小学 |
-- | 初中 | 初中 |
-- | 高中 | 高中 |
-- | 中职 | 中职 |
--
-- ## active_user_attribution（用户活跃时归属）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | b | b端用户，智课团队的用户（C 端默认筛选见 `knowledge/glossary.md`「C 端活跃默认筛选」） |
-- | c | c端用户，非智课团队的用户（C 端默认筛选见 `knowledge/glossary.md`「C 端活跃默认筛选」） |
--
-- ## product_id（产品ID）
--
-- > product_id 名称与备注由数仓与业务维护；与 `knowledge/glossary.md`「C 端活跃默认筛选」中 `product_id = '01'` 口径可对照使用。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | (空字符串) | 数仓可能出现的空产品编码 |
-- | 01 | 原app；支付；包含教师容器 |
-- | 02 | 教师独立app |
-- | 03 | 小学容器 |
-- | 04 | 学生校园版app 1.0；支持教育局报备 |
-- | 05 | M2(课程4.0) |
-- | 06 | 小学独立APP |
-- | 07 | 洋葱星球app |
-- | 08 | 洋葱学园PICO版 |
-- | 09 | 预习神器 |
-- | 10 | 个性化学习系统 |
-- | 11 | 小学小程序 |
-- | 12 | 家长小程序；家长业务群 |
-- | 13 | 小程序成长版 |
-- | 14 | 洋葱应用市场 |
-- | 21 | 电销小程序-洋葱学园 |
-- | 22 | 2023武汉电销春节福利卡 |
-- | 31 | 原教师pc（洋葱学院PC端） |
-- | 32 | 小学pc |
-- | 33 | PC校园版（解决方案2.0） |
-- | 34 | 运营后台；运营后台创建"校园版"订单 |
-- | 36 | B端运营后台 |
-- | 37 | 个性化学习系统 |
-- | 38 | 电销CRM系统 |
-- | 41 | 站外h5；弃用，站外h5用更小的分类替代，编码101开始 |
-- | 42 | 线下渠道；渠道系统订单 |
-- | 101 | 阿里云OS |
-- | 102 | QQ浏览器 |
-- | 103 | 有赞商城；家长业务群 |
-- | 110 | 小学数学营销小程序 |
-- | 111 | 小学数学学习体验小程序 |
-- | 112 | 洋葱星球小程序授权 |
-- | 120 | 家长洋葱商城；家长业务群（H5 商城）支付 |
-- | 121 | 京东商城；暂未接入订单系统；付缺 |
-- | 122 | 华为教育中心 |
-- | 123 | 百度小程序 |
-- | 124 | 洋葱星球家长课堂小程序授权 |
-- | 201 | 麦莉妈妈（分销商）；小学渠道分销 |
-- | 202 | 妈妈心选 |
-- | 203 | 花生日记 |
-- | 204 | ahaschool |
-- | 205 | 妈觅精选 |
-- | 206 | 枣妈与恺摩 |
-- | 207 | 萌状元 |
-- | 208 | 爸妈严选 |
-- | 209 | 向日葵妈妈分销 |
-- | 210 | 分销合作平台-习惯熊 |
-- | 211 | 分销合作平台公众号订单导入运营后台 |
-- | 300 | H5投放订单；打开H5投放支付的订单，复制链接支付 |
-- | 410 | 寒假课程礼包H5 |
-- | 411 | 企业微信h5 |
-- | 414 | 微店 |
-- | 415 | 抖音app h5页面 |
-- | 416 | 微信app 小程序 |
-- | 417 | 抖店商城 h5页面 |
-- | 418 | 洋葱教辅书二维码 |
-- | 419 | 智能客服系统 |
-- | 421 | 京东商城导入订单or未来接订单使用的h5页面 |
-- | 422 | 社区站外分享 |
-- | 423 | 奥德赛_直播 |
-- | 424 | 企微站外引流-H5登录 |
-- | 425 | 天猫商城h5页面注册 |
-- | 500 | 入校项目的希沃合作 |
-- | 501 | 洋葱学院APP-mac版 |
-- | 700 | 视频号小店导入订单 |
--
-- ## business_user_pay_status_business（见 `dws.topic_user_info` 同名字段 COMMENT；取值对齐线上）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 新用户 | 统计日期30天内注册的（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 续费用户 | 统计日期之前买过正价课（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 老用户 | 统计日期30以前注册的（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 高净值用户 | 统计日期之前方案型商品（不包括商品二级分类 id 为一年积木块、体验机、到期型培优课积木块等）（见 `dws.topic_user_info` 字段 COMMENT） |
--
-- ## business_user_pay_status_statistics（见 `dws.topic_user_info` 同名字段 COMMENT；取值对齐线上）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 新增 | 统计日期当天注册的（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 续费用户 | 统计日期之前买过正价课（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 老未 | 统计日期之前注册的（见 `dws.topic_user_info` 字段 COMMENT） |
-- | 高净值用户 | 统计日期之前方案型商品（不包括商品二级分类 id 为一年积木块、体验机、到期型培优课积木块等）（见 `dws.topic_user_info` 字段 COMMENT） |
--
-- ## user_strategy_tag_week（用户策略标签）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 付费加购品用户 | 付费加购品用户（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段；与日表 `user_strategy_tag_day` 同口径） |
-- | 付费组合品用户 | 付费组合品用户（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
-- | 付费零售品用户 | 付费零售品用户（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
-- | 历史大会员用户_不可续购 | 历史大会员用户_不可续购（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
-- | 历史大会员用户_可续购 | 历史大会员用户_可续购（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
-- | 新用户 | 新用户（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
-- | 老用户 | 老用户（见 `dws.topic_user_info` / `aws.business_active_user_last_14_day` 枚举段） |
--
-- ## user_strategy_eligibility_week（用户策略资格）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | (空字符串) | 无策略资格（见 `dws.topic_user_info` 枚举段） |
-- | 历史大会员续购策略资格;学习机加购策略资格 | 历史大会员续购策略资格;学习机加购策略资格（见 `dws.topic_user_info` 枚举段） |
-- | 历史大会员续购策略资格;学习机加购策略资格;小学品升级补差至小初品资格 | 历史大会员续购策略资格;学习机加购策略资格;小学品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格 | 学习机加购策略资格;高中囤课策略资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小初同步品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;多孩策略资格_寒促特别版;小学品升级补差至小初品资格;小初同步品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 学习机加购策略资格;高中囤课策略资格;小学品升级补差至小初品资格 | 学习机加购策略资格;高中囤课策略资格;小学品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 小初同步品升级补差至小初品资格 | 小初同步品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
-- | 小学品升级补差至小初品资格 | 小学品升级补差至小初品资格（见 `dws.topic_user_info` 枚举段） |
