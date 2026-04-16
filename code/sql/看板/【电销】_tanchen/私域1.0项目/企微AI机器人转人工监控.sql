DROP TABLE IF EXISTS tmp.fanyu_wecomAI_addv_AI_manual；
CREATE TABLE  IF NOT EXISTS tmp.fanyu_wecomAI_addv_AI_manual AS(

with qr_hist_ai AS (
  select qr_code_id, effective_time, invalid_time
  from (
    select
      qr_code_id,
      effective_time,
      invalid_time,
      ROW_NUMBER() OVER (
        PARTITION BY qr_code_id, TO_DATE(effective_time)
        ORDER BY effective_time DESC
      ) AS rn_qr
    from crm.qr_code_change_history
    where type_name = 'AI机器人'
  ) q
  where rn_qr = 1
)

,contact_yc_map AS (
  select
    t1.external_user_id,
    substr(t1.created_at, 1, 10) AS contact_date,
    t1.worker_id,
    t1.yc_user_id,
    ROW_NUMBER() OVER (
      PARTITION BY t1.external_user_id, t1.worker_id, substr(t1.created_at, 1, 10)
      ORDER BY substr(t1.created_at, 1, 19) ASC
    ) AS rn
  from crm.contact_log t1
  inner join qr_hist_ai t9
    on t1.channel_id = t9.qr_code_id
    and substr(t1.created_at, 1, 19) >= t9.effective_time
    and substr(t1.created_at, 1, 19) < t9.invalid_time
  where source = 3
    and substr(created_at, 1, 10) between '2026-02-03' and date_sub(current_date, 1)
    and change_type = 'add_external_contact'
    and length(yc_user_id) = 24
    and yc_user_id <> '000000000000000000000001'
    and substr(created_at, 1, 10) >= '2026-02-09'
)

,contact_yc AS (
  select external_user_id, contact_date, worker_id, yc_user_id
  from contact_yc_map
  where rn = 1
)

,dim_user AS (
  -- 取用户当日的属性：dw.dim_user_his 按日分区存储快照，取 contact_date（用户添加日）当日信息
  select
    u_user
    ,grade
    ,case when stage_id = 1 then '小学'
          when stage_id = 2 then '初中'
          when stage_id = 3 then '高中'
          when stage_id = 4 then '中职'
          when stage_id = 5 then '启蒙'
          else '' end AS stage
    ,case when role = 'student'  and is_parents = false then '纯学生'
          when role = 'student' and is_parents = true then '学生家长共用'
          when real_identity = 'parents' then '纯家长'
          else '' end AS identity
    ,day
  from dw.dim_user_his
  where day between 20260209 and cast(date_format(date_sub(current_date,1), 'yyyyMMdd') as int)
)

-- 互动用户（用户消息>=1、AI消息>=1）
,msg_user AS(
  select 
     external_user_id
    ,CAST(worker_id AS BIGINT) as worker_id  -- 转换为 BIGINT
    ,send_date
    ,count(DISTINCT case when sender_type = 'external' then message_id else null end) as etnuser_msg_num -- 用户消息
    ,count(DISTINCT case when is_ai_message = true then message_id else null end) as AI_msg_num -- AI消息
    ,count(DISTINCT case when sender_type = 'external' or is_ai_message = true then message_id else null end) as etnuserAI_msg_num
  from 
    (
  -- 会话
  select
      message_id -- 消息ID
      ,concat(substr(send_time, 1, 10), ' ', substr(send_time, 12, 8)) AS send_time -- 消息发送时间
      ,substr(send_time, 1, 10) as send_date
      ,channel_id -- 渠道ID
      ,regexp_extract(coze_user_id, ':(.*)$', 1) as external_user_id -- 企微用户ID
      ,is_ai_message -- 是否ai消息
      ,sender_type -- 消息发送方（internal 内部销售，external 外部客户）
      ,worker_id -- crm销售ID
      ,raw_content -- 消息json
      ,day -- 分区（对应created_at）
  from study_data_center.telesale_robot_message_history
  where day BETWEEN '20260209' and date_format(date_sub(current_date,1), 'yyyyMMdd')
  )
  where external_user_id is not null
  group by external_user_id,worker_id,send_date
)

-- 转人工
,work_turn as
(
    select 
     external_user_id
    ,worker_id
    ,created_date
    ,count(DISTINCT id) as allrg_num
    ,count(DISTINCT case when manage_type = "人工接管" then id else null end) as rgjg_num
    from 
    (
    select
        id -- 转人工记录ID
        ,created_at -- 转人工时间
        ,substr(created_at,1,10) as created_date -- 转人工日期
        ,worker_id -- 销售ID
        ,worker_user_id -- 销售拼音
        ,external_user_id -- 企微用户ID
        ,channel_id -- 渠道ID
        ,trigger_type -- 触发类型
        ,from_tag -- 原标签
        ,to_tag -- 目标标签
        ,case when (trigger_type = "active" and to_tag = "人工接待") -- 销售主动触发的转人工
            or (trigger_type = "defensive" and to_tag = "人工接待") -- 被动转人工（人工介入AI）
            or (trigger_type = "tag_callback" and to_tag = "人工接待") -- 销售修改企业微信左侧会话标签转人工
            then "人工接管"
            when trigger_type = "passive"  then "异常转人工"-- 异常转人工（AI无法回复）
            -- when trigger_type = "defensive" and to_tag = "AI接待"  then "添加微信接入AI" --用户加企业微信默认AI
        else "其他"
        end as manage_type
    from crm.transfer_human_record
    where substr(created_at,1,10)  between '2026-02-09' and date_sub(current_date,1) 
    )t
    group by
         external_user_id
        ,worker_id
        ,created_date
)

select
    t1.send_date
    ,ifnull(d.grade, '') AS grade
    ,ifnull(d.stage, '') AS stage
    ,ifnull(d.identity, '') AS identity
    -- ,t1.worker_id
    ,count(distinct t1.external_user_id) as mag_user_num
    ,count(distinct case when t2.rgjg_num>=1 then t1.external_user_id else null end) as manual_user_num
from (select * from msg_user where etnuser_msg_num>=1 and AI_msg_num>=1) t1
left join contact_yc c
  on t1.external_user_id = c.external_user_id
  and t1.send_date = c.contact_date
  and t1.worker_id = c.worker_id
left join dim_user d
  on c.yc_user_id = d.u_user
  and cast(regexp_replace(c.contact_date, '-', '') as int) = d.day
left join work_turn t2
on t1.external_user_id = t2.external_user_id
and t1.worker_id = t2.worker_id
and t1.send_date = t2.created_date
group by     
    t1.send_date
    ,ifnull(d.grade, '')
    ,ifnull(d.stage, '')
    ,ifnull(d.identity, '')
    -- ,t1.worker_id
)