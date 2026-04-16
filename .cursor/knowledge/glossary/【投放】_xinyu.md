# 【投放】业务知识字典

> 本词典定义业务术语的数据口径，确保取数时口径一致。
> 
> **使用方式**：遇到业务术语时，先查本词典确认数据定义，再写SQL。

| 快速定位 | 说明 |
|---------|------|
| **投放与增长** | **「一、投放与增长」** |
| **体验营** | **「二、体验营」** |

---

## 一、投放与增长

### 每日新增用户数
- **定义**：按日汇总的新增用户数据
- **数据来源**：`aws.user_increase_new_add_day`
- **计算方式**：`count(distinct u_user) 
- **适用表**：`aws.user_increase_new_add_day`
- **核心字段**：`day`（日期）、`u_user`（用户id）


### 每日投放量
- **定义**：按日汇总的投放消耗金额与投放用户量
- **数据来源**：`tmp.wxy_consume_day_total`
- **计算方式**：`channel = '汇总'` 取全渠道汇总
- **适用表**：`tmp.wxy_consume_day_total`
- **核心字段**：`date1`（日期）、`consume_pay`（投放金额）、`consume_user`（投放量）

### 裂变拉新量
- **定义**：裂变活动邀请成功产生的新用户数
- **数据来源**：`growth_activity.fission1201_invite_user`
- **计算方式**：`status IN ('邀请成功','待绑定手机号','手机号重复','设备重复')` 均算成功拉新（实际仅「邀请成功」发放奖励）
- **适用表**：`growth_activity.fission1201_invite_user`
- **核心字段**：`user_id`（被邀请人）、`invite_from`（邀请人）、`status`（状态）

### 自然量
- **定义**：总量 - 投放量 - 新媒体口令拉新量 - 裂变拉新量
- **计算方式**：`自然量 = 总量 - 投放量 - 新媒体口令拉新量 - 裂变拉新量`
- **各分量口径**：总量见「App 总量」、投放量见「每日投放量」、裂变见「裂变拉新量」、新媒体口令见「新媒体口令核减后拉新量」


### 投放归因（点击归因）
- **定义**：投放过程中，用户在外部媒体点击广告后的激活/注册/付费数据，用于检测各渠道广告链路转化情况。
- **数据来源**：按场景选表（三张表字段结构一致，**不是同一张表**）：
  | 表 | 实时 | 内容 | 适用场景 |
  |----|------|------|----------|
  | `thirdparty.traffic` | T+1 | 点击/激活/注册 | 标准归因主表（历史分析） |
  | `traffic_investment.traffic` | T+1 | 仅点击（冷数据） | 2026-03-23 起仅存点击，激活/注册不回写 |
  | `dw.fact_traffic` | T+1 | 点击归因明细（分区） | 数仓层汇总，查询通常比 thirdparty 慢；无需全量点击时优先 thirdparty |
  | `thirdparty.traffic_hour` | ~1h延迟 | 激活+注册 | 当日激活/注册核对 |
  | `default_catalog.ods.thirdparty_traffic` | ✅无延迟 | **仅注册** | 实时核对注册回传；oaid 为空 |
- **适用表**：按上表选；常用 `thirdparty.traffic`（标准归因）、`dw.fact_traffic`（数仓分区总表）
- **核心字段**：`id`（关联广告明细表 traffic_id）、`oaid`、`userid`、`status`、`source`、`channel`、`clicktime`、`activatetime`、`registertime`
- **status 状态**：0=点击 1=激活 2=注册 3=付费（新状态覆盖旧值）→ 枚举与筛选详见 `code/sql/表结构/thirdparty.traffic.sql`、`code/sql/表结构/dw.fact_traffic.sql`
- **⚠️ 注意**：`dw.fact_traffic` 与 `thirdparty.traffic` 均为明细粒度，非「按渠道去重表」。具体广告位华为用 `channel` 直接标识，oppo/vivo 需关联 attribution → `table-relations.md#八、投放归因表关联`

### 少回传（注册回传压制）
- **定义**：投放侧按渠道配置回传比例，让部分注册用户**不回传**给媒体（压制），以降低媒体 eCPM 或优化结算成本；上线于 4.8。
- **数据来源**：`thirdparty.register_callback_record`（每个注册用户一条；关联 `thirdparty.traffic.id`）
- **计算方式**：
  | 口径 | SQL 表达式 |
  |------|-----------|
  | 少回传前用户数（全量注册） | `COUNT(DISTINCT traffic.userid) WHERE status >= 2` |
  | 少回传用户数（被压制，不回传） | `COUNT(DISTINCT ... WHERE sample_hit = 0)` |
  | 少回传后用户数（实际回传） | `COUNT(DISTINCT ... WHERE sample_hit = 1 OR sample_hit IS NULL)` |
- **适用表**：`thirdparty.register_callback_record`（与 `thirdparty.traffic` 通过 `traffic_id = id` 关联）
- **核心字段**：`sample_hit`（命中回传=1 / 不回传=0）、`traffic_id`、`callback_ratio`
- **⚠️ 注意**：少量走旧接口注册的用户（约 40 条/天，修复中）不会写入本表，这些用户已正常回传，`sample_hit IS NULL` 时归入「实际回传」口径。→ `code/sql/表结构/thirdparty.register_callback_record.sql`

