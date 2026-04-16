# 【投放】业务背景

> 维护人：**欣雨**。

> **使用方式**：先理解业务如何运转、数据如何产生，再选表写 SQL。**指标定义、计算公式、口径差异以 [`glossary.md`](glossary.md) 为准**；**表怎么 JOIN 见 [`table-relations.md`](table-relations.md)**；**写法模板见 [`sql-patterns.md`](sql-patterns.md)**。本文件**不写指标公式**，只描述链路与落表。

---

## 与知识库其他模块的关系

| 内容类型 | 存放位置 |
|---------|----------|
| 指标是什么、怎么算、用哪张表 | `glossary.md` |
| 表与表 JOIN 用哪个键 | `table-relations.md` |
| 标准 SQL 模板、写法约束 | `sql-patterns.md` |
| 单表字段、枚举、必加 WHERE | `code/sql/表结构/*.sql`（DDL 即文档） |
| **业务流程、数据从哪来、关键环节落哪张表** | **本文件** |

跨表通用规则（如 R01–R08）若已迁入 `glossary.md` **「八、通用业务规则（跨表 SQL）」**，以词典为准。

---

## 一、App 用户与行为（C 端主链路）

面向「谁在什么时候用了产品、是否付费」类分析。用户主键在数仓侧多为 **`u_user`**（字符串）。

```
[端上/App 行为] → 埋点/服务端日志 → 数仓明细与汇总
        │
        ├→ 新增注册：按日落表 → aws.user_increase_new_add_day（必限 day、端口等，见 glossary）
        │
        ├→ 日活/行为：按日 → dws.topic_user_active_detail_day（注意分区字段名 day 等，见 DDL）
        │
        ├→ 用户属性/分层快照（按日宽表）→ dws.topic_user_info（分区 day=yyyymmdd，必限分区）
        │
        └→ 订单/营收：全量订单宽表等 → dws.topic_order_detail、dw.fact_order_detail（见 glossary 选表）
```

**关联习惯**：`u_user` 串联用户维 `dw.dim_user`、活跃表、订单表；线索/电销侧部分表用 `user_id`，JOIN 时注意与 `u_user` 对齐（见 `table-relations.md`）。

---

## 二、App 投放与归因（拉新）

面向「用户在哪个媒体/计划点了广告、是否激活、注册归因到哪条投放」类分析。详细 **JOIN 关系、表选型（thirdparty vs fact_traffic vs 点击冷数据）** 见 [`table-relations.md`](table-relations.md) **「二、投放归因表关联」**；字段与分区以各表 DDL 为准。

### 2.1 链路概览

```
[各媒体/商店投放] → 用户点击广告（带渠道参数、设备标识如 oaid）
        │
        ├→ 点击/归因主链（T+1 常用）→ thirdparty.traffic（每点击一条，可关联激活/注册 userid）
        │       │
        │       ├→ 分媒体明细：vivo / oppo / 小米 等 → thirdparty.*_attribution（按 traffic_id 对齐）
        │       │
        │       ├→ 注册用户：traffic.userid → dw.dim_user.u_user（同一人多次点击取业务口径去重，见 glossary）
        │       │
        │       └→ [少回传] 注册时写入 → thirdparty.register_callback_record（每注册用户一条，含 sample_hit / callback_ratio）
        │                                   ↑ 4.8 上线；旧接口约 40 条/天漏写（已正常回传）
        │
        ├→ 当日激活/注册（实时/准实时）→ thirdparty.traffic_hour（1小时延迟，含激活+注册）
        │
        ├→ 当日注册（实时，无延迟）→ default_catalog.ods.thirdparty_traffic（仅注册，StarRocks，oaid 为空）
        │                              ↑ 主要用于实时核对媒体注册回传 / 测试新渠道
        │
        ├→ 全量点击（含未激活）冷数据 → traffic_investment.traffic（与主表存数策略不同，勿混用口径）
        │
        ├→ 按日分区的点击明细 → dw.fact_traffic（需按 day 等条件；与 thirdparty.traffic 是两张表）
        │
        └→ 注册用户的渠道标签（投放/自然等拆分）→ aws.user_increase_channel_label_day（u_user + day，见 glossary/DDL）
```

### 2.1.1 traffic 下游与各媒体明细表（链路关系）

