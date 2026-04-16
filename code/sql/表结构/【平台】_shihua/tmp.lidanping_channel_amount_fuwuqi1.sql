-- =====================================================
-- 大盘营收- 大盘营收日月报-日维度 tmp.lidanping_channel_amount_fuwuqi1
-- =====================================================
--
-- 【表粒度】
--   见建表sql，分区字段：day
--
-- 【业务定位】
--   - 【归属】大盘营收 / 大盘营收日月报-日维度。
--   - 帆软看板「大盘营收日月报-日维度」的底层表
--
-- 【数据来源】
--   - 见建表sql
--
-- 【常用关联】
--   - tags：channel_base CROSS JOIN status_base；JOIN date_range c ON 1=1
--   - maindata1：tags a LEFT JOIN gmv_data b ON a.day = b.paid_time_sk AND a.channel = b.business_gmv_attribution_channel AND a.status = b.status
--   - maindata1：LEFT JOIN sellfrom_data c ON a.day = c.paid_time_sk AND a.channel = c.sell_from_channel AND a.status = c.status
--   - maindata1：LEFT JOIN fuwuqi_data d ON a.day = d.paid_time_sk AND a.channel = d.channel AND a.status = d.status
--   - final_data：今年 a1 LEFT JOIN 去年 a2 ON a1.year = a2.year+1 AND a1.month_day = a2.month_day AND a1.channel = a2.channel AND a1.status = a2.status
--
-- 【常用筛选条件】
--   - 分区 day
--
-- 【注意事项】
--   - insert overwrite table … partition(day)；日期窗口为「近 31 日」及去年同期（-10000 sk）对齐同比
--
-- =====================================================

insert overwrite tmp.lidanping_channel_amount_fuwuqi1 partition(day)

with order_info as (
    SELECT
      paid_time_sk,
      status,
      good_kind_id_level_1,
      team_names,
      -- 统一业务渠道映射逻辑
      CASE 
        WHEN business_gmv_attribution = '体验营' THEN '体验营'
        WHEN business_gmv_attribution = '奥德赛' THEN '奥德赛'
        WHEN business_gmv_attribution = '商业化-电商' THEN '商业化-公域'
        WHEN business_gmv_attribution = '商业化' THEN '商业化-APP'
        WHEN business_gmv_attribution = '入校' THEN '入校'
        WHEN business_gmv_attribution = '电销' THEN '电销/网销'
        WHEN business_gmv_attribution = '新媒体变现' THEN '研学' 
        ELSE business_gmv_attribution
      END AS business_gmv_attribution_channel,
      -- 统一sellfrom映射逻辑（正则优化）
      CASE 
        WHEN sell_from LIKE '%telesale%' THEN '电销/网销'
        WHEN sell_from LIKE '%tiyanying%' THEN '体验营'
        WHEN sell_from LIKE '%ruxiao%' THEN '入校'
        WHEN sell_from LIKE '%aodesai%' THEN '奥德赛'
        WHEN sell_from REGEXP 'xinmeitishipin|xinmeiti_doudian|xinmeiti_shipin|xinmeiti_xiaohongshu' THEN '新媒体视频'
        WHEN sell_from = 'xinmeiti' OR sell_from REGEXP 'xinmeitibianxian|yanxue|xinmeiti_weidian|xinmeiti_bianxian|Xinmeitigongzhonghao' THEN '研学'
        WHEN sell_from LIKE '%shangyehua%' THEN '商业化-公域'
        WHEN sell_from LIKE '%app%' THEN '商业化-APP'
        ELSE '商业化-APP'
      END AS sell_from_channel,
      SUM(sub_amount) AS amount,
      SUM(CASE WHEN good_kind_id_level_1 = 'f76be748-e94c-453d-a3d7-9800113bcb7b' THEN sub_amount ELSE 0 END) AS pb_amount,
      SUM(CASE WHEN good_kind_id_level_1 != 'f76be748-e94c-453d-a3d7-9800113bcb7b' THEN sub_amount ELSE 0 END) AS nonpb_amount
    FROM dws.topic_order_detail
    WHERE paid_time_sk BETWEEN DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 31), '%Y%m%d') 
                           AND DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), '%Y%m%d')
       OR paid_time_sk BETWEEN DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 31), '%Y%m%d') - 10000 
                           AND DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), '%Y%m%d') - 10000
    GROUP BY 1,2,3,4,5,6
)




