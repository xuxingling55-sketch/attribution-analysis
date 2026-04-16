-- =====================================================
-- 看板名称：202511_线索品198六期
-- 业务域：【平台】_shihua
-- 图表/组件：202511_线索品198六期_整体转化日表_对照组拆分
-- 工具与位置：FineBI（自 `.cursor/code/sql/临时文件` 迁入）
-- 刷新周期：T+1
-- 维护人：meishihua
-- 关联指标：→ glossary/【平台】_shihua.md#
-- 主用表：→ code/sql/表结构/【平台】_shihua/
-- 最后同步自看板日期：20260410
-- ⚠️ 注意：
-- =====================================================

-- 帆软-数据准备-sql 
-- 整体用户的付费（含当日首购/续购拆分，与付费金额可加总对齐）
with r1 as (select 
        ab_name
        ,u_user
        ,grade_stage_name_day
        ,stage_name_day
        ,business_user_pay_status_business_day
        ,business_user_pay_status_statistics_day
        ,grade_name_day
        ,str2date(day,'%Y%m%d') as date
        ,day
    from tmp.lidanping_quanyu_198test_2
    where day between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int) 
        <parameter> 
        and `business_user_pay_status_business_day` in ('${doris_dp_198test2_business_user_pay_status_business_day}')
      </parameter>
      <parameter> 
          and `business_user_pay_status_statistics_day` in ('${doris_dp_198test2_business_user_pay_status_statistics_day}')
          </parameter>
      <parameter> 
      and `grade_name_day` in ('${doris_dp_198test2_grade_name_day}')
        </parameter>
        <parameter> 
      and `stage_name_day` in ('${doris_dp_198test2_stage_name_day}')
        </parameter>
        <parameter> 
      and `grade_stage_name_day` in ('${doris_dp_198test2_grade_stage_name_day}')
        </parameter>
    group by 
        1,2,3,4,5,6,7,8,9
)



,r2 as (
        select
            u_user
            ,str2date(paid_time_sk,'%Y%m%d') as date
            ,good_type
            ,pb_amount
            ,non_pb_amount
            ,zuhe_amount
            ,qita_amount
            ,amount
            ,order_id
            ,rank_total
            ,rank_day
        from 
            (select
                u_user
                ,paid_time_sk
                ,business_gmv_attribution
                ,row_number() over(partition by u_user order by paid_time,order_id,business_gmv_attribution,good_type) as rank_total -- 整体-汇总表、首单-汇总表、首单-日表：周期首单
                ,row_number() over(partition by u_user,paid_time_sk order by paid_time,order_id,business_gmv_attribution,good_type) as rank_day -- 整体-日表：每日首单
                ,good_type
                ,order_id
                ,pb_amount
                ,non_pb_amount
                ,zuhe_amount
                ,qita_amount
                ,amount
            from 
                (select
                    paid_time_sk
                    ,u_user
                    ,order_id
                    ,paid_time
                    ,business_gmv_attribution
                    ,case when business_good_kind_name_level_1 = '组合品' then '组合品'
                        when good_kind_name_level_1='方案型商品' then '其他方案型商品'
                        when good_kind_name_level_2='同步课加培优课' and good_kind_name_level_3='同步课加培优课流量品' then '线索品198'
                        when good_kind_name_level_2='同步课' and good_kind_name_level_3='同步课-3个月' then '3个月同步课198'
                        when good_kind_name_level_2='同步课' and good_kind_name_level_3='同步课-12个月' then '12个月同步课498'
                        else '除以上其他商品'
                        end as good_type
                    ,sum(if(good_kind_name_level_1='方案型商品' ,sub_amount,0)) as pb_amount
                    ,sum(if(good_kind_name_level_1!='方案型商品' ,sub_amount,0)) as non_pb_amount
                    ,sum(if(business_good_kind_name_level_1 = '组合品',sub_amount,0)) as zuhe_amount
                    ,sum(if(business_good_kind_name_level_1 != '组合品',sub_amount,0)) as qita_amount
                    ,sum(sub_amount) as amount
                from dws.topic_order_detail
                where paid_time_sk between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int)
                and original_amount>=39 
                and business_gmv_attribution in ('商业化','电销') -- 用户在C端的首单，而不是用户的首单是在C端,原逻辑
                
                <parameter> 
                    and `business_gmv_attribution` in ('${doris_dp_198test2_business_gmv_attribution}')
                </parameter> 
                
                group by 
                    1,2,3,4,5,6
                ) as a1 
            ) as a2 
             where 1=1
                
               
  ) 




