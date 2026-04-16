# 归因分析 AI 工作流 & 数据知识库

> 集成了**业务指标异动分析工具**与 **AI 原生数据知识库**的统一工作流。

## 核心理念
本项目旨在解决数据分析中的两个痛点：
1. **取数难**：通过 AI 原生知识库（.cursor/knowledge），让 AI Agent 能够准确理解业务口径和表结构，自动生成高质量 SQL。
2. **分析累**：通过自动化归因脚本（main.py），实现从"发现异动"到"产出归因报告"的全流程自动化。

---

## 目录结构

```
.
├── .cursor/                # AI 知识库与规则 (核心脑部)
│   ├── knowledge/          # 业务指标词典、表关系、SQL 模板
│   └── rules/              # SQL 编写实时约束规范
├── code/sql/               # 数据资产 (核心资产)
│   └── 表结构/              # 按业务域划分的 DDL 及其详尽元数据
├── src/                    # 归因分析 Python 源码
├── main.py                 # 归因分析执行入口
├── docs/                   # 方法论与框架文档
├── examples/               # 实战归因案例
├── config.example.yaml     # 数据库连接配置模板
├── requirements.txt        # Python 依赖
└── SKILL.md                # Accio Agent 技能定义文件
```

---

## 一、自动化归因工具 (Attribution Analysis)

### 快速开始
1. **安装依赖**: `pip install -r requirements.txt`
2. **配置连接**: `cp config.example.yaml config.yaml` 并填入 SSH/DB 信息。
3. **运行分析**:
   - 修改 `main.py` 中的 `ANOMALY_DESC`（异动描述）和 `GRADE`（年级）。
   - 执行 `python main.py`。
4. **查看报告**: 结果将生成在 `reports/` 目录，可参考 `examples/`。

---

## 二、AI 数据知识库 (Knowledge Base)

本项目遵循 [`.cursor/knowledge/SPEC.md`](.cursor/knowledge/SPEC.md) 规范构建。

### 核心组件
- **Glossary (词典)**: 定义业务指标（如：日活、转化率）的权威计算公式。
- **DDL as Document**: 所有的表结构信息（含枚举值、筛选条件、坑点）均直接写在 `code/sql/表结构/` 下的 SQL 注释中。
- **Cursor Rules**: 配合 Cursor 编辑器，实时校验 SQL 编写是否符合业务口径。

---

## 三、Accio Agent 集成

如果你使用 Accio Agent，可以直接通过 `SKILL.md` 加载该工作流：
- **触发**: "分析上周XX年级转化率下降的原因"
- **行为**: Agent 会自动解析日期，调用 Python 脚本跑数，并基于知识库进行根因推断。

---

## 数据口径摘要 (Cheat Sheet)
| 字段 | 规则 |
|---|---|
| `day` | **int 类型** (如 20260325) |
| `paid_time` | timestamp (订单日期筛选) |
| `mid_grade` | 修正年级字段 |
| 活跃宽表筛选 | `product_id='01'`, `is_test_user=0` 等 |

---

## License
MIT
