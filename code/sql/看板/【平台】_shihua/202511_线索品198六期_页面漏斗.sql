-- =====================================================
-- 看板名称：202511_线索品198六期
-- 业务域：【平台】_shihua
-- 图表/组件：202511_线索品198六期_页面漏斗
-- 工具与位置：FineBI（自 `.cursor/code/sql/临时文件` 迁入）
-- 刷新周期：T+1
-- 维护人：meishihua
-- 关联指标：→ glossary/【平台】_shihua.md#
-- 主用表：→ code/sql/表结构/【平台】_shihua/
-- 最后同步自看板日期：20260410
-- ⚠️ 注意：
-- =====================================================

-- 帆软-数据准备-sql 
-- 上一个仪表盘，拆分四个售卖渠道分别是：营销页（指从学习banner、消息通知、课程卡片进入的）/付费落地页/ai定制班（包含定制和未定制状态进入的所有订单）/其它，观察以上数据的漏斗和线索品订单占比（这个指的是，100%是线索品，然后四个地方分别贡献了多少）
-- 加一个用户筛选，用户购买前已定制和未定制，方便看ai定制班的效果 对于那部分用户最好
-- 26.3.10新增直播间渠道

with r1 as (select
        day 
        ,ab_name
        ,u_user
        ,grade_stage_name_day
        ,stage_name_day
        ,business_user_pay_status_business_day
        ,business_user_pay_status_statistics_day
        ,grade_name_day
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
    )

,r2 as (-- 线索品购买
        select
            paid_time_sk
            ,case 
                when good_kind_name_level_2='同步课加培优课' and good_kind_name_level_3='同步课加培优课流量品' then '线索品198'
                when good_kind_name_level_2='同步课' and good_kind_name_level_3='同步课-3个月' then '3个月同步课198' 
                else '除以上其他商品'
                end as good_type
            ,u_user
            ,sum(sub_amount) as amount
        from dws.topic_order_detail
        where paid_time_sk between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int)
        and business_gmv_attribution in ('商业化')
        and original_amount>=39
        group by 
            1,2,3 
    ) 



 select
    str2date(r1.day,'%Y%m%d') as `日期`
    ,ab_name as `实验分组`
    ,case when ab_name='3-对照组' then to_date('2024-01-01')
        when ab_name='4-left组' then to_date('2024-01-01')
        else to_date('2025-01-01')
        end as date_type
    ,case when ab_name='3-对照组' then '对照组'
        when ab_name='4-left组' then '对照组'
        else ab_name
        end as `实验名称`
    ,'营销页' as `页面类型`
    ,count(distinct r1.u_user) as `分组活跃人数`
    ,count(distinct r3.u_user) as `商品页面进入人数`
    ,count(distinct case 
                        when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.u_user
                        when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.u_user
                        else null end) as `进入页面后付费人数`
    ,sum(case 
            when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.amount
            when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.amount
            else 0 end) as `进入页面后付费金额`
from r1 
left join r2 on r1.day=r2.paid_time_sk and r1.u_user=r2.u_user
left join
    (-- 营销页面进入
        select
			day
			,u_user
		from aws.business_user_pay_process_enter_good_page_day
		where day between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int)
		and page_name regexp '68da3af3ffedc10dd4e0f49f'
        and from_page_name regexp 'ad-learntab-banner|ad-mytab-notification|shop-baozang-courseCard|tabStudy|shop-baozang-commonCard'
		and (!(from_page_name regexp 'purchase') or from_page_name is null or from_page_name='null' or from_page_name='') -- 排除电销推送
		group by 
		  1,2
    ) as r3 on r1.day=r3.day and r1.u_user=r3.u_user
group by 1,2,3,4,5

union all 

select
    str2date(r1.day,'%Y%m%d') as `日期`
    ,ab_name as `实验分组`
    ,case when ab_name='3-对照组' then to_date('2024-01-01')
        when ab_name='4-left组' then to_date('2024-01-01')
        else to_date('2025-01-01')
        end as date_type
    ,case when ab_name='3-对照组' then '对照组'
        when ab_name='4-left组' then '对照组'
        else ab_name
        end as `实验名称`
    ,'付费落地页' as `页面类型`
    ,count(distinct r1.u_user) as `分组活跃人数`
    ,count(distinct r3.u_user) as `商品页面进入人数`
    ,count(distinct case 
                        when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.u_user
                        when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.u_user
                        else null end) as `进入页面后付费人数`
    ,sum(case 
            when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.amount
            when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.amount
            else 0 end) as `进入页面后付费金额`
