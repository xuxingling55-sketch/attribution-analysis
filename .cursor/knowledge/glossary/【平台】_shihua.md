# 【平台】业务知识字典

> 维护人：**诗华**。
> 结构：仅保留标准字段；按 `规则 / 指标 / 维度` 组织。

## 标准字段

| 字段 | 必填 | 说明 |
|------|------|------|
| **唯一规范名** | 推荐 | 在全文内可检索的标准称呼；同名口语必须区分场景 |
| **类型** | 推荐 | `指标` / `维度` / `规则` 之一 |
| **定义** | 是 | 一句话说明「是什么」 |
| **计算方式** | 是 | 可执行 SQL、取数字段或分步逻辑；维度写字段或映射入口 |
| **表来源** | 是 | `schema.table`；多表时分别写清 |
| **筛选条件** | 否 | 仅当与 DDL 常规筛选不一致时写 |
| **⚠️ 注意** | 否 | 易混、口径差异、待验证 |

## 规则

### 1. 规则 R01：手机号解码

- **唯一规范名**：规则 R01：手机号解码
- **类型**：规则
- **定义**：`dw.dim_user` 等存 Base64 手机号的场景。
- **计算方式**：展示或匹配前需 `unbase64` / `FROM_BASE64` 等解码。
- **表来源**：`dw.dim_user`

### 2. 规则 R02：判断用户购买历史

- **唯一规范名**：规则 R02：判断用户购买历史
- **类型**：规则
- **定义**：是否买过某品类/商品。
- **计算方式**：必须用 `dws.topic_order_detail`，这是全量订单表。
- **表来源**：`dws.topic_order_detail`

### 3. 规则 R03：正价订单

- **唯一规范名**：规则 R03：正价订单
- **类型**：规则
- **定义**：正价购买订单。
- **计算方式**：平台当前通用口径是`original_amount >= 39`。
- **表来源**：`dws.topic_order_detail`

### 4. 规则 R04：正价商品

- **唯一规范名**：规则 R04：正价商品
- **类型**：规则
- **定义**：正价商品。
- **计算方式**：平台当前通用口径是`original_amount >= 39`。
- **表来源**：`dws.topic_order_detail`


### 7. 规则 R07：user_id / u_user

- **唯一规范名**：规则 R07：user_id / u_user
- **类型**：规则
- **定义**：跨 aws 与 dws/dw。
- **计算方式**：`aws.*` 多为 `user_id`，`dws`/`dw` 多为 `u_user`。
- **表来源**：`dw.dim_user_his`

### 8. 规则 R08：家长身份

- **唯一规范名**：规则 R08：家长身份
- **类型**：规则
- **定义**：用户身份判断。
- **计算方式**：用 `real_identity`，禁止用 `role` 代替。
- **表来源**：`dw.dim_user_his`

### 11. 规则 R11：C 端活跃默认筛选（活跃表必加）

- **唯一规范名**：规则 R11：C 端活跃默认筛选（活跃表必加）
- **类型**：规则
- **定义**：默认「主产品移动端 C 端」活跃口径。
- **计算方式**：u_user，无需过滤
- **表来源**：`aws.business_active_user_last_14_day`
- **⚠️ 注意**：默认选择上述表来源。底层表是`dws.topic_user_active_detail_day`，底层表的计算方式：```sql
  product_id = '01'
  AND client_os IN ('android', 'ios', 'harmony')
  AND active_user_attribution IN ('中学用户', '小学用户', 'c')
  ```
  
### 12. 规则 R12：role（注册角色，不可用于家长判断）

- **唯一规范名**：规则 R12：role（注册角色，不可用于家长判断）
- **类型**：规则
- **定义**：用户注册时选择的角色（学生/老师等），不等于是否家长。
- **计算方式**：直接取 `role`。
- **表来源**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`dw.dim_user` 等
- **⚠️ 注意**：⚠️ `role = 'student'` 中约 30% 实际家长（`real_identity` 为 `parents` / `student_parents`）；`role = 'parents'` 多为历史小程序用户且 `real_identity` 常为 NULL。判家长只信 `real_identity`（需 JOIN `dim_user`）。取值列表 → `code/sql/表结构/` 对应表 DDL 第三段「枚举值」「role」。

### 14. 规则 R14：业务口径一二三级类目迭代（20251225，CASE 全量）

- **唯一规范名**：规则 R14：业务口径一二三级类目迭代（20251225，CASE 全量）
- **类型**：规则
- **定义**：
  说明：新类目商品 20260101 上线后才有订单；以下 CASE 用于二级 `business_good_kind_name_level_2`、三级 `business_good_kind_name_level_3` 迭代映射（一级「积木块」→「零售商品」等）。
  ```sql
  -- 一级
  CASE
    WHEN business_good_kind_name_level_1 = '积木块' THEN '零售商品'
    ELSE business_good_kind_name_level_1
  END AS business_good_kind_name_level_1_new;
  -- 二级（节选结构：单学段/多学段/零售/特殊品）
  CASE
    WHEN good_kind_id_level_3 IN (
      '31b7ea04-1c16-452c-9922-720226471c4b','b5c1c6c5-30f6-41e5-87de-ee3d494c4358',
      '93804163-4872-4a3e-b260-a25bba3fd2da','d8563061-2a7a-4f9e-b404-431e2663db53',
      '3798125e-e1a6-4f97-81cf-def49a792ee3','dad67779-4f78-4c6e-86db-1b2681687268',
      'c190551a-e86d-4ad1-9a3f-80a276765ddc'
    ) THEN '单学段商品'
    WHEN good_kind_id_level_3 IN (
      'efee4e99-35c9-4b26-951d-8592bac8d90a','5f1ece35-9cb1-48be-b399-6d25bf302b60',
      'a8bef5b4-17de-456a-9b4d-b9881d469f38','dc23ef8b-1491-40a8-8e2b-a4cee361f065',
      'c4c18cfb-1f62-4d61-94db-f749a2154ede'
    ) THEN '多学段商品'
    WHEN business_good_kind_name_level_2 = '特殊品' AND business_good_kind_name_level_3 = '高中品' THEN '单学段商品'
    WHEN business_good_kind_name_level_2 = '特殊品' AND business_good_kind_name_level_3 <> '高中品' THEN '多学段商品'
    WHEN business_good_kind_name_level_2 = '积木块' THEN '零售商品'
    ELSE business_good_kind_name_level_2
  END AS business_good_kind_name_level_2_new;
  -- 三级（小学品/初中品/高中品/小初同步品/小初品/初高品/同步课/培优课/拓展课等）
  CASE
    WHEN good_kind_id_level_3 = '31b7ea04-1c16-452c-9922-720226471c4b' THEN '小学品'
    WHEN good_kind_id_level_3 IN (
      'c190551a-e86d-4ad1-9a3f-80a276765ddc','93804163-4872-4a3e-b260-a25bba3fd2da',
      'd8563061-2a7a-4f9e-b404-431e2663db53'
    ) THEN '初中品'
    WHEN good_kind_id_level_3 IN (
      '3798125e-e1a6-4f97-81cf-def49a792ee3','dad67779-4f78-4c6e-86db-1b2681687268',
      'b5c1c6c5-30f6-41e5-87de-ee3d494c4358'
    ) THEN '高中品'
    WHEN good_kind_id_level_3 = 'efee4e99-35c9-4b26-951d-8592bac8d90a' THEN '小初同步品'
    WHEN good_kind_id_level_3 IN (
      '5f1ece35-9cb1-48be-b399-6d25bf302b60','a8bef5b4-17de-456a-9b4d-b9881d469f38',
      'dc23ef8b-1491-40a8-8e2b-a4cee361f065'
    ) THEN '小初品'
    WHEN good_kind_id_level_3 = 'c4c18cfb-1f62-4d61-94db-f749a2154ede' THEN '小初高品'
    WHEN business_good_kind_name_level_3 = '小初跨学段品' THEN '小初品'
    WHEN business_good_kind_name_level_3 = '初高跨学段品' THEN '初高品'
    WHEN business_good_kind_name_level_3 = '小初高全学段品' THEN '小初高品'
    WHEN business_good_kind_name_level_2 = '特殊品' AND business_good_kind_name_level_3 = '小学品' THEN '小初同步品'
    WHEN business_good_kind_name_level_2 = '特殊品' AND business_good_kind_name_level_3 = '初中品' THEN '小初品'
    WHEN business_good_kind_name_level_3 = '全科同步课联售' THEN '同步课'
    WHEN business_good_kind_name_level_3 = '全科培优课联售' THEN '培优课'
    WHEN good_kind_id_level_2 = '04418594-744a-4bab-a6cf-da504c1576ef' THEN '拓展课'
    ELSE business_good_kind_name_level_3
  END AS business_good_kind_name_level_3_new;
  ```
- **计算方式**：按「业务口径一二三级类目迭代（20251225，CASE 全量）」对应的业务规则执行。
- **表来源**：

### 15. 规则 R15：两套标签（数据侧同时使用）

- **唯一规范名**：规则 R15：两套标签（数据侧同时使用）
- **类型**：规则
- **定义**：
  | 体系 | 字段 | 用途 |
  |------|------|------|
  | 后端商品类目 | `good_kind_id_level_1`、`good_kind_id_level_2`、`good_kind_id_level_3` | 商品中台类目树 |
  | 前端业务口径 | `business_good_kind_name_level_1`、`business_good_kind_name_level_2`、`business_good_kind_name_level_3` | 营收、策略、BI 主用 |
  注意：`course_timing_kind`（商品类型：到期型/时长型等）与 `course_group_kind`（商品分组：公域主推/私域主推等）与上表不同维；商品类型 ≠ 商品分组，禁止混为一列做 GROUP BY。
- **计算方式**：按「两套标签（数据侧同时使用）」对应的业务规则执行。
- **表来源**：

### 16. 规则 R16：中台策略 2.0 总述

- **唯一规范名**：规则 R16：中台策略 2.0 总述
- **类型**：规则
- **定义**：
  在商品体系 2.0 下，统一各渠道「策略」看数口径，使 BI / 数据 / 业务对同一指标指向同一统计对象；自 2026-01-01 起生效。
  - 产品侧约定（原文要点）：
    - BI：用「商品分组」表达公域/私域主推等；使用场景会随业务发展调整，故用 `course_group_kind` 实现，而非写死渠道枚举。
    - 后端：增加「商品类型」标签（到期型/时长型等），对应 `course_timing_kind`。
- **计算方式**：
  具体枚举与 CASE 以数仓落表为准。

  #### 策略相关核心监控指标（2.0 正文）
  实现时须叠加正价、时间窗、商品类目及组合品/策略资格约束。
  | 指标 | 分母 | 分子 |
  |------|------|------|
  | 付费零售品用户 → 组合品续购率 | 购买过零售品的用户 | 后续购买组合品的用户 |
  | 付费零售品用户 → 非组合品续购率 | 同上 | 后续购买非组合品的用户 |
  | 付费组合品或历史大会员用户 → 组合品续购率 | 购买过组合品的用户（可区分历史大会员用户 / 付费组合品用户） | 后续仍购买组合品或续购品（可按商品分类拆） |
  | 同上 → 非组合品续购率 | 同上 | 后续购买非组合品的用户 |
  | 平板加购率 | 购买过积木块、组合品的用户 | 单后加购或随单加购三级类目「学习机加购-平板加购」的用户 |
  | 多孩加购率（2.0） | 有多孩策略资格的用户 | 以多孩策略 −2000 购买组合品的用户 |
  | 小学品、小初同步品用户升级率 | 有对应补差资格的用户（两路并存时以补差金额更高策略为准） | 升级购买组合品的用户 |
  平板加购：单后加购 = 支付后再次购买三级类目「学习机加购-平板加购」；随单加购 = 支付当下订单内已含平板。维度：付费场景分为单后加购、随单加购。
  小学品/小初同步品升级率：优先级 小初同步品 > 小学品；分母为历史买过对应品类的用户，分子为买了补差品（升级）的用户。