,gmv_data as (
    SELECT
      paid_time_sk,
      status,
      business_gmv_attribution_channel,
      SUM(amount) AS amount,
      SUM(pb_amount) AS pb_amount,
      SUM(nonpb_amount) AS nonpb_amount
    FROM order_info
    
    GROUP BY 1,2,3
    
    union all
    
    SELECT
      paid_time_sk,
      status,
      'C端整体' AS business_gmv_attribution_channel,
      SUM(amount) AS amount,
      SUM(pb_amount) AS pb_amount,
      SUM(nonpb_amount) AS nonpb_amount
    FROM order_info
    WHERE business_gmv_attribution_channel in ('电销/网销','商业化-APP')
      
    GROUP BY 1,2,3
) 



,sellfrom_data as (
    SELECT
      paid_time_sk,
      status,
      sell_from_channel,
      SUM(amount) AS amount,
      SUM(pb_amount) AS pb_amount,
      SUM(nonpb_amount) AS nonpb_amount
    FROM order_info
    
    GROUP BY 1,2,3
    
    union all
    
    SELECT
      paid_time_sk,
      status,
      'C端整体' AS sell_from_channel,
      SUM(amount) AS amount,
      SUM(pb_amount) AS pb_amount,
      SUM(nonpb_amount) AS nonpb_amount
    FROM order_info
    WHERE sell_from_channel in ('电销/网销','商业化-APP')
      
    GROUP BY 1,2,3
) 



,fuwuqi_data AS (
  SELECT 
    channel,
    paid_time_sk,
    status,
    SUM(CASE WHEN channel_cnt > 1 THEN amount ELSE 0 END) AS amount_multi,
    SUM(CASE WHEN channel_cnt = 1 THEN amount ELSE 0 END) AS amount_unit,
    SUM(amount) AS amount,
    SUM(pb_amount) AS pb_amount,
    SUM(nonpb_amount) AS nonpb_amount
  FROM (
    -- 使用UNNEST展开数组
    SELECT
      unnest_channel AS channel,
      CARDINALITY(team_names) AS channel_cnt,
      paid_time_sk,
      status,
      SUM(amount) AS amount,
      SUM(pb_amount) AS pb_amount,
      SUM(nonpb_amount) AS nonpb_amount
    FROM order_info, UNNEST(team_names) AS t(unnest_channel)
    GROUP BY unnest_channel, CARDINALITY(team_names), paid_time_sk, status
  ) as a1
  GROUP BY channel, paid_time_sk, status
    
  UNION ALL
  
  -- C端整体服务期数据（优化数组判断逻辑）
  select
  		'C端整体' as channel,
  		paid_time_sk,
  		status,
  		sum(amount) as amount_multi, -- c端是2个渠道加总
  		0 as amount_unit, -- 仅1个渠道
  		SUM(amount) AS amount,
      SUM(pb_amount) AS pb_amount,
      SUM(nonpb_amount) AS nonpb_amount
  FROM order_info
  WHERE team_names IS NOT NULL 
    AND (
    -- ARRAY_CONTAINS(team_names, '电销') OR ARRAY_CONTAINS(team_names, '商业化-APP')
    ARRAY_JOIN(team_names,',') regexp '电销|商业化-APP'
    ) 
  GROUP BY paid_time_sk, status
)


,date_range AS (
  SELECT 
    DISTINCT date_sk AS day,
    day_timestamp,
    year_month,
    year,
    RIGHT(CAST(date_sk AS STRING), 4) AS month_day,
    month_begin_timestamp
  FROM dw.dim_date 
  WHERE date_sk BETWEEN DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 31), '%Y%m%d') 
                   AND DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), '%Y%m%d')
     OR date_sk BETWEEN DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 31), '%Y%m%d') - 10000 
                   AND DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), '%Y%m%d') - 10000 
)


,channel_base AS (
  SELECT '阿拉丁' AS channel UNION ALL 
  SELECT '体验营' UNION ALL SELECT '奥德赛' UNION ALL 
  SELECT '商业化-公域' UNION ALL SELECT '新媒体视频' UNION ALL 
  SELECT '商业化-APP' UNION ALL SELECT '入校' UNION ALL 
  SELECT '电销/网销' UNION ALL SELECT '研学' UNION ALL 
  SELECT 'C端整体'
)


,status_base AS (
  SELECT '支付成功' AS status UNION ALL 
  SELECT '退款成功'
)


