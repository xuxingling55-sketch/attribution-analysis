select cast(day as date) day,order_flag
,case 
      when length(practice_type_arr)=0 then ''
      when practice_type_arr='教材同步' then '教材同步'
      when practice_type_arr='题库场景（日常练习）' then '题库场景（日常练习）'
      when practice_type_arr='作业场景（作业速攻）' then '作业场景（作业速攻）'
      when practice_type_arr='备考场景（精准复习）' then '备考场景（精准复习）'
      when practice_type_arr='总复习场景' then '总复习场景'
      when practice_type_arr='试炼场' then '试炼场'
      when practice_type_arr='注册30天内用户-观看视频' then '注册30天内用户-观看3个学习视频'
      when practice_type_arr='注册30天内用户-新手场景' then '注册30天内用户-新手场景观看1个洋葱TV'
      when practice_type_arr='注册30天内用户-成长场景' then '注册30天内用户-成长场景进入次元书桌'
      when practice_type_arr='研究-我的书房' then '研究-我的书房'
      when practice_type_arr='研究-课外探索' then '研究-课外探索'
      when practice_type_arr='客服咨询' then '客服咨询'
      when practice_type_arr='研究-教学区' then '研究-教学区-顶部搜索框'
      else '触发多个场景' end practice_type_arr
,active_user_attribution
,user_pay_status_business,business_user_pay_status_business
,mid_stage_name,grade,gender,channel,u_from,regist_os
,city_class,province,city,real_identity
,count(distinct active_u_user) active_cnt
,count(distinct case when push_u_user is not null then active_u_user end) push_cnt
,count(distinct case when enter_datapool_u_user is not null then active_u_user end) datapool_cnt
,count(distinct case when recieve_u_user is not null then active_u_user end) recieve_cnt
,count(distinct case when recieve_u_user_all is not null then active_u_user end) recieve_all_cnt
from aws.crm_active_data_pool_day 
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
