-- =====================================================
-- APP- ab实验用户表 xlab.sample_hour
-- =====================================================
--
-- 【表粒度】
--   一个id一条（无分区字段）
--
-- 【业务定位】
--   - 【归属】APP / ab实验用户表。
--   - ab实验用户表
--
-- 【统计口径】
--   - 关联dw.dim_user表u_user(uid)
--   - 关联xlab.scenario/xlab_new.scenario表id(scenario_id)
--   - 关联xlab.abgroup/xlab_new.abgroup表id(group_id)
--   - 关联xlab.ab/xlab_new.ab表id(ab_id)
--
-- 【常用关联】
--   - `u_user` 与 `dw.dim_user`；`scenario_id` / `group_id` / `ab_id` 分别与 xlab 侧 scenario、abgroup、ab 维表对齐（见【统计口径】）
--
-- 【常用筛选条件】
--   - scenario_id、group_id、ab_id、ab_code
--
-- 【注意事项】
--   - 更新频率 T+1
--
-- =====================================================

CREATE TABLE
  `xlab`.`sample_hour` (
    `id` varchar(1073741824) DEFAULT NULL,
    `scenario_id` varchar(1073741824) DEFAULT NULL,
    `group_id` varchar(1073741824) DEFAULT NULL,
    `group_code` varchar(1073741824) DEFAULT NULL,
    `ab_id` varchar(1073741824) DEFAULT NULL,
    `ab_code` varchar(1073741824) DEFAULT NULL,
    `uid` varchar(1073741824) DEFAULT NULL,
    `create_time` datetime DEFAULT NULL
  ) PROPERTIES ("location" = "tos://yc-data-platform/user/hive/warehouse/xlab.db/sample_hour");

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见关联表的实际枚举值
