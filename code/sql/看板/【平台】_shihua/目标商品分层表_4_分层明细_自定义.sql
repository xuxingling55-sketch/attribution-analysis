-- =====================================================
-- 看板名称：目标商品分层表
-- 业务域：【平台】_shihua
-- 图表/组件：目标商品分层表_4_分层明细_自定义
-- 工具与位置：FineBI（自 `.cursor/code/sql/临时文件` 迁入）
-- 刷新周期：T+1
-- 维护人：meishihua
-- 关联指标：→ glossary/【平台】_shihua.md#
-- 主用表：→ code/sql/表结构/【平台】_shihua/
-- 最后同步自看板日期：2026
-- ⚠️ 注意：
-- =====================================================

-- 帆软-数据准备-sql 
with order_info as (select 
stage_name_day -- 日用户学段
,grade_name_day -- 日用户年级
,grade_stage_name_day -- 日用户年级段
,business_user_pay_status_statistics_day -- 日统计分层
,business_user_pay_status_business_day -- 日业务分层
,grade_name_month -- 月用户学段
,stage_name_month -- 月用户年级
,grade_stage_name_month -- 月用户年级段
,business_user_pay_status_statistics_month --  月统计分层
,business_user_pay_status_business_month --  月业务分层
,business_gmv_attribution -- gmv归属
,business_good_kind_name_level_1
,business_good_kind_name_level_2
,business_good_kind_name_level_3
,subject_name
,stage_name
,good_name
,price_kind
,fix_good_year 
,paid_time
,paid_time_sk
,add_time_day
,a.order_id
,u_user
,sub_amount
,good_subject_cnt
,order_amount
,original_amount
,buy_kind
,is_zuhe
,ceils
,ceils_kind
,good_type_kind -- 策略分层-历史商品的商品分类标签
,b.type
,b.is_zaiqi_type
,b.max_is_zaiqi_type
,b.is_zaiqi_all 
,b.max_is_zaiqi
,b.zaiqi_all_info
,b.is_subject
,b.is_zaiqi_subject
,b.max_is_zaiqi_subject
,b.zaiqi_subject_info
from hive.tmp.meishihua_good_day_order_info a   -- 底层表不限制，原因是统计分层等标签没限制，追溯历史订单进行归类时如果限制了就会对不上
left join hive.tmp.meishihua_good_day_historyordertegs b on a.order_id = b.order_id
)




,new_orders as (
select
paid_time
,paid_time_sk
,order_id
,u_user
,is_zuhe
,sum(sub_amount) as amount
from order_info 
where u_user is not null 
and paid_time_sk is not null 
and original_amount >= 39
and date(paid_time) between '${doris_xufei_begin}' and '${doris_xufei_end}' -- 动态参数

<parameter> 
and `business_gmv_attribution` in ('${doris_business_gmv_attribution}')
</parameter>

group by paid_time
,paid_time_sk
,order_id
,u_user
,is_zuhe
)


,orders as (select * from 
(select *
,row_number() over(partition by u_user,buy_kind order by paid_time,order_id) as ranks
from order_info 
where date(paid_time) between '${doris_paid_begin}' and '${doris_paid_end}' -- 动态参数
and u_user is not null 
and paid_time_sk is not null 
and original_amount >= 39

) n
where ranks = 1 
)




-- # 下单后，转组合前，是否在此期间添加了企微
,qiwei as (select distinct
external_user_id
--  ,channel_id -- 添加渠道
,substr(created_at,1,10) add_times -- 添加时间
,replace(substr(created_at,1,10),'-','') as add_day
from hive.crm.contact_log -- 添加企微表
where source=3 -- 限制渠道活码添加
and substr(created_at,1,10) >= '${doris_paid_begin}' 
and substr(created_at,1,10) <= '${doris_xufei_end}'
and change_type  = 'add_external_contact' -- 添加微信 --  ###用external_user_id在crm.new_user表取user_id
)


,qiwei_user as (select a.add_times,a.add_day,b.user_id as u_user
from qiwei a 
join hive.crm.new_user b --  企微添加成功的用户:1.status=0,external_user_id=''代表用户没添加过;2.status=1,external_user_id!=''代表用户已添加且好友关系没解除;3.status=0,external_user_id!=''代表用户之前添加过，好友关系已解除
on a.external_user_id = b.external_user_id
group by a.add_times,a.add_day,b.user_id 
)

-- # 下单后，转组合前，是否在此期间参与了AI定制班学习
,mid_active_user_ai_personalized_class_day as (select 
u_user
,day -- 最近一次学习AI定制班的时间
from aws.mid_active_user_ai_personalized_class_day -- 这个表是全量c端活跃表，study_duration 是AI定制班的学习时长，如果study_duration is null 则未学习AI定制班；ai_personalized_class_user_sk 这个仅大会员在期（班级）的用户
where day >= replace(substr('${doris_paid_begin}',1,10),'-','')
and day <= replace(substr('${doris_xufei_end}',1,10),'-','') 
and study_duration > 0

group by 1,2
)



