-- =====================================================
-- 大盘营收- 大盘营收日月报-月维度 tmp.lidanping_channel_amount_fuwuqi_month1
-- =====================================================
--
-- 【表粒度】
--   见建表sql，分区字段：year_month
--
-- 【业务定位】
--   - 【归属】大盘营收 / 大盘营收日月报-月维度。
--   - 帆软看板「大盘营收日月报-月维度」的底层表
--
-- 【数据来源】
--   - 见建表sql
--
-- 【常用关联】
--   - maindata2：channel 维 b1 LEFT JOIN status r5、LEFT JOIN dw.dim_date 派生 r1；LEFT JOIN GMV 子查询 r2 ON b1.channel = r2.business_gmv_attribution AND r1.day = r2.paid_time_sk AND r2.status = r5.status
--   - maindata2：LEFT JOIN 服务期 r3 ON b1.channel = r3.channel AND r1.day = r3.paid_time_sk AND r3.status = r5.status；LEFT JOIN sellfrom r4 ON b1.channel = r4.sellfrom AND r1.day = r4.paid_time_sk AND r4.status = r5.status
--   - 最外层：maindata2 a1 LEFT JOIN maindata2 a2 ON a1.year_month-100 = a2.year_month AND a1.month_day = a2.month_day AND a1.channel = a2.channel AND a1.status = a2.status（同比）
--
-- 【常用筛选条件】
--   - 分区 year_month
--
-- 【注意事项】
--   - insert overwrite table … partition(year_month)；同比按 year_month-100 对齐去年同月
--
-- =====================================================

insert overwrite table tmp.lidanping_channel_amount_fuwuqi_month1 partition(year_month)

