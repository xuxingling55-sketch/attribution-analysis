with qr_hist_ai AS (
  -- type_name=AI机器人：按 qr_code_id、effective_time 所在日去重，取当日最新 effective_time
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

,addv_base AS
(
  -- 企微添加
  select distinct
    t1.external_user_id --企微 id
    ,t1.yc_user_id --用户 id
    ,t1.channel_id --渠道 id
    ,t1.created_at  --添加时间
    ,t1.contact_date
    ,t1.worker_id
    -- ,cast(t1.worker_id as STRING) as worker_id
    ,t2.name as worker_name
    ,t3.heads_name
    ,t4.regiment_name
    ,t1.rn
  from (
    select distinct
    t1.external_user_id --企微 id
    ,t1.yc_user_id --用户 id
    ,t1.channel_id --渠道 id
    ,substr(t1.created_at, 1, 19) as created_at  --添加时间
    ,substr(t1.created_at, 1, 10) AS contact_date
    ,t1.worker_id
    ,t1.group_id2
    ,t1.group_id3
    ,ROW_NUMBER() OVER (PARTITION BY t1.external_user_id,t1.worker_id,substr(t1.created_at, 1, 10) ORDER BY substr(t1.created_at, 1, 19) ASC) AS rn -- 测试期间存在当日删除后重新添加场景
    from crm.contact_log t1
    inner join qr_hist_ai t9
    on t1.channel_id = t9.qr_code_id and substr(t1.created_at, 1, 19) >= t9.effective_time and substr(t1.created_at, 1, 19) < t9.invalid_time
    where source = 3 --1是未知,0是海报,1是短信,3渠道活码 
    and substr(created_at,1,10)  between '2026-02-09' and date_sub(current_date,1) 
    and change_type  = 'add_external_contact' --行为=添加
    and length(yc_user_id) = 24
    and yc_user_id <> '000000000000000000000001'
    and substr(created_at, 1, 10)>='2026-02-09' -- 2/9上线使用渠道活码
  )t1
  left join crm.worker t2 on t1.worker_id = t2.id --匹配坐席姓名
  left join dw.dim_crm_organization t3 on t1.group_id2 = t3.id --匹配坐席所属团队
  left join dw.dim_crm_organization t4 on t1.group_id3 = t4.id --匹配坐席所属主管组

  where rn = 1
)

,message_base AS
(-- 会话（AI触达、用户回复、消息条数）
  select
  ai_request_id -- AI请求ID
  ,message_id -- 消息ID
  ,concat(substr(send_time, 1, 10), ' ', substr(send_time, 12, 8)) AS send_time -- 消息发送时间
  ,substr(send_time, 1, 10) as send_date
  ,case when badge = 0 then "人工消息"
      when badge = 1 then "AI消息"
      when badge = 2 then "触发器消息" -- 触发器消息ai_request_id、coze_user_id信息为空
      else "异常"
      end as badge_name
  ,channel_id -- 渠道ID
  ,corp_id_str -- 企业ID
  ,coze_user_id -- 企业ID：企微用户ID
  ,regexp_extract(coze_user_id, ':(.*)$', 1) as external_user_id -- 企微用户ID
  ,is_ai_message -- 是否ai消息
  ,sender_type -- 消息发送方（internal 内部销售，external 外部客户）
  ,worker_acc_id -- 企微销售ID
  ,worker_id -- crm销售ID
  ,raw_content -- 消息json
  ,get_json_object(raw_content, '$.type') AS type_value -- 消息回调类型（11041是文本，11042是图片，11043是视频，11044是语音）
  ,get_json_object(raw_content, '$.data.content.contentType') AS content_type --消息内容类型
  -- 根据类型提取不同的内容
  ,CASE get_json_object(raw_content, '$.data.content.contentType')
      WHEN 'TEXT' THEN get_json_object(raw_content, '$.data.content.content')
      WHEN 'IMAGE' THEN get_json_object(raw_content, '$.data.content.fileInfo.fileId')
      WHEN 'VOICE' THEN get_json_object(raw_content, '$.data.content.fileId')
      WHEN 'VIDEO' THEN get_json_object(raw_content, '$.data.content.fileId')
      WHEN 'FILE' THEN get_json_object(raw_content, '$.data.content.fileName')
      ELSE NULL
  END AS content_value
  ,media_url -- 媒体文件url
  ,voice_text -- 语音转文本
  ,day -- 分区（对应created_at）
  from study_data_center.telesale_robot_message_history
  where day BETWEEN '20260209' and date_format(date_sub(current_date,1), 'yyyyMMdd')
)

,user_base AS
(-- 用户学习时长、打开app数据
  select 
  day -- 日期
  ,TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(CAST(day AS STRING), 'yyyyMMdd'))) AS day_date
  ,user_id -- 用户ID
  ,learn_duration_day -- 日学习时长
  ,is_open_app_1d -- 当日是否打开app(1)
  from aws.crm_user_profile_day
  where day>='20260209'
)

