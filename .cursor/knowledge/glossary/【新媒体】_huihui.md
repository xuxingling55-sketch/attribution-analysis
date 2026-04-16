# 通用口径

> 以下为跨业务通用的数据处理规则，用研和新媒体均适用。

### 用户ID关联方式

用研需求中，用户筛选支持通过 `u_user`、`phone`、`onion_id` 任意一个或多个匹配。

### 手机号解密

`dw.dim_user`、`dws.topic_order_detail` 等表中 `phone` 字段为加密存储，任何涉及手机号的场景需先解密：`IF(phone IS NULL, phone, IF(phone RLIKE '^\\d+$', phone, CAST(unbase64(phone) AS STRING)))`

### 学段划分

按 `grade` 字段归类学段：
- 学龄前：`grade IN ('学龄前')`
- 小学：`grade IN ('一年级','二年级','三年级','四年级','五年级','六年级')`
- 初中：`grade IN ('七年级','八年级','九年级')`
- 高中：`grade IN ('高一','高二','高三')`
- 职中：`grade IN ('职一','职二','职三')`
- 其他：以上均不满足时归为其他

### 注册身份标签（`real_identity`）

`dw.dim_user` 表中 `real_identity` 字段标识用户注册时选择的身份：
- `student_parents`：家长代学生注册
- `parents`：家长注册
- `student`：学生注册

---

# 业务术语词典（用研）

> 本词典定义用研取数中的业务术语口径，确保上传用户ID/手机号/洋葱id后匹配字段一致。

## 一、用户注册相关

### 注册用户数

- **定义**：新增加的注册用户数
- **计算方式**：`COUNT(DISTINCT u_user)`
- **表来源**：`dw.dim_user`
- **筛选条件**：统计时需排除 `regist_entrance_id is not null AND activate_date is not null` 的数据


### 家长注册用户数

- **定义**：注册时选择的标签是家长注册或家长代学生注册用户数
- **计算方式**：`COUNT(DISTINCT CASE WHEN real_identity IN ('student_parents','parents') THEN u_user END)`
- **表来源**：`dw.dim_user`
- **筛选条件**：沿用注册用户数的排除条件

### 学生注册用户数

- **定义**： 注册时选择的标签时学生注册用户数
- **计算方式**：`COUNT(DISTINCT CASE WHEN real_identity IN ('student') THEN u_user END)`
- **表来源**：`dw.dim_user`
- **筛选条件**：沿用注册用户数的排除条件

---

## 二、看课相关

### 看视频时长（秒）

- **定义**：用户观看视频时长（秒）
- **计算方式**：`SUM(learn_duration)`
- **表来源**：`dw.fact_user_watch_video_day`
- **筛选条件**：
  - `day` 按指定时间范围过滤
  - 用户筛选：支持通过 `u_user`、`phone`、`onion_id` 任意一个或多个匹配
  - 按学科/学段/版本拆分时，需关联 `dw.dim_term`（`topic_sk = term_sk`），可按 `subject_name`、`semester_name`、`publisher_id`、`publisher_name` 筛选
- **⚠️ 注意**：原始单位为秒；如需分钟需 `/60`，如需小时需 `/3600`

### 看课天数

- **定义**：用户观看课程天数
- **计算方式**：`COUNT(DISTINCT date_sk)`
- **表来源**：`dw.fact_user_watch_video_day`
- **筛选条件**：
  - `day` 按指定时间范围过滤
  - 用户筛选：支持通过 `u_user`、`phone`、`onion_id` 任意一个或多个匹配
  - 按学科/学段/版本拆分时，需关联 `dw.dim_term`（`topic_sk = term_sk`），可按 `subject_name`、`semester_name`、`publisher_id`、`publisher_name` 筛选
- **⚠️ 注意**：按 `date_sk` 去重，一天内多次看课只计1天

### 看课次数

- **定义**：用户观看视频次数
- **计算方式**：`COUNT(DISTINCT watch_id)`
- **表来源**：`dw.fact_user_watch_video_day`
- **筛选条件**：
  - `day` 按指定时间范围过滤
  - 用户筛选：支持通过 `u_user`、`phone`、`onion_id` 任意一个或多个匹配
  - 按学科/学段/版本拆分时，需关联 `dw.dim_term`（`topic_sk = term_sk`），可按 `subject_name`、`semester_name`、`publisher_id`、`publisher_name` 筛选

### 看课完播次数

