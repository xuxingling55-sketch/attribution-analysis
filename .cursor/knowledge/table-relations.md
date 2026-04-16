# 表关联关系

> 本文档说明核心表之间的关联方式，避免JOIN时用错字段。

---

## 核心表一览

| 表名 | 别名 | 粒度 | 用户关联字段 | 主键 |
|------|------|------|-------------|------|
| `dw.dim_user` | 用户信息表 | 一个用户一条 | `u_user` | `user_sk` |
| `dws.topic_user_active_detail_day` | 活跃表(日) | 用户+日期一条 | `u_user` | `u_user` + `day` |
| `aws.clue_info` | 线索领取记录表 | 一次领取一条 | `user_id` | `info_uuid` |
| `dw.fact_call_history` | 外呼记录表 | 一次外呼一条 | `user_id` | `action_id` |
| `aws.crm_order_info` | 电销订单表 | 一个订单一条 | `user_id` | `order_id` |
| `dws.topic_order_detail` | 全公司订单宽表 | 一个子订单一条 | `u_user` | `order_id` + `sub_good_sk` |

---

## 一、用户维度关联（最常用）

### 关联字段对照

```
┌─────────────────────────────┐
│        用户标识字段          │
├─────────────────────────────┤
│  user_id  =  u_user         │  ← 字符串类型，实际关联首选
│  user_sk                    │  ← 整型，理论性能更优但很少使用
└─────────────────────────────┘
```

> **实际使用惯例**：用户关联统一用 `user_id` / `u_user`，`user_sk` 几乎不用。

| 表 | 用户ID字段 | 说明 |
|----|-----------|------|
| `dw.dim_user` | `u_user` | 用户主表 |
| `dws.topic_user_active_detail_day` | `u_user` | 活跃表 |
| `dws.topic_order_detail` | `u_user` | 全公司订单表 |
| `aws.clue_info` | `user_id` | 线索表，注意字段名是 user_id |
| `dw.fact_call_history` | `user_id` | 外呼表，注意字段名是 user_id |
| `aws.crm_order_info` | `user_id` | 电销订单表，注意字段名是 user_id |

### 关联示例

```sql
-- 活跃表 关联 用户信息表
SELECT a.*, u.phone
FROM dws.topic_user_active_detail_day a
LEFT JOIN dw.dim_user u ON a.u_user = u.u_user
WHERE a.day = '2026-02-03'

-- 线索表 关联 活跃表（注意：线索表用 user_id，活跃表用 u_user）
SELECT c.*, a.is_vip_user
FROM aws.clue_info c
LEFT JOIN dws.topic_user_active_detail_day a 
  ON c.user_id = a.u_user 
  AND DATE(c.created_at) = a.day
```

### ⚠️ 常见错误

```sql
-- ❌ 错误：字段名不匹配
SELECT * FROM aws.clue_info c
JOIN dws.topic_order_detail o ON c.user_id = o.user_id  -- 订单表没有 user_id 字段！

-- ✅ 正确
SELECT * FROM aws.clue_info c
JOIN dws.topic_order_detail o ON c.user_id = o.u_user
```

---

## 二、线索 → 订单 关联

### 关联方式选择

| 场景 | 关联方式 | 说明 |
|------|---------|------|
| **从订单查营收分布** | `info_uuid` 关联 | 用 `recent_info_uuid` 或 `modify_recent_info_uuid` |
| **计算领取转化率** | `user_id` 关联 | 按用户维度统计，一个用户只算一次转化 |

### 关联字段

```
aws.clue_info                    aws.crm_order_info
┌──────────────┐                ┌──────────────────────────┐
│  info_uuid   │ ←───────────── │  recent_info_uuid        │  成交前最近一次领取的线索
│  (主键)      │ ←───────────── │  modify_recent_info_uuid │  矫正后（排除人工录入）
│  user_id     │ ═══════════════ │  user_id                 │  用户维度关联
└──────────────┘                └──────────────────────────┘
```

| 关联字段 | 说明 | 使用场景 |
|---------|------|---------|
| `recent_info_uuid` | 成交前该坐席最近一次领取的线索id | 营收归因到具体线索 |
| `modify_recent_info_uuid` | 矫正后：排除人工录入来源 | 营收分布（排除人工录入干扰） |
| `user_id` | 用户维度 | 计算转化率（用户去重） |

### 关联示例

```sql
-- 场景1：从订单查营收分布（按线索关联）
SELECT 
    c.clue_source,
    SUM(o.amount) AS 营收
FROM aws.crm_order_info o
LEFT JOIN aws.clue_info c ON o.recent_info_uuid = c.info_uuid
WHERE o.status = '支付成功'
  AND o.pay_time >= '2026-01-01'
GROUP BY c.clue_source

-- 场景2：计算领取转化率（按用户关联）
SELECT 
    DATE(c.created_at) AS 领取日期,
    COUNT(DISTINCT c.user_id) AS 领取用户量,
    COUNT(DISTINCT o.user_id) AS 转化用户量,
    COUNT(DISTINCT o.user_id) * 1.0 / COUNT(DISTINCT c.user_id) AS 转化率
FROM aws.clue_info c
LEFT JOIN aws.crm_order_info o 
    ON c.user_id = o.user_id 
    AND o.status = '支付成功'
    AND o.pay_time >= c.created_at  -- 领取后成交
WHERE c.created_at >= '2026-01-01'
GROUP BY DATE(c.created_at)
```

### ⚠️ 注意事项

1. **一条线索可能对应0或多个订单**：线索未转化则无订单，同一线索周期内可能多次购买
2. **一个订单只关联一条线索**：`recent_info_uuid` 是订单表字段，指向最近一条线索
3. **同一用户可有多条线索记录**：用户可被多次领取，每次产生新的 `info_uuid`
4. **转化率用 user_id 关联**：避免同一用户被多次领取导致重复计算

