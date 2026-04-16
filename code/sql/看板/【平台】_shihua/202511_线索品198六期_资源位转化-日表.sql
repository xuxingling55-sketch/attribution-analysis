-- =====================================================
-- 看板名称：202511_线索品198六期
-- 业务域：【平台】_shihua
-- 图表/组件：202511_线索品198六期_资源位转化-日表
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
    ab_name as `实验名称`
  ,case when ab_name='3-对照组' then '对照组'
        when ab_name='4-left组' then '对照组'
        else ab_name
        end as `实验分组`
  ,grade_stage_name_day
    ,stage_name_day
    ,business_user_pay_status_business_day
    ,business_user_pay_status_statistics_day
    ,grade_name_day
    ,str2date(r1.day,'%Y%m%d') as `日期`
    ,count(distinct get_entrance_user) as `资源位曝光人数`
    ,count(distinct if(click_entrance_user>0,get_entrance_user,null)) as `资源位点击人数`
    ,count(distinct if(click_entrance_user>0 and enter_good_page_user>0,get_entrance_user,null)) as `进入活动页面人数`
    ,count(distinct if(click_entrance_user>0 and enter_good_page_user>0 and click_good_page_user>0,get_entrance_user,null)) as `页面点击购买人数`
    ,count(distinct if(click_entrance_user>0 and enter_good_page_user>0 and click_good_page_user>0 and enter_order_page_user>0,get_entrance_user,null)) as `进入订单详情页人数`
    ,count(distinct if(click_entrance_user>0 and enter_good_page_user>0 and click_good_page_user>0 and enter_order_page_user>0 and click_order_page_user>0,get_entrance_user,null)) as `订单详情页点击人数`
    ,count(distinct if(click_entrance_user>0 and enter_good_page_user>0 and click_good_page_user>0 and enter_order_page_user>0 and click_order_page_user>0 and paid_order_user>0,get_entrance_user,null)) as `支付成功人数`
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
(select
    day
    ,get_entrance_user
    ,scene
    ,click_entrance_user
    ,enter_good_page_user
    ,click_good_page_user
    ,enter_order_page_user
    ,click_order_page_user
    ,paid_order_user
from tmp.lidanping_quanyu_198test_2_scene 
 where str2date(day,'%Y%m%d') between ('${doris_dp_198test2_date_start}') and ('${doris_dp_198test2_date_end}')
  <parameter> 
      and `scene` in ('${doris_dp_198test2_scene}')
      </parameter>
) as r2 on r1.u_user=r2.get_entrance_user and r1.day=r2.day 
group by 
   1,2,3,4,5,6,7,8


   