- **表来源**：`dws.topic_order_detail`、`dw.fact_order_detail`、`dws.topic_user_info`、`dws.topic_user_active_detail_day` / `month` / `year`、`aws.business_active_user_last_14_day` 等。
- **⚠️ 注意**：
  - strategy_type 仅组合品有业务标签；使用前须 先筛组合品（通常 `business_good_kind_name_level_1 = '组合品'`），再筛策略字段。
    - 多孩策略资格：判定用户资格时，不统计公域「已满足多孩策略但尚未实际发生退款」的订单；仅完成退差价后才计入资格。
    - multi_child_refund_time：记录公域需客服延迟手动退差价的时间；私域随单自动扣差价等 不记或记法不同。讨论结论：用户策略资格不统计未退款订单；退差价时间只记公域延迟退差价。
    - 公域多孩与 tags / promotions：曾讨论 `order_list.tags`、未退差价时 promotions 是否已有优惠记录等，以线上落表与最新业务结论为准。
    - 优惠与金额：`strategy_detail` 与 `original_amount`（超值价/订单原价）、`sub_amount`（到手价）、`discount_amount`（优惠总额 = 超值价 − 到手价，含券）成套使用。
    - user_strategy_tag_*：在统计/业务分层之上，将原「高净值」拆为 历史大会员 与 付费组合品用户 等；历史大会员可再分可续购/不可续购，看整体常需合并。
    - user_strategy_eligibility_*：小初同步品资格、小学品资格、多孩策略资格等；与 `business_user_pay_status_*` 分工不同——商业化付费分层用后者，策略资格/升级率/多孩贡献用本组字段。
    - 策略类型（BI）：多孩、续购等若实际购买均为组合品，需依赖专项标签看贡献与优惠金额；组合品中单孩/多孩订单占比等需结合 `strategy_type` 与多孩标签。

### 17. 规则 R17：付费分层字段选择指南

- **唯一规范名**：规则 R17：付费分层字段选择指南
- **类型**：规则
- **定义**：多付费分层字段并存时的选用规则（一律使用商业化字段 `business_user_pay_status_*`，不使用无 `business_` 前缀的 `user_pay_status_*`）。
- **计算方式**：无单独公式；按场景选列（如下表）。
- **表来源**：`dws.topic_user_info`,`dws.topic_user_active_detail_day`,`dws.topic_order_detail`等

### 18. 规则 R18：用户策略分层专用：判断用户是否购买过某商品且当前未退款

- **唯一规范名**：规则 R18：用户策略分层专用：判断用户是否购买过某商品且当前未退款
- **类型**：规则
- **定义**：用户策略分层专用：判断用户是否购买过某商品且当前未退款。
- **计算方式**：`dws.topic_order_detail` 上 `status = '支付成功'` + 商品条件后 `SELECT DISTINCT u_user`。
- **表来源**：
  仅 `dws.topic_order_detail`

  ```sql
  -- 后端类目「组合商品」（二级类目名）
  SELECT u_user FROM dws.topic_order_detail
  WHERE status = '支付成功' AND good_kind_name_level_2 = '组合商品' GROUP BY u_user;

  -- 业务「组合品」（2.0 优先）
  SELECT u_user FROM dws.topic_order_detail
  WHERE status = '支付成功'
    AND business_good_kind_name_level_1 = '组合品'
    AND original_amount >= 39
  GROUP BY u_user;
  ```
- **⚠️ 注意**：`good_kind_name_level_2 = '组合商品'` ≠ `business_good_kind_name_level_1 = '组合品'`。



### 20. 规则 R20：寒假分析时间窗口（可与业务年一起调整）

- **唯一规范名**：规则 R20：寒假分析时间窗口（可与业务年一起调整）
- **类型**：规则
- **定义**：节前/节中/节后与「去年寒假 vs 今年寒假」对齐用日期标签。
- **计算方式**：
  按 `day`（`yyyyMMdd` 或库内实际类型）落在下列区间打标 `period_flag` / `year_flag`（与底表 SQL 一致）：

  | 标签 | 日期范围（闭区间，按 SQL 当前版本） |
  |------|-------------------------------------|
  | 去年寒假 `last_year_holiday` | `20250101`～`20250209` |
  | 今年寒假 `this_year_holiday` | `20260126`～`20260302` |
  | 去年节前 `last_year_pre` | `20241225`～`20241231` |
  | 去年节后 `last_year_post` | `20250210`～`20250216` |
  | 今年节前 `this_year_pre` | `20260119`～`20260125` |
  | 今年节后 `this_year_post` | `20260303`～`20260309` |
- **表来源**：与底表关联的日期维（可从 `dws.topic_user_active_detail_day` 抽 distinct `day`）。
- **⚠️ 注意**：换年或换假需同步改 SQL 与本文档；`year_flag` 规则见 `2025-2026寒假流量整体分析底表.sql` 内注释。

### 21. 规则 R21：寒假流量与大盘活跃（临时需求口径）

- **唯一规范名**：规则 R21：寒假流量与大盘活跃（临时需求口径）
- **类型**：规则
- **定义**：用于「寒假前后流量对比、学段/新老付费分层、省份与城市线级」等季节性分析的活跃 UV，不要求主产品移动端 C 端切片。
- **计算方式**：
  ```sql
  is_active_user = 1
  AND is_test_user = 0
  ```
- **表来源**：`dws.topic_user_active_detail_day`（主）；分层可结合 `aws.business_active_user_last_14_day`（见下）。
- **筛选条件**：日期范围按分析需求；已沉淀对比窗口见「寒假分析时间窗口」。
- **⚠️ 注意**：与「C 端活跃默认筛选」互斥默认：本场景不加 `product_id` / `client_os` / `active_user_attribution`，除非需求明确要求收窄为 C 端。来源：`code/sql/临时需求/2025-2026寒假流量整体分析底表.sql` 及拆分 SQL。需求背景：`session-notes.md`「寒假流量」条目；勿整篇读取该历史文件。


### 23. 规则 R23：数据需求：字段上线与业务说明

