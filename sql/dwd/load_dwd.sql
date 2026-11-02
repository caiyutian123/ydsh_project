-- ============================================================
-- 云购生活数仓项目 · DWD 层 ETL 加载（子任务6）
-- 输入：ydsh_ods.cln_* / cln_order_final
-- 输出：ydsh_dwd 各维度表与事实表
-- 说明：dwd_order / dwd_user_behavior 采用动态分区加载；
--      dwd_order 加载时按 order_id 去重（保留时间最早一条）。
-- ============================================================
SET hive.exec.dynamic.partition.mode=nonstrict;
-- 关闭本地 Map Join（Hive 4 在容器内 local task 会因 JobConf 初始化空指针失败）
SET hive.auto.convert.join=false;
SET hive.auto.convert.join.noconditionaltask=false;
SET hive.enforce.bucketing=true;
-- 动态分区上限调大（订单按 366 天分区，默认 100/节点 会报 Error 20004）
SET hive.exec.max.dynamic.partitions=2000;
SET hive.exec.max.dynamic.partitions.pernode=2000;

-- ---------- 日期维度：生成 2024 全年（闰年 366 天） ----------
INSERT OVERWRITE TABLE ydsh_dwd.dim_date
SELECT
  CAST(date_format(d, 'yyyyMMdd') AS INT) AS date_id,
  d                                       AS date_str,
  YEAR(d)                                 AS year,
  QUARTER(d)                              AS quarter,
  MONTH(d)                                AS month,
  DAY(d)                                  AS day,
  weekofyear(d)                           AS week_of_year,
  CAST(date_format(d, 'u') AS INT)        AS day_of_week,
  IF(date_format(d, 'u') >= 6, 1, 0)      AS is_weekend
FROM (
  SELECT date_add('2024-01-01', idx) AS d
  FROM (SELECT posexplode(split(space(365), ' ')) AS (idx, x)) e
) t;

-- ---------- 用户维度：region 合并 + 会员等级编码映射 ----------
INSERT OVERWRITE TABLE ydsh_dwd.dim_user
SELECT
  u.user_id, u.user_name, u.gender, u.age, u.province, u.city,
  concat(u.province, '-', u.city) AS region,
  u.register_date, u.member_level,
  COALESCE(m.level_code, 1) AS member_level_code,
  u.phone, u.email
FROM ydsh_ods.cln_user u
LEFT JOIN ydsh_dwd.dim_member_level m
  ON u.member_level = m.level_name;

-- ---------- 商品维度 ----------
INSERT OVERWRITE TABLE ydsh_dwd.dim_product
SELECT
  product_id, product_name, category, sub_category, brand,
  CAST(price AS DOUBLE), CAST(cost AS DOUBLE), CAST(stock AS INT),
  status, launch_date
FROM ydsh_ods.cln_product;

-- ---------- 门店维度 ----------
INSERT OVERWRITE TABLE ydsh_dwd.dim_store
SELECT
  store_id, store_name, province, city, district, address,
  open_date, CAST(area AS DOUBLE), manager
FROM ydsh_ods.cln_store;

-- ---------- 订单事实：去重 + 支付编码映射 + 动态分区 ----------
INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_date)
SELECT
  t.order_id, t.user_id, t.store_id, t.order_timestamp,
  t.pay_amount, t.discount_amount, t.pay_type,
  COALESCE(p.pay_type_code, 5) AS pay_type_code,
  t.order_status, t.channel,
  t.order_date
FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_timestamp) AS rn
  FROM ydsh_ods.cln_order_final
) t
LEFT JOIN ydsh_dwd.dim_pay_type p
  ON t.pay_type = p.pay_type_name
WHERE t.rn = 1;

-- ---------- 订单明细事实 ----------
INSERT OVERWRITE TABLE ydsh_dwd.dwd_order_item
SELECT
  item_id, order_id, product_id, quantity, unit_price, discount
FROM ydsh_ods.cln_order_item;

-- ---------- 用户行为事实：按行为日期动态分区 ----------
INSERT OVERWRITE TABLE ydsh_dwd.dwd_user_behavior PARTITION (behavior_date)
SELECT
  behavior_id, user_id, product_id, behavior_type, behavior_time, session_id,
  substr(behavior_time, 1, 10) AS behavior_date
FROM ydsh_ods.cln_user_behavior;

-- ---------- 验证 ----------
SELECT 'dim_date' AS tbl, COUNT(*) AS cnt FROM ydsh_dwd.dim_date;
SELECT 'dim_user' AS tbl, COUNT(*) AS cnt FROM ydsh_dwd.dim_user;
SELECT 'dim_product' AS tbl, COUNT(*) AS cnt FROM ydsh_dwd.dim_product;
SELECT 'dim_store' AS tbl, COUNT(*) AS cnt FROM ydsh_dwd.dim_store;
SELECT 'dwd_order' AS tbl, COUNT(*) AS cnt FROM ydsh_dwd.dwd_order;
SELECT 'dwd_order_item' AS tbl, COUNT(*) AS cnt FROM ydsh_dwd.dwd_order_item;
SELECT 'dwd_user_behavior' AS tbl, COUNT(*) AS cnt FROM ydsh_dwd.dwd_user_behavior;
SHOW PARTITIONS ydsh_dwd.dwd_order;
SHOW PARTITIONS ydsh_dwd.dwd_user_behavior;
SELECT 'dwd_order重复order_id' AS item, COUNT(*) AS cnt FROM (
  SELECT order_id FROM ydsh_dwd.dwd_order GROUP BY order_id HAVING COUNT(*) > 1) dup;
