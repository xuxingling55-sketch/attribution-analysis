-- =====================================================
-- 裂变活动邀请用户表 growth_activity.fission1201_invite_user
-- =====================================================
-- 【表粒度】
--   一对邀请关系一条数据
--
-- 【业务定位】
--   裂变活动邀请记录，统计邀请新用户数、拉新成功的邀请人数
--
-- 【统计口径】
--   邀请新用户数：status IN ('邀请成功','待绑定手机号','手机号重复','设备重复') 的 user_id 去重
--   拉新成功的邀请人数：同上 status 的 invite_from 去重
--   发放奖励：仅 status = '邀请成功'
--
-- 【常用筛选条件】
--   ★时间范围：
--   - date(created_at) >= ${start} AND date(created_at) < ${end}
--   场景：
--   - 邀请新用户数/拉新人数：status IN ('邀请成功','待绑定手机号','手机号重复','设备重复')
--   - 仅发奖励：status = '邀请成功'
--
-- 【注意事项】
--   status 枚举见文件末
-- =====================================================

CREATE TABLE growth_activity.fission1201_invite_user (
    id BIGINT COMMENT '主键',
    user_id STRING COMMENT '被邀请用户ID',
    invite_from STRING COMMENT '邀请人ID',
    device_id STRING COMMENT '设备ID，用于防刷',
    status STRING COMMENT '邀请状态（枚举见文件末）',
    start_of_week STRING COMMENT '哪一周的记录',
    created_at TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP COMMENT '更新时间',
    deleted_at TIMESTAMP COMMENT '删除时间',
    phone STRING COMMENT '被邀请用户的手机号',
    ph STRING COMMENT '洋葱加密手机号',
    activity_type BIGINT COMMENT '活动类型'
)
USING text;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## status（邀请状态）
--
-- | 枚举值 | 含义 | 备注 |
-- |--------|------|------|
-- | 邀请成功 | 成功，需发奖励 | 仅此状态发奖 |
-- | 待绑定手机号 | 待绑定 | 统计拉新量时常纳入 |
-- | 手机号重复 | 重复 | 统计拉新量时常纳入 |
-- | 设备重复 | 重复设备 | 统计拉新量时常纳入 |
