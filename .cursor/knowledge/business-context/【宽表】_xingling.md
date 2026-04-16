# 【宽表】业务背景（选表与链路摘要）

> 维护人：**杏玲**。  
> **完整选表原则、跨表对照、待确认清单** 请以全文为准：  
> → [reference/口径对齐整理.md](./reference/口径对齐整理.md)  
> 冲突与合并来源：→ [reference/合并汇总_冲突点分析.md](./reference/合并汇总_冲突点分析.md)

## 选表原则（摘要）

| 分析目的 | 推荐主表 |
|----------|----------|
| 全渠道 GMV / 是否买过某商品 / 转化与订单明细 | `dws.topic_order_detail` |
| 电销专属营收、产能、线索与成单归因 | `aws.crm_order_info` |
| 用户活跃（日/周/月） | `dws.topic_user_active_detail_day` / `_week` / `_month` |
| 用户静态属性、家长身份 | `dw.dim_user` 等维表 |
| 用户服务期进出 | `user_allocation.user_allocation` |
| 退款分析 | `dw.fact_order_detail_refund` 等 |

**宽表筛「电销」营收 ≠ `aws.crm_order_info` 电销营收**（服务期归属规则不同）；电销专题以后者为准。

## 数据链路（骨架）

```text
（待补）ODS → DW 事实/维表 → DWS 宽表 → 应用
```

## 更新记录

| 日期 | 内容 |
|------|------|
| 2026-04-01 | 摘要 + 引用 reference 全文 |
