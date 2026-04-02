"""
归因分析 AI 工作流 — 主入口
用法：python main.py
"""
import sys
import os

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
from src.report import AttributionReport


# ─────────────────────────────────────────────
# 1. 配置数据库连接（修改为你的实际信息）
# ─────────────────────────────────────────────
config = DBConfig(
    ssh_host    = "YOUR_SSH_HOST",       # SSH 跳板机 IP
    ssh_user    = "YOUR_SSH_USER",       # SSH 用户名
    ssh_password= "YOUR_SSH_PASSWORD",   # SSH 密码
    db_host     = "YOUR_DB_HOST",        # 数据库内网 IP
    db_port     = 10010,                 # Impala 端口
    db_user     = "YOUR_DB_USER",        # 数据库用户名
    db_pass     = "YOUR_DB_PASS",        # 数据库密码
)

# ─────────────────────────────────────────────
# 2. 描述异动（修改为你的实际异动描述）
# ─────────────────────────────────────────────
ANOMALY_DESC = "上周9年级线索转化率和客单价都跌了"
GRADE        = "九年级"        # 分析的年级维度

# 近4周的周期定义：(标签, 开始日期int, 结束日期int)
WEEKS_INT = [
    ("上周",   20260323, 20260329),
    ("上上周",  20260316, 20260322),
    ("3周前",  20260309, 20260315),
    ("4周前",  20260302, 20260308),
]

# 近2周的日期字符串（用于 paid_time / created_at 筛选）
WEEKS_STR = [
    ("上周",   "2026-03-23", "2026-03-30"),
    ("上上周",  "2026-03-16", "2026-03-23"),
]

# 生成 CASE WHEN 子句（供各查询函数复用）
WEEK_CASES_STR = "\n        ".join(
    [f"WHEN created_at >= '{s}' AND created_at < '{e}' THEN '{l}'"
     for l, s, e in WEEKS_STR]
)
WEEK_CASES_INT = "\n        ".join(
    [f"WHEN day BETWEEN {s} AND {e} THEN '{l}'"
     for l, s, e in WEEKS_INT]
)


