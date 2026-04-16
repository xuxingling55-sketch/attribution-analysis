-- =====================================================
-- 看板名称：202511_线索品198六期
-- 业务域：【平台】_shihua
-- 图表/组件：202511_线索品198六期_小转大续费-累计
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
    ,grade_stage_name_day as `年级段`
    ,stage_name_day as `学段`
    ,business_user_pay_status_business_day  as `业务分层`
    ,business_user_pay_status_statistics_day  as `统计分层`
    ,grade_name_day  as `年级`
    ,good_type as `商品分类`
    ,business_gmv_attribution as `渠道`
    ,type as `分层`
    ,count(distinct u_user) as `付费人数`
    ,count(distinct if(amount>0,u_user,null)) as `续费人数`
    ,sum(amount) as `续费金额`
    ,count(distinct if(zuhe_amount>0,u_user,null)) as `组合品续费人数`
    ,sum(zuhe_amount) as `组合品续费金额`
    ,count(distinct if(qita_amount>0,u_user,null)) as `非组合品续费人数`
    ,sum(qita_amount) as `非组合续费金额`
from 
    (select
        *
        ,case when is_wechat=1 and is_ai=1 then 'AI定制班+加微'
             when is_wechat=1 and is_ai=0 then '仅加微'
             when is_wechat=0 and is_ai=1 then '仅AI定制班'
             else '都不加'
             end as type 
    from 
    (select
        ab_name
        ,grade_stage_name_day
        ,stage_name_day
        ,business_user_pay_status_business_day
        ,business_user_pay_status_statistics_day
        ,grade_name_day
        ,good_type
        ,business_gmv_attribution
        ,r1.order_id
        ,r1.amount as firstpay_amount 
        ,r1.paid_time
        ,r1.u_user
        ,r1.paid_time_sk
        ,add_times
        ,add_day
        ,ai_day
        ,paid_rank
        ,max(case when add_day<=r2.paid_time_sk then 1 
                when add_day>r2.paid_time_sk then 0
                when r2.paid_time_sk is null and add_day is not null then 1
                else 0 end
                ) as is_wechat -- 可能会下多单
         ,max(case when ai_day<=r2.paid_time_sk then 1 
                when ai_day>r2.paid_time_sk then 0
                when r2.paid_time_sk is null and ai_day is not null then 1
                else 0 end
                ) as is_ai
        ,sum(zuhe_amount) as zuhe_amount
        ,sum(qita_amount) as qita_amount
        ,sum(r2.amount) as amount
    from 
        (select
            ab_name
            ,grade_stage_name_day
            ,stage_name_day
            ,business_user_pay_status_business_day
            ,business_user_pay_status_statistics_day
            ,grade_name_day
            ,good_type
            ,business_gmv_attribution
            ,order_id
            ,amount 
            ,paid_time
            ,u_user
            ,paid_time_sk
            ,add_times
            ,add_day
            ,ai_day
            ,paid_rank
        from 
            (
                select
                    ab_name
                    ,grade_stage_name_day
                    ,stage_name_day
                    ,business_user_pay_status_business_day
                    ,business_user_pay_status_statistics_day
                    ,grade_name_day
                    ,good_type
                    ,business_gmv_attribution
                    ,order_id
                    ,amount 
                    ,paid_time
                    ,u_user
                    ,paid_time_sk
                    ,add_times
                    ,add_day
                    ,ai_day
                    ,row_number()over(partition by ab_name,u_user,good_type,business_gmv_attribution order by paid_time) as paid_rank
                from tmp.lidanping_quanyu_198test_2_goodtype
                where str2date(paid_time_sk,'%Y%m%d') between ('${doris_dp_198test2_date_start}') and ('${doris_dp_198test2_date_end}') 
                -- and good_type in ('线索品198','3个月同步课198','12个月同步课498')
                    <parameter> 
                    and `business_gmv_attribution` in ('${doris_dp_198test2_business_gmv_attribution}')
                    </parameter>
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
                    <parameter> 
                  and `good_type` in ('${doris_dp_198test2_good_type}')
                    </parameter>
            ) as a1 
            where paid_rank=1  
        ) as r1 
    left join 
         (
            select
                paid_time_sk
                ,u_user
                ,order_id
                ,paid_time
                ,sum(if(business_good_kind_name_level_1 = '组合品',sub_amount,0)) as zuhe_amount
                ,sum(if(business_good_kind_name_level_1 != '组合品',sub_amount,0)) as qita_amount
                ,sum(sub_amount) as amount
            from dws.topic_order_detail
            where str2date(paid_time_sk,'%Y%m%d') between ('${doris_dp_198test2_xugou_date_start}') and ('${doris_dp_198test2_xugou_date_end}') 
            -- and business_gmv_attribution in ('商业化','电销')
            and original_amount>=39
             <parameter> 
                and `business_gmv_attribution` in ('${doris_dp_198test2_xugou_business_gmv_attribution}')
                </parameter>
            group by 
            1,2,3,4
         ) as r2 on r1.u_user=r2.u_user and r1.paid_time<=r2.paid_time and r1.order_id<>r2.order_id
    group by 
        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
    ) as k0 
) as k1 
where 1=1
   <parameter> 
    and `type` in ('${doris_dp_198test2_type}')
     </parameter>
group by 
    1,2,3,4,5,6,7,8,9,10,11