### 渠道标签（用户增长归因标签）
- **定义**：根据 apk/api 点击归因逻辑，以优先 api 归因、再 apk 归因的方式，对2025年之后注册用户打渠道标签。
- **数据来源**：`aws.user_increase_channel_label_day`（上游 `aws.user_increase_new_add_day`）
- **适用表**：`aws.user_increase_channel_label_day`
- **核心字段**：`u_user`、`regist_channel_label1`（一级）、`regist_channel_label2`（二级）、`regist_channel_label3`（三级）
- **一级标签**：投放 / 免费 / 其他
- **二级标签**：投放下分 cpa、信息流、厂商渠道、学习机、其他；免费下分 厂商渠道、其他、以上
- **枚举详情** → `code/sql/表结构/aws.user_increase_channel_label_day.sql`







### 新媒体口令（业务流程）
- **定义**：新媒体在站外平台（直播/视频/账号等）以发放口令/兑换码的方式引流用户到站内注册；若用户激活口令/兑换兑换码的时间发生在**注册后 24 小时内**，则归为「新媒体口令」带来的用户。
- **相关表**：
  | 表 | 内容 |
  |----|------|
  | `aws.new_media_code_info` | 口令/兑换码主数据（类型、项目名、分组等元信息） |
  | `aws.new_media_new_user_code_detail_day` | 原始激活明细（24h 内激活口令的新用户，首次激活一条） |
  | `tmp.xmt_hejian_user_detail` | 核减后明细（结算/日报口径，需加三个核减筛选条件） |
- **DDL 详见**：`code/sql/表结构/aws.new_media_code_info.sql`、`code/sql/表结构/aws.new_media_new_user_code_detail_day.sql`、`code/sql/表结构/tmp.xmt_hejian_user_detail.sql`

### 新媒体口令核减后拉新量
- **定义**：通过新媒体口令兑换产生的新用户数（排除裂变、投放归因），即投放部门结算口径。
- **数据来源**：`tmp.xmt_hejian_user_detail`（在 `aws.new_media_new_user_code_detail_day` 基础上核减）
- **计算方式**：`COUNT(DISTINCT u_user)`，必加三个核减筛选条件
- **适用表**：`tmp.xmt_hejian_user_detail`
- **必加筛选条件**：
  | 条件 | SQL | 说明 |
  |------|-----|------|
  | 设备去重 | `device_user_nums <= 2` | 去掉同一台设备重复注册 |
  | 排除裂变 | `is_fission_first = 0` | 去掉先激活裂变口令的用户 |
  | 排除投放 | `is_link_deliver = 0` | 去掉投放点击归因的用户 |
- **⚠️ 注意**：不加三个条件的结果是「原始激活量」，不是结算量。→ `code/sql/表结构/tmp.xmt_hejian_user_detail.sql`

---

## 二、体验营

> **数据链路概要**：进线主表 `training_camp.tm_extra`（`yc_user_id`）；数仓渠道/期数 `dw.dim_user_training_camp`；期数配置（开课/招生结束/结营）`training_camp.tm_number`；渠道名称与级别 `training_camp.tm_channel`（`tm_extra.channel` 关联）；过程行为 `dw.fact_user_watch_video_day`（必限 `day`）；用户属性快照 `dws.topic_user_info`（必限 `day`）；转化 `training_camp.crm_order` 等。流程图与落表说明 → `knowledge/business-context.md`「体验营」；JOIN 方式 → `knowledge/table-relations.md`「九、体验营表关联」。**与全站 App 商店投放归因（`thirdparty.traffic` 等）不是同一套表**，跨域分析时勿混用渠道口径。

### 体验营非灰产线索
- **定义**：体验营线索中剔除灰产用户后的集合（**不等同于 A 类线索**）。
- **计算方式**：`training_camp.tm_extra` 上 `risk_user = 0`
- **适用表**：`training_camp.tm_extra`
- **筛选条件**：常与 `team_status = 1`、进线日期范围同用 → `code/sql/表结构/training_camp.tm_extra.sql`

### 体验营结营日期
- **定义**：体验营某一期的**结营日**（经营截止时间，超过后销售一般不再对本期做主动转化），取期数配置表中的 **`operate_at`**。
- **计算方式**：`DATE(training_camp.tm_number.operate_at)`；对应 **`yyyymmdd` 分区键**用于按日宽表取数时为 `CAST(DATE_FORMAT(DATE(operate_at), 'yyyyMMdd') AS INT)`（与 SQL 引擎日期函数一致即可）。`periods` 与线索/维度表期数字段对齐后关联；表内**每期一行**。
- **适用表**：`training_camp.tm_number` → `code/sql/表结构/training_camp.tm_number.sql`；表关联见 `knowledge/table-relations.md` 体验营章节。
- **⚠️ 注意**：与「招生结束日」`end_at` 不同；与「开课日」`str_at` 不同。

### 体验营招生结束日
- **定义**：体验营某一期的**期数结束/招生或投放结束**业务日，用于「截止招生结束」类统计截面（与**结营日**不是同一概念）。
- **计算方式**：`DATE(training_camp.tm_number.end_at)`；对应按日宽表分区键时常写为 `CAST(DATE_FORMAT(DATE(end_at), 'yyyyMMdd') AS INT)`。`periods` 与线索/维度表对齐后关联。
- **适用表**：`training_camp.tm_number`
- **⚠️ 注意**：若取 `dws.topic_user_info.grade` 等「招生结束当日」快照，须 **`topic_user_info.day` = 上式 `yyyymmdd`**，且 `u_user = tm_extra.yc_user_id`。

