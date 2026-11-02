-- ============================================================
-- 云购生活数仓项目 · 探索性分析（子任务7）
-- 基于 ydsh_dwd 层实跑核心指标
-- ============================================================
SET hive.auto.convert.join=false;
SET hive.auto.convert.join.noconditionaltask=false;
SET hive.mapjoin.smalltable.filesize=0;

-- ---------- 1. 核心经营指标：GMV / 订单量 / 客单价 ----------
SELECT
  '核心指标(已完成订单)' AS scope,
  ROUND(SUM(pay_amount), 2)        AS gmv,
  COUNT(DISTINCT order_id)         AS order_cnt,
  ROUND(SUM(pay_amount) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM ydsh_dwd.dwd_order
WHERE order_status = '已完成';

-- ---------- 2. 品类销售分布（已完成订单明细 × 商品维表） ----------
SELECT
  p.category,
  COUNT(DISTINCT o.order_id)            AS order_cnt,
  SUM(i.quantity)                       AS sales_qty,
  ROUND(SUM(i.quantity * i.unit_price), 2) AS sales_amount
FROM ydsh_dwd.dwd_order_item i
JOIN ydsh_dwd.dwd_order o  ON i.order_id = o.order_id
JOIN ydsh_dwd.dim_product p ON i.product_id = p.product_id
WHERE o.order_status = '已完成'
GROUP BY p.category
ORDER BY sales_amount DESC;

-- ---------- 3. 省份订单分布 ----------
SELECT
  u.province,
  COUNT(DISTINCT o.order_id)     AS order_cnt,
  ROUND(SUM(o.pay_amount), 2)    AS gmv
FROM ydsh_dwd.dwd_order o
JOIN ydsh_dwd.dim_user u ON o.user_id = u.user_id
WHERE o.order_status = '已完成'
GROUP BY u.province
ORDER BY gmv DESC
LIMIT 10;

-- ---------- 4. 门店销售分布 ----------
SELECT
  s.store_name, s.city,
  COUNT(DISTINCT o.order_id)  AS order_cnt,
  ROUND(SUM(o.pay_amount), 2) AS gmv
FROM ydsh_dwd.dwd_order o
JOIN ydsh_dwd.dim_store s ON o.store_id = s.store_id
WHERE o.order_status = '已完成'
GROUP BY s.store_name, s.city
ORDER BY gmv DESC
LIMIT 10;

-- ---------- 5. 渠道分布 ----------
SELECT
  channel,
  COUNT(DISTINCT order_id)  AS order_cnt,
  ROUND(SUM(pay_amount), 2) AS gmv,
  ROUND(SUM(pay_amount) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM ydsh_dwd.dwd_order
WHERE order_status = '已完成'
GROUP BY channel
ORDER BY gmv DESC;

-- ---------- 6. 用户行为漏斗（浏览→加购→收藏→购买） ----------
SELECT
  behavior_type,
  COUNT(*) AS event_cnt,
  COUNT(DISTINCT user_id) AS user_cnt
FROM ydsh_dwd.dwd_user_behavior
GROUP BY behavior_type;

-- ---------- 7. 窗口函数：用户累计消费（已完成订单，按时间累计） ----------
SELECT
  user_id, order_id, order_timestamp, pay_amount,
  ROUND(SUM(pay_amount) OVER (
    PARTITION BY user_id ORDER BY order_timestamp
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS cumulative_amount
FROM ydsh_dwd.dwd_order
WHERE order_status = '已完成'
ORDER BY user_id, order_timestamp
LIMIT 20;

-- ---------- 8. 窗口函数：用户订单消费排名（每用户订单金额降序） ----------
SELECT
  user_id, order_id, pay_amount,
  ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY pay_amount DESC) AS amt_rank
FROM ydsh_dwd.dwd_order
WHERE order_status = '已完成'
ORDER BY user_id, amt_rank
LIMIT 20;

-- ---------- 9. 高价值用户 TOP10（累计消费） ----------
SELECT
  user_id,
  ROUND(SUM(pay_amount), 2) AS total_amount,
  COUNT(DISTINCT order_id)  AS order_cnt
FROM ydsh_dwd.dwd_order
WHERE order_status = '已完成'
GROUP BY user_id
ORDER BY total_amount DESC
LIMIT 10;

-- ---------- 10. 月度销售趋势（窗口函数累计 GMV） ----------
SELECT
  month,
  ROUND(month_gmv, 2) AS month_gmv,
  ROUND(SUM(month_gmv) OVER (ORDER BY month), 2) AS cumulative_gmv
FROM (
  SELECT substr(order_date, 1, 7) AS month, SUM(pay_amount) AS month_gmv
  FROM ydsh_dwd.dwd_order
  WHERE order_status = '已完成'
  GROUP BY substr(order_date, 1, 7)
) t
ORDER BY month;