---

## 三、线索 → 外呼 关联

### 关联字段

```
aws.clue_info                    dw.fact_call_history
┌──────────────┐                ┌──────────────────────────┐
│  info_uuid   │ ═══════════════ │  info_uuid               │
│  (主键)      │                │  (外键，关联线索)          │
└──────────────┘                └──────────────────────────┘
```

### 关联示例

```sql
-- 查看线索的外呼情况
SELECT 
    c.info_uuid,
    c.user_id,
    c.clue_source,
    COUNT(h.action_id) AS 外呼次数,
    COUNT(CASE WHEN h.is_connect = 1 THEN h.action_id END) AS 接通次数,
    COUNT(CASE WHEN h.is_valid_connect = 1 THEN h.action_id END) AS 有效接通次数
FROM aws.clue_info c
LEFT JOIN dw.fact_call_history h ON c.info_uuid = h.info_uuid
WHERE c.created_at >= '2026-01-01'
GROUP BY c.info_uuid, c.user_id, c.clue_source
```

### ⚠️ 注意事项

1. **一条线索可能有多次外呼**：同一 `info_uuid` 可对应多条外呼记录
2. **外呼表可独立使用**：通过 `user_id` 直接关联用户维度，无需经过线索表
3. **分区字段**：外呼表按 `day`（int类型，如20260115）分区

---

## 四、订单表之间的关系

### 电销订单表 vs 全公司订单宽表

```
aws.crm_order_info (电销订单表)          dws.topic_order_detail (全公司订单宽表)
┌─────────────────────┐                  ┌─────────────────────┐
│  order_id           │  ═══════════════ │  order_id           │
│  仅电销业务订单      │                  │  全公司所有业务订单   │
│  一个订单一条记录    │                  │  一个子订单一条记录   │
└─────────────────────┘                  └─────────────────────┘
```

| 维度 | 电销订单表 | 全公司订单宽表 |
|------|-----------|---------------|
| 业务范围 | 仅电销 | 电销+新媒体+入校+体验营等 |
| 粒度 | 订单级 | 子订单级（需去重） |
| 营收字段 | `amount` | `order_amount`（去重后）/ `sub_amount` |
| 使用场景 | 电销营收分析 | 活跃转化分析、判断购买历史 |

### ⚠️ 重要差异

```sql
-- 以下两个查询结果可能不同！
-- 原因：双服务期用户的订单，全公司表可能按优先级归属到非电销业务

-- 电销订单表：电销业务口径
SELECT SUM(amount) FROM aws.crm_order_info WHERE status = '支付成功'

-- 全公司表筛选电销：可能因业务归属逻辑而金额不同
SELECT SUM(order_amount) FROM dws.topic_order_detail 
WHERE status = '支付成功' AND business_gmv_attribution = '电销'
```

---

## 五、常用关联模式

### 模式1：线索领取 + 转化订单

```sql
-- 计算领取转化率（用 user_id 关联，按用户去重）
SELECT 
    DATE(c.created_at) AS 领取日期,
    COUNT(DISTINCT c.user_id) AS 领取用户量,
    COUNT(DISTINCT o.user_id) AS 转化用户量,
    COUNT(DISTINCT o.user_id) * 1.0 / COUNT(DISTINCT c.user_id) AS 转化率
FROM aws.clue_info c
LEFT JOIN aws.crm_order_info o 
    ON c.user_id = o.user_id 
    AND o.status = '支付成功'
    AND o.pay_time >= c.created_at
WHERE c.created_at >= '2026-01-01'
GROUP BY DATE(c.created_at)
```

### 模式2：活跃用户 + 购买历史

```sql
-- 查询活跃用户是否购买过大会员
SELECT 
    a.u_user,
    a.day,
    CASE WHEN h.u_user IS NOT NULL THEN 1 ELSE 0 END AS 是否购买过大会员
FROM dws.topic_user_active_detail_day a
LEFT JOIN (
    SELECT DISTINCT u_user
    FROM dws.topic_order_detail
    WHERE status = '支付成功'
      AND good_kind_name_level_2 = '大会员'
) h ON a.u_user = h.u_user
WHERE a.day = '2026-02-03'
  AND a.is_active_user = 1
```

### 模式3：用户信息 + 服务期归属

```sql
-- 查询电销服务期用户
SELECT u_user, user_allocation
FROM dw.dim_user
WHERE ARRAY_CONTAINS(user_allocation, '电销')
  AND is_test_user = false
```

---

## 六、关联关系图

```
                              ┌─────────────────┐
                              │   dw.dim_user   │
                              │   (用户主表)     │
                              └────────┬────────┘
                                       │ u_user
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
        ┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐
        │  aws.clue_info    │ │ topic_user_active │ │ topic_order_detail│
        │  (线索表)          │ │ (活跃表)          │ │ (全公司订单表)     │
        │  user_id          │ │ u_user            │ │ u_user            │
        └─────────┬─────────┘ └───────────────────┘ └───────────────────┘
                  │ info_uuid
                  ├─────────────────────┐
                  │                     │
                  ▼                     ▼
        ┌───────────────────┐ ┌───────────────────┐
        │aws.crm_order_info │ │dw.fact_call_history│
        │  (电销订单表)      │ │  (外呼记录表)       │
        │recent_info_uuid   │ │  info_uuid        │
        └───────────────────┘ └───────────────────┘
```

---

## 更新记录

| 日期 | 内容 |
|------|------|
| 2026-02-05 | 明确用户关联以 user_id/u_user 为主；补充线索-订单关联场景（营收分布用info_uuid，转化率用user_id） |
| 2026-02-04 | 初始化关联关系文档 |
