-- ============================================================
-- 云购生活数仓项目 · 清洗脚本（一）—— 重复值去重
-- 目标：ods_order → dwd_order
-- 方法：ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY order_time DESC)
--      每笔订单保留一条（最新下单时间），消除"整行重复"与"主键重复内容不同"
-- ============================================================
USE ydsh_ods;

-- 去重前后行数差异（应在预评估阶段一致）
SELECT '去重前 ods_order 行数' AS item, COUNT(*) AS cnt FROM ods_order;

CREATE TABLE dwd_order AS
SELECT order_id, user_id, store_id, order_date, order_time,
       pay_amount, discount_amount, pay_type, order_status, channel
FROM (
  SELECT *,
         ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY order_time DESC) AS rn
  FROM ods_order
) t
WHERE rn = 1;

-- 验证：dwd_order 中 order_id 不再重复，且与预评估重复数吻合
SELECT '去重后 dwd_order 行数' AS item, COUNT(*) AS cnt FROM dwd_order;
SELECT '去重后 order_id 是否仍重复' AS item,
       CASE WHEN COUNT(*) > 0 THEN '存在重复' ELSE '无重复' END AS result
FROM (SELECT order_id FROM dwd_order GROUP BY order_id HAVING COUNT(*) > 1) dup;

-- 差值与预评估阶段发现重复数核对
SELECT '去重前后行数差(应≈预评估重复数)' AS item,
       (SELECT COUNT(*) FROM ods_order) - (SELECT COUNT(*) FROM dwd_order) AS diff;
