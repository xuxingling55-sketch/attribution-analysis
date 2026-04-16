-- =====================================================
-- 点击归因数仓总表 dw.fact_traffic
-- =====================================================
-- 【表粒度】
--   投放过程中，每个设备每次点击一条记录（id 唯一，与渠道广告明细表 traffic_id 关联）；
--   分区表，按 day（yyyyMMdd）分区；T+1
--
-- 【业务定位】
--   与 thirdparty.traffic、traffic_investment.traffic 为**三张不同表**，字段结构一致，存档量与构成不同：
--
--   | 表 | 数据范围与特点 |
--   |----|----------------|
--   | thirdparty.traffic | 2026-03-24 前：完整点击/激活/注册；2026-03-24 起：仅保存有激活的数据，不再保存「点击但未激活、注册」；不考虑 id 的点击全貌时可用 |
--   | traffic_investment.traffic | 2026-03-23 起存数据；仅存放点击；点击后若发生激活/注册，本表**不随状态变更更新**（冷数据） |
--   | **dw.fact_traffic（本表）** | （1）2026-03-24 之前 thirdparty.traffic 的全量数据；（2）2026-03-24 之后：依据 thirdparty.traffic 的更新记录，对 traffic_investment.traffic 中**字段发生变更**的行做合并后的数仓总表 |
--
--   具体广告位粒度：本表仅能到渠道、代理粒度；华为 source=huawei 时 channel 为广告位；oppo/vivo 等需关联对应渠道广告明细表。
--
-- 【数据来源】
--   数仓汇总层；逻辑上由 thirdparty.traffic 与 traffic_investment.traffic 按上述规则构成（非简单全量 UNION）。
--
-- 【分区与更新】
--   - 分区字段：day（yyyyMMdd），明细表**查询必须带 day 分区**（与其他条件组合，避免全表扫）
--   - 分区与 updated_at 等业务字段的关系：广告数据流转周期约 **7 天**，7 天内状态可更新；超过 7 天无字段更新则视为冷数据，不再做状态更新
--   - 更新频率：T+1
--
-- 【统计口径】
--   以下为在**明细行**上聚合的示例（表本身仍是每点击一行，非按渠道预汇总）：
--   渠道维度下去重设备/用户（需同时卡分区与业务时间时，按分析习惯组合 day 与时间字段）：
--     SELECT channel
--          , COUNT(DISTINCT oaid) AS `去重oaid数`
--          , COUNT(DISTINCT userid) AS `去重用户数`
--     FROM dw.fact_traffic
--     WHERE day BETWEEN '${day1}' AND '${day2}'
--       AND channel = '${channel}'
--       AND (
--            created_at BETWEEN '${start}' AND '${end}'
--         OR clicktime BETWEEN '${start}' AND '${end}'
--         OR activatetime BETWEEN '${start}' AND '${end}'
--         OR registertime BETWEEN '${start}' AND '${end}'
--       )
--     GROUP BY channel
--
--   与媒体排查：分时点击/激活/注册分别用 clicktime、activatetime、registertime 并结合 status 统计 oaid；
--   可对比某渠道点击/激活 oaid 在其他渠道是否也有点击/激活时间，辅助判断是否渠道量劫持。
--
-- 【常用关联】
--   本表.id = thirdparty.vivo_attribution.traffic_id / thirdparty.oppo_attribution.traffic_id
--          / thirdparty.xiaomixin_attribution.traffic_id
--   本表.userid → dw.dim_user.u_user
--
-- 【常用筛选条件】
--   ★必加：
--   - day BETWEEN 'yyyyMMdd' AND 'yyyyMMdd'   -- 分区裁剪，必带
--   - 未特指点击/激活/注册事件或行为时，一律用 created_at 卡时间
--
--   场景追加：
--   - 特指点击：clicktime；激活：activatetime；注册：registertime
--   - 排除脏 oaid：oaid <> '' AND oaid <> '00000000-0000-0000-0000-000000000000'
--
-- 【注意事项】
--   - 与 thirdparty.traffic 不是同一张表，选表见表头【业务定位】
--   - 查询成本：同条件下查本表通常比 thirdparty.traffic 更慢、数据量更大；若无点击/未激活等明细或全量点击口径需求，优先用 thirdparty.traffic
--   - 有的渠道不传 android_id，与媒体排查优先用 oaid
--   - source、channel 均可标识媒体；华为 source=huawei 时 channel 为具体广告位
-- =====================================================

CREATE TABLE dw.fact_traffic (
    id BIGINT COMMENT '64位id（与渠道广告明细表 traffic_id 关联）',
    id_old BIGINT COMMENT '记录id',
    created_at TIMESTAMP COMMENT '创建时间（未特指事件时默认日期筛选字段）',
    updated_at TIMESTAMP COMMENT '更新时间',
    deleted_at TIMESTAMP COMMENT '删除时间',
    activity_id BIGINT COMMENT '关联的投放渠道信息',
    idfa STRING COMMENT '点击广告的设备的idfa信息',
    oaid STRING COMMENT '点击广告的设备的oaid（与媒体排查首选；空或全零为脏数据）',
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
    channel STRING COMMENT '同一投放渠道下的不同广告位（华为可直接标识广告位）',
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
    retain_status DECIMAL(38,10) COMMENT '激活次日留存上报状态 0初始/历史 1等待 2成功 3超时 4失败',
    other_status BIGINT COMMENT '其他状态 0初始 1已看客',
    status_list STRING COMMENT '状态列表 数组字符串形式 appStartUp=应用启动',
    register_retain_status BIGINT COMMENT '注册次留上报状态 0初始/历史 1等待上报 2成功 3超时 4失败',
    register_retention_bitmask BIGINT COMMENT '注册后1~8天活跃位图：bit1=第1天...1表示活跃',
    ip_ua_md5 STRING COMMENT '(ip+ua)md5的值',
    day STRING COMMENT '分区字段 YYYYMMDD'
)
USING orc
PARTITIONED BY (day)
TBLPROPERTIES (
    'transient_lastDdlTime' = '1774419742'
);

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## status（用户状态）
--
-- > 状态流转：点击 → 激活 → 注册 → 付费，新状态**覆盖**原有 status。
-- > 「仅到点击、未激活」用 `status = 0`；`status >= 1` 表示至少已激活。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 点击 |
-- | 1 | 激活 |
-- | 2 | 注册 |
-- | 3 | 付费 |
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
-- | '' | 空字符串 |
-- | 00000000-0000-0000-0000-000000000000 | 全零 |
--