- **唯一规范名**：规则 R23：数据需求：字段上线与业务说明
- **类型**：规则
- **定义**：
  下列为需求侧约定的字段、表与时间点；若与线上一致性有疑，以 DDL 为准。
  | 序号 | 字段 | 说明 | 类型/时间 | 所在表 |
  |------|------|------|-----------|--------|
  | 1 | `fix_good_kind_id_level_2`、`fix_good_kind_name_level_2` | 修正二级类目（积木块抵扣「升单商品」专用） | 迭代 20251225 | `dws.topic_order_detail` 等 |
  | 2 | `business_good_kind_name_level_1/2/3` | 前端业务口径类目 | 迭代 20251225 | 订单宽表、活跃表等 |
  | 3 | `course_timing_kind` | 商品类型（到期型/时长型等） | new，约 20260106 | 同上 |
  | 4 | `course_group_kind` | 商品分组（公域主推/私域主推等） | new，约 20260106 | 同上 |
  | 5 | `userauth_exchange_time` | 授权转换时间 | new，开发库同步 | `dws.topic_order_detail` |
  | 6 | `delay_vip_activation_time` | 高中囤课品延迟开通激活时间 | new | 同上 |
  | 7 | `multi_child_refund_time` | 多孩策略退差价时间（公域售后期后退款等场景） | new | 同上 |
  | 8 | `strategy_type` | 策略类型（仅组合品需先筛组合品） | new | `dws.topic_order_detail`、`dw.fact_order_detail` |
  | 9 | `strategy_detail` | 优惠金额明细 | new | 同上 |
  | 10 | `user_strategy_tag_day/month/year` | 策略用户分层（历史大会员拆可续购/不可续购） | new | `dws.topic_user_info`、活跃日/月/年、`aws.business_active_user_last_14_day`、订单表 |
  | 11 | `user_strategy_eligibility_day/month/year` | 用户策略资格 | new | 用户表、活跃表、订单表 |
  | 12–16 | `original_amount`、`sub_amount`、`discount_amount`、`discount_id`、`discount_price` | 超值价、到手价、优惠总额、券 ID、券金额 | 与 2.0 定义对齐 | `dws.topic_order_detail`、`dw.fact_order_detail` |
  迭代说明（需求原文）：
  - 20251125：`fix_good_*` 字段描述更新为「积木块抵扣升单商品专用」。
  - 20251225：`business_good_kind_*` 业务口径类目迭代（见下文 业务口径一二三级类目 CASE）；三张表 `dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`aws.business_active_user_last_14_day` 同步。
  - 策略用户分层：预计与开发库同步；历史侧将 `business_user_pay_status_business = '高净值用户'` 拆成「历史大会员用户」与「组合品用户」等，以底层脚本为准。
  - 策略资格标签：依赖策略用户分层；补数从最新日期倒序。
  - strategy_type：须同时上线 `dw.fact_order_detail`（与宽表一致口径时）。
  切日规则（再次强调）：`paid_time_sk < 20260101` 时订单用 `dws.topic_order_detail` + `business_good_kind_name_level_*`；`paid_time_sk >= 20260101` 且涉及后端类目细项时用 `dw.fact_order_detail` + `good_kind_id_level_*`。同一分析禁止混用两套条件而不带日期分界。
- **计算方式**：按「数据需求：字段上线与业务说明」对应的业务规则执行。
- **表来源**：`dws.topic_order_detail`、`dw.fact_order_detail`、`dws.topic_user_info`、`aws.business_active_user_last_14_day`、`dws.topic_user_active_detail_day`

### 24. 规则 R24：新品销量监控口径（临时需求）

- **唯一规范名**：规则 R24：新品销量监控口径（临时需求）
- **类型**：规则
- **定义**：指定「新品类型」维度的订单量、退前/退后金额；`types` 由 `sku_group_good_id` / `good_id` / `good_kind_id_level_*` / `good_stage_subject` / `peiyou_kind` 等规则映射。
- **计算方式**：`count(distinct order_id)`；`sum(sub_amount)`；退后 `sum(case when status = '支付成功' then sub_amount else 0 end)`；时间 `paid_time_sk`；周趋势 `weekofyear(date_add(date(paid_time), 3))`（上周五～本周四）；高中培优等按 `sku_name` 文本匹配。
- **表来源**：`dws.topic_order_detail`、`dw.dim_date`
- **⚠️ 注意**：以 `code/sql/临时需求/新品销量监控.sql` 为事实源。

### 25. 规则 R25：术语辨析

- **唯一规范名**：规则 R25：商品策略术语辨析
- **类型**：规则
- **定义**：
  #### Q1：「组合品」与「组合商品」
  | 术语 | 维度 | SQL |
  |------|------|-----|
  | 组合品 | 业务一级类目 | `business_good_kind_name_level_1 = '组合品'` |
  | 组合商品 | 后端类目二级 | `good_kind_name_level_2 = '组合商品'` 或对应 UUID |
  「组合品」展开在脚本中常含 组合商品 + 毕业年级到期品 + 升单商品（见 `newzuhe1` 的 `good_kind_id_level_2` 三元组），不等于仅写「组合商品」。
  #### Q2：大会员商品、大会员用户、历史大会员用户
  - 大会员商品：订单维度；`bigvip1`/`bigvip2`/`bigvip3` 等见上表 `user_pay`。
  - 大会员用户（口语）：策略语境下默认对齐 `user_strategy_tag_*` = 历史大会员用户，不是 `business_user_pay_status_* = '高净值用户'` 的单义子集。
  - 历史大会员用户：由 `offline_list_bigvip`、`bigvip*`、`unbigvip` 与 先付费组合品再历史大会员 等 CASE 顺序共同判定；枚举见 DDL「user_strategy_tag_*」。
- **计算方式**：按「术语辨析」对应的业务规则执行。
- **表来源**：

### 26. 规则 R26：渠道活跃转化：底层汇总（`business_active_channel_*` 加工）

- **唯一规范名**：规则 R26：渠道活跃转化：底层汇总（`business_active_channel_*` 加工）
- **类型**：规则
- **定义**：以下与 `business_active_channel_day` / `business_active_channel_month` 类脚本（及 tmp 自测文档）一致，说明 落表字段 `active_uv`、`amount`、`pay_uv`、`pb_amount` 等如何从 `aws.business_active_user_last_14_day` 汇总而来；报表上的 转化率 / ARPU / **活跃客单价**（`amount / pay_uv`，口播常被简称「客单价」）由这些落表字段按行计算，见下各小节。
- **计算方式**：按「渠道活跃转化：底层汇总（`business_active_channel_*` 加工）」对应的业务规则执行。
- **表来源**：
  `aws.business_active_user_last_14_day`；日期窗（参数以调度为准）：`day` ∈ `[before_15_day, day]`，同比对照常用 `day - 10000` 与当年同日对齐。
  - 渠道分支（多路 `UNION ALL`）——在用户日粒度内汇总金额（每路对同一用户、同一 `day` 先 `SUM` 再进入外层）：
    - 商业化：`total_amount` = `sum(if(business_gmv_attribution in ('商业化'), normal_price_amount, 0))`；`pb_amount` / `non_pb_amount` 分别对 `normal_price_scheme_amount`、`normal_price_non_scheme_amount` 用同一条件；各 `new_normal_price_*` 子列同理。
    - 电销：上式条件改为 `business_gmv_attribution in ('电销')`。
    - 整体：条件为 `in ('商业化','电销')`。
    - APP实际成单：`total_amount` = `sum(nvl(fix_normal_price_amount,0))`，`pb_amount` / `non_pb_amount` 对 `fix_normal_price_scheme_amount`、`fix_normal_price_non_scheme_amount`；细分策略金额对 `fix_new_normal_price_*`（不再按 `business_gmv_attribution` 拆分）。
  - 用户日粒度：上述结果按 `day`、`u_user`、分层（`business_user_pay_status_*_day`）、年级/学段、`channel_allocation`（`user_allocation` 是否含「电销/网销」等）、`is_tele_belong_day`、`user_strategy_tag_day`、`user_strategy_eligibility_day`、`big_vip_kind_day` 等 GROUP BY，得到每人每日一行及当日 `total_amount`、`pb_amount`、`non_pb_amount` 等。
  - 切片聚合（渠道日表一行）：再按 `day`、`channel`、分层、年级、`channel_allocation`、坐席归属、策略标签等 GROUP BY：
    - `active_uv` = `COUNT(DISTINCT u_user)`
    - `amount` = `SUM(total_amount)`
    - `pb_amount` / `non_pb_amount` = `SUM(pb_amount)` / `SUM(non_pb_amount)`
    - `pay_uv` = `COUNT(DISTINCT IF(total_amount > 0, u_user, NULL))`
    - `pb_paid_uv` = `COUNT(DISTINCT IF(pb_amount > 0, u_user, NULL))`
    - `non_pb_paid_uv` = `COUNT(DISTINCT IF(non_pb_amount > 0, u_user, NULL))`
    - 各「新正价 / 方案型策略线」：金额为对应列 `SUM`，人数为 `COUNT(DISTINCT IF(该列金额 > 0, u_user, NULL))`（与 `new_normal_price_*_uv` 类字段一致）。
  - 同比 `yoy_*`：当年切片 `a` 与去年切片 `a2` FULL JOIN，`a.year = a2.year + 1` 且 `month_day`、`channel`、分层、年级、`channel_allocation`、坐席归属、策略标签等维度对齐，去年侧 `COALESCE(a2.*, 0)` 写入 `yoy_active_uv`、`yoy_amount` 等。
  - 月表：`aws.business_active_channel_month` 为 自然月 × 渠道 × 分层 × … 粒度，金额与 UV 口径与日表同源，维度使用 `*_month` 字段；`channel_allocation` 等或取月内规则行（如 `rn = 1`），以线上 DDL/落表为准；查询模板见 T-CHA-02。

### 27. 规则 R27：策略用户身份：`user_pay` 聚合与分层 CASE

- **唯一规范名**：规则 R27：策略用户身份：`user_pay` 聚合与分层 CASE
- **类型**：规则
- **定义**：
  （字段级口径见上文 user_strategy_tag_day 等（策略用户分层）。）
  策略标签加工依赖订单聚合 CTE `user_pay`，典型度量包括：
  | 度量 | 含义 |
  |------|------|
  | `zuhe` | `business_good_kind_name_level_1 = '组合品'` 的实付金额 |
  | `bigvip1` | `paid_time_sk < 20250301` 且 `good_kind_id_level_2 in ('1ea973d0-bb4c-4499-bca7-330378a7baad','ad1d45cb-21b9-478b-8cc7-3fd75ac93aa4')` 的金额（全价大会员 + 体验机尾款） |
  | `bigvip2` | `business_good_kind_name_level_3 = '普通续购'` 的金额 |
  | `bigvip3` | 命中 `offline_list_bigvip` 兑换码等补充的大会员金额 |
  | `unbigvip` | 命中 `offline_list_unbigvip` 需剔除的历史 6 年品等金额 |
  | `newzuhe1` | `good_kind_id_level_2 in ('5e42f66c-0376-41b6-860b-9e437662283a','14cd8784-5583-48a6-a14b-85dfc63a2848','0d63071c-a690-4b51-ba2d-c9387c69026c')`（组合商品 + 毕业年级到期品 + 升单商品） |
  | `newzuhe2` | 命中 `offline_list_newzuhe` 兑换码等补充的组合品金额 |
  | `jiagou` | `good_kind_id_level_3 in ('77142d09-5cc6-43b1-82d0-089f906a5f1e','7cf62e78-b244-41d3-b3a5-9490b87dfef2')`（升单后加购-到期型培优课、学段加购） |
  典型分层 CASE（顺序敏感）：
  ```sql
  CASE
    WHEN newzuhe1 + newzuhe2 > 0 THEN '付费组合品用户'
    WHEN jiagou > 0 THEN '付费加购品用户'
    WHEN bigvip1 + bigvip2 + bigvip3 > unbigvip THEN '历史大会员用户'
    WHEN zuhe > 0 THEN '剩余组合品用户'
    WHEN b_u_user > 0 THEN '付费零售品用户'
    WHEN is_new = 0 THEN '老用户'
    WHEN is_new > 0 THEN '新用户'
  END
  ```
  （字段名以落表为准；历史大会员可再拆可续购/不可续购。）offline_list_* 为 `sku_group_good_id` 白名单或兑换码批次等，全量见本节文末「UUID 与批次号全量附录」。
- **计算方式**：按「策略用户身份：`user_pay` 聚合与分层 CASE」对应的业务规则执行。
- **表来源**：

### 28. 规则 R28：策略资格标签：切日与示例规则

- **唯一规范名**：规则 R28：策略资格标签：切日与示例规则
- **类型**：规则
- **定义**：说明策略资格标签的切日方式和核心判定规则。
- **计算方式**：
  `day >= 20230101`（以脚本为准）。
  - 小初同步品用户：`paid_time_sk < 20260101` 时 `dws.topic_order_detail` 且 `business_good_kind_name_level_3 = '小初同步品'`；`paid_time_sk >= 20260101` 时 `dw.fact_order_detail` 且 `good_kind_id_level_3 in ('05843c2f-8ce3-4da0-a680-d779c06e7f8a','efee4e99-35c9-4b26-951d-8592bac8d90a')`；可 union 兑换码批次（脚本列 batch_id）。
  - 小学品用户：`paid_time_sk < 20260101` 用 `business_good_kind_name_level_3 = '小学品'`；`>= 20260101` 用 `good_kind_id_level_3 in ('a639867c-b284-45f0-8b1d-d7239a501999','597fc454-7190-47e3-87ec-8a507ad25ff5','31b7ea04-1c16-452c-9922-720226471c4b')`（去重以脚本为准）；可 union 兑换码。
  - 多孩策略资格（常规版）：在 `dw.fact_order_detail` 上 `sku_group_good_id in (...)`（全量见「UUID 与批次号全量附录」中 `user_children_kind1` 与 `newzuhe1` 三元组）或 `good_kind_id_level_2 in ('5e42f66c-0376-41b6-860b-9e437662283a','14cd8784-5583-48a6-a14b-85dfc63a2848','0d63071c-a690-4b51-ba2d-c9387c69026c')`，且 `datediff(统计日, paid_time) <= 30`，且 `strategy_type regexp '补差策略|无策略'` 等（其它条件以线上脚本为准）。
- **表来源**：`dws.topic_order_detail`、`dw.fact_order_detail`

  > 商品 2.0 体系：2026-01-01 起在策略看数、策略用户身份/资格、策略类型等维度生效；字段枚举值逐步沉淀在 `code/sql/表结构/` 各表 DDL 第三段「枚举值」，本节约定为口径与 SQL 的单一事实源（商品 2.0 与中台策略部分）。

  > 与 1.0 关系：早期「中台策略通用数据口径 1.0」定义了付费用户续购等转化 SQL；2.0 在其基础上迭代。自 2026-01-01 起，凡涉及策略看数、策略用户身份/资格、策略类型的分析，以本节约定及数仓落表为准；1.0 中的 `zuhe_user` / `unzuhe_user` 等仅作历史报表或理解旧口径；与 `user_strategy_tag_*`、`user_strategy_eligibility_*` 落表冲突时 以 2.0 落表为准。


### 31. 规则 R31：营收查询选表指南

- **唯一规范名**：规则 R31：营收查询选表指南
- **类型**：规则
- **定义**：
  | 查询场景 | 使用表 | 关键字段 | 说明 |
  |----------|--------|----------|------|
  | 电销营收 | `aws.crm_order_info` | `amount` | 电销业务专用 |
  | 各业务 GMV | `dws.topic_order_detail` | `business_gmv_attribution` | 电销/新媒体等 |
  | 服务期营收 | `dws.topic_order_detail` | `team_names` | 服务期归属 |
  | 用户购买历史 | `dws.topic_order_detail` | — | 全渠道，防遗漏 |
- **计算方式**：按「营收查询选表指南」对应的业务规则执行。
- **表来源**：`aws.crm_order_info`、`dws.topic_order_detail`

### 32. 规则 R32：UUID 与批次号全量附录

- **唯一规范名**：规则 R32：UUID 与批次号全量附录
- **类型**：规则
- **定义**：
  > 来源：自策略用户身份、策略资格标签加工说明（产品设计定稿脚本）抽取；若与线上数仓脚本或表结构不一致，以 DDL 与线上为准。`sku_group_good_id` 为标准 UUID；部分历史品为 24 位十六进制（与 MongoDB `ObjectId` 同形），脚本中与 UUID 列在同一 `IN` 列表中。
  #### `user_pay` 结构用到的 `good_kind_id_level_2` / `good_kind_id_level_3`
  | 用途 | 字段 | UUID |
  |------|------|------|
  | bigvip1（大会员商品等） | `good_kind_id_level_2` | `1ea973d0-bb4c-4499-bca7-330378a7baad` |
  | bigvip1（大会员商品等） | `good_kind_id_level_2` | `ad1d45cb-21b9-478b-8cc7-3fd75ac93aa4` |
  | newzuhe1（组合商品+毕业到期+升单） | `good_kind_id_level_2` | `5e42f66c-0376-41b6-860b-9e437662283a` |
  | newzuhe1（组合商品+毕业到期+升单） | `good_kind_id_level_2` | `14cd8784-5583-48a6-a14b-85dfc63a2848` |
  | newzuhe1（组合商品+毕业到期+升单） | `good_kind_id_level_2` | `0d63071c-a690-4b51-ba2d-c9387c69026c` |
  | jiagou（升单后加购） | `good_kind_id_level_3` | `77142d09-5cc6-43b1-82d0-089f906a5f1e` |
  | jiagou（升单后加购） | `good_kind_id_level_3` | `7cf62e78-b244-41d3-b3a5-9490b87dfef2` |
  #### 策略资格：`paid_time_sk >= 20260101` 时 `dw.fact_order_detail` 的 `good_kind_id_level_3`
  | 用途 | UUID |
  |------|------|
  | 小初同步品 | `05843c2f-8ce3-4da0-a680-d779c06e7f8a` |
  | 小初同步品 | `efee4e99-35c9-4b26-951d-8592bac8d90a` |
  | 小学品 | `a639867c-b284-45f0-8b1d-d7239a501999` |
  | 小学品 | `597fc454-7190-47e3-87ec-8a507ad25ff5` |
  | 小学品 | `31b7ea04-1c16-452c-9922-720226471c4b` |
  #### `offline_list_newzuhe`：`dws.topic_order_detail.sku_group_good_id`
  | # | UUID |
  |---|------|
  | 1 | `9ea9439b-05d9-456f-b749-e04e9be9618d` |
  | 2 | `4582f84e-8ec5-4c8d-bb9e-bcea2ac58ec7` |
  | 3 | `38796a0f-1fa4-4575-addd-e23861ee2387` |
  | 4 | `1bc962db-bbb9-46f1-83e9-a123884d4157` |
  | 5 | `6d5d3ce7-ff0b-42bd-9aca-5da3c22d33b3` |
  | 6 | `9052fe05-1103-4bca-b1c0-67bd1a08a593` |
  | 7 | `50a49de0-e49e-4a79-a21a-3c77a326d80d` |
  | 8 | `08808df8-59db-49c1-a045-401884b60d43` |
  | 9 | `2ac7dd3f-c384-4bce-9ff2-315d99ee0ad4` |
  | 10 | `1afb8cb4-a0bb-4afb-8c51-5604f77ba48a` |
  | 11 | `b43a2e0a-ab1e-42ca-a7d6-5d89c4b0a7e9` |
  | 12 | `72c8b16e-319d-4551-8580-2793bfbf4252` |
  | 13 | `fe70555a-e65c-4c7e-ac84-0a97e621355a` |
  | 14 | `1a2b1705-6921-40d8-8510-874bc8cca1e7` |
  | 15 | `e891749d-e34e-42f0-be46-030c3f5abac9` |
  | 16 | `feb06d5f-fcf4-4a47-8639-09ea51741920` |
  | 17 | `bc2d9608-63b9-408e-aaac-4c5da34fc9b4` |
  | 18 | `25d3bd34-5296-4e56-87f4-b276e8abb348` |
  | 19 | `40b2b7fa-7a89-4772-9801-4f1423b60d6c` |
  | 20 | `e013242e-55cc-4c95-a1eb-5fad9db4df75` |
  | 21 | `b15e95bb-90ce-44a3-b7e9-24ba361696b8` |
  | 22 | `92ec68e7-5626-4bdf-8818-c89515708032` |
  | 23 | `ee371312-b86e-441a-9904-db115d155f30` |
  #### `offline_list_newzuhe`：`dw.fact_user_redeem_code.batch_id`（union 补充）
  | # | batch_id / id |
  |---|---------------|
  | 1 | `67bc32af6563230b9e95888d` |
  | 2 | `67ca64209dbaa1b59ba3d708` |
  | 3 | `67ca8acf9dbaa1b59ba3d70a` |
  | 4 | `6819c6991de31cdae8fa677a` |
  | 5 | `6821aa143a8ce044fdd63eaf` |
  | 6 | `68259197f3a6c7b0a4c3009b` |
  | 7 | `6864d175d3323d827e4986fc` |
  | 8 | `6864d389c2b62c65753cbbcf` |
  | 9 | `6887239bc27c232a900acb67` |
  | 10 | `68b51ad0dc986907a4dcde46` |
  | 11 | `68b51ba08a28f3ee6b8202b4` |
  | 12 | `68b51c6b8f34e857b9da54ce` |
  | 13 | `68b51ca15af47f89de82f51d` |
  | 14 | `68d8dac1e262734dc610ceee` |
  | 15 | `68d8dadf30a1fc36baccdf44` |
  | 16 | `68d8daf9e262734dc610ceef` |
  | 17 | `68d8db21e262734dc610cef0` |
  | 18 | `68ff15cd579bcf0f56a613d0` |
  | 19 | `68ff16019b2de17481c4337f` |
  | 20 | `68ff1619a64ba0189634df6b` |
  | 21 | `68ff162b579bcf0f56a613d1` |
  | 22 | `69240ef2350cd673cec39b74` |
  | 23 | `69240f3dfd77c104285f9c12` |
  | 24 | `69240f564f37600ad46fd62d` |
  | 25 | `69240f6b8021289f8b7f7914` |
  #### `offline_list_bigvip`：`sku_group_good_id`
  | # | UUID |
  |---|------|
  | 1 | `c9aee050-4cd0-4c55-80f7-a783944b533b` |
  | 2 | `9bbd656f-e1cd-4c3e-b447-daceb775a06b` |
  | 3 | `dcf59e19-5285-45ee-8b45-19c7a2ba4d6f` |
  | 4 | `862f0458-e271-4ae8-93b7-43c498fc2d58` |
  | 5 | `2ef44391-83e8-4d9f-8b2b-16d48bc6144b` |
  | 6 | `3e963d27-b353-4017-a774-18384a22ea87` |
  | 7 | `8ff119a2-264c-4f1b-8e1e-0e475762a981` |
  | 8 | `da13ea40-975f-45e5-8f2e-a254deec9ee5` |
  | 9 | `4c45c30e-ae9e-41cd-8457-ce0cab090b9c` |
  #### `offline_list_unbigvip`：`sku_group_good_id`（UUID 形）
  | # | UUID |
  |---|------|
  | 1 | `07afbb36-ce56-4ab7-ba08-edd5af43d5ae` |
  | 2 | `0a5edb06-e5b0-46f5-9af4-4130b43eba3b` |
  | 3 | `32493256-d76e-4e8c-8bf5-2db92c0bc3c4` |
  | 4 | `3631ad86-acbc-4dc4-b993-c0dcd44a6aad` |
  | 5 | `4608f80d-62a5-478f-b943-278a02db1848` |
  | 6 | `5be6b78c-9d14-4552-9e0a-2196ebdd0fff` |
  | 7 | `7f02308c-c41e-4bb6-987c-fbb7567f982b` |
  | 8 | `873d9b85-96c5-42cb-9ce9-3f32656c6d84` |
  | 9 | `8e555e52-0992-49dc-be9f-1049e7d7281d` |
  | 10 | `a6ea1393-e5ea-4db5-9af3-397a9648d774` |
  | 11 | `a82c856d-262d-4906-a5ff-4384f299e08f` |
  | 12 | `c0faab91-eab9-4181-ac35-a98541ad69ff` |
  | 13 | `cef3662e-753b-43d8-9d2c-eaf3bdac5249` |
  | 14 | `dff97d5f-94c1-4bfc-a3f9-94929bb2fb6b` |
  | 15 | `ff978544-4eae-40f8-8a7d-be1fb894e8bc` |
  | 16 | `f0db2d79-a693-45a3-bc45-a8a9379754f7` |
  | 17 | `96cff631-f488-4d63-92e7-87785bdff72a` |
  | 18 | `626900ff-7391-40a1-94f4-13b8ddded3fb` |
  | 19 | `9b23ac99-bc9d-4eed-b9b5-2be565f0a165` |
  | 20 | `c7649d8d-1fd0-40d7-a39a-45b349353784` |
  | 21 | `a5ceacdf-13db-4b7a-8290-dbd76ae3c184` |
  | 22 | `ea4559cd-75d2-467c-91f6-1d96ac0c74f3` |
  | 23 | `27fa8138-0dc9-4fdc-8687-340bdba5c4a0` |
  | 24 | `e86f12ce-6efc-4ba1-b56b-50791f1e5162` |
  | 25 | `7f4dd383-17ea-494f-af11-f34b3dfefccf` |
  | 26 | `3931de43-5b8e-4c36-8ab8-9b9d3d372ee1` |
  | 27 | `89df8825-a28a-4c38-9884-d166da5408e6` |
  | 28 | `505379ab-5393-4326-93c2-cb2cc3531c82` |
  | 29 | `25a844fc-6aa2-4488-a02e-22eff7b398ca` |
  | 30 | `2ab48047-a88c-4f75-98a0-a77aa11deb5d` |
  | 31 | `7473bbb3-975e-4256-990c-dafd59b5b619` |
  | 32 | `4bbc89c4-b171-498f-96ae-5bb18b739731` |
  #### `offline_list_unbigvip`：`sku_group_good_id`（24 位十六进制）
  | # | batch_id / id |
  |---|---------------|
  | 1 | `649e47815b86c2194646e160` |
  | 2 | `651545a1f70e1f5999154f78` |
  | 3 | `653a708618716748936d13aa` |
  | 4 | `6548b9d3c07d5347708a4d22` |
  | 5 | `6554a1550e18c8d0aacd5588` |
  | 6 | `65815854f038046dfb254f93` |
  | 7 | `6594c9b064e819fd7d46bb66` |
  | 8 | `6594c9e99190d8cc480f7b2e` |
  | 9 | `659e4e267f3c7afb9ea48b89` |
  | 10 | `659e4e6de8370fafb63238a2` |
  | 11 | `659e4eab3cf6381e1cae6380` |
  | 12 | `65d868db30f7b1b87d084fae` |
  | 13 | `65d869111142f89a37a3da81` |
  | 14 | `65d869710808304e4b556a8f` |
  | 15 | `65fd48baf028daa2638e4453` |
  | 16 | `66069829bb34d702540a3bf8` |
  | 17 | `660bcc0c3421a8414e90da4f` |
  | 18 | `663b16b8584a5d6e76b7a198` |
  | 19 | `6645700ed0206f26e0ea330c` |
  | 20 | `6675622a62afdc7480ddbdfa` |
  | 21 | `6675683f0c9e0afc8499ddd6` |
  | 22 | `6675686fab85109f2a65f681` |
  | 23 | `66756891c9712adb3331cc29` |
  | 24 | `667568ac62afdc7480ddbdfd` |
  | 25 | `667568c906d64f56491fd3e5` |
  | 26 | `667568ffc9712adb3331cc2a` |
  | 27 | `66878fff02e0624ddba3748e` |
  | 28 | `6696361f6eee27ada4e8915d` |
  | 29 | `669877c1974d69611727b806` |
  | 30 | `66b47a07bd6c964ed62d6465` |
  | 31 | `671df20d29b610450b0731d7` |
  | 32 | `671df36519bd54b0c2e93390` |
  | 33 | `671df658ae3188352d6a5a37` |
  | 34 | `65c468862e49c20223c7f2a7` |
  | 35 | `63ae4860fde765d77340c7df` |
  | 36 | `63ae4ab6bac51145975e4d09` |
  | 37 | `6749733d0098111483400546` |
  | 38 | `67497429a5e8e92422a11341` |
  #### `user_children_kind1`（多孩策略资格-常规版）与 `offline_list_newzuhe` 相同的 `sku_group_good_id` 列表
  | # | UUID |
  |---|------|
  | 1 | `9ea9439b-05d9-456f-b749-e04e9be9618d` |
  | 2 | `4582f84e-8ec5-4c8d-bb9e-bcea2ac58ec7` |
  | 3 | `38796a0f-1fa4-4575-addd-e23861ee2387` |
  | 4 | `1bc962db-bbb9-46f1-83e9-a123884d4157` |
  | 5 | `6d5d3ce7-ff0b-42bd-9aca-5da3c22d33b3` |
  | 6 | `9052fe05-1103-4bca-b1c0-67bd1a08a593` |
  | 7 | `50a49de0-e49e-4a79-a21a-3c77a326d80d` |
  | 8 | `08808df8-59db-49c1-a045-401884b60d43` |
  | 9 | `2ac7dd3f-c384-4bce-9ff2-315d99ee0ad4` |
  | 10 | `1afb8cb4-a0bb-4afb-8c51-5604f77ba48a` |
  | 11 | `b43a2e0a-ab1e-42ca-a7d6-5d89c4b0a7e9` |
  | 12 | `72c8b16e-319d-4551-8580-2793bfbf4252` |
  | 13 | `fe70555a-e65c-4c7e-ac84-0a97e621355a` |
  | 14 | `1a2b1705-6921-40d8-8510-874bc8cca1e7` |
  | 15 | `e891749d-e34e-42f0-be46-030c3f5abac9` |
  | 16 | `feb06d5f-fcf4-4a47-8639-09ea51741920` |
  | 17 | `bc2d9608-63b9-408e-aaac-4c5da34fc9b4` |
  | 18 | `25d3bd34-5296-4e56-87f4-b276e8abb348` |
  | 19 | `40b2b7fa-7a89-4772-9801-4f1423b60d6c` |
  | 20 | `e013242e-55cc-4c95-a1eb-5fad9db4df75` |
  | 21 | `b15e95bb-90ce-44a3-b7e9-24ba361696b8` |
  | 22 | `92ec68e7-5626-4bdf-8818-c89515708032` |
  | 23 | `ee371312-b86e-441a-9904-db115d155f30` |
  #### 策略资格：`user_primary_and_middle_good` 兑换码 `batch_id`
  | # | batch_id |
  |---|----------|
  | 1 | `67bc32af6563230b9e95888d` |
  | 2 | `67ca64209dbaa1b59ba3d708` |
  | 3 | `67ca8acf9dbaa1b59ba3d70a` |
  | 4 | `68b51c6b8f34e857b9da54ce` |
  | 5 | `68d8dadf30a1fc36baccdf44` |
  | 6 | `68ff1619a64ba0189634df6b` |
  | 7 | `69240f564f37600ad46fd62d` |
  | 8 | `6819c6991de31cdae8fa677a` |
  | 9 | `6821aa143a8ce044fdd63eaf` |
  | 10 | `68259197f3a6c7b0a4c3009b` |
  | 11 | `6864d175d3323d827e4986fc` |
  | 12 | `68b51ba08a28f3ee6b8202b4` |
  | 13 | `68d8daf9e262734dc610ceef` |
  | 14 | `68ff16019b2de17481c4337f` |
  | 15 | `69240f3dfd77c104285f9c12` |
  | 16 | `6864d389c2b62c65753cbbcf` |
  | 17 | `6887239bc27c232a900acb67` |
  | 18 | `68b51ad0dc986907a4dcde46` |
  | 19 | `68b51ca15af47f89de82f51d` |
  | 20 | `68d8dac1e262734dc610ceee` |
  | 21 | `68d8db21e262734dc610cef0` |
  | 22 | `68ff15cd579bcf0f56a613d0` |
  | 23 | `68ff162b579bcf0f56a613d1` |
  | 24 | `69240ef2350cd673cec39b74` |
  | 25 | `69240f6b8021289f8b7f7914` |
  #### 策略资格：`user_primary_good` 兑换码 `batch_id`
  | # | batch_id |
  |---|----------|
  | 1 | `6819c6991de31cdae8fa677a` |
  | 2 | `6821aa143a8ce044fdd63eaf` |
  | 3 | `68259197f3a6c7b0a4c3009b` |
  | 4 | `6864d175d3323d827e4986fc` |
  | 5 | `68b51ba08a28f3ee6b8202b4` |
  | 6 | `68d8daf9e262734dc610ceef` |
  | 7 | `68ff16019b2de17481c4337f` |
  | 8 | `69240f3dfd77c104285f9c12` |
  | 9 | `67bc32af6563230b9e95888d` |
  | 10 | `67ca64209dbaa1b59ba3d708` |
  | 11 | `67ca8acf9dbaa1b59ba3d70a` |
  | 12 | `6864d389c2b62c65753cbbcf` |
  | 13 | `6887239bc27c232a900acb67` |
  | 14 | `68b51ad0dc986907a4dcde46` |
  | 15 | `68b51c6b8f34e857b9da54ce` |
  | 16 | `68b51ca15af47f89de82f51d` |
  | 17 | `68d8dac1e262734dc610ceee` |
  | 18 | `68d8dadf30a1fc36baccdf44` |
  | 19 | `68d8db21e262734dc610cef0` |
  | 20 | `68ff15cd579bcf0f56a613d0` |
  | 21 | `68ff1619a64ba0189634df6b` |
  | 22 | `68ff162b579bcf0f56a613d1` |
  | 23 | `69240ef2350cd673cec39b74` |
  | 24 | `69240f564f37600ad46fd62d` |
  | 25 | `69240f6b8021289f8b7f7914` |
  #### 多孩策略资格中的 `good_kind_id_level_2`（与 `newzuhe1` 三元组一致）
  与上文 newzuhe1 三行相同，用于 `good_kind_id_level_2 in (...)` 分支。
- **计算方式**：按「UUID 与批次号全量附录」对应的业务规则执行。
- **表来源**：`dw.fact_order_detail`

### 33. 规则 R33：附录口径：单孩订单与多孩加购率（两套分母）

- **唯一规范名**：规则 R33：附录口径：单孩订单与多孩加购率（两套分母）
- **类型**：规则
- **定义**：
  - 单孩订单：`strategy_type` 标签中，非「多孩策略」的组合品订单（用于部分监测）。
  - 多孩加购率（附录，可折叠需求）：
    - 分母：当月「单孩订单」的全量用户（含曾购任意策略组合品的用户）。
    - 分子：当月存在「多孩资格优惠判断」为 true 的订单的用户。
  - 多孩加购率（2.0 正文主口径）：分母 = 有多孩策略资格的用户；分子 = 以多孩策略 −2000 购买组合品的用户。
  两套 不可混报；未写明时默认 主口径。
  其它附录约定：付费零售品/组合品/大会员续购率与「大盘活跃转化监控看板」统计分层、用户分层逻辑对齐；小学品/小初同步品用户逻辑同付费零售品续购率；寒促等活动可能对非大会员组合品用户有特殊时间窗（业务待定）。
- **计算方式**：按「附录口径：单孩订单与多孩加购率（两套分母）」对应的业务规则执行。
- **表来源**：

### 34. 规则 R34：数仓分层与血缘推理（减少重复口径说明）

- **唯一规范名**：规则 R34：数仓分层与血缘推理（减少重复口径说明）
- **类型**：规则
- **定义**：公司数仓按**四层**组织；数据**自上而下加工**（上游定义语义，下游继承并叠加汇总/筛选）。编写或阅读 `code/sql/表结构`、看板 SQL 时，应先用**表所在层级**判断字段/指标应在哪里写清定义与枚举，**避免**在每一层把同名含义再写一遍。
- **计算方式**（层级职责与典型 schema，用于推理血缘，而非替代具体 DDL）：
  1. **ODS（落地层）**  
     - 承接业务库**原始镜像**，与业务侧实体**同构**，原则上不做业务口径转换。  
     - 典型：`ods*` / `ods_rt.*` 等；仅作明细来源，**不作为**报表与指标定义的权威落点。
  2. **DWD / DW 明细层（`dw`）**  
     - 对 ODS 做清洗、格式统一、脱敏等，保证质量与完整性；保留**业务最细粒度**一行一事实（如一次行为、一笔订单明细粒度，以具体表为准）。  
     - **命名习惯**：维表 `dim_*`，事实表 `fact_*`；按日/周/月滚动的快照表常用 `_day` / `_week` / `_month` 后缀。  
     - **语义权威**：与业务对象强绑定的码表、枚举、主数据含义，优先在本层或贴源维表中**集中说明**；下游表若字段同源同名，默认**继承**该含义，除非 DDL/规则另有「重定义」说明。
  3. **DWS 公共汇总层（`dws`）**  
     - 按主题做**宽表**与多实体关联，沉淀**跨域可复用**的汇总指标与标签，统一口径、减少重复计算。  
     - **命名习惯**：主题表常见 `topic_*` 前缀（如用户、订单等主题，以实际表名为准）。  
     - **语义权威**：主题级指标、宽表派生字段的**业务定义与注意事项**适合写在本层对应表的 DDL/字典；更底层的码值、枚举若仅透传，可与 `dw` 共用一条解释，不在 `dws` 重复罗列枚举全表。
  4. **AWS 数据集市 / 应用层（`aws`）**  
     - 面向具体场景、看板、实验的**应用表**；可直接对接 Hue、FineBI 等分析工具。  
     - **命名习惯**：常以业务域词根开头（如各类 `business_*`、`mid_*`、`*_day` 应用汇总表等，以实际表为准）。  
     - **语义权威**：侧重**本层新增**的聚合字段、窗口、归因与筛选口径；若字段明显来自某张 `dw`/`dws` 主表且含义未变，**默认继承**上游解释，DDL 中写清关联键与聚合粒度即可，无需重复整段枚举说明。
- **依赖与使用约束**（推理血缘时与排错强相关）：
  - **禁止跨层直连**：`dws`、`aws` 侧需求**不应**直接引用 ODS 表完成常规报表；ODS 仅应由 `dw`（及等价明细加工链路）消费。
  - **禁止反向依赖**：ODS **不得**依赖 `dws` / `aws` 产物。
  - **同层谨慎链式**：同一主题域内尽量避免 `dws` 表再生成大量下游 `dws` 表的长链，以免 ETL 耦合与效率问题；应用层优先消费明确的主题宽表或稳定中间层。
- **两条标准数据路径**（稳定业务 vs 探索）：  
  - **稳定业务**：ODS → `dw` 明细 → `dws` 主题汇总 → `aws` 应用。  
  - **探索/非稳定需求**：可走 ODS → `dw` → `aws` 的**简化路径**，但仍需遵守「应用层不直连 ODS」的边界。
- **写作约定（本仓库）**：  
  - 某字段在**最上游首次出现**且带业务枚举/口径时，在**该层对应表**的 DDL 或本 glossary **写全**；下游同名、同含义字段用「见 `schema.table` 字段 xxx」或「继承 `dw`/`dws` 某表定义」一笔带过。  
  - 若下游对同名字段**收窄、重算或改义**（例如过滤条件变化、聚合后不再可比），必须在**当前表层**显式写出差异，避免读者误用上游枚举。
- **表来源**：`ods*` / `ods_rt.*`、`dw.*`、`dws.*`、`aws.*`（以 `code/sql/表结构/【平台】_shihua` 实际归档为准）。


## 指标

### GMV归属营收/总营收

- **唯一规范名**：GMV归属营收/总营收
- **定义**：统计周期内，基于业务GMV归属（单算）规则判定营收的业务归属，即该用户所产生的营收为所属业务GMV归属的营收总和。GMV营收不可双计或多计，因此营收总计为1+1=2（一级指标）
- **计算方式**：
`--【来源- 丹萍aws.business_active_channel_detail_day】
SELECT 
  case when business_gmv_attribution='体验营' then '体验营'
        when business_gmv_attribution='奥德赛' then '奥德赛'
        when business_gmv_attribution='商业化-电商' then '商业化-公域'
        when business_gmv_attribution='新媒体视频' then '新媒体视频'
        when business_gmv_attribution='商业化' then '商业化-APP'
        when business_gmv_attribution='入校' then '入校'
        when business_gmv_attribution='电销' then '电销/网销'
        when business_gmv_attribution='新媒体变现' then '研学'
        else  business_gmv_attribution
        end as business_gmv_attribution--渠道标签
 ,paid_time_sk --支付时间
 ,sum(sub_amount) AS amount --营收金额