### 体验营开课日 / 期数起始日
- **定义**：体验营某一期的**开课/期数起始**业务日，常与「开营后至结营前」过程指标（如看视频）时间窗的**左端**对齐。
- **计算方式**：`DATE(training_camp.tm_number.str_at)`；过程表按日筛选时常用 `day >= CAST(DATE_FORMAT(DATE(str_at), 'yyyyMMdd') AS INT)`（与本期 `operate_at` / `end_at` 联合限定窗口）。
- **适用表**：`training_camp.tm_number`
- **⚠️ 注意**：勿与 `operate_at`（结营）、`end_at`（招生结束）混用；具体窗口以需求文档为准。

### 体验营 App 年级（口径选择）
- **定义**：统计「体验营线索在 App 侧的年级」时，存在**线索自填**与**用户宽表按日快照**两类口径，**同一需求内只选一种**。
- **计算方式**：
  | 口径 | 表与字段 | 说明 |
  |------|----------|------|
  | 线索自填 | `training_camp.tm_extra`，`COALESCE(NULLIF(TRIM(stage_app), ''), '未知')` 等 | 进线时填写，非按日快照 |
  | 宽表快照 | `dws.topic_user_info`，`grade` | **必须**限制分区 `day` 与业务统计日一致（如结营日或招生结束日），`u_user = yc_user_id` |
- **适用表**：`training_camp.tm_extra`、`dws.topic_user_info`
- **⚠️ 注意**：年级枚举见 **「三、用户分层」** 中「年级（grade）」；宽表必须先限 `day` 再关联，否则扫描分区过多。

### 体验营 A 类线索
- **定义**：在 `dw.dim_user_training_camp` 中渠道类型为 **A** 的体验营用户/线索维度。
- **计算方式**：`channel_type = 'A'`；维度上常先聚合  
  `(SELECT yc_user_id, channel_type FROM dw.dim_user_training_camp GROUP BY yc_user_id, channel_type)`  
  再与 `training_camp.tm_extra`（如 `t.yc_user_id = d.yc_user_id`）等关联。
- **适用表**：`dw.dim_user_training_camp`（关联 `training_camp.tm_extra`）
- **⚠️ 注意**：与「非灰产」叠加时同时加 `risk_user = 0`；A 类线索见 `code/sql/表结构/dw.dim_user_training_camp.sql`（`channel_type`）

---

## 三、用户分层

> **正价商品定义**：订单金额 >= 39元
> 
> **高净值商品定义**：大会员、组合品

### 字段1：user_pay_status_statistics（统计维度口径）

| 枚举值 | 定义 |
|-------|------|
| `付费` | 购买过任一正价商品用户 |
| `新增` | 注册当天未正价付费用户 |
| `老未` | 注册非当天未正价付费用户 |
| *(空)* | 无用户归属订单 |

### 字段2：user_pay_status_business（业务维度口径）

| 枚举值 | 定义 |
|-------|------|
| `付费用户` | 购买过任一正价商品用户 |
| `新用户` | 注册30天内（≤30天）未正价付费用户 |
| `老用户` | 注册30天以上（>30天）未正价付费用户 |
| *(空)* | 无用户归属订单 |

### 字段3：business_user_pay_status_statistics（商业化统计维度口径）

| 枚举值 | 定义 |
|-------|------|
| `高净值用户` | 购买过任一高净值商品用户（大会员、组合品） |
| `续费用户` | 购买过任一正价商品且非高净值用户 |
| `新增` | 注册当天未正价付费用户 |
| `老未` | 注册非当天未正价付费用户 |
| *(空)* | 无用户归属订单 |

### 字段4：business_user_pay_status_business（商业化业务维度口径）

| 枚举值 | 定义 |
|-------|------|
| `高净值用户` | 购买过任一高净值商品用户（大会员、组合品） |
| `续费用户` | 购买过任一正价商品且非高净值用户 |
| `新用户` | 注册30天内（≤30天）未正价付费用户 |
| `老用户` | 注册30天以上（>30天）未正价付费用户 |
| *(空)* | 无用户归属订单 |

### 字段选择指南

**默认字段：`business_user_pay_status_business`** ⭐

| 场景 | 使用字段 |
|------|---------|
| 默认/无特殊说明 | `business_user_pay_status_business` |
| 需求明确"新用户=当日注册" | `business_user_pay_status_statistics` |
| 不需要区分高净值用户 | `user_pay_status_statistics` 或 `user_pay_status_business` |

**适用表**：`dws.topic_order_detail`、`dws.topic_user_active_detail_day`、`dws.topic_user_info`、`aws.clue_info`

### 用户日宽表（dws.topic_user_info）

- **定义**：用户在统计日当天的属性与行为快照，**每个用户每个自然日一条**记录（用户宽表按日分区）。
- **计算方式**：`FROM dws.topic_user_info WHERE day = ${yyyyMMdd}`（或 `day BETWEEN ...`）；按 `u_user` 统计时先限定分区再 `COUNT(DISTINCT u_user)` 等。
- **表来源**：`dws.topic_user_info`
- **筛选条件**：**必须**限制分区 `day`；关联本表时 JOIN 条件须包含 `day` 或与业务日一致的范围，否则扫描分区过多、数据量极大。分析 C 端用户时通常加 `is_test_user = 0`。
- **核心字段**：`u_user`（用户 ID）、`day`（分区，格式 `yyyymmdd`）
- **⚠️ 注意**：与 `dws.topic_user_active_detail_day` 相比，本表为「宽表」含付费分层、VIP、学习行为等更多字段；枚举定义见 → `code/sql/表结构/dws.topic_user_info.sql`，付费分层四类字段的权威定义仍以本章「字段1～4」为准。