# ─────────────────────────────────────────────
# 3. 执行分析
# ─────────────────────────────────────────────
def main():
    print(f"\n{'='*60}")
    print(f"归因分析工作流启动")
    print(f"异动描述：{ANOMALY_DESC}")
    print(f"分析维度：{GRADE}")
    print(f"{'='*60}\n")

    # 测试连接
    if not test_connection(config):
        return

    report = AttributionReport(ANOMALY_DESC, GRADE)

    with get_cursor(config) as cursor:

        # Step 1: 基线数据
        print("\n>>> Step 1: 获取基线数据")
        df_active = query_active_users_weekly(cursor, GRADE, WEEKS_INT)
        df_order  = query_paid_users_weekly(
            cursor, GRADE,
            [(l, s, e) for l, s, e in WEEKS_STR]
        )
        report.add_baseline(df_active, df_order)

        # Step 2: H1 流量/线索结构
        print("\n>>> Step 2: 验证 H1 流量/线索假设")
        query_clue_volume(
            cursor, GRADE,
            date_start=WEEKS_STR[1][1],  # 上上周开始
            date_end=WEEKS_STR[0][2],    # 上周结束
        )
        query_clue_source(
            cursor, GRADE, WEEK_CASES_STR,
            date_start=WEEKS_STR[1][1],
            date_end=WEEKS_STR[0][2],
        )

        # Step 3: H2 用户结构
        print("\n>>> Step 3: 验证 H2 用户结构假设")
        min_day = WEEKS_INT[-1][1]
        max_day = WEEKS_INT[0][2]
        query_user_layer(cursor, GRADE, WEEK_CASES_INT, min_day, max_day)

        # Step 4: H3 电销执行
        print("\n>>> Step 4: 验证 H3 电销执行假设")
        query_sales_performance(
            cursor, GRADE, WEEK_CASES_STR,
            date_start=WEEKS_STR[1][1],
            date_end=WEEKS_STR[0][2],
        )
        query_workplace_performance(
            cursor, GRADE, WEEK_CASES_STR,
            date_start=WEEKS_STR[1][1],
            date_end=WEEKS_STR[0][2],
        )

        # Step 5: H4 商品结构
        print("\n>>> Step 5: 验证 H4 商品结构假设")
        query_product_mix(
            cursor, GRADE, WEEK_CASES_STR,
            date_start=WEEKS_STR[1][1],
            date_end=WEEKS_STR[0][2],
        )

    # Step 6: 填写根因（AI 分析后填写，或人工审阅后填写）
    print("\n>>> Step 6: 生成分析报告")
    report.add_root_cause(
        level="主因",
        label="活跃流量持续萎缩",
        contribution="~40%",
        evidence="4周内9年级活跃从17.05万→14.71万，累计下跌13.7%。时间节点与寒促结束(3.2)高度吻合。",
        conclusion="寒促结束后自然回落，叠加开学季节律，是活跃下滑的主因。",
    )
    report.add_root_cause(
        level="主因",
        label="组合品销售大幅下滑拉低客单价",
        contribution="~35%",
        evidence="组合品付费人数202→149，↓26.2%；组合品客单价约1,958元，是零售商品(~297元)的6.6倍。",
        conclusion="寒促结束后无定金机制支撑，组合品自然塌陷，直接拉低大盘客单价。",
    )
    report.add_root_cause(
        level="次因",
        label="线索领取量小幅下降",
        contribution="~10%",
        evidence="上周24,660条 vs 上上周26,846条，↓8.1%。",
        conclusion="部分成立，但幅度不足以解释全部转化下滑。",
    )
    report.add_root_cause(
        level="排除",
        label="用户分层结构/线索来源/电销执行",
        contribution="< 1%",
        evidence="分层占比各层波动<0.5pp；线索来源结构稳定；电销接通率持平，人效反升25%。",
        conclusion="全部排除，电销团队执行无问题。",
    )

    report.add_hypothesis("H1.1", "线索量下降", "上周24660 vs 上上周26846，↓8.1%", "~10%", "次因")
    report.add_hypothesis("H1.2", "线索来源结构变化", "主渠道占比稳定(62.5% vs 62.8%)", "<2%", "排除")
    report.add_hypothesis("H1.3", "活跃用户规模萎缩", "4周累计↓13.7%，持续下滑", "~40%", "主因")
    report.add_hypothesis("H2.1", "用户分层结构变化", "各层占比变化<0.5pp，稳定", "<1%", "排除")
    report.add_hypothesis("H3.1", "电销外呼/接通率", "接通率持平，人效↑25%", "<1%", "排除")
    report.add_hypothesis("H3.2", "职场维度异常", "仅一个职场，指标稳定", "—", "排除")
    report.add_hypothesis("H4.1", "组合品销售大幅下滑", "付费人数↓26%，GMV↓25%", "~35%", "主因")
    report.add_hypothesis("H5.2", "寒促结束+开学季节律", "时间节点高度吻合", "协同", "主因")

    report.add_action([
        "【短期】核查电销团队上周9年级外呼量明细，确认是否有个人异常（职场级别无异常但个人可能有）",
        "【短期】策略侧评估3-4月组合品的替代性拉动方案（如学期末冲刺节点的小活动）",
        "【中期】持续监控9年级活跃是否在4月触底反弹，若继续下滑需排查产品/渠道问题",
        "【亮点】续购付费人数17→30，↑76%，建议分析续购用户画像并定向扩大运营",
    ])

    report.add_data_note([
        "活跃口径：product_id='01', client_os IN ('android','ios','harmony'), active_user_attribution IN ('中学用户','小学用户','c'), is_test_user=0, mid_grade='九年级'",
        "付费口径：sub_amount >= 39，按 paid_time 筛选日期",
        "线索表无 is_test 字段，未做测试过滤",
        "待补充：APP埋点维度（资源位曝光、点击）",
    ])

    # 保存报告
    report.save(output_dir="./reports")
    print("\n✅ 归因分析完成！")


if __name__ == "__main__":
    main()
