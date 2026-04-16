DROP TABLE IF EXISTS tmp.fanyu_wecomAI_regist_retention_day；
CREATE TABLE  IF NOT EXISTS tmp.fanyu_wecomAI_regist_retention_day AS(
WITH t0 AS ( -- 分组用户（同 sql04）
  SELECT
    substr(create_time, 1, 10) AS create_day,
    substr(create_time, 1, 19) AS create_time,
    uid AS u_user,
    ab_code,
    CASE WHEN ab_code = 'a' THEN '实验组'
         WHEN ab_code = 'b' THEN '对照组'
         WHEN ab_code = 'c' THEN 'left组'
         ELSE '' END AS group_code
  FROM xlab.sample_hour
  WHERE substr(create_time, 1, 10) BETWEEN '2026-02-09' AND date_sub(current_date(), 1)
    AND group_code IN ('cdacc7962750c4a86c184c7d989d454a')
  GROUP BY 1, 2, 3, 4, 5
),

t1 AS ( -- 用户信息（同 sql04）
  SELECT DISTINCT
    TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(CAST(day AS STRING), 'yyyyMMdd'))) AS day,
    u_user,
    grade,
    CASE WHEN stage_id = 1 THEN '小学'
         WHEN stage_id = 2 THEN '初中'
         WHEN stage_id = 3 THEN '高中'
         WHEN stage_id = 4 THEN '中职'
         WHEN stage_id = 5 THEN '启蒙'
         ELSE '' END AS stage,
    CASE WHEN role = 'student' AND is_parents = false THEN '纯学生'
         WHEN role = 'student' AND is_parents = true THEN '学生家长共用'
         WHEN real_identity = 'parents' THEN '纯家长'
         ELSE '' END AS identity,
    CASE WHEN role = 'student' AND is_parents = false THEN '学生路径'
         WHEN role = 'student' AND is_parents = true THEN '学生路径'
         WHEN real_identity = 'parents' THEN '家长路径'
         ELSE '' END AS role
  FROM dw.dim_user_his
  WHERE day >= 20260209
    AND substr(regist_time, 1, 10) BETWEEN '2026-02-09' AND date_sub(current_date(), 1)
    AND user_attribution IN ('中学业务', '小学业务', 'c')
),

y1 AS ( -- 分组用户信息，带 create_time 供订单关联
  SELECT
    t0.create_day,
    t0.create_time,
    t0.u_user,
    ifnull(t1.role, '') AS role,
    t0.group_code,
    ifnull(t1.grade, '') AS grade,
    ifnull(t1.stage, '') AS stage,
    ifnull(t1.identity, '') AS identity
  FROM (
    SELECT create_day, u_user, group_code, min(create_time) AS create_time
    FROM t0
    GROUP BY 1, 2, 3
  ) t0
  LEFT JOIN t1 ON t0.u_user = t1.u_user AND t0.create_day = t1.day
),

y2 AS ( -- 活跃用户（同 sql04）
  SELECT
    u_user,
    TO_DATE(FROM_UNIXTIME(UNIX_TIMESTAMP(CAST(day AS STRING), 'yyyyMMdd'))) AS active_date
  FROM aws.mid_active_user_os_day
  WHERE day >= 20260209
    AND active_user IS NOT NULL
  GROUP BY 1, 2
),

ord AS ( -- 转化订单（同 funnel 口径）
  SELECT
    substr(pay_time, 1, 10) AS pay_day,
    substr(pay_time, 1, 19) AS pay_time,
    order_id,
    user_id,
    amount
  FROM aws.crm_order_info
  WHERE substr(pay_time, 1, 10) BETWEEN '2026-02-09' AND date_sub(current_date(), 1)
    AND workplace_id IN (4, 400, 702)
    AND regiment_id NOT IN (0, 303, 546)
    AND worker_id <> 0
    AND in_salary = 1
    AND is_test = false
),