### 电销触达用户
- **定义**：在线索领取表有过记录的用户
- **判断方式**：关联 `aws.clue_info` 表判断是否有记录
- **适用表**：`aws.clue_info`
- **⚠️ 特定场景下的"触达"**：
  分析"某类用户的电销触达情况"时，"触达"通常指：
  - 当前在坐席名下：`事件时间 BETWEEN created_at AND clue_expire_time`
  - 或后续被领取：`created_at > 事件时间`
  - ❌ 历史已过期的线索不算触达
- **⚠️ 注意**：`is_telemarketing_user` 字段口径待验证，暂不推荐使用

### 新增注册用户
- **定义**：当日新注册的用户
- **数据来源**：`aws.user_increase_new_add_day`
- **计算方式**：`SELECT u_user, day, u_from, province, stage_id FROM aws.user_increase_new_add_day WHERE ...`
- **适用表**：`aws.user_increase_new_add_day`
- **必加筛选条件**：
  | 条件 | SQL | 说明 |
  |------|-----|------|
  | 日期范围 | `day BETWEEN ${start} AND ${end}` | 查询必须限制日期 |
  | 移动端 | `u_from IN ('android', 'ios', 'harmony')` | 默认看移动端 |
  | 有效用户 | `user_sk > 0` | 排除无效用户 |
- **核心字段**：`u_user`（用户ID）、`day`（注册日期，int 格式如 20260101）、`u_from`（端口）、`province`（省份）、`stage_id`（学段）

### App 总量 / App 新增注册量
- **定义**：与「新增注册用户」同口径，app 总量 = app 新增注册量
- **数据来源**：`aws.user_increase_new_add_day`
- **计算方式**：见「新增注册用户」，必加 day、u_from、user_sk 筛选
- **适用表**：`aws.user_increase_new_add_day`

### 学段（stage）

| 字段 | 说明 | 适用表 |
|------|------|--------|
| `mid_stage_name` | 中学修正学段 | 订单表、活跃表 |
| `clue_stage` | 线索学段 | 线索表 |

**枚举值**：学龄前、小学、初中、高中、中职、NULL

**⚠️ 用户表无学段字段**：需用 `grade` 年级字段聚合得到学段

### 年级（grade）

| 字段 | 说明 | 适用表 |
|------|------|--------|
| `mid_grade` | 中学修正年级 | 订单表、活跃表 |
| `clue_grade` | 线索年级 | 线索表 |
| `grade` | 用户填写年级 | 用户表 |

**枚举值及学段映射**：

| 学段 | 年级枚举值 |
|------|-----------|
| 学龄前 | 学龄前 |
| 小学 | 一年级、二年级、三年级、四年级、五年级、六年级 |
| 初中 | 七年级、八年级、九年级 |
| 高中 | 高一、高二、高三、十年级 |
| 中职 | 职一、职二、职三 |
| 其他 | 其他、unavailable、NULL |

### 性别（gender）

| 字段 | 说明 | 适用表 |
|------|------|--------|
| `gender` | 用户性别 | 订单表、活跃表、用户表、线索表 |

**枚举值**：

| 值 | 含义 |
|----|------|
| `male` | 男 |
| `female` | 女 |
| `NULL` | 未知 |

### 地理位置

| 字段 | 说明 | 适用表 |
|------|------|--------|
| `province` | 省 | 订单表、活跃表、用户表、线索表 |
| `province_code` | 省code | 订单表、活跃表、用户表、线索表 |
| `city` | 市 | 订单表、活跃表、用户表、线索表 |
| `city_code` | 市code | 订单表、活跃表、用户表、线索表 |
| `area` | 区 | 订单表、活跃表、用户表 |
| `area_code` | 区code | 订单表、活跃表、用户表 |

### 城市线级（city_class）

| 字段 | 说明 | 适用表 |
|------|------|--------|
| `city_class` | 城市分线（一线/二线/三线等） | 订单表、活跃表、线索表 |

### 用户身份/角色

**判断是否家长的核心字段：`real_identity`**

> `real_identity` 是判断用户身份（是否家长）的首选字段。`is_parents` 是由 `real_identity` 派生的布尔标记。

**`is_parents` 与 `real_identity` 的派生关系**：

```sql
IF(real_identity IN ('parents', 'student_parents'), true, false) AS is_parents
```

| real_identity | is_parents | 含义 |
|---------------|------------|------|
| `parents` | true | 纯家长 |
| `student_parents` | true | 学生家长共用 |
| `student` | false | 学生 |
| `teacher` | false | 老师 |

**判断用户身份的标准逻辑**：

```sql
CASE 
  WHEN real_identity = 'student' THEN '纯学生'
  WHEN real_identity = 'student_parents' THEN '学生家长共用'
  WHEN real_identity = 'parents' THEN '纯家长'
  ELSE '其他' 
END AS identity
```

**⚠️ 简化场景**：仅需区分"是否家长"时，直接用 `real_identity IN ('parents', 'student_parents')` 即可

---

**role（注册时选择的角色）**

| 值 | 含义 | 适用表 |
|----|------|--------|
| `student` | 学生 | 订单表、活跃表、用户表 |
| `teacher` | 老师 | 订单表、活跃表、用户表 |
| `parents` | 历史小程序注册用户默认给的家长身份 | 用户表 |
| `youzan` | 有赞 | 订单表、用户表 |

**⚠️ `role` 不能用于判断用户身份（是否家长）**：`role` 仅表示用户注册时选的是"学生"还是"老师"，无法区分是否为家长。判断家长身份必须使用 `real_identity` 字段（仅用户表有），需 JOIN `dw.dim_user`。

**role × real_identity 交叉关系**（2024 年后注册数据验证）：

