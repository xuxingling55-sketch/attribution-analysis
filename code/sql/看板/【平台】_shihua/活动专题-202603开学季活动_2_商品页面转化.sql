-- =====================================================
-- 看板名称：活动专题-202603开学季活动
-- 业务域：【平台】_shihua
-- 图表/组件：活动专题-202603开学季活动_2_商品页面转化
-- 工具与位置：FineBI（自 `.cursor/code/sql/临时文件` 迁入）
-- 刷新周期：T+1
-- 维护人：meishihua
-- 关联指标：→ glossary/【平台】_shihua.md#
-- 主用表：→ code/sql/表结构/【平台】_shihua/
-- 最后同步自看板日期：20260302
-- ⚠️ 注意：
-- =====================================================

-- 帆软-数据准备-sql 
-- 活动资源位转化（当天漏斗）


-- APP C端活跃
WITH act_user_app_c AS
  ( SELECT u_user ,
           day ,
           STR_TO_DATE(day, '%Y%m%d') AS date_time ,
           COALESCE(business_user_pay_status_business_day,'未知') AS business_user_pay_status_business ,
           COALESCE(business_user_pay_status_statistics_day,'未知') AS business_user_pay_status_statistics ,
           if(stage_name_day IN ('小学','初中','高中','中职'),grade_name_day,'未知') AS grade_name ,
           if(stage_name_day IN ('小学','初中','高中','中职'),stage_name_day,'未知') AS stage_name ,
           if(stage_name_day IN ('小学','初中','高中','中职'),grade_stage_name_day,'未知') AS grade_stage_name
   FROM hive.aws.business_active_user_last_14_day
   WHERE 
  (day between 20260302 and 20260331 and day <= DATE_FORMAT(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), '%Y%m%d')) -- 正式时间
  -- or day between 20240901 and 20240930
  
   GROUP BY u_user ,
            day ,
            COALESCE(business_user_pay_status_business_day,'未知') ,
            COALESCE(business_user_pay_status_statistics_day,'未知'),
            if(stage_name_day IN ('小学','初中','高中','中职'),grade_name_day,'未知') ,
            if(stage_name_day IN ('小学','初中','高中','中职'),stage_name_day,'未知') ,
            if(stage_name_day IN ('小学','初中','高中','中职'),grade_stage_name_day,'未知') )


-- 进入正式页面
,yure_page AS
  (SELECT day ,
          u_user
   FROM hive.aws.business_user_pay_process_enter_good_page_day
   WHERE 

    (day between 20260302 and 20260331 and day <= DATE_FORMAT(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), '%Y%m%d') -- 
    AND page_name regexp '首购会场|多孩续购会场|高中囤课会场|大会员续购会场|加购平板页面' ) 

     
     AND u_user IS NOT NULL
     AND u_user != ''
   GROUP BY day ,
            u_user)


-- 正式下单
, yure_order AS
  ( SELECT paid_time_sk AS day ,
           u_user ,
           sum(sub_amount) AS amount
   FROM hive.dws.topic_order_detail
   WHERE business_gmv_attribution in ('商业化','电销') 
  

and paid_time_sk between 20260302 and 20260331 and paid_time_sk <= DATE_FORMAT(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), '%Y%m%d')  
-- (or paid_time_sk between 20240701 and 20240831)
 
and business_good_kind_name_level_1 = '组合品' -- 正式商品
  
  
   GROUP BY paid_time_sk,
            u_user)




select a.date_time
,a.day
,count(distinct a.u_user) act_users
,count(distinct b.u_user) yure_users
,count(distinct c.u_user) pay_users
,COALESCE(sum(c.amount), 0) amount
,COALESCE(count(distinct b.u_user) / count(distinct a.u_user), 0) act_yure_per
,COALESCE(count(distinct c.u_user) / count(distinct b.u_user), 0) yure_pay_per
,COALESCE(count(distinct c.u_user) / count(distinct a.u_user), 0) act_pay_per
from act_user_app_c a 
left join yure_page b 
on a.u_user=b.u_user and a.day=b.day 
left join yure_order c 
on b.u_user=c.u_user and b.day=c.day 

where a.date_time between '${doris_increase_date_time_start}' and '${doris_increase_date_time_end}'

<parameter> 
and `stage_name` in ('${doris_increase_stage_name_day}')
</parameter>
<parameter> 
and `grade_name` in ('${doris_increase_grade_name_day}')
</parameter>
<parameter> 
and `grade_stage_name` in ('${doris_increase_grade_stage_name_day}')
</parameter>
<parameter> 
and `business_user_pay_status_statistics` in ('${doris_increase_business_user_pay_status_statistics_day}')
</parameter>
<parameter> 
and `business_user_pay_status_business` in ('${doris_increase_business_user_pay_status_business_day}')
</parameter>

group by a.date_time
,a.day
