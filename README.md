# 归因分析 AI 工作流

> 适用于在线教育/电销行业的业务指标异动归因分析工具
> 输入一句话描述异动 → 自动查数据 → 输出结构化 Markdown 报告

---

## 功能概览

- 自动连接 Impala 数据仓库（通过 SSH 隧道）
- 覆盖 **6 大假设维度**：流量结构、用户结构、电销执行、商品结构、外部因素、产品功能
- 标准化 SQL 口径（含踩坑规避）
- 自动生成 Markdown 报告，含根因排序、假设验证汇总、建议行动

---

## 快速开始

### 1. 安装依赖

```bash
pip install -r requirements.txt
```

### 2. 配置连接信息

```bash
cp config.example.yaml config.yaml
# 编辑 config.yaml，填入你的 SSH + DB 信息
```

### 3. 修改分析参数

打开 `main.py`，修改顶部的配置段：

```python
# 数据库连接
config = DBConfig(
    ssh_host     = "221.194.xxx.xxx",
    ssh_user     = "master",
    ssh_password = "your_password",
    db_host      = "10.17.2.45",
    db_port      = 10010,
    db_user      = "your_user",
    db_pass      = "your_pass",
)

# 分析参数
ANOMALY_DESC = "上周9年级线索转化率和客单价都跌了"
GRADE        = "九年级"
```

以及时间窗口（按实际日期替换）：

```python
WEEKS_INT = [
    ("上周",   20260323, 20260329),
    ("上上周",  20260316, 20260322),
    ...
]
WEEKS_STR = [
    ("上周",   "2026-03-23", "2026-03-30"),
    ("上上周",  "2026-03-16", "2026-03-23"),
]
```

### 4. 运行

```bash
python main.py
```

报告自动保存到 `reports/` 目录。

---

## 输出示例

见 [`examples/归因分析报告_9年级线索异动.md`](examples/归因分析报告_9年级线索异动.md)

关键结论：
- 🔴 **主因**：寒促结束后活跃流量萎缩（4周累计↓13.7%）
- 🔴 **主因**：组合品销售大幅下滑（↓26%），直接拉低客单价
- ⚪ **排除**：用户分层稳定、电销执行正常（人效反升25%）

---

## 目录结构

```
attribution-analysis/
├── main.py                 # 主入口，修改顶部参数后直接运行
├── src/
│   ├── db.py               # SSH 隧道 + Impala 连接
│   ├── queries.py          # 各维度标准 SQL 查询
│   └── report.py           # Markdown 报告生成
├── examples/               # 真实案例示例
├── docs/                   # 方法论文档
├── config.example.yaml     # 连接配置模板（不含密码）
├── requirements.txt
└── .gitignore              # config.yaml 已加入忽略列表
```

---

## 数据口径说明

| 字段 | 口径规则 |
|------|---------|
| `day` | **int 类型**（如 `20260325`），不是字符串 |
| `paid_time` | timestamp，用于订单表日期筛选 |
| `mid_grade` | 使用修正年级，不用 `grade` |
| `real_identity` | 用户身份字段，禁用 `role` |
| 活跃宽表必筛 | `product_id='01'`, `client_os IN ('android','ios','harmony')`, `active_user_attribution IN ('中学用户','小学用户','c')`, `is_test_user=0` |

---

## 方法论

详见 [`docs/归因分析框架v1.md`](docs/归因分析框架v1.md)

**GMV 三因子分解**：

```
GMV = 流量（活跃用户）× 转化率 × 客单价
```

任何 GMV 异动，必然由三因子中至少一个驱动，逐层拆解、逐假设验证。

---

## 适用场景

- 转化率异动（上升/下降）
- 客单价异动
- GMV 整体异动
- 特定年级/渠道/商品异动

---

## License

MIT