主表 **`thirdparty.traffic`** 一行一次点击/归因记录，主键 **`id`**。各媒体「广告计划 / 创意 / 广告位」等明细在 **分渠道表** 中，通过 **`traffic_id` 回指主表**（即 **`{媒体}_attribution.traffic_id = traffic.id`**）。`dw.fact_traffic` 与 `thirdparty.traffic` 为不同表，但 **`fact_traffic.id` 与各明细表的 `traffic_id` 对齐方式相同**（见 `table-relations.md` 对照表）。

```
thirdparty.traffic                    thirdparty 分媒体明细（均需 traffic_id 对齐）
        id  ◄────────────────────────  vivo_attribution.traffic_id   （计划/组/广告位等）
         │  ◄────────────────────────  oppo_attribution.traffic_id
         │  ◄────────────────────────  xiaomixin_attribution.traffic_id（小米创意/计划等）
         │
         │  同构对齐（按 day 分区查 fact 时）
         ▼
   dw.fact_traffic.id  ◄────────────  同上：fact_traffic.id = *_attribution.traffic_id
```

| 下游表 | 与 traffic 的关联 | 典型用途 |
|--------|-------------------|----------|
| `thirdparty.vivo_attribution` | `traffic_id = traffic.id` | vivo 计划、组、广告位等维度下钻 |
| `thirdparty.oppo_attribution` | `traffic_id = traffic.id` | oppo 广告位等；历史缺口见 `table-relations.md` |
| `thirdparty.xiaomixin_attribution` | `traffic_id = traffic.id` | 小米创意/计划等；数据起始时间见 `table-relations.md` |
| `dw.fact_traffic` | 明细行 `id` 与各 `*_attribution.traffic_id` 同义 | 按 **day** 分区做点击明细；与 `thirdparty.traffic` 勿混为一张表 |

**例外（无需关联分媒体明细表）**：**华为** 等场景下，当 `source = 'huawei'` 时，**`traffic.channel` 已能标识广告位**，一般不再 JOIN `*_attribution`（与 `table-relations.md`「注意事项」一致）。**vivo / oppo** 等若需拆到媒体侧计划维度，则需按 `source` 命中后关联对应 attribution 表。

### 2.2 与「站内行为」的衔接

- **投放侧**：解决「从哪条广告来的」；主键多为 **点击粒度** + **`userid`（注册后）** / **设备标识（对齐媒体）**。
- **站内行为**：注册落地后，仍用 **`u_user`** 关联 `topic_user_active_detail_day`、`topic_user_info`、订单表等（见上一节）。
- **与体验营投放**：体验营线索/渠道名称另有 **`training_camp.tm_channel`**、**`dim_user_training_camp`** 等，与 **App 商店投放归因表不是同一套表**；跨域分析需明确是「全站拉新归因」还是「体验营进线渠道」。

### 2.3 少回传机制

4.8 上线。运营在后台按 `channel` 配置回传比例（`callback_ratio`），注册请求到达服务端时：
- **命中**（`sample_hit = 1`）：正常回传给媒体，计入媒体侧的注册量；
- **未命中**（`sample_hit = 0`）：不回传，媒体侧不记录该注册；
- **IS NULL**：走旧接口的注册，未写入本表但已正常回传（存量约 40 条/天，修复中）。

统计「少回传后实际回传用户数」时，`sample_hit = 1 OR sample_hit IS NULL` 均归入「回传」口径。详见 `code/sql/表结构/thirdparty.register_callback_record.sql`，口径定义见 `glossary.md`「少回传」。

### 2.4 写 SQL 时注意点（链路层面）

- **先定场景**：要「标准归因、可关联用户」多用 **`thirdparty.traffic`**；要「仅注册、实时无延迟」用 **`default_catalog.ods.thirdparty_traffic`**（StarRocks，语法有差异）；要「点击全貌、含未激活」需另看清 **`traffic_investment.traffic`** 与主表的时间切分说明（见 `table-relations.md`）。
- **分区**：`dw.fact_traffic` 等 **必须带 `day`（或等价区间）**，避免扫全表。
- **与媒体对数**：常用 **`oaid` + 渠道 + 时间** 与媒体后台核对；具体表字段见 DDL。

---

## 二点五、新媒体口令引流注册

面向「站外内容平台（直播/视频/账号等）通过口令/兑换码带来的新用户」类分析。与 App 商店广告投放归因（`thirdparty.traffic` 等）**是独立的两套拉新链路**，不要混用渠道口径。

