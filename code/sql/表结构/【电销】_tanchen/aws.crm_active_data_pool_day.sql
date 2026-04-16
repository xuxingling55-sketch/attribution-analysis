-- =====================================================
-- C端活跃用户推送公海池触发漏斗日表 aws.crm_active_data_pool_day
-- =====================================================
-- 【表粒度】★必填
--   一个用户一条记录，按 day(int, 如 20260311) 分区
--
-- 【业务定位】
--   电话线索（CRM系统线索）的日度漏斗表，追踪 活跃→推送→入库→领取 四层漏斗
--   在漏斗基础上记录用户属性、推送场景、公海池拒绝原因、活跃前3天行为指标等
--   漏斗术语定义（活跃量/推送量/入库量/入库领取量/活跃领取量）→ glossary.md #电话线索漏斗指标
--
-- 【数据来源】
--   dws.topic_user_active_detail_day  —— 用户活跃数据 + 用户属性（当天值）
--   dw.dim_grade                      —— 年级→学段映射维表（mid_stage_name）
--   dw.fact_telesale_clue_day         —— 推送记录 + 公海池拒绝原因（deny_reason / deny_index）
--   dw.fact_clue_allocate_info        —— 坐席领取信息（区分线索来源 clue_source，用于两个领取口径）
--   events.frontend_event_orc         —— 前端埋点（活跃前3天行为指标来源）
--   aws.crm_order_info                —— 电销订单（order_flag / before_sum_amount）
--   线索领取表说明：dw.fact_clue_allocate_info 为线索领取底层表；aws.clue_info 为数仓加工后的线索领取表，BI 取数常用。
--
-- 【漏斗4层 + 补充口径】
--   第1层 active_u_user          当天活跃用户
--   第2层 push_u_user            当天被推送到电销的用户（活跃用户的子集）
--   第3层 enter_datapool_u_user  当天进入公海池的用户（推送用户的子集）
--   第4层 recieve_u_user         当天被坐席领取的用户，仅限 mid_school 来源（入库领取）
--   补充  recieve_u_user_all     当天被坐席领取的用户，不限线索来源（活跃领取）
--
-- 【与月表(crm_active_data_pool_month)的关系】
--   月表由日表按月聚合而来
--   用户属性：日表为当天值，月表区分月初值（首日）/月末值（末日）
--   漏斗字段：日表为当天状态，月表为当月是否至少一次
--   日表独有字段（月表不包含）：
--     推送场景：first_practice_type/scene、practice_type/scene_arr
--     活跃前3天行为指标：launch_order_3dcnt、各 *_3d_cnt 字段（约15个）
--     设备信息：login_device_num、device_regist_uv
--     风控信息：risk_score、risk_tag
--     其他：order_flag、user_vip_tag、is_bind_parent、auth_type、is_clue_seat
--
-- 【属性取值时点】
--   取当天(day)的活跃表数据
--
-- 【常用筛选条件】
--   ★必加条件：
--   无
--
--   场景条件：
--   - day 按分区过滤（int 类型，格式 yyyyMMdd）
-- =====================================================

