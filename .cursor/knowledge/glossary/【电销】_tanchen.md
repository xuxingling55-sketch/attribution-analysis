# 业务术语词典

> 本词典定义业务术语的数据口径，确保取数时口径一致。
>
> **使用方式**：遇到业务术语时，先查本词典确认数据定义，再写 SQL。
>
> **配套文档**：
> - 表结构 DDL（含枚举值、筛选条件） → `code/sql/表结构/【电销】_tanchen/*.sql`
> - 表间关联 → `table-relations.md`
> - 通用业务规则 → 本文件末尾"通用业务规则"


## 一、用户信息

### 用户付费身份

- **定义**：用户按付费行为和金额划分的身份标签，区分新用户、老未用户、正价付费、高净值付费等
- **判断方式**：共 4 个字段，按场景选用（电销默认用`business_user_pay_status_business`）：
  | 场景 | 字段 |
  |------|------|
  | 默认 | `business_user_pay_status_business` |
  | 需求明确"新用户=当日注册" | `business_user_pay_status_statistics` |
  | 不需要区分高净值用户 | `user_pay_status_statistics` 或 `user_pay_status_business` |
- **适用表**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`aws.clue_info`
- **⚠️ 注意**：枚举值见各 DDL 文件末尾

### 电销触达用户

- **定义**：在线索领取表中有过领取记录的用户
- **判断方式**：关联 `aws.clue_info` 判断是否有记录
- **适用表**：`aws.clue_info`
- **⚠️ 注意**：
  - 特定场景"某类用户的电销触达情况"中，"触达"指当前在坐席名下（`created_at <= 事件时间 AND clue_expire_time >= 事件时间`）或后续被领取（`created_at > 事件时间`），历史已过期线索不算
  - `is_telemarketing_user` 字段口径待验证，暂不推荐使用

### 用户学段
- **定义**：用户所在的教育阶段（小学/初中/高中等）
- **判断方式**：
  | 表 | 字段 |
  |----|------|
  | 订单表、活跃表 | `mid_stage_name`（中学修正学段） |
  | 线索表 | `clue_stage` |
  | 用户表 | 无学段字段，需用 `grade` 聚合 |
- **适用表**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`aws.clue_info`、`dw.dim_user`（需聚合）
- **⚠️ 注意**：枚举值及学段-年级映射见各 DDL 文件末尾

### 用户年级

- **定义**：用户所在的年级
- **判断方式**：
  | 表 | 字段 |
  |----|------|
  | 订单表、活跃表 | `mid_grade`（中学修正年级） |
  | 线索表 | `clue_grade` |
  | 用户表 | `grade`（用户填写年级） |
- **适用表**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`aws.clue_info`、`dw.dim_user`

### 用户手机号

- **定义**：用户的手机号码
- **判断方式**：`dw.dim_user.phone`，取值时必须解码：
  ```sql
  if(phone is null, phone, if(phone rlike '^\\d+$', phone, cast(unbase64(phone) as string))) as phone
  ```
- **适用表**：`dw.dim_user`
- **⚠️ 注意**：phone 字段存在纯数字明文和 base64 编码两种格式，不解码会导致部分手机号为乱码

### 用户性别

- **定义**：用户的性别
- **判断方式**：`gender` 字段，枚举值 `male`（男）、`female`（女）、`NULL`（未填写）
- **适用表**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`dw.dim_user`、`aws.clue_info`

### 用户省份

- **定义**：用户所在的省/市/区地理位置
- **判断方式**：`province`（省）、`city`（市）、`area`（区）
- **适用表**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`dw.dim_user`、`aws.clue_info`
- **⚠️ 注意**：线索表无 `area` 字段

### 用户城市线级

- **定义**：用户所在城市的经济发展等级
- **判断方式**：`city_class` 字段
- **适用表**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`aws.clue_info`

### 用户学生家长身份

- **定义**：用户的实际身份类型（学生/家长/学生家长共用/老师）
- **判断方式**：使用 `real_identity` 字段：
  - 判断是否家长：`real_identity IN ('parents', 'student_parents')`
  - 完整身份判断：
    ```sql
    CASE 
      WHEN real_identity = 'student' THEN '纯学生'
      WHEN real_identity = 'student_parents' THEN '学生家长共用'
      WHEN real_identity = 'parents' THEN '纯家长'
      ELSE '其他' 
    END
    ```
- **适用表**：`dw.dim_user`（仅用户表有 `real_identity`，其他表需 JOIN）
- **⚠️ 注意**：
  - 禁止使用 `role` 判断是否家长，`role = 'student'` 中约 30% 实际是家长
  - 线索表的 `real_identity` 将 `parents` 和 `student_parents` 统一标记为 `parents`

---

## 二、活跃相关

> 默认看 C 端活跃，★必加条件 → `code/sql/表结构/【电销】_tanchen/用户活跃表_日.sql` 【常用筛选条件】

### 活跃量

- **定义**：统计周期内的活跃用户数
- **计算方式**：`COUNT(DISTINCT u_user)`
- **表来源**：`dws.topic_user_active_detail_day`（日维度）、`dws.topic_user_active_detail_month`（月维度）
- **筛选条件**：★必加条件 → `code/sql/表结构/【电销】_tanchen/用户活跃表_日.sql` 【常用筛选条件】

### 学习活跃量

- **定义**：统计周期内有学习行为的活跃用户数，区别于普通活跃
- **计算方式**：`COUNT(DISTINCT CASE WHEN is_learn_active_user = 1 THEN u_user END)`
- **表来源**：`dws.topic_user_active_detail_day`
- **筛选条件**：在活跃表★必加条件基础上增加 `is_learn_active_user = 1`

### 活跃转化率

- **定义**：活跃用户中有付费行为的用户占比
- **计算方式**：`COUNT(DISTINCT 付费用户) / COUNT(DISTINCT 活跃用户)`
  - 分母：活跃用户数，from `dws.topic_user_active_detail_day`（加★必加条件）
  - 分子：付费用户数，from `dws.topic_order_detail`（`status = '支付成功'` + `is_test_user = 0`）
  - 关联：`活跃表.u_user = 订单表.u_user`
- **表来源**：`dws.topic_user_active_detail_day` + `dws.topic_order_detail`
- **⚠️ 注意**：用全量订单表（不是电销订单表），加 `status = '支付成功'`，衡量活跃用户整体付费情况
- **参考 SQL**：→ `sql-patterns.md` #T-ACT-02

---

## 三、订单与营收

> **⚠️ 退款处理规则**：
> - **电销业务口径**（`aws.crm_order_info`）：默认**剔除退款**，`status = '支付成功'` 即可排除已退款订单（退款后 status 会变更）；需分析退款时间、分批退款明细时才关联 `dw.fact_order_detail_refund`
> - **电销 GMV / 服务期口径**（`dws.topic_order_detail`）：默认**不剔除退款**，统计原始支付金额
> 电销业务、电销 GMV、服务期是同一组指标（营收 / 订单量 / 付费人数）从不同归属维度看的结果，不是独立指标。
> **⚠️ 判断购买历史必须用全量订单表**：判断用户是否购买过某商品时，强制使用 `dws.topic_order_detail`，禁止用单业务表（用户可能多渠道购买，单表会遗漏）。

### 正价订单

- **定义**：实收金额 >= 39 元的订单
- **判断方式**：
  | 表 | 表达式 |
  |----|--------|
  | 全量订单表 `dws.topic_order_detail` | `order_amount >= 39` |
  | 电销订单表 `aws.crm_order_info` | `amount >= 39` |
- **适用表**：`dws.topic_order_detail`、`aws.crm_order_info`
- **⚠️ 注意**：`is_normal_price = 1` 与金额判断结果略有差异，不推荐

### 电销业务口径指标

> 数据来源：`aws.crm_order_info`，默认**剔除退款**
> 筛选条件：`status = '支付成功'` + ★必加条件 → `code/sql/表结构/【电销】_tanchen/电销订单表.sql`
> 退款剔除方式：`status = '支付成功'` 自然排除已退款订单，无需额外关联退款表

#### 电销业务营收

- **定义**：电销业务订单的净营收金额（剔除退款）
- **计算方式**：`SUM(amount)`（`status = '支付成功'` 已排除退款订单）
- **表来源**：`aws.crm_order_info`
- **⚠️ 注意**：按坐席拆分 `GROUP BY worker_id`，"坐席营收"只是组织维度拆分，不是独立指标

