-- ================================================================
-- 用研-分学科学段看课/做题 汇总SQL
-- ================================================================
-- 基于：用研看课、练习学习相关.sql
-- 变更：去掉 top_watch_subject / top_exercise_subject / last_active
--       加入 dw.dim_term 按学科、学段拆分看课指标
--
-- 【日期规则】fact 表默认近一年（动态），可按需替换
-- 【用户范围】在 uid_list 中加 WHERE u_user IN (...) 过滤
-- ================================================================

WITH

-- 0、用户列表（支持 u_user / phone / onion_id 匹配）
uid_list AS (
    SELECT
        u_user,
        if(phone is null, phone, if(phone rlike "^\\d+$", phone, cast(unbase64(phone) as string))) AS phone,
        onion_id
    FROM dw.dim_user
    -- WHERE u_user IN ('xxx')
    -- WHERE phone IN ('13800138000')
    -- WHERE onion_id IN ('xxx')
),

-- 1、看课情况
watch_video AS (
    SELECT
        topic_sk,
        learn_duration,
        date_sk,
        watch_id,
        u_user,
        finish_type_level,
        is_finish
    FROM dw.fact_user_watch_video_day
    WHERE day BETWEEN cast(date_format(date_sub(current_date(), 365), 'yyyyMMdd') as int)
                  AND cast(date_format(date_sub(current_date(), 1), 'yyyyMMdd') as int)
    --AND u_user = '58e4fc08bcfa0105fb03edd9'
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),

-- 2、课程版本
dim_term AS (
    SELECT
        term_sk,
        publisher_name,
        publisher_id,
        semester_name,
        subject_name
    FROM dw.dim_term
    GROUP BY 1, 2, 3, 4, 5
)

SELECT
    wv.u_user,
    u.phone,
    u.onion_id,
    dt.publisher_name  AS `观看时的版本`,
    dt.publisher_id    AS `观看时的版本id`,
    dt.semester_name   AS `学段`,
    dt.subject_name    AS `学科`,
    sum(wv.learn_duration)             AS `观看时长秒`,
    count(distinct wv.date_sk)         AS `观看天数`,
    count(distinct wv.watch_id)        AS `观看次数`,
    count(case when wv.is_finish = true then wv.watch_id end)      AS `is_finish看完次数`,
    count(case when wv.finish_type_level > 6 then wv.watch_id end) AS `认真看课次数`
FROM watch_video wv
JOIN dim_term dt ON wv.topic_sk = dt.term_sk
JOIN uid_list u  ON wv.u_user = u.u_user
GROUP BY 1, 2, 3, 4, 5, 6, 7