-- =====================================================
-- 新增设备日表 aws.device_increase_new_add_day
-- =====================================================
-- 【表粒度】
--   每天每个 app 新增设备一条；分区 day(yyyyMMdd)；T+1
--
-- 【使用场景】
--   - app 新增设备：按 day、device_channel、device_app_version 统计
--   - 当天/7 日内注册用户数：today_regist_user_num、seven_regist_user_num
--   - 激活-注册漏斗：关联 aws.user_increase_new_add_day
-- 
-- 【业务定位】
--   新增设备日明细
--   上游是 dw.dim_device_new
--
-- 【常用关联】
--   device_sk；可与 user_increase_new_add_day 对漏斗
--
-- 【常用筛选条件】
--   ★必加：
--   - day BETWEEN ${start} AND ${end}
--   - device_product_id IN ('01', '03', '08')   -- 01 主 app，03 小学，08 pico
-- =====================================================

CREATE TABLE aws.device_increase_new_add_day (
    device_sk BIGINT COMMENT '设备代理键',
    device_os STRING COMMENT '设备首次安装的端口',
    device_channel STRING COMMENT '设备首次下载渠道',
    device_app_version STRING COMMENT '设备首次使用的App版本号',
    device_product_id STRING COMMENT '设备首次安装产品id',
    device_province STRING COMMENT '省',
    device_city STRING COMMENT '市',
    device_area STRING COMMENT '区',
    device_city_class STRING COMMENT '设备第一次出现的城市分线',
    first_server_time STRING COMMENT '设备第一次出现的时间',
    first_server_date STRING COMMENT '设备第一次出现的日期',
    model STRING COMMENT '设备品牌',
    model_series STRING COMMENT '设备型号',
    today_regist_user_num INT COMMENT '当日内注册用户数',
    seven_regist_user_num INT COMMENT '七日内注册用户数',
    dw_insert_time TIMESTAMP COMMENT 'ETL清洗时间',
    day INT COMMENT '分区日期 yyyyMMdd'
)
USING orc
PARTITIONED BY (day);