#### 电销业务订单量

- **定义**：电销业务的有效订单数（剔除退款）
- **计算方式**：`COUNT(DISTINCT order_id)`
- **表来源**：`aws.crm_order_info`

#### 电销业务付费人数

- **定义**：电销业务中产生有效订单的用户数（剔除退款）
- **计算方式**：`COUNT(DISTINCT user_id)`
- **表来源**：`aws.crm_order_info`

### 电销 GMV 口径指标

> 全公司经营分析口径，默认**不剔除退款**，统计原始支付金额
> 数据来源：`dws.topic_order_detail`
> 筛选条件：`status = '支付成功'` + `is_test_user = 0`
> 电销筛选：`business_gmv_attribution` 按优先级将订单归属到唯一一个业务
> ⚠️ 双服务期用户可能归非电销

#### 电销 GMV 营收

- **定义**：全公司订单按 GMV 归属维度拆分到电销的营收（不剔除退款）
- **计算方式**：`SUM(order_amount)`（按 order_id 去重后）或 `SUM(sub_amount)`（子商品粒度），按 `business_gmv_attribution` 筛选
- **表来源**：`dws.topic_order_detail`
- **⚠️ 注意**：`dws.topic_order_detail` 粒度为子商品（sub_good_sk），同一 order_id 可能有多行；统计营收用 `SUM(sub_amount)` 或按 order_id 去重后 `SUM(order_amount)`

#### 电销 GMV 订单量

- **定义**：按 GMV 归属维度归到电销的订单数
- **计算方式**：`COUNT(DISTINCT order_id)`
- **表来源**：`dws.topic_order_detail`

#### 电销 GMV 付费人数

- **定义**：按 GMV 归属维度归到电销的付费用户数
- **计算方式**：`COUNT(DISTINCT u_user)`
- **表来源**：`dws.topic_order_detail`

### 服务期口径指标

> 数据来源：`dws.topic_order_detail`，默认**不剔除退款**（与 GMV 同源）
> 筛选条件：`status = '支付成功'` + `is_test_user = 0`
> 服务期筛选：`array_contains(team_names, '电销')` 或按其他业务名称筛选
> ⚠️ `team_names` 是数组字段，一单可归多个服务期，按单个业务汇总时金额存在重复计算

#### 服务期营收

- **定义**：全公司订单按服务期归属维度拆分的营收（不剔除退款）
- **计算方式**：`SUM(order_amount)`（按 order_id 去重后）或 `SUM(sub_amount)`（子商品粒度），按 `team_names` 筛选
- **表来源**：`dws.topic_order_detail`
- **⚠️ 注意**：一单可归多个服务期，按单个业务统计时总额可能大于公司整体营收

#### 服务期订单量

- **定义**：按服务期归属维度拆分的订单数
- **计算方式**：`COUNT(DISTINCT order_id)`
- **表来源**：`dws.topic_order_detail`

#### 服务期付费人数

- **定义**：按服务期归属维度拆分的付费用户数
- **计算方式**：`COUNT(DISTINCT u_user)`
- **表来源**：`dws.topic_order_detail`

### ⚠️ 三种口径差异

| 口径 | 数据来源 | 归属方式 | 退款处理 | 特点 |
|------|---------|---------|---------|------|
| 电销业务 | `aws.crm_order_info` | 电销专用表，只含电销订单 | 默认剔除退款 | 口径最窄，净营收 |
| 电销 GMV | `dws.topic_order_detail` | `business_gmv_attribution` 按优先级归属 | 默认不剔除退款 | 一单归一个业务，经营分析用 |
| 服务期 | `dws.topic_order_detail` | `team_names` 按服务期归属 | 默认不剔除退款 | 一单可归多个，金额可能重复 |

### 营收选表指南

| 查询场景 | 使用表 | 关键字段 | 退款 |
|---------|-------|---------|------|
| 电销业务营收 / 订单量 / 付费人数 | `aws.crm_order_info` | `amount` / `order_id` / `user_id` | 默认剔除 |
| 各业务 GMV 营收 / 订单量 / 付费人数 | `dws.topic_order_detail` | `business_gmv_attribution` | 默认不剔除 |
| 服务期营收 / 订单量 / 付费人数 | `dws.topic_order_detail` | `team_names` | 默认不剔除 |
| 判断用户购买历史 | `dws.topic_order_detail` | — | — |

### 当配/往期营收占比

- **定义**：将电销营收按线索领取时间与成交时间的关系拆分为三类，用于定位营收异常和预测当月营收
  | 分类 | 判断条件 | 含义 |
  |------|---------|------|
  | 当月领取（当配） | `substr(created_at,1,7) = substr(pay_time,1,7)` | 领取月 = 成交月 |
  | 非当月领取（往期） | `recent_info_uuid IS NOT NULL` 且领取月 ≠ 成交月 | 领取月早于成交月，存量线索的长尾转化 |
  | 无领取记录 | `recent_info_uuid IS NULL` | 订单无法关联到线索领取记录 |
- **判断方式**：通过 `aws.crm_order_info.recent_info_uuid = aws.clue_info.info_uuid` 关联线索，比较 `clue_info.created_at`（领取时间）与 `pay_time`（成交时间）的月份；线索来源名称需 JOIN `tmp.wuhan_clue_soure_name`
- **适用表**：`aws.crm_order_info` + `aws.clue_info` + `tmp.wuhan_clue_soure_name`
- **⚠️ 注意**：
  - 业务用途：当配占比高说明新线索转化效率高；往期占比高说明营收依赖存量线索长尾转化。可用当配转化率预估当月最终营收
  - SQL 中 `status` 作为分组维度而非过滤条件，下游使用时需筛选 `status = '支付成功'` 才是净营收口径
  - 占比计算在下游 Excel/BI 工具完成，SQL 仅输出分组明细
- **参考 SQL**：`code/sql/营收拆分类/月度营收分线索来源当配往期占比.sql`

---

## 四、线索相关

> `aws.clue_info`★必加条件 → `code/sql/表结构/【电销】_tanchen/电销线索领取记录表.sql` 【★必加条件】

### 在库 / 在坐席名下

- **定义**：用户在统计日期处于某坐席的线索有效期内
- **判断方式**：
  - 线索表：`created_at <= '统计日期' AND clue_expire_time >= '统计日期'`
  - 活跃表：`is_clue_seat = 1`（当天快照）
- **适用表**：`aws.clue_info`、`dws.topic_user_active_detail_day`
- **⚠️ 注意**：
  - 一个用户同一时间只属于一个坐席（不会存在时间交叉）
  - 判断某天在库时，该天之后领取的线索不算在库

### 电销服务期

- **定义**：用户被电销触达（领取）后进入的服务期，时长与线索来源有关
- **判断方式**：`user_allocation` 包含"电销"
- **适用表**：`dws.topic_user_active_detail_day`、`dw.dim_user`
- **⚠️ 注意**：在电销服务期 ≠ 在库，线索可能已过期但服务期未结束

### 公海池线索

- **定义**：电话线索流程中经过公海池过滤规则、进入公海池等待坐席领取的线索
- **判断方式**：仅电话线索（`clue_source` 含 `mid_school`）经过公海池流程，企微线索不经过
- **适用表**：`aws.crm_active_data_pool_day`、`aws.crm_active_data_pool_month`、`aws.clue_info`
- **⚠️ 注意**：业务流程详情 → `business-context.md` #1.1 电话线索 / #1.3 公海池

### 领取线索量 / 消耗线索量

- **定义**：被领取的用户数
- **计算方式**：`COUNT(DISTINCT user_id)`
- **表来源**：`aws.clue_info`
- **⚠️ 注意**：
  - 同一用户可被多次领取，统计线索量时要去重，去重的维度按实际需求来，无要求默认参考 `sql-patterns.md` #T-CLU-01
  - **日报口径（默认）**：除非用户明确要求去重口径，一律先在日报粒度 COUNT DISTINCT，再按需求维度 SUM。原因：COUNT DISTINCT 不可加，直接在月度/整体粒度做会导致跨日去重，与日报表数据无法对齐。领取线索量的量级统计和按任意维度（来源、等级、坐席、团组等）查看分布时同理
  - 日报粒度字段清单：`日期 + worker_id + 用户类型 + 付费状态 + 线索学段(b) + 线索等级 + 线索名称(b) + 线索一级分类(b) + 新老人 + 职场 + 部门 + 团 + 小组`，其中线索学段、线索名称、线索一级分类需关联 `tmp.wuhan_clue_soure_name b ON a.clue_source = b.clue_source` 取得