,r3 as (-- 所有商品页面进入-（暂缺失了我的tab-营销页ab测页面数据，埋点还未上线，目前无法区分入口进来后会进入方案型商品页面还是常规商品页面）
    	select
    		u_user
    		,str2date(day,'%Y%m%d') as date
            ,sum(non_pb_cnt) as non_pb_cnt
            ,sum(pb_cnt) as pb_cnt
    	from 
    	(select
			day
			,u_user
            ,count(if(page_name regexp '付费介绍页|_聚合页|期中满分冲刺包急救包|68da3af3ffedc10dd4e0f49f|AI定制结果页面|洋葱私教班｜4周特训',u_user,null)) as non_pb_cnt 
            ,count(if(page_name regexp '暑期大促|组合课包会场|首购会场|多孩续购会场|高中囤课会场|大会员续购会场|加购平板页面',u_user,null)) as pb_cnt 
		from aws.business_user_pay_process_enter_good_page_day
        where day between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int) 
		-- and page_name regexp '付费介绍页|_聚合页|暑期大促|组合课包|期中满分冲刺包急救包|68da3af3ffedc10dd4e0f49f|AI定制结果页面'
		and (!(from_page_name regexp 'purchase') or from_page_name is null or from_page_name='null' or from_page_name='') -- 排除电销推送
		group by 
			day
			,u_user
		union all
				select
			        day 
			        ,u_user --`直播观看人数`
                    ,0 as non_pb_cnt
                    ,1 as pb_cnt
			    from aws.user_live_detail_day
				where day between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int) 
			    and duration>0 
			    group by
			        day
			        ,u_user
		) as a1 
		group by 
			1,2
)




,r4 as (select r1.*,r2.u_user as pay_user,r2.good_type,r2.amount,r2.pb_amount,r2.non_pb_amount,r2.zuhe_amount,r2.qita_amount,r2.order_id,r2.rank_total,r2.date as pay_date,r3.u_user as page_user,r3.non_pb_cnt,r3.pb_cnt
  ,row_number() over(partition by r1.u_user,r1.ab_name,r1.day order by r2.date nulls last,r2.order_id nulls last,r2.rank_day nulls last) as rn2_day  -- 日表：活跃人数适用
  ,row_number() over(partition by r1.u_user,r1.ab_name,r1.day order by r2.date nulls last,r2.order_id nulls last,r2.rank_day nulls last,r1.day,r1.ab_name) as rn1_allpay_day  -- 整体-日表：付费人数适用
  ,row_number() over(partition by r1.u_user,r1.ab_name,r1.day order by r3.date nulls last,r1.day,r1.ab_name) as rn3_day  -- 日表：页面进入人数适用
  
  from r1 
  left join r2 on r1.u_user=r2.u_user and r1.date = r2.date
  left join r3 on r1.u_user=r3.u_user and r1.date = r3.date
)