FROM dws.topic_order_detail 
GROUP BY 1, 2`
- **表来源**：`dws.topic_order_detail`
- **筛选条件**：1.如果明确是“正价商品/正价课”的营收，则original_amount >= 39；如果不明确，则不加筛选;2.统计周期（日/月）；日维度、月维度下学段、年级段、年级、业务分层、统计分层

### 服务期营收

- **唯一规范名**：服务期营收
- **定义**：统计周期内，基于用户服务期归属判定营收的业务归属，即该用户所产生的营收为所属业务服务期的营收总和。服务期营收可双计或多计，因此营收总计为1+1>2（一级指标）
- **计算方式**：
`--【来源- 丹萍aws.business_active_channel_detail_day】
SELECT nvl(team_name,'其他') --渠道标签
 ,paid_time_sk --支付时间
 ,sum(sub_amount) AS amount --营收金额
FROM dws.topic_order_detail 
LATERAL VIEW OUTER explode (team_names) a AS team_name
GROUP BY 1, 2`
- **表来源**：`dws.topic_order_detail`
- **筛选条件**：；1.如果明确是“正价商品/正价课”的营收，则original_amount >= 39；如果不明确，则不加筛选;2.统计周期（日/月）；日维度、月维度下学段、年级段、年级、业务分层、统计分层

### 平台成单营收

- **唯一规范名**：平台成单营收
- **定义**：统计周期内，基于订单成单时的平台判定营收的业务归属，即该用户所产生的营收为在所属平台成单的营收总和。平台成单营收不可双计或多计，因此营收总计为1+1=2（一级指标）
- **计算方式**：
`--【来源- 丹萍aws.business_active_channel_detail_day】
SELECT 
  case when sell_from regexp 'telesale' then '电销/网销'
            when sell_from regexp 'tiyanying' then '体验营'
            when sell_from regexp 'ruxiao' then '入校'
            when sell_from regexp 'aodesai' then '奥德赛'
            when sell_from regexp 'xinmeitishipin' or sell_from regexp 'xinmeiti_doudian' or sell_from regexp 'xinmeiti_shipin' or sell_from regexp 'xinmeiti_xiaohongshu' then '新媒体视频'
            when sell_from = 'xinmeiti' or sell_from regexp 'xinmeitibianxian' or sell_from regexp 'yanxue' or sell_from regexp 'xinmeiti_weidian' or sell_from regexp 'xinmeiti_bianxian' or sell_from regexp 'Xinmeitigongzhonghao' then '研学'
            when sell_from regexp 'shangyehua' or sell_from regexp 'app' then '商业化-APP'
            else '商业化-APP'
            end as sellfrom
 ,paid_time_sk --支付时间
 ,sum(sub_amount) AS amount --营收金额