- **参考 SQL**：`sql-patterns.md` #T-CLU-01

### 线索领取次数 / 线索流转次数

- **定义**：线索被领取的总次数（含同一用户多次领取）
- **计算方式**：`COUNT(info_uuid)`
- **表来源**：`aws.clue_info`
- **⚠️ 注意**：线索表自带转化字段（`paid_cnt`、`paid_amount` 等）口径不明确，不建议使用，转化需求应直接关联 `aws.crm_order_info` 计算

### 电话线索漏斗指标

> 核心漏斗：活跃 → 推送 → 入库 → 领取，逐层递减。
> 活跃领取量独立于上述漏斗，包含所有线索来源的领取。

#### 活跃量

- **定义**：统计周期内的活跃用户数
- **计算方式**：`COUNT(DISTINCT active_u_user)`
- **表来源**：`aws.crm_active_data_pool_month`、`aws.crm_active_data_pool_day`、`crm_active_data_pool_paid_month`

#### 推送量

- **定义**：统计周期内被数仓推送到电销系统的用户数（活跃用户的子集）
- **计算方式**：`COUNT(DISTINCT push_u_user)`
- **表来源**：`aws.crm_active_data_pool_month`、`aws.crm_active_data_pool_day`、`crm_active_data_pool_paid_month`

#### 入库量

- **定义**：统计周期内通过公海池过滤规则、进入公海池的用户数（推送用户的子集）
- **计算方式**：`COUNT(DISTINCT enter_datapool_u_user)`
- **表来源**：`aws.crm_active_data_pool_month`、`aws.crm_active_data_pool_day`、`crm_active_data_pool_paid_month`

#### 入库领取量

- **定义**：统计周期内从公海池被坐席领取的用户数，仅限电话线索（`mid_school`）
- **计算方式**：`COUNT(DISTINCT recieve_u_user)`
- **表来源**：`aws.crm_active_data_pool_month`、`aws.crm_active_data_pool_day`、`crm_active_data_pool_paid_month`
- **⚠️ 注意**：是入库用户的子集，不是所有领取用户

#### 活跃领取量

- **定义**：统计周期内活跃用户中被坐席领取的用户数，不限线索来源（含企微等非公海池渠道）
- **计算方式**：`COUNT(DISTINCT recieve_u_user_all)`
- **表来源**：`aws.crm_active_data_pool_month`、`aws.crm_active_data_pool_day`、`crm_active_data_pool_paid_month`
- **⚠️ 注意**：
  - 与入库领取量的区别：入库领取量仅含公海池链路（`mid_school`），活跃领取量含所有渠道
  - 跨表同名字段含义不同：漏斗表 `recieve_u_user_all` 无公海池前置条件；转化表 `crm_active_data_pool_paid_month` 的同名字段有公海池前置条件，等价字段为 `active_recieve_u_user_all`

### 企微业务选表指南

> **⚠️ 核心原则**：企微相关取数涉及多张表，根据业务场景选择正确的表。

| 需求场景 | 使用表 | 说明 |
|---------|-------|------|
| **整体月度企微活跃添加率**（不分渠道） | `aws.crm_active_user_wechat_paid_month` | 宏观表，活跃→添加→入库→转化，无中间漏斗环节 |
| **分渠道添加量 / 添加转化** | `crm.contact_log` + `aws.clue_info` | 按渠道活码维度拆解 |
| **日活/月活企微添加量**（不分渠道） | `aws.crm_active_user_wechat_paid_month` | 直接取 `add_wechat_u_user` |
| **日活/月活企微添加量**（分渠道） | 活跃表 + `crm.contact_log` | 活跃表提供活跃用户，contact_log 提供渠道维度的添加数据，聚合计算 |
| **五层漏斗（定位异常 / 资源位调优）** | `aws.user_pay_process_add_wechat_day/month` | 含曝光→点击→二维码曝光→添加→入库五层，用于定位添加过程异常、资源位效率低于平均值 |
| **坐席二维码曝光→添加率** | `crm.new_user` | 单看坐席二维码曝光到添加的转化率，**不用于统计企微添加量** |
### 企微漏斗指标
> 核心漏斗：资源位曝光 → 点击入口 → 曝光坐席二维码 → 添加坐席微信 → 拉取入库，逐层递减。
> 仅用于定位企微添加过程异常及资源位效率调优，常规企微取数用下方"常规企微业务指标"。
> 资源位通过 `task_id`（渠道活码 ID）区分，可按渠道活码维度拆分看各资源位效率。用户入库后同一 ID 记录在 `aws.clue_info.qr_code_channel_id`。
#### 企微资源位曝光量

- **定义**：统计周期内资源位曝光的用户数
- **计算方式**：`COUNT(DISTINCT get_entrance_user)`
- **表来源**：`aws.user_pay_process_add_wechat_day`、`aws.user_pay_process_add_wechat_month`

#### 企微资源位点击量

- **定义**：统计周期内点击资源位入口的用户数（曝光用户的子集）
- **计算方式**：`COUNT(DISTINCT click_entrance_user)`
- **表来源**：`aws.user_pay_process_add_wechat_day`、`aws.user_pay_process_add_wechat_month`

#### 坐席企微二维码曝光量

- **定义**：统计周期内曝光了坐席二维码的用户数（点击用户的子集）
- **计算方式**：`COUNT(DISTINCT get_wechat_user)`
- **表来源**：`aws.user_pay_process_add_wechat_day`、`aws.user_pay_process_add_wechat_month`

#### 坐席企微添加量

- **定义**：统计周期内添加了坐席微信的用户数（二维码曝光用户的子集）
- **计算方式**：`COUNT(DISTINCT add_wechat_user)`
- **表来源**：`aws.user_pay_process_add_wechat_day`、`aws.user_pay_process_add_wechat_month`

#### 企微拉取入库量

- **定义**：统计周期内被坐席成功拉取入库的用户数（添加用户的子集）
- **计算方式**：`COUNT(DISTINCT pull_wechat_user)`
- **表来源**：`aws.user_pay_process_add_wechat_day`、`aws.user_pay_process_add_wechat_month`

#### 活码资源位点击率

- **定义**：点击量 / 曝光量
- **计算方式**：`COUNT(DISTINCT click_entrance_user) / COUNT(DISTINCT get_entrance_user)`
- **表来源**：`aws.user_pay_process_add_wechat_day`、`aws.user_pay_process_add_wechat_month`

#### 坐席二维码曝光率

- **定义**：二维码曝光量 / 点击量
- **计算方式**：`COUNT(DISTINCT get_wechat_user) / COUNT(DISTINCT click_entrance_user)`
- **表来源**：`aws.user_pay_process_add_wechat_day`、`aws.user_pay_process_add_wechat_month`

#### 企微添加率

- **定义**：添加量 / 二维码曝光量
- **计算方式**：`COUNT(DISTINCT add_wechat_user) / COUNT(DISTINCT get_wechat_user)`
- **表来源**：`aws.user_pay_process_add_wechat_day`、`aws.user_pay_process_add_wechat_month`

#### 企微拉取入库率

- **定义**：拉取入库量 / 添加量
- **计算方式**：`COUNT(DISTINCT pull_wechat_user) / COUNT(DISTINCT add_wechat_user)`
- **表来源**：`aws.user_pay_process_add_wechat_day`、`aws.user_pay_process_add_wechat_month`

#### 资源位点击→坐席二维码曝光 中间漏斗细查

> 默认漏斗（五层）不含以下两步。当需要定位"资源位点击→坐席二维码曝光"之间转化异常时，可单独插入这两层细查。
> 数据来源：`events.frontend_event_orc`（非漏斗汇总表），需以漏斗表 `click_entrance_user` 为基准用户，按 `user + day` 关联埋点事件。
> 参考 SQL：`code/sql/看板/【电销】_tanchen/企微相关/企微活码点击资源位到小程序二维码曝光之间新增漏斗.sql`

##### 跳转微信过渡页曝光量

