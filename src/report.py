"""
报告生成模块
将分析结果输出为结构化 Markdown 报告
"""
from datetime import datetime
import pandas as pd
import os


class AttributionReport:
    def __init__(self, anomaly_desc: str, dimension: str):
        self.anomaly_desc = anomaly_desc
        self.dimension = dimension
        self.created_at = datetime.now().strftime("%Y-%m-%d %H:%M")
        self.sections = []
        self.root_causes = []      # (level, label, contribution, evidence, conclusion)
        self.hypothesis_table = [] # (h_id, desc, result, contribution, verdict)

    def add_baseline(self, df_active: pd.DataFrame, df_order: pd.DataFrame):
        """添加基线数据"""
        self._df_active = df_active
        self._df_order = df_order

    def add_root_cause(self, level: str, label: str, contribution: str, evidence: str, conclusion: str):
        """添加根因（level: '主因'/'次因'/'排除'）"""
        icons = {"主因": "🔴", "次因": "🟡", "排除": "⚪"}
        self.root_causes.append({
            "level": level,
            "icon": icons.get(level, "❓"),
            "label": label,
            "contribution": contribution,
            "evidence": evidence,
            "conclusion": conclusion,
        })

    def add_hypothesis(self, h_id: str, desc: str, result: str, contribution: str, verdict: str):
        """添加假设验证记录"""
        icons = {"主因": "🔴", "次因": "🟡", "排除": "⚪", "待查": "❓"}
        self.hypothesis_table.append({
            "id": h_id,
            "desc": desc,
            "result": result,
            "contribution": contribution,
            "verdict": f"{icons.get(verdict, '❓')} {verdict}",
        })

    def add_action(self, actions: list):
        """添加建议行动"""
        self._actions = actions

    def add_data_note(self, notes: list):
        """添加数据说明"""
        self._notes = notes

    def render(self) -> str:
        lines = []

        # 标题
        lines.append(f"# {self.anomaly_desc} — 归因分析报告\n")
        lines.append(f"> **分析时间**：{self.created_at}  ")
        lines.append(f"> **分析维度**：{self.dimension}  ")
        lines.append(f"> **数据来源**：Impala（活跃宽表 + 订单表 + 线索表）\n")
        lines.append("---\n")

        # 一、异动概况（基线表格）
        lines.append("## 📌 一、异动概况\n")
        if hasattr(self, "_df_active") and hasattr(self, "_df_order"):
            merged = self._build_summary_table()
            lines.append(merged)
        lines.append("")

        # 二、根因定位
        lines.append("## 🔍 二、根因定位\n")
        for rc in self.root_causes:
            lines.append(f"### {rc['icon']} {rc['level']}：{rc['label']}\n")
            lines.append(f"**贡献度估算：{rc['contribution']}**\n")
            lines.append(rc["evidence"])
            lines.append(f"\n**结论**：{rc['conclusion']}\n")

        # 三、全维度验证汇总
        lines.append("## 📊 三、全维度验证汇总\n")
        lines.append("| 假设编号 | 假设描述 | 验证结果 | 贡献度 | 判定 |")
        lines.append("|---------|---------|---------|-------|------|")
        for h in self.hypothesis_table:
            lines.append(f"| {h['id']} | {h['desc']} | {h['result']} | {h['contribution']} | {h['verdict']} |")
        lines.append("")

        # 四、建议行动
        lines.append("## 💡 四、建议行动\n")
        if hasattr(self, "_actions"):
            for i, action in enumerate(self._actions, 1):
                lines.append(f"{i}. {action}")
        lines.append("")

        # 五、数据说明
        lines.append("## 📎 五、数据说明\n")
        if hasattr(self, "_notes"):
            for note in self._notes:
                lines.append(f"- {note}")
        lines.append("")

        return "\n".join(lines)

    def _build_summary_table(self) -> str:
        """构建基线汇总表格"""
        active_map = dict(zip(self._df_active["week_label"], self._df_active["active_users"]))
        order_map = {}
        for _, row in self._df_order.iterrows():
            order_map[row["week_label"]] = row

        rows = []
        rows.append("| 周期 | 活跃人数 | 付费人数 | 转化率 | GMV | 客单价 |")
        rows.append("|------|---------|---------|-------|-----|-------|")

        for label in self._df_active["week_label"].tolist():
            active = active_map.get(label, 0)
            if label in order_map:
                o = order_map[label]
                paid = int(o.get("paid_users", 0) or 0)
                gmv = int(o.get("total_gmv", 0) or 0)
                aov = o.get("avg_order_value", 0) or 0
            else:
                paid, gmv, aov = 0, 0, 0
            cvr = f"{paid * 100 / active:.2f}%" if active else "—"
            rows.append(f"| {label} | {active:,} | {paid:,} | {cvr} | {gmv/10000:.1f}万 | {aov}元 |")

        return "\n".join(rows)

    def save(self, output_dir: str = ".") -> str:
        """保存报告到文件"""
        os.makedirs(output_dir, exist_ok=True)
        safe_desc = self.anomaly_desc.replace("/", "_").replace(" ", "_")[:30]
        filename = f"归因分析报告_{self.dimension}_{safe_desc}.md"
        filepath = os.path.join(output_dir, filename)
        content = self.render()
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"\n✅ 报告已保存：{filepath}")
        return filepath
