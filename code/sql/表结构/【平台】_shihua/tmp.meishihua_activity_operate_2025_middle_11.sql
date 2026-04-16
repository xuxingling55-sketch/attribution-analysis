-- =====================================================
-- 资源位转化- 活动资源位看板底层表 tmp.meishihua_activity_operate_2025_middle_11
-- =====================================================
--
-- 【表粒度】
--   见建表sql，分区字段：day, activity_id
--
-- 【业务定位】
--   - 【归属】资源位转化 / 活动资源位看板底层表。
--   - 同tmp.meishihua_activity_operate_2025_middle_1，最终结果表
--   - 活动资源位看板最终结果表

-- 【统计口径】
--   - 同tmp.meishihua_activity_operate_2025_middle_1

-- 【常用关联】
--   - insert 无 JOIN：select * from tmp.meishihua_activity_operate_2025_middle（同源结果表写入分区）

-- 【注意事项】
--   - 同tmp.meishihua_activity_operate_2025_middle_1
--
-- =====================================================

-- step2：存入分区表
insert overwrite tmp.meishihua_activity_operate_2025_starrocks partition(day,activity_id)

select * from tmp.meishihua_activity_operate_2025_middle ;

-- =====================================================
-- 枚举值
-- =====================================================
--
-- 见建表sql
