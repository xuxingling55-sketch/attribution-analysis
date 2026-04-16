-- =====================================================
-- 体验营线索表 training_camp.tm_extra
-- =====================================================
--
-- 【表粒度】
--   一个用户一条记录（业务上用户不重复进入线索表）；一条记录对应一条体验营线索主数据。
--
-- 【使用场景】
--   - 统计体验营线索量、进线时间分布、渠道与坐席维度
--   - 限定「服务期内」线索：`team_status = 1`
--   - 与 `yc_user_id` 关联 `training_camp.crm_order` 判断付费转化
--   - 需数仓扩展字段（如渠道类型 A 类等）时关联 `dw.dim_user_training_camp`
--
-- 【统计口径】（线索池/过程分析常用）
--
-- ```sql
-- SELECT created_at   -- 进线时间
--      , periods
--      , channel      -- 渠道
--      , channel_id   -- 代理
--      , phone
--      , yc_user_id   -- 与 crm_order 关联看付费转化
--      , add_wx
--      , self_character_tag
--      , self_stage_tag
-- FROM training_camp.tm_extra
-- WHERE periods BETWEEN ${number1} AND ${number2}   -- 常配合期数或日期范围
--   AND date(created_at) BETWEEN '${day1}' AND '${day2}'
--   AND length(yc_user_id) > 0
--   AND team_status = '1'   -- 服务期内
--   AND risk_user = 0       -- 非灰产
-- ```
--
-- 【常用关联】
--   - `training_camp.crm_order`：`tm_extra.yc_user_id = crm_order.userid_leads`（转化分析时建议再加 `crm_order.paid_time >= tm_extra.created_at`）
--   - `dw.dim_user_training_camp`：`tm_extra.yc_user_id = dim_user_training_camp.yc_user_id`
--   - `training_camp.tm_number`：按 `periods` 取期数起止与结营时间
--   - `training_camp.tm_channel`：`tm_extra.channel = tm_channel.channel` 取渠道名称、类型、级别
--
-- 【常用筛选条件】
--   ★服务期内线索（典型）：
--   - `team_status = '1'`
--   - `risk_user = 0`
--   - `length(yc_user_id) > 0`
--   - `date(created_at)` 或 `periods` 按分析窗口限定
--
-- 【注意事项】
--   ⚠️ 非分区明细表；Text 存储；更新频率 T+1。
--   ⚠️ `risk_user` 源表类型为 DECIMAL，比较时按数值 0/1 使用。
--   ⚠️ `self_stage_tag` 存 JSON 风格字符串，分析年级时常用下方「归一 grade」CASE。
--
-- =====================================================

