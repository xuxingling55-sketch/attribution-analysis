# 付费用户在当月转介绍执行情况

sql3 = '''
DROP TABLE IF EXISTS tmp.niyiqiao_referral_operation_month
'''
sql4 = '''
CREATE TABLE  IF NOT EXISTS tmp.niyiqiao_referral_operation_month as (
with t1 as(
-- 基准表：付费用户信息（1用户1月1坐席1条记录，去重）
select distinct
    substr(a.pay_time,1,7) paid_month  -- 付费年月（如2022-05）
    ,case when last_day(substr(a.pay_time,1,10)) >= current_date 
          then date_sub(current_date,1)  -- 当前月：截止到昨天（避免统计未生成数据）
          else last_day(substr(pay_time,1,10)) -- 历史月：截止到付费当月月底
     end last_day  -- 行为统计截止日期（统一为付费月的次月月底）
    ,c.department_name  -- 部门名称
    ,d.regiment_name  -- 团队名称
    ,f.team_name  -- 小组名称
    ,a.worker_id  -- 坐席ID
    ,a.worker_name  -- 坐席姓名
    ,a.user_id paid_user_id  -- 付费用户ID
from aws.crm_order_info a
left join dw.dim_crm_organization as c on a.department_id = c.id  -- 关联部门维度
left join dw.dim_crm_organization as d on a.regiment_id = d.id  -- 关联团队维度
left join dw.dim_crm_organization as f on a.team_id = f.id  -- 关联小组维度
where substr(a.pay_time,1,10) between '2022-05-01' and date_sub(current_date,1)  -- 时间范围：2022-05起至今
    and a.is_test = false  -- 排除测试数据
    and a.in_salary = 1  -- 计入业绩
    and a.worker_id <> 0  -- 排除无效坐席
)

, t2 as (
-- 行为表1：付费用户下载海报（按年月+坐席+用户汇总次数）
select 
    substr(created_at,1,7) download_month  -- 下载年月
    ,worker_id  -- 坐席ID
    ,user_id download_user_id  -- 下载用户ID
    ,count(user_id) download_cnt  -- 单用户当月下载次数
from crm.promotion_poster 
where substr(created_at,1,10) between '2022-05-01' and date_sub(current_date,1)  -- 与t1时间范围一致
    and worker_id <> 0  -- 排除无效坐席
group by substr(created_at,1,7), worker_id, user_id  -- 确保1用户1月1坐席1条记录
)

, t3 as (
-- 行为表2：付费用户当月转介绍拉新（按年月+坐席+用户汇总新用户数）
select 
    substr(created_at,1,7) referral_month  -- 转介绍发生年月
    ,worker_id  -- 坐席ID
    ,old_user_id referred_user_id  -- 转介绍人ID
    ,count(distinct user_id) referred_cnt  -- 单用户当月拉新数
from crm.new_user 
where substr(created_at,1,10) between '2022-05-01' and date_sub(current_date,1)  -- 与t1时间范围一致
    and channel = 2  -- 限定转介绍渠道
group by substr(created_at,1,7), worker_id, old_user_id  -- 确保1用户1月1坐席1条记录
)

,t4 as(
-- 行为表3：付费用户发朋友圈（按年月+用户去重）
select 
    distinct substr(created_at,1,7) moments_month  -- 发圈年月
    ,user_id moments_user_id  -- 发圈用户ID
from crm.point_log_all 
where substr(created_at,1,10) between '2022-05-01' and date_sub(current_date,1)  -- 与t1时间范围一致
    and point_type=1  -- 限定朋友圈分享积分类型
)

, t5 as(
-- 转化表：付费用户当月拉新的新用户，在当月完成付费转化
SELECT 
    substr(m.created_at,1,7) referral_month  -- 转介绍发生年月
    ,substr(n.pay_time,1,7) paid_month  -- 新用户付费年月
    ,m.worker_id  -- 坐席ID
    ,m.old_user_id  -- 转介绍人ID
    ,count(distinct n.user_id) referred_paid_cnt  -- 转化的新用户数（去重）
    ,count(n.order_id) referred_paid_order_cnt  -- 转化订单总数
    ,sum(n.amount) referred_paid_amount  -- 转化总金额
FROM crm.new_user m  -- 转介绍记录主表
left join aws.crm_order_info n  -- 新用户订单表
    on m.user_id = n.user_id  -- 新用户ID匹配
    and m.worker_id = n.worker_id  -- 坐席ID匹配
    and n.pay_time > m.created_at  -- 付费时间在转介绍之后
    and substr(add_months(m.created_at,6),1,19) > substr(n.pay_time,1,19)  -- 转介绍后6个月内付费（宽口径，外层关联限定2个月）
    and n.status = '支付成功'  -- 订单状态
    and n.in_salary = 1  -- 计入业绩
    and n.is_test = false  -- 排除测试数据
    and n.worker_id <> 0  -- 排除无效坐席
    and substr(n.pay_time,1,10) >= '2022-05-01'  -- 订单时间范围
WHERE m.channel = 2  -- 限定转介绍渠道
    and substr(m.created_at,1,10) between '2022-05-01' and date_sub(current_date,1)  -- 与t1时间范围一致
group by substr(m.created_at,1,7), substr(n.pay_time,1,7), m.worker_id, m.old_user_id
)

, t6 as (
-- 汇总表：付费用户在付费月的行为明细
SELECT 
    t1.paid_month,
    t1.last_day,
    t1.department_name,
    t1.regiment_name,
    t1.team_name,
    t1.worker_id,
    t1.worker_name,
    t1.paid_user_id,
    -- 是否下载海报：当月有下载则标记“是”，无则空
    max(case when t2.download_user_id is not null then '是' else '' end) is_download,
    -- 下载总次数：仅当月的下载次数（无需累加，t2已按当月分组）
    sum(t2.download_cnt) download_cnt,
    -- 是否发朋友圈：当月有发圈则标记“是”，无则空
    max(case when t4.moments_user_id is not null then '是' else '' end) is_moments,
    -- 是否拉新：当月有拉新则标记“是”，无则空
    max(case when t3.referred_user_id is not null then '是' else '' end) is_paid,
    -- 拉新总用户数：仅当月的拉新数（无需累加，t3已按当月分组）
    sum(t3.referred_cnt) referred_cnt
FROM t1
left join t2  -- 关联当月下载行为：仅匹配“付费年月=下载年月”
    ON t1.paid_month = t2.download_month AND t1.worker_id = t2.worker_id AND t1.paid_user_id = t2.download_user_id
left join t4  -- 关联当月发圈行为：仅匹配“付费年月=发圈年月”
    ON t1.paid_month = t4.moments_month AND t1.paid_user_id = t4.moments_user_id
left join t3 -- 关联当月拉新行为：仅匹配“付费年月=转介绍年月”
    ON t1.paid_month = t3.referral_month AND t1.worker_id = t3.worker_id AND t1.paid_user_id = t3.referred_user_id
group by t1.paid_month, t1.last_day, t1.department_name, t1.regiment_name, 
         t1.team_name, t1.worker_id, t1.worker_name, t1.paid_user_id
)

-- 最终统计：按部门/团队/坐席汇总“付费当月行为及当月转化”数据
SELECT 
    t6.paid_month  -- 付费年月
    ,t6.last_day  -- 统计截止日期（付费当月月底/当前月昨天）
    ,t6.department_name  -- 部门名称
    ,t6.regiment_name  -- 团队名称
    ,t6.team_name  -- 小组名称
    ,t6.worker_id  -- 坐席ID
    ,t6.worker_name  -- 坐席姓名
    ,count(distinct t6.paid_user_id) paid_user_cnt  -- 付费用户总量
    ,count(distinct case when t6.is_download = '是' then t6.paid_user_id end ) download_user_cnt  -- 付费月有下载行为的用户数
    ,sum(t6.download_cnt) download_cnt  -- 付费月的总下载次数
    ,count(distinct case when t6.is_moments = '是'  then t6.paid_user_id end ) moments_user_cnt  -- 付费月有发圈行为的用户数
    ,count(distinct case when t6.is_paid = '是'  then t6.paid_user_id end ) referral_user_cnt  -- 付费月有拉新行为的用户数
    ,ifnull(sum(t6.referred_cnt),0) referred_user_cnt  -- 付费月的总拉新用户数
    ,ifnull(sum(t5.referred_paid_cnt),0) referred_paid_cnt  -- 拉新用户中在付费月转化的用户数
    ,ifnull(sum(t5.referred_paid_order_cnt),0) referred_paid_order_cnt  -- 拉新用户在付费月的转化订单数
    ,ifnull(sum(t5.referred_paid_amount),0) referred_paid_amount  -- 拉新用户在付费月的转化总金额
FROM t6
left join t5  -- 关联转介绍转化数据（限定转化时间：付费月）
    ON t5.referral_month = t6.paid_month AND t5.paid_month = t6.paid_month AND t6.worker_id = t5.worker_id  AND t6.paid_user_id = t5.old_user_id
group by t6.paid_month, t6.last_day, t6.department_name, t6.regiment_name, 
         t6.team_name, t6.worker_id, t6.worker_name

         )