from r1 
left join r2 on r1.day=r2.paid_time_sk and r1.u_user=r2.u_user
left join
    (-- 营销页面进入
        select
            day
            ,u_user
        from aws.business_user_pay_process_enter_good_page_day
        where day between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int)
        and page_name regexp '付费介绍页|_聚合页'
        -- and from_page_name regexp 
        and (!(from_page_name regexp 'purchase|member-mytab-coursePromotion') or from_page_name is null or from_page_name='null' or from_page_name='') -- 排除电销推送
        group by 
          1,2
    ) as r3 on r1.day=r3.day and r1.u_user=r3.u_user
group by 1,2,3,4,5


union all
select
    str2date(r1.day,'%Y%m%d') as `日期`
    ,ab_name as `实验分组`
    ,case when ab_name='3-对照组' then to_date('2024-01-01')
        when ab_name='4-left组' then to_date('2024-01-01')
        else to_date('2025-01-01')
        end as date_type
    ,case when ab_name='3-对照组' then '对照组'
        when ab_name='4-left组' then '对照组'
        else ab_name
        end as `实验名称`
    ,'我的tab' as `页面类型`
    ,count(distinct r1.u_user) as `分组活跃人数`
    ,count(distinct r3.u_user) as `商品页面进入人数`
    ,count(distinct case 
                        when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.u_user
                        when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.u_user
                        else null end) as `进入页面后付费人数`
    ,sum(case 
            when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.amount
            when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.amount
            else 0 end) as `进入页面后付费金额`
from r1 
left join r2 on r1.day=r2.paid_time_sk and r1.u_user=r2.u_user
-- left join
--     (-- 营销页面进入
--         select
--             day
--             ,u_user
--         from aws.business_user_pay_process_enter_good_page_day
--         where day between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int)
--         and page_name not regexp '洋葱私教班｜4周特训'
--         and from_page_name regexp 'member-mytab-coursePromotion'
--         and (!(from_page_name regexp 'purchase') or from_page_name is null or from_page_name='null' or from_page_name='') -- 排除电销推送
--         group by 
--           1,2
--     ) as r3 on r1.day=r3.day and r1.u_user=r3.u_user

left join
    (-- ab测的营销页面埋点还未上线，这里临时统计的是资源位点击
        select
            day
            ,u_user
        from aws.business_user_pay_process_day
        where day between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int)
        and click_entrance_user is not null 
        and scene regexp 'member-mytab-coursePromotion'
        and (page_name not regexp '洋葱私教班｜4周特训' or page_name is null ) -- ab测的营销页面埋点还未上线，这部分的pagename是null
        group by 
          1,2
    ) as r3 on r1.day=r3.day and r1.u_user=r3.u_user

group by 1,2,3,4,5



union all
select
    str2date(r1.day,'%Y%m%d') as `日期`
    ,ab_name as `实验分组`
    ,case when ab_name='3-对照组' then to_date('2024-01-01')
        when ab_name='4-left组' then to_date('2024-01-01')
        else to_date('2025-01-01')
        end as date_type
    ,case when ab_name='3-对照组' then '对照组'
        when ab_name='4-left组' then '对照组'
        else ab_name
        end as `实验名称`
    ,'直播间' as `页面类型`
    ,count(distinct r1.u_user) as `分组活跃人数`
    ,count(distinct r3.u_user) as `商品页面进入人数`
    ,count(distinct case 
                        when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.u_user
                        when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.u_user
                        else null end) as `进入页面后付费人数`
    ,sum(case 
            when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.amount
            when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.amount
            else 0 end) as `进入页面后付费金额`
from r1 
left join r2 on r1.day=r2.paid_time_sk and r1.u_user=r2.u_user
left join
    (-- 营销页面进入
        select
            day
            ,u_user
        from aws.business_user_pay_process_enter_good_page_day
        where day between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int)
        and page_name regexp '洋葱私教班｜4周特训'
        -- and from_page_name regexp 
        and (!(from_page_name regexp 'purchase|member-mytab-coursePromotion') or from_page_name is null or from_page_name='null' or from_page_name='') -- 排除电销推送
        group by 
          1,2
    ) as r3 on r1.day=r3.day and r1.u_user=r3.u_user
