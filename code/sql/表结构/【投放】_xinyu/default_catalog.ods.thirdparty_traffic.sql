-- =====================================================
-- 点击归因仅注册无延迟实时表 default_catalog.ods.thirdparty_traffic
-- =====================================================
--
-- 【表粒度】
--   一个 API 投放新注册用户一条数据；非分区表；**实时（无延迟）**。
--
-- 【业务定位】
--   ★ 仅保存「已注册」用户（对应 `thirdparty.traffic.status >= 2`），不含纯点击/激活；
--   实时写入，**无延迟**，是对实时性要求高、仅需注册维度的首选表。
--
--   与其他 traffic 表的对比（选表指南）：
--   | 表 | 实时 | 内容 | 说明 |
--   |----|------|------|------|
--   | `default_catalog.ods.thirdparty_traffic` | ✅ 无延迟 | 仅注册 | 实时核对注册用 |
--   | `thirdparty.traffic_hour` | 有延迟 | 激活+注册 | 可核对激活/注册，有延迟 |
--   | `thirdparty.traffic` | T+1 | 点击+激活+注册 | 历史全量分析 |
--
-- 【使用场景】
--   1. 协助运营**实时核对媒体的注册回传数据**（与媒体拉的数据对齐）
--   2. **测试新渠道**的注册回传情况
--
-- 【核心字段】
--   `userid`（注册用户ID）、`channel`、`source`、`registertime`
--
-- 【统计口径】（分时注册监控）
--
-- ```sql
-- -- 按小时统计分渠道注册量（当天实时）
-- SELECT  substr(registertime, 12, 2) AS hour
--       , COUNT(DISTINCT CASE WHEN channel LIKE 'jisu%' THEN userid END) AS jisu_regist
--       , COUNT(DISTINCT CASE WHEN channel LIKE 'jbp%'  THEN userid END) AS jbp_regist
-- FROM default_catalog.ods.thirdparty_traffic
-- WHERE date(registertime) = current_date()
-- GROUP BY substr(registertime, 12, 2)
-- ORDER BY hour
--
-- -- 快速查最新注册时间与累计量
-- SELECT  MAX(registertime) AS max_registtime
--       , COUNT(DISTINCT CASE WHEN channel LIKE 'jisu%' THEN userid END) AS jisu_regist
--       , COUNT(DISTINCT CASE WHEN channel LIKE 'jbp%'  THEN userid END) AS jbp_regist
-- FROM default_catalog.ods.thirdparty_traffic
-- WHERE date(registertime) = current_date()
-- ```
--
-- 【常用筛选条件】
--   场景条件：
--   - 限日期：`date(registertime) = current_date()` 或 `date(registertime) BETWEEN ...`
--   - 限渠道：`channel LIKE '${prefix}%'` 或 `channel = '${channel}'`
--
-- 【注意事项】
--   ⚠️ StarRocks/OLAP 引擎（PRIMARY KEY 表），非 Hive；SQL 语法以 StarRocks 为准。
--   ⚠️ 本表**仅保存注册用户**，无法统计激活/点击；需激活/点击数据用 `thirdparty.traffic_hour`。
--   ⚠️ `registertime` 为 datetime 类型，`date()` 函数取日期。
--
-- =====================================================

CREATE TABLE `thirdparty_traffic` (
    `id` bigint(20) NOT NULL COMMENT '主键ID',
    `created_at` datetime NULL COMMENT '创建时间',
    `updated_at` datetime NULL COMMENT '更新时间',
    `deleted_at` datetime NULL COMMENT '删除时间',
    `activity_id` int(11) NULL COMMENT '投放活动ID',
    `ip` varchar(65533) NULL COMMENT '用户IP',
    `mac_md5` varchar(65533) NULL COMMENT '设备mac地址md5',
    `os` varchar(65533) NULL COMMENT '操作系统',
    `userid` varchar(65533) NULL COMMENT '注册用户ID',
    `status` int(11) NULL COMMENT '用户状态（本表仅含注册及以上）',
    `source` varchar(65533) NULL COMMENT '投放渠道（如 huawei/oppo/vivo 等）',
    `channel` varchar(65533) NULL COMMENT '同一渠道下的广告位',
    `proto` int(11) NULL COMMENT 'proto',
    `clicktime` datetime NULL COMMENT '广告点击时间',
    `activatetime` datetime NULL COMMENT '激活时间',
    `registertime` datetime NULL COMMENT '用户注册时间（主要过滤字段）',
    `paytime` datetime NULL COMMENT '用户支付时间',
    `idfa` varchar(65533) NULL COMMENT '设备idfa',
    `oaid` varchar(65533) NULL COMMENT '设备oaid',
    `android_id` varchar(65533) NULL COMMENT '设备android_id',
    `ip_ua_md5` varchar(65533) NULL COMMENT '(ip+ua) md5'
) ENGINE = OLAP
PRIMARY KEY (`id`)
COMMENT 'OLAP'
DISTRIBUTED BY HASH(`id`) BUCKETS 1
PROPERTIES (
    "compression" = "LZ4",
    "enable_persistent_index" = "false",
    "fast_schema_evolution" = "false",
    "replicated_storage" = "true",
    "replication_num" = "1"
);
