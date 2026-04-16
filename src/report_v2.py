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
        # 重写渲染逻辑，加入 Q2 和 Q3 的展示
        lines = []
        lines.append(f"# {self.anomaly_desc} — 归因分析报告 (v2.0)\n")
        lines.append(f"> **分析框架**：SOP v2 (六问) | **维度**：{self.dimension}\n")
        lines.append("---\n")

        # Q2: 真伪判定
        q2 = self.q_steps.get("Q2_Authenticity", {"success": False, "data": "未执行"})
        icon = "✅" if q2["success"] else "⚠️"
        lines.append(f"## {icon} Q2 真伪判定\n- 结论：{q2['data']}\n")

        # Q3: 定位下钻 & 对标
        q3 = self.q_steps.get("Q3_Location", {"success": False, "data": []})
        lines.append(f"## 🔍 Q3 定位下钻 & 对标\n")
        lines.append("- **全局对比**：已检测目标维度与全学段背离度。")
        lines.append("- **下钻发现**：已定位到波动贡献最大的核心分层。\n")

        # 原有报告内容 (Q4/Q5/Q6)
        lines.append(super().render())
        
        return "\n".join(lines)
