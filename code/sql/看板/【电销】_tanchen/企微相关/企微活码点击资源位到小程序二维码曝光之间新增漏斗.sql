-- Funnel: telesales wecom drainage | resource entrance click -> transition page -> mini program -> wecom QR exposure
-- Period: 202603 | dedup by user
-- Join logic: use click_entrance_user from aws table as base user, join each step by user + day
-- Source:
--   step1 (entrance click)  : aws.user_pay_process_add_wechat_day -> click_entrance_user
--   step2 (transition page) : events.frontend_event_orc           -> enterOpenWechatTransitionPage
--   step3 (mini program)    : events.frontend_event_orc           -> enterWeComAddMiniProgramHomePage
--   step4 (wecom QR expose) : aws.user_pay_process_add_wechat_day -> get_wechat_user

WITH

-- base: users who clicked resource entrance (telesales drainage, valid task_id)
base AS (
    SELECT
        day
        ,click_entrance_user    AS u_user
        ,get_wechat_user
    FROM aws.user_pay_process_add_wechat_day
    WHERE day BETWEEN 20260301 AND 20260331
        AND click_entrance_user IS NOT NULL
        AND task_id <> 'undefined'
),

-- step2: transition page exposure (enterOpenWechatTransitionPage)
-- remove page_type filter if this event does not carry page_type field
transition_page AS (
    SELECT DISTINCT
        day
        ,u_user
    FROM events.frontend_event_orc
    WHERE day BETWEEN 20260301 AND 20260331
        AND event_type  = 'enter'
        AND event_key   = 'enterOpenWechatTransitionPage'
        AND LENGTH(u_user) > 0
        AND LENGTH(task_id) > 0
),

-- step3: enter mini program (enterWeComAddMiniProgramHomePage)
-- remove page_type filter if this event does not carry page_type field
mini_program AS (
    SELECT DISTINCT
        day
        ,u_user
    FROM events.frontend_event_orc
    WHERE day BETWEEN 20260301 AND 20260331
        AND event_type  = 'enter'
        AND event_key   = 'enterWeComAddMiniProgramHomePage'
        AND LENGTH(u_user) > 0
        AND LENGTH(task_id) > 0
)

SELECT
    DATE_FORMAT(STR_TO_DATE(CAST(a.day AS VARCHAR), '%Y%m%d'), '%Y-%m-%d') AS dt
    ,COUNT(DISTINCT a.u_user)                                               AS click_entrance_cnt
    ,COUNT(DISTINCT CASE WHEN b.u_user IS NOT NULL THEN a.u_user END)       AS transition_page_cnt
    ,COUNT(DISTINCT CASE WHEN c.u_user IS NOT NULL THEN a.u_user END)       AS mini_program_cnt
    ,COUNT(DISTINCT CASE WHEN a.get_wechat_user IS NOT NULL
                         THEN a.u_user END)                                 AS wecom_qr_cnt
FROM base a
LEFT JOIN transition_page b ON a.day = b.day AND a.u_user = b.u_user
LEFT JOIN mini_program    c ON a.day = c.day AND a.u_user = c.u_user
GROUP BY a.day
ORDER BY a.day

-- 2026-03-20 | init: telesales wecom drainage funnel, user+day join