-- 留存指标：y1 × y2，仅涉及 COUNT DISTINCT，不受扇出影响
ret AS (
  SELECT
    y1.create_day, y1.role, y1.group_code, y1.grade, y1.stage, y1.identity,
    count(DISTINCT y1.u_user) AS user_num,
    count(DISTINCT CASE WHEN y2.active_date = y1.create_day THEN y2.u_user END) AS user_active_num,
    count(DISTINCT CASE WHEN y2.active_date = date_add(y1.create_day, 1) THEN y2.u_user END) AS user_nextday_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 2) THEN y2.u_user END) AS user_2day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 3) THEN y2.u_user END) AS user_3day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 4) THEN y2.u_user END) AS user_4day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 5) THEN y2.u_user END) AS user_5day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 6) THEN y2.u_user END) AS user_6day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 7) THEN y2.u_user END) AS user_7day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 8) THEN y2.u_user END) AS user_8day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 9) THEN y2.u_user END) AS user_9day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 10) THEN y2.u_user END) AS user_10day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 11) THEN y2.u_user END) AS user_11day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 12) THEN y2.u_user END) AS user_12day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 13) THEN y2.u_user END) AS user_13day_num,
    count(DISTINCT CASE WHEN y2.active_date BETWEEN date_add(y1.create_day, 1) AND date_add(y1.create_day, 14) THEN y2.u_user END) AS user_14day_num
  FROM y1
  LEFT JOIN y2 ON y1.u_user = y2.u_user
  WHERE y1.create_day BETWEEN '2026-02-09' AND date_sub(current_date(), 1)
  GROUP BY 1, 2, 3, 4, 5, 6
),

-- 转化指标：y1 × ord，独立聚合避免 y2 扇出
conv AS (
  SELECT
    y1.create_day, y1.role, y1.group_code, y1.grade, y1.stage, y1.identity,

    count(DISTINCT CASE WHEN ord.pay_day = y1.create_day THEN y1.u_user END) AS paid_cnt,
    count(DISTINCT CASE WHEN ord.pay_day <= date_add(y1.create_day, 3) THEN y1.u_user END) AS paid_cnt_3d,
    count(DISTINCT CASE WHEN ord.pay_day <= date_add(y1.create_day, 7) THEN y1.u_user END) AS paid_cnt_7d,
    count(DISTINCT CASE WHEN ord.pay_day <= date_add(y1.create_day, 14) THEN y1.u_user END) AS paid_cnt_14d,
    count(DISTINCT CASE WHEN ord.pay_day <= date_add(y1.create_day, 30) THEN y1.u_user END) AS paid_cnt_30d,

    sum(CASE WHEN substr(ord.pay_time, 1, 10) = y1.create_day THEN ord.amount END) AS paid_amount,
    sum(CASE WHEN substr(ord.pay_time, 1, 10) <= date_add(y1.create_day, 3) THEN ord.amount END) AS paid_amount_3d,
    sum(CASE WHEN substr(ord.pay_time, 1, 10) <= date_add(y1.create_day, 7) THEN ord.amount END) AS paid_amount_7d,
    sum(CASE WHEN substr(ord.pay_time, 1, 10) <= date_add(y1.create_day, 14) THEN ord.amount END) AS paid_amount_14d,
    sum(CASE WHEN substr(ord.pay_time, 1, 10) <= date_add(y1.create_day, 30) THEN ord.amount END) AS paid_amount_30d
  FROM y1
  LEFT JOIN ord ON y1.u_user = ord.user_id AND ord.pay_time > y1.create_time
  WHERE y1.create_day BETWEEN '2026-02-09' AND date_sub(current_date(), 1)
  GROUP BY 1, 2, 3, 4, 5, 6
)

SELECT
  ret.create_day,
  ret.role,
  ret.group_code,
  ret.grade,
  ret.stage,
  ret.identity,
  ret.user_num,
  ret.user_active_num,
  ret.user_nextday_num,
  ret.user_2day_num,
  ret.user_3day_num,
  ret.user_4day_num,
  ret.user_5day_num,
  ret.user_6day_num,
  ret.user_7day_num,
  ret.user_8day_num,
  ret.user_9day_num,
  ret.user_10day_num,
  ret.user_11day_num,
  ret.user_12day_num,
  ret.user_13day_num,
  ret.user_14day_num,
  conv.paid_cnt,
  conv.paid_cnt_3d,
  conv.paid_cnt_7d,
  conv.paid_cnt_14d,
  conv.paid_cnt_30d,
  conv.paid_amount,
  conv.paid_amount_3d,
  conv.paid_amount_7d,
  conv.paid_amount_14d,
  conv.paid_amount_30d
FROM ret
LEFT JOIN conv
  ON ret.create_day = conv.create_day
  AND ret.role = conv.role
  AND ret.group_code = conv.group_code
  AND ret.grade = conv.grade
  AND ret.stage = conv.stage
  AND ret.identity = conv.identity
)