### 链路概览

```
[站外平台发放口令/兑换码] → 用户在站内注册 + 24h 内激活/兑换
        │
        ├→ 原始激活明细（未核减）→ aws.new_media_new_user_code_detail_day（一口令一用户一条，分区 day）
        │       │
        │       └→ 口令元信息（类型/项目名/分组）→ aws.new_media_code_info（通过 code 关联）
        │
        └→ 核减后明细（结算/日报口径）→ tmp.xmt_hejian_user_detail
                    核减逻辑（三项，缺一不可）：
                    1. 同一设备重复注册（device_user_nums > 2）
                    2. 先激活了裂变口令（is_fission_first = 1）
                    3. 投放点击归因渠道注册（is_link_deliver = 1）
```

### 写 SQL 时注意点

- **结算口径**：必须同时加三个核减条件，见 `code/sql/表结构/tmp.xmt_hejian_user_detail.sql`【常用筛选条件】。
- **未核减 vs 核减**：`new_media_new_user_code_detail_day` 是全量（量更大），`xmt_hejian_user_detail` 才是日报结算口径，两者数量不同。
- **与裂变、投放的交叉**：核减条件本身依赖对裂变表和投放归因表的判断，已沉淀到 `xmt_hejian_user_detail` 字段中，直接用字段过滤即可，不需重新关联源表。

---

## 三、体验营（Training Camp）

面向「体验营投放 → 进线 → 营内过程 → 结营/转化」类分析。体验营侧用户主键 **`yc_user_id`** 与全站 `u_user` 的对应关系以 **`dw.dim_user_training_camp`** 及 DDL 说明为准。

### 3.1 业务链路（概念）

```
[投放/渠道] ──→ 用户点击短链 / 落地页 ──→ 进线成为线索
        │               │
        │               ├ 落地页→报名→验证码→付费→激活全漏斗（埋点）→ events.frontend_event_orc
        │               │     enter_DyTyyApplyNow_Page（进入落地页）
        │               │     click_DyTyyApplyNow_Button（立即报名）
        │               │     click_DyTyyGetVerification_Button（获取验证码）
        │               │     click_DyTyyGetVerification_ReportButton（提交验证码）
        │               │     enter_DyTyyOrderConfirm_Page（进入付费详情页）
        │               │     click_DyTyyConfirmPay_Button（确认支付）
        │               │     enter_TyyActivateCourse_Page（进入激活课程页）
        │               │     click_TyyActivateCourseSubmit_Button（点击提交激活）
        │               │     模板 → sql-patterns.md T-TYY-03（完整漏斗）/ T-TYY-01（仅激活课程页进入/点击）
        │               │
        │               └ 挽留弹窗行为（埋点）→ events.frontend_event_orc
        │                     enter_TyyRetainPopup_Page（曝光）
        │                     click_TyyRetainPopup_Button（点击领取/关闭）
        │                     模板 → sql-patterns.md T-TYY-02
        │
        ├ 业务库线索主表：training_camp.tm_extra（一用户一条进线维度，含 team_status、risk_user、stage_app 等）
        │
        ├ 渠道名称/级别：training_camp.tm_channel（通过 tm_extra.channel 关联，取 channel_name、channel_type、channel_grade）
        │
        ├ 数仓维度/渠道：dw.dim_user_training_camp（与 tm_extra 按 yc_user_id 关联，含 channel_type='A'、periods 等）
        │
        ├ 期数与关键日期：training_camp.tm_number（每期一行：str_at、operate_at、end_at 等，用于开课、结营、招生结束日）
        │
        ├ 过程行为：dw.fact_user_watch_video_day（按日分区 day，学习时长等；分析必限 day 区间）
        │
        ├ 用户属性快照（年级等）：dws.topic_user_info（按日分区；关联 u_user + 业务日 day）
        │
        └ 转化/订单：training_camp.crm_order（转化时间条件 paid_time >= tm_extra.created_at；金额字段单位为分，/100 得元）
```

### 3.2 与表关联文档的对应