CREATE TABLE training_camp.tm_extra (
    id BIGINT COMMENT '主键ID',
    userid STRING COMMENT '洋葱userid',
    unionid STRING COMMENT 'wx_unionid',
    phone STRING COMMENT '订单手机号',
    push BIGINT COMMENT '绑定是否推送 0未 1已推',
    created_at TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP COMMENT '更新时间',
    deleted_at TIMESTAMP COMMENT '删除时间',
    exchange_code STRING COMMENT '兑换码',
    work_id STRING COMMENT '销售id',
    work_name STRING COMMENT '销售姓名',
    order_id STRING COMMENT '订单id',
    order_bind STRING COMMENT '订单绑定状态',
    order_act TIMESTAMP COMMENT '激活时间',
    order_exp TIMESTAMP COMMENT '到期时间',
    sync_crm STRING COMMENT '同步crm状态',
    user_attribute STRING COMMENT '用户属性',
    qw_user_id STRING COMMENT '增加客户的销售企微id',
    channel_id STRING COMMENT '渠道Id',
    entity STRING COMMENT '是否包含实物',
    sync_logistics STRING COMMENT '同步物流状态',
    bind_way STRING COMMENT '激活方式',
    yc_tag STRING COMMENT '洋葱身份tag',
    active_at TIMESTAMP COMMENT '最近活跃时间',
    periods STRING COMMENT '期数',
    tags STRING COMMENT '探马标签',
    wechat_nickname STRING COMMENT '微信昵称',
    channel_tag STRING COMMENT '渠道标签',
    channel STRING COMMENT '渠道',
    account STRING COMMENT '是否为测试账号',
    channel_account STRING COMMENT '区分账号（不常用）',
    channel_plan STRING COMMENT '区分计划（不常用）',
    add_wx STRING COMMENT '是否添加企业微信',
    add_wx_type STRING COMMENT '添加类型:0未知 1主动 2被动',
    character_tag STRING COMMENT '人物标签',
    stage_tag STRING COMMENT '年级标签',
    intention STRING COMMENT '意向',
    doc STRING COMMENT '备注',
    today_learn STRING COMMENT '当天累计学习时长',
    recent_learn STRING COMMENT '近7天累计学习时长',
    regist_learn STRING COMMENT '购买后累计学习时长',
    self_character_tag STRING COMMENT '手动设置人物标签',
    self_stage_tag STRING COMMENT '手动设置年级标签',
    source STRING COMMENT '线索来源',
    external_user_id STRING COMMENT '外部用户ID',
    add_wx_at TIMESTAMP COMMENT '添加微信时间',
    team STRING COMMENT '所属团队',
    allocation_start TIMESTAMP COMMENT '分配起始时间',
    allocation_end TIMESTAMP COMMENT '分配终止时间',
    team_status STRING COMMENT '所属团队是否为体验 0不是 1是',
    active_end STRING COMMENT '是否体验营主动终结服务期/自然过期',
    owned_operations STRING COMMENT '线索是否归属运营',
    init_team STRING COMMENT '入线索时所属团队',
    remark STRING COMMENT '跟单备注',
    user_intention STRING COMMENT '跟单用户意向度',
    follow_up_status STRING COMMENT '跟进状态',
    operator_code STRING COMMENT '跟进人编码',
    operator_name STRING COMMENT '跟进人名称',
    follow_up_time TIMESTAMP COMMENT '最近跟进时间',
    next_order_time TIMESTAMP COMMENT '下次跟单时间',
    yc_user_id STRING COMMENT '手机号对应的用户ID',
    yc_onion_id STRING COMMENT '手机号对应洋葱ID',
    have_sea STRING COMMENT '是否曾在公海池',
    apply_sea_time TIMESTAMP COMMENT '从公海池领取时间',
    trigger_scenario STRING COMMENT '线索触发场景',
    now_qw_name STRING COMMENT '当前所属坐席名称',
    now_qw_id STRING COMMENT '当前所属坐席',
    u_transform STRING COMMENT '是否已经转化',
    expiration_sea_time TIMESTAMP COMMENT '线索到期时间',
    amount STRING COMMENT '订单金额',
    paid_time TIMESTAMP COMMENT '支付时间',
    good_name STRING COMMENT '订单名',
    now_order_id STRING COMMENT '最新订单ID',
    lock_time TIMESTAMP COMMENT '锁定时间',
    lock_str TIMESTAMP COMMENT '锁定时刻',
    calm_time TIMESTAMP COMMENT '冷静期时间',
    allocation_lately TIMESTAMP COMMENT '服务期上次认领时间',
    import_doc STRING COMMENT '批量导入线索原因',
    ph STRING COMMENT '洋葱加密手机号',
    light_class STRING COMMENT '是否是轻课用户 0不是 1是',
    province STRING COMMENT '省',
    province_code STRING COMMENT '省编码',
    city STRING COMMENT '市',
    city_code STRING COMMENT '市编码',
    county STRING COMMENT '县',
    county_code STRING COMMENT '县编码',
    stage_app STRING COMMENT 'APP内年级',
    family_id STRING COMMENT '用户家庭id',
    risk_user DECIMAL(38, 10) COMMENT '是否是灰产 0非 1是',
    recommended DECIMAL(38, 10) COMMENT '是否推荐他人 0非 1是',
    current_expiration_time TIMESTAMP COMMENT '当期剩余在库时间',
    task_name STRING COMMENT '任务名称',
    task_status BIGINT COMMENT '任务状态',
    deadline_time BIGINT COMMENT '任务截止时间',
    channel_grade STRING COMMENT '渠道年级等配置字段',
    referral_status DECIMAL(38, 10) COMMENT '转介绍状态：0无资格 1未下载 2已下载'
) USING text
TBLPROPERTIES (
    'STATS_GENERATED_VIA_STATS_TASK' = 'true',
    'bucketing_version' = '2',
    'transient_lastDdlTime' = '1743611198'
);

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## 核心字段说明（取数常选）
--
-- | 字段 | 用途摘要 |
-- |------|----------|
-- | unionid, phone | 微信/手机号维度 |
-- | created_at | 进线时间 |
-- | work_name | 销售姓名 |
-- | channel, channel_id | 渠道与代理 |
-- | channel_account, channel_plan | 账号/计划（较少用） |
-- | periods | 期数 |
-- | add_wx | 是否加企微 |
-- | self_character_tag, self_stage_tag | 手动角色/年级 |
-- | today_learn, recent_learn, regist_learn | 学习时长 |
-- | team_status | 是否服务期内 |
-- | yc_user_id | 关联订单转化 |
-- | stage_app | APP 内年级 |
-- | risk_user | 是否灰产 |
--
-- ## team_status
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 非体验营服务期口径 |
-- | 1 | 体验营服务期内 |
--
-- ## risk_user
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 非灰产 |
-- | 1 | 灰产 |
--
-- ## add_wx
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 否 |
-- | 1 | 是 |
--
-- ## add_wx_type
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 未知 |
-- | 1 | 主动 |
-- | 2 | 被动 |
--
-- ## self_character_tag（人物/角色，业务常用取值）
--
-- | 取值示例 | 含义 |
-- |----------|------|
-- | 爸爸 | 父亲角色 |
-- | 妈妈 | 母亲角色 |
-- | 学生 | 学生 |
-- | 家长 | 家长 |
--
-- ## self_stage_tag → 分析用 grade（归一）
--
-- > 源字段为类 JSON 字符串（如 `'["三年级"]'`）。下述 CASE 将年级归并为 a～m 档便于报表。
--
-- ```sql
-- CASE
--     WHEN self_stage_tag IN ('["一年级"]', '["1年级"]') THEN 'a.一年级'
--     WHEN self_stage_tag IN ('["二年级"]', '["2年级"]') THEN 'b.二年级'
--     WHEN self_stage_tag IN ('["三年级"]', '["3年级"]') THEN 'c.三年级'
--     WHEN self_stage_tag IN ('["四年级"]', '["4年级"]') THEN 'd.四年级'
--     WHEN self_stage_tag IN ('["五年级"]', '["5年级"]') THEN 'e.五年级'
--     WHEN self_stage_tag IN ('["六年级"]', '["6年级"]') THEN 'f.六年级'
--     WHEN self_stage_tag IN ('["七年级"]', '["7年级"]', '["初一"]') THEN 'g.七年级'
--     WHEN self_stage_tag IN ('["八年级"]', '["8年级"]', '["初二"]') THEN 'h.八年级'
--     WHEN self_stage_tag IN ('["九年级"]', '["9年级"]', '["初三"]') THEN 'i.九年级'
--     WHEN self_stage_tag IN ('["高一"]') THEN 'j.高一'
--     WHEN self_stage_tag IN ('["高二"]') THEN 'k.高二'
--     WHEN self_stage_tag IN ('["高三"]') THEN 'l.高三'
--     WHEN self_stage_tag IS NULL OR self_stage_tag = '' THEN 'm.未知'
--     ELSE replace(replace(replace(self_stage_tag, '"', ''), '[', ''), ']', '')
-- END AS grade
-- ```
