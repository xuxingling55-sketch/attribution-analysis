-- =====================================================
-- 点击归因表 thirdparty.traffic
-- =====================================================
-- 【表粒度】
--   投放过程中每个设备每次点击一条记录（id 唯一）；非分区表；T+1
--
-- 【使用场景】
--   - 检测华为/小米/oppo/vivo/信息流/cpa 等渠道广告链路的转化情况
--   - 与各渠道广告明细表（vivo_attribution / oppo_attribution / xiaomixin_attribution）通过 id 关联查看具体广告位
--   - 与媒体排查分时点击/激活/注册数据
--
-- 【业务定位】
--   存放用户在外部媒体点击广告及点击后的激活/转化数据，只能获取渠道、代理粒度，
--   具体广告位需关联渠道广告明细表。
--
--   traffic 相关有多个表（**与 dw.fact_traffic 不是同一张表**，选表详见 → code/sql/表结构/dw.fact_traffic.sql）：
--   - thirdparty.traffic：2026-03-24 前为完整点击/激活/注册；2026-03-24 起仅保存有激活的数据，不再保存点击未激活、注册
--   - traffic_investment.traffic：2026-03-23 起存数据，仅点击且状态不随激活/注册更新（冷库）
--   - dw.fact_traffic：数仓总表（分区 T+1），构成见 fact_traffic DDL【业务定位】
--   - 当日激活、点击用 thirdparty.traffic_hour
--   - dw.dim_traffic 与 traffic_investment.traffic 表结构一样
--
-- 【统计口径】
--   渠道去重设备/用户数（示例）：
--     SELECT channel
--          , COUNT(DISTINCT oaid) AS `去重oaid数`
--          , COUNT(DISTINCT userid) AS `去重用户数`
--     FROM thirdparty.traffic
--     WHERE channel = '${channel}'
--       AND created_at BETWEEN '${start}' AND '${end}'
--     GROUP BY channel
--
--   与媒体排查分时数据：分别用 clicktime/activatetime/registertime 结合 status 统计 oaid 数
--
-- 【常用关联】
--   本表.id = vivo_attribution.traffic_id / oppo_attribution.traffic_id / xiaomixin_attribution.traffic_id
--   本表.userid → dw.dim_user.u_user / aws.user_increase_new_add_day.u_user
--
-- 【常用筛选条件】
--   ★必加：
--   - 日期筛选：未特指点击/激活/注册事件时，一律用 created_at 卡时间
--
--   场景追加：
--   - 特指点击事件：用 clicktime
--   - 特指激活事件：用 activatetime
--   - 特指注册事件：用 registertime
--   - 排除脏 oaid：oaid <> '' AND oaid <> '00000000-0000-0000-0000-000000000000'
--
-- 【注意事项】
--   - oaid='' 和 '00000000-0000-0000-0000-000000000000' 是脏数据
--   - 有的渠道不传 android_id，与媒体排查一般用 oaid
--   - source 和 channel 都能标识媒体：华为渠道 source=huawei，channel 为具体投放广告位；
--     oppo/vivo 的具体广告位需关联对应渠道广告明细表
--   - 状态流转：点击→激活→注册→付费，新状态覆盖旧 status
-- =====================================================

CREATE TABLE thirdparty.traffic (
    id BIGINT COMMENT '64位id（关联广告明细表的 traffic_id）',
    id_old BIGINT COMMENT '记录id',
    created_at TIMESTAMP COMMENT '创建时间（默认日期筛选字段）',
    updated_at TIMESTAMP COMMENT '更新时间',
    deleted_at TIMESTAMP COMMENT '删除时间',
    activity_id BIGINT COMMENT '关联的投放渠道信息',
    idfa STRING COMMENT '点击广告的设备的idfa信息',
    oaid STRING COMMENT '点击广告的设备的oaid（与媒体排查首选）',
    android_id STRING COMMENT '点击广告的设备的androidid',
    imei STRING COMMENT '设备的imei',
    uuid STRING COMMENT '广告的标识',
    ua STRING COMMENT '用户点击广告的useragent',
    ip STRING COMMENT '用户ip',
    mac_md5 STRING COMMENT '设备mac地址的md5',
    callback STRING COMMENT '需要给广告方回传数据的地址',
    os STRING COMMENT '点击广告的系统类型',
    userid STRING COMMENT '注册后的洋葱用户id',
    status BIGINT COMMENT '用户状态（详见文件末尾枚举值）',
    source STRING COMMENT '投放渠道（如 huawei/oppo/vivo 等）',
    channel STRING COMMENT '同一投放渠道下的不同广告位（华为渠道直接标识广告位）',
    proto BIGINT COMMENT 'proto',
    clicktime TIMESTAMP COMMENT '广告点击时间',
    activatetime TIMESTAMP COMMENT '激活时间',
    registertime TIMESTAMP COMMENT '用户注册时间',
    paytime TIMESTAMP COMMENT '用户支付时间',
    track_id STRING COMMENT 'trackid',
    hash_android_id STRING COMMENT 'androidid md5值',
    hash_idfa STRING COMMENT 'idfa md5值',
    hash_oaid STRING COMMENT 'oaid md5值',
    hash_imei STRING COMMENT 'imei md5值',
    extra STRING COMMENT 'extra',
    retain_status DECIMAL(38,10) COMMENT '激活次日留存上报状态 0初始/历史 1等待上报 2成功 3超时 4失败',
    other_status BIGINT COMMENT '其他状态 0初始 1已看客',
    status_list STRING COMMENT '状态列表 数组字符串形式 appStartUp=应用启动',
    register_retain_status BIGINT COMMENT '注册次留上报状态 0初始/历史 1等待上报 2成功 3超时 4失败',
    register_retention_bitmask BIGINT COMMENT '注册后1~8天活跃位图：bit1=第1天 bit2=第2天...1表示活跃',
    ip_ua_md5 STRING COMMENT '(ip+ua)md5的值'
)
USING orc
TBLPROPERTIES (
    'transient_lastDdlTime' = '1768295876'
);

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## status（用户状态）
--
-- > 状态流转：点击 → 激活 → 注册 → 付费，新状态**覆盖**原有 status。
-- > `status >= 1` 表明设备/用户至少有过激活。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 点击（仅点击广告，未激活） |
-- | 1 | 激活（已激活 app） |
-- | 2 | 注册（已注册 app） |
-- | 3 | 付费（已发生支付） |
--
-- ## source（投放渠道，部分）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | huawei | 华为（channel 直接标识广告位） |
-- | oppo | OPPO（具体广告位关联 oppo_attribution） |
-- | vivo | vivo（具体广告位关联 vivo_attribution） |
--
-- ## oaid 脏数据
--
-- | 值 | 含义 |
-- |----|------|
-- | '' | 空字符串，脏数据 |
-- | 00000000-0000-0000-0000-000000000000 | 全零，脏数据 |
