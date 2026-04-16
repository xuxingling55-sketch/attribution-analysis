-- ================================================================
-- dws.topic_order_detail 相关SQL汇总（合并版）
-- ================================================================
-- 合并内容：
--   1. 购课类型判断（组合品/续购/积木块/零售品）
--   2. 一段时间内是否在新媒体下过单
--   3. 历史消费金额（含小学学段拆分）
--   4. 历史上是否在新媒体下过单
-- 备注：组合品含：组合品、升单品、毕业年级到期品
-- ================================================================

WITH

-- 1、购课类型 + 一段时间内新媒体标签（指定时间范围，wfs > 0.5）
order_type AS (
    SELECT
        u_user,
        max(case when business_good_kind_name_level_1 = '组合品' then '是' end)   AS `组合商品uid`,
        max(case when business_good_kind_name_level_1 = '续购' then '是' end)     AS `续购商品uid`,
        max(case when business_good_kind_name_level_1 = '积木块' then '是' end)   AS `积木块uid`,
        max(case when business_good_kind_name_level_1 = '零售商品' then '是' end) AS `零售品uid`,
        max(case when is_xinmeiti = 1 then '是' end) AS `一段时间内是否在新媒体下过单`
    FROM (
        SELECT
            u_user,
            business_good_kind_name_level_1,
            sum(sub_amount) - sum(total_refund_amt) AS wfs,
            max(case when array_contains(team_ids, '5') then 1 else 0 end) AS is_xinmeiti
        FROM dws.topic_order_detail
        WHERE substring(paid_time, 1, 7) >= '2025-03'
          AND substring(paid_time, 1, 7) <= '2025-12'
          AND status = '支付成功'
        GROUP BY u_user, business_good_kind_name_level_1
        HAVING sum(sub_amount) - sum(total_refund_amt) > 0.5
    ) t
    GROUP BY u_user
),

-- 2、历史消费金额 + 历史新媒体标签（全量订单）
history_consume AS (
    SELECT
        u_user,
        sum(sub_amount) - sum(total_refund_amt) AS `历史消费金额`
        
    FROM dws.topic_order_detail
    WHERE status = '支付成功'
    GROUP BY u_user
)

SELECT
    hc.u_user,
    ot.`组合商品uid`,
    ot.`续购商品uid`,
    ot.`积木块uid`,
    ot.`零售品uid`,
    ot.`一段时间内是否在新媒体下过单`,
    hc.`历史消费金额`,
    hc.`历史上是否在新媒体下过单`
FROM history_consume hc
LEFT JOIN order_type ot ON hc.u_user = ot.u_user