- **定义**：点击资源位后弹出跳转微信过渡页的用户数（部分手机展示后自动跳转，部分需点击确认；两种情况均正常上报埋点）
- **计算方式**：`COUNT(DISTINCT u_user)` WHERE `event_key = 'enterOpenWechatTransitionPage'`
- **表来源**：`events.frontend_event_orc`（`event_type = 'enter'`）
- **筛选条件**：`LENGTH(u_user) > 0 AND LENGTH(task_id) > 0`；`task_id` = 渠道活码 ID，可按渠道活码维度拆分

##### 进入企微添加小程序量

- **定义**：确认跳转后进入企微添加小程序首页的用户数（自动跳转场景也正常上报）
- **计算方式**：`COUNT(DISTINCT u_user)` WHERE `event_key = 'enterWeComAddMiniProgramHomePage'`
- **表来源**：`events.frontend_event_orc`（`event_type = 'enter'`）
- **筛选条件**：`LENGTH(u_user) > 0 AND LENGTH(task_id) > 0`；`task_id` 同上

### 企微常规业务指标

> 数据来源：`crm.contact_log`（添加）+ `aws.clue_info`（拉取入库）+ `crm.qr_code_change_history`（渠道维度）
> 拉取入库时间窗口：入库时间 > 添加时间 且 < 添加时间+1天
>
> **参考 SQL**：
> - 不分组织架构：`code/sql/看板/【电销】_tanchen/企微相关/企微添加拉取入库转化情况_不分组织架构.sql`
> - 分组织架构：`code/sql/看板/【电销】_tanchen/企微相关/企微添加拉取入库转化情况_分组织架构.sql`

#### 企微添加量

- **定义**：通过渠道活码添加坐席企微的用户数
- **计算方式**：`COUNT(DISTINCT external_user_id)`
- **表来源**：`crm.contact_log`（`source = 3` 且 `change_type = 'add_external_contact'`）
- **⚠️ 注意**：去重粒度和额外筛选因"是否分组织架构"不同，详见参考 SQL

#### 拉取入库量（常规）

- **定义**：添加企微后被成功拉取入库的用户数
- **计算方式**：`COUNT(DISTINCT ex_user_id)`（`ex_user_id` 来自 `aws.clue_info.we_com_open_id`）
- **表来源**：`crm.contact_log` LEFT JOIN `aws.clue_info`
- **⚠️ 注意**：关联条件和去重粒度因"是否分组织架构"不同，详见参考 SQL

#### 企微拉取入库率（常规）

- **定义**：拉取入库量 / 企微添加量
- **计算方式**：`COUNT(DISTINCT ex_user_id) / COUNT(DISTINCT external_user_id)`
- **表来源**：同上

#### 企微坐席二维码曝光添加率
- **定义**：坐席二维码曝光后用户添加企微的比率
- **计算方式**：
  - 分子（添加用户数）：`COUNT(DISTINCT CASE WHEN length(external_user_id) > 0 THEN external_user_id END)`
  - 分母（曝光用户数）：日维度 `COUNT(channel_id)`，月维度 `COUNT(DISTINCT external_user_id)`
- **表来源**：`crm.new_user`（`channel = 3`）
- **筛选条件**：`channel = 3`（渠道活码）+ `group_id0 IN (4, 400, 702)`（电销职场）
- **⚠️ 注意**：与漏斗表的添加率因埋点数据损耗有差异，不用于统计企微添加量
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/企微相关/企微坐席二维码曝光添加率.sql`

#### 企微添加拉取入库转化率

- **定义**：基于原始日志表的企微转化分析，可分渠道、分组织架构
- **计算方式**：
  | 指标 | SQL 表达式 |
  |------|-----------|
  | 企微添加量 | `COUNT(DISTINCT external_user_id)` |
  | 拉取入库量 | `COUNT(DISTINCT ex_user_id)` |
  | 转化用户量 | `COUNT(DISTINCT paid_userid)` |
  | 转化金额 | `SUM(amount)` |
- **表来源**：`crm.contact_log` + `aws.clue_info` + `aws.crm_order_info`
- **⚠️ 注意**：转化时间窗口因维度不同而异（按渠道为累积，按渠道+组织架构为多窗口），详见参考 SQL
- **参考 SQL**：
  - 不分组织架构：`code/sql/看板/【电销】_tanchen/企微相关/企微添加拉取入库转化情况_不分组织架构.sql`
  - 分组织架构：`code/sql/看板/【电销】_tanchen/企微相关/企微添加拉取入库转化情况_分组织架构.sql`

#### 活跃企微添加拉取入库转化

- **定义**：从活跃用户出发看企微添加→拉取入库→付费转化的整体情况（不分渠道，月维度）
- **计算方式**：
  | 指标 | SQL 表达式 |
  |------|-----------|
  | 活跃量 | `COUNT(DISTINCT active_u_user)` |
  | 企微添加量 | `COUNT(DISTINCT add_wechat_u_user)` |
  | 拉取入库量 | `COUNT(DISTINCT recieve_u_user)` |
  | 转化用户量 | `COUNT(DISTINCT recieve_paid_u_user)` |
  | 转化金额 | `SUM(recieve_paid_amount)` |
- **表来源**：`aws.crm_active_user_wechat_paid_month`
- **⚠️ 注意**：不含资源位曝光/点击等中间漏斗，分渠道或看漏斗用其他表 → 上方"企微业务选表指南"
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/企微相关/活跃用户企微活码添加转化情况_月.sql`

### 线索来源

- **定义**：线索进入电销系统的渠道
- **判断方式**：`clue_source` 字段；来源名称需 JOIN 维表 `tmp.wuhan_clue_soure_name`
- **适用表**：`aws.clue_info`
- **⚠️ 注意**：
  - 下钻字段：`mid_school` → `tag`（用户画像分层），`WeCom` → `wecom_clue_level_id`(渠道活码等级) → `qr_code_channel_id`(渠道活码id)
  - 枚举值 → `code/sql/表结构/【电销】_tanchen/电销线索领取记录表.sql` 文件末尾
  - 业务流程 → `business-context.md` #一、线索业务

### 领取转化率
- **定义**：领取线索后的付费转化比率
- **计算方式**：`SUM(paid_cnt) / SUM(recieve_cnt)`
  - 分母：日报粒度 `COUNT(DISTINCT user_id)` from `aws.clue_info`
  - 分子：日报粒度 `COUNT(DISTINCT user_id)` from `aws.crm_order_info`，关联条件 `pay_time >= created_at`
- **表来源**：`aws.clue_info` + `aws.crm_order_info`
- **筛选条件**：有订单即算转化，不限 `status`；电销订单表其他★必加条件必须加 → `code/sql/表结构/【电销】_tanchen/电销订单表.sql`
- **⚠️ 注意**：
  - **日报口径（默认）**：必须先按日报粒度聚合再按需求维度 SUM，不可直接在大粒度做 COUNT DISTINCT（COUNT DISTINCT 不可加，否则与日报表数据无法对齐）。日报粒度字段清单和 SQL 模板 → 上方「领取线索量 / 消耗线索量」条目
  - 转化时间窗口：当日 / 3天 / 7天 / 14天 / 21天 / 30天 / 当月（领取月=成交月）/ 累积，仅转化周期不同，计算逻辑一致
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/领取转化率/分团组领取转化率_日报表.sql`，模板 → `sql-patterns.md` #T-CLU-01

### 定向分配线索转化率

- **定义**：定向分配线索在领取当月内的转化比率
- **计算方式**：`COUNT(DISTINCT 转化user_id) / COUNT(DISTINCT user_id)`
  - 分母：`aws.clue_info` WHERE `clue_source = 'mid_school_manual'`
  - 分子：关联 `aws.crm_order_info`，`pay_time >= created_at AND substr(pay_time,1,7) = substr(created_at,1,7)`
- **表来源**：`aws.clue_info` + `aws.crm_order_info`
- **筛选条件**：电销订单表★必加条件 → `code/sql/表结构/【电销】_tanchen/电销订单表.sql`；可选 `note` 字段按批次拆分
- **⚠️ 注意**：与领取转化率的区别是转化窗口限定领取当月内
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/定向分配业务/定向分配数据转化.sql`

### 人工录入线索转化率

- **定义**：人工录入线索在领取当月内的转化比率
- **计算方式**：与定向分配线索转化率一致，仅 `clue_source = 'manual'`
- **表来源**：`aws.clue_info` + `aws.crm_order_info`

