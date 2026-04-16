-- =============================================================================
-- 待分析用户（商品2.0分析）
-- =============================================================================
-- 用途：产出「待分析用户」名单（用户 id、坐席、通时、组合品/续购订单等），供后续逐用户商品2.0分析、录音分析使用。
--
-- 可调项（提需求时常改）：
--   ① 时间周期：全文 '2026-01-01' / '2026-01-31' 等日期区间，需统一替换；最终结果中的「datezone」字段由该起止日期拼接，替换后自动一致
--   ② 单次通话时长：t0 中 call_time_length > 300 表示单次通话>5分钟（300 为秒），按需改
--   ③ 总通话时长：t1 中 having sum(...) >= 1800 表示该用户在该坐席下总有效通时≥30分钟（1800 为秒），按需改
--   ④ timezone：根据线索创建日（c.created_at）自动判断——>= 2026-01-01 为 2.0，>= 2025-03-01 为 1.0，更早为 大会员
-- =============================================================================

-- -----------------------------------------------------------------------------
-- y0_top20：业绩前 20 坐席名单（仅用于后续排除「其他普通销售」）
-- -----------------------------------------------------------------------------
-- 由两段 union 组成，同一坐席可能同时出现在两段中（会保留两行，到 y1 再聚合）：
--   (1) 总业绩前20：按 crm_order_info 统计周期内支付成功订单金额 sum(amount) 排序，取前 20 名 worker_id
--   (2) 当配业绩前20：线索来源为中学（mid_school_manual / mid_school），线索领取后由同一坐席成单的金额排序，取前 20 名
-- 过滤口径：workplace_id in (4,400,702)、regiment_id 排除 0/303/546、worker_id<>0、in_salary=1、is_test=false
with y0_top20 as (
  select worker_type, worker_id, worker_name, amount from (
    -- (1) 总业绩前20：全库订单金额排序取 top20
    select
      '总业绩前20' as worker_type, worker_id, worker_name, sum(amount) as amount
    from aws.crm_order_info
    where
      substr(pay_time, 1, 10) between '2026-01-01' and '2026-01-31'
      and status = '支付成功'
      and workplace_id in (4, 400, 702)
      and regiment_id not in (0, 303, 546)
      and worker_id <> 0
      and in_salary = 1
      and is_test = false
    group by 1, 2, 3
    order by 4 desc
    limit 20
  )
  union
  (
    -- (2) 当配业绩前20：中学线索当配成单金额排序取 top20
    select
      '当配业绩前20' as worker_type, a.worker_id, a.worker_name, sum(amount) as amount
    from aws.clue_info a
    left join aws.crm_order_info b on a.user_id = b.user_id and b.pay_time > a.created_at and a.worker_id = b.worker_id
    where
      substr(a.created_at, 1, 10) between '2026-01-01' and '2026-01-31'
      and a.clue_source in ('mid_school_manual', 'mid_school')
      and b.status = '支付成功'
      and b.workplace_id in (4, 400, 702)
      and b.regiment_id not in (0, 303, 546)
      and b.worker_id <> 0
      and b.in_salary = 1
      and b.is_test = false
    group by 1, 2, 3
    order by 4 desc
    limit 20
  )
)

-- -----------------------------------------------------------------------------
-- y0：本次分析所涉全部坐席（业绩前20 + 其他普通销售）
-- -----------------------------------------------------------------------------
-- 在 y0_top20 基础上，union all 增加「其他普通销售」：
--   同口径（同时间、同 workplace/regiment、支付成功等）下有订单，但 worker_id 不在 y0_top20 中的坐席
-- 输出：每行 (worker_type, worker_id, worker_name, amount)，同一坐席若既在总业绩前20又在当配前20 会有两行
, y0 as (
  select * from y0_top20
  union all
  select
    '其他普通销售' as worker_type, c.worker_id, c.worker_name, sum(c.amount) as amount
  from aws.crm_order_info c
  where
    substr(c.pay_time, 1, 10) between '2026-01-01' and '2026-01-31'
    and c.status = '支付成功'
    and c.workplace_id in (4, 400, 702)
    and c.regiment_id not in (0, 303, 546)
    and c.worker_id <> 0
    and c.in_salary = 1
    and c.is_test = false
    and not exists (
      select 1 from y0_top20 t
      where t.worker_id = c.worker_id
    )
  group by c.worker_id, c.worker_name
)

