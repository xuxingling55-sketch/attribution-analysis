-- =====================================================
-- 看板名称：202511_线索品198六期
-- 业务域：【平台】_shihua
-- 图表/组件：202511_线索品198六期_198精研班付费来源
-- 工具与位置：FineBI（自 `.cursor/code/sql/临时文件` 迁入）
-- 刷新周期：T+1
-- 维护人：meishihua
-- 关联指标：→ glossary/【平台】_shihua.md#
-- 主用表：→ code/sql/表结构/【平台】_shihua/
-- 最后同步自看板日期：20260410
-- ⚠️ 注意：
-- =====================================================

-- 帆软-数据准备-sql 
 

select
    ab_name as `实验分组`
    ,case when ab_name='3-对照组' then to_date('2024-01-01')
        when ab_name='4-left组' then to_date('2024-01-01')
        else to_date('2025-01-01')
        end as date_type
    ,case when ab_name='3-对照组' then '对照组'
        when ab_name='4-left组' then '对照组'
        else ab_name
        end as `实验名称`
    ,type as `页面类型`
    ,count(distinct r2.u_user) as `付费人数`
    ,sum(amount) as `付费金额`
from 
  (select
        day 
        ,ab_name
        ,u_user
        ,grade_stage_name_day
        ,stage_name_day
        ,business_user_pay_status_business_day
        ,business_user_pay_status_statistics_day
        ,grade_name_day
    from tmp.lidanping_quanyu_198test_2
    where str2date(day,'%Y%m%d') between ('${doris_dp_198test2_date_start}') and ('${doris_dp_198test2_date_end}')
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
    ) as r1 
 join
    (-- 线索品购买
        select
            paid_time_sk
            ,u_user
            ,case 
                when sell_from regexp 'zhibojian' then '直播间'
                when sell_from regexp 'member-mytab-coursePromotion' then '我的tab'
                when sell_from regexp 'ad-learntab-banner|ad-mytab-notification|shop-baozang-courseCard|tabStudy|shop-baozang-commonCard' then '营销页'
                when sell_from regexp 'study-learntab-aiClassEntrance|study-AIPersonalizedClass-classPromotion' then 'AI定制班'
                when sell_from regexp '付费介绍页|_聚合页' then '付费落地页'
                else '其他'
                end as type 
            ,sum(sub_amount) as amount
        from dws.topic_order_detail
        where str2date(paid_time_sk,'%Y%m%d') between ('${doris_dp_198test2_date_start}') and ('${doris_dp_198test2_date_end}')
        and business_gmv_attribution in ('商业化')
        and original_amount>=39
        and good_kind_name_level_2='同步课加培优课' and good_kind_name_level_3='同步课加培优课流量品'
        group by 
            1,2,3
    ) as r2 on r1.day=r2.paid_time_sk and r1.u_user=r2.u_user
group by 1,2,3,4
