-- =====================================================
-- 用户服务期进出记录表 user_allocation.user_allocation
-- =====================================================
-- 【表粒度】★必填
--   一个用户 × 一个服务期团队 × 一次进出记录 = 一行
--   ⚠️ 同一用户是否允许同时存在多条 effective 记录待确认：
--      技术团队文档写有唯一约束（同一时间只允许一条有效记录），
--      但营收表存在服务期双算场景（topic_order_detail.team_names 包含多个服务期），
--      可能是历史数据或其他机制导致，使用时注意。
--
-- 【数据范围】仅 C 端用户，不包含 B 端用户
--
-- 【分区】无分区，全量表，直接查询
--
-- 【业务定位】
--   记录用户进入/退出各服务期的时间及状态，是服务期归属的底层事实表。
--   判断用户在某时间点是否处于某服务期内：
--     WHERE state = 'effective'
--       AND start_time <= '目标时间'
--       AND end_time   >  '目标时间'
--
-- 【常用关联】
--   服务期团队名称需关联 user_allocation.team：
--     LEFT JOIN user_allocation.team t ON ua.team_id = t.id
--   取 t.name 获取服务期名称（如"电销"、"体验营"、"新媒体"等）
--   ⚠️ team_id 与电销组织架构（dw.dim_crm_organization）无关
--
-- 【常用筛选条件】
--   ★必加条件：
--   无
--
--   场景条件：
--   - state = 'effective'                  -- 查询当前生效的服务期
--   - start_time <= '目标时间' AND end_time > '目标时间'  -- 查询某时间点是否在服务期内
--
-- 【与 dws.topic_order_detail.team_names 的关系】
--   topic_order_detail.team_names 是基于本表计算的数组字段，
--   记录订单发生时用户所在的所有服务期团队名称。
-- =====================================================

CREATE TABLE `user_allocation`.`user_allocation` (
  `id`            string    COMMENT '记录主键',
  `user_id`       string    COMMENT '用户ID',
  `team_id`       bigint    COMMENT '服务期团队ID',
  `start_time`    timestamp COMMENT '服务期开始时间',
  `end_time`      timestamp COMMENT '服务期截止时间',
  `state`         string    COMMENT '服务期状态：invalid=未生效，effective=生效',
  `created_at`    timestamp COMMENT '记录创建时间',
  `updated_at`    timestamp COMMENT '记录更新时间',
  `deleted_at`    timestamp COMMENT '记录删除时间（软删除）',
  `initial_phone` string    COMMENT '用户进入服务期时的手机号',
  `end_reason`    string    COMMENT '服务期终止原因：expired=自然过期，abandon=主动放弃，cancelAfterSales=商品退款后权益不足'
);

-- =====================================================
-- 枚举值
-- =====================================================
--
-- ## team_id（服务期团队ID）
--
-- > 关联 user_allocation.team 表获取团队名称
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | 1 | 入校 |
-- | 2 | 电销/网销 |
-- | 4 | 体验营 |
-- | 5 | 新媒体视频 |
-- | 6 | 研学 |
-- | 7 | 本地化 |
-- | 8 | 商业化-公域 |
-- | 9 | 商业化-APP |
-- | 11 | 智能硬件-仅用于标记订单 |
-- | 12 | 客服-仅用于标记订单 |
-- | 13 | 伴学团队 |
-- | 14 | 大制作-仅用于标记订单 |
-- | 15 | 课程团队-仅用于标记订单 |
-- | 3 | 奥德赛-废弃 |
-- | 10 | 阿拉丁-废弃 |
--
-- ## state（服务期状态）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | effective | 生效 |
-- | invalid | 未生效 |
--
-- ## end_reason（服务期终止原因）
--
-- | 枚举值 | 含义 |
-- |--------|------|
-- | expired | 自然过期 |
-- | abandon | 主动放弃 |
-- | cancelAfterSales | 商品退款后权益不足 |
