"""
归因分析 AI 工作流 — 主入口

用法（命令行参数）：
  python main.py \
    --ssh-host 1.2.3.4 --ssh-user master --ssh-pass xxx \
    --db-host 10.0.0.1 --db-port 10010 --db-user me --db-pass yyy \
    --grade 九年级 \
    --anomaly "上周9年级转化率和客单价都跌了" \
    --weeks "上周,20260323,20260329,2026-03-23,2026-03-30" \
           "上上周,20260316,20260322,2026-03-16,2026-03-23" \
           "3周前,20260309,20260315,2026-03-09,2026-03-16" \
           "4周前,20260302,20260308,2026-03-02,2026-03-09"

每个 --weeks 条目格式：标签,日期int开始,日期int结束,日期str开始,日期str结束
"""
import sys
import os
import argparse

sys.path.insert(0, os.path.dirname(__file__))

from src.db import DBConfig, get_cursor, test_connection
from src.queries import (
    query_active_users_weekly,
    query_paid_users_weekly,
    query_clue_volume,
    query_clue_source,
    query_user_layer,
    query_sales_performance,
    query_workplace_performance,
    query_product_mix,
)


def parse_args():
    p = argparse.ArgumentParser(description="归因分析 AI 工作流")
    # 数据库连接
    p.add_argument("--ssh-host",  required=True)
    p.add_argument("--ssh-user",  required=True)
    p.add_argument("--ssh-pass",  required=True)
    p.add_argument("--db-host",   required=True)
    p.add_argument("--db-port",   type=int, default=10010)
    p.add_argument("--db-user",   required=True)
    p.add_argument("--db-pass",   required=True)
    # 分析参数
    p.add_argument("--grade",    required=True, help="年级，如：九年级")
    p.add_argument("--anomaly",  required=True, help="异动描述")
    p.add_argument("--weeks",    required=True, nargs="+",
                   help="每条格式：标签,int开始,int结束,str开始,str结束")
    return p.parse_args()


def parse_weeks(weeks_raw):
    """把命令行传入的周期字符串解析成两种格式"""
    weeks_int = []
    weeks_str = []
    for w in weeks_raw:
        parts = w.split(",")
        label, d_int_s, d_int_e, d_str_s, d_str_e = parts
        weeks_int.append((label, int(d_int_s), int(d_int_e)))
        weeks_str.append((label, d_str_s, d_str_e))
    return weeks_int, weeks_str


def print_section(title):
    print(f"\n{'='*60}\n【{title}】\n{'='*60}")


def main():
    args = parse_args()

    config = DBConfig(
        ssh_host    = args.ssh_host,
        ssh_user    = args.ssh_user,
        ssh_password= args.ssh_pass,
        db_host     = args.db_host,
        db_port     = args.db_port,
        db_user     = args.db_user,
        db_pass     = args.db_pass,
    )

    weeks_int, weeks_str = parse_weeks(args.weeks)

    WEEK_CASES_STR = "\n        ".join(
        [f"WHEN created_at >= '{s}' AND created_at < '{e}' THEN '{l}'"
         for l, s, e in weeks_str]
    )
    WEEK_CASES_INT = "\n        ".join(
        [f"WHEN day BETWEEN {s} AND {e} THEN '{l}'"
         for l, s, e in weeks_int]
    )

    print(f"\n{'='*60}")
    print(f"归因分析工作流启动")
    print(f"异动描述：{args.anomaly}")
    print(f"分析维度：{args.grade}")
    print(f"时间窗口：{[l for l,*_ in weeks_int]}")
    print(f"{'='*60}")

    if not test_connection(config):
        sys.exit(1)

    with get_cursor(config) as cursor:

        print_section("Step 1 · 基线数据：活跃人数 + 付费/GMV/客单价")
        query_active_users_weekly(cursor, args.grade, weeks_int)
        query_paid_users_weekly(cursor, args.grade, weeks_str)

        print_section("Step 2 · H1 流量/线索结构")
        query_clue_volume(
            cursor, args.grade,
            date_start=weeks_str[-1][1],
            date_end=weeks_str[0][2],
        )
        query_clue_source(
            cursor, args.grade, WEEK_CASES_STR,
            date_start=weeks_str[-1][1],
            date_end=weeks_str[0][2],
        )

        print_section("Step 3 · H2 用户结构")
        min_day = weeks_int[-1][1]
        max_day = weeks_int[0][2]
        query_user_layer(cursor, args.grade, WEEK_CASES_INT, min_day, max_day)

        print_section("Step 4 · H3 电销执行")
        query_sales_performance(
            cursor, args.grade, WEEK_CASES_STR,
            date_start=weeks_str[-1][1],
            date_end=weeks_str[0][2],
        )
        query_workplace_performance(
            cursor, args.grade, WEEK_CASES_STR,
            date_start=weeks_str[-1][1],
            date_end=weeks_str[0][2],
        )

        print_section("Step 5 · H4 商品结构")
        query_product_mix(
            cursor, args.grade, WEEK_CASES_STR,
            date_start=weeks_str[-1][1],
            date_end=weeks_str[0][2],
        )

    print(f"\n{'='*60}")
    print("✅ 数据查询完成，请根据以上数据判断根因。")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