| role | real_identity | 说明 |
|------|---------------|------|
| `student` | `student` | 纯学生 |
| `student` | `student_parents` | 注册选了学生，实际是家长共用 |
| `student` | `parents` | 注册选了学生，实际是家长 |
| `parents` | `NULL` | 历史小程序注册用户，`real_identity` 未填写 |
| `teacher` | `teacher` | 老师 |

> **关键结论**：`role = 'student'` 中约 30% 实际是家长（`real_identity` 为 `parents` 或 `student_parents`），因此 `role` 无法区分家长。`role = 'parents'` 的用户 `real_identity` 全部为 NULL。

**real_identity（用户真实身份）** ⭐ 判断家长身份首选

| 值 | 含义 | 适用表 |
|----|------|--------|
| `student` | 学生 | 用户表、线索表 |
| `parents` | 家长 | 用户表、线索表 |
| `student_parents` | 学生家长共用 | 用户表 |
| `teacher` | 老师 | 用户表 |
| `NULL` | 未填写（对应 `role = 'parents'` 的历史小程序注册用户） | 用户表 |

**⚠️ 线索表口径差异**：线索表的 `real_identity` 将用户表中含 `parents` 的值（`parents`、`student_parents`）统一标记为 `parents`

**user_identity（用户身份等级）**

| 值 | 含义 | 适用表 |
|----|------|--------|
| `common` | 研究员 | 活跃表、用户表、`dws.topic_user_info` |
| `advanced` | 高级研究员 | 活跃表、用户表、`dws.topic_user_info` |
| `lead` | 首席研究员 | 活跃表、用户表、`dws.topic_user_info` |
| `expLead` | 体验版首席研究员 | 活跃表、用户表、`dws.topic_user_info` |

**is_parents（是否家长）** —— 由 `real_identity` 派生

| 值 | 含义 | 适用表 |
|----|------|--------|
| `true` | 是家长（`real_identity IN ('parents', 'student_parents')`） | 用户表 |
| `false` | 非家长 | 用户表 |

---

## 四、活跃相关

### 活跃数据标准筛选条件

查询活跃表数据时，**默认看C端活跃**，必须加上以下条件：

```sql
  WHERE product_id = '01'
  AND client_os IN ('android', 'ios', 'harmony')
  AND active_user_attribution IN ('中学用户', '小学用户', 'c')
```

| 条件 | 说明 |
|------|------|
| `product_id = '01'` | 主产品 |
| `client_os IN ('android', 'ios', 'harmony')` | 移动端操作系统 |
| `active_user_attribution IN ('中学用户', '小学用户', 'c')` | C端用户归属 |

### 看视频
- **定义**：当日有观看视频行为的用户；表为**用户观看视频明细表**，一条记录为一次观看会话（`watch_id`），按分区 `day` 存储。
- **数据来源**：`dw.fact_user_watch_video_day`
- **计算方式**：
  ```sql
  SELECT day
       , COUNT(DISTINCT u_user) AS `观看视频用户数`
  FROM dw.fact_user_watch_video_day
  WHERE day BETWEEN ${start} AND ${end}
    AND client_os IN ('android', 'ios', 'harmony')
    AND product_id IN ('01', '03')
    AND is_test_user = 0
  GROUP BY day
  ```
- **适用表**：`dw.fact_user_watch_video_day`
- **必加筛选条件**：
  | 条件 | SQL | 说明 |
  |------|-----|------|
  | 日期范围 | `day BETWEEN ${start} AND ${end}` | **查询必须限制分区 day** |
- **默认筛选（与 C 端主 App 分析一致时）**：`client_os IN ('android', 'ios', 'harmony')`、`product_id IN ('01', '03')`、`is_test_user = 0`（详见 `code/sql/表结构/dw.fact_user_watch_video_day.sql`）
- **注意事项**：`day` 为 int 分区（如 20260101）；字段 `product_id` 为 STRING，须写成 `'01'`、`'03'`。表级枚举与统计示例 → `code/sql/表结构/dw.fact_user_watch_video_day.sql`

### 视频完播
- **定义**：单次观看会话内**已完播**（播完），以事实字段 `is_finish` 标识；统计「完播用户」时对用户去重。
- **计算方式**：`is_finish = true`（字段为 BOOLEAN）；按日示例：`COUNT(DISTINCT CASE WHEN is_finish = true THEN u_user END)`（默认筛选同「看视频」）
- **适用表**：`dw.fact_user_watch_video_day`
- **⚠️ 注意**：与「认真观看」（进度 **> 70%**，`finish_type_level > 6`）不同：完播看 `is_finish`，认真观看看进度档位。

### 认真观看视频
- **定义**：观看进度 **> 70%** 视为认真观看（业务口径）。
- **计算方式**：`finish_type_level > 6`（档位 7～10 对应 **[70%, +∞)**，见 `dw.fact_user_watch_video_day` 字段说明）
- **适用表**：`dw.fact_user_watch_video_day`
- **筛选条件**：与「看课」等指标组合时，见下「看课」及 `code/sql/表结构/dw.fact_user_watch_video_day.sql`

### 看课（课程类看视频指标）
- **定义**：统计「看课」类看视频行为时，仅保留课程维度数据。
- **计算方式**：在 `dw.fact_user_watch_video_day` 上增加 `video_type_level1 = 'course'`
- **适用表**：`dw.fact_user_watch_video_day`
- **注意事项**：认真观看口径与看课口径常同时使用：`video_type_level1 = 'course' AND finish_type_level > 6`

---

## 五、订单相关