- **定义**：用户完整看完视频的次数
- **计算方式**：`COUNT(CASE WHEN is_finish = true THEN watch_id END)`
- **表来源**：`dw.fact_user_watch_video_day`
- **筛选条件**：
  - `day` 按指定时间范围过滤
  - 用户筛选：支持通过 `u_user`、`phone`、`onion_id` 任意一个或多个匹配
  - 按学科/学段/版本拆分时，需关联 `dw.dim_term`（`topic_sk = term_sk`），可按 `subject_name`、`semester_name`、`publisher_id`、`publisher_name` 筛选
- **⚠️ 注意**：完播判断依据 `is_finish = true`

### 认真看课次数

- **定义**：用户认真看课（达到一定完成度）的次数
- **计算方式**：`COUNT(CASE WHEN finish_type_level > 6 THEN watch_id END)`
- **表来源**：`dw.fact_user_watch_video_day`
- **筛选条件**：
  - `day` 按指定时间范围过滤
  - 用户筛选：支持通过 `u_user`、`phone`、`onion_id` 任意一个或多个匹配
  - 按学科/学段/版本拆分时，需关联 `dw.dim_term`（`topic_sk = term_sk`），可按 `subject_name`、`semester_name`、`publisher_id`、`publisher_name` 筛选
- **⚠️ 注意**：认真看课阈值为 `finish_type_level > 6`

---

## 三、练习做题相关

### 做题次数

- **定义**：用户累计做题数量
- **计算方式**：`SUM(problem_cnt)`
- **表来源**：`dw.fact_user_exercise_day`
- **筛选条件**：
  - `day` 按指定时间范围过滤
  - 用户筛选：支持通过 `u_user`、`phone`、`onion_id` 任意一个或多个匹配
- **⚠️ 注意**：`problem_cnt` 是单次练习的题目数，SUM 后为累计总题数

---

## 四、活跃相关

### 学习活跃次数

- **定义**：用户在指定时间范围内的学习活跃记录次数
- **计算方式**：`COUNT(topic_id)`
- **表来源**：`dw.fact_user_learn_active_detail_day`
- **筛选条件**：
  - `day` 按指定时间范围过滤
  - 用户筛选：支持通过 `u_user`、`phone`、`onion_id` 任意一个或多个匹配

### 使用学习机用户数

- **定义**：使用过学习机的用户数（学习机=洋葱星球）
- **计算方式**：`COUNT(distinct  CASE WHEN is_use_ycpad = '1' THEN u_user END)`
- **表来源**：`aws.mid_active_user_os_day`
- **筛选条件**：
  - `day` 按指定时间范围过滤
  - 用户筛选：支持通过 `u_user`、`phone`、`onion_id` 任意一个或多个匹配

---

## 五、订单消费相关

### 历史消费金额

- **定义**：用户历史累计消费金额（实付减退款）
- **计算方式**：`SUM(sub_amount)`
- **表来源**：`dws.topic_order_detail`
- **筛选条件**：
  - `status = '支付成功'`
  - `paid_time` 按指定时间范围过滤（不传则统计全量历史）
  - 用户筛选：支持通过 `u_user`、`phone`、`onion_id` 任意一个或多个匹配
  - 按购课类型拆分时，可按 `business_good_kind_name_level_1` 筛选（组合品/续购/积木块/零售商品）
  - 按学段拆分时，可按 `grade` 筛选（如小学：`grade IN ('一年级','二年级','三年级','四年级','五年级','六年级')`）
  - 按新媒体渠道筛选时，可加 `sell_from regexp 'xinmeitishipin' or sell_from regexp 'xinmeiti_doudian' or sell_from regexp 'xinmeiti_shipin' or sell_from regexp 'xinmeiti_xiaohongshu' or sell_from regexp 'xinmeitishipin_weidian'` 判断是否为新媒体订单
- **⚠️ 注意**：组合品含：组合品、升单品、毕业年级到期品

---

## 更新记录

| 日期 | 内容 |
|------|------|
| 2026-03-20 | 初始化用研业务术语词典 |
| 2026-03-27 | 统一格式：去掉术语编号、关联键、输出类型，统一为 定义/计算方式/表来源/筛选条件/注意 |
| 2026-03-27 | 新增看课相关：看课时长/天数/次数/完播次数/认真看课次数/最多学科及次数 |
| 2026-03-27 | 新增练习做题相关：做题次数/做题最多学科 |
| 2026-03-27 | 新增活跃相关：学习活跃次数/学习机用户标签 |
| 2026-03-28 | 新增订单消费相关：购课类型标签/历史消费金额/新媒体下单标签 |
| 2026-04-09 | 新增用户注册相关：手机号解密口径（unbase64） |
| 2026-04-10 | 手机号解密口径移至文件顶部「通用口径」，作为跨业务通用规则 |