FROM dws.topic_order_detail
GROUP BY 1, 2`
- **表来源**：`dws.topic_order_detail`
- **筛选条件**：1.如果明确是“正价商品/正价课”的营收，则original_amount >= 39；如果不明确，则不加筛选;2.统计周期（日/月）；日维度、月维度下学段、年级段、年级、业务分层、统计分层

### 活跃用户数

- **唯一规范名**：活跃用户数
- **定义**：C端APP活跃用户数（一级指标）
- **计算方式**：`count(distinct u_user)`
- **表来源**：`aws.business_active_user_last_14_day`
- **筛选条件**：统计周期（日/月）；日维度、月维度下学段、年级段、年级、业务分层、统计分层

### 活跃付费用户数

- **唯一规范名**：活跃付费用户数
- **定义**：C端APP活跃用户中正价付费用户数（二级指标）
- **计算方式**：`count(distinct u_user)`
- **表来源**：`aws.business_active_user_last_14_day`,`dws.topic_order_detail`
- **筛选条件**：正价订单`original_amount >= 39`，且`sum(sub_amount) > 0`；统计周期（日/月）；日维度、月维度下学段、年级段、年级、业务分层、统计分层

### 活跃付费金额

- **唯一规范名**：活跃付费金额
- **定义**：C端APP活跃用户中正价付费金额（二级指标）
- **计算方式**：`sum(sub_amount)`
- **表来源**：`aws.business_active_user_last_14_day`,`dws.topic_order_detail`
- **筛选条件**：正价订单`original_amount >= 39`，且`sum(sub_amount) > 0`；统计周期（日/月）；日维度、月维度下学段、年级段、年级、业务分层、统计分层

### 活跃转化率

- **唯一规范名**：活跃转化率
- **定义**：活跃付费用户数/活跃用户数（二级指标）
- **计算方式**：同定义
- **表来源**：见定义的指标的表来源
- **筛选条件**：统计周期（日/月）；日维度、月维度下学段、年级段、年级、业务分层、统计分层

### 活跃客单价

- **唯一规范名**：活跃客单价
- **类型**：指标
- **定义**：活跃付费金额/活跃付费用户数（二级指标）
- **计算方式**：同定义
- **表来源**：见定义的指标的表来源
- **筛选条件**：统计周期（日/月）；日维度、月维度下学段、年级段、年级、业务分层、统计分层

### 活跃ARPU

- **唯一规范名**：活跃ARPU
- **定义**：活跃付费金额/活跃用户数（二级指标）
- **计算方式**：同定义
- **表来源**：见定义的指标的表来源
- **筛选条件**：统计周期（日/月）；日维度、月维度下学段、年级段、年级、业务分层、统计分层

### 活跃订单量

- **唯一规范名**：活跃订单量
- **定义**：活跃用户的订单个数（二级指标）
- **计算方式**：`COUNT(DISTINCT order_id)`
- **表来源**：`aws.business_active_user_last_14_day`,`dws.topic_order_detail`
- **筛选条件**：正价订单`original_amount >= 39`，且`sum(sub_amount) > 0`；统计周期（日/月）；日维度、月维度下学段、年级段、年级、业务分层、统计分层

### 资源位曝光用户数

- **唯一规范名**：资源位曝光用户数
- **定义**：资源位曝光用户数 指标。（三级指标）
- **计算方式**：`count(distinct get_entrance_user)`
- **表来源**：`aws.business_user_pay_process_day`
- **筛选条件**：资源位位置、资源位ID、统计周期（日/XX时间段）；统计周期内用户首次的学段、年级段、年级、业务分层、统计分层

### 资源位点击用户数

- **唯一规范名**：资源位点击用户数
- **定义**：资源位点击用户数 指标。（三级指标）
- **计算方式**：`count(distinct click_entrance_user)`
- **表来源**：`aws.business_user_pay_process_day`
- **筛选条件**：`count(distinct get_entrance_user) > 0`；资源位位置、资源位ID、统计周期（日/XX时间段）；统计周期内用户首次的学段、年级段、年级、业务分层、统计分层

### 资源位商品页面进入用户数

- **唯一规范名**：资源位商品页面进入用户数
- **定义**：商品页面进入用户数 指标。（三级指标）
- **计算方式**：`count(distinct enter_good_page_user)`
- **表来源**：`aws.business_user_pay_process_day`
- **筛选条件**：`count(distinct get_entrance_user) > 0 and count(distinct click_entrance_user) > 0`；商品页面名称、进入来源、统计周期（日/XX时间段）；统计周期内用户首次的学段、年级段、年级、业务分层、统计分层

### 资源位商品页面点击购买用户数

- **唯一规范名**：资源位商品页面点击购买用户数
- **定义**：商品页面点击购买按钮（点击后跳转订单详情页）的用户数（三级指标）
- **计算方式**：`count(distinct click_good_page_user)`
- **表来源**：`aws.business_user_pay_process_day`
- **筛选条件**：`count(distinct get_entrance_user) > 0 and count(distinct click_entrance_user) > 0 and count(distinct enter_good_page_user)`；商品页面名称、进入来源、统计周期（日/XX时间段）；统计周期内用户首次的学段、年级段、年级、业务分层、统计分层

### 资源位进入订单详情页用户数

- **唯一规范名**：资源位进入订单详情页用户数
- **定义**：进入订单详情页用户数 指标。（三级指标）
- **计算方式**：`count(distinct enter_order_page_user)`
- **表来源**：`aws.business_user_pay_process_day`
- **筛选条件**：`count(distinct get_entrance_user) > 0 and count(distinct click_entrance_user) > 0 and count(distinct enter_good_page_user) and count(distinct click_good_page_user) > 0`；商品页面名称、进入来源、统计周期（日/XX时间段）；统计周期内用户首次的学段、年级段、年级、业务分层、统计分层

### 资源位确认购买用户数

- **唯一规范名**：资源位确认购买用户数
- **定义**：订单详情页点击确认购买按钮的用户数（三级指标）
- **计算方式**：`count(distinct click_order_page_user)`
- **表来源**：`aws.business_user_pay_process_day`
- **筛选条件**：`count(distinct get_entrance_user) > 0 and count(distinct click_entrance_user) > 0 and count(distinct enter_good_page_user) and count(distinct click_good_page_user) > 0 and count(distinct enter_order_page_user) >0`；商品页面名称、进入来源、统计周期（日/XX时间段）；统计周期内用户首次的学段、年级段、年级、业务分层、统计分层

### 资源位支付成功用户数

- **唯一规范名**：资源位支付成功用户数
- **定义**：支付成功用户数 指标。（三级指标）
- **计算方式**：`count(distinct paid_order_user)`
- **表来源**：`aws.business_user_pay_process_day`
- **筛选条件**：`count(distinct get_entrance_user) > 0 and count(distinct click_entrance_user) > 0 and count(distinct enter_good_page_user) and count(distinct click_good_page_user) > 0 and count(distinct enter_order_page_user) >0 and count(distinct click_order_page_user) > 0`；商品页面名称、进入来源、统计周期（日/XX时间段）；统计周期内用户首次的学段、年级段、年级、业务分层、统计分层

### 资源位支付金额

- **唯一规范名**：漏斗-支付金额
- **定义**：支付金额 指标。（三级指标）
- **计算方式**：`sum(amount)`
- **表来源**：`aws.business_user_pay_process_day`
- **筛选条件**：`count(distinct get_entrance_user) > 0 and count(distinct click_entrance_user) > 0 and count(distinct enter_good_page_user) and count(distinct click_good_page_user) > 0 and count(distinct enter_order_page_user) >0 and count(distinct click_order_page_user) > 0 and count(distinct paid_order_user) > 0`;商品页面名称、进入来源、统计周期（日/XX时间段）；统计周期内用户首次的学段、年级段、年级、业务分层、统计分层

## 维度

### business_user_pay_status_business（商业化业务维度）

- **唯一规范名**：business_user_pay_status_business（商业化业务维度）
- **类型**：维度
- **定义**：商业化 + 业务时间口径（30 天）下的分层；默认取数优先用本字段。
- **计算方式**：枚举值
- **表来源**：
  `dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`aws.clue_info`
  - 口径说明：1.与 `business_user_pay_status_statistics` 的差异在「新/老」时间窗口（日 vs 30 天）。

