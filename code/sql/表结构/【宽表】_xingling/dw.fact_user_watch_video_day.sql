-- =====================================================
-- 用户观看视频明细表 dw.fact_user_watch_video_day
-- =====================================================
-- 【表粒度】
--   一次有效观看会话 = 一条记录（watch_id 标识）；分区 day（int，yyyyMMdd）；T+1
--   同一 u_user 在同一 day 可对不同 video_sk 多条；同一用户对同一视频多次观看亦多条
--
-- 【使用场景】
--   - 看视频行为：视频类型、完播/进度、课程类观看（看课）、端与产品筛选
--   - 与 glossary「看视频」「认真观看视频」「看课」口径对齐
--
-- 【业务定位】
--   观看事实明细；
--
-- 【统计口径】（业务指标权威定义见 glossary.md；以下为用本表计算方式）
--   按日汇总（主 App + 移动端默认筛选示例）：
--     观看视频用户数 = COUNT(DISTINCT u_user)
--     认真观看视频用户数 = COUNT(DISTINCT CASE WHEN finish_type_level > 7 THEN u_user END)  -- 进度 > 70%
--     观看课程用户数 = COUNT(DISTINCT CASE WHEN video_type_level1 = 'course' THEN u_user END)
--     视频完播用户数 = COUNT(DISTINCT CASE WHEN is_finish = true THEN u_user END)  -- 字段为 BOOLEAN；亦可写 is_finish
--   示例 SQL：
--     SELECT day
--          , COUNT(DISTINCT u_user) AS watch_uv
--          , COUNT(DISTINCT CASE WHEN finish_type_level > 7 THEN u_user END) AS serious_watch_uv
--          , COUNT(DISTINCT CASE WHEN video_type_level1 = 'course' THEN u_user END) AS course_watch_uv
--          , COUNT(DISTINCT CASE WHEN is_finish = true THEN u_user END) AS video_finish_uv
--     FROM dw.fact_user_watch_video_day
--     WHERE day BETWEEN ${start} AND ${end}
--       AND client_os IN ('android', 'ios', 'harmony')
--       AND product_id IN ('01', '03')
--       AND is_test_user = 0
--     GROUP BY day
--
-- 【常用关联】
--   u_user → 用户维表 / 活跃表（与 dw.dim_user.u_user、dws 系一致）
--   表级主键（TBLPROPERTIES）：watch_id + session_id
--
-- 【常用筛选条件】
--   ★必加：
--   - day BETWEEN ${start} AND ${end}
--
--   默认/常见（C 端主 App 与移动端，与活跃分析默认一致）：
--   - client_os IN ('android', 'ios', 'harmony')
--   - product_id IN ('01', '03')   -- 主 App 等，product_id 为 STRING
--   - is_test_user = 0             -- 排除测试用户（分析常用）
--
--   场景追加：
--   - 认真观看：finish_type_level > 7
--   - 视频完播：is_finish = true（BOOLEAN）
--   - 看课：video_type_level1 = 'course'
--   - 看课且认真：上两者同时满足
--
-- 【注意事项】
--   - 分区字段为 day；另含 date_sk（看视频的日期 sk），筛选以分区 day 为主避免扫表
--   - metastore 表名为 dw.fact_user_watch_video_day；LOCATION 路径目录为 fact_user_watch_video（与表名后缀不一致，以数仓为准）
-- =====================================================
CREATE TABLE dw.fact_user_watch_video (
    `watch_id` STRING COMMENT '本次观看视频的唯一id',
    `user_sk` INT COMMENT '用户数仓sk',
    `video_sk` INT COMMENT '数仓中生成的视频代理键',
    `video_type_level1` STRING COMMENT '视频类型英文（show/course/intro）',
    `video_duration` DOUBLE COMMENT '视频时长（秒）',
    `video_enter_type` STRING COMMENT '视频入口类型（主线/课程包）',
    `date_sk` INT COMMENT '看视频的日期',
    `hour_sk` INT COMMENT '看视频的小时，0到23',
    `term_sk` INT COMMENT '学段学科学期教材版本维度',
    `client_os` STRING COMMENT '观看视频的客户端os（android/ios/pc）',
    `role` STRING COMMENT '用户角色',
    `product_id` STRING COMMENT '产品名（例如初中、PC、H5、小程序） ',
    `app_version` STRING COMMENT '客户端版本号',
    `is_charge_video` SMALLINT COMMENT '本次观看的视频是否是付费视频',
    `server_time` TIMESTAMP COMMENT '开始看视频的时间',
    `event_time` TIMESTAMP COMMENT '开始看视频的时间 用户端时间',
    `learn_duration` INT COMMENT ' 4.26之后 这个字段为不含暂停的时长',
    `is_load_error` SMALLINT COMMENT '视频是否加载失败 startVideo后报错',
    `load_error_count` INT COMMENT '视频加载失败次数',
    `is_finish` SMALLINT COMMENT '视频是否完成（是否完播）',
    `exit_video_time` INT COMMENT '退出观看视频内的时间点——毫秒',
    `is_topic_finish` SMALLINT COMMENT '本次看完视频是否完成了知识点',
    `finish_type_level` INT COMMENT '观看时长/视频长度的百分比，精确到十位向下取整。如[0,10%)取0，[10%, 20%)取1，。。。，[90%，100%）取9,[100%,+∞)取10',
    `pause_count` INT COMMENT '本次观看视频过程中暂停次数',
    `drag_forth_count` INT COMMENT '本次观看视频过程中向前拖拽次数',
    `drag_back_count` INT COMMENT '本次观看视频过程中向后拖拽次数',
    `is_share` SMALLINT COMMENT '本次是否分享',
    `u_vip` STRING COMMENT '用户vip状态',
    `create_time` TIMESTAMP COMMENT '源系统创建条目的时间',
    `update_time` TIMESTAMP COMMENT '源系统修改条目的时间',
    `dw_insert_time` TIMESTAMP COMMENT 'ETL插入记录的时间',
    `dw_update_time` TIMESTAMP COMMENT 'ETL修改记录的时间',
    `u_user` STRING COMMENT '用户id',
    `error_type` STRING COMMENT '视频开始前报错、视频开始后报错',
    `learn_duration_business` INT COMMENT '开始播放到结束的时间减非主动暂停时长（4.26.0以后）(秒)',
    `topic_sk` INT COMMENT '知识点数仓id',
    `is_skip` SMALLINT COMMENT '是否跳过视频直接去做题',
    `course_package_id` STRING COMMENT '课程包id',
    `video_scene` STRING COMMENT '视频观看场景',
    `download_channel` STRING COMMENT '下载渠道',
    `device_id` STRING COMMENT '设备id',
    `client_os_version` STRING COMMENT '操作系统版本号',
    `network_type` STRING COMMENT '用户网络类型，比如wifi',
    `wx_version` STRING COMMENT '微信版本号',
    `phone_brand` STRING COMMENT '用户手机品牌',
    `phone_model` STRING COMMENT '用户手机型号',
    `is_try_watch` SMALLINT COMMENT '是否试看',
    `is_switch_resolution` SMALLINT COMMENT '是否切换清晰度',
    `is_switch_caption` SMALLINT COMMENT '是否开关字幕',
    `is_download` SMALLINT COMMENT '是否下载',
    `is_switch_segment` SMALLINT COMMENT '是否点击切换节点',
    `is_switch_speed` SMALLINT COMMENT '是否变速',
    `is_use_experience` SMALLINT COMMENT '是否使用体验机会',
    `is_ai_recommend` SMALLINT COMMENT '是否AI推荐视频',
    `time_out_count` INT COMMENT '加载超时次数',
    `lagged_count` INT COMMENT '卡顿次数',
    `error_count` INT COMMENT '报错次数',
    `is_voluntarily_exit` SMALLINT COMMENT '用户是否主动退出',
    `grade` STRING COMMENT '用户填写年级',
    `mid_grade` STRING COMMENT '中学修正年级',
    `mid_stage_name` STRING COMMENT '中学修正学段',
    `gender` STRING COMMENT '用户性别',
    `regist_time` TIMESTAMP COMMENT '注册时间',
    `regist_time_sk` INT COMMENT '注册时间sk',
    `channel` STRING COMMENT '注册渠道',
    `u_from` STRING COMMENT '系统平台',
    `type` STRING COMMENT '注册方式(枚举值)',
    `is_put_channel` SMALLINT COMMENT '是否投放渠道',
    `province` STRING COMMENT '省',
    `province_code` STRING COMMENT '省code',
    `city` STRING COMMENT '市',
    `city_code` STRING COMMENT '市code',
    `area` STRING COMMENT '区',
    `area_code` STRING COMMENT '区code',
    `is_test_user` SMALLINT COMMENT '是否测试用户',
    `is_teach_user` SMALLINT COMMENT '是否教学班用户',
    `is_admin_room` SMALLINT COMMENT '是否行政班用户',
    `is_room_user` SMALLINT COMMENT '是否有班用户',
    `is_new_user` SMALLINT COMMENT '是否新用户',
    `school_sk` INT COMMENT '学校sk',
    `school_id` STRING COMMENT '学校id',
    `school_id1` STRING COMMENT '学校id1',
    `school_sk1` INT COMMENT '学校sk1',
    `user_attribution` STRING COMMENT '用户活跃时归属',
    `regist_user_attribution` STRING COMMENT '用户注册当天归属',
    `room_id` STRING COMMENT '用户行政班id',
    `agent_id` STRING COMMENT '用户所在学校的代理商id',
    `ss_arr` ARRAY<STRING> COMMENT 'vip的学段学科数组',
    `is_vip_user` SMALLINT COMMENT '是否是vip用户',
    `barrage_notice_count` INT COMMENT '点击弹幕须知',
    `barrage_colose_count` INT COMMENT '点击关闭弹幕',
    `barrage_open_count` INT COMMENT '点击开启弹幕',
    `barrage_any_count` INT COMMENT '点击任意一条弹幕',
    `barrage_like_count` INT COMMENT '点击点赞弹幕',
    `barrage_report_count` INT COMMENT '点击举报弹幕',
    `barrage_role_count` INT COMMENT '点击弹幕角色',
    `barrage_preset_count` INT COMMENT '点击预设弹幕',
    `barrage_send_count` INT COMMENT '点击发送弹幕',
    `qa_count` INT COMMENT '点击答疑按钮',
    `tag_count` INT COMMENT '点击视频标记按钮',
    `tag_label_count` INT COMMENT '点击添加视频标记',
    `screen_shot_count` INT COMMENT '点击截屏按钮',
    `feed_back_count` INT COMMENT '点击视频反馈按钮',
    `feed_back_commit_count` INT COMMENT '点击提交视频反馈',
    `caption_open_count` INT COMMENT '点击打开字幕',
    `caption_close_count` INT COMMENT '点击关闭字幕',
    `more_action_count` INT COMMENT '点击更多按钮（三个点）',
    `init_speed` STRING COMMENT '初始速度',
    `init_cur_resolution` STRING COMMENT '初始清晰度',
    `init_timestamp` INT COMMENT '初始播放时间点',
    `session_id` STRING COMMENT '本次观看视频中，如果存在多个视频片段，此为唯一id',
    `pay` SMALLINT COMMENT '知识点是否付费',
    `is_free_time` SMALLINT COMMENT '知识点是否限免',
    `is_buy` SMALLINT COMMENT '判断用户在观看课程包视频时，是否已处于购买状态',
    `problem_id` STRING COMMENT '解析习题 id',
    `re_start_player` SMALLINT COMMENT '视频重播',
    `is_like` SMALLINT COMMENT '本次观看视频是否点赞',
    `sn_code` STRING COMMENT 'pad 设备码',
    `is_pad_device` SMALLINT COMMENT '是否pad设备',
    `video_enter_position` STRING COMMENT '视频入口位置，research_type1：首页研究tab入口1(首页右侧播放器样式入口)，research_type2：首页研究tab入口2(首页二级tab上方平铺入口)，research_type3：首页研究tab入口3(首页左侧IP形象位置入口)，treasure_type1：宝藏tab全息天幕入口',
    `day` INT
)
USING orc
PARTITIONED BY (day)
COMMENT '一次观看视频一条记录'
LOCATION 'tos://yc-data-platform/user/hive/warehouse/dw.db/fact_user_watch_video_day'
TBLPROPERTIES (
  'bucketing_version' = '2',
  'discover.partitions' = 'true',
  'last_modified_by' = 'master',
  'last_modified_time' = '1715153697',
  'transient_lastDdlTime' = '1715153697'
);

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## video_type_level1（视频大类）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | course | 课程类（「看课」指标必加） |
-- | show | 展示类 |
-- | intro | 引导类 |
--
-- ## is_finish（是否完播）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 1 | 本次观看会话内已完播 |
-- | 0 | 未完播 |
--
-- > 统计「视频完播用户数」：`COUNT(DISTINCT CASE WHEN is_finish = 1 THEN u_user END)`（与「认真观看」`finish_type_level > 6` 口径不同）。
--
-- ## finish_type_level（观看进度档位，相对视频长度）
--
-- > 与观看百分比对应：十位向下取整；**> 6 表示进度 > 60%**，即「认真观看」（见 glossary）。
--
-- | 取值区间（观看进度） | finish_type_level |
-- |---------------------|-------------------|
-- | [0%, 10%) | 0 |
-- | … | … |
-- | [90%, 100%) | 9 |
-- | [100%, +∞) | 10 |
--
-- ## client_os（常用筛选）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | android | 安卓 |
-- | ios | iOS |
-- | harmony | 鸿蒙 |
-- | pc | PC（非移动端分析时） |
--
-- ## product_id（部分，主 App）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 01 | 主产品（示例） |
-- | 03 | 主 App 相关（与 01 组合用于「主 app」筛选，以业务为准） |
--
-- > 字段为 STRING，SQL 中写作 `IN ('01', '03')`，勿省略引号。
--
