DROP TABLE IF EXISTS tmp.fanyu_wecomAI_funnel_efficiency；
CREATE TABLE  IF NOT EXISTS tmp.fanyu_wecomAI_funnel_efficiency AS(
with t0 as --分组用户信息
(
  select 
  substr(create_time,1,10) create_day
  ,substr(create_time,1,19) create_time
  ,uid as u_user
  ,ab_code
  ,case when ab_code = 'a' then '实验组'
      when ab_code = 'b' then '对照组'
      when ab_code = 'c' then 'left组'
      else '' end group_code
  from xlab.sample_hour
  where substr(create_time,1,10) between '2026-02-09' and date_sub(current_date(),1)
  and group_code in ('cdacc7962750c4a86c184c7d989d454a')
  group by 1,2,3,4,5
)

,t1 as --用户年级信息
(
  select 
  distinct
  from_unixtime(unix_timestamp(cast(day as string),'yyyyMMdd'),'yyyy-MM-dd') day
  ,u_user
  ,grade
  ,case when stage_id = 1 then '小学'
        when stage_id = 2 then '初中'
        when stage_id = 3 then '高中'
        when stage_id = 4 then '中职'
        when stage_id = 5 then '启蒙'
        else '' end as stage
  ,case when role = 'student'  and is_parents = false then '纯学生'
        when role = 'student' and is_parents = true then '学生家长共用'
        when real_identity = 'parents' then '纯家长'
        else '' end as identity
    -- 实验分流未区分家长学生，选择身份后展示页面不一样
  ,case when role = 'student'  and is_parents = false then '学生路径'
        when role = 'student' and is_parents = true then '学生路径'
        when real_identity = 'parents' then '家长路径'
        else '' end as role
  from dw.dim_user_his
  where day >=20260209
  and substr(regist_time,1,10) between '2026-02-09' and date_sub(current_date(),1)
  and user_attribution in ('中学业务','小学业务','c') 
)

,t2 as --漏斗数据,这个表是一个渠道一条曝光一条数据，有可能用户在A渠道曝光之后在B渠道又曝光，所以get_entrance_user不唯一，需要处理
(
  select DISTINCT
  a.day
  ,a.role
  ,get_entrance_user --资源位曝光
  ,click_entrance_user --资源位点击
  ,get_wechat_user --坐席二维码曝光
  ,add_wechat_user --坐席二维码添加
  ,pull_wechat_user --拉取入库
  from 
  (
    select distinct
    from_unixtime(unix_timestamp(cast(day as string),'yyyyMMdd'),'yyyy-MM-dd') day
    ,case when scene = 'registration-studentsProcess-addWechat' then '学生路径'
          when scene = 'registration-parentsProcess-addWechat' then '家长路径'
          else '' end as role
    ,get_entrance_user --资源位曝光
    from aws.user_pay_process_add_wechat_day 
    where day between 20260209 and date_format(date_sub(current_date(),1),'yyyyMMdd')
    and scene in ('registration-studentsProcess-addWechat','registration-parentsProcess-addWechat')
    -- and task_id in ()
  ) a --资源位曝光
  left join 
  (
    select distinct
    from_unixtime(unix_timestamp(cast(day as string),'yyyyMMdd'),'yyyy-MM-dd') day
    ,case when scene = 'registration-studentsProcess-addWechat' then '学生路径'
          when scene = 'registration-parentsProcess-addWechat' then '家长路径'
          else '' end as role
    ,click_entrance_user --资源位点击
    from aws.user_pay_process_add_wechat_day 
    where day between 20260209 and date_format(date_sub(current_date(),1),'yyyyMMdd')
    and scene in ('registration-studentsProcess-addWechat','registration-parentsProcess-addWechat')
    -- and task_id in ()
    and click_entrance_user is not null
  ) b --资源位点击
  on a.day = b.day and a.role = b.role and a.get_entrance_user = b.click_entrance_user 
  left join 
  (
    select distinct
    from_unixtime(unix_timestamp(cast(day as string),'yyyyMMdd'),'yyyy-MM-dd') day
    ,case when scene = 'registration-studentsProcess-addWechat' then '学生路径'
          when scene = 'registration-parentsProcess-addWechat' then '家长路径'
          else '' end as role
    ,get_wechat_user --坐席二维码曝光
    from aws.user_pay_process_add_wechat_day 
    where day between 20260209 and date_format(date_sub(current_date(),1),'yyyyMMdd')
    and scene in ('registration-studentsProcess-addWechat','registration-parentsProcess-addWechat')
    -- and task_id in ()
    and get_wechat_user is not null
  ) c --坐席二维码曝光
  on b.day = c.day and b.role = c.role and b.click_entrance_user = c.get_wechat_user
  left join 
  (
    select distinct
    from_unixtime(unix_timestamp(cast(day as string),'yyyyMMdd'),'yyyy-MM-dd') day
    ,case when scene = 'registration-studentsProcess-addWechat' then '学生路径'
          when scene = 'registration-parentsProcess-addWechat' then '家长路径'
          else '' end as role
    ,add_wechat_user --坐席二维码添加
    from aws.user_pay_process_add_wechat_day 
    where day between 20260209 and date_format(date_sub(current_date(),1),'yyyyMMdd')
    and scene in ('registration-studentsProcess-addWechat','registration-parentsProcess-addWechat')
    -- and task_id in ()
    and add_wechat_user is not null 
  ) d --坐席二维码添加
  on c.day = d.day and c.role = d.role and c.get_wechat_user = d.add_wechat_user
  left join 
  (
    select distinct
    from_unixtime(unix_timestamp(cast(day as string),'yyyyMMdd'),'yyyy-MM-dd') day
    ,case when scene = 'registration-studentsProcess-addWechat' then '学生路径'
          when scene = 'registration-parentsProcess-addWechat' then '家长路径'
          else '' end as role
    ,pull_wechat_user --拉取入库
    from aws.user_pay_process_add_wechat_day 
    where day between 20260209 and date_format(date_sub(current_date(),1),'yyyyMMdd')
    and scene in ('registration-studentsProcess-addWechat','registration-parentsProcess-addWechat')
    -- and task_id in ()
    and pull_wechat_user is not null
  ) e --拉取入库
  on d.day = e.day and d.role = e.role and d.add_wechat_user = e.pull_wechat_user
)

,y0 as --整体用户信息及漏斗数据
(
select
distinct 
    t0.create_day
    ,t0.create_time
    -- 实验分流未区分家长学生，选择身份后展示页面不一样
    ,ifnull(t1.role,'') as role
    ,t0.ab_code
    ,t1.grade
    ,t1.stage
    ,t1.identity
    ,t0.u_user --分组用户
    ,t2.get_entrance_user --资源位曝光
    ,t2.click_entrance_user --资源位点击
    ,t2.get_wechat_user --坐席二维码曝光
    ,t2.add_wechat_user --坐席二维码添加
    ,t2.pull_wechat_user --拉取入库
from t0
left join t1 on t0.u_user = t1.u_user and t0.create_day = t1.day
left join t2 on t0.u_user = t2.get_entrance_user and t0.create_day = t2.day
)

,y1 as --转化数据
(
  select 
  substr(pay_time,1,10) pay_day
  ,substr(pay_time,1,19) pay_time 
  ,order_id
  ,user_id
  ,amount
  from aws.crm_order_info 
  where 
  substr(pay_time,1,10) between '2026-02-09' and date_sub(current_date(),1)
  and workplace_id in (4,400,702)
  and regiment_id not in (0,303,546)
  and worker_id <> 0
  and in_salary = 1
  and is_test = false
)

select
create_day --分组时间
,role --分组身份
,ab_code --ab分组
,grade --用户年级
,stage --用户学段
,identity --用户身份
,count(distinct u_user) user_cnt--分组用户量
,count(distinct get_entrance_user)  get_entrance_user_cnt--资源位曝光量
,count(distinct click_entrance_user) click_entrance_user_cnt --资源位点击量
,count(distinct get_wechat_user)  get_wechat_user_cnt--坐席二维码曝光量
,count(distinct add_wechat_user) add_wechat_user_cnt --坐席二维码添加量
,count(distinct pull_wechat_user) pull_wechat_user_cnt --拉取入库量

,count(distinct case when y1.pay_day=y0.create_day then y0.pull_wechat_user end) paid_cnt--`入库线索当日转化量`
,count(distinct case when y1.pay_day<=date_add(y0.create_day,3) then y0.pull_wechat_user end) paid_cnt_3d
,count(distinct case when y1.pay_day<=date_add(y0.create_day,7) then y0.pull_wechat_user end) paid_cnt_7d
,count(distinct case when y1.pay_day<=date_add(y0.create_day,14) then y0.pull_wechat_user end) paid_cnt_14d
,count(distinct case when y1.pay_day<=date_add(y0.create_day,30) then y0.pull_wechat_user end) paid_cnt_30d
,count(distinct case when substr(y1.pay_day,1,7)=substr(y0.create_day,1,7) then y0.pull_wechat_user end) paid_cnt_current_momth

,sum(case when substr(y1.pay_time,1,10)=y0.create_day then y1.amount end) paid_amount--`入库线索当日转化金额`
,sum(case when substr(y1.pay_time,1,10)<=date_add(y0.create_day,3) then y1.amount end) paid_amount_3d
,sum(case when substr(y1.pay_time,1,10)<=date_add(y0.create_day,7) then y1.amount end) paid_amount_7d
,sum(case when substr(y1.pay_time,1,10)<=date_add(y0.create_day,14) then y1.amount end) paid_amount_14d
,sum(case when substr(y1.pay_time,1,10)<=date_add(y0.create_day,30) then y1.amount end) paid_amount_30d
,sum(case when substr(y1.pay_time,1,7)=substr(y0.create_day,1,7) then y1.amount end) paid_amount_current_month
,cast(regexp_replace(y0.create_day, '-', '') as int) as dt
from y0
left join y1 on y0.pull_wechat_user = y1.user_id and y1.pay_time > y0.create_time
group by 
create_day
,role
,ab_code
,grade
,stage
,identity
)