CREATE TABLE
  `aws`.`crm_active_data_pool_day` (
    `active_u_user` string COMMENT '当天活跃用户ID',
    `grade` string COMMENT '【当天值】年级',
    `gender` string COMMENT '【当天值】性别',
    `regist_time` timestamp COMMENT '注册时间',
    `user_attribution` string COMMENT '用户注册当天归属',
    `active_user_attribution` string COMMENT '【当天值】用户活跃时归属（中学用户/小学用户/c）',
    `attribution` string COMMENT '【当天值】用户归属',
    `channel` string COMMENT '注册渠道',
    `u_from` string COMMENT '【当天值】系统平台',
    `regist_app_version` string COMMENT '注册时的app版本号',
    `regist_os` string COMMENT '【当天值】操作系统',
    `regist_type` string COMMENT '注册方式',
    `city_class` string COMMENT '【当天值】用户城市分线',
    `province` string COMMENT '【当天值】省名称',
    `province_code` string COMMENT '【当天值】省code',
    `city` string COMMENT '【当天值】市名称',
    `city_code` string COMMENT '【当天值】市code',
    `area` string COMMENT '【当天值】区名称',
    `area_code` string COMMENT '【当天值】区code',
    `real_identity` string COMMENT '【当天值】用户真实身份（student/parents/student_parents/teacher），判断是否家长的核心字段',
    `user_pay_status_statistics` string COMMENT '【当天值】统计维度付费状态：新增（注册当天）、老未、付费',
    `user_pay_status_business` string COMMENT '【当天值】业务维度付费状态：新用户（注册30天内）、老用户、付费用户',
    `push_u_user` string COMMENT '【漏斗第2层-推送量】当天被数仓推送到电销系统的用户，非NULL表示当天被推送，NULL表示活跃但未被推送',
    `enter_datapool_u_user` string COMMENT '【漏斗第3层-入库量】当天通过公海池过滤规则并进入公海池的用户，非NULL表示当天进入公海池，NULL表示未进入',
    `recieve_u_user` string COMMENT '【漏斗第4层-入库领取量】当天被坐席领取的用户，仅限线索来源为 mid_school（电话线索/系统线索），业务上等价于从公海池被领取',
    `order_flag` string COMMENT '付费标签',
    `first_deny_reason` string COMMENT '当天首次被公海池过滤规则拒绝的原因文本，空字符串表示未被拒绝',
    `first_deny_index` smallint COMMENT '当天首次被公海池拒绝的编号（0表示未被拒绝）',
    `deny_index_reason_arr` string COMMENT '当天所有被拒绝的编号数组（逗号分隔字符串，月表为 array<string> 类型）',
    `push_cnt` smallint COMMENT '当天被推送的次数（一天内可被多次推送）',
    `datepool_cnt` smallint COMMENT '当天进入公海池的次数（一天内可多次进入）',
    `first_practice_type` string COMMENT '首次推送到电销时触发的大场景',
    `first_practice_scene` string COMMENT '首次推送到电销时触发的小场景',
    `practice_type_arr` string COMMENT '当天所有推送触发的大场景数组',
    `practice_scene_arr` string COMMENT '当天所有推送触发的小场景数组',
    `launch_order_3dcnt` int COMMENT '活跃前3天发起待支付订单个数（不含支付成功订单）',
    `pay_block_dialog_3d_cnt` int COMMENT '活跃前3天播放器付费视频阻断次数',
    `total_review_pay_block_dialog_3d_cnt` int COMMENT '活跃前3天总复习付费视频阻断次数',
    `click_study_upgrade_course_3d_cnt` int COMMENT '活跃前3天教材同步章节列表页点击升级课程按钮次数',
    `click_total_review_upgrade_course_3d_cnt` int COMMENT '活跃前3天总复习章节列表页点击升级课程按钮次数',
    `click_thinking_expanded_upgrade_course_3d_cnt` int COMMENT '活跃前3天教材同步思维拓展章节列表页点击升级课程按钮次数',
    `click_service_button_3d_cnt` int COMMENT '活跃前3天点击客服按钮次数',
    `enter_payment_page_3d_cnt` int COMMENT '活跃前3天进入订单支付详情页次数',
    `popup_payment_custservice_3d_cnt` int COMMENT '活跃前3天订单支付详情页点击人工咨询后弹出客服弹窗次数',
    `click_payment_helpdoc_3d_cnt` int COMMENT '活跃前3天订单支付详情页点击"支付帮助"次数',
    `click_payment_confirm_3d_cnt` int COMMENT '活跃前3天订单支付详情页点击"确认支付"次数',
    `click_payment_exit_stay_button_3d_cnt` int COMMENT '活跃前3天退出支付阻断弹窗内点击"我再想想"次数',
    `regist_duration` int COMMENT '注册时长（天），距注册日的天数',
    `mid_active_type` string COMMENT '【当天值】活跃类型（新增/回流/持续）',
    `all_user_clue_cnt` int COMMENT '截止活跃日期前，用户历史累计被销售领取的总次数',
    `all_add_wechat_cnt` int COMMENT '截止活跃日期前，用户历史累计添加过企微的总次数',
    `enter_community_3d_cnt` int COMMENT '活跃前3天进入社区场景次数',
    `community_content_comment_3d_cnt` int COMMENT '活跃前3天社区内评论次数',
    `community_content_success_public_3d_cnt` int COMMENT '活跃前3天社区内成功发布内容次数',
    `enter_onion_shop_3d_cnt` int COMMENT '活跃前3天进入洋葱商店次数',
    `enter_onion_shop_exchange_dialog_3d_cnt` int COMMENT '活跃前3天洋葱商店兑换次数',
    `enter_primp_3d_cnt` int COMMENT '活跃前3天进入换装次数',
    `enter_draw_3d_cnt` int COMMENT '活跃前3天抽取服装次数',
    `user_allocation` array < string > COMMENT '【当天值】用户全域服务期，如["电销/网销"]',
    `phone_range` string COMMENT '用户号段（手机号前3位）',
    `level` int COMMENT '【当天值】用户星阶等级',
    `click_help_center_home_menu_3d_cnt` int COMMENT '活跃前3天在帮助中心查询优惠券次数',
    `click_nuannuan_message_button_3d_cnt` int COMMENT '活跃前3天在洋葱树洞收听音频/视频的次数',
    `click_total_reviewnew_upgrade_3d_cnt` int COMMENT '活跃前3天点击新中考总复习升级按钮次数',
    `click_exam_store_download_3d_cnt` int COMMENT '活跃前3天试卷下载阻断次数',
    `login_device_num` int COMMENT '截止活跃前，用户历史登录设备数',
    `device_regist_uv` int COMMENT '截止活跃前，用户当前设备注册用户数',
    `before_sum_amount` double COMMENT '截止活跃前一天，用户历史累计成功付费金额',
    `user_vip_tag` string COMMENT '【当天值】用户当前会员身份标签',
    `is_bind_parent` smallint COMMENT '【当天值】是否绑定家长用户（1=是，0=否）',
    `auth_type` array < string > COMMENT '用户授权类型',
    `business_user_pay_status_statistics` string COMMENT '【当天值】商业化统计维度：新增、大会员付费用户、续费用户、老未',
    `business_user_pay_status_business` string COMMENT '【当天值】商业化业务维度：高净值用户、续费用户、新用户、老用户',
    `risk_score` smallint COMMENT '风险分数，范围 0-9，分数越大手机号风险值越高',
    `risk_tag` smallint COMMENT '风险标签',
    `mid_stage_name` string COMMENT '【当天值】中学修正学段（小学/初中/高中/中职/学龄前）',
    `recieve_u_user_all` string COMMENT '【活跃领取量】当天被坐席领取的用户',
    `is_clue_seat` smallint COMMENT '【当天值】当天该用户的线索是否在坐席名下（1=在库，0=不在库）'
  ) COMMENT 'C端活跃用户推送公海池触发漏斗日表，追踪活跃→推送→入库→领取四层漏斗，含用户属性和活跃前3天行为指标，粒度：一个用户一条记录' PARTITIONED BY (`day` int) ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/aws.db/crm_active_data_pool_day' TBLPROPERTIES (
    'alias' = 'C端活跃用户推送公海池触发漏斗日表',
    'bucketing_version' = '2',
    'is_core' = 'true',
    'last_modified_by' = 'finebi',
    'last_modified_time' = '1749696650',
    'transient_lastDdlTime' = '1749696650'
  )

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## grade（年级）
--
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
--
-- ## gender（性别）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | male | 男 |
-- | female | 女 |
--
-- ## city_class（城市分线）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 一线 | |
-- | 二线 | |
-- | 三线 | |
-- | 四线 | |
-- | 五线 | |
-- | NULL | 未填写 |
--
-- ## real_identity（用户真实身份）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | student | 学生 |
-- | parents | 家长 |
-- | student_parents | 学生家长共用 |
-- | teacher | 老师 |
-- | NULL | 未填写 |
--
-- ## user_attribution（用户注册当天归属）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | c | C端用户 |
-- | b | B端用户 |
-- | 中学用户 | C端用户 |
-- | 小学用户 | C端用户|
-- | B端用户 | B端用户  |
-- | NULL | 未填写 |
--
-- ## u_from（系统平台）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | android | 安卓 |
-- | ios | iOS |
-- | pc | PC端 |
-- | mobile | 移动端 |
-- | h5 | H5页面 |
-- | applet | 小程序 |
-- | harmony | 鸿蒙 |
-- | windows | Windows |
-- | shadow | |
-- | teacher-android | 教师端-安卓 |
-- | teacher-ios | 教师端-iOS |
-- | O5-android | |
-- | 06-android | |
-- | other | 其他 |
--
-- ## regist_os（操作系统）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | android | 安卓 |
-- | ios | iOS |
-- | pc | PC端 |
-- | mobile | 移动端 |
-- | h5 | H5页面 |
-- | applet | 小程序 |
-- | harmony | 鸿蒙 |
-- | windows | Windows |
-- | shadow | |
-- | teacher-android | 教师端-安卓 |
-- | teacher-ios | 教师端-iOS |
-- | O5-android | |
-- | 06-android | |
-- | other | 其他 |
--
-- ## regist_type（注册方式）
--
-- > 高基数字段，仅列出高频值
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | signup | 自主注册 |
-- | batch | 批量导入 |
-- | weixin | 微信 |
-- | qq | QQ |
-- | ios | iOS |
-- | huawei | 华为 |
-- | oppo | OPPO |
-- | bubugao | 步步高 |
-- | youxuepai | 优学派 |
-- | dushulang | 读书郎 |
-- | dawan | 大碗 |
-- | telesale-mp | 电销小程序 |
-- | quickRegister | 快捷注册 |
-- | parentApplet | 家长端小程序 |
-- | newParentApplet | |
-- | ParentHBShop | |
-- | channel-platform | |
