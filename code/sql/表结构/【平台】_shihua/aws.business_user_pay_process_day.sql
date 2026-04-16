-- =====================================================
-- 资源位转化- 商业化曝光到转化日表 aws.business_user_pay_process_day
-- =====================================================
--
-- -- 【表粒度】
-- - 一个用户一个scene一个operate_id一个section_id一个sessionid一个sessionPublic一条数据，分区字段：day
--
-- 【业务定位】
--   - 【归属】资源位转化 / 商业化曝光到转化日表。
-- - 与 dws.topic_user_active_detail_day 按 u_user + day 关联；含 *_day 后缀分层字段（与活跃日表同名字段语义不完全等同，见 table-relations）；与 dw.dim_user 可按 u_user 对齐
--   - 埋点资源位漏斗数据，来源于events.frontend_event_orc

-- 【统计口径】
--   - 见part3
--
-- 【常用关联】
--   - u_user、day 对齐 dws.topic_user_active_detail_day
--
-- 【常用筛选条件】
--   - day
--
-- 【注意事项】
--   - 更新频率 T+1

-- =====================================================

CREATE TABLE
  `aws`.`business_user_pay_process_day` (
    `u_user` varchar(1073741824) DEFAULT NULL COMMENT '用户id',
    `user_sk` int(11) DEFAULT NULL COMMENT '数仓用户sk',
    `is_test_user` int(11) DEFAULT NULL COMMENT '是否为测试用户',
    `mid_active_type` varchar(1073741824) DEFAULT NULL COMMENT '中学活跃类型',
    `attribution` varchar(1073741824) DEFAULT NULL COMMENT '业务中台-用户归属',
 `business_user_pay_status_statistics` varchar(1073741824) DEFAULT NULL COMMENT '新增(统计日期当天注册的)、大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、老未(统计日期之前注册的)',
 `business_user_pay_status_business` varchar(1073741824) DEFAULT NULL COMMENT '大会员付费用户(统计日期之前买过大会员商品)、续费用户(统计日期之前买过正价课)、新用户(统计日期30天内注册的)、老用户(统计日期30以前注册的)',
    `grade` varchar(1073741824) DEFAULT NULL COMMENT '年级',
    `stage_name` varchar(1073741824) DEFAULT NULL COMMENT '学段',
    `grade_stage_name` varchar(1073741824) DEFAULT NULL COMMENT '年级段',
    `school_id` varchar(1073741824) DEFAULT NULL COMMENT '学校id',
    `school_sk` int(11) DEFAULT NULL COMMENT '学校sk',
    `school_id1` varchar(1073741824) DEFAULT NULL COMMENT '学校id',
    `school_sk1` int(11) DEFAULT NULL COMMENT '学校sk1',
    `option` varchar(1073741824) DEFAULT NULL COMMENT '付费入口类型',
    `scene` varchar(1073741824) DEFAULT NULL COMMENT '付费入口场景',
    `operate_id` varchar(1073741824) DEFAULT NULL COMMENT '付费入口id',
    `page_name` varchar(1073741824) DEFAULT NULL COMMENT '商品曝光页名称',
    `type` varchar(1073741824) DEFAULT NULL COMMENT '商品曝光页类型',
    `suit_id` array<varchar(1073741824)> DEFAULT NULL,
    `enter_good_page_status` varchar(1073741824) DEFAULT NULL COMMENT '进入商品页状态',
    `get_entrance_user` varchar(1073741824) DEFAULT NULL COMMENT '进入付费入口曝光页',
    `click_entrance_user` varchar(1073741824) DEFAULT NULL COMMENT '点击付费入口曝光页',
    `enter_good_page_user` varchar(1073741824) DEFAULT NULL COMMENT '进入商品曝光页',
    `click_good_page_user` varchar(1073741824) DEFAULT NULL COMMENT '点击商品曝光页',
    `good_id` varchar(1073741824) DEFAULT NULL COMMENT '商品id',
    `enter_order_page_user` varchar(1073741824) DEFAULT NULL COMMENT '进入订单详情页',
    `click_order_page_user` varchar(1073741824) DEFAULT NULL COMMENT '点击订单详情页',
    `order_id` varchar(1073741824) DEFAULT NULL COMMENT '订单id',
    `get_order_user` varchar(1073741824) DEFAULT NULL COMMENT '成功获取订单',
    `paid_order_user` varchar(1073741824) DEFAULT NULL COMMENT '付费成功',
    `amount` double DEFAULT NULL COMMENT '订单实收金额',
    `order_status` varchar(1073741824) DEFAULT NULL COMMENT '当前订单状态',
    `session_id` varchar(1073741824) DEFAULT NULL COMMENT 'session_id',
    `session_public` varchar(1073741824) DEFAULT NULL COMMENT 'session_public',
    `section_id` varchar(1073741824) DEFAULT NULL COMMENT '活动id',
    `client_os` varchar(1073741824) DEFAULT NULL COMMENT '端口',
    `d_app_version` varchar(1073741824) DEFAULT NULL COMMENT 'app版本',
    `order_sell_from` varchar(1073741824) DEFAULT NULL COMMENT '商品售卖来源',
    `live_id` varchar(1073741824) DEFAULT NULL COMMENT '直播间id',
    `event_time` datetime DEFAULT NULL COMMENT '商品曝光页面/直播间曝光页面时间',
    `good_type` varchar(1073741824) DEFAULT NULL COMMENT '商品类别',
    `pad_type` varchar(1073741824) DEFAULT NULL COMMENT '平板类型',
    `good_kind_name_level_1` varchar(1073741824) DEFAULT NULL COMMENT '商品类目-一级',
    `good_kind_name_level_2` varchar(1073741824) DEFAULT NULL COMMENT '商品类目-二级',
    `good_kind_name_level_3` varchar(1073741824) DEFAULT NULL COMMENT '商品类目-三级',
    `good_kind_id_level_1` varchar(1073741824) DEFAULT NULL COMMENT '商品类目-一级id',
    `good_kind_id_level_2` varchar(1073741824) DEFAULT NULL COMMENT '商品类目-二级id',
    `good_kind_id_level_3` varchar(1073741824) DEFAULT NULL COMMENT '商品类目-三级id',
    `task_id` varchar(1073741824) DEFAULT NULL COMMENT '任务id',
    `day` int(11) DEFAULT NULL
 ) PARTITION BY (day) COMMENT ("一个用户一个scene一个operate_id一个section_id一个sessionid一个sessionPublic一条数据") PROPERTIES ("location" = "tos://yc-data-platform/user/hive/warehouse/aws.db/business_user_pay_process_day");

