-- =====================================================
-- 公用- 日期维度表 dw.dim_date
-- =====================================================
--
-- 【表粒度】
--   一自然日一行（date_sk / day 为键）
--   无分区；预生成维表
--
-- 【业务定位】
--   - 【归属】公用 / 日期维度表。
--   - 周/月趋势、weekofyear 与订单 paid_time 等关联；date_sk 对齐事实表
--
-- 【数据来源】
--   由数仓预生成（源导出见 `code/sql/临时文件/dw.dim_date.md`）
--
-- 【常用关联】
--   - tmp.meishihua_activity_operate_2025_middle_1：`join dw.dim_date b on b.day between a.start_day and a.end_day`
--   - tmp.lidanping_channel_amount_fuwuqi_month1：from dw.dim_date 作日期维；最外层同比 `maindata2 a1 left join maindata2 a2 on a1.year_month-100=a2.year_month and ...`
--   - 看板「新品销量表现_*」：`cross join week_day w`（week_day 由本表派生）
--
-- 【常用筛选条件】
--   场景条件：
--   - 按 date_sk、day、date 区间筛选

CREATE EXTERNAL TABLE `dw`.`dim_date` (
  `date_sk` int COMMENT '代理键，用于与事实表连接',
  `day` int COMMENT '日期',
  `date_id` string COMMENT '确保向后兼容，保持报表及历史代码稳定(2018-01-01)',
  `date` string COMMENT '20180101',
  `last_mon_date_id` string COMMENT '上周一的日期',
  `last_tue_date_id` string COMMENT '上周二的日期',
  `last_wed_date_id` string COMMENT '上周三的日期',
  `last_thu_date_id` string COMMENT '上周四的日期',
  `last_fri_date_id` string COMMENT '上周五的日期',
  `last_sat_date_id` string COMMENT '上周六的日期',
  `last_sun_date_id` string COMMENT '上周日的日期',
  `last_mon_date` string COMMENT '上周一的日期',
  `last_tue_date` string COMMENT '上周二的日期',
  `last_wed_date` string COMMENT '上周三的日期',
  `last_thu_date` string COMMENT '上周四的日期',
  `last_fri_date` string COMMENT '上周五的日期',
  `last_sat_date` string COMMENT '上周六的日期',
  `last_sun_date` string COMMENT '上周日的日期',
  `week_num` int COMMENT '周编号2013-12-19所在周为第一周，往后依次累加',
  `week_day` int COMMENT '一周第几天，周一是1，周日是7',
  `month_num` int COMMENT '月编号',
  `month_begin_date_id` string COMMENT '月开始日期',
  `month_begin_date` string COMMENT '月开始日期',
  `year_month` string COMMENT '年月(201911)',
  `year` string COMMENT '年',
  `month` string COMMENT '月',
  `year_num` int COMMENT '年编号（2013年为第一年，往后依次累加)',
  `day_num` int COMMENT '天编号（2013-12-19为第0天，往后依次累加）',
  `iso_week` string COMMENT 'ISO周日历格式',
  `week_begin_date_id` string COMMENT '周开始日期（同last_mon_date_id）',
  `is_work_day` boolean COMMENT '是否是工作日此字段针对20191231(包含)之前的数据有效',
  `week_begin_date` string COMMENT '周的开始日期',
  `week_end_date` string COMMENT '周的结束日期',
  `week_end_date_id` string COMMENT '周的结束日期',
  `month_end_date` string COMMENT '月的结束日期',
  `month_end_date_id` string COMMENT '月的结束日期',
  `tue_date_id` string COMMENT '本周二的日期(yyyy-MM-dd)',
  `wed_date_id` string COMMENT '本周三的日期(yyyy-MM-dd)',
  `thu_date_id` string COMMENT '本周四的日期(yyyy-MM-dd)',
  `fri_date_id` string COMMENT '本周五的日期(yyyy-MM-dd)',
  `sat_date_id` string COMMENT '本周六的日期(yyyy-MM-dd)',
  `tue_date` string COMMENT '本周二的日期(yyyyMMdd)',
  `wed_date` string COMMENT '本周三的日期(yyyyMMdd)',
  `thu_date` string COMMENT '本周四的日期(yyyyMMdd)',
  `fri_date` string COMMENT '本周五的日期(yyyyMMdd)',
  `sat_date` string COMMENT '本周六的日期(yyyyMMdd)',
  `week_begin_timestamp` timestamp COMMENT '周的开始日期(yyyy-MM-dd HH:mm:ss)',
  `week_end_timestamp` timestamp COMMENT '周的结束日期',
  `month_begin_timestamp` timestamp COMMENT '月的开始日期',
  `month_end_timestamp` timestamp COMMENT '月的结束日期',
  `yesterday_date` string COMMENT '昨天的日期sk',
  `tomorrow_date` string COMMENT '明天的日期sk',
  `day_timestamp` timestamp COMMENT '日期时间戳',
  `month_half_info` string COMMENT '上下半月信息',
  `month_day` int COMMENT '当前月份第几天，1号是1，30号是30',
  `month_day_cnt` int COMMENT '当前月总共多少天',
  `year_day` int COMMENT '每年第几天，20230101是1，20231231是365',
  `lunar_date` string COMMENT '农历日期',
  `week_to_year` string COMMENT '周是属于哪年的周',
  `semester_name` string COMMENT '学期信息',
  `semester_start_date` string COMMENT '学期开始日期',
  `semester_end_date` string COMMENT '学期结束日期'
)

ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat'
LOCATION 'tos://yc-data-platform/user/hive/warehouse/dw.db/dim_date'

-- =====================================================
-- 枚举值
-- =====================================================
-- 无需枚举值