"""
归因分析 SQL 查询模块
包含 6 大假设维度的标准查询
"""
from .db import run_query
import pandas as pd


# ─────────────────────────────────────────────
# 基线查询
# ─────────────────────────────────────────────

def query_active_users_weekly(cursor, grade: str, weeks: list) -> pd.DataFrame:
    """
    查询近N周活跃人数（活跃宽表）
    weeks: [(label, start_int, end_int), ...]  e.g. [('上周', 20260323, 20260329)]
    """
    conditions = "\n            ".join(
        [f"WHEN day BETWEEN {s} AND {e} THEN '{l}'" for l, s, e in weeks]
    )
    min_day = min(s for _, s, _ in weeks)
    max_day = max(e for _, _, e in weeks)

    sql = f"""
    SELECT
        CASE {conditions} END AS week_label,
        COUNT(DISTINCT u_user) AS active_users
    FROM dws.topic_user_active_detail_day
    WHERE product_id = '01'
        AND client_os IN ('android', 'ios', 'harmony')
        AND active_user_attribution IN ('中学用户', '小学用户', 'c')
        AND is_test_user = 0
        AND mid_grade = '{grade}'
        AND day BETWEEN {min_day} AND {max_day}
    GROUP BY 1
    """
    return run_query(cursor, sql, f"{grade} 各周活跃人数")


def query_paid_users_weekly(cursor, grade: str, weeks: list) -> pd.DataFrame:
    """
    查询近N周付费人数 + GMV + 客单价（订单表）
    """
    conditions = "\n            ".join(
        [f"WHEN paid_time >= '{l_s}' AND paid_time < '{l_e}' THEN '{l}'"
         for l, l_s, l_e in weeks]
    )
    min_date = min(s for _, s, _ in weeks)
    max_date = max(e for _, _, e in weeks)

    sql = f"""
    SELECT
        CASE {conditions} END AS week_label,
        COUNT(DISTINCT u_user) AS paid_users,
        ROUND(SUM(sub_amount), 0) AS total_gmv,
        ROUND(SUM(sub_amount) / NULLIF(COUNT(DISTINCT u_user), 0), 1) AS avg_order_value
    FROM dws.topic_order_detail
    WHERE mid_grade = '{grade}'
        AND sub_amount >= 39
        AND paid_time >= '{min_date}'
        AND paid_time < '{max_date}'
    GROUP BY 1
    """
    return run_query(cursor, sql, f"{grade} 各周付费人数/GMV/客单价")


# ─────────────────────────────────────────────
# H1 流量/线索结构
# ─────────────────────────────────────────────

def query_clue_volume(cursor, grade: str, date_start: str, date_end: str) -> pd.DataFrame:
    """H1.1 线索领取量变化"""
    sql = f"""
    SELECT
        CASE
            WHEN created_at >= '{date_start}' AND created_at < '{date_end}' THEN '当期'
            ELSE '对比期'
        END AS period,
        COUNT(DISTINCT info_uuid) AS clue_cnt,
        COUNT(DISTINCT user_id) AS clue_user_cnt
    FROM aws.clue_info
    WHERE clue_grade = '{grade}'
        AND created_at >= '{date_start}'
        AND created_at < '{date_end}'
    GROUP BY 1
    """
    return run_query(cursor, sql, f"H1.1 {grade} 线索领取量")


def query_clue_source(cursor, grade: str, week_cases: str, date_start: str, date_end: str) -> pd.DataFrame:
    """H1.2 线索来源结构变化"""
    sql = f"""
    SELECT
        CASE {week_cases} END AS week_label,
        clue_source,
        COUNT(DISTINCT info_uuid) AS clue_cnt
    FROM aws.clue_info
    WHERE clue_grade = '{grade}'
        AND created_at >= '{date_start}'
        AND created_at < '{date_end}'
    GROUP BY 1, 2
    ORDER BY 1, clue_cnt DESC
    """
    return run_query(cursor, sql, f"H1.2 {grade} 线索来源结构变化")


# ─────────────────────────────────────────────
# H2 用户结构
# ─────────────────────────────────────────────