,dim_user AS 
(-- 取用户当日的属性：dw.dim_user_his 按日分区存储快照，取 contact_date 当日信息
  select distinct
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

,active_user AS 
(
  -- 留存活跃用户（取自 mid_active_user_os_day，与实验组留存口径一致）
  SELECT
  u_user,
  TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(CAST(day AS STRING), 'yyyyMMdd'))) AS active_date
  FROM aws.mid_active_user_os_day
  WHERE day >= 20260209
    AND active_user IS NOT NULL
  GROUP BY 1, 2
)

-- 关联
,user_count AS
(
select distinct
   t1.contact_date
  ,t1.worker_id
  ,t1.worker_name
  ,t1.yc_user_id as addv_user -- 企微添加
  ,t1.external_user_id
  ,ifnull(dimu.grade, '') AS grade
  ,ifnull(dimu.stage, '') AS stage
  ,ifnull(dimu.identity, '') AS identity
  ,case when t2.external_user_id is not null then t1.yc_user_id else null end as AImsg_user -- AI首触
  ,case when t3.etnuser_msg_num>=3 then t1.yc_user_id else null end as usermag_user -- 用户开口
  ,t3.etnuser_msg_num -- 用户发消息条数
  ,t3.etnuserAI_msg_num -- AI用户互动消息条数
  ,case when t4.day_date = t1.contact_date and t4.learn_duration_day>=300 then t1.yc_user_id else null end as learn_1_user -- 当日学习用户
  ,max(case when t2.external_user_id is not null and t4.day_date = t1.contact_date and t4.is_open_app_1d=1 then t1.yc_user_id else null end) as active_1_user -- 当日活跃用户
  ,max(case when t2.external_user_id is not null and t4.day_date BETWEEN DATE_ADD(t1.contact_date,1) and DATE_ADD(t1.contact_date,3) and t4.is_open_app_1d=1 then t1.yc_user_id else null end) as active_3_user -- 3日活跃用户
  ,max(case when t2.external_user_id is not null and t4.day_date BETWEEN DATE_ADD(t1.contact_date,1) and DATE_ADD(t1.contact_date,5) and t4.is_open_app_1d=1 then t1.yc_user_id else null end) as active_5_user -- 5日活跃用户
  ,max(case when t2.external_user_id is not null and t4.day_date BETWEEN DATE_ADD(t1.contact_date,1) and DATE_ADD(t1.contact_date,7) and t4.is_open_app_1d=1 then t1.yc_user_id else null end) as active_7_user -- 7日活跃用户
from addv_base t1 -- 企微添加

left join dim_user dimu
on t1.yc_user_id = dimu.u_user
and cast(regexp_replace(t1.contact_date, '-', '') as int) = dimu.day

left join 
(
  select 
  external_user_id
  ,worker_id
  ,send_date
  from
  (
    select 
    external_user_id
    ,worker_id
    ,substr(send_time, 1, 10) as send_date
    ,ROW_NUMBER() OVER (PARTITION BY external_user_id,worker_id,substr(send_time, 1, 19) ORDER BY send_time ASC) AS rn
    from message_base
    where is_ai_message = true
  ) a 
  where rn = 1
)t2 -- AI首触
on t1.contact_date = t2.send_date
and t1.external_user_id = t2.external_user_id
and t1.worker_id = t2.worker_id

left join 
(
  select 
  external_user_id
  ,CAST(worker_id AS BIGINT) as worker_id  -- 转换为 BIGINT
  ,send_date
  ,count(DISTINCT case when sender_type = 'external' then message_id else null end) as etnuser_msg_num
  ,count(DISTINCT case when sender_type = 'external' or is_ai_message = true then message_id else null end) as etnuserAI_msg_num
  from message_base
  where external_user_id is not null
  group by external_user_id,worker_id,send_date
)t3 -- 用户开口、互动消息数
on t1.contact_date = t3.send_date
and t1.external_user_id = t3.external_user_id
and t1.worker_id = t3.worker_id

left join user_base t4 --用户学习时长、打开app数据
on t1.yc_user_id = t4.user_id
and t4.day_date BETWEEN t1.contact_date and DATE_ADD(t1.contact_date,6)

group by 1,2,3,4,5,6,7,8,9,10,11,12,13
)

