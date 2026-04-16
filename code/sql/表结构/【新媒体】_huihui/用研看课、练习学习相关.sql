-- ================================================================
-- 用研汇总SQL（CTE版）—— 正式模板
-- ================================================================
-- 基于：用研汇总SQL-CTE版.sql
--
-- 【日期规则】
-- dws.topic_user_info  → 固定 T-1（动态取昨天）
-- 其他 fact 表          → 默认近一年（动态），用户指定时间段时由执行者替换
--
-- 【用户范围】在 uid_list 中加 WHERE u_user IN (...) 过滤
-- 【执行方式】内存拼接执行，不生成中间文件
-- ================================================================

WITH

uid_list AS (
    SELECT
        u_user,
        if(phone is null, phone, if(phone rlike "^\\d+$", phone, cast(unbase64(phone) as string))) AS phone,
        substring(regist_time, 1, 10) AS regist_time,
        nickname,
        grade,
        channel
    FROM dw.dim_user
),

pad_active AS (
    SELECT
        u_user,
        is_use_ycpad
    FROM aws.mid_active_user_os_day
    WHERE day BETWEEN cast(date_format(date_sub(current_date(), 365), 'yyyyMMdd') as int)
                  AND cast(date_format(date_sub(current_date(), 1), 'yyyyMMdd') as int)
      AND is_use_ycpad = '1'
    GROUP BY 1, 2
),

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
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),

channel_label AS (
    SELECT
        u_user,
        concat(label1, '-', label2, '-', label3) AS label
    FROM tmp.wenxinyu_user_type_0416
),

learn_active AS (
    SELECT
        u_user,
        count(topic_id) AS learn_active_cnt
    FROM dw.fact_user_learn_active_detail_day
    WHERE day BETWEEN cast(date_format(date_sub(current_date(), 365), 'yyyyMMdd') as int)
                  AND cast(date_format(date_sub(current_date(), 1), 'yyyyMMdd') as int)
    GROUP BY u_user
),

exercise AS (
    SELECT
        u_user,
        sum(problem_cnt) AS problem_cnt
    FROM dw.fact_user_exercise_day
    WHERE day BETWEEN cast(date_format(date_sub(current_date(), 365), 'yyyyMMdd') as int)
                  AND cast(date_format(date_sub(current_date(), 1), 'yyyyMMdd') as int)
    GROUP BY u_user
),

last_active AS (
    SELECT
        u_user,
        recent_active_day,
        recent_active_days
    FROM dws.topic_user_info
    WHERE day = cast(date_format(date_sub(current_date(), 1), 'yyyyMMdd') as int)
    GROUP BY u_user, recent_active_day, cast(recent_active_day as string)
),

top_watch_subject AS (
    SELECT u_user, subject_name AS top_watch_subject_name, watch_cnt AS top_watch_subject_cnt
    FROM (
        SELECT
            u_user,
            subject_name,
            watch_cnt,
            row_number() over(partition by u_user order by watch_cnt desc) AS rk
        FROM (
            SELECT
                u_user,
                substr(subject_name, 4, 2) AS subject_name,
                sum(cast(watch_cnt as bigint)) AS watch_cnt
            FROM (
                SELECT
                    u_user,
                    regexp_replace(split(subject_info, ':')[0], '"', '') AS subject_name,
                    regexp_replace(split(subject_info, ':')[1], '"', '') AS watch_cnt
                FROM (
                    SELECT
                        u_user,
                        total_subject_watch_video_cnt,
                        split(substr(total_subject_watch_video_cnt, 2, length(total_subject_watch_video_cnt) - 2), ',') AS subject_list
                    FROM dws.topic_user_info
                    WHERE day = cast(date_format(date_sub(current_date(), 1), 'yyyyMMdd') as int)
                ) a
                LATERAL VIEW explode(subject_list) col AS subject_info
            ) a
            GROUP BY u_user, substr(subject_name, 4, 2)
        ) b11
    ) b111
    WHERE b111.rk = 1
),

