=====================================================

-- {学科学段学期教材版本混合维度表} {dw}.{dim_term}
-- =====================================================
--
-- 【表粒度】
--  一个学科一个学段一个学期一个教材版本=一条记录（term_sk 唯一标识）
--  存储学科、学段、学期、教材版本的名称、id的信息表

--【常用关联】
-- 查看具体单个或多个学科（如：数学）、学期（如：八年级上册）、教材版本（如：苏科版等）类数据
-- 本表.term_sk=dw.fact_user_watch_video_day.term_sk

-- 【注意事项】
--  与dw.fact_user_watch_video_day此表关联时，dw.fact_user_watch_video_day中的term_sk非唯一值，会出现多条的情况

--
-- =====================================================

CREATE EXTERNAL TABLE `dw`.`dim_term` (
  `term_sk` int COMMENT 'dw生成的代理键',
  `subject_id` int COMMENT '学科id',
  `subject_name` string COMMENT '学科名',
  `stage_id` int COMMENT '学段id',
  `stage_name` string COMMENT '学段名',
  `semester_id` int COMMENT '学期id',
  `semester_name` string COMMENT '学期名',
  `publisher_id` int COMMENT '教材版本id',
  `publisher_name` string COMMENT '教材版本名',
  `create_time` timestamp COMMENT '源系统创建条目的时间',
  `update_time` timestamp COMMENT '源系统修改条目的时间',
  `dw_insert_time` timestamp COMMENT 'ETL插入记录的时间',
  `dw_update_time` timestamp COMMENT 'ETL修改记录的时间'
) COMMENT '一个学科一个学段一个学期一个教材版本一条记录' ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dw.db/dim_term' TBLPROPERTIES (
  'alias' = '学科学段学期教材版本混合维度表',
  'bucketing_version' = '2',
  'last_modified_by' = 'liuguanxiong',
  'last_modified_time' = '1727248603',
  'spark.sql.create.version' = '2.2 or prior',
  'spark.sql.sources.schema.numParts' = '1',
  'spark.sql.sources.schema.part.0' = '{"type":"struct","fields":[{"name":"term_sk","type":"integer","nullable":true,"metadata":{"comment":"dw生成的代理键"}},{"name":"subject_id","type":"integer","nullable":true,"metadata":{"comment":"学科id"}},{"name":"subject_name","type":"string","nullable":true,"metadata":{"comment":"学科名"}},{"name":"stage_id","type":"integer","nullable":true,"metadata":{"comment":"学段id"}},{"name":"stage_name","type":"string","nullable":true,"metadata":{"comment":"学段名"}},{"name":"semester_id","type":"integer","nullable":true,"metadata":{"comment":"学期id"}},{"name":"semester_name","type":"string","nullable":true,"metadata":{"comment":"学期名"}},{"name":"publisher_id","type":"integer","nullable":true,"metadata":{"comment":"教材版本id"}},{"name":"publisher_name","type":"string","nullable":true,"metadata":{"comment":"教材版本名"}},{"name":"create_time","type":"timestamp","nullable":true,"metadata":{"comment":"源系统创建条目的时间"}},{"name":"update_time","type":"timestamp","nullable":true,"metadata":{"comment":"源系统修改条目的时间"}},{"name":"dw_insert_time","type":"timestamp","nullable":true,"metadata":{"comment":"ETL插入记录的时间"}},{"name":"dw_update_time","type":"timestamp","nullable":true,"metadata":{"comment":"ETL修改记录的时间"}}]}',
  'transient_lastDdlTime' = '1774369648'
)


-- =====================================================
-- 枚举值
-- =====================================================
-- 无
