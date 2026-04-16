-- =====================================================
-- 小米广告明细表 thirdparty.xiaomixin_attribution
-- =====================================================
-- 【表粒度】
--   每个洋葱设备一条记录，附带该设备的 oaid；非分区表；T+1
--
-- 【使用场景】
--   - 查看小米渠道的详细广告信息（创意名称、计划、账户等）
--   - 广告转化情况需关联 thirdparty.traffic 查看 status
--
-- 【统计口径】
--   小米渠道广告维度的设备数与注册用户数（示例）：
--     SELECT a.ad_name, a.campaign_id, a.customer_id, a.adreport_id
--          , COUNT(DISTINCT a.oaid) AS `设备数`
--          , COUNT(DISTINCT b.userid) AS `注册用户数`
--     FROM thirdparty.xiaomixin_attribution a
--     LEFT JOIN thirdparty.traffic b ON a.traffic_id = b.id
--     WHERE a.created_at BETWEEN '${start}' AND '${end}'
--       AND b.status >= 1
--     GROUP BY a.ad_name, a.campaign_id, a.customer_id, a.adreport_id
--
-- 【常用关联】
--   本表.traffic_id = thirdparty.traffic.id
--
-- 【注意事项】
--   - 历史数据不全，25年10月开始有小米渠道广告明细数据
--   - 小米的付费量从25年10月才能统计到
-- =====================================================

CREATE TABLE thirdparty.xiaomixin_attribution (
    id BIGINT COMMENT '主键ID',
    created_at TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP COMMENT '更新时间',
    oaid STRING COMMENT 'oaid',
    imei STRING COMMENT 'imei',
    ip STRING COMMENT 'ip',
    ua STRING COMMENT 'ua',
    app_id STRING COMMENT '小米渠道投放的渠道包id',
    ad_name STRING COMMENT '广告创意名称',
    channel STRING COMMENT '投放子渠道',
    campaign_id STRING COMMENT '广告计划ID',
    customer_id STRING COMMENT '广告账户ID',
    callback STRING COMMENT '归因回调参数',
    ts STRING COMMENT 'ts',
    sign STRING COMMENT '数据签名',
    adreport_id STRING COMMENT '广告创意ID',
    traffic_id BIGINT COMMENT '关联投放用户状态记录（traffic.id）'
)
USING text
TBLPROPERTIES (
    'STATS_GENERATED_VIA_STATS_TASK' = 'true',
    'bucketing_version' = '2',
    'transient_lastDdlTime' = '1764522786'
);