-- =====================================================
-- 枚举值
-- =====================================================
--
-- <!-- # 用户支付路径开发文档

## 埋点

- 付费入口曝光：event_key = 'get_PaySceneEntrance'
- 付费入口点击：event_key = 'click_PaySceneEntrance'
- 进入商品曝光页：event_key = 'enter_GoodIntroPage'
- 点击商品曝光页：event_key = 'click_GoodIntroPage'
- 进入订单详情页：event_key = 'enterPaymentPage'
- 点击订单详情页：event_key = 'clickPaymentConfirm'
- 成功获取订单：event_key = 'getCreateOrder'

## 口径

```sql
FROM events.frontend_event_orc
   WHERE DAY = ${yesterday}
     AND product_id = "01"
     AND ROLE = "student"
     AND os IN ("android",
                "ios")
     AND u_user IS NOT NULL
     AND u_user != ""
```

## 路径

### 入口曝光

**口径：**
```sql
AND scene IS NOT NULL
AND scene != ""
AND event_key = "get_PaySceneEntrance"
```

**字段：**
- scene
- OPTION
- section_id
- operate_ids
- operate_id

**处理：**

```sql
--第一层处理
explode(split(coalesce(operate_ids[0], ""), ",")) get_operate_id,
if((day >= 20221201 and scene = "member-mytab-toBuy") or (day >= 20230314 and scene = "member-mytab-knowDetail") or (day >= 20230519 and scene = "study-videoPlayer-payBlockDialog") or (day >= 20230525 and scene = "study-videoPlayer-payVideo"), coalesce(section_id, "1"), "1") section_id

--第二层处理
CASE
    WHEN scene = "study-synchronousChapter-chapaterList-upgradeCourse"
         AND ${yesterday} BETWEEN 20220101 AND 20220124 THEN ""
    WHEN scene = "study-learnTogether-PKFinishPage" THEN ""
    WHEN scene = "study-videoPlayer-payBlockDialog" AND ${yesterday} < 20220501 THEN ""
    WHEN scene = "study-videoPlayer-payVideo" AND ${yesterday} < 20220501 THEN ""
 WHEN scene = "member-mytab-square" THEN if(instr(trim(get_operate_id), "-") != 0, REGEXP_EXTRACT(trim(get_operate_id), '(-)(.*)', 2), trim(get_operate_id))
    ELSE trim(get_operate_id)
END get_operate_idd
```

