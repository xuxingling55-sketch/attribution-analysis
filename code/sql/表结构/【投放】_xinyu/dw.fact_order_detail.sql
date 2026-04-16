-- =====================================================
-- 订单明细表 dw.fact_order_detail
-- =====================================================
-- 【表粒度】
--   一个用户一个订单多条数据（按子商品拆分）
--
-- 【使用场景】
--   用户数/营收：count(distinct u_user)、sum(arrival_amount)
--   LTV：新用户当月付费/新增用户（需与用户表关联）
--
-- 【业务定位】
--   订单明细，一订单多子商品一条；事实支付/退款
--
-- 【统计口径】
--   营收/LTV 常用：paid_time_sk 范围内且 status IN ('支付成功','退款成功')；到账 sum(arrival_amount)
--   正价课：original_amount >= 39
--
-- 【常用筛选条件】
--   ★统计营收/到账：
--   - paid_time_sk BETWEEN ${start} AND ${end}
--   - status IN ('支付成功', '退款成功')
--   场景追加：
--   - 正价：original_amount >= 39
--
-- 【注意事项】
--   status 枚举见文件末
-- =====================================================

CREATE TABLE dw.fact_order_detail (
    order_id STRING COMMENT '订单业务id',
    good_sk INT COMMENT '商品代理键',
    good_name STRING COMMENT '商品名',
    sub_good_cnt INT COMMENT '子商品的个数',
    sub_good_sk INT COMMENT '子商品代理键',
    user_sk INT COMMENT '用户代理键',
    u_user STRING COMMENT '用户ID',
    date_sk INT COMMENT '订单创建日期代理键',
    update_time_sk INT COMMENT '订单修改日期代理键',
    status STRING COMMENT '当前订单状态（枚举见文件末）',
    kind STRING COMMENT '子商品的类型',
    stage_id INT COMMENT '学段',
    stage_name STRING COMMENT '学段名',
    subject_id INT COMMENT '学科',
    subject_name STRING COMMENT '学科名',
    semester_id INT COMMENT '学期',
    semester_name STRING COMMENT '学期名',
    good_original_amount DOUBLE COMMENT '商品原价',
    original_amount DOUBLE COMMENT '订单原价',
    amount DOUBLE COMMENT '订单实收金额',
    discount_amount DOUBLE COMMENT '优惠金额',
    sub_amount DOUBLE COMMENT '子商品实收金额',
    add_time_ms BIGINT COMMENT '增加的服务时长',
    add_time_day INT COMMENT '增加的服务时长（天）',
    client_os STRING COMMENT '设备类型',
    payment_platform STRING COMMENT '支付平台',
    platform_id STRING COMMENT '平台ID',
    business_id STRING COMMENT '商户ID',
    role STRING COMMENT '用户角色',
    business_group STRING COMMENT '业务群',
    activate_time_sk INT COMMENT '激活时间',
    create_time TIMESTAMP COMMENT '源系统创建条目的时间',
    update_time TIMESTAMP COMMENT '源系统修改条目的时间',
    dw_insert_time TIMESTAMP COMMENT 'ETL插入记录的时间',
    dw_update_time TIMESTAMP COMMENT 'ETL修改记录的时间',
    publisher_id INT COMMENT '版本',
    publisher_name STRING COMMENT '教材版本名',
    product_id STRING COMMENT '产品id',
    is_group_buy BOOLEAN COMMENT '是否线下渠道团购订单',
    app_version STRING COMMENT 'APP版本号',
    service_amount DOUBLE COMMENT '服务费',
    procedures_amount DOUBLE COMMENT '手续费',
    arrival_amount DOUBLE COMMENT '到账金额',
    payment_channel STRING COMMENT '支付渠道',
    coupon STRING COMMENT '业务系统中代金券id',
    app_channel STRING COMMENT '创建订单的App的下载渠道',
    transaction_no STRING COMMENT '支付平台生成的交易流水号',
    is_by_manual BOOLEAN COMMENT '是否是手工订单',
    account_id STRING COMMENT '账户id',
    shop_id STRING COMMENT '推广来源id',
    shop_name STRING COMMENT '推广来源',
    is_parent_telemarketing SMALLINT COMMENT '是否属于家长电销订单',
    seat_no STRING COMMENT '坐席号',
    mid_revenue_amount DOUBLE COMMENT '中学营收',
    mid_revenue_finance_amount DOUBLE COMMENT '中学营收-财务',
    teacher_school_revenue_amount DOUBLE COMMENT '教师和线下营收',
    teacher_school_revenue_finance_amount DOUBLE COMMENT '教师和线下营收-财务',
    parent_revenue_amount DOUBLE COMMENT '家长营收',
    parent_revenue_finance_amount DOUBLE COMMENT '家长营收-财务',
    primary_revenue_amount DOUBLE COMMENT '小学营收',
    primary_revenue_finance_amount DOUBLE COMMENT '小学营收-财务',
    other_revenue_amount DOUBLE COMMENT '其他营收',
    paid_time TIMESTAMP COMMENT '支付时间',
    paid_time_sk INT COMMENT '支付时间sk',
    recalled BOOLEAN COMMENT '权限是否收回',
    total_refund_amt DOUBLE COMMENT '总退款金额',
    refund_info_list ARRAY<STRING> COMMENT '退款详情',
    remain_amt DOUBLE COMMENT '剩余金额',
    shop_detail_id STRING COMMENT '推广来源明细id',
    shop_detail_name STRING COMMENT '推广来源明细名称',
    os STRING COMMENT '端口',
    is_by_manual_opertion BOOLEAN COMMENT '是否手工标记订单',
    activate_time TIMESTAMP COMMENT '激活时间',
    good_id STRING COMMENT '商品id',
    attribution STRING COMMENT 'B/C订单归属',
    check_attribution STRING COMMENT '数据中台计算B/C订单归属',
    grade STRING COMMENT '用户填写年级',
    mid_grade STRING COMMENT '中学修正年级',
    mid_stage_name STRING COMMENT '中学修正学段',
    gender STRING COMMENT '用户性别',
    regist_time TIMESTAMP COMMENT '注册时间',
    regist_time_sk INT COMMENT '注册时间sk',
    regist_channel STRING COMMENT '注册渠道',
    u_from STRING COMMENT '系统平台',
    regist_type STRING COMMENT '注册方式(枚举值)',
    is_put_channel SMALLINT COMMENT '是否投放渠道',
    province STRING COMMENT '省',
    province_code STRING COMMENT '省code',
    city STRING COMMENT '市',
    city_code STRING COMMENT '市code',
    area STRING COMMENT '区',
    area_code STRING COMMENT '区code',
    is_test_user SMALLINT COMMENT '是否测试用户',
    is_teach_user SMALLINT COMMENT '是否教学班用户',
    is_admin_room SMALLINT COMMENT '是否行政班用户',
    is_room_user SMALLINT COMMENT '是否有班用户',
    is_new_user SMALLINT COMMENT '是否新用户',
    school_sk INT COMMENT '学校sk',
    school_id STRING COMMENT '学校id',
    school_sk1 INT COMMENT '学校sk1',
    school_id1 STRING COMMENT '学校id1',
    user_attribution STRING COMMENT '用户活跃时归属',
    regist_user_attribution STRING COMMENT '用户注册当天归属',
    missed_order BOOLEAN COMMENT '是否掉单',
    group ARRAY<STRING> COMMENT '标签',
    real_add_time_day INT COMMENT '真实服务时长',
    real_activate_time TIMESTAMP COMMENT '真实激活时间',
    sell_from STRING COMMENT '商品售卖来源',
    new_media_revenue_finance_amount DOUBLE COMMENT '新媒体财务营收',
    institution_revenue_finance_amount DOUBLE COMMENT '机构财务营收',
    business_attribution STRING COMMENT '业务群归属',
    yc_from STRING COMMENT '机构名称',
    sku_amount DOUBLE COMMENT 'sku 价格',
    sku_name STRING COMMENT 'sku名字',
    procedures_rate DOUBLE COMMENT '手续费率',
    sn STRING COMMENT 'pad sn',
    good_sell_kind STRING COMMENT '商品售卖类型',
    is_pad_price_difference_order BOOLEAN COMMENT '是否体验机补差价订单',
    new_media_type STRING COMMENT '新媒体营收类型',
    model_type STRING COMMENT '平板型号',
    insurance_category STRING COMMENT '保险类别',
    dynamic_diff_price_type STRING COMMENT '补差价类型',
    binding_time TIMESTAMP COMMENT '绑定时间',
    binding_time_sk INT COMMENT '绑定时间sk',
    good_year STRING COMMENT '商品时长',
    good_content STRING COMMENT '内容标识',
    business_gmv_attribution STRING COMMENT '业务GMV归属划分',
    xugou_order_kind STRING COMMENT '续购订单类型',
    xugou_pre_order_id STRING COMMENT '续购前序订单id',
    discount_id STRING COMMENT '优惠券id',
    discount_note STRING COMMENT '优惠券note',
    discount_price DOUBLE COMMENT '优惠券金额（元）',
    special_course_type STRING COMMENT '课程包类型',
    discount_order_id STRING COMMENT '尾款订单的优惠券订单id',
    team_ids ARRAY<STRING> COMMENT '全域业绩归属',
    team_names ARRAY<STRING> COMMENT '全域业绩归属',
    good_category STRING COMMENT '商品类别',
    sku_group_good_id STRING COMMENT 'sku商品组id',
    good_type STRING COMMENT '商品类型(已弃用,推荐good_kind_name_level_2)',
    correct_team_names ARRAY<STRING> COMMENT '修正后业绩归属',
    first_order_type STRING COMMENT '前序订单类型',
    last_order_type STRING COMMENT '尾单类型',
    coupon_order_id STRING COMMENT '前序优惠券订单id',
    pad_type STRING COMMENT '平板类型',
    pre_order_id STRING COMMENT '前序订单id',
    live_platform_tag STRING COMMENT '直播平台标签',
    good_kind_name_level_1 STRING COMMENT '商品类目-一级',
    good_kind_name_level_2 STRING COMMENT '商品类目-二级',
    good_kind_name_level_3 STRING COMMENT '商品类目-三级',
    good_kind_id_level_1 STRING COMMENT '商品类目-一级id',
    good_kind_id_level_2 STRING COMMENT '商品类目-二级id',
    good_kind_id_level_3 STRING COMMENT '商品类目-三级id',
    auth_time_sk INT COMMENT '授权赋予时间',
    good_type_src STRING COMMENT '售后方式: Duration/Timing',
    strategy_type STRING COMMENT '策略类型',
    strategy_detail STRING COMMENT '策略明细'
)
USING orc
COMMENT '一笔订单一个子商品一条记录，只包含支付成功和退款成功的非测试订单';

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## status（订单状态，本表常用取值）
--
-- | 枚举值 | 含义 | 备注 |
-- |--------|------|------|
-- | 支付成功 | 已支付 | 营收常用 |
-- | 退款成功 | 已退款 | LTV 等含退款场景 |
