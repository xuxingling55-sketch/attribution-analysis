-- =====================================================
-- 周周有礼奖品发放记录表 growth_activity.fission1201_user_reward_record
-- =====================================================
--
-- 【表粒度】
--   每周每个用户一条记录（user_id + start_of_week 唯一）
--   周周有礼是周频率的任务，一周算一个完整活动周期
--
-- 【业务定位】
--   记录裂变活动中奖品的发放情况（实物/虚拟）
--   通常第一个奖品是虚拟商品 VIP
--   不含邀请关系，邀请明细见 growth_activity.fission1201_invite_user
--
-- 【统计口径】
--   奖品1发放用户数 = COUNT(DISTINCT user_id) WHERE gift1_send_time IS NOT NULL
--   按日统计发放：
--     SELECT  to_date(gift1_send_time) AS 奖品发放日期
--            ,COUNT(DISTINCT user_id)   AS 奖品1用户数
--     FROM growth_activity.fission1201_user_reward_record
--     WHERE to_date(gift1_send_time)
--           BETWEEN date_sub(current_date(), 32) AND date_sub(current_date(), 1)
--     GROUP BY to_date(gift1_send_time)
--
-- 【常用关联】
--   与邀请表关联：
--     growth_activity.fission1201_invite_user.invite_from
--       = growth_activity.fission1201_user_reward_record.user_id
--     （邀请人是奖品领取人）
--
-- 【常用筛选条件】
--   场景条件：
--   - to_date(gift1_send_time) BETWEEN ${start} AND ${end}  -- 按奖品1发放日期过滤
--   - to_date(gift2_send_time) BETWEEN ${start} AND ${end}  -- 按奖品2发放日期过滤
--
-- 【注意事项】
--   ⚠️ 非分区表，全表扫描，查询时务必加时间过滤
--   ⚠️ tel、vip_wanted 已废弃，不要使用
--
-- =====================================================

CREATE TABLE growth_activity.fission1201_user_reward_record (
    id                    BIGINT    COMMENT '主键',
    user_id               STRING    COMMENT '用户ID',
    start_of_week         STRING    COMMENT '哪一周的记录',
    gift1_send_time       TIMESTAMP COMMENT '第一个奖励发放时间',
    gift2_send_time       TIMESTAMP COMMENT '第二个奖励发放时间',
    gift3_send_time       TIMESTAMP COMMENT '第三个奖励发放时间',
    created_at            TIMESTAMP COMMENT '创建时间',
    updated_at            TIMESTAMP COMMENT '更新时间',
    deleted_at            TIMESTAMP COMMENT '删除时间',
    order_id              STRING    COMMENT '本次记录采用的sourceId',
    tel                   STRING    COMMENT '用户电话（已废弃）',
    vip_wanted            STRING    COMMENT '选择的vip科目（已废弃）',
    gift2_sku_num         STRING    COMMENT '第二个奖品对应的sku编号',
    gift4_users           STRING    COMMENT '第四个奖品邀请的用户',
    gift2_address_id      STRING    COMMENT '奖品2地址',
    gift3_address_id      STRING    COMMENT '奖品3地址',
    gift3_sku_num_or_vip  STRING    COMMENT '第三个奖品对应的sku编号',
    u_group               STRING    COMMENT '对照实验分组',
    stage                 STRING    COMMENT '当前学段',
    week_user_group       BOOLEAN   COMMENT '用户身份分层结果'
)
USING text
TBLPROPERTIES (
    'is_core' = 'false'
);