,tags AS (
SELECT a.channel,b.status,c.day,c.day_timestamp,c.year_month,c.year,c.month_day,c.month_begin_timestamp
FROM channel_base a
  CROSS JOIN status_base b
  JOIN date_range c ON 1=1
)



,maindata1 AS (select 
	STR_TO_DATE(CAST(a.day AS STRING), '%Y%m%d') as date_time
	,a.day
	,a.year_month
	,a.month_day
	,a.year
	,a.month_begin_timestamp -- 月初日期
	,a.channel
	,a.status as status
	,ifnull(b.amount,0) as GMVamount
	,ifnull(c.amount,0) as sellfromamount
	,ifnull(d.amount,0) as fuwuqi
	,ifnull(d.amount_multi,0) as multifuwuqi
	,ifnull(d.amount_unit,0) as unitfuwuqi
	
	,ifnull(b.pb_amount,0) as GMV_pb_amount
	,ifnull(b.nonpb_amount,0) as GMV_nonpb_amount
	
	,ifnull(c.pb_amount,0) as sellfrom_pb_amount
	,ifnull(c.nonpb_amount,0) as sellfrom_nonpb_amount
	
	,ifnull(d.pb_amount,0) as fuwuqi_pb_amount
	,ifnull(d.nonpb_amount,0) as fuwuqi_nonpb_amount
  from tags a 
  left join gmv_data b on a.day = b.paid_time_sk and a.channel = b.business_gmv_attribution_channel and a.status = b.status
  left join sellfrom_data c on a.day = c.paid_time_sk and a.channel = c.sell_from_channel and a.status = c.status
  left join fuwuqi_data d on a.day = d.paid_time_sk and a.channel = d.channel and a.status = d.status
)
  


,final_data as (select 
	a1.year
	,right(a1.year_month,2)as month
	,a1.year_month
	,a1.month_day
	,a1.month_begin_timestamp
	,a1.channel
	,a1.status
	,a1.GMVamount
	,a1.sellfromamount
	,a1.fuwuqi
	,a1.multifuwuqi
	,a1.unitfuwuqi
	,a1.GMV_pb_amount
	,a1.GMV_nonpb_amount
	,a1.sellfrom_pb_amount
	,a1.sellfrom_nonpb_amount
	,a1.fuwuqi_pb_amount
	,a1.fuwuqi_nonpb_amount

	,a2.GMVamount as yoy_GMVamount
	,a2.sellfromamount as yoy_sellfromamount
	,a2.fuwuqi as yoy_fuwuqi
	,a2.multifuwuqi as yoy_multifuwuqi
	,a2.unitfuwuqi as yoy_unitfuwuqi
	,a2.GMV_pb_amount as yoy_GMV_pb_amount
	,a2.GMV_nonpb_amount as yoy_GMV_nonpb_amount
	,a2.sellfrom_pb_amount as yoy_sellfrom_pb_amount
	,a2.sellfrom_nonpb_amount as yoy_sellfrom_nonpb_amount
	,a2.fuwuqi_pb_amount as yoy_fuwuqi_pb_amount
	,a2.fuwuqi_nonpb_amount as yoy_fuwuqi_nonpb_amount

	,to_date(a1.date_time)as day

from (select * from maindata1 where day BETWEEN DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 31), '%Y%m%d') AND DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), '%Y%m%d') ) as a1 
left join (select * from maindata1 where day BETWEEN DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 31), '%Y%m%d') - 10000 AND DATE_FORMAT(DATE_SUB(CURRENT_DATE(), 1), '%Y%m%d') - 10000 ) as a2 
on a1.year=a2.year+1 and a1.month_day=a2.month_day and a1.channel=a2.channel and a1.status=a2.status
)

select * from final_data ;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## channel（业务渠道维度，与 channel_base 一致）
--
-- | 取值 | 含义 |
-- |------|------|
-- | 阿拉丁 | 阿拉丁 |
-- | 体验营 | 体验营 |
-- | 奥德赛 | 奥德赛 |
-- | 商业化-公域 | 商业化-公域 |
-- | 新媒体视频 | 新媒体视频 |
-- | 商业化-APP | 商业化-APP |
-- | 入校 | 入校 |
-- | 电销/网销 | 电销/网销 |
-- | 研学 | 研学 |
-- | C端整体 | C端整体（电销/网销 + 商业化-APP 聚合） |
--
-- ## status（订单状态）
--
-- | 取值 | 含义 |
-- |------|------|
-- | 支付成功 | 支付成功 |
-- | 退款成功 | 退款成功 |