def query_user_layer(cursor, grade: str, week_cases: str, min_day: int, max_day: int) -> pd.DataFrame:
    """H2.1 用户分层结构占比变化"""
    sql = f"""
    SELECT
        CASE {week_cases} END AS week_label,
        business_user_pay_status_business AS pay_status,
        COUNT(DISTINCT u_user) AS users
    FROM dws.topic_user_active_detail_day
    WHERE product_id = '01'
        AND client_os IN ('android', 'ios', 'harmony')
        AND active_user_attribution IN ('中学用户', '小学用户', 'c')
        AND is_test_user = 0
        AND mid_grade = '{grade}'
        AND day BETWEEN {min_day} AND {max_day}
    GROUP BY 1, 2
    ORDER BY 1, users DESC
    """
    return run_query(cursor, sql, f"H2.1 {grade} 用户分层结构变化")


# ─────────────────────────────────────────────
# H3 电销执行
# ─────────────────────────────────────────────

def query_sales_performance(cursor, grade: str, week_cases: str, date_start: str, date_end: str) -> pd.DataFrame:
    """H3.1 外呼量/接通率/有效通话率/人效"""
    sql = f"""
    SELECT
        CASE {week_cases} END AS week_label,
        COUNT(DISTINCT info_uuid) AS clue_cnt,
        SUM(call_phone_cnt) AS total_call,
        SUM(call_through_cnt) AS total_through,
        SUM(valid_call_cnt) AS total_valid,
        ROUND(SUM(call_through_cnt) * 100.0 / NULLIF(SUM(call_phone_cnt), 0), 1) AS through_rate_pct,
        ROUND(SUM(valid_call_cnt) * 100.0 / NULLIF(SUM(call_through_cnt), 0), 1) AS valid_rate_pct,
        SUM(paid_cnt) AS total_paid,
        ROUND(SUM(paid_amount), 0) AS total_gmv,
        ROUND(SUM(paid_amount) / NULLIF(SUM(valid_call_cnt), 0), 1) AS gmv_per_valid_call
    FROM aws.clue_info
    WHERE clue_grade = '{grade}'
        AND created_at >= '{date_start}'
        AND created_at < '{date_end}'
    GROUP BY 1
    ORDER BY 1 DESC
    """
    return run_query(cursor, sql, f"H3.1 {grade} 电销执行指标")


def query_workplace_performance(cursor, grade: str, week_cases: str, date_start: str, date_end: str) -> pd.DataFrame:
    """H3.2 职场维度异常"""
    sql = f"""
    SELECT
        CASE {week_cases} END AS week_label,
        workplace_id,
        COUNT(DISTINCT info_uuid) AS clue_cnt,
        SUM(call_phone_cnt) AS total_call,
        ROUND(SUM(call_through_cnt) * 100.0 / NULLIF(SUM(call_phone_cnt), 0), 1) AS through_rate_pct,
        ROUND(SUM(valid_call_cnt) * 100.0 / NULLIF(SUM(call_through_cnt), 0), 1) AS valid_rate_pct,
        SUM(paid_cnt) AS paid_cnt,
        ROUND(SUM(paid_cnt) * 100.0 / NULLIF(COUNT(DISTINCT info_uuid), 0), 2) AS clue_cvr_pct
    FROM aws.clue_info
    WHERE clue_grade = '{grade}'
        AND created_at >= '{date_start}'
        AND created_at < '{date_end}'
    GROUP BY 1, 2
    ORDER BY 1 DESC, clue_cnt DESC
    """
    return run_query(cursor, sql, f"H3.2 {grade} 职场维度对比")


# ─────────────────────────────────────────────
# H4 商品结构
# ─────────────────────────────────────────────

def query_product_mix(cursor, grade: str, week_cases: str, date_start: str, date_end: str) -> pd.DataFrame:
    """H4.1 商品类型结构变化"""
    sql = f"""
    SELECT
        CASE {week_cases} END AS week_label,
        business_good_kind_name_level_1 AS good_type_l1,
        business_good_kind_name_level_2 AS good_type_l2,
        COUNT(DISTINCT u_user) AS paid_users,
        ROUND(SUM(sub_amount), 0) AS gmv,
        ROUND(SUM(sub_amount) / NULLIF(COUNT(DISTINCT u_user), 0), 1) AS aov
    FROM dws.topic_order_detail
    WHERE mid_grade = '{grade}'
        AND sub_amount >= 39
        AND paid_time >= '{date_start}'
        AND paid_time < '{date_end}'
    GROUP BY 1, 2, 3
    ORDER BY 1, gmv DESC
    """
    return run_query(cursor, sql, f"H4.1 {grade} 商品结构变化")
