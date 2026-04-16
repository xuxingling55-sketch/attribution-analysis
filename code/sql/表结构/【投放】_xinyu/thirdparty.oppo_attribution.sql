-- =====================================================
-- oppo广告明细表 thirdparty.oppo_attribution
-- =====================================================
-- 【表粒度】
--   每个洋葱设备一条记录，附带该设备的 oaid；非分区表；T+1
--
-- 【使用场景】
--   - 查看 oppo 渠道的详细广告信息（广告位、点击/下载/安装时间等）
--   - 广告转化情况需关联 thirdparty.traffic 查看 status
--
-- 【统计口径】
--   oppo 渠道广告维度的设备数与注册用户数（示例）：
--     SELECT a.ad_id
--          , COUNT(DISTINCT a.oaid) AS `设备数`
--          , COUNT(DISTINCT b.userid) AS `注册用户数`
--     FROM thirdparty.oppo_attribution a
--     LEFT JOIN thirdparty.traffic b ON a.traffic_id = b.id
--     WHERE a.created_at BETWEEN '${start}' AND '${end}'
--       AND b.status >= 1
--     GROUP BY a.ad_id
--
-- 【常用关联】
--   本表.traffic_id = thirdparty.traffic.id
--
-- 【注意事项】
--   - 历史数据不全，25年10月丢过一次数据
--   - 查看25年10月之前的 oppo 付费数据，需用 aws.user_increase_deliver_user_info
--     的 channel LIKE 'oppo%' 取 group_id、group_name
-- =====================================================

CREATE TABLE thirdparty.oppo_attribution (
    id BIGINT COMMENT '记录id',
    created_at TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP COMMENT '更新时间',
    deleted_at TIMESTAMP COMMENT '删除时间',
    traffic_id BIGINT COMMENT '关联投放用户状态记录（traffic.id）',
    ad_id STRING COMMENT '当前点击的id，oppo生成',
    imei STRING COMMENT '设备的imei',
    oaid STRING COMMENT '设备的oaid',
    android_id STRING COMMENT '设备的android_id',
    click_at TIMESTAMP COMMENT '点击时间',
    download_at TIMESTAMP COMMENT '下载完成时间',
    install_at TIMESTAMP COMMENT '安装完成时间',
    traffic_id_temp BIGINT COMMENT '临时traffic_id'
)
USING text
TBLPROPERTIES (
    'STATS_GENERATED_VIA_STATS_TASK' = 'true',
    'bucketing_version' = '2',
    'last_modified_by' = 'huaxiong',
    'last_modified_time' = '1768391629',
    'transient_lastDdlTime' = '1768392008'
);