group by 1,2,3,4,5



union all
select
    str2date(r1.day,'%Y%m%d') as `日期`
    ,ab_name as `实验分组`
    ,case when ab_name='3-对照组' then to_date('2024-01-01')
        when ab_name='4-left组' then to_date('2024-01-01')
        else to_date('2025-01-01')
        end as date_type
    ,case when ab_name='3-对照组' then '对照组'
        when ab_name='4-left组' then '对照组'
        else ab_name
        end as `实验名称`
    ,'AI定制班' as `页面类型`
    ,count(distinct r1.u_user) as `分组活跃人数`
    ,count(distinct r3.u_user) as `商品页面进入人数`
    ,count(distinct case 
                        when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.u_user
                        when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.u_user
                        else null end) as `进入页面后付费人数`
    ,sum(case 
            when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.amount
            when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.amount
            else 0 end) as `进入页面后付费金额`
from r1 
left join r2 on r1.day=r2.paid_time_sk and r1.u_user=r2.u_user
left join
    (-- 营销页面进入
        select
            day
            ,u_user
        from aws.business_user_pay_process_enter_good_page_day
        where day between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int)
        and page_name regexp '68da3af3ffedc10dd4e0f49f|AI定制结果页面'
        and from_page_name regexp 'study-learntab-aiClassEntrance|study-AIPersonalizedClass-classPromotion'
        and (!(from_page_name regexp 'purchase') or from_page_name is null or from_page_name='null' or from_page_name='') -- 排除电销推送
        group by 
          1,2
    ) as r3 on r1.day=r3.day and r1.u_user=r3.u_user
group by 1,2,3,4,5



union all
select
    str2date(r1.day,'%Y%m%d') as `日期`
    ,ab_name as `实验分组`
    ,case when ab_name='3-对照组' then to_date('2024-01-01')
        when ab_name='4-left组' then to_date('2024-01-01')
        else to_date('2025-01-01')
        end as date_type
    ,case when ab_name='3-对照组' then '对照组'
        when ab_name='4-left组' then '对照组'
        else ab_name
        end as `实验名称`
    ,'全部页面' as `页面类型`
    ,count(distinct r1.u_user) as `分组活跃人数`
    ,count(distinct r3.u_user) as `商品页面进入人数`
    ,count(distinct case 
                        when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.u_user
                        when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.u_user
                        else null end) as `进入页面后付费人数`
    ,sum(case 
            when r3.u_user is not null and ab_name in ('3-对照组','4-left组') and r2.good_type = '3个月同步课198' then r2.amount
            when r3.u_user is not null and ab_name not in ('3-对照组','4-left组') and r2.good_type = '线索品198' then r2.amount
            else 0 end) as `进入页面后付费金额`
from r1 
left join r2 on r1.day=r2.paid_time_sk and r1.u_user=r2.u_user
left join
    (-- 营销页面进入
        select
            day
            ,u_user
        from aws.business_user_pay_process_enter_good_page_day
        where day between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int)
        and page_name regexp '68da3af3ffedc10dd4e0f49f|AI定制结果页面|付费介绍页|_聚合页|洋葱私教班｜4周特训'
        -- and from_page_name regexp 'study-learntab-aiClassEntrance|study-AIPersonalizedClass-classPromotion'
        and (!(from_page_name regexp 'purchase') or from_page_name is null or from_page_name='null' or from_page_name='') -- 排除电销推送
        group by 
          1,2
        
        union 
        
        -- ab测的营销页面埋点还未上线，这里临时统计的是资源位点击
        select
            day
            ,u_user
        from aws.business_user_pay_process_day
        where day between cast(replace('${doris_dp_198test2_date_start}','-','') as int) and cast(replace('${doris_dp_198test2_date_end}','-','') as int)
        and click_entrance_user is not null 
        and scene regexp 'member-mytab-coursePromotion'
        and (page_name not regexp '洋葱私教班｜4周特训' or page_name is null ) -- ab测的营销页面埋点还未上线，这部分的pagename是null
        group by 
          1,2
    ) as r3 on r1.day=r3.day and r1.u_user=r3.u_user
    
group by 1,2,3,4,5