with maindata2 as 
(
	select
	to_date(from_unixtime(unix_timestamp(string(r1.day),'yyyyMMdd'),'yyyy-MM-dd')) as date_time
	,year_month
	,month_day
	,year
	,month_begin_timestamp -- 月初日期
	,r1.day
	,b1.channel
	,r5.status as status
	,nvl(r2.amount,0) as GMVamount
	,nvl(r4.amount,0) as sellfromamount
	,nvl(r3.amount,0) as fuwuqi
	,nvl(r3.amount_multi,0) as multifuwuqi
	,nvl(r3.amount_unit,0) as unitfuwuqi
	
	,nvl(r2.pb_amount,0) as GMV_pb_amount
	,nvl(r2.nonpb_amount,0) as GMV_nonpb_amount
	
	,nvl(r4.pb_amount,0) as sellfrom_pb_amount
	,nvl(r4.nonpb_amount,0) as sellfrom_nonpb_amount
	
	,nvl(r3.pb_amount,0) as fuwuqi_pb_amount
	,nvl(r3.nonpb_amount,0) as fuwuqi_nonpb_amount


from 
	(
		select '阿拉丁' as channel
			union all 
			select '体验营' as channel
			union all 
			select '奥德赛' as channel
			union all 
			select '商业化-公域' as channel
			union all 
			select '新媒体视频' as channel
			union all 
			select '商业化-APP' as channel
			union all 
			select '入校' as channel
			union all 
			select '电销/网销' as channel
			union all 
			select '研学' as channel
			union all
			select 'C端整体' as channel
	) as b1
left join(
			select '支付成功' as status
			union all 
			select '退款成功' as status
		) as r5
left join
	(
		select 
	        distinct date_sk as day,
	        day_timestamp,
	        year_month,
	        year,
	        right(day,4)as month_day
	        ,month_begin_timestamp
	    from dw.dim_date 
	    where date_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','') and regexp_replace(date_add(current_date(),-1),'-','')
	    	or date_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','')-10000 and regexp_replace(date_add(current_date(),-1),'-','')-10000  
	) as r1
left join 
	(	select
		case when business_gmv_attribution='体验营' then '体验营'
			when business_gmv_attribution='奥德赛' then '奥德赛'
			when business_gmv_attribution='商业化-电商' then '商业化-公域'
			when business_gmv_attribution='新媒体视频' then '新媒体视频'
			when business_gmv_attribution='商业化' then '商业化-APP'
			when business_gmv_attribution='入校' then '入校'
			when business_gmv_attribution='电销' then '电销/网销'
			when business_gmv_attribution='新媒体变现' then '研学' 
			else  business_gmv_attribution
			end as business_gmv_attribution
			,paid_time_sk
			,status
			,sum(sub_amount) as amount
			,sum(if(good_kind_id_level_1='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as pb_amount -- 方案型商品ID 
			,sum(if(good_kind_id_level_1!='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as nonpb_amount
		from dws.topic_order_detail 
		where paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','') and regexp_replace(date_add(current_date(),-1),'-','')
			or paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','')-10000 and regexp_replace(date_add(current_date(),-1),'-','')-10000
		group by 
			case when business_gmv_attribution='体验营' then '体验营'
			when business_gmv_attribution='奥德赛' then '奥德赛'
			when business_gmv_attribution='商业化-电商' then '商业化-公域'
			when business_gmv_attribution='新媒体视频' then '新媒体视频'
			when business_gmv_attribution='商业化' then '商业化-APP'
			when business_gmv_attribution='入校' then '入校'
			when business_gmv_attribution='电销' then '电销/网销'
			when business_gmv_attribution='新媒体变现' then '研学' 
			else  business_gmv_attribution
			end,
			paid_time_sk,
			status

			union all 
			select
				'C端整体' as business_gmv_attribution
				,paid_time_sk
				,status
				,sum(sub_amount) as amount
				,sum(if(good_kind_id_level_1='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as pb_amount -- 方案型商品ID 
				,sum(if(good_kind_id_level_1!='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as nonpb_amount
			from dws.topic_order_detail 
			where (paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','') and regexp_replace(date_add(current_date(),-1),'-','')
				or paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','')-10000 and regexp_replace(date_add(current_date(),-1),'-','')-10000)
			and business_gmv_attribution in ('商业化','电销')
			group by 
				'C端整体',
				paid_time_sk,
				status

	) as r2  on b1.channel = r2.business_gmv_attribution and r1.day = r2.paid_time_sk and r2.status = r5.status
left join 
	(-- 服务期口径
		select
		channel
		,paid_time_sk
		,status
		,sum(if(channel_cnt > 1, amount, 0)) as amount_multi
		,sum(if(channel_cnt = 1, amount, 0)) as amount_unit -- 仅1个渠道
		,sum(amount) as amount
		,sum(pb_amount) as pb_amount
		,sum(nonpb_amount) as nonpb_amount
	from 
		(
			select
				a.channel as channel
				,array_size(team_names) as channel_cnt
				,paid_time_sk
				,status
				,sum(sub_amount) as amount
				,sum(if(good_kind_id_level_1='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as pb_amount -- 方案型商品ID 
				,sum(if(good_kind_id_level_1!='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as nonpb_amount
			from dws.topic_order_detail lateral view outer explode (team_names) a as channel
			where paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','') and regexp_replace(date_add(current_date(),-1),'-','')
			or paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','')-10000 and regexp_replace(date_add(current_date(),-1),'-','')-10000
			group by 
				a.channel,
				array_size(team_names),
				paid_time_sk,
				status
		) as a1 
	group by  
		channel,
		paid_time_sk,
		status

		union all

			select
				'C端整体' as channel
				,paid_time_sk
				,status
				,sum(sub_amount) as amount_multi -- c端是2个渠道加总
				,0 as amount_unit -- 仅1个渠道
				,sum(sub_amount) as amount
				,sum(if(good_kind_id_level_1='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as pb_amount -- 方案型商品ID 
				,sum(if(good_kind_id_level_1!='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as nonpb_amount
			from dws.topic_order_detail 
			where (paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','') and regexp_replace(date_add(current_date(),-1),'-','')
			or paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','')-10000 and regexp_replace(date_add(current_date(),-1),'-','')-10000)
			and string(team_names) regexp '电销|商业化-APP'
			group by 
				'C端整体',
				paid_time_sk,
				status
				

	) as r3  on b1.channel = r3.channel and r1.day = r3.paid_time_sk and r3.status = r5.status
left join 
	(-- sellfrom 口径
		select
			case when sell_from regexp 'telesale' then '电销/网销'
				when sell_from regexp 'tiyanying' then '体验营'
				when sell_from regexp 'ruxiao' then '入校'
				when sell_from regexp 'aodesai' then '奥德赛'
				when sell_from regexp 'xinmeitishipin' or sell_from regexp 'xinmeiti_doudian' or sell_from regexp 'xinmeiti_shipin' or sell_from regexp 'xinmeiti_xiaohongshu' then '新媒体视频'
				when sell_from = 'xinmeiti' or sell_from regexp 'xinmeitibianxian' or sell_from regexp 'yanxue' or sell_from regexp 'xinmeiti_weidian' or sell_from regexp 'xinmeiti_bianxian' or sell_from regexp 'Xinmeitigongzhonghao' then '研学'
				when sell_from regexp 'shangyehua'  then '商业化-公域'
				when sell_from regexp 'app' then '商业化-APP'
				else '商业化-APP'
				end as sellfrom
			,paid_time_sk
			,status
			,sum(sub_amount) as amount
			,sum(if(good_kind_id_level_1='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as pb_amount -- 方案型商品ID 
			,sum(if(good_kind_id_level_1!='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as nonpb_amount
		from dws.topic_order_detail
		where paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','') and regexp_replace(date_add(current_date(),-1),'-','')
			or paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','')-10000 and regexp_replace(date_add(current_date(),-1),'-','')-10000
		group by 
			case when sell_from regexp 'telesale' then '电销/网销'
				when sell_from regexp 'tiyanying' then '体验营'
				when sell_from regexp 'ruxiao' then '入校'
				when sell_from regexp 'aodesai' then '奥德赛'
				when sell_from regexp 'xinmeitishipin' or sell_from regexp 'xinmeiti_doudian' or sell_from regexp 'xinmeiti_shipin' or sell_from regexp 'xinmeiti_xiaohongshu' then '新媒体视频'
				when sell_from = 'xinmeiti' or sell_from regexp 'xinmeitibianxian' or sell_from regexp 'yanxue' or sell_from regexp 'xinmeiti_weidian' or sell_from regexp 'xinmeiti_bianxian' or sell_from regexp 'Xinmeitigongzhonghao' then '研学'
				when sell_from regexp 'shangyehua'  then '商业化-公域'
				when sell_from regexp 'app' then '商业化-APP'
				else '商业化-APP'
				end,
			paid_time_sk,
			status

			union all
				select
				 'C端整体' as sellfrom
				,paid_time_sk
				,status
				,sum(sub_amount) as amount
				,sum(if(good_kind_id_level_1='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as pb_amount -- 方案型商品ID 
				,sum(if(good_kind_id_level_1!='f76be748-e94c-453d-a3d7-9800113bcb7b',sub_amount,0)) as nonpb_amount
			from dws.topic_order_detail
			where (paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','') and regexp_replace(date_add(current_date(),-1),'-','')
			or paid_time_sk between regexp_replace(trunc(add_months(current_date(),-1),'MM'),'-','')-10000 and regexp_replace(date_add(current_date(),-1),'-','')-10000)
			and  (case when sell_from regexp 'telesale' then '电销/网销'
					when sell_from regexp 'tiyanying' then '体验营'
					when sell_from regexp 'ruxiao' then '入校'
					when sell_from regexp 'aodesai' then '奥德赛'
					when sell_from regexp 'xinmeitishipin' or sell_from regexp 'xinmeiti_doudian' or sell_from regexp 'xinmeiti_shipin' or sell_from regexp 'xinmeiti_xiaohongshu' then '新媒体视频'
					when sell_from = 'xinmeiti' or sell_from regexp 'xinmeitibianxian' or sell_from regexp 'yanxue' or sell_from regexp 'xinmeiti_weidian' or sell_from regexp 'xinmeiti_bianxian' or sell_from regexp 'Xinmeitigongzhonghao' then '研学'
					when sell_from regexp 'shangyehua' then '商业化-公域'
					when sell_from regexp 'app' then '商业化-APP'
					else '商业化-APP'
					end) in ('电销/网销','商业化-APP')
			group by 
				 'C端整体',
				paid_time_sk,
				status
				
	) as r4 on b1.channel = r4.sellfrom and r1.day = r4.paid_time_sk and r4.status = r5.status
) 


select 
	a1.year
	,right(a1.year_month,2)as month
	,a1.month_begin_timestamp
	,a1.channel
	,a1.status
	
	,sum(a1.GMVamount) as GMVamount
	,sum(a1.sellfromamount) as sellfromamount
	,sum(a1.fuwuqi) as fuwuqi
	,sum(a1.multifuwuqi) as multifuwuqi
	,sum(a1.unitfuwuqi) as unitfuwuqi
	,sum(a1.GMV_pb_amount) as GMV_pb_amount
	,sum(a1.GMV_nonpb_amount) as GMV_nonpb_amount
	,sum(a1.sellfrom_pb_amount) as sellfrom_pb_amount
	,sum(a1.sellfrom_nonpb_amount) as sellfrom_nonpb_amount
	,sum(a1.fuwuqi_pb_amount) as fuwuqi_pb_amount
	,sum(a1.fuwuqi_nonpb_amount) as fuwuqi_nonpb_amount

	,sum(a2.GMVamount) as yoy_GMVamount
	,sum(a2.sellfromamount) as yoy_sellfromamount
	,sum(a2.fuwuqi) as yoy_fuwuqi
	,sum(a2.multifuwuqi) as yoy_multifuwuqi
	,sum(a2.unitfuwuqi) as yoy_unitfuwuqi
	,sum(a2.GMV_pb_amount) as yoy_GMV_pb_amount
	,sum(a2.GMV_nonpb_amount) as yoy_GMV_nonpb_amount
	,sum(a2.sellfrom_pb_amount) as yoy_sellfrom_pb_amount
	,sum(a2.sellfrom_nonpb_amount) as yoy_sellfrom_nonpb_amount
	,sum(a2.fuwuqi_pb_amount) as yoy_fuwuqi_pb_amount
	,sum(a2.fuwuqi_nonpb_amount) as yoy_fuwuqi_nonpb_amount

	,a1.year_month

from maindata2 as a1 
	left join maindata2 as a2 
	on a1.year_month-100=a2.year_month and a1.month_day=a2.month_day and a1.channel=a2.channel and a1.status=a2.status
	where a1.day between 20200101 and regexp_replace(date_add(current_date(),-1),'-','')
	and a2.day between 20200101 and regexp_replace(date_add(current_date(),-1),'-','')-10000--截至去年今日
group by 
	a1.year
	,right(a1.year_month,2)
	,a1.year_month
	,a1.month_begin_timestamp
	,a1.channel
	,a1.status
	
;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## channel（业务渠道维度）
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
-- | C端整体 | C 端聚合口径 |
--
-- ## status（订单状态）
--
-- | 取值 | 含义 |
-- |------|------|
-- | 支付成功 | 支付成功 |
-- | 退款成功 | 退款成功 |
--
-- ## year_month（分区）
--
-- > 形如 yyyymm，与 dw.dim_date.year_month 一致；同比 join 使用 year_month - 100 对齐去年同月。
