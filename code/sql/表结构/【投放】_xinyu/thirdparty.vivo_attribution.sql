-- =====================================================
-- vivo广告明细表 thirdparty.vivo_attribution
-- =====================================================
-- 【表粒度】
--   每个洋葱设备一条记录，附带该设备的 oaid；非分区表；T+1
--
-- 【使用场景】
--   - 查看 vivo 渠道的详细广告信息（广告位、计划、推广组等）
--   - 广告转化情况（点击后是否激活/注册）需关联 thirdparty.traffic 查看 status
--
-- 【统计口径】
--   vivo 渠道广告维度的设备数与注册用户数（示例）：
--     SELECT a.advertisement_id, a.ad_name, a.group_id, a.group_name
--          , a.campaign_name, a.campaign_id
--          , COUNT(DISTINCT a.oaid) AS `设备数`
--          , COUNT(DISTINCT b.userid) AS `注册用户数`
--     FROM thirdparty.vivo_attribution a
--     LEFT JOIN thirdparty.traffic b ON a.traffic_id = b.id
--     WHERE a.created_at BETWEEN '${start}' AND '${end}'
--       AND b.status >= 1
--     GROUP BY a.advertisement_id, a.ad_name, a.group_id, a.group_name
--            , a.campaign_name, a.campaign_id
--
-- 【常用关联】
--   本表.traffic_id = thirdparty.traffic.id
--
-- 【注意事项】
--   - 本表主要存放媒体广告信息，转化数据在 traffic 表
--   - 历史数据一直都有
-- =====================================================

CREATE TABLE thirdparty.vivo_attribution (
    id BIGINT COMMENT 'id主键',
    created_at TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP COMMENT '更新时间',
    deleted_at TIMESTAMP COMMENT '删除时间',
    traffic_id BIGINT COMMENT '关联投放用户状态记录（traffic.id）',
    request_id STRING COMMENT '请求id',
    imei STRING COMMENT 'imei',
    click_time BIGINT COMMENT '点击时间',
    ip STRING COMMENT 'ip',
    ua STRING COMMENT 'ua',
    oaid STRING COMMENT 'oaid',
    creative_id INT COMMENT '创意id',
    media_type INT COMMENT '素材类型',
    advertiser_id STRING COMMENT '广告主id',
    advertiser_name STRING COMMENT '广告主名称',
    place_type INT COMMENT '地区类型',
    advertisement_id INT COMMENT '广告id',
    ad_name STRING COMMENT '广告名称',
    group_id INT COMMENT '推广组id',
    group_name STRING COMMENT '推广组名称',
    campaign_id INT COMMENT '推广计划id',
    campaign_name STRING COMMENT '推广计划名称',
    click_id STRING COMMENT '点击id',
    traffic_id_temp BIGINT COMMENT '临时traffic_id'
)
USING text
TBLPROPERTIES (
    'STATS_GENERATED_VIA_STATS_TASK' = 'true',
    'bucketing_version' = '2',
    'last_modified_by' = 'huaxiong',
    'last_modified_time' = '1768391701',
    'transient_lastDdlTime' = '1768391997'
);
