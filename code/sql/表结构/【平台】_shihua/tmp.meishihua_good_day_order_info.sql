-- =====================================================
-- 商品- 商品维度表 tmp.meishihua_good_day_order_info
-- =====================================================
--
-- 【表粒度】
--   一个order_id一行（分区字段：无）
--
-- 【业务定位】
--   - 【归属】商品 / 商品维度表。
--   - 与 dws.topic_user_active_detail_day 按 u_user + day(paid_time_sk) 关联；含 *_day 后缀分层字段（与活跃日表同名字段语义不完全等同，见 table-relations）；与 dw.dim_user 可按 u_user 对齐
--   - 商品系列看板的底层表，来源于dws.topic_order_detail

-- 【统计口径】
--   表内营收/订单汇总列见字段 COMMENT
--
-- 【常用关联】
--   - 建表：order_info 内 join first_order_info b on a.order_id = b.order_id（dws.topic_order_detail a）
--   - 另可对齐：u_user、day(paid_time_sk) 与 dws.topic_user_active_detail_day（见业务定位）

--
-- 【常用筛选条件】
--   - day(paid_time_sk)、分层字段
--
-- 【注意事项】
--   - 更新频率 T+1
--
-- =====================================================


<!-- drop table if exists tmp.meishihua_good_day_order_info force; -->
create table tmp.meishihua_good_day_order_info as 

with first_order_info as (select 
order_id
,group_concat(distinct stage_name) as stage_names
,group_concat(distinct model_type) as model_types
,group_concat(distinct case when good_kind_id_level_1 in ('f76be748-e94c-453d-a3d7-9800113bcb7b','cd445957-06eb-4cd9-afeb-0ded1c4677a7') -- 方案型商品+零售商品
    and good_kind_id_level_2 not in ('9433f2e3-7908-44b6-ae84-d3ba257ad3ce','329c024c-9c8a-4e53-95a2-b751d9dec9c8') -- 体验机+学习机加购
    and kind = 'pad' then kind end) as is_add_pad
from dws.topic_order_detail
group by 1 
)



