# 数据知识库索引（cursor2.0）

本目录为项目根 `cursor2.0` 下的知识库入口。编写 SQL 时配合 `.cursor/rules/*.mdc` 使用。

## 文件与职责

| 路径 | 说明 |
|------|------|
| [SPEC.md](./SPEC.md) | 建设规范（不含业务内容） |
| [table-relations.md](./table-relations.md) | 全局表间关联、JOIN 示例 |
| [sql-patterns.md](./sql-patterns.md) | 可执行 SQL 模板（`${param}` 占位） |
| [glossary/](./glossary/) | 业务术语与指标，**按业务域拆分** |
| [business-context/](./business-context/) | 业务流程与背景，**按业务域拆分**；跨域全文见 `reference/` |

## 业务域与维护人（后缀）

| 域 | glossary / business-context 文件名 | DDL 目录 |
|----|--------------------------------------|----------|
| 电销 | `【电销】_tanchen.md` | `code/sql/表结构/【电销】_tanchen/` |
| 投放 | `【投放】_xinyu.md` | `code/sql/表结构/【投放】_xinyu/` |
| 新媒体 | `【新媒体】_huihui.md` | `code/sql/表结构/【新媒体】_huihui/` |
| 平台 | `【平台】_shihua.md` | `code/sql/表结构/【平台】_shihua/` |
| 智课 | `【智课】_shihua.md` | `code/sql/表结构/【智课】_shihua/` |
| 宽表 | `【宽表】_xingling.md` | `code/sql/表结构/【宽表】_xingling/` |

**DDL 权威来源**：当前宽表域以「表结构收集的副本」合并稿为准，路径见 `【宽表】_xingling/*.sql`。

## 跨模块引用（摘要）

- 术语 / 指标 → `glossary/【域】_维护人.md`
- 表结构 / 枚举 → `code/sql/表结构/【域】_维护人/{表名}.sql`
- 关联与易错 JOIN → `table-relations.md`
- 标准 SQL 片段 → `sql-patterns.md`
- 口径对齐全文 → `business-context/reference/口径对齐整理.md`

## 更新记录

| 日期 | 内容 |
|------|------|
| 2026-04-01 | 初版索引与域划分说明 |