### 正价订单
- **定义**：实收金额 >= 39 元的订单
- **判断方式**：
  | 表 | 字段 |
  |----|------|
  | 全量订单表 `dws.topic_order_detail` | `order_amount >= 39` |
  | 电销订单表 `aws.crm_order_info` | `amount >= 39` |
- **⚠️ 备选**：`is_normal_price = 1`（两种方式结果略有差异，不推荐）

### 订单量
- **定义**：订单数
- **计算方式**：`COUNT(DISTINCT order_id)`
- **筛选条件**：
  - 看营收：加 `status in  ('支付成功','退款成功')`
  - 看转化率：不限制状态
- **适用表**：`dws.topic_order_detail`、`aws.crm_order_info`
- **详细规范**：
  - 订单表：见 `code/sql/表结构/dw.fact_order_detail.sql` 注释

### 营收金额
- **定义**：订单实收金额汇总
- **计算方式**：
  | 表 | 字段 |
  |----|------|
  | 全量订单表 | `SUM(arrival_amount)` 到账金额  `SUM(sub_amount)` 付费金额
- **筛选条件**：`status in  ('支付成功','退款成功')`
- **详细规范**：
  - 订单表：见 `code/sql/表结构/dw.fact_order_detail.sql` 注释

### 转化用户量
- **定义**：有订单的用户数
- **计算方式**：
  | 表 | 字段 |
  |----|------|
  | 全量订单表 | `COUNT(DISTINCT u_user)` |
  | 电销订单表 | `COUNT(DISTINCT user_id)` |
- **筛选条件**：
  - 看营收：加 `status in  ('支付成功','退款成功')`
  - 看转化率：不限制状态
- **详细规范**：
  - 订单表：见 `code/sql/表结构/dw.fact_order_detail.sql` 注释

---

## 六、商品相关

> **商品2.0体系**：2026-01-01起生效，以下枚举值基于该体系。
> 
> **适用表**：`dws.topic_order_detail`（全量订单表）、`aws.crm_order_info`（电销订单表）

### 商品类目（原始分类）

```
good_kind_name_level_1 → good_kind_name_level_2 → good_kind_name_level_3
```

**good_kind_name_level_1（一级类目）**：

| 枚举值 | 说明 |
|-------|------|
| `方案型商品` | 组合商品，主力营收来源 |
| `零售商品` | 单课程零售 |
| `体验品` | 低价体验产品 |
| `研学商品` | 研学相关 |
| `AI课堂` | AI课程 |
| `其他商品` | 其他 |

**good_kind_name_level_2（二级类目）**：

| 枚举值 | 说明 |
|-------|------|
| `组合商品` | 主力产品（初中品、高中品、小学品等） |
| `同步课` | 零售同步课 |
| `培优课` | 零售培优课 |
| `同步课加培优课` | 组合 |
| `升单后加购` | 学段加购 |
| `学习机加购` | 平板加购 |
| `一年积木块` | 千元品2.0 |
| `拓展课` | 拓展课程 |
| `活动定金` | 定金 |
| `学习机单售` | 学习机单独售卖 |
| `学习方法课` | 学习方法 |
| `学前启蒙` | 学前 |
| `衔接课` | 衔接 |
| `试卷库` | 试卷 |
| `研学商品` | 研学 |
| `体验版组合商品` | 体验版 |
| `AI课堂` | AI |
| `其他体验品` | 体验品 |
| `实物商品` | 周边等 |
| `未分类课程商品` | 未分类 |
| `其他综合类商品` | 其他 |
| `其他辅助学习产品` | 辅助产品 |

**good_kind_name_level_3（三级类目）**：

| 一级 | 二级 | 三级枚举值 |
|-----|-----|-----------|
| 方案型商品 | 组合商品 | `初中品-3年同步课加培优课`、`初中品-2年同步课加培优课`、`初中品-1年同步课加培优课`、`高中品-3年同步课加培优课`、`高中品-2年同步课加培优课`、`高中品-1年同步课加培优课`、`小学品-6年同步课`、`小初品-6年同步课加培优课`、`小初品-5年同步课加培优课`、`小初品-4年同步课加培优课`、`小初品-4年同步课`、`组合商品-4年时长型同步课加到期培优课`、`组合商品-4年时长型同步课`、`组合商品-6年时长型` |
| 方案型商品 | 一年积木块 | `千元品2.0` |
| 方案型商品 | 升单后加购 | `升单后加购-学段加购` |
| 方案型商品 | 学习机加购 | `学习机加购-平板加购` |
| 零售商品 | 同步课 | `同步课-12个月`、`同步课-3个月`、`同步课-智课特殊品` |
| 零售商品 | 同步课加培优课 | `同步课加培优课流量品`、`同步课加培优课` |
| 零售商品 | 培优课 | `培优课-到期型`、`培优课-12个月`、`培优课-3个月` |
| 零售商品 | 拓展课 | `拓展课` |
| 零售商品 | 学习机单售 | `全价购买` |
| 零售商品 | 学习方法课 | `学习方法课`、`AI通识课` |
| 零售商品 | 学前启蒙 | `学前启蒙` |
| 零售商品 | 衔接课 | `衔接课` |
| 零售商品 | 试卷库 | `试卷库` |
| 零售商品 | 未分类课程商品 | `未分类课程商品` |
| 零售商品 | 其他辅助学习产品 | `升学志愿` |
| 体验品 | 活动定金 | `活动定金` |
| 体验品 | 体验版组合商品 | `体验版组合商品` |
| 体验品 | 其他体验品 | `其他体验品` |
| 研学商品 | 研学商品 | `寒暑假营`、`研学商品` |
| AI课堂 | AI课堂 | `软件采购`、`硬件+软件采购`、`硬件采购` |
| 其他商品 | 实物商品 | `周边` |
| 其他商品 | 其他综合类商品 | `单后赠品` |