-- -----------------------------------------------------------------------------
-- y1：坐席主表（每个坐席一行，带入选类型标签）
-- -----------------------------------------------------------------------------
-- 对 y0 按 worker_id, worker_name 聚合：同一坐席在 y0 中的多行（如既总业绩前20又当配前20）合并为一行，
-- worker_types 为各类型的拼接，如 '总业绩前20'、'当配业绩前20'、'总业绩前20 + 当配业绩前20'、'其他普通销售'
, y1 as (
  select
    worker_id
    , worker_name
    , concat_ws(' + ', collect_set(worker_type)) as worker_types
  from y0
  group by worker_id, worker_name
)

-- -----------------------------------------------------------------------------
-- t0：上述坐席下、在统计周期内有「单次通时 > 可调时长」的用户（每用户取该坐席下最早一次达标通话时间）
-- -----------------------------------------------------------------------------
-- 从 fact_call_history 取与 y1 坐席匹配的通话，条件：统计周期内、call_time_length > 300（可调项②）、user_id 非空
-- 粒度：每个 (坐席, user_id, info_uuid) 一行；created_at 为该用户在该坐席下满足条件的通话中最早一次的时间
, t0 as (
  select
    y1.worker_types
    , y1.worker_id
    , y1.worker_name
    , user_id
    , info_uuid
    , substr(min(created_at), 1, 19) as created_at
  from dw.fact_call_history a
  left join y1 on a.worker_id = y1.worker_id
  where
    substr(created_at, 1, 10) between '2026-01-01' and '2026-01-31'
    and call_time_length > 300
    and length(user_id) > 0
  group by 1, 2, 3, 4, 5
)

-- -----------------------------------------------------------------------------
-- t1：在 t0 基础上汇总该用户在该坐席下、统计周期内的有效接通通话
-- -----------------------------------------------------------------------------
-- 与 fact_call_history 再次关联：同一 user_id + worker_id、统计周期内、is_valid_connect=1 的通话
-- 产出：action_ids（有效接通 action_id 列表，分号分隔）、call_cnt（有效通次）、call_time_length（有效通时合计，秒）
-- 筛选：仅保留总有效通时≥30分钟（可调项③，1800 秒）的用户
, t1 as (
  select
    t0.info_uuid
    , t0.user_id
    , t0.created_at
    , t0.worker_id, t0.worker_name, t0.worker_types
    , concat_ws(';', collect_set(a.action_id)) as action_ids
    , count(distinct a.action_id) as call_cnt
    , sum(a.call_time_length) as call_time_length
  from t0
  left join dw.fact_call_history a
    on
      t0.user_id = a.user_id
      and substr(a.created_at, 1, 10) between '2026-01-01' and '2026-01-31'
      and is_valid_connect = 1
      and t0.worker_id = a.worker_id
  group by 1, 2, 3, 4, 5, 6
  having sum(a.call_time_length) >= 1800
)

