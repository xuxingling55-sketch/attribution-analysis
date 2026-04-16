# 【宽表】业务知识字典（摘要）

> 维护人：**杏玲**。宽表域 DDL：`code/sql/表结构/【宽表】_xingling/`（以「表结构收集的副本」为准）。  
> **字段级推荐口径全文** → [business-context/reference/口径对齐整理.md](../business-context/reference/口径对齐整理.md) 第二节；此处只保留可检索的术语锚点，避免与全文重复。

## 选表与口径（术语锚点）

### 全渠道 GMV / 是否买过某商品

- **定义**：跨渠道订单与用户购买事实的统计与明细
- **计算方式**：（按场景选用 `SUM` / `COUNT(DISTINCT)`，见各表 DDL 表头【统计口径】）
- **表来源**：`dws.topic_order_detail`（子订单粒度；「是否买过」类需求优先宽表）
- **⚠️ 注意**：电销专属营收与宽表筛「电销」不等价 → 电销专题用 `aws.crm_order_info`，详见口径对齐文档

### 付费标签字段（business_ 前缀）

- **定义**：商业化场景下用户付费分层标签（统计维 vs 业务维两套）
- **计算方式**：按需求选用 `business_user_pay_status_statistics` 或 `business_user_pay_status_business`，禁止与无 `business_` 前缀字段混用
- **表来源**：`dws.topic_order_detail`、`dws.topic_user_active_detail_*`、`dws.topic_user_info*`、`aws.crm_order_info` 等（以各表 DDL 为准）
- **⚠️ 注意**：`*_statistics` 与 `*_business` 语义不同，须在需求中写明选用哪一套

### 用户身份（家长判断）

- **定义**：判断用户是否家长等身份
- **计算方式**：使用 `real_identity`（以维表定义为准）；**不要用 `role` 判断家长**
- **表来源**：`dw.dim_user` 及下游宽表同名字段
- **⚠️ 注意**：详见 [口径对齐整理.md](../business-context/reference/口径对齐整理.md) 2.2

### 手机号 phone

- **定义**：用户手机号（可能存在明文与 base64）
- **计算方式**：展示或关联前统一解码（参见口径对齐文档中的参考 SQL）
- **表来源**：`dw.dim_user`、`dws.topic_order_detail` 等含 phone 的表
- **⚠️ 注意**：详见 [口径对齐整理.md](../business-context/reference/口径对齐整理.md) 2.3

## 更新记录

| 日期 | 内容 |
|------|------|
| 2026-04-01 | 建立域文件，摘入口径对齐要点为 glossary 锚点 |
