-- =====================================================
-- 用户维表 dw.dim_user
-- =====================================================
-- 【表粒度】
--   每个洋葱用户一条（明细）；非分区；T+1
--
-- 【使用场景】
--   - 取用户属性：渠道、城市、身份、年级、注册版本、注册方式、BC 归属、注册时间、手机号
--   - 判断电销服务期：ARRAY_CONTAINS(user_allocation, '电销')
--   - 排除测试用户：is_test_user = false
--
-- 【业务定位】
--   用户主数据；判断家长身份优先用 real_identity（见文件末枚举），勿单独用 role
--
-- 【统计口径】
--   关联键 u_user；手机号解密见下方 R01 / 【通用业务规则】glossary.md
--
-- 【常用筛选条件】
--   ★默认 C 端移动端注册用户：
--   - u_from IN ('android', 'ios', 'harmony')
--   - regist_time_sk BETWEEN ${start} AND ${end}
--
-- 【注意事项】
--   phone 可能需 unbase64；枚举见文件末
-- =====================================================

CREATE TABLE dw.dim_user (
    user_sk INT COMMENT '数仓用户sk',
    u_user STRING COMMENT '用户id',
    system_id STRING COMMENT '系统id',
    onion_id STRING COMMENT '洋葱id',
    name STRING COMMENT '姓名',
    nickname STRING COMMENT '昵称',
    gender STRING COMMENT '性别（枚举见文件末）',
    role STRING COMMENT '注册时角色（枚举见文件末；勿用于判断家长）',
    school_id STRING COMMENT '学校id',
    school_sk INT COMMENT '学校sk',
    school_sk1 INT COMMENT '学校sk1',
    channel STRING COMMENT '注册渠道',
    is_put_channel BOOLEAN COMMENT '是否投放渠道',
    is_room BOOLEAN COMMENT '是否有班',
    u_from STRING COMMENT '注册端口 android/ios/harmony（与 dim_device.os 一致）',
    grade STRING COMMENT '年级',
    type STRING COMMENT '注册方式（枚举见文件末）',
    province STRING COMMENT '省',
    province_code STRING COMMENT '省代码',
    city STRING COMMENT '市',
    city_code STRING COMMENT '市代码',
    area STRING COMMENT '地区',
    area_code STRING COMMENT '区',
    region_source STRING COMMENT '区域数据来源',
    learning_time INT COMMENT '',
    teaching_type STRING COMMENT '教学类型',
    teacher_organization STRING COMMENT '教师用户的单位属性',
    regist_time TIMESTAMP COMMENT '注册时间',
    activate_date TIMESTAMP COMMENT '激活时间',
    regist_time_sk INT COMMENT '注册date_sk',
    activate_date_sk INT COMMENT '激活date_sk',
    level INT COMMENT '等级',
    coins DOUBLE COMMENT '洋葱币数量',
    points DOUBLE COMMENT '经验值数',
    scores DOUBLE COMMENT '23个技能总分',
    verified_by_phone BOOLEAN COMMENT '手机号是否经过验证',
    is_parents BOOLEAN COMMENT '是否家长',
    tenant STRING COMMENT '校园版id',
    trial_type INT COMMENT '是否为新商品实验组',
    is_test_user BOOLEAN COMMENT '是否为测试用户',
    is_agent_user BOOLEAN COMMENT '是否归属代理商',
    realname STRING COMMENT '用户真实姓名',
    auth_type ARRAY<STRING> COMMENT '用户授权类型',
    stage_id INT COMMENT '学段',
    subject_id INT COMMENT '老师的学科',
    is_admin_room BOOLEAN COMMENT '是否为行政班用户',
    regist_app_version STRING COMMENT '注册时的app版本号',
    school_tag INT COMMENT '学校标签：0:非维护学校，1普通维护学校，2、重点维护学校',
    is_room_user BOOLEAN COMMENT '是否是有班用户',
    is_teach_user BOOLEAN COMMENT '是否是有教学班用户',
    regist_entrance_id STRING COMMENT '注册入口',
    os STRING COMMENT '操作系统',
    is_bind_parent BOOLEAN COMMENT '是否绑定家长用户',
    ladder_info_list ARRAY<STRING> COMMENT '天梯试炼场数据',
    skills ARRAY<INT> COMMENT '用户能力值',
    attribution STRING COMMENT '用户归属',
    user_attribution STRING COMMENT '数仓计算用户当天归属',
    regist_user_attribution STRING COMMENT '数仓计算用户注册时归属',
    study_book_info STRING COMMENT '学生当前的教学版本和学期信息',
    study_book_info_array ARRAY<STRING> COMMENT '学生当前的教学版本和学期信息(数组)',
    phone STRING COMMENT '手机号(需unbase64解码)',
    email STRING COMMENT '邮箱',
    qq_no STRING COMMENT 'qq号',
    user_allocation ARRAY<STRING> COMMENT '用户全域服务期',
    user_vip_tag STRING COMMENT '会员身份标签',
    regist_user_allocation ARRAY<STRING> COMMENT '用户注册当天服务期归属',
    real_identity STRING COMMENT '用户真实身份（判断家长首选，枚举见文件末）',
    user_risk STRING COMMENT '用户风险',
    user_identity STRING COMMENT '用户身份：common/advanced/lead/expLead',
    core_first_activated_date TIMESTAMP COMMENT '首次激活洋葱学园app产品时间',
    user_lifecycle_stage STRING COMMENT '引入期/成长期/成熟期',
    is_provost_teacher INT COMMENT '是否确认老师',
    is_ai_room_user INT COMMENT '是否ai班级用户'
)
USING orc
COMMENT '一个用户一条记录';

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## real_identity（用户真实身份）
--
-- | 枚举值 | 含义 | 备注 |
-- |--------|------|------|
-- | parents | 纯家长 | |
-- | student_parents | 学生家长共用 | |
-- | student | 学生 | |
-- | teacher | 老师 | |
-- | NULL | 未填写 | 历史 parents 角色用户可能为 NULL |
--
-- ## role（注册时角色，不能单独判断家长）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | student | 学生 |
-- | teacher | 老师 |
-- | parents | 历史小程序默认家长 |
-- | youzan | 有赞 |
--
-- ## gender（性别）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | male | 男 |
-- | female | 女 |
-- | NULL | 未知 |