---
---

# 业务术语词典（新媒体）

## 一、支付口径

`dws.topic_order_detail`（全量订单表）：公司全量订单数据，各渠道均可获取。新媒体场景需加 `sell_from` 筛选：`sell_from regexp 'xinmeitishipin' or sell_from regexp 'xinmeiti_doudian' or sell_from regexp 'xinmeiti_shipin' or sell_from regexp 'xinmeiti_xiaohongshu' or sell_from regexp 'xinmeitishipin_weidian'`（仅线上视频渠道）

`tmp.dinghuihui_xmt_online_order_detail`（新媒体业绩表）：仅含新媒体数据，含线上视频渠道 + 线下分销渠道 + 服务期（新媒体用户在其他渠道下单），按 `rq` 过滤时间

⚠️ 两表区别：全量表覆盖全公司所有渠道，业绩表仅含新媒体。新媒体场景下业绩表范围更大（含线下分销+服务期），全量表加 sell_from 只含线上视频渠道。单独说新媒体业绩时，默认从 `tmp.dinghuihui_xmt_online_order_detail` 取

常用维度字段：

- `zidabo_type`：自达播类型，字段枚举值包括：自播、小店自卖、服务期、微店、达播、线下。宽口径（默认）：自播 = `zidabo_type IN ('自播','小店自卖','服务期')`，达播 = `zidabo_type IN ('微店','达播','线下')`；窄口径：按枚举值各自独立统计，无特殊说明时默认使用宽口径
- `payment_platform`：支付渠道，枚举值：微店、视频号、抖店、服务期、线下、小红书
- 达人等级（历史标签）：按统计时间之前历史数据中，单天（`rq` + `o1daren_id`）`SUM(wfs)` 最高值划分 → 头部≥100万、肩部≥50万、腰部≥25万、尾部<25万

核心单品识别（`dws.topic_order_detail`）：

- 计算训练营：`dws.topic_order_detail` → `CASE WHEN good_kind_name_level_1 = '营课商品' THEN '计算训练营' END`
- 从小学物理 / 小初物理品：`dws.topic_order_detail` → `CASE WHEN good_kind_id_level_3 = 'f6f781ef-b49e-4e63-89a9-8b8bd4e0dfbc' AND good_subject_cnt = 1 AND good_stage_subject REGEXP '1-2-specialCourse' THEN '从小学物理' WHEN good_kind_id_level_3 = '3bf5762c-f9a6-4a04-b6e8-506f097474e4' AND good_subject_cnt = 1 AND good_stage_subject REGEXP '1-2-specialCourse' AND good_stage_subject REGEXP '2-2-vip' THEN '小初物理品' END`
- 核心单品支付渠道（按 `sell_from` 划分）：电销/网销=`telesale`、体验营=`tiyanying`、入校=`ruxiao`、奥德赛=`aodesai`、新媒体视频=`xinmeitishipin/xinmeiti_doudian/xinmeiti_shipin/xinmeiti_xiaohongshu/xinmeitishipin_weidian`、研学=`xinmeiti/xinmeitibianxian/yanxue/xinmeiti_weidian/xinmeiti_bianxian/Xinmeitigongzhonghao`、商业化-APP=`shangyehua/app`，其余默认归为商业化-APP


### 2.1 订单类

#### 支付订单量

