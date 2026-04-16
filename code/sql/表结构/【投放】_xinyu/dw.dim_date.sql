-- =====================================================
-- 日期维表 dw.dim_date
-- =====================================================
-- 【表粒度】
--   一个日期一条
--
-- 【使用场景】
--   - 日期序列：替代 explode(sequence(...)) 生成连续日期
--   - 周中/周末：week_day 1=周一…7=周日 → 1-5 周中，6-7 周末
--   - 年月/周聚合：year_month、month_begin_date_id、week_begin_date_id 等
--
-- 【统计口径示例】
--   周中周末：case when week_day between 1 and 5 then '周中' else '周末' end
--
-- 【常用筛选条件】
--   - day BETWEEN ${start} AND ${end} 或按 date_id 范围
-- =====================================================

CREATE TABLE dw.dim_date (
    date_sk INT COMMENT '代理键，用于与事实表连接',
    day INT COMMENT '日期 yyyyMMdd',
    date_id STRING COMMENT '日期 yyyy-MM-dd',
    date STRING COMMENT '20180101',
    last_mon_date_id STRING COMMENT '上周一的日期',
    last_tue_date_id STRING COMMENT '上周二的日期',
    last_wed_date_id STRING COMMENT '上周三的日期',
    last_thu_date_id STRING COMMENT '上周四的日期',
    last_fri_date_id STRING COMMENT '上周五的日期',
    last_sat_date_id STRING COMMENT '上周六的日期',
    last_sun_date_id STRING COMMENT '上周日的日期',
    last_mon_date STRING COMMENT '上周一的日期',
    last_tue_date STRING COMMENT '上周二的日期',
    last_wed_date STRING COMMENT '上周三的日期',
    last_thu_date STRING COMMENT '上周四的日期',
    last_fri_date STRING COMMENT '上周五的日期',
    last_sat_date STRING COMMENT '上周六的日期',
    last_sun_date STRING COMMENT '上周日的日期',
    week_num INT COMMENT '周编号',
    week_day INT COMMENT '一周第几天，周一是1，周日是7',
    month_num INT COMMENT '月编号',
    month_begin_date_id STRING COMMENT '月开始日期',
    month_begin_date STRING COMMENT '月开始日期',
    year_month STRING COMMENT '年月(201911)',
    year STRING COMMENT '年',
    month STRING COMMENT '月',
    year_num INT COMMENT '年编号',
    day_num INT COMMENT '天编号',
    iso_week STRING COMMENT 'ISO周日历格式',
    week_begin_date_id STRING COMMENT '周开始日期',
    is_work_day BOOLEAN COMMENT '是否是工作日',
    week_begin_date STRING COMMENT '周的开始日期',
    week_end_date STRING COMMENT '周的结束日期',
    week_end_date_id STRING COMMENT '周的结束日期',
    month_end_date STRING COMMENT '月的结束日期',
    month_end_date_id STRING COMMENT '月的结束日期',
    tue_date_id STRING COMMENT '本周二的日期(yyyy-MM-dd)',
    wed_date_id STRING COMMENT '本周三的日期(yyyy-MM-dd)',
    thu_date_id STRING COMMENT '本周四的日期(yyyy-MM-dd)',
    fri_date_id STRING COMMENT '本周五的日期(yyyy-MM-dd)',
    sat_date_id STRING COMMENT '本周六的日期(yyyy-MM-dd)',
    tue_date STRING COMMENT '本周二的日期(yyyyMMdd)',
    wed_date STRING COMMENT '本周三的日期(yyyyMMdd)',
    thu_date STRING COMMENT '本周四的日期(yyyyMMdd)',
    fri_date STRING COMMENT '本周五的日期(yyyyMMdd)',
    sat_date STRING COMMENT '本周六的日期(yyyyMMdd)',
    week_begin_timestamp TIMESTAMP COMMENT '周的开始日期',
    week_end_timestamp TIMESTAMP COMMENT '周的结束日期',
    month_begin_timestamp TIMESTAMP COMMENT '月的开始日期',
    month_end_timestamp TIMESTAMP COMMENT '月的结束日期',
    yesterday_date STRING COMMENT '昨天的日期sk',
    tomorrow_date STRING COMMENT '明天的日期sk',
    day_timestamp TIMESTAMP COMMENT '日期时间戳',
    month_half_info STRING COMMENT '上下半月信息',
    month_day INT COMMENT '当前月份第几天',
    month_day_cnt INT COMMENT '当前月总共多少天',
    year_day INT COMMENT '每年第几天',
    lunar_date STRING COMMENT '农历日期',
    week_to_year STRING COMMENT '周是属于哪年的周',
    semester_name STRING COMMENT '学期信息',
    semester_start_date STRING COMMENT '学期开始日期',
    semester_end_date STRING COMMENT '学期结束日期'
) USING orc;
