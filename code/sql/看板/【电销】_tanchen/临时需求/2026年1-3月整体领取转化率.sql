-- 2026年1-3月整体领取转化率及转化金额
-- 口径：日报粒度先聚合再按月SUM（conversion-calc-convention）
-- 转化窗口：累积（领取后所有时间）
-- 基于模板 T-CLU-01

with detail as (
  select
    substr(a.created_at, 1, 10) as `领取日期`
    ,a.worker_id
    ,a.regiment_id
    ,b.clue_source_name
    ,b.clue_source_name_level_1
    ,count(distinct a.user_id) as recieve_cnt
    ,count(distinct t2.user_id) as paid_cnt
    ,sum(case when t2.user_id is not null then t2.amount else 0 end) as paid_amount
  from aws.clue_info a
  left join tmp.wuhan_clue_soure_name b on a.clue_source = b.clue_source
  left join (
    select user_id, order_id, amount, pay_time
    from aws.crm_order_info
    where workplace_id in (4, 400, 702)
      and regiment_id not in (0, 303, 546)
      and worker_id <> 0
      and in_salary = 1
      and is_test = false
  ) t2 on a.user_id = t2.user_id and t2.pay_time >= a.created_at
  where a.workplace_id in (4, 400, 702)
    and substr(a.created_at, 1, 7) between '2026-01' and '2026-03'
  group by substr(a.created_at, 1, 10), a.worker_id, a.regiment_id
    ,b.clue_source_name, b.clue_source_name_level_1
)
select
  substr(`领取日期`, 1, 7) as `月份`
  ,sum(recieve_cnt) as `领取量`
  ,sum(paid_cnt) as `转化量`
  ,round(sum(paid_cnt) * 1.0 / sum(recieve_cnt), 4) as `转化率`
  ,sum(paid_amount) as `转化金额`
from detail
group by substr(`领取日期`, 1, 7)
order by `月份`
limit 100000