### 入口点击

**口径：**
```sql
AND scene IS NOT NULL
AND scene != ""
AND event_key = "click_PaySceneEntrance"
```

**字段：**
- scene
- OPTION
- section_id
- operate_id

**处理：**
```sql
CASE
    WHEN scene = "study-synchronousChapter-chapaterList-upgradeCourse"
         AND ${yesterday} BETWEEN 20220101 AND 20220124 THEN ""
    WHEN scene = "study-learnTogether-PKFinishPage" THEN ""
    WHEN scene = "study-videoPlayer-payBlockDialog" AND ${yesterday} < 20220501 THEN ""
    WHEN scene = "study-videoPlayer-payVideo" AND ${yesterday} < 20220501 THEN ""
 WHEN scene = "member-mytab-square" THEN if(instr(trim(operate_id), "-") != 0, REGEXP_EXTRACT(trim(operate_id), '(-)(.*)', 2), trim(operate_id))
    ELSE trim(operate_id)
END operate_id
```

### 入口曝光——入口点击

**关联字段：**
- scene
- section_id（scene = "member-mytab-toBuy"、"member-mytab-knowDetail"、"study-videoPlayer-payBlockDialog"、"study-videoPlayer-payVideo"）时需要传
- u_user
- operate_id

**处理：**
```sql
t1.u_user = t2.u_user
AND if(t1.scene = "ad-VIPIntroPage-activityModule" AND ${yesterday} BETWEEN 20220701 AND 20220705, 1 = 1, t1.scene = t2.scene)
AND t1.section_id = t2.section_id
AND t1.get_operate_id = t2.operate_id
```

### 进入商品介绍页和点击去付费

**字段：**
- u_user,
- session_id,
- session_public,
- good_id,
- event_key,
- operate_id,
- section_id,
- order_id,
- from_page_name,
- page_name,
- TYPE

**口径：**
```sql
AND event_key IN ("enter_GoodIntroPage",
                  "click_GoodIntroPage")
AND u_user IS NOT NULL
AND u_user != ""
AND session_id IS NOT NULL
AND session_id != ""
```

**处理：**

```sql
--第一层处理
if(event_key = "enter_GoodIntroPage" AND DAY BETWEEN 20220701 AND 20220705, replace(from_page_name, "_july_zhulang_2022", ""), from_page_name) from_page_name

--第二层处理
split(from_page_name, "_")[size(split(from_page_name, "_")) - 1] scene

--第三层处理
if((${yesterday} >= 20221201 and scene = "member-mytab-toBuy") or (${yesterday} >= 20230314 and scene = "member-mytab-knowDetail") or (${yesterday} >= 20230519 and scene = "study-videoPlayer-payBlockDialog") or ($yesterday >= 20230525 and scene = "study-videoPlayer-payVideo"), coalesce(section_id, "1"), "1") section_id,
CASE
    WHEN scene = "study-synchronousChapter-chapaterList-upgradeCourse"
         AND ${yesterday} BETWEEN 20220101 AND 20220124 THEN ""
    WHEN scene = "study-learnTogether-PKFinishPage" THEN ""
    WHEN scene = "study-videoPlayer-payBlockDialog" AND ${yesterday} < 20220501 THEN ""
    WHEN scene = "study-videoPlayer-payVideo" AND ${yesterday} < 20220501 THEN ""
 WHEN scene = "member-mytab-square" THEN if(instr(operate_id, "-") != 0, REGEXP_EXTRACT(operate_id, '(-)(.*)', 2), operate_id)
    ELSE operate_id
END operate_id
```

