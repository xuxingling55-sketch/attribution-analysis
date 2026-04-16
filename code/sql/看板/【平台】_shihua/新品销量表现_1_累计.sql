-- =====================================================
-- 看板名称：新品销量表现
-- 业务域：【平台】_shihua
-- 图表/组件：新品销量表现_1_累计
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

-- 新品销量表现 - 累计表（供报告「新品」累计订单量/销售额）
-- 口径与《新品销量监控》一致，时间：今年至今

with peiyou_sku_names as (
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
)
select
  case
    when sku_group_good_id = '7ce03413-b076-4188-9ff8-4bbf2c2c35bf' then '初中部系列徽章盲盒单枚'
    when sku_group_good_id = '3f7934bd-5e10-4181-aa3d-4266bef8344e' then '初中部系列徽章盲盒套装'
    when sku_group_good_id = '2ad8276a-4363-4c08-a136-68ee9f2dd9dd' then '好习惯提分笔记本套装'
    when good_id = '667d160a603f7a548696f55f' or sku_group_good_id in ('f1a4ada7-5eef-4255-a944-61196ec9f613','9c9de29e-b871-4aa1-9748-5ba519aeab34','66d95c7829a2104ca665ed06') then '小初高甄选试卷库'
    when good_kind_id_level_3 = 'f6f781ef-b49e-4e63-89a9-8b8bd4e0dfbc' and good_subject_cnt = 1 and good_stage_subject regexp '1-2-specialCourse' then '从小学物理'
    when good_kind_id_level_3 = '3bf5762c-f9a6-4a04-b6e8-506f097474e4' and good_subject_cnt = 1 and good_stage_subject regexp '1-2-specialCourse' and good_stage_subject regexp '2-2-vip' then '小初物理品'
    when good_kind_id_level_2 = 'd99f155b-c0e7-4ee6-9833-39a6eadbab58' and good_subject_cnt = 1 and good_stage_subject regexp '3-7-vip' then '高中地理同步课'
    when good_kind_id_level_2 = 'd99f155b-c0e7-4ee6-9833-39a6eadbab58' and good_subject_cnt = 1 and good_stage_subject regexp '3-12-vip' then '高中历史同步课'
    when good_kind_id_level_2 = 'd99f155b-c0e7-4ee6-9833-39a6eadbab58' and good_subject_cnt = 1 and good_stage_subject regexp '3-20-vip' then '高中思想政治同步课'
    when good_kind_id_level_2 = '3aa9d1fb-0c47-407e-9d5b-35c73768ec14' and good_subject_cnt = 1 and good_stage_subject regexp '3-3-timingSpecialCourse' then '高中语文总复习培优课'
    when b.peiyou_kind = '重难点培优课' and good_stage_subject regexp '3-1-specialCourse' then '高中数学重难点培优课'
    when b.peiyou_kind = '重难点培优课' and good_stage_subject regexp '3-2-specialCourse' then '高中物理重难点培优课'
    when b.peiyou_kind = '重难点培优课' and good_stage_subject regexp '3-4-specialCourse' then '高中化学重难点培优课'
    when b.peiyou_kind = '重难点培优课' and good_stage_subject regexp '3-6-specialCourse' then '高中生物重难点培优课'
  end as types        -- 新品
  , count(distinct a.order_id) as orders             -- 累计订单量
  , sum(sub_amount) as amount                        -- 累计销售额(退前)
  , sum(case when status = '支付成功' then sub_amount else 0 end) as tuihou_amount  -- 累计销售额(退后)
from dws.topic_order_detail a
left join peiyou_sku_names b on a.order_id = b.order_id
where paid_time_sk between 20250101 and replace(date(now())-1,'-','')
group by 1
having types is not null
limit 100000
