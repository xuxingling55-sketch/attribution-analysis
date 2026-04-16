-- 企微预估 Step1: 宏观表取活跃量/添加量/入库/转化 by 月×学段
-- 历史窗口: 2025-01~2025-04 + 2025-12~2026-03

select
    substr(from_unixtime(unix_timestamp(cast(concat(month,'01') as string),'yyyyMMdd'),'yyyy-MM-dd'),1,7) as `月份`
    ,stage_name_month as `学段`
    ,count(distinct active_u_user) as `活跃量`
    ,count(distinct case when add_wechat_u_user is not null then active_u_user end) as `企微添加量`
    ,count(distinct case when recieve_u_user is not null then active_u_user end) as `拉取入库量`
    ,count(distinct case when recieve_paid_u_user is not null then active_u_user end) as `当配转化量`
    ,sum(recieve_paid_amount) as `当配转化金额`
from aws.crm_active_user_wechat_paid_month
where month in (202501,202502,202503,202504,202512,202601,202602,202603)
group by 1,2
order by 1,2
limit 100000