### 客服推送线索转化率

- **定义**：客服推送线索在领取当月内的转化比率
- **计算方式**：与定向分配线索转化率基本一致，`clue_source = 'custom_service_manual'`，不限制领取人与转化人的对应关系
- **表来源**：`aws.clue_info` + `aws.crm_order_info`

### 当配转化率

- **定义**：当月领取的线索在当月内完成转化的比率（领取月 = 成交月）
- **计算方式**：`COUNT(DISTINCT 转化user_id) / COUNT(DISTINCT user_id)`，转化窗口 `substr(pay_time,1,7) = substr(created_at,1,7)`
- **表来源**：`aws.clue_info` + `aws.crm_order_info`
- **筛选条件**：电销订单表★必加条件 → `code/sql/表结构/【电销】_tanchen/电销订单表.sql`
- **⚠️ 注意**：
  - 与领取转化率的区别：领取转化率无时间截止（累积），当配限定领取月=成交月
  - 当月实时需显式加 `substr(pay_time,1,10) <= last_day(substr(created_at,1,7))`
  - 按线索来源拆分的变体（转化逻辑一致，仅分母来源不同）：
    | 口径 | 分母来源 |
    |------|---------|
    | 电话线索当配 | `mid_school`、`building_blocks_goods_midschool` |
    | 企微线索当配 | `WeCom`、`building_blocks_goods_wecom` |
    | 系统当配 | `mid_school`、`mid_school_manual`、`building_blocks_goods_midschool` |

## 五、外呼相关

> 底表：`dw.fact_call_history`，DDL → `code/sql/表结构/【电销】_tanchen/外呼记录表.sql`
> tmp 表：`tmp.niyiqiao_crm_clue_call_record`，DDL → `code/sql/表结构/【电销】_tanchen/外呼记录表_tmp.sql`
> 选表规则 → `code/sql/表结构/【电销】_tanchen/外呼记录表.sql` 【业务定位】
> 判断接通统一用 `is_connect`，有效接通用 `is_valid_connect`，不要用 `call_state` / `call_status`
>
> **筛选条件**：
> - 用 tmp 表：无需额外筛选（已内置职场/团组过滤，覆盖 2023-01-01 至昨日）
> - 用底表：★必加 `workplace_id IN (4, 400, 702)` + `regiment_id NOT IN (0, 303, 546)`

### 外呼时间

- **定义**：外呼发起/拨打的时间
- **判断方式**：`created_at` 字段
- **适用表**：`dw.fact_call_history`、`tmp.niyiqiao_crm_clue_call_record`

### 接通时间

- **定义**：电话被接通的时间
- **判断方式**：`call_start_time` 字段
- **适用表**：`dw.fact_call_history`、`tmp.niyiqiao_crm_clue_call_record`

### 外呼电话量

- **定义**：外呼的总次数
- **计算方式**：`COUNT(action_id)`
- **表来源**：`dw.fact_call_history` 或 `tmp.niyiqiao_crm_clue_call_record`

### 外呼线索量

- **定义**：统计周期内被外呼的用户数（按用户去重）
- **计算方式**：`COUNT(DISTINCT user_id)`
- **表来源**：`dw.fact_call_history` 或 `tmp.niyiqiao_crm_clue_call_record`

### 线索外呼次数 / 线索外呼深度

- **定义**：平均每个被外呼用户的外呼次数
- **计算方式**：`COUNT(action_id) / COUNT(DISTINCT user_id)`
- **表来源**：`dw.fact_call_history` 或 `tmp.niyiqiao_crm_clue_call_record`

### 电话接通量

- **定义**：接通的外呼次数
- **计算方式**：`COUNT(CASE WHEN is_connect = 1 THEN action_id END)`
- **表来源**：`dw.fact_call_history` 或 `tmp.niyiqiao_crm_clue_call_record`

### 线索接通量

- **定义**：有接通记录的用户数
- **计算方式**：`COUNT(DISTINCT CASE WHEN is_connect = 1 THEN user_id END)`
- **表来源**：`dw.fact_call_history` 或 `tmp.niyiqiao_crm_clue_call_record`

### 电话有效接通量

- **定义**：通话时长 ≥ 10 秒的接通次数
- **计算方式**：`COUNT(CASE WHEN is_valid_connect = 1 THEN action_id END)`
- **表来源**：`dw.fact_call_history` 或 `tmp.niyiqiao_crm_clue_call_record`

### 线索有效接通量

- **定义**：有有效接通记录（通话 ≥ 10 秒）的用户数
- **计算方式**：`COUNT(DISTINCT CASE WHEN is_valid_connect = 1 THEN user_id END)`
- **表来源**：`dw.fact_call_history` 或 `tmp.niyiqiao_crm_clue_call_record`
- **⚠️ 注意**：`aws.clue_info` 的 `valid_call_cnt` 字段有汇总值可直接使用

### 电话接通率

- **定义**：接通电话量占外呼电话量的比率
- **计算方式**：`COUNT(CASE WHEN is_connect = 1 THEN action_id END) / COUNT(action_id)`
- **表来源**：`dw.fact_call_history` 或 `tmp.niyiqiao_crm_clue_call_record`

### 电话有效接通率

- **定义**：有效接通电话量占外呼电话量的比率
- **计算方式**：`COUNT(CASE WHEN is_valid_connect = 1 THEN action_id END) / COUNT(action_id)`
- **表来源**：`dw.fact_call_history` 或 `tmp.niyiqiao_crm_clue_call_record`

### 线索接通率

- **定义**：有接通记录的用户数占外呼用户数的比率
- **计算方式**：`COUNT(DISTINCT CASE WHEN is_connect = 1 THEN user_id END) / COUNT(DISTINCT user_id)`
- **表来源**：`dw.fact_call_history` 或 `tmp.niyiqiao_crm_clue_call_record`

### 线索有效接通率

- **定义**：有有效接通记录的用户数占外呼用户数的比率
- **计算方式**：`COUNT(DISTINCT CASE WHEN is_valid_connect = 1 THEN user_id END) / COUNT(DISTINCT user_id)`
- **表来源**：`dw.fact_call_history` 或 `tmp.niyiqiao_crm_clue_call_record`

---

## 六、组织架构

> 组织层级（从大到小）：职场 → 学部 → 团 → 主管组 → 小组 → 坐席
> 名称字段需 JOIN 维表 `dw.dim_crm_organization`（或 `crm.organization`）
> 员工数据：`crm.staff_change`（变动记录）+ `crm.worker`（坐席信息），通过 `email = mail` 关联

### 职场

- **定义**：组织架构最顶层，业务按职场划分
- **判断方式**：`workplace_id` 字段；电销职场 = `workplace_id IN (4, 400, 702)`
- **适用表**：`aws.clue_info`、`aws.crm_order_info`、`dws.topic_order_detail`

### 学部

- **定义**：职场下的业务学部划分
- **判断方式**：`department_id` 字段；名称需 JOIN `dw.dim_crm_organization`
- **适用表**：`aws.clue_info`、`aws.crm_order_info`

### 团队

- **定义**：学部下的团队划分
- **判断方式**：`regiment_id` 字段；常用排除 `regiment_id NOT IN (0, 303, 546)`
- **适用表**：`aws.clue_info`、`aws.crm_order_info`

### 主管组

- **定义**：团队下的主管组划分
- **判断方式**：`heads_id` 字段
- **适用表**：`aws.clue_info`、`aws.crm_order_info`

### 小组

- **定义**：主管组下的小组划分
- **判断方式**：`team_id` 字段
- **适用表**：`aws.clue_info`、`aws.crm_order_info`

### 员工入离职时间

- **定义**：员工的入职日期和离职日期
- **判断方式**：
  - 入职时间：`SUBSTR(start_date, 1, 10)` from `crm.staff_change`
  - 离职时间：`SUBSTR(stop_date, 1, 10)`，`0001-01-01` / `0001-01-03` 表示在职（转为 NULL）
  - 同一员工多条记录时按 `employment_no` 分组取 `created_at` 最新一条
