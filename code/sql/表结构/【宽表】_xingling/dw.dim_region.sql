-- =====================================================
-- 地理位置维表 dw.dim_region
-- =====================================================
--
-- 【表粒度】
--   一个省份一个城市一个地区一条记录；city_code 关联活跃/订单等
--   无分区；更新按需（以调度为准）
--
-- 【业务定位】
--   - city_code → city_class（城市线级）；与 topic_user_active_detail_day、归因 SQL JOIN
--
-- 【统计口径】
--   维表，一般不直接汇总指标
--
-- 【常用筛选条件】
--   场景条件：
--   - 按 city_code / province_code 筛选地域时与事实表对齐

CREATE TABLE
  `dw`.`dim_region` (
    `province` string COMMENT '省',
    `province_code` string COMMENT '省code',
    `city` string COMMENT '市',
    `city_code` string COMMENT '市code',
    `area` string COMMENT '区县',
    `area_code` string COMMENT '区县code',
    `is_has_area` boolean COMMENT '是否有区县',
    `city_class` string COMMENT '城市分线',
    `p_change_from` array < string > COMMENT '（省）旧code',
    `c_change_from` array < string > COMMENT '（市）旧code',
    `a_change_from` array < string > COMMENT '（区）旧code'
  ) COMMENT '一个省份一个城市一个地区一条记录' ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dw.db/dim_region'

-- =====================================================
-- 枚举值
-- =====================================================
-- 无需枚举值
--