- **定义**：支付的订单数（含支付成功和退款成功，即全量订单）
- **计算方式**：`COUNT(DISTINCT order_id)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤

#### 退款订单量

- **定义**：发生退款的订单数
- **计算方式**：`COUNT(DISTINCT CASE WHEN ramount > 0 THEN order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤

#### 退后订单量（实际支付订单量）

- **定义**：扣除退款后的有效订单数
- **计算方式**：`COUNT(DISTINCT order_id) - COUNT(DISTINCT CASE WHEN ramount > 0 THEN order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤

#### 激活订单量

- **定义**：已激活（开课）用户的去重订单数
- **计算方式**：`COUNT(DISTINCT CASE WHEN u_user IS NOT NULL AND u_user NOT IN ('unavailable','','null') AND wfs > 0.5 THEN order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤
- **⚠️ 注意**：激活判断口径为 `CASE WHEN u_user IS NULL OR u_user IN ('unavailable','','null') THEN '未激活' ELSE '激活' END`，且需 `wfs > 0.5`

#### 未激活订单量

- **定义**：未激活（未开课）用户的去重订单数
- **计算方式**：`COUNT(DISTINCT CASE WHEN (u_user IS NULL OR u_user IN ('unavailable','','null')) AND wfs > 0.5 THEN order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤
- **⚠️ 注意**：激活判断口径为 `CASE WHEN u_user IS NULL OR u_user IN ('unavailable','','null') THEN '未激活' ELSE '激活' END`，且需 `wfs > 0.5`

#### 总开课前退款订单量

- **定义**：退款时间早于开课时间（激活时间）的去重退款订单数
- **计算方式**：`COUNT(DISTINCT CASE WHEN SUBSTRING(r.refund_time,1,19) < SUBSTRING(d.binding_time,1,19) THEN a.order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` LEFT JOIN `dw.fact_order_detail`（取 binding_time）LEFT JOIN `dw.fact_order_detail_refund`（取 refund_time），关联条件：`a.order_id = d.order_id`、`a.order_id = r.order_id`
- **筛选条件**：`rq` 按指定时间范围过滤，且 `ramount > 0`
- **SQL来源**：`开课前后退款分析sql`

#### 总开课后退款订单量

- **定义**：退款时间晚于或等于开课时间（激活时间）的去重退款订单数
- **计算方式**：`COUNT(DISTINCT CASE WHEN SUBSTRING(r.refund_time,1,19) >= SUBSTRING(d.binding_time,1,19) THEN a.order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` LEFT JOIN `dw.fact_order_detail`（取 binding_time）LEFT JOIN `dw.fact_order_detail_refund`（取 refund_time），关联条件：`a.order_id = d.order_id`、`a.order_id = r.order_id`
- **筛选条件**：`rq` 按指定时间范围过滤，且 `ramount > 0`
- **SQL来源**：`开课前后退款分析sql`

#### 复购订单量

- **定义**：新媒体用户在全渠道再次购买正价商品的去重订单数
- **计算方式**：`COUNT(DISTINCT b.order_id)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` LEFT JOIN `dws.topic_order_detail`，关联条件：`a.u_user = b.u_user AND a.rq < b.paid_time AND a.order_id <> b.order_id`
- **筛选条件**：`rq` / `paid_time` 按指定时间范围过滤
- **SQL来源**：`复购相关数据sql`

### 2.2 GMV类

#### 支付GMV

- **定义**：用户支付的订单总金额（含支付成功和退款成功，即全量GMV）
- **计算方式**：`SUM(amount)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤

#### 退款GMV

- **定义**：用户退款的订单总金额
- **计算方式**：`SUM(ramount)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤

#### 退后GMV（实际支付GMV）

- **定义**：支付金额减去退款后的实际金额
- **计算方式**：`SUM(wfs)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤

#### 激活GMV

- **定义**：已激活（开课）用户的退后支付金额
- **计算方式**：`SUM(CASE WHEN u_user IS NOT NULL AND u_user NOT IN ('unavailable','','null') THEN wfs END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤
- **⚠️ 注意**：激活判断口径为 `CASE WHEN u_user IS NULL OR u_user IN ('unavailable','','null') THEN '未激活' ELSE '激活' END`

#### 未激活GMV

- **定义**：未激活（未开课）用户的退后支付金额
- **计算方式**：`SUM(CASE WHEN u_user IS NULL OR u_user IN ('unavailable','','null') THEN wfs END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤
- **⚠️ 注意**：激活判断口径为 `CASE WHEN u_user IS NULL OR u_user IN ('unavailable','','null') THEN '未激活' ELSE '激活' END`

#### 总开课前退款GMV

- **定义**：退款时间早于开课时间（激活时间）的退款金额合计
- **计算方式**：`SUM(CASE WHEN SUBSTRING(r.refund_time,1,19) < SUBSTRING(d.binding_time,1,19) THEN r.refund_amount END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` LEFT JOIN `dw.fact_order_detail`（取 binding_time）LEFT JOIN `dw.fact_order_detail_refund`（取 refund_time），关联条件：`a.order_id = d.order_id`、`a.order_id = r.order_id`
- **筛选条件**：`rq` 按指定时间范围过滤，且 `ramount > 0`
- **SQL来源**：`开课前后退款分析sql`

#### 总开课后退款GMV

- **定义**：退款时间晚于或等于开课时间（激活时间）的退款金额合计
- **计算方式**：`SUM(CASE WHEN SUBSTRING(r.refund_time,1,19) >= SUBSTRING(d.binding_time,1,19) THEN r.refund_amount END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` LEFT JOIN `dw.fact_order_detail`（取 binding_time）LEFT JOIN `dw.fact_order_detail_refund`（取 refund_time），关联条件：`a.order_id = d.order_id`、`a.order_id = r.order_id`
- **筛选条件**：`rq` 按指定时间范围过滤，且 `ramount > 0`
- **SQL来源**：`开课前后退款分析sql`

#### 复购GMV

- **定义**：新媒体用户在全渠道再次购买正价商品的实际支付金额（扣除退款）
- **计算方式**：`SUM(b.sub_amount)`，其中 `sub_amount = SUM(NVL(sub_amount,0)) - SUM(NVL(total_refund_amt,0))`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` LEFT JOIN `dws.topic_order_detail`，关联条件：`a.u_user = b.u_user AND a.rq < b.paid_time AND a.order_id <> b.order_id`
- **筛选条件**：`rq` / `paid_time` 按指定时间范围过滤
- **SQL来源**：`复购相关数据sql`

### 2.3 率值类

#### GMV退款率（线上）

- **定义**：线上退款金额占线上支付金额的比例
- **计算方式**：`SUM(CASE WHEN zidabo_type <> '线下' THEN ramount END) / SUM(CASE WHEN zidabo_type <> '线下' THEN amount END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤
- **⚠️ 注意**：需排除 `zidabo_type = '线下'` 的数据

#### 订单退款率（线上）

- **定义**：线上退款订单数占线上支付订单数的比例
- **计算方式**：`COUNT(DISTINCT CASE WHEN zidabo_type <> '线下' AND ramount > 0 THEN order_id END) / COUNT(DISTINCT CASE WHEN zidabo_type <> '线下' THEN order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤
- **⚠️ 注意**：需排除 `zidabo_type = '线下'` 的数据

#### 订单未激活率

- **定义**：未激活（未开课）订单数占全量订单数的比例
- **计算方式**：`COUNT(DISTINCT CASE WHEN (u_user IS NULL OR u_user IN ('unavailable','','null')) AND wfs > 0.5 THEN order_id END) / COUNT(DISTINCT CASE WHEN wfs > 0.5 THEN order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤

#### 订单激活率

- **定义**：已激活（开课）订单数占全量订单数的比例
- **计算方式**：`COUNT(DISTINCT CASE WHEN u_user IS NOT NULL AND u_user NOT IN ('unavailable','','null') AND wfs > 0.5 THEN order_id END) / COUNT(DISTINCT CASE WHEN wfs > 0.5 THEN order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤

#### GMV未激活率

- **定义**：未激活（未开课）GMV占全量退后GMV的比例
- **计算方式**：`SUM(CASE WHEN u_user IS NULL OR u_user IN ('unavailable','','null') THEN wfs END) / SUM(wfs)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤

#### GMV激活率

- **定义**：已激活（开课）GMV占全量退后GMV的比例
- **计算方式**：`SUM(CASE WHEN u_user IS NOT NULL AND u_user NOT IN ('unavailable','','null') THEN wfs END) / SUM(wfs)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤

#### 总开课前退款订单率

- **定义**：开课前退款订单数占全量退款订单数的比例
- **计算方式**：`COUNT(DISTINCT CASE WHEN SUBSTRING(r.refund_time,1,19) < SUBSTRING(d.binding_time,1,19) THEN a.order_id END) / COUNT(DISTINCT CASE WHEN r.refund_amount > 0 THEN a.order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` LEFT JOIN `dw.fact_order_detail`（取 binding_time）LEFT JOIN `dw.fact_order_detail_refund`（取 refund_time），关联条件：`a.order_id = d.order_id`、`a.order_id = r.order_id`
- **筛选条件**：`rq` 按指定时间范围过滤，且 `ramount > 0`
- **SQL来源**：`开课前后退款分析sql`

#### 总开课后退款订单率

- **定义**：开课后退款订单数占全量退款订单数的比例
- **计算方式**：`COUNT(DISTINCT CASE WHEN SUBSTRING(r.refund_time,1,19) >= SUBSTRING(d.binding_time,1,19) THEN a.order_id END) / COUNT(DISTINCT CASE WHEN r.refund_amount > 0 THEN a.order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` LEFT JOIN `dw.fact_order_detail`（取 binding_time）LEFT JOIN `dw.fact_order_detail_refund`（取 refund_time），关联条件：`a.order_id = d.order_id`、`a.order_id = r.order_id`
- **筛选条件**：`rq` 按指定时间范围过滤，且 `ramount > 0`
- **SQL来源**：`开课前后退款分析sql`

#### 总开课前GMV退款率

- **定义**：开课前退款GMV占全量支付GMV的比例
- **计算方式**：`SUM(CASE WHEN SUBSTRING(r.refund_time,1,19) < SUBSTRING(d.binding_time,1,19) THEN r.refund_amount END) / SUM(a.amount)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` LEFT JOIN `dw.fact_order_detail`（取 binding_time）LEFT JOIN `dw.fact_order_detail_refund`（取 refund_time），关联条件：`a.order_id = d.order_id`、`a.order_id = r.order_id`
- **筛选条件**：`rq` 按指定时间范围过滤
- **SQL来源**：`开课前后退款分析sql`

#### 总开课后GMV退款率

- **定义**：开课后退款GMV占全量支付GMV的比例
- **计算方式**：`SUM(CASE WHEN SUBSTRING(r.refund_time,1,19) >= SUBSTRING(d.binding_time,1,19) THEN r.refund_amount END) / SUM(a.amount)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` LEFT JOIN `dw.fact_order_detail`（取 binding_time）LEFT JOIN `dw.fact_order_detail_refund`（取 refund_time），关联条件：`a.order_id = d.order_id`、`a.order_id = r.order_id`
- **筛选条件**：`rq` 按指定时间范围过滤
- **SQL来源**：`开课前后退款分析sql`

### 2.4 用户数

#### 新用户数

- **定义**：注册时间与支付时间差值 ≤ 24小时（86400秒）的去重用户数，包含两种情况：注册24小时内支付、支付24小时内注册
- **计算方式**：`COUNT(DISTINCT CASE WHEN (ABS(UNIX_TIMESTAMP(SUBSTRING(regist_time, 1, 10)) - UNIX_TIMESTAMP(SUBSTRING(paid_time, 1, 10))) <= 86400) THEN u_user END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` 关联 `dw.dim_user`（取 `regist_time`）
- **筛选条件**：`rq` 按指定时间范围过滤，`regist_time` 和 `paid_time` 均不为空
- **⚠️ 注意**：`regist_time` 和 `paid_time` 均需 `SUBSTRING(..., 1, 10)` 截取到日期级别再比较；此为新媒体专属口径，与通用词典 `business_user_pay_status_business`（30天口径）不同

#### 老用户数

- **定义**：注册时间与支付时间均不为空，但差值 > 24小时（86400秒）的去重用户数
- **计算方式**：`COUNT(DISTINCT CASE WHEN regist_time IS NOT NULL AND paid_time IS NOT NULL AND (ABS(UNIX_TIMESTAMP(SUBSTRING(regist_time, 1, 10)) - UNIX_TIMESTAMP(SUBSTRING(paid_time, 1, 10))) > 86400) THEN u_user END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` 关联 `dw.dim_user`（取 `regist_time`）
- **筛选条件**：`rq` 按指定时间范围过滤
- **⚠️ 注意**：`regist_time` 和 `paid_time` 均需 `SUBSTRING(..., 1, 10)` 截取到日期级别再比较；注册时间或支付时间为空的用户归为"未激活（未开课）用户"，不计入新/老用户

#### 激活用户数

- **定义**：已激活（开课）的去重用户数（u_user 有效）
- **计算方式**：`COUNT(DISTINCT CASE WHEN u_user IS NOT NULL AND u_user NOT IN ('unavailable','','null') AND wfs > 0.5 THEN u_user END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤

#### 复购用户数

- **定义**：在新媒体下单后（wfs>0.5），在全渠道再次购买正价商品（original_amount>=39.9）的去重用户数
- **计算方式**：`COUNT(DISTINCT b.u_user)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail` LEFT JOIN `dws.topic_order_detail`，关联条件：`a.u_user = b.u_user AND a.rq < b.paid_time AND a.order_id <> b.order_id`
- **筛选条件**：`rq` / `paid_time` 按指定时间范围过滤
- **SQL来源**：`复购相关数据sql`

### 2.5 其他

#### 客单价（线上）

- **定义**：线上每笔退后订单的平均支付金额
- **计算方式**：`SUM(CASE WHEN zidabo_type <> '线下' THEN wfs END) / COUNT(DISTINCT CASE WHEN zidabo_type <> '线下' AND wfs > 0.5 THEN order_id END)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：`rq` 按指定时间范围过滤
- **⚠️ 注意**：需排除 `zidabo_type = '线下'` 的数据

#### 达人数（线上）

- **定义**：线上合作的达人数量
- **计算方式**：`COUNT(DISTINCT o1daren_id)`
- **表来源**：`tmp.dinghuihui_xmt_online_order_detail`
- **筛选条件**：
  - `rq` 按指定时间范围过滤
- **⚠️ 注意**：达人等级是**历史标签**，按统计时间之前的历史数据中，单天（`rq` + `o1daren_id` 分组）`SUM(wfs)` 的最高值划分：

  | 等级 | 历史单天营收条件 |
  |------|------------|
  | 头部达人 | ≥ 100万 |
  | 肩部达人 | ≥ 50万 且 < 100万 |
  | 腰部达人 | ≥ 25万 且 < 50万 |
  | 尾部达人 | < 25万 |

  取数逻辑：先从统计月份之前的历史数据中，找出符合等级条件的达人 ID，再用这些 ID 去取指定时间范围内的指标数据

---

## 二、结算口径（来源：tmp.dinghuihui_caiwu_order_detail）

### 结算GMV

- **定义**：未扣除退款的结算金额
- **计算方式**：`SUM(NVL(wt_shiji_jiesuan_gmv, 0))`
- **表来源**：`tmp.dinghuihui_caiwu_order_detail`
- **筛选条件**：仅含当月财务全域数据

### 实际结算GMV

- **定义**：扣除退款后的实际结算金额
- **计算方式**：`SUM(NVL(shiji_jiesuan_gmv, 0))`
- **表来源**：`tmp.dinghuihui_caiwu_order_detail`
- **筛选条件**：仅含当月财务全域数据

### 结算后退款GMV

- **定义**：结算后发生退款的金额
- **计算方式**：`SUM(NVL(wt_shiji_jiesuan_gmv, 0)) - SUM(NVL(shiji_jiesuan_gmv, 0))`
- **表来源**：`tmp.dinghuihui_caiwu_order_detail`
- **筛选条件**：仅含当月财务全域数据

### 结算订单量

- **定义**：未扣除退款的结算去重订单数
- **计算方式**：`COUNT(DISTINCT CASE WHEN wt_shiji_jiesuan_gmv > 0 THEN order_id END)`
- **表来源**：`tmp.dinghuihui_caiwu_order_detail`
- **筛选条件**：仅含当月财务全域数据

### 实际结算订单量

- **定义**：扣除退款后实际结算的去重订单数
- **计算方式**：`COUNT(DISTINCT CASE WHEN shiji_jiesuan_gmv > 0 THEN order_id END)`
- **表来源**：`tmp.dinghuihui_caiwu_order_detail`
- **筛选条件**：仅含当月财务全域数据

### 结算后退款订单量

- **定义**：结算后发生退款的去重订单数
- **计算方式**：`COUNT(DISTINCT CASE WHEN wt_shiji_jiesuan_gmv > 0 THEN order_id END)-COUNT(DISTINCT CASE WHEN shiji_jiesuan_gmv > 0 THEN order_id END)`
- **表来源**：`tmp.dinghuihui_caiwu_order_detail`
- **筛选条件**：仅含当月财务全域数据

---

## 三、口令&兑换码激活相关

### 领取口令用户数

- **定义**：领取过口令的去重用户数
- **计算方式**：`COUNT(DISTINCT user_id)`
- **表来源**：`promote_code.onion_password_activate`
- **⚠️ 注意**：看具体达人对应口令时，通过 `password_code` 字段限制

### 领取兑换码用户数

- **定义**：在指定时间范围内领取过兑换码的去重用户数
- **计算方式**：`COUNT(DISTINCT user_id)`
- **表来源**：`dw.fact_user_redeem_code`
- **筛选条件**：
  - `redeem_time` 按指定时间范围过滤
  - 取新媒体数据时加 `application_departments = '新媒体团队'`
  - 限定业务用途时通过 `application_usage` 筛选

### 口令全渠道转化金额

- **定义**：领取口令用户在全渠道产生的订单转化金额
- **计算方式**：`SUM(b.sub_amount)`
- **表来源**：`promote_code.onion_password_activate` a JOIN `dws.topic_order_detail` b，关联条件：`a.user_id = b.u_user`
- **筛选条件**：
  - 按订单状态筛选时，可通过 `b.status` 过滤（如 `'支付成功'`、`'退款成功'` 等），不传则统计全量订单
  - 看具体达人对应口令时，通过 `a.password_code` 字段限制
- **⚠️ 注意**：通过用户ID（`user_id = u_user`）关联口令表与订单表

### 口令新媒体转化金额

- **定义**：领取口令用户在新媒体渠道产生的订单转化金额
- **计算方式**：`SUM(CASE WHEN b.sell_from REGEXP 'xinmeitishipin|xinmeiti_doudian|xinmeiti_shipin|xinmeiti_xiaohongshu|xinmeitishipin_weidian' THEN b.sub_amount END)`
- **表来源**：`promote_code.onion_password_activate` a JOIN `dws.topic_order_detail` b，关联条件：`a.user_id = b.u_user`
- **筛选条件**：
  - 按订单状态筛选时，可通过 `b.status` 过滤（如 `'支付成功'`、`'退款成功'` 等），不传则统计全量订单
  - 看具体达人对应口令时，通过 `a.password_code` 字段限制

### 口令非新媒体转化金额

- **定义**：领取口令用户在非新媒体渠道产生的订单转化金额
- **计算方式**：`SUM(CASE WHEN NOT (b.sell_from REGEXP 'xinmeitishipin|xinmeiti_doudian|xinmeiti_shipin|xinmeiti_xiaohongshu|xinmeitishipin_weidian') THEN b.sub_amount END)`
- **表来源**：`promote_code.onion_password_activate` a JOIN `dws.topic_order_detail` b，关联条件：`a.user_id = b.u_user`
- **筛选条件**：
  - 按订单状态筛选时，可通过 `b.status` 过滤（如 `'支付成功'`、`'退款成功'` 等），不传则统计全量订单
  - 看具体达人对应口令时，通过 `a.password_code` 字段限制

### 口令全渠道转化率

- **定义**：领取口令用户中在全渠道产生下单行为的用户比例（分子为领取口令且在全渠道有订单的用户数，分母为领取口令的总用户数）
- **计算方式**：`COUNT(DISTINCT b.u_user) / COUNT(DISTINCT a.user_id)`，
- **表来源**：`promote_code.onion_password_activate` a LEFT JOIN `dws.topic_order_detail` b，关联条件：`a.user_id = b.u_user`
- **筛选条件**：
  - 按订单状态筛选时，可通过 `b.status` 过滤（如 `'支付成功'`、`'退款成功'` 等），不传则统计全量订单
  - 看具体达人对应口令时，通过 `a.password_code` 字段限制

### 口令新媒体转化率

- **定义**：领取口令用户中在新媒体渠道产生下单行为的用户比例
- **计算方式**：`COUNT(DISTINCT CASE WHEN b.sell_from REGEXP 'xinmeitishipin|xinmeiti_doudian|xinmeiti_shipin|xinmeiti_xiaohongshu|xinmeitishipin_weidian' THEN b.u_user END) / COUNT(DISTINCT a.user_id)`
- **表来源**：`promote_code.onion_password_activate` a LEFT JOIN `dws.topic_order_detail` b，关联条件：`a.user_id = b.u_user`
- **筛选条件**：
  - 按订单状态筛选时，可通过 `b.status` 过滤（如 `'支付成功'`、`'退款成功'` 等），不传则统计全量订单
  - 看具体达人对应口令时，通过 `a.password_code` 字段限制

### 口令非新媒体转化率

- **定义**：领取口令用户中在非新媒体渠道产生下单行为的用户比例
- **计算方式**：`COUNT(DISTINCT CASE WHEN NOT (b.sell_from REGEXP 'xinmeitishipin|xinmeiti_doudian|xinmeiti_shipin|xinmeiti_xiaohongshu|xinmeitishipin_weidian') THEN b.u_user END) / COUNT(DISTINCT a.user_id)`
- **表来源**：`promote_code.onion_password_activate` a LEFT JOIN `dws.topic_order_detail` b，关联条件：`a.user_id = b.u_user`
- **筛选条件**：
  - 按订单状态筛选时，可通过 `b.status` 过滤（如 `'支付成功'`、`'退款成功'` 等），不传则统计全量订单
  - 看具体达人对应口令时，通过 `a.password_code` 字段限制


---

## 更新记录

| 日期 | 内容 |
|------|------|
| 2026-03-28 | 初始化新媒体业务术语词典 |
| 2026-03-28 | 新增支付口径：支付GMV/退款GMV/退后GMV/支付订单量/退款订单量/退后订单量 |
| 2026-03-28 | 新增结算口径：实际结算GMV/结算GMV/结算后退款GMV |
| 2026-04-09 | 新增兑换码相关：领取兑换码用户数/领取兑换码数 |
| 2026-04-09 | 新增口令激活相关：领取口令用户数 |
| 2026-04-09 | 新增用户服务期相关：服务期用户数 |
| 2026-04-09 | 新增新媒体新老用户定义：新用户/老用户/未激活用户（24小时口径） |
| 2026-04-09 | 新增支付口径：激活订单量/激活GMV |
| 2026-04-09 | 新增开课前后退款相关：开课前/后退款订单量、退款GMV、退款订单率、GMV退款率 |
| 2026-04-10 | 新增全渠道转化相关：全渠道转化金额、全渠道转化率（口令用户关联全渠道订单） |
| 2026-04-10 | 新增新媒体/非新媒体转化相关：新媒体转化金额、非新媒体转化金额、新媒体转化率、非新媒体转化率（按 sell_from 区分渠道） |