- **适用表**：`crm.staff_change` + `crm.worker`
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/人效相关/在职人员每月人效情况.sql`

### 在职状态

- **定义**：员工在某个时间点是否在职
- **计算方式**：`in_date <= 日期 AND (out_date IS NULL OR out_date >= 日期)`
  | 场景 | 判断逻辑 |
  |------|---------|
  | 某日在职 | `in_date <= 日期 AND (out_date IS NULL OR out_date >= 日期)` |
  | 当月入职 | `in_date BETWEEN 月初 AND 月末` |
  | 当月离职 | `out_date IS NOT NULL AND out_date BETWEEN 月初 AND 月末` |
- **表来源**：`crm.staff_change` + `crm.worker`

### 入职天数

- **定义**：员工从入职到指定日期的天数
- **计算方式**：`DATEDIFF(截止日期, in_date)`
- **表来源**：`crm.staff_change` + `crm.worker`
- **⚠️ 注意**：常用分层 [0,30] 新员工 / (30,60] / (60,90] / (90,120] / (120,150] / (150,180] / (180,360] 半年-1年 / (360,+inf) 1年以上

### 新老人

- **定义**：一线销售坐席在领取线索时按入职时长判断的新人/老人标记（计算字段，非表中列）
- **计算方式**：
  ```sql
  case
    when substr(worker_join_at,1,10) = TRUNC(worker_join_at,'month')
         and substr(worker_join_at,1,10) < add_months(substr(a.created_at,1,7),-2) then '老人'
    when substr(worker_join_at,1,10) > TRUNC(worker_join_at,'month')
         and substr(worker_join_at,1,10) < add_months(substr(a.created_at,1,7),-3) then '老人'
    else '新人'
  end as worker
  ```
- **表来源**：`aws.clue_info`（依赖 `worker_join_at` 和 `created_at`）
- **⚠️ 注意**：月初入职（入职日=当月1日）往前推 2 个月算老人；月中入职往前推 3 个月算老人

### 人效

- **定义**：一线销售坐席的人均营收产出
- **计算方式**：`SUM(营收) / COUNT(一线销售员工数)`
- **表来源**：`aws.crm_order_info`（营收）+ `crm.staff_change` + `crm.worker`（人数）
- **⚠️ 注意**：
  - 分母需排除职能岗（待验证）：营收=0 且 领取≤5 且 外呼=0 且 入职>30天 → 判定为职能岗，排除后计人数
  - 详细识别逻辑 → `sql-patterns.md` #T-HR-01
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/人效相关/在职人员每月人效情况.sql`

---

## 七、商品相关

> 商品类目枚举值 → `code/sql/表结构/【电销】_tanchen/电销订单表.sql` 和 `code/sql/表结构/【电销】_tanchen/全公司订单宽表.sql` 文件末尾

### 组合品与策略续购判断

- **定义**：业务看营收分布时，日常说的"组合品"默认剔除策略续购订单，策略续购单独归为"续购"
- **判断方式**：使用修正字段 `business_good_kind_name_level_1/2/3_modify`（CASE WHEN 修正原始字段），完整修正 SQL → `sql-patterns.md` #T-REV-02
- **适用表**：`dws.topic_order_detail`、`aws.crm_order_info`
- **⚠️ 注意**：当需求涉及"组合品营收"且口径不明确时，反问确认"组合品是否包含策略续购订单？"

---

## 八、业绩目标

> 目标体系采用**自上而下拆标、自下而上汇总**：个人目标 → 小组目标 → 团目标 → 电销整体目标
>
> | 层级 | 数据表 | level 值 | 中间汇总表 |
> |------|--------|---------|-----------|
> | 个人 | `crm.worker_goal` | — | `tmp.wuhan_crm_worker_goal_mm` |
> | 小组 | `crm.group_goal` | `level = 4` | `tmp.wuhan_crm_heads_goal_mm` |
> | 团 | `crm.group_goal` | `level = 3` | `tmp.wuhan_crm_regiment_goal_mm` |

### 业绩目标体系

- **定义**：电销团队分层级管理的月度营收目标，按个人/小组/团三级拆标与汇总
- **判断方式**：`crm.group_goal` 用 `level` 区分团(3)/小组(4)；`crm.worker_goal` 存个人目标；`path` 字段过滤电销职场路径 `REGEXP '^,[^,]+,(4|400)'`
- **适用表**：`crm.group_goal`、`crm.worker_goal`、`crm.worker`（通过 `mail` 关联获取坐席姓名）
- **⚠️ 注意**：
  - 同一组织/坐席同月可能有多条记录，需 `ROW_NUMBER() OVER(... ORDER BY updated_at DESC)` 去重取最新
  - 个人目标去重规则不同：先按 `goal DESC` 再按 `updated_at DESC`（应对同一人多次拆标）
  - 目标与实际营收口径独立：目标来自 `crm.*_goal`，实际营收来自 `aws.crm_order_info`，不要混用
  - 排除特殊团组：`org_id NOT IN (303, 546, 233, 234)`；小组还需排除 `name REGEXP '离职|体验营'`
  - 完整查询 SQL → `sql-patterns.md` #T-GOAL-01；参考文件 `code/sql/看板/【电销】_tanchen/目标相关/团队、小组、个人目标.sql`

---

## 九、转介绍相关

> 转介绍是电销团队的裂变营销活动，老用户邀请新用户购课。拥有独立的数据表、业务流程和指标体系。
>
> **业务流程详情**：→ `business-context.md` #三、转介绍业务
>
> **核心数据表**：
> - 转介绍绑定记录：`crm.new_user`（`channel = 2`）
> - 线索入库：`aws.clue_info`（`clue_source = 'referral'`）
> - 海报下载：`crm.promotion_poster`
> - 朋友圈分享：`crm.point_log_all`（`point_type = 1`）
> - 活动页埋点：`events.frontend_event_orc`
> - 订单转化：`aws.crm_order_info`
>
> **⚠️ 易混淆概念**：
> - **转介绍线索营收 vs 转介绍业务营收**：前者按 `clue_source = 'referral'` 拆分电销营收；后者基于 `crm.new_user` 绑定关系归因，有 6 个月窗口，是独立指标
> - **转介绍新/老用户 vs 坐席新老人**：前者指被推荐人注册状态，后者指坐席入职时长，完全不同

### 转介绍线索

- **定义**：通过转介绍小程序进入且满足转介绍规则的线索
- **判断方式**：`aws.clue_info.clue_source = 'referral'`
- **适用表**：`aws.clue_info`
- **⚠️ 注意**：不满足规则但通过转介绍渠道进入的用户，来源为 `telesale_mp`/`server_number`/`parent`，不归为转介绍线索

### 转介绍绑定关系

- **定义**：推荐人（老用户）与被推荐人（新用户）之间的转介绍绑定记录，有效期 6 个月
- **判断方式**：`crm.new_user.channel = 2`；关键字段 `old_user_id`（推荐人）、`user_id`（被推荐人）、`worker_id`（归属坐席）、`created_at`（绑定时间）、`group_id0~group_id4`（组织架构）
- **适用表**：`crm.new_user`
- **⚠️ 注意**：`crm.new_user` 同时承载企微二维码曝光添加（`channel=3`）等数据，转介绍必须限定 `channel = 2`

### 转介绍被推荐人新/老用户

- **定义**：被推荐人在绑定转介绍关系时的注册状态
- **判断方式**：注册时间与绑定时间差 ≤ 12 小时或尚未注册 → 新用户；否则 → 老用户
  ```sql
  CASE WHEN regist_time > created_at OR regist_time >= from_unixtime(unix_timestamp(created_at) - 12 * 3600) THEN '新用户' ELSE '老用户' END
  ```
- **适用表**：`crm.new_user` + `dw.dim_user`
- **⚠️ 注意**：与「六、组织架构 → 新老人」完全不同——新老人主体是坐席（员工），本概念主体是被推荐人（用户）

### 转介绍线索转化率

- **定义**：转介绍来源线索的领取转化率
- **计算方式**：沿用「四、线索相关 → 领取转化率」标准口径，增加 `clue_source = 'referral'` 筛选
- **表来源**：`aws.clue_info` + `aws.crm_order_info`
- **⚠️ 注意**：使用 `aws.clue_info` 而非 `crm.new_user`；后者用于转介绍业务分析（追踪推荐人→被推荐人链路）

### 转介绍线索营收

- **定义**：转介绍来源线索产生的电销营收
- **计算方式**：`SUM(amount)`，关联 `aws.clue_info` 筛选 `clue_source = 'referral'`
- **表来源**：`aws.crm_order_info`
- **⚠️ 注意**：与"转介绍业务营收"不同——本指标按线索来源拆分电销营收，不涉及绑定关系