### 入口点击——进入商品介绍页

**口径1：**
```sql
event_key = "enter_GoodIntroPage"
AND page_name LIKE '%2023新禧主会场%'
AND join_scene = ""
AND operate_id = ""
```

**关联条件：**
从20221231-20230217，scene值为'member-mytab-toBuy'的场景，增加section_id作为关联条件
当section_id为cheap时，后续enter_GoodIntroPage埋点，取固定条件页面【from_page_name ='' and operate_id ='' and page_name regexp '2023新禧主会场'】

**处理1：**
```sql
t1.click_user = t21.u_user
AND t1.scene = "member-mytab-toBuy"
AND t1.click_section_id = 'cheap'
AND ${yesterday} BETWEEN 20221231 AND 20230217
```

**口径2:**
非口径1之外的

**关联条件：**
当section_id不为cheap时，直接按照
- scene
- operateId
- section_id

**处理2：**
```sql
t1.click_user = t2.u_user
AND if(t1.scene = "ad-VIPIntroPage-activityModule" AND ${yesterday} BETWEEN 20220701 AND 20220705, 1 = 1, t1.scene = t2.join_scene)
AND t1.click_section_id = t2.section_id
AND t1.operate_id = t2.operate_id
```

### 进入商品介绍页——点击去付费

**关联条件：**
- session_id
- u_user
- session_public

**处理：**
```sql
--非1即2

if(t21.u_user is not null, t21.session_id, t2.session_id) = t3.session_id
AND coalesce(t21.u_user, t2.u_user) = t3.u_user AND if(${yesterday} >= 20220701, if(t21.u_user is not null, t21.session_public, t2.session_public) = t3.session_public, 1 = 1)
```

### 进入付费落地页、点击订单详情、获取订单

**字段：**
- u_user,
- session_id,
- session_public,
- good_id,
- operate_id,
- order_id,
- from_page_name,
- page_name,
- TYPE

**口径：**
```sql
AND event_key IN ("enterPaymentPage",
                  "clickPaymentConfirm",
                  "getCreateOrder")
AND u_user IS NOT NULL
AND u_user != ""
AND session_id IS NOT NULL
AND session_id != ""
```

**处理：**

```sql
--第一层
split(from_page_name, "_")[size(split(from_page_name, "_")) - 1] scene,
row_number() over(PARTITION BY u_user, session_id, good_id, event_key, order_id ORDER BY event_time DESC) rk

--第二层
CASE
    WHEN scene = "study-synchronousChapter-chapaterList-upgradeCourse"
         AND ${yesterday} BETWEEN 20220101 AND 20220124 THEN ""
    WHEN scene = "study-learnTogether-PKFinishPage" THEN ""
    WHEN scene = "study-videoPlayer-payBlockDialog" THEN ""
    WHEN scene = "study-videoPlayer-payVideo" THEN ""
 WHEN scene = "member-mytab-square" THEN if(instr(operate_id, "-") != 0, REGEXP_EXTRACT(operate_id, '(-)(.*)', 2), operate_id)
    ELSE operate_id
END operate_id,
scene join_scene

--第三层
rk = 1
```

### 点击去付费——进入付费落地页

**处理：**
```sql
t3.session_id = t4.session_id
AND t3.good_id = t4.good_id
AND t3.u_user = t4.u_user
```

### 进入付费落地页——点击订单详情

**处理：**
```sql
t4.session_id = t5.session_id
AND t4.good_id = t5.good_id
AND t4.u_user = t5.u_user
```

### 点击订单详情——获取订单

**处理：**
```sql
t5.session_id = t6.session_id
AND t5.good_id = t6.good_id
AND t5.u_user = t6.u_user
```

### 获取订单——付费

**口径：**
```sql
SELECT DISTINCT user_sk,
                order_id,
                amount,
                status
FROM dw.fact_order_detail
WHERE paid_time_sk >= ${yesterday}
```

**处理：**
```sql
t7.user_sk = t8.user_sk
AND t6.order_id = t8.order_id
``` -->

