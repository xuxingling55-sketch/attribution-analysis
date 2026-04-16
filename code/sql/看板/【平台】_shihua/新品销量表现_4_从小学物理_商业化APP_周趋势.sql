-- =====================================================
-- 看板名称：新品销量表现
-- 业务域：【平台】_shihua
-- 图表/组件：新品销量表现_4_从小学物理_商业化APP_周趋势
-- 工具与位置：FineBI（自 `.cursor/code/sql/临时文件` 迁入）
-- 刷新周期：T+1
-- 维护人：meishihua
-- 关联指标：→ glossary/【平台】_shihua.md#
-- 主用表：→ code/sql/表结构/【平台】_shihua/
-- 【常用关联】
--   - 依赖表与 JOIN 口径见正文 SELECT；tmp/维表 DDL 见 code/sql/表结构/【平台】_shihua/（若暂无对应 DDL 以调度与库元数据为准）
-- 最后同步自看板日期：20260401
-- ⚠️ 注意：
-- =====================================================

-- 帆软-数据准备-sql 
-- 数据准备-sql

-- 新品销量表现 - 周趋势下钻：仅「从小学物理」+「商业化-APP」
-- 近一个月，周口径与周趋势一致；维度 sell_from，筛选 新品=从小学物理 且 sellfrom=商业化-APP

with week_day as (
  select
    date(date_id) as dt
  from dw.dim_date
  where day between substr(replace(date(now()) + interval -1 month, '-', ''), 1, 8)
                 and replace(date(now()) - 1, '-', '')
),
peiyou_sku_names as (
  select
    order_id,
    case
      when sku_list rlike '重难点' and sku_list not rlike '一轮复习|二轮复习|真题精讲' then '重难点培优课'
      when sku_list rlike '一轮复习' and sku_list not rlike '重难点|二轮复习|真题精讲' then '一轮复习培优课'
      when sku_list rlike '二轮复习' and sku_list not rlike '重难点|一轮复习|真题精讲' then '二轮复习培优课'
      when sku_list rlike '真题精讲' and sku_list not rlike '重难点|一轮复习|二轮复习' then '真题精讲培优课'
      else '其它'
    end as peiyou_kind
  from (
    select order_id, concat_ws(',', collect_set(sku_name)) as sku_list
    from dws.topic_order_detail
    where paid_time_sk >= 20230101
      and good_kind_name_level_2 = '培优课'
      and good_subject_cnt = 1
      and kind rlike 'specialCourse|SpecialCourse'
      and sku_name rlike '重难点|一轮复习|二轮复习|真题精讲'
      and stage_name = '高中'
    group by order_id
  ) t
),
new_good_types as (
  select
    case
      when good_kind_id_level_3 = 'f6f781ef-b49e-4e63-89a9-8b8bd4e0dfbc' and good_subject_cnt = 1 and good_stage_subject regexp '1-2-specialCourse' then '从小学物理'
    end as types,
    case
      when sell_from regexp 'shangyehua' or sell_from regexp 'app' then '商业化-APP'
      else '其它'
    end as sellfrom,
    a.order_id,
    date(paid_time) as dt
  from dws.topic_order_detail a
  left join peiyou_sku_names b on a.order_id = b.order_id
  where paid_time_sk between substr(replace(date(now()) + interval -1 month, '-', ''), 1, 8)
                         and replace(date(now()) - 1, '-', '')
    and good_kind_id_level_3 = 'f6f781ef-b49e-4e63-89a9-8b8bd4e0dfbc'
    and good_subject_cnt = 1
    and good_stage_subject regexp '1-2-specialCourse'
    and (sell_from regexp 'shangyehua' or sell_from regexp 'app')
  group by 1, 2, 3, 4
  having types is not null and sellfrom = '商业化-APP'
),
base as (
  select
    w.dt,
    n.order_id
  from week_day w
  left join new_good_types n on w.dt = n.dt
),
agg as (
  select
    weekofyear(date_add(dt, 3)) as week,
    min(dt) as week_start_date,
    count(distinct order_id) as orders
  from base
  group by week
)
select
  date_format(week_start_date, 'yyyy-MM-dd') as week_start_date  -- 周起始日
  , orders                                                       -- 当周订单量
from agg
order by week_start_date
limit 100000