### 策略组修正类目（业务视角）

```
business_good_kind_name_level_1 → business_good_kind_name_level_2 → business_good_kind_name_level_3
```

> **用途**：策略组基于业务视角对商品重新分类，便于营收分析和策略制定。

**business_good_kind_name_level_1（策略组一级）**：

| 枚举值 | 说明 |
|-------|------|
| `组合品` | 方案型主力产品 |
| `零售商品` | 单课程零售 |
| `续购` | 加购类（学段加购、学习机加购） |
| `其他` | 定金、研学、体验品等 |

**business_good_kind_name_level_2（策略组二级）**：

| 枚举值 | 说明 |
|-------|------|
| `单学段商品` | 初中品、高中品、小学品 |
| `多学段商品` | 小初品、小初同步品 |
| `零售商品` | 同步课、培优课、拓展课等 |
| `续购` | 学段加购、学习机加购 |
| `其他` | 定金、研学、体验品 |

**business_good_kind_name_level_3（策略组三级）**：

| 枚举值 | 说明 |
|-------|------|
| `初中品` | 初中组合商品 |
| `高中品` | 高中组合商品 |
| `小学品` | 小学组合商品 |
| `小初品` | 小初跨学段商品 |
| `小初同步品` | 小初同步组合 |
| `同步课` | 零售同步课 |
| `培优课` | 零售培优课 |
| `拓展课` | 零售拓展课 |
| `学段加购` | 升单后学段加购 |
| `学习机加购` | 平板加购 |
| `定金` | 活动定金 |
| `研学` | 研学商品 |
| `体验品` | 体验类商品 |
| `其他` | 其他 |

### 商品时长（fix_good_year）

| 类型 | 枚举值示例 |
|------|-----------|
| 年型 | `1年`、`2年`、`3年`、`4年`、`5年`、`6年`、`12年` |
| 天型 | `0天`、`1天`、`7天`、`30天`、`31天`、`93天` |
| 到期型 | `2026年01月到期`、`2027年06月到期`、`2028年06月到期` |
| 特殊 | `小学6年品` |

### 商品分类标签（course_timing_kind）

| 枚举值 | 说明 |
|-------|------|
| `到期型` | 固定到期日期（如2027年6月到期） |
| `时长型` | 从购买日起算时长（如3年） |
| `NULL` | 未分类（零售、体验品等） |

### 商品分组标签（course_group_kind）

| 枚举值 | 说明 |
|-------|------|
| `私域主推品` | 电销主推的组合商品 |
| `公域主推品` | 新媒体/其他渠道主推 |
| `NULL` | 未分类（零售、加购等） |

### 策略类型（strategy_type）

> 2026-01-01上线，之前按规则清洗。

| 枚举值（部分） | 说明 |
|--------------|------|
| `多孩策略` | 多孩家庭优惠 |
| `高中囤课策略` | 高中囤课 |
| `学习机加购策略` | 学习机加购 |
| `历史大会员续购策略` | 历史大会员续购 |
| 其他 | 待补充 |

### 营收分布统计口径（业务修正）

> **重要**：业务看营收分布时，使用以下修正逻辑，而非原始字段。

#### ⚠️ 关键口径差异：组合品与策略续购

| 口径 | 组合品范围 | 说明 |
|-----|-----------|------|
| **原始口径** | 包含策略续购订单 | `business_good_kind_name_level_1 = '组合品'` |
| **常规口径（默认）** | 剔除策略续购订单 | 策略续购订单单独归为"续购" |

**默认使用常规口径**：日常说的"组合品"默认剔除策略续购订单。

**取数时如有疑问**：当需求涉及"组合品营收"且口径不明确时，反问确认：
- "组合品是否包含策略续购订单？"

**business_good_kind_name_level_1_modify（一级修正）**：

```sql
CASE 
    WHEN business_good_kind_name_level_1 = '积木块' THEN '零售商品' 
    ELSE business_good_kind_name_level_1 
END AS business_good_kind_name_level_1_modify
```

| 原始值 | 修正后 |
|-------|-------|
| `积木块` | `零售商品` |
| 其他 | 保持不变 |

**business_good_kind_name_level_2_modify（二级修正）**：

```sql
CASE 
    WHEN course_group_kind = '公域主推品' THEN '公域主推品' 
    WHEN string(strategy_type) REGEXP '多孩策略|高中囤课策略|学习机加购策略|历史大会员续购策略' THEN '续购'
    ELSE business_good_kind_name_level_2 
END AS business_good_kind_name_level_2_modify
```

| 条件 | 修正后 |
|-----|-------|
| `course_group_kind = '公域主推品'` | `公域主推品` |
| `strategy_type` 包含续购类策略 | `续购` |
| 其他 | 保持原 `business_good_kind_name_level_2` |

**business_good_kind_name_level_3_modify（三级修正）**：

```sql
CASE 
    WHEN string(strategy_type) REGEXP '多孩策略' THEN '多孩策略'
    WHEN string(strategy_type) REGEXP '高中囤课策略' THEN '高中屯课策略'
    WHEN string(strategy_type) REGEXP '历史大会员续购策略' THEN '历史大会员续购'
    WHEN business_good_kind_name_level_3 = '学习机加购' 
         OR string(strategy_type) REGEXP '学习机加购策略' THEN '学习机加购策略'
    WHEN business_good_kind_name_level_2 = '其他' THEN '其他'
    ELSE business_good_kind_name_level_3 
END AS business_good_kind_name_level_3_modify
```