top_exercise_subject AS (
    SELECT u_user, subject_name_end AS top_exercise_subject_name
    FROM (
        SELECT
            u_user,
            subject_name,
            CASE
                WHEN subject_name = '1'  THEN '数学'
                WHEN subject_name = '2'  THEN '物理'
                WHEN subject_name = '3'  THEN '语文'
                WHEN subject_name = '4'  THEN '化学'
                WHEN subject_name = '5'  THEN '英语'
                WHEN subject_name = '6'  THEN '生物'
                WHEN subject_name = '7'  THEN '地理'
                WHEN subject_name = '8'  THEN '自然'
                WHEN subject_name = '9'  THEN '地球'
                WHEN subject_name = '10' THEN '实验'
                WHEN subject_name = '11' THEN '道德与法治'
                WHEN subject_name = '12' THEN '历史'
                WHEN subject_name = '13' THEN '信息技术'
                WHEN subject_name = '14' THEN '理化生实验'
                WHEN subject_name = '15' THEN '体育与健康'
                WHEN subject_name = '16' THEN '素养'
                WHEN subject_name = '17' THEN '学前启蒙'
                WHEN subject_name = '18' THEN '学习方法'
                WHEN subject_name = '19' THEN '科学'
            END AS subject_name_end,
            do_cnt,
            rk
        FROM (
            SELECT
                u_user,
                subject_name,
                do_cnt,
                row_number() over(partition by u_user order by do_cnt desc) AS rk
            FROM (
                SELECT
                    u_user,
                    substr(subject_name, 3, 1) AS subject_name,
                    sum(cast(watch_cnt as bigint)) AS do_cnt
                FROM (
                    SELECT
                        u_user,
                        regexp_replace(split(subject_info, ':')[0], '"', '') AS subject_name,
                        regexp_replace(split(subject_info, ':')[1], '"', '') AS watch_cnt
                    FROM (
                        SELECT
                            u_user,
                            mid_total_problem_cnt,
                            split(substr(mid_total_problem_cnt, 2, length(mid_total_problem_cnt) - 2), ',') AS subject_list
                        FROM dws.topic_user_info
                        WHERE day = cast(date_format(date_sub(current_date(), 1), 'yyyyMMdd') as int)
                    ) a
                    LATERAL VIEW explode(subject_list) col AS subject_info
                ) a
                WHERE subject_name <> 'total'
                GROUP BY u_user, substr(subject_name, 3, 1)
            ) a1
        ) a11
        WHERE rk = 1
    ) a111
)

SELECT
    u.u_user , --用户id
    u.phone, --手机号
    u.regist_time, --注册时间
    u.nickname, --用户昵称
    u.grade, --学段
    u.channel, --注册渠道
    p.is_use_ycpad                     AS is_pad_active, --学习机标签
    sum(wv.learn_duration)             AS watch_duration_s, --看课时长
    count(distinct wv.date_sk)         AS watch_days, --看课天数
    count(distinct wv.watch_id)        AS watch_cnt, --看课次数
    count(case when wv.is_finish = true then wv.watch_id end)      AS finish_cnt, --看课完播次数
    count(case when wv.finish_type_level > 6 then wv.watch_id end) AS finish_level_cnt, --认真看课次数
    w.label                            AS channel_label, --投放注册来源（一级二级三级标签拼接的）
    la.learn_active_cnt,  --学习活跃次数
    ex.problem_cnt,  --做题次数
    a1.recent_active_day, --最近一次访问活跃时间
    a1.recent_active_days, --距离上次访问活跃天数
    tws.top_watch_subject_name, --看课最多的学科
    tws.top_watch_subject_cnt, --看课最多额学科次数
    tes.top_exercise_subject_name --做题最多的学科
FROM uid_list u
LEFT JOIN pad_active p               ON u.u_user = p.u_user
LEFT JOIN watch_video wv             ON u.u_user = wv.u_user
LEFT JOIN channel_label w            ON u.u_user = w.u_user
LEFT JOIN learn_active la            ON u.u_user = la.u_user
LEFT JOIN exercise ex                ON u.u_user = ex.u_user
LEFT JOIN last_active a1             ON u.u_user = a1.u_user
LEFT JOIN top_watch_subject tws      ON u.u_user = tws.u_user
LEFT JOIN top_exercise_subject tes   ON u.u_user = tes.u_user
GROUP BY
    u.u_user,
    u.phone,
    u.regist_time,
    u.nickname,
    u.grade,
    u.channel,
    p.is_use_ycpad,
    w.label,
    la.learn_active_cnt,
    ex.problem_cnt,
    a1.recent_active_day,
    a1.recent_active_days,
    tws.top_watch_subject_name,
    tws.top_watch_subject_cnt,
    tes.top_exercise_subject_name

