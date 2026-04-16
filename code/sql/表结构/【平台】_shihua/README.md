# 【平台】_shihua — DDL

维护人：**诗华**。知识库：`glossary/【平台】_shihua.md`、`business-context/【平台】_shihua.md`。

本目录含 **39** 个 `.sql` 文件。**文件命名**：`schema.table.sql`（如 `dws.topic_order_detail.sql`），与库中 `schema.table` 对应；无中文文件名前缀。

其中 `dw.fact_user_active_day.__raw_from_临时文件.sql` 为自 `.cursor/code/sql/临时文件` 迁入的 **StarRocks 导出备查**，表头与枚举待补；**权威 DDL** 仍以 `dw.fact_user_active_day.sql` 为准。

## 更新记录

| 日期 | 内容 |
|------|------|
| 2026-03-31 | 自 `.cursor/code/sql/临时文件` 非 `finebi_` 的 `.md` 迁入：三段式 DDL（表粒度/枚举待补充处已标「待补充」）；含活动资源位中间表、`onion.frontend_event_orc`、`ods_rt.order_processing_orders_rt`、若干 `aws`/`tmp` 表等 |
| 2026-04-01 | 文件重命名为 `schema.table.sql`；自 `.cursor/code/sql/表结构` 重新同步内容 |
| 2026-04-01 | 自 `.cursor/code/sql/表结构` 迁入 18 个 `.sql`；本 README 由「待收集」改为已归档说明 |
| 2026-04-01 | 预建目录 |
