-- =====================================================
-- 看板名称：202511_线索品198六期
-- 业务域：【平台】_shihua
-- 图表/组件：202511_线索品198六期_整体转化累计_用户明细
-- 工具与位置：FineBI（自 `.cursor/code/sql/临时文件` 迁入）
-- 刷新周期：T+1
-- 维护人：meishihua
-- 关联指标：→ glossary/【平台】_shihua.md#
-- 主用表：→ code/sql/表结构/【平台】_shihua/
-- 最后同步自看板日期：20260410
-- ⚠️ 注意：
-- =====================================================

-- 帆软-数据准备-sql 
-- =============================================================================
-- 整体用户的付费（周期汇总版，无 day 分组）
-- -----------------------------------------------------------------------------
-- 相对「日表」版的主要改动：
-- 1) 最外层去掉 `day`；r4 中 rn*_day 改为 rn*_total，partition 去掉 r1.day，
--    order by 以 r1.day 起头，保证跨日只保留「每个 u_user × ab_name」一条链。
-- 2) rn1_allpay_total：左连接 r2 时，先出现的自然日可能无支付；在 order by 中
--    用「有 amount>0 优先」，避免 rn1=1 落在无支付行上导致付费人数被低估。
-- 3) rn3_total：同理，用「当日有页面行为(non_pb_cnt 或 pb_cnt>0)优先」。
-- 4) rn1/rn2 的排序字段与日表一致，使用 rank_day（日内序），不用 rank_total。
-- 5) 指标注释由「当日」改为「周期内/所选区间」。
-- 注意：partition 仅 (u_user, ab_name) 时，若年级/分层等随日变化，用户可能只
-- 被算入排序靠前那天的维度桶——若业务上维度会变，需把对应字段放进 partition
-- 或先定义「周期内取哪一天的维度」。
-- =============================================================================

with r1 as (
    select
        ab_name
        ,u_user
        ,grade_stage_name_day
        ,stage_name_day
        ,business_user_pay_status_business_day
        ,business_user_pay_status_statistics_day
        ,grade_name_day
        ,str2date(day, '%Y%m%d') as date
        ,day
    from tmp.lidanping_quanyu_198test_2
    where day between cast(replace('${doris_dp_198test2_date_start}', '-', '') as int)
              and cast(replace('${doris_dp_198test2_date_end}', '-', '') as int)
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
        1, 2, 3, 4, 5, 6, 7, 8, 9
)

, r2 as (
    select
        u_user
        ,str2date(paid_time_sk, '%Y%m%d') as date
        ,good_type
        ,pb_amount
        ,non_pb_amount
        ,zuhe_amount
        ,qita_amount
        ,amount
        ,order_id
        ,rank_total
        ,rank_day
    from (
        select
            u_user
            ,paid_time_sk
            ,business_gmv_attribution
            ,row_number() over (
                partition by u_user
                order by paid_time, order_id, business_gmv_attribution, good_type
            ) as rank_total -- 周期内用户维度首单/续单
            ,row_number() over (
                partition by u_user, paid_time_sk
                order by paid_time, order_id, business_gmv_attribution, good_type
            ) as rank_day -- 日内订单序
            ,good_type
            ,order_id
            ,pb_amount
            ,non_pb_amount
            ,zuhe_amount
            ,qita_amount
            ,amount
        from (
            select
                paid_time_sk
                ,u_user
                ,order_id
                ,paid_time
                ,business_gmv_attribution
                ,case
                    when business_good_kind_name_level_1 = '组合品' then '组合品'
                    when good_kind_name_level_1 = '方案型商品' then '其他方案型商品'
                    when good_kind_name_level_2 = '同步课加培优课' and good_kind_name_level_3 = '同步课加培优课流量品' then '线索品198'
                    when good_kind_name_level_2 = '同步课' and good_kind_name_level_3 = '同步课-3个月' then '3个月同步课198'
                    when good_kind_name_level_2 = '同步课' and good_kind_name_level_3 = '同步课-12个月' then '12个月同步课498'
                    else '除以上其他商品'
                end as good_type
                ,sum(if(good_kind_name_level_1 = '方案型商品', sub_amount, 0)) as pb_amount
                ,sum(if(good_kind_name_level_1 != '方案型商品', sub_amount, 0)) as non_pb_amount
                ,sum(if(business_good_kind_name_level_1 = '组合品', sub_amount, 0)) as zuhe_amount
                ,sum(if(business_good_kind_name_level_1 != '组合品', sub_amount, 0)) as qita_amount
                ,sum(sub_amount) as amount
            from dws.topic_order_detail
            where paid_time_sk between cast(replace('${doris_dp_198test2_date_start}', '-', '') as int)
                                 and cast(replace('${doris_dp_198test2_date_end}', '-', '') as int)
              and original_amount >= 39
              and business_gmv_attribution in ('商业化', '电销')
            <parameter>
                and `business_gmv_attribution` in ('${doris_dp_198test2_business_gmv_attribution}')
            </parameter>
            group by
                1, 2, 3, 4, 5, 6
        ) as a1
    ) as a2
    where 1 = 1
)