### business_user_pay_status_statistics（商业化统计维度）

- **唯一规范名**：business_user_pay_status_statistics（商业化统计维度）
- **类型**：维度
- **定义**：商业化 + 统计时间口径下的分层（含高净值 / 续费 / 新增 / 老未）。
- **计算方式**：枚举值
- **表来源**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`aws.clue_info`

### course_timing_kind（商品类型）

- **唯一规范名**：course_timing_kind（商品类型）
- **类型**：维度
- **定义**：
  含义：`course_timing_kind` = 商品类型（时长型、到期型等），会随业务变。
  2026-01-01 之后：开发库同步。
  2026-01-01 之前：
  历史清洗 SQL 核心逻辑（字段名与库内一致为准）：
  ```sql
  -- course_timing_kind：时长型 / 到期型
  CASE
    WHEN good_kind_id_level_3 = 'a639867c-b284-45f0-8b1d-d7239a501999'
         AND business_good_kind_name_level_2_old = '单学段商品' -- business_good_kind_name_level_2_old指1.0的business_good_kind_name_level_2，已下线，下同
         AND business_good_kind_name_level_3_old = '小学品' THEN '时长型'
    WHEN good_kind_id_level_3 = '597fc454-7190-47e3-87ec-8a507ad25ff5'
         AND business_good_kind_name_level_2_old = '单学段商品'
         AND business_good_kind_name_level_3_old = '小学品' THEN '时长型'
    WHEN business_good_kind_name_level_2_old = '单学段商品'
         AND business_good_kind_name_level_3_old IN ('初中品', '高中品') THEN '到期型'
    WHEN business_good_kind_name_level_2_old = '多学段商品'
         AND business_good_kind_name_level_3_old IN ('初中品', '高中品') THEN '到期型'
    WHEN business_good_kind_name_level_2_old = '特殊品' THEN '时长型'
  END AS course_timing_kind_new;
  ```
