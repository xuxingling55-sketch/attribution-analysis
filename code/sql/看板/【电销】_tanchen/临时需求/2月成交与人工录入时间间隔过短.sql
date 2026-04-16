-- 质检场景：2月成交数据中，成交坐席人工录入线索后5分钟内即成交
-- 用 recent_info_uuid 直接关联最近一次线索记录，判断是否为 manual 且间隔 < 5min
with feb_orders as (
  select
    order_id
    ,user_id
    ,worker_id
    ,worker_name
    ,pay_time
    ,regiment_id
    ,recent_info_uuid
  from aws.crm_order_info
  where substr(cast(pay_time as string), 1, 7) = '2026-02'
    and workplace_id in (4, 400, 702)
    and regiment_id not in (0, 303, 546)
    and worker_id <> 0
    and in_salary = 1
    and is_test = false
    and status = '支付成功'
    and recent_info_uuid is not null
)
select
  substr(cast(o.pay_time as string), 1, 19) as `成交时间`
  ,o.order_id as `订单号`
  ,o.user_id as `用户id`
  ,o.worker_name as `坐席名称`
  ,d.regiment_name as `所属团`
  ,c.clue_source as `最近一次入库方式`
  ,substr(cast(c.created_at as string), 1, 19) as `录入时间`
  ,round((unix_timestamp(o.pay_time) - unix_timestamp(c.created_at)) / 60.0, 1) as `录入到成交间隔_分钟`
from feb_orders o
inner join aws.clue_info c on o.recent_info_uuid = c.info_uuid
left join dw.dim_crm_organization d on o.regiment_id = d.id
where c.clue_source = 'manual'
  and unix_timestamp(o.pay_time) - unix_timestamp(c.created_at) between 0 and 299
order by o.pay_time
limit 100000
