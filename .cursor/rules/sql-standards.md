---
description: Spark SQL 编写规范，适用于所有 SQL 编写场景
globs: "**/*.sql"
alwaysApply: true
---

# Spark SQL 编写规范（Spark 3.3.3）

默认所有 SQL 均为 Spark SQL 语法。

## 硬性约束

| # | 约束 | 说明 |
|---|------|------|
| 1 | 禁止 `select *` | 必须列出具体字段，避免资源浪费 |
| 2 | 分区条件前置 | 分区表的分区字段筛选必须写在 WHERE 后第一个条件 |
| 3 | 分区日期禁用公式 | 日期分区表 WHERE 后的日期字段直接写常量值，不要用函数/表达式计算 |
| 4 | 强制使用 CTE | 总是使用 `with ... as` 语法，禁止多层嵌套子查询，提升可读性与复用性 |
| 5 | 禁止隐式 JOIN | 禁止逗号分隔表名，优先 `left join` |
| 6 | 强制 LIMIT | SQL 末尾必须加 `limit 100000`，防止卡死 |
| 7 | 字段中文注释 | 所有输出字段必须加中文别名（用反引号 `` as `中文名` ``），便于 BI 核查逻辑 |
| 8 | 日期格式统一 | 输出日期统一处理为 `yyyy-MM-dd` 格式 |
| 9 | 关键字小写 | select / from / where / group by / left join 等全部小写（个人习惯，可按团队调整） |
| 10 | 同名字段强制区分 | SQL 中出现两个同名字段时，必须用表别名或重命名显式区分，避免歧义 |
| 11 | 避免小文件 | 注意 Spark 小文件问题，合理使用 `repartition` / `coalesce` 或相关配置 |
| 12 | 超时自动终止 | SQL 查询超过 10 分钟未出结果时自动终止运行 |

## events.frontend_event_orc 表特殊约束

- 必须同时添加两个分区条件：`day`（格式 `yyyyMMdd`）和 `event_type`
- `event_type` 取 `event_key` 前缀，共 6 种：`click`、`dev`、`get`、`enter`、`popup`、`other`（不在前五种的归 `other`）
- 单次最多查询 **7 天**数据