- **计算方式**：见定义
- **表来源**：`dws.topic_order_detail`

### course_group_kind（商品分组）

- **唯一规范名**：course_group_kind（商品分组）
- **类型**：维度
- **定义**：
  含义：`course_group_kind` = 商品分组（公域主推品、私域主推品等），表达公私域主推，会随业务变。
  2026-01-01 之后：开发库同步。
  2026-01-01 之前：
  历史清洗 SQL 核心逻辑（字段名与库内一致为准）：
  ```sql
  -- course_group_kind：公域主推品 / 私域主推品
  CASE
    WHEN good_kind_id_level_3 = '597fc454-7190-47e3-87ec-8a507ad25ff5'
         AND business_good_kind_name_level_2_old = '单学段商品' -- business_good_kind_name_level_2_old指1.0的business_good_kind_name_level_2，已下线，下同
         AND business_good_kind_name_level_3_old = '小学品' THEN '私域主推品'
    WHEN good_kind_id_level_3 = 'a639867c-b284-45f0-8b1d-d7239a501999'
         AND business_good_kind_name_level_2_old = '单学段商品'
         AND business_good_kind_name_level_3_old = '小学品' THEN '公域主推品'
    WHEN business_good_kind_name_level_2_old = '单学段商品'
         AND business_good_kind_name_level_3_old IN ('初中品', '高中品') THEN '私域主推品'
    WHEN business_good_kind_name_level_2_old = '多学段商品'
         AND business_good_kind_name_level_3_old IN ('初中品', '高中品') THEN '私域主推品'
    WHEN business_good_kind_name_level_2_old = '特殊品' THEN '公域主推品'
  END AS course_group_kind_new;
  ```
  验收：用历史快照订单表与 `dws.topic_order_detail` 同 `order_id` 比对 `course_timing_kind`、`course_group_kind`（及类目迭代结果）。
  
- **计算方式**：见定义
- **表来源**：`dws.topic_order_detail`

### strategy_type（策略类型）

- **唯一规范名**：strategy_type（策略类型）
- **类型**：维度
- **定义**：
  订单实际使用的策略；枚举侧包含：多孩策略、高中囤课策略、学习机加购策略、补差策略、历史大会员续购策略、无策略等。
  - 2026-01-01 及以后：
    - 开发库同步；清洗后，非上述五类策略的订单统一打 无策略。
    - 多孩策略若策略组合里混有「无策略」与其它策略，剔除无策略后再归类（以落表为准）。
    - promotions 表映射（同步规则）：

  | 策略 | 条件 |
  |------|------|
  | 补差策略 | `category = 补差价优惠` |
  | 多孩策略 | `category = 续购优惠` 且 `strategyCategory = mulChild` |
  | 高中囤课策略 | `category = 续购优惠` 且 `strategyCategory = highHoardCourse` |
  | 学习机加购策略 | `category = 续购优惠` 且 `strategyCategory = padAddPur` |
  | 历史大会员续购策略 | `category = 续购优惠` 且 `strategyCategory = hisMem`（以线上字段拼写为准） |
  | 无策略 | 未命中上述 |

  - 2026-01-01 之前（数仓清洗）：
    - 补差策略：`promotions.kind = '补差价优惠'` 且 `promotions.补差价优惠` 与 `order_deductible_info` 中 `deductCategory = direct`（商品直降优惠）等组合满足文档不等式（直降金额 > 0 等，以脚本为准）。
    - 无策略：否则多为无策略。
    - `order_deductible_info.info` 为 JSON 数组，元素示例：`deductCategory: "direct"` 表示存在直降优惠。

  - 计算方式（筛组合品后使用）：`strategy_type` 字段；禁止全表直接 `GROUP BY strategy_type`。
  
- **计算方式**：见定义
- **表来源**：`dws.topic_order_detail`、`dw.fact_order_detail`。

### user_identity（身份等级）

- **唯一规范名**：user_identity（身份等级）
- **类型**：维度
- **定义**：研究员等级等业务身份。
- **计算方式**：直接取字段。
- **表来源**：`dws.topic_user_active_detail_day`、`dw.dim_user`
- **⚠️ 注意**：取值列表 → `code/sql/表结构/` 对应表 DDL 第三段「枚举值」「user_identity」。

### user_strategy_tag_day 等（策略用户分层）

- **唯一规范名**：user_strategy_tag_day 等（策略用户分层）
- **类型**：维度
- **定义**：在订单历史聚合得到的 `user_pay` 度量之上，按 固定顺序 的 `CASE` 分支，将用户划入「付费组合品 / 付费加购品 / 历史大会员（可再拆可续购·不可续购）/ 剩余组合品 / 付费零售品 / 新用户 / 老用户」等策略线；用于 商品体系 2.0 策略看数，与 `business_user_pay_status_*` 中粗粒度「高净值用户」不是同一字段。
- **计算方式**：
  - `user_strategy_tag_day`：日粒度策略用户分层（用户活跃日表、用户主题信息日表、近 14 天商业化活跃日表、订单宽表等）。
    - `user_strategy_tag_month`：月粒度（用户活跃月表、用户主题信息月表、订单宽表、渠道活跃月表等）。
    - `user_strategy_tag_year`：年粒度（订单宽表、近 14 天商业化活跃日表等）。
    - `user_strategy_tag_week`：周粒度（`dws.topic_user_active_detail_week`）；与同族日/月/年 同一套枚举与加工思路，时间窗口随分区粒度变化。

  （节选；顺序敏感；完整 `offline_list_*` / `good_kind_id_level_*` 白名单见本节文末「UUID 与批次号全量附录」）：

    1. 订单聚合 CTE `user_pay`（典型度量） — 与下文「策略用户身份：`user_pay` 聚合与分层 CASE」同表：

    | 度量 | 含义（原 SQL 条件摘要） |
    |------|-------------------------|
    | `zuhe` | `business_good_kind_name_level_1 = '组合品'` 的实付金额 |
    | `bigvip1` | `paid_time_sk < 20250301` 且 `good_kind_id_level_2 in ('1ea973d0-bb4c-4499-bca7-330378a7baad','ad1d45cb-21b9-478b-8cc7-3fd75ac93aa4')` 的金额 |
    | `bigvip2` | `business_good_kind_name_level_3 = '普通续购'` 的金额 |
    | `bigvip3` | 命中 `offline_list_bigvip`（兑换码等）补充的大会员金额 |
    | `unbigvip` | 命中 `offline_list_unbigvip` 需剔除的历史 6 年品等金额 |
    | `newzuhe1` | `good_kind_id_level_2 in ('5e42f66c-0376-41b6-860b-9e437662283a','14cd8784-5583-48a6-a14b-85dfc63a2848','0d63071c-a690-4b51-ba2d-c9387c69026c')` |
    | `newzuhe2` | 命中 `offline_list_newzuhe` 等补充的组合品金额 |
    | `jiagou` | `good_kind_id_level_3 in ('77142d09-5cc6-43b1-82d0-089f906a5f1e','7cf62e78-b244-41d3-b3a5-9490b87dfef2')` |

    2. 分层 CASE（原 SQL 片段） — 在 `user_pay` 结果上：

  ```sql
  CASE
    WHEN newzuhe1 + newzuhe2 > 0 THEN '付费组合品用户'
    WHEN jiagou > 0 THEN '付费加购品用户'
    WHEN bigvip1 + bigvip2 + bigvip3 > unbigvip THEN '历史大会员用户'  /* 落表可映射为「历史大会员用户_可续购 / _不可续购」，见 ⚠️ 与 DDL */
    WHEN zuhe > 0 THEN '剩余组合品用户'
    WHEN b_u_user > 0 THEN '付费零售品用户'
    WHEN is_new = 0 THEN '老用户'
    WHEN is_new > 0 THEN '新用户'
  END
  ```

    3. 日 / 月 / 年 / 周：同一套逻辑在 不同统计日（或月、年、周）截止的订单集合上计算；`is_new` 等辅助字段含义以各表字段 COMMENT 与加工脚本为准。
