# 推荐有礼活动页曝光引流效率

sql01 = '''
with t1 as (
select  
  day
  ,case  when from_channel = 'exclusive_posters' or c_from = 'exclusive_posters' then '专属海报'
         when from_channel = 'exclusive_link_card' or c_from = 'exclusive_link_card' then '专属链接卡片'
         when from_channel = 'telesale_mp' then '洋葱学园+小程序'
         when from_channel = 'server_number' then '电销服务号'
         when from_channel = 'parent' then '家长端小程序'
         when from_channel ='' and c_from = 'other' then '渠道活码跳转'
    else '其他'
  end from_channel
  ,count(user_id) exposure_times --曝光次数
  ,count(distinct user_id) exposure_cnt --曝光人数
from events.frontend_event_orc
where day between  CAST(REGEXP_REPLACE(DATE_SUB(CURRENT_DATE(), 15), '-', '') AS INT) and CAST(REGEXP_REPLACE(DATE_SUB(CURRENT_DATE(), 1), '-', '') AS INT)
and event_type = 'get' AND event_key in ('getRecommendGiftsPageButton','getDownloadExclusivePostersButton')
group by 1,2 
)

, t2 as (
select 
  day
  ,case  when from_channel = 'exclusive_posters' or c_from = 'exclusive_posters' then '专属海报'
        when from_channel = 'exclusive_link_card' or c_from = 'exclusive_link_card' then '专属链接卡片'
        when from_channel = 'telesale_mp' then '洋葱学园+小程序'
        when from_channel = 'server_number' then '电销服务号'
        when from_channel = 'parent' then '家长端小程序'
        when from_channel ='' and c_from = 'other' then '渠道活码跳转'
    else '其他'
  end from_channel
  ,count(user_id) click_times --点击次数
  ,count(distinct user_id) click_cnt --点击人数
FROM events.frontend_event_orc
WHERE day between  CAST(REGEXP_REPLACE(DATE_SUB(CURRENT_DATE(), 15), '-', '') AS INT) and CAST(REGEXP_REPLACE(DATE_SUB(CURRENT_DATE(), 1), '-', '') AS INT)
AND event_type = 'click' AND event_key in ( 'clickDownloadExclusivePostersButton','clickRecommendGiftsPageButton')
group by 1,2
)

, t3 as (
select * from (
select distinct 
  day
  ,u_user
  ,case  when from_channel = 'exclusive_posters' or c_from = 'exclusive_posters' then '专属海报'
        when from_channel = 'exclusive_link_card' or c_from = 'exclusive_link_card' then '专属链接卡片'
        when from_channel = 'telesale_mp' then '洋葱学园+小程序'
        when from_channel = 'server_number' then '电销服务号'
        when from_channel = 'parent' then '家长端小程序'
        when from_channel ='' and c_from = 'other' then '渠道活码跳转'
    else '其他' end from_channel
  ,row_number()over (partition by u_user,day order by event_time ) rk
FROM events.frontend_event_orc
WHERE day between  CAST(REGEXP_REPLACE(DATE_SUB(CURRENT_DATE(), 15), '-', '') AS INT) and CAST(REGEXP_REPLACE(DATE_SUB(CURRENT_DATE(), 1), '-', '') AS INT)
and authorization_status = 1 
AND event_type in ('click' ,'get')
AND event_key in ( 'clickDownloadExclusivePostersButton','clickRecommendGiftsPageButton','getRecommendGiftsPageButton','getDownloadExclusivePostersButton')
and (from_channel in ('exclusive_posters', 'exclusive_link_card' ,'telesale_mp','server_number','parent') 
or  c_from in ('exclusive_posters', 'exclusive_link_card')
)
)
where rk = 1
)


, t4 as (
select 
  CAST(REGEXP_REPLACE(substr(created_at,1,10), '-', '') AS INT) day
  ,user_id
  ,ifnull(count(user_id),0) ruku_cnt
  ,ifnull(count(case when paid_cnt_14d>0 then user_id end),0) paid_cnt_14d
  ,ifnull(sum(paid_amount_14d),0) paid_amount_14d
  ,ifnull(count(case when (unix_timestamp(substr(created_at,1,19))-unix_timestamp(substr(regist_time,1,19)))/3600<=24 then user_id end),0) new_ruku_cnt 
  ,ifnull(count(case when (unix_timestamp(substr(created_at,1,19))-unix_timestamp(substr(regist_time,1,19)))/3600<=24 and paid_cnt_14d>0 then user_id end),0) new_paid_cnt_14d
  ,ifnull(sum(case when (unix_timestamp(substr(created_at,1,19))-unix_timestamp(substr(regist_time,1,19)))/3600<=24 then paid_amount_14d end),0) new_paid_amount_14d
from aws.clue_info 
  where clue_source in ('telesale_mp','server_number','parent','referral')
    and substr(created_at,1,10)>=DATE_SUB(CURRENT_DATE(), 15)
  group by 1,2
)

, t5 as (
select 
 t3.day
 ,t3.from_channel
 ,count(distinct t3.u_user) auth_cnt
 ,sum(ruku_cnt)ruku_cnt
 ,sum(paid_cnt_14d)paid_cnt_14d
 ,sum(paid_amount_14d)paid_amount_14d
 ,sum(new_ruku_cnt)new_ruku_cnt
 ,sum(new_paid_cnt_14d)new_paid_cnt_14d
 ,sum(new_paid_amount_14d)new_paid_amount_14d
from t3 
left join t4 on t3.day = t4.day and t3.u_user = t4.user_id
group by 1,2
)


, ty1 as (
select
t1.day
,t1.from_channel
,t1.exposure_times
,t1.exposure_cnt
,t2.click_times
,t2.click_cnt
,auth_cnt
,ruku_cnt
,paid_cnt_14d
,paid_amount_14d
,new_ruku_cnt
,new_paid_cnt_14d
,new_paid_amount_14d
,t1.day as dt
from t1
left join t2 on t1.day = t2.day and t1.from_channel=t2.from_channel
left join t5 on t1.day = t5.day and t1.from_channel=t5.from_channel
)

insert overwrite table tmp.niyiqiao_invite_friends_earn_points_active  partition(dt)
select * from ty1; 