select
    ab_name as `实验分组`
    ,day as `日期`
    ,case when ab_name='3-对照组' then to_date('2024-01-01')
        when ab_name='4-left组' then to_date('2024-01-01')
        else to_date('2025-01-01')
        end as date_type
    -- ,case when ab_name='3-对照组' then '对照组'
    --     when ab_name='4-left组' then '对照组'
    --     else ab_name
    --     end as `实验名称`
    ,ab_name as `实验名称`
    ,grade_stage_name_day as `年级段`
    ,stage_name_day as `学段`
    ,business_user_pay_status_business_day  as `业务分层`
    ,business_user_pay_status_statistics_day  as `统计分层`
    ,grade_name_day  as `年级`
    ,good_type as `商品分类`
    ,count(distinct if(amount>0,order_id,null)) as `订单量` -- 订单量
    ,sum(amount) as `付费金额`
    ,sum(pb_amount) as `方案型商品付费金额`
    ,sum(non_pb_amount) as `常规商品付费金额`
    
    -- 当日首购/续购拆分（rank_total=1 为周期内用户维度首单；>1 为续单；金额与「付费金额」可加总一致）
    ,count(distinct if(amount>0 and rank_total=1,order_id,null)) as `首购订单量`
    ,count(distinct if(amount>0 and rank_total>1,order_id,null)) as `续购订单量`
    ,sum(if(rank_total=1,amount,0)) as `首购付费金额`
    ,sum(if(rank_total>1,amount,0)) as `续费金额`
    ,sum(if(rank_total=1,zuhe_amount,0)) as `组合品首购金额`
    ,sum(if(rank_total=1,qita_amount,0)) as `非组合首购金额`
    ,sum(if(rank_total>1,zuhe_amount,0)) as `组合品续费金额`
    ,sum(if(rank_total>1,qita_amount,0)) as `非组合续费金额`
    
    ,count(distinct if(amount>0 and rank_total=1,pay_user,null)) as `首购付费人数` -- 当日至少一笔首单的去重用户（可与续购人数重叠）
    ,count(distinct if(zuhe_amount>0 and rank_total=1,pay_user,null)) as `组合品首购人数` -- 当日至少一笔首单的去重用户（可与续购人数重叠）
    ,count(distinct if(qita_amount>0 and rank_total=1,pay_user,null)) as `非组合品首购人数` -- 当日至少一笔首单的去重用户（可与续购人数重叠）
    ,count(distinct if(amount>0 and rank_total>1,pay_user,null)) as `续费人数` -- 当日至少一笔续单的去重用户（可与首购人数重叠）
    ,count(distinct if(zuhe_amount>0 and rank_total>1,pay_user,null)) as `组合品续费人数` -- 当日至少一笔续单的去重用户（可与首购人数重叠）
    ,count(distinct if(qita_amount>0 and rank_total>1,pay_user,null)) as `非组合品续费人数` -- 当日至少一笔续单的去重用户（可与首购人数重叠）
    
    -- 1.通用-日表
    ,count(distinct case when rn2_day = 1 then u_user end) as `分组活跃人数` -- 日表：去重活跃人数
    ,count(distinct case when rn3_day = 1 then page_user end) as `商品页面进入人数` -- 日表：去重商品页面进入人数
    ,count(distinct case when rn3_day = 1 and non_pb_cnt>0 then page_user end) as `常规商品页面进入人数` -- 日表：去重常规商品页面进入人数
    ,count(distinct case when rn3_day = 1 and pb_cnt>0 then page_user end) as `方案型商品页面进入人数` -- 日表：去重方案型商品页面进入人数
    
    -- # 整体-日表
    ,count(distinct case when rn1_allpay_day = 1 and amount>0 then pay_user end) as `付费人数` -- 整体-日表：去重付费人数
    ,count(distinct case when rn1_allpay_day = 1 and pb_amount>0 then pay_user end) as `方案型商品付费人数` -- 整体-日表：方案型商品付费人数
    ,count(distinct case when rn1_allpay_day = 1 and non_pb_amount>0 then pay_user end) as `常规商品付费人数` -- 整体-日表：常规商品付费人数
    
    
    
from r4 
group by 
    1,2,3,4,5,6,7,8,9,10

