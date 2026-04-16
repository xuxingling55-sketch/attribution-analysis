-- =====================================================
-- 组织架构维表 dw.dim_crm_organization
-- =====================================================
--
-- 【表粒度】★必填
--   一条记录 = 一个组织单元（id 唯一标识），每行包含该单元向上的完整层级链
--   （team → heads → regiment → department → workplace）
--
-- 【业务定位】
--   电销团队组织架构通用维表。需要团名称、小组名称等展示名时，必须关联本表获取。
--
-- 【常用关联】
--   同一查询中可 left join 多次（不同别名），用 id 对齐事实表各层级 id：
--
--   left join dw.dim_crm_organization d0 on t.workplace_id  = d0.id  -- 职场名称
--   left join dw.dim_crm_organization d1 on t.department_id = d1.id  -- 学部名称
--   left join dw.dim_crm_organization d2 on t.regiment_id   = d2.id  -- 团队名称
--   left join dw.dim_crm_organization d4 on t.team_id       = d4.id  -- 小组名称
--
--   取哪个层级，用对应别名上的 _name 字段：
--   - 职场：d0.workplace_name
--   - 学部：d1.department_name
--   - 团队：d2.regiment_name
--   - 小组：d4.team_name
--
-- 【常用筛选条件】
--   ★必加条件：
--   无（本表为维表，直接 JOIN 即可）
--
--   场景条件（在事实表侧筛选，非本表字段）：
--   - workplace_id IN (4, 400, 702)     -- 限定电销职场
--   - regiment_id NOT IN (0, 303, 546)  -- 排除特殊/无效团
--
-- 【注意事项】
--   ⚠️ 勿在 aws.clue_info、aws.crm_order_info 等事实表上直接选 regiment_name 等名称字段
--      —— 表中通常无该列；应通过对应 *_id JOIN 本表取名称。
--
-- =====================================================

CREATE TABLE
  `dw`.`dim_crm_organization` (
    `id` int COMMENT '组织id',
    `team_id` int COMMENT '小组id',
    `team_name` string COMMENT '小组名称',
    `heads_id` int COMMENT '主管组id',
    `heads_name` string COMMENT '主管组名称',
    `regiment_id` int COMMENT '团id',
    `regiment_name` string COMMENT '团名称',
    `department_id` int COMMENT '学部id',
    `department_name` string COMMENT '学部名称',
    `workplace_id` int COMMENT '销售职场id',
    `workplace_name` string COMMENT '销售职场名称',
    `father_path_id` string COMMENT '上级路径id',
    `full_path_id` string COMMENT '本机路径id',
    `created_at` string COMMENT '创建时间',
    `updated_at` string COMMENT '更新时间'
  ) COMMENT '电销组织架构维度表\n' ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde' STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcInputFormat' OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat' LOCATION 'tos://yc-data-platform/user/hive/warehouse/dw.db/dim_crm_organization' TBLPROPERTIES (
    'alias' = '电销组织架构维度表',
    'bucketing_version' = '2',
    'transient_lastDdlTime' = '1776013481'
  )