,paid_to_qiwei_or_ai_day as (
select a.stage_name_day
,a.grade_name_day
,a.grade_stage_name_day
,a.business_user_pay_status_statistics_day
,a.business_user_pay_status_business_day
,a.business_gmv_attribution
,a.buy_kind
,case 
    when a.type is not null then type 
    when a.business_user_pay_status_statistics_month not in ('新增','老未') then '20160916前商品'
    when a.business_user_pay_status_statistics_month is not null then a.business_user_pay_status_statistics_month
    else '月统计分层标签缺失' 
    end as old_type
,a.u_user
,a.order_amount as amount
,a.paid_time_sk
,a.paid_time
,a.order_id
,a.is_zaiqi_type
,a.is_zaiqi_all
,a.is_subject
,a.is_zaiqi_subject
,min(case when b.u_user is not null then b.add_day else 99999999 end) as paid_to_qiwei_day
,min(case when c.u_user is not null then c.day else 99999999 end) as paid_to_ai_personalized_class_day
from orders a 
left join qiwei_user b on a.u_user = b.u_user and a.paid_time_sk <= b.add_day
left join mid_active_user_ai_personalized_class_day c on a.u_user = c.u_user and a.paid_time_sk <= c.day
group by a.stage_name_day
,a.grade_name_day
,a.grade_stage_name_day
,a.business_user_pay_status_statistics_day
,a.business_user_pay_status_business_day
,a.business_gmv_attribution
,a.buy_kind
,case 
    when a.type is not null then type 
    when a.business_user_pay_status_statistics_month not in ('新增','老未') then '20160916前商品'
    when a.business_user_pay_status_statistics_month is not null then a.business_user_pay_status_statistics_month
    else '月统计分层标签缺失' 
    end
,a.u_user
,a.order_amount
,a.paid_time_sk
,a.paid_time
,a.order_id
,a.is_zaiqi_type
,a.is_zaiqi_all
,a.is_subject
,a.is_zaiqi_subject
)




,base3 as (SELECT 
a.stage_name_day
,a.grade_name_day
,a.grade_stage_name_day
,a.business_user_pay_status_statistics_day
,a.business_user_pay_status_business_day
,a.business_gmv_attribution
,a.buy_kind
,a.old_type
,a.u_user
,a.amount
,a.paid_time_sk
,a.order_id
,a.is_zaiqi_type
,a.is_zaiqi_all
,a.is_subject
,a.is_zaiqi_subject
,'续费周期（自定义）' as monthdiff
,max(case 
          when a.paid_to_qiwei_day = 99999999 then 0 
          when c.is_zuhe = '组合品' and a.paid_to_qiwei_day <= c.paid_time_sk then 1 
          when c.is_zuhe = '组合品' then 0
          else 1 end ) as is_add_qiwei
,max(case 
          when a.paid_to_ai_personalized_class_day = 99999999 then 0 
          when c.is_zuhe = '组合品' and a.paid_to_ai_personalized_class_day <= c.paid_time_sk then 1 
          when c.is_zuhe = '组合品' then 0
          else 1 end ) as is_add_ai
,sum(c.amount) as xufei_amount
,count(distinct c.u_user) as xufei_users
,sum(case when c.is_zuhe = '组合品' then c.amount end) as zuhe_xufei_amount
,count(distinct case when c.is_zuhe = '组合品' then c.u_user end) as zuhe_xufei_users
,sum(case when c.is_zuhe = '非组合品' then c.amount end) as unzuhe_xufei_amount
,count(distinct case when c.is_zuhe = '非组合品' then c.u_user end) as unzuhe_xufei_users
from paid_to_qiwei_or_ai_day a 
left join new_orders c on a.u_user = c.u_user and a.order_id <> c.order_id and a.paid_time <= c.paid_time

group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
)





,final as (SELECT 
stage_name_day
,grade_name_day
,grade_stage_name_day
,business_user_pay_status_statistics_day
,business_user_pay_status_business_day
,business_gmv_attribution
,buy_kind
,old_type
,monthdiff
,is_zaiqi_type
,is_zaiqi_all
,is_subject
,is_zaiqi_subject
,case when is_add_qiwei = 0 then '否' when is_add_qiwei = 1 then '是' end as is_add_qiwei
,case when is_add_ai = 0 then '否' when is_add_ai = 1 then '是' end as is_add_ai
,count(distinct u_user) users
,sum(xufei_users) as xufei_users
,sum(zuhe_xufei_users) as zuhe_xufei_users
,sum(unzuhe_xufei_users) as unzuhe_xufei_users
,sum(amount) as amount
,sum(xufei_amount) as xufei_amount
,sum(zuhe_xufei_amount) as zuhe_xufei_amount
,sum(unzuhe_xufei_amount) as unzuhe_xufei_amount
from base3 

group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 ) 



select *
from final
