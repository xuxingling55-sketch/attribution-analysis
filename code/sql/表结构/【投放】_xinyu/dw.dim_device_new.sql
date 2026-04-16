-- =====================================================
-- 设备维表 dw.dim_device_new
-- =====================================================
-- 【表粒度】
--   每个洋葱设备一条数据，附带 oaid；非分区明细；T+1
--
-- 【使用场景】
--   - 统计设备品牌：按 model、model_series 分组
--   - 导出/统计新增设备 oaid，device_sk：按 date_sk 筛选
--   - 关联桥接表：device_sk → dw.bridge_device_user_new
--
-- 【业务定位】
--   设备主数据，用于设备级统计与用户设备关联
--
-- 【常用关联】
--   用 device_sk 做关联；与桥接表bridge_device_user_new关联时统一用 device_sk
-- 【常用筛选条件】
--   ★必加（按默认 C 端移动端口径）：
--   - os IN ('android', 'ios', 'harmony')
--   - first_channel != 'undefined'   -- 排除未定义渠道
--   - date_sk BETWEEN ${start} AND ${end}
--
-- 【注意事项】
-- =====================================================

CREATE TABLE dw.dim_device_new (
    device_sk BIGINT COMMENT '设备代理键',
    device_ids ARRAY<STRING> COMMENT '设备号',
    imeis ARRAY<STRING> COMMENT 'imei',
    meids ARRAY<STRING> COMMENT 'meid',
    mac_addresses ARRAY<STRING> COMMENT 'mac_address',
    platform STRING COMMENT '来自哪个平台 web/app/share..',
    os STRING COMMENT '系统平台（枚举见文件末）',
    model STRING COMMENT '设备品牌',
    model_series STRING COMMENT '设备型号',
    first_app_version STRING COMMENT '设备首次使用的App版本号',
    recent_app_version STRING COMMENT '最近一次设备使用的App版本号',
    first_channel STRING COMMENT '设备首次激活安装渠道',
    recent_channel STRING COMMENT '最新安装渠道',
    country STRING COMMENT '设备首次登录国家',
    province STRING COMMENT '省',
    city STRING COMMENT '市',
    area STRING COMMENT '区',
    first_server_time STRING COMMENT '设备第一次出现的时间',
    last_server_time STRING COMMENT '设备最后出现的时间',
    date_sk INT COMMENT '设备进库时间sk',
    first_product_id STRING COMMENT '设备首次安装产品id',
    recent_product_id STRING COMMENT '最近一次产品id',
    is_merge_device BOOLEAN COMMENT '是否合并设备',
    d_open_uuid STRING COMMENT 'ios端设备特殊识别码',
    aaid STRING COMMENT '',
    vaid STRING COMMENT '',
    oaid STRING COMMENT '设备标识',
    is_support SMALLINT COMMENT '',
    first_device_terminal_type STRING COMMENT '设备第一次类型'
)
USING orc
COMMENT '一个设备一条记录';

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## os（系统平台）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | android | 安卓 |
-- | ios | iOS |
-- | harmony | 鸿蒙 |
