-- =====================================================
-- 体验营用户数据表（数仓维表） dw.dim_user_training_camp
-- =====================================================
--
-- 【表粒度】
--   一条体验营线索一条记录；`id` 为主键；与源业务表 `training_camp.tm_extra` 对齐线索粒度后，在数仓侧补充/加工字段（如渠道名称、团组、期数相关标签等）。
--
-- 【数据来源】
--   上游为 `training_camp.tm_extra`，在本表基础上加工数仓字段（具体加工逻辑以数仓任务为准）。
--
-- 【业务定位】
--   需要渠道类型、团组、期数支付标签等数仓扩展字段时，与 `tm_extra` 按 `yc_user_id`（等业务键）关联使用；与仅查业务库字段时的选表见各场景说明。
--
-- 【常用关联】
--   - `training_camp.tm_extra`：`tm_extra.yc_user_id = dim_user_training_camp.yc_user_id`
--   - `training_camp.crm_order`：`crm_order.userid_leads = dim_user_training_camp.yc_user_id`
--   - `training_camp.tm_number`：按 `periods` 与期数配置对齐（字符串/数值比较方式同 `tm_extra`）
--
-- 【常用筛选条件】
--   与 `tm_extra` 联用时，进线时间、服务期、灰产等仍以 `tm_extra` 侧 `created_at`、`team_status`、`risk_user` 等为准；本表多承担维度扩展，一般不再单独替代线索主表筛选。
--
-- 【注意事项】
--   ⚠️ 存储格式 ORC；非分区明细表；更新频率 T+1。
--   ⚠️ 与 `tm_extra` 部分字段同名时，以业务键关联后取数，避免混用两套表独立统计未对齐用户。
--
-- =====================================================

CREATE TABLE dw.dim_user_training_camp (
    id INT COMMENT '主键ID',
    user_id STRING COMMENT '用户id',
    user_sk INT COMMENT '数仓用户代理键',
    is_order INT COMMENT '是否下单',
    org_user_id STRING COMMENT '原表-洋葱userid',
    unionid STRING COMMENT 'wx_unionid',
    phone STRING COMMENT '订单手机号',
    push INT COMMENT '绑定是否推送 0未 1已推',
    created_at TIMESTAMP COMMENT '创建时间',
    created_at_sk STRING COMMENT '创建时间0-格式yyyymmdd',
    updated_at TIMESTAMP COMMENT '更新时间',
    deleted_at TIMESTAMP COMMENT '删除时间',
    exchange_code STRING COMMENT '兑换码',
    work_id STRING COMMENT '销售id',
    work_name STRING COMMENT '销售姓名',
    h5_order_id STRING COMMENT 'h5页面下的-订单id',
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
    channel_account STRING COMMENT '区分账号',
    channel_plan STRING COMMENT '区分计划',
    add_wx STRING COMMENT '是否添加企业微信',
    add_wx_type STRING COMMENT '添加类型:0为未知,1为主动,2为被动',
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
    sale_order_id STRING COMMENT '销售跟进的-订单ID',
    lock_time TIMESTAMP COMMENT '锁定时间',
    lock_str TIMESTAMP COMMENT '锁定时刻',
    calm_time TIMESTAMP COMMENT '冷静期时间',
    allocation_lately TIMESTAMP COMMENT '服务期上次认领时间',
    import_doc STRING COMMENT '批量导入线索原因',
    qw_user_name STRING COMMENT '坐席名称',
    auth_id INT COMMENT '小组id',
    auth_name STRING COMMENT '所在小组名称',
    group_id INT COMMENT '团id',
    group_name STRING COMMENT '团名称',
    start_time TIMESTAMP COMMENT '期数起始时间',
    end_time TIMESTAMP COMMENT '期数终止时间',
    star_next_friday TIMESTAMP COMMENT '开始时间的下周五',
    operate_at TIMESTAMP COMMENT '经营时间',
    periods_user_service_label STRING COMMENT '期数支付标签',
    channel_name STRING COMMENT '渠道名称',
    channel_type STRING COMMENT '渠道类型',
    family_id STRING COMMENT '用户家庭id',
    risk_user INT COMMENT '是否是灰产 0非 1是'
) USING orc
COMMENT '体验营用户数据表'
TBLPROPERTIES (
    'alias' = '体验营用户数据表',
    'bucketing_version' = '2',
    'last_modified_by' = 'huaxiong',
    'last_modified_time' = '1732607095',
    'transient_lastDdlTime' = '1774977231'
);

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## channel_type（渠道类型）
--
-- > A 类线索等场景常与 `tm_extra` 联表后在本表取 `channel_type`；完整业务枚举以数仓与运营配置为准。
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | A | A 类线索（常用） |
-- | （其他） | 以实际配置为准 |
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
-- ## add_wx_type
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 0 | 未知 |
-- | 1 | 主动添加 |
-- | 2 | 被动添加 |