### 转介绍业务营收

- **定义**：基于转介绍绑定关系归因的营收，独立于电销营收口径
- **计算方式**：`SUM(amount)`，关联 `crm.new_user`（`channel=2`）；归因窗口 6 个月（`pay_time <= add_months(created_at, 6)`）；多条绑定取 `created_at` 最新
- **表来源**：`aws.crm_order_info` + `crm.new_user`
- **筛选条件**：`status = '支付成功'` + `in_salary = 1` + `is_test = false`
- **⚠️ 注意**：
  - 用户分类：付费月=绑定月 → 当月转介绍新用户；付费月≠绑定月 → 非当月转介绍用户；无匹配 → 其他用户
  - 可按用户分类 × 订单类型 × 商品类型拆分营收构成；商品分类修正 → `glossary.md` #组合品与策略续购判断
  - 参考 SQL：`code/sql/看板/【电销】_tanchen/转介绍相关-电销/转介绍营收构成.sql`

### 下载海报用户数 / 次数

- **定义**：统计周期内下载专属推荐海报的用户数/总次数
- **计算方式**：用户数 `COUNT(DISTINCT user_id)` / 次数 `COUNT(user_id)`
- **表来源**：`crm.promotion_poster`
- **筛选条件**：`worker_id <> 0`

### 发朋友圈用户数

- **定义**：统计周期内有朋友圈分享行为的用户数
- **计算方式**：`COUNT(DISTINCT user_id)`
- **表来源**：`crm.point_log_all`
- **筛选条件**：`point_type = 1`

### 转介绍拉新用户数

- **定义**：统计周期内通过转介绍带来的新用户数
- **计算方式**：`COUNT(DISTINCT user_id)` WHERE `channel = 2`
- **表来源**：`crm.new_user`
- **⚠️ 注意**：此处"拉新"特指转介绍绑定中的被推荐人，非通用新注册用户

### 转介绍推荐人数

- **定义**：统计周期内有成功转介绍拉新行为的推荐人数
- **计算方式**：`COUNT(DISTINCT old_user_id)` WHERE `channel = 2`
- **表来源**：`crm.new_user`

### 转介绍转化（按窗口）

- **定义**：转介绍新用户在指定时间窗口内的付费转化
- **计算方式**：转化用户 `COUNT(DISTINCT user_id)` / 转化金额 `SUM(amount)`；关联 `pay_time > created_at`
- **表来源**：`crm.new_user`（`channel=2`）+ `aws.crm_order_info`
- **筛选条件**：`status = '支付成功'` + `in_salary = 1` + `is_test = false`
- **时间窗口**：
  | 窗口 | 条件 |
  |------|------|
  | 14天 | `pay_time <= date_add(created_at, 14)` |
  | 当月 | `pay_time <= last_day(created_at)` |
  | 次月 | `pay_time <= last_day(add_months(created_at, 1))` |
  | 30天 | `pay_time <= date_add(pay_time_老用户, 30)` |
  | 6个月 | `pay_time <= add_months(created_at, 6)` |
- **⚠️ 注意**：与标准领取转化率数据来源不同——本指标基于 `crm.new_user` 绑定关系，非 `aws.clue_info`
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/转介绍相关-电销/团组转介绍线索领取及转化.sql`

### 推荐有礼活动页漏斗

- **定义**：推荐有礼活动页的曝光→点击→授权→入库→付费漏斗
- **计算方式**：曝光/点击人数 `COUNT(DISTINCT user_id)`；授权人数按渠道取首次；入库按 `clue_source IN ('telesale_mp','server_number','parent','referral')`
- **表来源**：`events.frontend_event_orc`（曝光/点击/授权）+ `aws.clue_info`（入库）
- **⚠️ 注意**：曝光 `event_key IN ('getRecommendGiftsPageButton', 'getDownloadExclusivePostersButton')`；点击 `event_key IN ('clickRecommendGiftsPageButton', 'clickDownloadExclusivePostersButton')`；渠道字段 `from_channel`/`c_from` 枚举见参考 SQL
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/转介绍相关-电销/推荐有礼活动页曝光引流效率.sql`

### 付费用户转介绍执行情况

- **定义**：从付费用户出发，追踪付费后的转介绍行为执行率（下载海报、发朋友圈、拉新）及后续转化
- **计算方式**：以当月付费用户为基准，关联各行为表计算执行率和转化金额
- **表来源**：`aws.crm_order_info` + `crm.promotion_poster` + `crm.point_log_all` + `crm.new_user`
- **⚠️ 注意**：分"当月"和"当月+次月"两种观察窗口
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/转介绍相关-电销/付费用户在当月转介绍执行情况.sql`

### 转介绍人效

- **定义**：坐席维度的转介绍业务产出效率，结合司龄分段分析
- **计算方式**：转介绍业务营收按坐席分组，关联司龄 `DATEDIFF(截止日, 入职日)` 分段（<31 / 31-60 / 61-90 / 91-120 / 121-180 / 181-365 / >365 天）
- **表来源**：`aws.crm_order_info` + `crm.new_user`（`channel=2`）+ `crm.worker` + `crm.staff_change`
- **⚠️ 注意**：在职状态与入职时间 → `glossary.md` #员工入离职时间
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/转介绍相关-电销/转介绍人效.sql`

### 付费后N月朋友圈分享率

- **定义**：付费用户在付费后第 0~6 个月各月仍有朋友圈分享行为的占比
- **计算方式**：`COUNT(DISTINCT CASE WHEN 第N月有分享 THEN user_id END) / COUNT(DISTINCT user_id)`
- **表来源**：`aws.crm_order_info` + `crm.point_log_all`（`point_type=1`）
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/转介绍相关-电销/转发朋友圈情况及后续带来新用户的转化情况_月.sql`

### 转介绍老用户画像

- **定义**：推荐人（老用户）多维度画像分析，了解什么样的用户更容易产生转介绍行为
- **计算方式**：按城市线级、省市、性别、学段、年级、分期方式、商品类型、金额分段、复购次数等维度分组
- **表来源**：`aws.crm_order_info` + `crm.new_user`（`channel=2`）
- **⚠️ 注意**：拉新人数分层（未拉新/1人/2人/3人/4+）、拉新周期分层（30天一段至1年以上）
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/转介绍相关-电销/转介绍老用户画像明细表.sql`

---

## 十、私域1.0 / 企微AI机器人

> 私域1.0项目通过企微AI机器人自动触达添加企微的用户，促进用户活跃和付费转化，必要时转人工坐席跟进。
> 2026-02-09 上线，通过 A/B 实验（实验组接入AI机器人 vs 对照组不接入）评估效果。
>
> **核心数据表**：
> - AI 机器人渠道活码识别：`crm.qr_code_change_history`（`type_name = 'AI机器人'`）
> - 企微添加日志：`crm.contact_log`（`source = 3`）
> - AI 机器人消息记录：`study_data_center.telesale_robot_message_history`
> - 转人工记录：`crm.transfer_human_record`
> - A/B 实验分流：`xlab.sample_hour`（`group_code = 'cdacc7962750c4a86c184c7d989d454a'`）
>
> **参考 SQL**：`code/sql/看板/【电销】_tanchen/私域1.0项目/`

### AI首触覆盖量

- **定义**：添加微信当日 AI 机器人成功发送第一条消息的用户数
- **计算方式**：`COUNT(DISTINCT AImsg_user)`；判断逻辑：添加当日（`contact_date = send_date`）存在 `is_ai_message = true` 的消息记录
- **表来源**：`crm.contact_log` + `study_data_center.telesale_robot_message_history`
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/私域1.0项目/企微AI机器人触达激活监控.sql`

### AI首触覆盖率

- **定义**：AI 首触覆盖用户占企微添加用户的比率
- **计算方式**：`AI首触覆盖量 / 企微添加量`

### 首日开口量

- **定义**：添加微信当日用户发送 >= 3 条消息的用户数
- **计算方式**：`COUNT(DISTINCT usermag_user)`；判断逻辑：添加当日用户侧消息数（`sender_type = 'external'`）>= 3
- **表来源**：`crm.contact_log` + `study_data_center.telesale_robot_message_history`
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/私域1.0项目/企微AI机器人触达激活监控.sql`