- **表来源**：
  （取数时按粒度选表；枚举值全文见各表 `code/sql/表结构/{表名}.sql` 第三段「`user_strategy_tag_*`」）：

    | 粒度 | 典型表与字段 |
    |------|----------------|
    | 日 | `dws.topic_user_active_detail_day.user_strategy_tag_day`、`dws.topic_user_info.user_strategy_tag_day`、`aws.business_active_user_last_14_day.user_strategy_tag_day`、`dws.topic_order_detail.user_strategy_tag_day` |
    | 周 | `dws.topic_user_active_detail_week.user_strategy_tag_week` |
    | 月 | `dws.topic_user_active_detail_month.user_strategy_tag_month`、`dws.topic_user_info_month.user_strategy_tag_month`、`dws.topic_order_detail.user_strategy_tag_month`、`aws.business_active_channel_month.user_strategy_tag_month` 等 |
    | 年 | `dws.topic_order_detail.user_strategy_tag_year`、`aws.business_active_user_last_14_day.user_strategy_tag_year` 等 |
- **⚠️ 注意**：
  - 与 `business_user_pay_status_*` 分工不同：商业化默认分层用后者；策略线（历史大会员 vs 组合品、可续购拆分） 用 `user_strategy_tag_*`。
    - 最终取值以 DDL 枚举为准：上表 `CASE` 中「历史大会员用户」「剩余组合品用户」等与落表字符串可能经 二次映射；订单宽表 `big_vip_kind_day/month/year` 与 `user_strategy_tag_*` 的对应关系见 `code/sql/表结构/【平台】_shihua/dws.topic_order_detail.sql` 第三段。
    - `user_strategy_eligibility_*` 表示策略资格标签，依赖策略分层但含义不同，勿与 `user_strategy_tag_*` 混用。
    - 若脚本与线上一致性有疑，以数仓落表与 DDL 第三段为准。

### 同步类订单字段

- **唯一规范名**：同步类订单字段
- **类型**：维度
- **定义**：
  | 字段 | 说明 |
  |------|------|
  | `userauth_exchange_time` | 授权转换时间（开发库同步） |
  | `delay_vip_activation_time` | 高中囤课品延迟开通激活时间；分析维表常用：`CASE WHEN strategy_type REGEXP '高中囤课策略' THEN delay_vip_activation_time ELSE NULL END` |
  | `multi_child_refund_time` | 多孩退差价时间；可与 `refund_reason = '多胎加购商品退款/用户原因/暂时用不到'` 等联合校验（枚举以线上为准） |
  
- **计算方式**：直接取「同步类订单字段」对应字段或按文内映射规则分组/筛选。
- **表来源**：

### fix_good_year（商品时长）

- **唯一规范名**：fix_good_year（商品时长）
- **类型**：维度
- **定义**：订单的商品权益时长标签。
- **计算方式**：直接取字段。
- **表来源**：`dws.topic_order_detail`、`aws.crm_order_info`

### good_kind_name_level_*（商品类目-一/二/三级）

- **唯一规范名**：good_kind_name_level_*（商品类目-一/二/三级）
- **类型**：维度
- **定义**：从一级到三级的原始商品类目体系，与产品后台/开发数据库的类目一致。
- **计算方式**：`good_kind_name_level_1/2/3`枚举值。
- **表来源**：`dws.topic_order_detail`、`aws.crm_order_info`

### business_good_kind_name_level_*（策略组修正-商品类目-一/二/三级）

- **唯一规范名**：策略组类目（business_good_kind_name_level_*）
- **类型**：维度
- **定义**：业务视角修正后的类目，用于营收结构与策略分析。
- **计算方式**： `business_good_kind_name_level_1/2/3`枚举值 。
- **表来源**：`dws.topic_order_detail`、`aws.crm_order_info`

### 地理位置与城市线级

- **唯一规范名**：地理位置与城市线级
- **类型**：维度
- **定义**：省市区及城市线级（一线/二线等）。
- **计算方式**：直接使用 `province` / `city` / `area` 及对应 `*_code`；线级用 `city_class`。
- **表来源**：订单、活跃、用户、线索等宽表，底层映射`dw.dim_region_his`表。
- **⚠️ 注意**：字段名在各表一致时需确认是否已做脱敏或编码口径。

### 城市线级分组（高线 / 低线）

- **唯一规范名**：城市线级分组（高线 / 低线）
- **类型**：维度
- **定义**：将 `city_class` 归为高线（1～2 线）与低线（3～5 线）等，用于寒假流量归因（线下辅导、免费工具等假设验证）。
- **计算方式**：
  ```sql
  CASE
    WHEN city_class IN ('一线', '新一线', '二线') THEN '高线城市(1-2线)'
    WHEN city_class IN ('三线', '四线', '五线', '六线') THEN '低线城市(3-5线)'
    ELSE '其他'
  END
  ```
- **表来源**：`dws.topic_user_active_detail_day.city_class`；亦可关联 `dw.dim_region`（`city_code` → `city_class`）。
- **⚠️ 注意**：省/市/线级与 `topic_user_active_detail_day` 同行字段 JOIN 时注意去重粒度。


### stage（学段）

- **唯一规范名**：stage（学段）
- **类型**：维度
- **定义**：用户/订单/线索所属学段（中学修正口径 vs 线索原始口径）。
- **计算方式**：订单/活跃用 `mid_stage_name`；线索用 `clue_stage`；用户表无学段时需由 `grade` 映射。
- **表来源**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`aws.clue_info`、`dw.dim_user`（间接）

### grade（年级）

- **唯一规范名**：grade（年级）
- **类型**：维度
- **定义**：用户填写或业务修正后的年级。
- **计算方式**：订单/活跃 `mid_grade`；线索 `clue_grade`；用户 `grade`。
- **表来源**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`aws.clue_info`、`dw.dim_user`

### gender（性别）

- **唯一规范名**： gender（性别）
- **类型**：维度
- **定义**：用户性别。
- **计算方式**：直接取 `gender`。
- **表来源**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`dw.dim_user`、`aws.clue_info`

### 方案型商品

- **唯一规范名**：方案型商品
- **类型**：维度
- **定义**：商品类目之一，一般指代高价商品（也是主推商品）
- **计算方式**：`good_kind_name_level_1 = '方案型商品'`
- **表来源**：`dws.topic_order_detail`


### 新方案型商品

- **唯一规范名**：新方案型商品
- **类型**：维度
- **定义**：商品体系2.0之后，商品分析语境下的方案型商品，区别于原“方案型商品”。
- **计算方式**：`business_good_kind_name_level_1 in ('组合品','续购')`
- **表来源**：`dws.topic_order_detail`


### 常规型商品

- **唯一规范名**：常规型商品
- **类型**：维度
- **定义**：商品类目之一，一般指代低价商品
- **计算方式**：`good_kind_name_level_1 = '方案型商品'`
- **表来源**：`dws.topic_order_detail`


### 新常规型商品

- **唯一规范名**：新常规型商品
- **类型**：维度
- **定义**：商品体系2.0之后，商品分析语境下的常规型商品，区别于原“常规型商品”。
- **计算方式**：`business_good_kind_name_level_1 not in ('组合品','续购')`
- **表来源**：`dws.topic_order_detail`


### 活跃类型（新增 / 持续 / 回流）

- **唯一规范名**：活跃类型（新增 / 持续 / 回流）
- **类型**：维度
- **定义**：在寒假大盘活跃基础上，按「假日前最后一次活跃」距寒假开始日远近拆成三类，用于判断下降来自回流还是持续活跃。
- **计算方式**：
  （与 `2025-2026寒假流量新增持续回流拆分.sql` 一致）：
    - 新增：`business_user_pay_status_statistics = '新增'`（当日行上的商业化统计分层字段）。
    - 持续：非新增，且 `datediff(寒假开始日, last_active_before_holiday) <= 7`。
    - 回流：非新增，且上述间隔 `> 7` 或无历史活跃记录。
    - 去年寒假开始锚点：`2025-01-01`；今年：`2026-01-26`；`last_active_before_*` 由各年寒假首日前 `topic_user_active_detail_day` 中 `max(day)` 得到。
- **表来源**：`dws.topic_user_active_detail_day` + 历史活跃子查询。
- **⚠️ 注意**：与「C 端」三件套独立；7 天阈值变更需同步改 SQL。

### 用户身份（real_identity）

- **唯一规范名**：用户身份（real_identity）
- **类型**：维度
- **定义**：用户真实身份，判是否家长必须以本字段为准。
- **计算方式**：
  - 是否家长：`real_identity IN ('parents', 'student_parents')`
    - 细分类：`CASE WHEN real_identity = 'student' THEN '纯学生' WHEN real_identity = 'student_parents' THEN '学生家长共用' WHEN real_identity = 'parents' THEN '纯家长' ELSE '其他' END`
    - `is_parents` 派生：`IF(real_identity IN ('parents', 'student_parents'), true, false)`
- **表来源**：`dw.dim_user` 为主；`aws.clue_info.real_identity` 口径有合并（见 `code/sql/表结构/` 对应表 DDL 第三段「枚举值」「real_identity」备注）
- **⚠️ 注意**：⚠️ 线索表将 `parents`、`student_parents` 合并显示为 `parents`；禁止用 `role` 判断家长。取值明细 → `code/sql/表结构/` 对应表 DDL 第三段「枚举值」「real_identity」。


### 金额与优惠券字段

- **唯一规范名**：金额与优惠券字段
- **类型**：维度
- **定义**：
  | 字段 | 含义 |
  |------|------|
  | `original_amount` | 超值价 / 订单原价 |
  | `sub_amount` | 到手价 / 实收金额 |
  | `discount_amount` | 实际优惠总金额 = 超值价 − 到手价（含优惠券） |
  | `discount_id` | 优惠券 ID 列表 |
  | `discount_price` | 优惠券金额之和 |
  单券明细查询示例（库表以线上为准）：
  ```sql
  SELECT id,
         promotion_id,
         order_id,
         note,
         discount
  FROM go_order.promotions;
  ```
  
- **计算方式**：直接取「金额与优惠券字段」对应字段或按文内映射规则分组/筛选。
- **表来源**：

### 优惠金额明细（strategy_detail）

- **唯一规范名**：优惠金额明细
- **类型**：维度
- **定义**：
  - 当 策略类型 = 无策略：未使用优惠 → `{无策略:0}`；仅直降或优惠券 → `{无策略:<金额>}`。
  - 当 策略类型 ≠ 无策略：无额外直降/券 → `{策略名:<金额>, 无策略:0}`；叠加直降或优惠券 → `{策略名:<金额>, 无策略:<金额>}`。
  - 20260101 前后清洗规则与 `strategy_type` 一致；日期对齐 `paid_time_sk`。
- **计算方式**：见定义
- **表来源**：`dws.topic_order_detail`