,order_info as (select 
mid_stage_name as stage_name_day -- 日用户学段
,mid_grade as grade_name_day -- 日用户年级
,case when mid_grade regexp '一年级|二年级' then '小初'
when mid_grade regexp '三年级|四年级' then '小中'
when mid_grade regexp '五年级|六年级' then '小高'
else mid_grade 
end as grade_stage_name_day -- 日用户年级段
,business_user_pay_status_statistics as business_user_pay_status_statistics_day -- 日统计分层
,business_user_pay_status_business as business_user_pay_status_business_day -- 日业务分层
,grade_name_month -- 月用户学段
,stage_name_month -- 月用户年级
,grade_stage_name_month -- 月用户年级段
,business_user_pay_status_statistics_month --  月统计分层
,business_user_pay_status_business_month --  月业务分层

,case when user_strategy_tag_day regexp '历史大会员' then '历史大会员' else user_strategy_tag_day end as user_strategy_tag_day  -- 策略用户分层-日-临时字段名占位【需要清洗：历史大会员】
,case when user_strategy_tag_month regexp '历史大会员' then '历史大会员' else user_strategy_tag_month end as user_strategy_tag_month  -- 策略用户分层-月-临时字段名占位【需要清洗：历史大会员】
,user_strategy_eligibility_day  -- 策略资格-日-临时字段名占位
,user_strategy_eligibility_month  -- 策略资格-月-临时字段名占位
,strategy_type -- 策略类型
,big_vip_kind_day -- 历史大会员标签【需要根据user_strategy_tag_day/month/year清洗：null值为「非历史大会员」】
,big_vip_kind_month -- 历史大会员标签【需要根据user_strategy_tag_day/month/year清洗：null值为「非历史大会员」】

,business_gmv_attribution -- gmv归属
,concat(stage_name,subject_name) as stage_subject
,stage_name
,subject_name
,good_name
,business_good_kind_name_level_1
,business_good_kind_name_level_2
,business_good_kind_name_level_3
,good_kind_name_level_1
,good_kind_name_level_2
,good_kind_name_level_3
,good_stage_subject_cnt
,case 
    when business_good_kind_name_level_1 = '组合品' then '组合品'
    when business_good_kind_name_level_3 = '普通续购' then '普通续购'
    when business_good_kind_name_level_3 = '学段加购' then '学段加购'
    when business_good_kind_name_level_3 = '学习机加购' then '学习机加购'
    when business_good_kind_name_level_3 = '培优课加购' then '培优课加购'
    when business_good_kind_name_level_3 in ('培优课','全科培优课联售') then '培优课'
    when business_good_kind_name_level_3 = '全科同步课联售' and good_kind_id_level_3 <> 'ee8e64d4-b43e-4858-a6cd-81c8c94fc055' then '901-1000'
    when business_good_kind_name_level_1 = '零售商品' and order_amount < 100 then '39-99'
    when business_good_kind_name_level_1 = '零售商品' and order_amount <= 200 then '100-200'
    when business_good_kind_name_level_1 = '零售商品' and order_amount <= 300 then '201-300'
    when business_good_kind_name_level_1 = '零售商品' and order_amount <= 500 then '301-500'
    when business_good_kind_name_level_1 = '零售商品' and order_amount <= 900 then '501-900'
    when business_good_kind_name_level_1 = '零售商品' and order_amount <= 1000 then '901-1000'
    when business_good_kind_name_level_1 = '零售商品' and order_amount <= 1300 then '1001-1300'
    when business_good_kind_name_level_1 = '零售商品' and order_amount <= 1500 then '1301-1500'
    when good_kind_id_level_3 = 'ee8e64d4-b43e-4858-a6cd-81c8c94fc055' then '1301-1500'
    when business_good_kind_name_level_1 = '零售商品' and order_amount > 1500 then '1500+'
    else '其他'
    end as price_kind
,fix_good_year 
,paid_time
,paid_time_sk
,add_time_day
,is_recalled
,a.order_id
,u_user
,sub_amount
,good_subject_cnt
,order_amount
,original_amount
,case 
      when business_good_kind_name_level_3 = '全科同步课联售' then '同步课12个月小初高全科'
      when business_good_kind_name_level_3 = '全科培优课联售' then '培优课全科'
      when business_good_kind_name_level_3 = '同步课' and fix_good_year = '93天' and good_subject_cnt = 1 then '同步课3个月1科'
      when business_good_kind_name_level_3 = '同步课' and fix_good_year = '1年' and good_subject_cnt = 1 then '同步课12个月1科'
      when business_good_kind_name_level_3 = '同步课' and fix_good_year = '93天' and good_subject_cnt = 2 then '同步课3个月2科'
      when business_good_kind_name_level_3 = '同步课' and fix_good_year = '1年' and good_subject_cnt = 5 then '同步课12个月5科'
      when business_good_kind_name_level_3 = '同步课' and fix_good_year = '1年' and ((b.stage_names regexp '高中' and good_subject_cnt > 5) or (b.stage_names regexp '初中' and good_subject_cnt > 6)) then '同步课12个月全科' -- 订单可能有跨学段商品，如果子商品有高中，那就默认是高中商品
      when business_good_kind_name_level_3 = '培优课' and good_subject_cnt = 1 then '培优课1科'
      when business_good_kind_name_level_3 = '培优课' and good_subject_cnt = 2 then '培优课2科'
      
      WHEN good_kind_id_level_3 = 'a0ef9569-61b0-42b4-af38-2d357d076902' THEN '同步课加培优课流量品'
      WHEN ( (ARRAY_JOIN(`group`,',') regexp '24666蓄水' and (paid_time_sk between 20240608 and 20240630)) or 
            (sku_group_good_id in ('2ad36071-17ec-4eda-9a7a-27c005fd61fa','10138aa5-ea9c-4723-9ac7-4aab637e7218') and (paid_time_sk between 20250603 and 20250622)) ) THEN '同步课加培优课流量品'
      WHEN array_join(`group`,',') regexp  '策略中心测试品' and array_join(`group`,',') regexp  '202508暑期规划' THEN '同步课加培优课流量品'
      
      when sku_group_good_id = 'ab416aba-0e49-46d2-b804-b4c7c1290258' then 'AI通识课'
      when sku_group_good_id = 'f2802fca-7a87-4a13-b854-115ff05a594b' then '计算训练营'
      
      when array_join(`group`,',') regexp  '渠道测试品' then concat('渠道测试品-',substring_index(substring_index(array_join(`group`,','),'渠道测试品-',-1),',',1),'-',good_name )
      when array_join(`group`,',') regexp  '策略中心测试品' then concat('策略中心测试品-',substring_index(substring_index(array_join(`group`,','),'策略中心测试品-',-1),',',1),'-',good_name )
      else '其他'
      end buy_kind
,case 
    when business_good_kind_name_level_1 = '组合品' then '组合品' else '非组合品' end is_zuhe
,FLOOR((order_amount - 10) / 20) as ceils
,CONCAT(FLOOR((order_amount - 10) / 20) * 20 + 10, '-', FLOOR((order_amount - 10) / 20) * 20 + 30) as ceils_kind
,case
      when good_kind_id_level_2 in ('ad1d45cb-21b9-478b-8cc7-3fd75ac93aa4','1ea973d0-bb4c-4499-bca7-330378a7baad') then '历史大会员'
      when good_kind_id_level_2 in ('5e42f66c-0376-41b6-860b-9e437662283a','0d63071c-a690-4b51-ba2d-c9387c69026c','14cd8784-5583-48a6-a14b-85dfc63a2848') then '组合品'
      when good_kind_id_level_2 in ('329c024c-9c8a-4e53-95a2-b751d9dec9c8','f5463f28-9e13-465e-a428-34618d8ddae0') then '续购'
      when good_kind_id_level_2 = '9eb79b68-99f2-4bd0-a9c7-061af50a186a' then '一年积木块'
      when good_kind_id_level_2 = '27fc5116-263b-4ee6-9b56-b71029bead61' then '到期型培优课积木块'
      when good_kind_id_level_1 = 'cd445957-06eb-4cd9-afeb-0ded1c4677a7' and original_amount>900 then '900以上零售品'
      when good_kind_id_level_2 = '3aa9d1fb-0c47-407e-9d5b-35c73768ec14' and fix_good_year = '3年' then '培优课-3年'
      when good_kind_id_level_2 = 'd99f155b-c0e7-4ee6-9833-39a6eadbab58' and fix_good_year = '1年' then '同步课-1年'
      when good_kind_id_level_2 = '3aa9d1fb-0c47-407e-9d5b-35c73768ec14' and fix_good_year = '1年' then '培优课-1年'
      when good_kind_id_level_2 ='d99f155b-c0e7-4ee6-9833-39a6eadbab58' and fix_good_year = '186天' then '同步课-6个月'
      when good_kind_id_level_2 ='d99f155b-c0e7-4ee6-9833-39a6eadbab58' and fix_good_year = '93天' then '同步课-3个月'
      when good_kind_id_level_2 ='3aa9d1fb-0c47-407e-9d5b-35c73768ec14' and fix_good_year = '93天' then '培优课-3个月'
      when good_kind_id_level_2 ='d99f155b-c0e7-4ee6-9833-39a6eadbab58' and fix_good_year = '31天' then '同步课-1个月'
      when good_kind_id_level_2 ='3aa9d1fb-0c47-407e-9d5b-35c73768ec14' and fix_good_year = '31天' then '培优课-1个月'
      when good_kind_id_level_1 ='cd445957-06eb-4cd9-afeb-0ded1c4677a7' then '900以下零售品-其他'
      else business_good_kind_name_level_3
      end good_type_kind -- 策略分层-历史商品的商品分类标签
,fix_good_kind_id_level_2
,CASE 
    WHEN good_kind_id_level_2 in ('9eb79b68-99f2-4bd0-a9c7-061af50a186a','d99f155b-c0e7-4ee6-9833-39a6eadbab58') THEN '同步课'
    WHEN good_kind_id_level_3 in ('2f380c3c-b3fd-4ad3-a059-7af87923790e','79c2f91f-c4ca-4a3e-806a-7b24a464f704') THEN '同步课'
    
    WHEN good_kind_id_level_2 in ('27fc5116-263b-4ee6-9b56-b71029bead61','3aa9d1fb-0c47-407e-9d5b-35c73768ec14') THEN '培优课'
    WHEN good_kind_id_level_3 = '77142d09-5cc6-43b1-82d0-089f906a5f1e' THEN '培优课'
    
    WHEN good_kind_id_level_2 in ('5e42f66c-0376-41b6-860b-9e437662283a','1ea973d0-bb4c-4499-bca7-330378a7baad','0d63071c-a690-4b51-ba2d-c9387c69026c','f5463f28-9e13-465e-a428-34618d8ddae0'
            ,'14cd8784-5583-48a6-a14b-85dfc63a2848','5e42f66c-0376-41b6-860b-9e437662283a','ad1d45cb-21b9-478b-8cc7-3fd75ac93aa4') THEN '全系列（同步+培优）'
    
    WHEN good_kind_id_level_2 in ('329c024c-9c8a-4e53-95a2-b751d9dec9c8','9433f2e3-7908-44b6-ae84-d3ba257ad3ce','a3ef9ba6-1bdd-4699-9eaa-0cfd2408b76c') THEN '学习机'
    WHEN good_kind_id_level_3 = '2438bcab-6da8-4aa4-98a8-7b47b6ed7cfc' THEN '洋葱选科志愿卡'
    WHEN good_kind_id_level_2 = '88fad460-6c3e-496a-86aa-53c355b6961c' THEN '同步加培优'
    WHEN good_kind_id_level_3 = 'a9af0cfc-96ba-4bf3-bca8-3122a7381a37' THEN 'AI通识课'
    WHEN good_kind_id_level_2 = '00123a28-1e6b-4760-b36f-7e9c2c37df51' THEN '清葱学习方法课'
    WHEN good_kind_id_level_2 = '90a3dbee-fe78-4201-9ee5-3641de6c586f' THEN '启蒙课'
    WHEN good_kind_id_level_2 = 'b6a07a14-b0d0-430e-8a30-60f8200c6bdb' THEN '衔接课'
    WHEN good_kind_id_level_2 = '7ecdf8da-0a44-4dec-a546-73a10acad159' THEN '试卷库'
    WHEN good_kind_id_level_3 = 'f6f781ef-b49e-4e63-89a9-8b8bd4e0dfbc' AND stage_id = 1 and subject_id = 2 THEN '从小学物理' -- 临时配置，当前商品的子商品stage_id、subject_id都是唯一的，不存在null或其它学科学段信息
    ELSE '其他' END AS product_kind -- 产品系列
,CASE WHEN good_subject_cnt = 1 then '单科' else '联售' end as subjects_kind 
,CASE WHEN is_add_pad = 'pad' then '是' else '否' end as is_add_pad -- 是否随单加购平板
,model_types -- 加购平板型号

from dws.topic_order_detail a   -- 底层表不限制，原因是统计分层等标签没限制，追溯历史订单进行归类时如果限制了就会对不上
join first_order_info b on a.order_id = b.order_id 
)


select * from order_info;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
