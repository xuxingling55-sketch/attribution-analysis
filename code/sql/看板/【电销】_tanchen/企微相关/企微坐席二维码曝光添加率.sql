select 
  substr(t0.created_at,1,10) created_at
  ,t0.channel_id
  ,t1.channel_name
  ,t1.type
  ,t1.level_1
  ,t1.level_2
  ,t0.worker_id
  ,t2.name worker_name
  ,d4.team_name
  ,d3.heads_name
  ,d2.regiment_name
  ,d1.department_name
  ,case when t0.is_belong_worker = 'false' then '否' 
        when t0.is_belong_worker = 'true' then '是' 
        end is_belong_worker
  ,case when substr(t0.created_at,1,10) < '2025-07-26' then '历史无法区分'
        when substr(t0.created_at,1,10) >= '2025-07-26' and is_repeated_exposure = true then '是'
        when substr(t0.created_at,1,10) >= '2025-07-26' and is_repeated_exposure = false then '否'
      end is_repeated_exposure
  ,count(t0.channel_id) exposure_cnt 
  ,count(distinct case when length(t0.external_user_id)>0 then t0.external_user_id end) add_cnt 
from crm.new_user t0
left join tmp.wuhan_wecom_channel_id t1 on t0.channel_id = t1.id
left join crm.worker t2 on t0.worker_id = t2.id
left join dw.dim_crm_organization d1 on t0.group_id1 = d1.id
left join dw.dim_crm_organization d2 on t0.group_id2 = d2.id
left join dw.dim_crm_organization d3 on t0.group_id3 = d3.id
left join dw.dim_crm_organization d4 on t0.group_id4 = d4.id
where 
  substr(t0.created_at,1,10) between '2022-01-01' and date_sub(current_date,1)
  and t0.channel = 3
  and d2.regiment_name is not null
  and t0.group_id0 in (4,400,702)
group by 
  substr(t0.created_at,1,10) 
  ,t0.channel_id
  ,t1.channel_name
  ,t1.type
  ,t1.level_1
  ,t1.level_2
  ,t0.worker_id
  ,t2.name
  ,d4.team_name
  ,d3.heads_name
  ,d2.regiment_name
  ,d1.department_name
  ,case when t0.is_belong_worker = 'false' then '否' 
        when t0.is_belong_worker = 'true' then '是' 
        end 
  ,case when substr(t0.created_at,1,10) < '2025-07-26' then '历史无法区分'
        when substr(t0.created_at,1,10) >= '2025-07-26' and is_repeated_exposure = true then '是'
        when substr(t0.created_at,1,10) >= '2025-07-26' and is_repeated_exposure = false then '否'
      end 