- **期数、结营日、招生结束日**：`tm_number` 与 `periods` 对齐；结营/招生结束等口径见 `glossary.md` **「二、体验营」** 中对应术语。
- **渠道名称与级别**：`tm_channel` 与线索表 `channel` 对齐；见 `code/sql/表结构/training_camp.tm_channel.sql`。
- **A 类 / 渠道类型**：`dim_user_training_camp.channel_type` 等，见 **「二、体验营」** 中「体验营 A 类线索」及 DDL。
- **非灰产**：`tm_extra.risk_user = 0` 等，见 **「二、体验营」** 中「体验营非灰产线索」。
- **短链获客、弹窗、完整漏斗**：均走 `events.frontend_event_orc` 埋点，模板见 `sql-patterns.md` T-TYY-01（短链）、T-TYY-02（弹窗）、T-TYY-03（完整漏斗）。

### 3.3 写 SQL 时的常见约束（链路层面）

- **分区表**：`topic_user_info`、`fact_user_watch_video_day` 等 **必须先限 `day`（或业务可推导的 min/max 区间）**，否则扫描量与任务文件数会放大；具体写法见 `sql-patterns.md` 与项目内临时需求 SQL 注释。
- **年级**：若用宽表 `grade`，需与统计日 `day` 与 JOIN 条件一致；若用 `tm_extra.stage_app`，口径不同，勿混用（以需求说明为准）。
- **订单金额**：`training_camp.crm_order` 金额字段（`amount`、`order_amount`）单位为**分**，展示元时需 `/100`。
- **转化时间约束**：分析线索的付费转化时，需加 `crm_order.paid_time >= tm_extra.created_at`，确保转化行为发生在进线之后。
- **埋点统计**：短链与弹窗埋点均来自 `events.frontend_event_orc`，按 `day`（int 或字符串格式）分区，注意各模板的日期格式转换写法（见 sql-patterns.md T-TYY-01/02/03）。

---

## 四、线索与电销（Leads → 坐席 → 订单）

面向「线索从哪来、是否被领取、是否外呼、是否成单」类分析。

```
[各渠道线索进入池] → aws.clue_info（领取/分配记录，一条领取一条）
        │
        ├→ 在库/服务期/触达等口径 → 依赖领取时间、过期时间及统计日关系（见 glossary「电销触达用户」及 `code/sql/表结构/aws.clue_info.sql`）
        │
        ├→ 外呼 → dw.fact_call_history（一次外呼一条，user_id 关联）
        │
        └→ 电销订单 → aws.crm_order_info 等（与全量订单表字段差异见 glossary）
```

**注意**：线索表 `user_id` 与订单宽表 `u_user` 对照使用；「触达」在特定分析中有时间窗定义，不能简单等同「有过领取记录」（见 glossary「电销触达用户」）。

---

## 五、数据产生与存储的共性（便于理解「为什么必加条件」）

| 维度 | 说明 |
|------|------|
| 按日分区 | 多表以 `day`（int，yyyymmdd）或 `dt`（date）分区，**分区字段必须在查询中显式限定**，否则全表/多分区扫描。 |
| 用户 ID 多套 | 全站 `u_user`、线索 `user_id`、体验营 `yc_user_id` 等，**不能混用**，关联方式见 `table-relations.md`。 |
| 快照与累计 | 宽表多为「某日快照」；订单/行为可累加；**统计日选错会导致口径不一致**。 |

---

## 六、维护说明

- **新增一条业务线**（新投放形态、新训练营）：在本文件增加一小节流程图 + 落表，并在 `table-relations.md` / 对应 DDL 补关联与字段。
- **只改指标口径**：改 `glossary.md`，不必在本文件重复公式。
- **只改表结构/枚举**：改 `code/sql/表结构/*.sql`。

---

## 更新记录

| 日期 | 内容 |
|------|------|
| 2026-03-25 | 随 SPEC 改版新建文件，占位待补充业务流程 |
| 2026-03-25 | 说明与 glossary / DDL 迁移关系 |
| 2026-04-01 | 补充 App 主链路、线索电销、体验营链路与表；数据共性、维护说明 |
| 2026-04-01 | 新增「App 投放与归因」：traffic 主链、分媒体明细、渠道标签日表及与体验营渠道区别 |
| 2026-04-01 | 补充 2.1.1：traffic.id / fact_traffic.id 与各 `*_attribution.traffic_id`、华为例外 |
| 2026-04-09 | 新增/更新：投放归因补充少回传分支（`register_callback_record`）与注册实时表（`thirdparty_traffic`）及 2.3 少回传机制；新增「二点五、新媒体口令引流注册」；体验营从「四」前移至「三」并补充完整漏斗埋点（T-TYY-03）、渠道维表 tm_channel、订单金额单位 |