, r3 as (
    -- 商品页进入（埋点说明同原 SQL）
    select
        u_user
        ,str2date(day, '%Y%m%d') as date
        ,sum(non_pb_cnt) as non_pb_cnt
        ,sum(pb_cnt) as pb_cnt
    from (
        select
            day
            ,u_user
            ,count(if(page_name regexp '付费介绍页|_聚合页|期中满分冲刺包急救包|68da3af3ffedc10dd4e0f49f|AI定制结果页面|洋葱私教班｜4周特训', u_user, null)) as non_pb_cnt
            ,count(if(page_name regexp '暑期大促|组合课包会场|首购会场|多孩续购会场|高中囤课会场|大会员续购会场|加购平板页面', u_user, null)) as pb_cnt
        from aws.business_user_pay_process_enter_good_page_day
        where day between cast(replace('${doris_dp_198test2_date_start}', '-', '') as int)
                      and cast(replace('${doris_dp_198test2_date_end}', '-', '') as int)
          and (not (from_page_name regexp 'purchase') or from_page_name is null or from_page_name = 'null' or from_page_name = '')
        group by
            day
            ,u_user
        union all
        select
            day
            ,u_user
            ,0 as non_pb_cnt
            ,1 as pb_cnt
        from aws.user_live_detail_day
        where day between cast(replace('${doris_dp_198test2_date_start}', '-', '') as int)
                      and cast(replace('${doris_dp_198test2_date_end}', '-', '') as int)
          and duration > 0
        group by
            day
            ,u_user
    ) as a1
    group by
        1, 2
)

, r4 as (
    select
        r1.*
        ,r2.u_user as pay_user
        ,r2.good_type
        ,r2.amount
        ,r2.pb_amount
        ,r2.non_pb_amount
        ,r2.zuhe_amount
        ,r2.qita_amount
        ,r2.order_id
        ,r2.rank_total
        ,r2.date as pay_date
        ,r3.u_user as page_user
        ,r3.non_pb_cnt
        ,r3.pb_cnt
        -- 汇总：每个 u_user×ab_name 全周期一条链；与日表一致用 rank_day 排序 join 行
        ,row_number() over (
            partition by r1.u_user, r1.ab_name
            order by
                r1.day
                ,r2.date nulls last
                ,r2.order_id nulls last
                ,r2.rank_day nulls last
                ,r3.date nulls last
        ) as rn2_total
        -- 付费人数：无支付日优先排在后，避免 rn1=1 落在 amount=0 上
        ,row_number() over (
            partition by r1.u_user, r1.ab_name
            order by
                r1.day
                ,case when coalesce(r2.amount, 0) > 0 then 0 else 1 end
                ,r2.date nulls last
                ,r2.order_id nulls last
                ,r2.rank_day nulls last
        ) as rn1_allpay_total
        -- 页面进入：有页面计数优先，避免 rn3=1 落在「无页面」行上
        ,row_number() over (
            partition by r1.u_user, r1.ab_name
            order by
                r1.day
                ,case when coalesce(r3.non_pb_cnt, 0) + coalesce(r3.pb_cnt, 0) > 0 then 0 else 1 end
                ,r3.date nulls last
        ) as rn3_total
    from r1
    left join r2
        on r1.u_user = r2.u_user
       and r1.date = r2.date
    left join r3
        on r1.u_user = r3.u_user
       and r1.date = r3.date
)

,before_amount as (
            select
                u_user
                ,sum(sub_amount) as amount
                ,count(distinct order_id) as orders
            from dws.topic_order_detail
            where paid_time_sk < cast(replace('${doris_dp_198test2_date_start}', '-', '') as int)
                                 
              and original_amount >= 39
              and business_gmv_attribution in ('商业化', '电销')
            <parameter>
                and `business_gmv_attribution` in ('${doris_dp_198test2_business_gmv_attribution}')
            </parameter>
            group by
                1
        )


,user_order as (select
    u_user 
    ,ab_name
    ,count(distinct if(amount > 0, order_id, null)) as orders
    ,coalesce(sum(amount),0) as amount
from r4
group by
    1, 2
)


select 
    a.u_user as `用户id`
    ,a.ab_name as `实验分组`
    ,a.orders as `订单量`
    ,a.amount as `付费金额`
    ,b.orders as `统计周期之前的订单量`
    ,coalesce(b.amount,0) as `统计周期之前的付费金额`
from user_order a 
left join before_amount b on a.u_user = b.u_user 


