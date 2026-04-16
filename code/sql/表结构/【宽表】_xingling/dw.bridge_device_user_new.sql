-- =====================================================
-- 设备用户桥接表 dw.bridge_device_user_new
-- =====================================================
-- 【表粒度】
--   每用户每设备一条；分区 create_time_sk(yyyyMMdd)；T+1
--
-- 【使用场景】
--   用户在设备上的登录/注册行为；按 device_sk、u_user、first_scene 分析
--
-- 【业务定位】
--   设备-用户桥接明细
--
-- 【常用关联】
--   u_user、device_sk
--
-- 【常用筛选条件】
--   ★必加：
--   - create_time_sk BETWEEN ${start} AND ${end}
--   - first_scene IN ('注册', '登录')
--
-- 【注意事项】
--   first_scene 枚举见文件末
-- =====================================================

CREATE TABLE dw.bridge_device_user_new (
    device_sk BIGINT COMMENT '设备代理键',
    u_user STRING COMMENT '用户id',
    user_sk INT COMMENT '用户sk',
    create_time TIMESTAMP COMMENT '创建时间',
    create_time_sk INT COMMENT '分区日期 yyyyMMdd',
    first_scene STRING COMMENT '该设备该用户组合首次出现的场景（枚举见文件末）',
    scene_rk INT COMMENT '该设备该用户组合在不同场景下的强排序',
    rk INT COMMENT '该设备该用户组合首次出现，不分场景下的强排序'
)
USING orc
COMMENT '一个设备一个用户一条记录';

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## first_scene（首次场景）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 注册 | 首次为注册 |
-- | 登录 | 首次为登录 |