-- 留存指标：addv_base × active_user，独立聚合避免与 user_count 交叉扇出
,retention AS 
(
  SELECT
   t1.contact_date
  ,ifnull(dimu.grade, '') AS grade
  ,ifnull(dimu.stage, '') AS stage
  ,ifnull(dimu.identity, '') AS identity
  ,count(DISTINCT CASE WHEN t5.active_date = date_add(t1.contact_date, 1) THEN t1.yc_user_id END) AS retain_nextday_num -- 次日留存量
  ,count(DISTINCT CASE WHEN t5.active_date BETWEEN date_add(t1.contact_date, 1) AND date_add(t1.contact_date, 3) THEN t1.yc_user_id END) AS retain_3day_num -- 3日留存量
  ,count(DISTINCT CASE WHEN t5.active_date BETWEEN date_add(t1.contact_date, 1) AND date_add(t1.contact_date, 5) THEN t1.yc_user_id END) AS retain_5day_num -- 5日留存量
  ,count(DISTINCT CASE WHEN t5.active_date BETWEEN date_add(t1.contact_date, 1) AND date_add(t1.contact_date, 7) THEN t1.yc_user_id END) AS retain_7day_num -- 7日留存量
  ,count(DISTINCT CASE WHEN t5.active_date BETWEEN date_add(t1.contact_date, 1) AND date_add(t1.contact_date, 14) THEN t1.yc_user_id END) AS retain_14day_num -- 14日留存量
  FROM addv_base t1
  LEFT JOIN dim_user dimu
  ON t1.yc_user_id = dimu.u_user AND cast(regexp_replace(t1.contact_date, '-', '') as int) = dimu.day
  LEFT JOIN active_user t5
  ON t1.yc_user_id = t5.u_user AND t5.active_date BETWEEN date_add(t1.contact_date, 1) AND date_add(t1.contact_date, 14)
  GROUP BY 1, 2, 3, 4
)

-- 合并：原有指标 + 留存指标
insert overwrite table tmp.fanyu_wecomAI_addv_AI_active partition(dt)
SELECT
   ma.contact_date
  ,ma.grade
  ,ma.stage
  ,ma.identity
  ,ma.addv_user_num
  ,ma.aimsg_user_num
  ,ma.usermag_user_num
  ,ma.etnuser_msg_num
  ,ma.etnuserai_msg_num
  ,ma.learn_1_user_num
  ,ma.active_1_user_num
  ,ma.active_3_user_num
  ,ma.active_5_user_num
  ,ma.active_7_user_num
  ,ifnull(rt.retain_nextday_num, 0) AS retain_nextday_num -- 次日留存量
  ,ifnull(rt.retain_3day_num, 0) AS retain_3day_num -- 3日留存量
  ,ifnull(rt.retain_5day_num, 0) AS retain_5day_num -- 5日留存量
  ,ifnull(rt.retain_7day_num, 0) AS retain_7day_num -- 7日留存量
  ,ifnull(rt.retain_14day_num, 0) AS retain_14day_num -- 14日留存量
  ,cast(regexp_replace(ma.contact_date, '-', '') as int) as dt
FROM 
(
  SELECT
  contact_date
  ,grade
  ,stage
  ,identity
  ,count(distinct addv_user) as addv_user_num -- 企微添加量
  ,count(distinct AImsg_user) as aimsg_user_num -- AI首触覆盖量
  ,count(distinct usermag_user) as usermag_user_num -- 用户开口量
  ,sum(etnuser_msg_num) as etnuser_msg_num -- 用户发消息条数
  ,sum(etnuserAI_msg_num) as etnuserai_msg_num -- AI用户互动消息条数
  ,count(distinct learn_1_user) as learn_1_user_num -- 当日学习用户量
  ,count(distinct active_1_user) as active_1_user_num -- 当日活跃用户量
  ,count(distinct active_3_user) as active_3_user_num -- 3日活跃用户量
  ,count(distinct active_5_user) as active_5_user_num -- 5日活跃用户量
  ,count(distinct active_7_user) as active_7_user_num -- 7日活跃用户量
  FROM user_count
  GROUP BY contact_date, grade, stage, identity
) ma
LEFT JOIN retention rt
  ON ma.contact_date = rt.contact_date
  AND ma.grade = rt.grade
  AND ma.stage = rt.stage
  AND ma.identity = rt.identity