| 条件 | 修正后 |
|-----|-------|
| `strategy_type` 包含 `多孩策略` | `多孩策略` |
| `strategy_type` 包含 `高中囤课策略` | `高中屯课策略` |
| `strategy_type` 包含 `历史大会员续购策略` | `历史大会员续购` |
| `business_good_kind_name_level_3 = '学习机加购'` 或 `strategy_type` 包含 `学习机加购策略` | `学习机加购策略` |
| `business_good_kind_name_level_2 = '其他'` | `其他` |
| 其他 | 保持原 `business_good_kind_name_level_3` |

### 判断用户是否购买过某商品

- **强制使用表**：`dws.topic_order_detail`（全量订单表）
- **原因**：用户可能通过多渠道购买，仅查单一业务表会遗漏
- **示例**：
  ```sql
  -- 判断是否购买过组合商品
  SELECT u_user
  FROM dws.topic_order_detail
  WHERE status = '支付成功'
    AND good_kind_name_level_2 = '组合商品'
  GROUP BY u_user
  ```

---

## 七、业务归属与营收查询

### 营收查询场景选表指南

| 查询场景 | 使用表 | 关键字段 | 说明 |
|---------|-------|---------|------|
| **电销营收** | `aws.crm_order_info` | `amount` | 电销业务专用表 |
| **各业务GMV** | `dws.topic_order_detail` | `business_gmv_attribution` | 区分电销/新媒体等业务 |
| **服务期营收** | `dws.topic_order_detail` | `team_names` | 按服务期归属区分 |
| **判断用户购买历史** | `dws.topic_order_detail` | - | 全量订单，避免遗漏 |

### 业务GMV归属
- **字段**：`business_gmv_attribution`
- **用途**：区分订单归属哪个业务（电销、新媒体等）
- **适用表**：`dws.topic_order_detail`
- **⚠️ 注意**：此字段与服务期无直接关系

### 服务期营收归属
- **字段**：`team_names`
- **用途**：按服务期归属区分营收
- **适用表**：`dws.topic_order_detail`

---

## 八、通用业务规则（跨表 SQL）

> 以下为写 SQL 时跨表适用的硬性规则；**表级必加条件以各表 `code/sql/表结构/*.sql` 内【常用筛选条件】为准**。

### R01：手机号解码（`dw.dim_user.phone`）

- **规则**：`phone` 可能为 base64，需解码后再匹配或展示。
- **示例**：`if(phone rlike '^\\d+$', phone, cast(unbase64(phone) AS string))`

### R02：判断用户购买历史必须用全量订单表

- **规则**：判断用户是否买过某商品须用 `dws.topic_order_detail`，不能单用 `aws.crm_order_info` 等单业务表。
- **示例**：`FROM dws.topic_order_detail WHERE status = '支付成功' AND good_kind_name_level_2 = 'xxx'`

### R03：正价订单判断

- **规则**：正价订单 = `order_amount >= 39`（全量表）或 `amount >= 39`（电销表）；不依赖 `is_normal_price`。
- **违反后果**：`is_normal_price` 与金额判断可能不一致。

### R04：组织架构名称需 JOIN 维表

- **适用范围**：`aws.clue_info`、`aws.crm_order_info` 等无中文职场/团组名字段时。
- **规则**：需 JOIN 组织维表取名称。

### R05：线索来源展示名

- **适用范围**：`aws.clue_info.clue_source`
- **规则**：枚举值展示中文名常需 JOIN `tmp.wuhan_clue_soure_name`。

### R06：领取转化率（日报口径）

- **规则**：先按日报粒度聚合再汇总，避免跨日重复计算领取。

### R07：user_id / u_user 惯例

- **规则**：`aws` 系多用 `user_id`，`dws`/`dw` 系多用 `u_user`，JOIN 时注意字段名对应。

### R08：判断家长身份

- **规则**：用 `real_identity IN ('parents', 'student_parents')`，**不要**用 `role` 判断家长（易误判）。

---

## 九、更新记录

| 日期 | 内容 |
|------|------|
| 2026-02-06 | 活跃筛选条件新增 `active_user_attribution`，默认 C 端活跃 |
| 2026-03-12 | 新增「看视频」「新增注册用户」口径 |
| 2026-03-13 | 新增「投放与增长」：App 总量、投放量、裂变/新媒体口令拉新量 |
| 2026-03-16 | 新增自然量定义（总量 - 投放 - 口令 - 裂变） |
| 2026-03-24 | 体验营：新增「非灰产线索」「A 类线索」术语；看视频：补充每日看视频表说明、「认真观看」「看课」口径 |
| 2026-03-25 | 合并旧版索引：R01–R08 入「通用业务规则」；表级筛选/枚举迁入 DDL 文件 |
| 2026-03-26 | 看视频：`fact_user_watch_video_day` DDL 同步；完播口径 `is_finish = true` |
| 2026-03-27 | 新增「投放归因」「渠道标签」口径；DDL 文件名统一加 schema 前缀；引用路径同步 |
| 2026-03-31 | 投放归因：补充 `dw.fact_traffic` DDL 与选表差异说明 |
| 2026-04-01 | 体验营：新增结营日/招生结束日/开课日/App 年级口径；用户分层补充 `dws.topic_user_info`；新增「用户日宽表」术语 |
| 2026-04-09 | 投放：新增「少回传」术语、更新选表指南（含 `thirdparty_traffic` 实时表）；新增「新媒体口令业务流程」三张表说明 |