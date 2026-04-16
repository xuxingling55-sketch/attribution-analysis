-- 企微预估 Step2: contact_log口径 添加量/入库量/当配转化 by 月×学段×SABC
-- 历史窗口: 2025-01~2025-04 + 2025-12~2026-03

with t0 as (
    select
        external_user_id, yc_user_id, worker_id, channel_id, add_created_at
    from (
        select distinct
            external_user_id, yc_user_id, worker_id, channel_id
            ,created_at as add_created_at
            ,row_number() over(partition by external_user_id, worker_id, channel_id, yc_user_id order by created_at) as rn
        from crm.contact_log
        where source = 3
          and change_type = 'add_external_contact'
          and (substr(created_at,1,7) between '2025-01' and '2025-04'
               or substr(created_at,1,7) between '2025-12' and '2026-03')
          and substr(created_at,1,10) <= date_sub(current_date,1)
          and length(yc_user_id) = 24
          and yc_user_id <> '000000000000000000000001'
    ) tmp
    where rn = 1
)

,t1 as (
    select * from (
        select
            t0.add_created_at
            ,t0.external_user_id
            ,t0.yc_user_id
            ,t0.worker_id
            ,t0.channel_id
            ,c.clue_level_name as sabc
            ,case
                when u.grade in ('一年级','二年级','三年级','四年级','五年级','六年级') then '小学'
                when u.grade in ('七年级','八年级','九年级') then '初中'
                when u.grade in ('高一','高二','高三','十年级') then '高中'
                when u.grade in ('职一','职二','职三') then '中职'
                when u.grade = '学龄前' then '学龄前'
                else '其他'
            end as stage
            ,b.user_id as clue_user_id
            ,substr(b.created_at,1,19) as recieve_time
            ,row_number() over(partition by t0.add_created_at, t0.external_user_id, t0.worker_id, t0.channel_id order by substr(b.created_at,1,19)) as rk
        from t0
        left join dw.dim_user u
            on t0.yc_user_id = u.u_user
        left join crm.qr_code_change_history c
            on t0.channel_id = c.qr_code_id
            and substr(t0.add_created_at,1,19) >= c.effective_time
            and substr(t0.add_created_at,1,19) < c.invalid_time
        left join aws.clue_info b
            on t0.external_user_id = b.we_com_open_id
            and t0.worker_id = b.worker_id
            and t0.channel_id = b.qr_code_channel_id
            and t0.yc_user_id = b.user_id
            and b.created_at > t0.add_created_at
            and substr(b.created_at,1,10) < date_add(t0.add_created_at,1)
    ) tmp
    where rk = 1
)

,t2 as (
    select
        substr(pay_time,1,19) as pay_time
        ,user_id as paid_userid
        ,worker_id as workerid
        ,order_id as orderid
        ,amount
    from aws.crm_order_info
    where (substr(pay_time,1,7) between '2025-01' and '2025-04'
           or substr(pay_time,1,7) between '2025-12' and '2026-03')
      and substr(pay_time,1,10) <= date_sub(current_date,1)
      and workplace_id in (4,400,702)
      and regiment_id not in (0,303,546)
      and worker_id <> 0
      and in_salary = 1
      and is_test = false
      and status = '支付成功'
)

select
    substr(t1.add_created_at,1,7) as `月份`
    ,t1.stage as `学段`
    ,t1.sabc as `渠道等级`
    ,count(distinct t1.external_user_id) as `添加量`
    ,count(distinct case when t1.clue_user_id is not null then t1.external_user_id end) as `拉取入库量`
    ,count(distinct case
        when t2.paid_userid is not null
        and substr(t2.pay_time,1,7) = substr(t1.add_created_at,1,7)
        then t2.paid_userid end) as `当配转化量`
    ,sum(case
        when t2.paid_userid is not null
        and substr(t2.pay_time,1,7) = substr(t1.add_created_at,1,7)
        then t2.amount else 0 end) as `当配转化金额`
from t1
left join t2
    on t1.clue_user_id = t2.paid_userid
    and t2.pay_time > t1.recieve_time
group by
    substr(t1.add_created_at,1,7)
    ,t1.stage
    ,t1.sabc
order by 1,2,3
limit 100000