### 首日开口率

- **定义**：首日开口用户占企微添加用户的比率
- **计算方式**：`首日开口量 / 企微添加量`

### 互动用户

- **定义**：用户消息 >= 1 条且 AI 消息 >= 1 条的用户（不含触发器消息）
- **判断方式**：`etnuser_msg_num >= 1 AND AI_msg_num >= 1`；其中 `etnuser_msg_num` = `sender_type = 'external'` 的消息数，`AI_msg_num` = `is_ai_message = true` 的消息数（`badge = 1`，不含 `badge = 2` 触发器消息）
- **适用表**：`study_data_center.telesale_robot_message_history`
- **⚠️ 注意**：互动维度按 `send_date`（互动日期）统计，非添加日期；与首日开口量的区别：首日开口限定添加当日且消息 >= 3，互动用户不限日期且消息 >= 1
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/私域1.0项目/企微AI机器人转人工监控.sql`

### 人工接管率

- **定义**：当日转人工的用户量占当日互动用户量的比率
- **计算方式**：`COUNT(DISTINCT manual_user) / COUNT(DISTINCT mag_user)`
  - 分子（转人工用户）：当日有 `manage_type = '人工接管'` 记录的用户，包含三种触发方式：
    - `trigger_type = 'active' AND to_tag = '人工接待'`（销售主动触发）
    - `trigger_type = 'defensive' AND to_tag = '人工接待'`（销售介入AI被动转人工）
    - `trigger_type = 'tag_callback' AND to_tag = '人工接待'`（销售修改会话标签转人工）
  - 分母（互动用户）：用户消息 >= 1 且 AI 消息 >= 1
- **表来源**：`study_data_center.telesale_robot_message_history` + `crm.transfer_human_record`
- **⚠️ 注意**：不包含异常转人工（`trigger_type = 'passive'`，即 AI 无法回复的场景）
- **参考 SQL**：`code/sql/看板/【电销】_tanchen/私域1.0项目/企微AI机器人转人工监控.sql`

---

## 更新记录

| 日期 | 内容 |
|------|------|
| 2026-03-23 | 新增"十一、转介绍相关"章节：转介绍线索、绑定关系、转化率口径（沿用领取转化率+clue_source筛选）、线索营收（电销营收来源拆分）、业务营收（独立指标，6个月归因窗口）、裂变行为指标（下载海报/发朋友圈/拉新）、推荐有礼漏斗、执行情况、人效、朋友圈分享率、老用户画像；标注与现有指标的关系和歧义警示 |
| 2026-02-04 | 初始化词典，涵盖用户分层、订单、线索、组织架构、商品、业务归属 |
| 2026-02-04 | 完善用户分层：补充4个字段的完整枚举值定义，新增高净值用户概念 |
| 2026-02-04 | 明确默认字段为 `business_user_pay_status_business`，仅当需求明确"新用户=当日注册"时用 statistics |
| 2026-02-04 | 修正"电销触达"和"在坐席名下"定义，明确特定场景下的触达判断逻辑 |
| 2026-02-04 | 补充用户属性分层：学段、年级、性别、地理位置、城市线级、用户身份/角色 |
| 2026-02-05 | 新增职能岗员工识别逻辑（待验证），基于领取量和组织归属特征 |
| 2026-02-05 | 完善职能岗识别：以人员表为基础，关联营收/领取/外呼行为数据，适配人效计算场景 |
| 2026-02-05 | 完善商品相关：新增商品2.0体系全部核心字段枚举值（9个字段），包含原始类目、策略组类目、时长、分类标签、分组标签 |
| 2026-02-05 | 新增商品营收分布统计口径（业务修正逻辑），包含 strategy_type 字段和三级修正规则 |
| 2026-02-05 | 新增营收查询场景选表指南：电销营收用电销表、业务GMV用全量表+business_gmv_attribution、服务期营收用team_names |
| 2026-02-06 | 更新活跃数据标准筛选条件：新增 active_user_attribution 条件，默认看C端活跃 |
| 2026-02-12 | 补充外呼相关：新增 dw.fact_call_history 全部核心字段说明；补充 call_state 枚举值；完善 channel_id 渠道映射 |
| 2026-03-04 | 新增手机号解码逻辑：dim_user.phone 字段存在 base64 编码，取数时必须用 unbase64 解码 |
| 2026-03-05 | 补充电销订单表默认筛选条件（workplace_id/regiment_id/worker_id/in_salary/is_test）及 in_salary 含义；新增 is_learn_active_user 字段说明；组织架构名称字段补充 heads_name 及 crm.organization 并用说明；修正"高中屯课策略"错别字为"高中囤课策略" |
| 2026-03-05 | 新增"九、业绩目标"章节：电销团队拆标逻辑、个人/小组/团三级目标体系、数据来源表（crm.group_goal/crm.worker_goal）、去重逻辑、中间汇总表结构及注意事项 |
| 2026-03-06 | 新增线索来源聚合口径（业务默认定义）；新增当配转化率口径 |
| 2026-03-10 | **知识库重构**：枚举值明细迁移至 enums.md，默认筛选条件迁移至 default-filters.md，保留术语定义和计算逻辑，文件从 1166 行精简至约 700 行 |
| 2026-03-11 | 新增公海池定义；线索来源补充业务流程交叉引用（→ business-context.md） |
| 2026-03-11 | 新增电话线索漏斗指标：活跃量、推送量、入库量、入库领取量、活跃领取量，含定义、计算方式、口径差异 |
| 2026-03-11 | 新增企微漏斗指标：曝光量、点击量、二维码曝光量、添加量、拉取入库量 + 4个转化率（点击率、二维码曝光率、添加率、拉取入库率） |
| 2026-03-12 | 标注企微漏斗指标仅限漏斗表使用；新增常规企微业务指标（企微添加量、拉取入库量、企微拉取入库率），区分"分组织架构"与"不分组织架构"两种口径，数据来源为 crm.contact_log + aws.clue_info |
| 2026-03-12 | 修正文件路径拼写（拉去→拉取）；活跃领取量增加 recieve_u_user_all 跨表同名字段含义差异警示；新增"企微业务选表指南"，区分宏观表/分渠道/漏斗/坐席二维码曝光等场景的选表规则 |
| 2026-03-12 | 新增"领取转化率（累积转化率）"独立定义，含日报口径、无截止时间窗口、多窗口转化率说明；强化"转化 vs 营收"的 status 规则；标注线索表自带转化字段口径不明确不建议使用 |
| 2026-03-12 | 新增"活跃转化率"定义；新增"活跃企微添加拉取入库转化"定义（宏观表 crm_active_user_wechat_paid_month）；新增"企微添加拉取入库转化"定义（常规日志表，按渠道/按渠道+组织架构两种维度）；新增"企微坐席二维码曝光添加率"定义（crm.new_user，与漏斗表因埋点损耗有差异） |
| 2026-03-25 | 知识库规范重构：移除 enums.md/default-filters.md 引用，枚举值指向 DDL 文件末尾，筛选条件指向 DDL 文件【常用筛选条件】，通用业务规则 R01-R08 迁入本文件 |
| 2026-03-25 | 全文按概念/指标模板重构（一～八章）；合并"业务归属与营收"入"订单与营收"；删除"通用业务规则"独立板块（R02 归入三章 blockquote，R07 移至 table-relations.md，其余与各章已有内容重复） |
| 2026-04-08 | 新增企微漏斗"资源位点击→坐席二维码曝光 中间漏斗细查"：跳转微信过渡页曝光量、进入企微添加小程序量，数据来源 events.frontend_event_orc，不改动默认五层漏斗 |
| 2026-03-31 | 合并 conversion-calc-convention.mdc 规则到「领取线索量」和「领取转化率」条目：日报口径计算规范、日报粒度字段清单内联到 glossary，删除独立 rule 文件 |
| 2026-04-08 | 新增"十、私域1.0 / 企微AI机器人"章节：AI首触覆盖量/率、首日开口量/率、互动用户、人工接管率，含核心数据表说明和参考 SQL 引用 |
| 2026-04-08 | 新增"当配/往期营收占比"概念定义（三、订单与营收），说明三类拆分逻辑、归因方式（recent_info_uuid）、业务用途（定位营收异常/预测当月营收），引用参考 SQL |
