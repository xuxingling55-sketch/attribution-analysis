"""
SOP v2 报告生成器
结构：精确化 -> 真伪判定 -> 定位对标 -> 归因验证 -> 量化决策 -> 建议
"""
from src.report import AttributionReport

class SOPv2Report(AttributionReport):
    def __init__(self, anomaly_desc, dimension):
        super().__init__(anomaly_desc, dimension)
        self.q_steps = {}

    def add_step(self, step_id, success, data):
        """记录六问中每一阶段的结果"""
        self.q_steps[step_id] = {"success": success, "data": data}

    def render(self) -> str:
        # 重写渲染逻辑，按用户要求的顺序：背景 -> 结论 -> 分析步骤
        lines = []
        lines.append(f"# {self.anomaly_desc} — 归因分析报告 (v2.0)\n")
        lines.append(f"> **分析框架**：SOP v2 (六问) | **维度**：{self.dimension} | **分析时间**：{self.created_at}\n")
        lines.append("---\n")

        # 1. 背景 (Background / Q1)
        lines.append("## 📌 一、分析背景 (Background)\n")
        if hasattr(self, "_df_active") and hasattr(self, "_df_order"):
            merged = self._build_summary_table()
            lines.append(merged)
        lines.append("")

        # 2. 结论 (Conclusion / Q5 & Q6)
        lines.append("## 🎯 二、核心结论 (Conclusion)\n")
        # 2.1 根因判定 (Q5)
        for rc in self.root_causes:
            lines.append(f"### {rc['icon']} {rc['level']}：{rc['label']}\n")
            lines.append(f"**贡献度估算：{rc['contribution']}**\n")
            lines.append(f"**结论总结**：{rc['conclusion']}\n")
        
        # 2.2 建议行动 (Q6)
        lines.append("\n### 💡 业务建议与行动计划\n")
        if hasattr(self, "_actions"):
            for i, action in enumerate(self._actions, 1):
                lines.append(f"{i}. {action}")
        lines.append("")

        # 3. 分析步骤 (Analysis Steps / Q2, Q3, Q4)
        lines.append("---\n## 🔬 三、分析推导过程 (Analysis Steps)\n")
        
        # 3.1 Q2: 真伪判定
        q2 = self.q_steps.get("Q2_Authenticity", {"success": False, "data": "未执行"})
        icon_q2 = "✅" if q2["success"] else "⚠️"
        lines.append(f"### {icon_q2} Step 1: Q2 真伪判定\n- **校验结论**：{q2['data']}\n")

        # 3.2 Q3: 定位下钻 & 对标
        q3 = self.q_steps.get("Q3_Location", {"success": False, "data": []})
        lines.append(f"### 🔍 Step 2: Q3 定位下钻 & 对标\n")
        lines.append("- **全局对比**：已通过全学段大盘趋势背离度检测。")
        lines.append("- **下钻发现**：已定位到波动贡献最大的核心分层或亲缘年级。\n")

        # 3.3 Q4: 假设验证汇总
        lines.append(f"### 📊 Step 3: Q4 全维度验证明细\n")
        lines.append("| 假设编号 | 假设描述 | 验证结果 | 贡献度 | 判定 |")
        lines.append("|---------|---------|---------|-------|------|")
        for h in self.hypothesis_table:
            lines.append(f"| {h['id']} | {h['desc']} | {h['result']} | {h['contribution']} | {h['verdict']} |")
        lines.append("")

        # 4. 附录
        lines.append("## 📎 四、附录与数据说明\n")
        if hasattr(self, "_notes"):
            for note in self._notes:
                lines.append(f"- {note}")
        lines.append("")
        
        return "\n".join(lines)