-- -----------------------------------------------------------------------------
-- t2：在 t1 基础上关联该用户在该坐席下、线索领取/首通之后的组合品与续购订单
-- -----------------------------------------------------------------------------
-- 与 crm_order_info 关联：user_id + worker_id 一致，订单支付时间 > t1.created_at（首通达标时间），
-- 品类 in ('组合品','续购')，支付成功，同 workplace/regiment 等口径，且订单归属该坐席、统计周期内
-- 产出：购买商品（按多孩/续购组合品/首购组合品/高中囤课or学段加购 分段拼接，格式见字段 schema）、ord（订单数）、amount（金额合计）
, t2 as (
  select
    t1.info_uuid
    , t1.user_id
    , t1.created_at
    , t1.worker_id, t1.worker_name, t1.worker_types
    , t1.action_ids
    , t1.call_cnt
    , t1.call_time_length
    -- @PRODUCT_CLASSIFICATIONS_START
    -- 购买商品：多条用 " | " 分隔；单条为 Tab 分隔的 8 列：类型, 一级品类, 二级品类, 三级品类, 支付时间, 订单id, 商品名, 金额（商品名内 Tab 已替换为空格）
    , concat_ws(
      ' | '
      , max(
        case
          when
            string(strategy_type) regexp '多孩策略'
            then
              concat_ws(
                '\t'
                , '多孩品'
                , business_good_kind_name_level_1
                , business_good_kind_name_level_2
                , business_good_kind_name_level_3
                , pay_time
                , order_id
                , regexp_replace(good_name, '\\t', ' ')
                , amount
              )
        end
      )
      , max(
        case
          when
            string(strategy_type) regexp '历史大会员续购策略'
            then
              concat_ws(
                '\t'
                , '续购组合品'
                , business_good_kind_name_level_1
                , business_good_kind_name_level_2
                , business_good_kind_name_level_3
                , pay_time
                , order_id
                , regexp_replace(good_name, '\\t', ' ')
                , amount
              )
        end
      )
      , max(
        case
          when
            string(strategy_type) regexp '无策略|补差策略'
            then
              concat_ws(
                '\t'
                , '首购组合品'
                , business_good_kind_name_level_1
                , business_good_kind_name_level_2
                , business_good_kind_name_level_3
                , pay_time
                , order_id
                , regexp_replace(good_name, '\\t', ' ')
                , amount
              )
        end
      )
      , max(
        case
          when
            string(business_good_kind_name_level_3) regexp '学段加购'
            then
              concat_ws(
                '\t'
                , '高中囤课or学段加购'
                , business_good_kind_name_level_1
                , business_good_kind_name_level_2
                , business_good_kind_name_level_3
                , pay_time
                , order_id
                , regexp_replace(good_name, '\\t', ' ')
                , amount
              )
        end
      )
    ) as `购买商品`
    -- @PRODUCT_CLASSIFICATIONS_END
    , count(distinct order_id) as ord
    , sum(amount) as amount
  from t1
  left join aws.crm_order_info b
    on
      t1.user_id = b.user_id
      and b.pay_time > t1.created_at
      and b.business_good_kind_name_level_1 in ('组合品', '续购') -- @PRODUCT_JOIN_FILTER
      and b.status = '支付成功'
      and b.workplace_id in (4, 400, 702)
      and b.regiment_id not in (0, 303, 546)
      and b.worker_id <> 0
      and b.in_salary = 1
      and b.is_test = false
      and substr(b.pay_time, 1, 10) between '2026-01-01' and '2026-01-31'
      and t1.worker_id = b.worker_id
  group by 1, 2, 3, 4, 5, 6, 7, 8, 9
)

-- -----------------------------------------------------------------------------
-- 最终输出：在 t2 基础上关联线索与用户维度，产出可直接用于分析的宽表
-- -----------------------------------------------------------------------------
-- 关联 dim_user：取手机号（明文或 base64 解码）；关联 clue_info：取线索领取日期、线索等级、领取时用户类型
-- 用户类型：续费 / 老未 / 新增-当月注册 / 新增-非当月注册（以线索领取时的 user_type_name 与注册月判断）
-- 限制：仅保留线索领取时间在可调时间周期内的记录
-- datezone：与可调项①时间周期一致，替换起止日期时此处会同步
select distinct
  t2.*
  , clue_grade
  , concat('2026-01-01', ' ~ ', '2026-01-31') as datezone
  , substr(c.created_at, 1, 10) as recieve_at
  , if(b.phone is null, b.phone, if(b.phone rlike '^\\d+$', b.phone, cast(unbase64(b.phone) as string))) as phone
  , case
    when user_type_name = '续费' then '续费'
    when user_type_name = '老未' then '老未'
    when user_type_name = '新增' and substr(c.created_at, 1, 7) = substr(c.regist_time, 1, 7) then '新增-当月注册'
    when user_type_name = '新增' then '新增-非当月注册'
  end as user_type_name
  , case
    when substr(c.created_at, 1, 10) >= '2026-01-01' then '2.0'
    when substr(c.created_at, 1, 10) >= '2025-03-01' then '1.0'
    else '大会员'
  end as timezone
from t2
left join dw.dim_user b on t2.user_id = b.u_user
left join aws.clue_info c on t2.info_uuid = c.info_uuid
where substr(c.created_at, 1, 10) between '2026-01-01' and '2026-01-31'
