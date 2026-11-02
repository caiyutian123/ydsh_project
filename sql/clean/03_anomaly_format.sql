-- ============================================================
-- 云购生活数仓项目 · 第2周清洗（三）—— 异常值处理 + 格式标准化（子任务2、3）
-- 输入：ydsh_ods.stg_*（枚举已标准化）
-- 输出：ydsh_ods.cln_*
-- 规则：
--   age          空/<=0/>120 → 有效年龄均值
--   pay_amount   <0 → 取绝对值；>10000 → 删除该订单行
--   discount_amount <0 → 取绝对值；>pay_amount → 置为等于 pay_amount
--   quantity     <=0 → 删除明细行
--   unit_price   <0 → 取绝对值
--   register_date / order_date 统一为 yyyy-MM-dd（'/'→'-'；yyyymmdd→yyyy-MM-dd）
--   phone        去除 '-'
--   behavior_time 长度16(缺秒) → 补 ':00'
--   launch_date  缺失 → 库内众数
-- ============================================================
USE ydsh_ods;

-- ---------- 用户表：age 异常 → 均值填充；phone 去 '-'；register_date 统一格式 ----------
DROP TABLE IF EXISTS cln_user;
CREATE TABLE cln_user AS
SELECT
  user_id, user_name, gender,
  CASE WHEN age IS NULL OR CAST(age AS INT) <= 0 OR CAST(age AS INT) > 120
       THEN (SELECT CAST(ROUND(AVG(CAST(a.age AS DOUBLE))) AS INT)
             FROM stg_user a
             WHERE a.age IS NOT NULL AND CAST(a.age AS INT) BETWEEN 1 AND 120)
       ELSE CAST(age AS INT) END AS age,
  city, province,
  CASE WHEN register_date RLIKE '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
         THEN regexp_replace(register_date, '/', '-')
       WHEN register_date RLIKE '^[0-9]{8}$'
         THEN concat(substr(register_date,1,4),'-',substr(register_date,5,2),'-',substr(register_date,7,2))
       ELSE register_date END AS register_date,
  member_level,
  regexp_replace(phone, '-', '') AS phone,
  email
FROM stg_user;

-- ---------- 商品表：launch_date 缺失 → 众数补全 ----------
DROP TABLE IF EXISTS cln_product;
CREATE TABLE cln_product AS
SELECT
  product_id, product_name, category, sub_category, brand, price, cost, stock, status,
  CASE WHEN launch_date IS NULL OR launch_date = ''
       THEN (SELECT ld FROM (
               SELECT launch_date AS ld, COUNT(*) AS c
               FROM stg_product
               WHERE launch_date IS NOT NULL AND launch_date <> ''
               GROUP BY launch_date ORDER BY c DESC LIMIT 1) mode_t)
       ELSE launch_date END AS launch_date
FROM stg_product;

-- ---------- 门店表：直接转储（扫描无异常） ----------
DROP TABLE IF EXISTS cln_store;
CREATE TABLE cln_store AS SELECT * FROM stg_store;

-- ---------- 订单表：金额异常处理 + order_date 格式统一 ----------
-- 步骤1：先处理负值与日期格式
DROP TABLE IF EXISTS cln_order_tmp;
CREATE TABLE cln_order_tmp AS
SELECT
  order_id, user_id, store_id,
  CASE WHEN order_date RLIKE '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
         THEN regexp_replace(order_date, '/', '-')
       WHEN order_date RLIKE '^[0-9]{8}$'
         THEN concat(substr(order_date,1,4),'-',substr(order_date,5,2),'-',substr(order_date,7,2))
       ELSE order_date END AS order_date,
  order_time,
  CASE WHEN CAST(pay_amount AS DOUBLE) < 0 THEN ABS(CAST(pay_amount AS DOUBLE))
       ELSE CAST(pay_amount AS DOUBLE) END AS pay_amount,
  CAST(discount_amount AS DOUBLE) AS discount_amount,
  pay_type, order_status, channel
FROM stg_order;

-- 步骤2：discount 负值取绝对值、超过 pay_amount 置为 pay_amount；删除 pay_amount>10000 的订单
DROP TABLE IF EXISTS cln_order;
CREATE TABLE cln_order AS
SELECT
  order_id, user_id, store_id, order_date, order_time, pay_amount,
  CASE WHEN ABS(discount_amount) > pay_amount THEN pay_amount
       ELSE ABS(discount_amount) END AS discount_amount,
  pay_type, order_status, channel
FROM cln_order_tmp
WHERE pay_amount <= 10000;

DROP TABLE IF EXISTS cln_order_tmp;

-- ---------- 订单明细表：quantity<=0 删除；unit_price<0 取绝对值 ----------
DROP TABLE IF EXISTS cln_order_item;
CREATE TABLE cln_order_item AS
SELECT
  item_id, order_id, product_id,
  CAST(quantity AS INT) AS quantity,
  ABS(CAST(unit_price AS DOUBLE)) AS unit_price,
  CAST(discount AS DOUBLE) AS discount
FROM stg_order_item
WHERE CAST(quantity AS INT) > 0;

-- ---------- 用户行为表：behavior_time 缺秒补 ':00' ----------
DROP TABLE IF EXISTS cln_user_behavior;
CREATE TABLE cln_user_behavior AS
SELECT
  behavior_id, user_id, product_id, behavior_type,
  CASE WHEN length(behavior_time) = 16 THEN concat(behavior_time, ':00')
       ELSE behavior_time END AS behavior_time,
  session_id
FROM stg_user_behavior;

-- ---------- 验证：清洗后不应再有异常 ----------
SELECT 'age异常' AS item, COUNT(*) AS cnt FROM cln_user WHERE age IS NULL OR age <= 0 OR age > 120;
SELECT 'phone带横杠' AS item, COUNT(*) AS cnt FROM cln_user WHERE phone LIKE '%-%';
SELECT 'register_date非标准' AS item, COUNT(*) AS cnt FROM cln_user WHERE register_date NOT RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';
SELECT 'launch_date空' AS item, COUNT(*) AS cnt FROM cln_product WHERE launch_date IS NULL OR launch_date = '';
SELECT 'pay_amount负' AS item, COUNT(*) AS cnt FROM cln_order WHERE pay_amount < 0;
SELECT 'pay_amount超万' AS item, COUNT(*) AS cnt FROM cln_order WHERE pay_amount > 10000;
SELECT 'discount负' AS item, COUNT(*) AS cnt FROM cln_order WHERE discount_amount < 0;
SELECT 'discount超pay' AS item, COUNT(*) AS cnt FROM cln_order WHERE discount_amount > pay_amount;
SELECT 'order_date非标准' AS item, COUNT(*) AS cnt FROM cln_order WHERE order_date NOT RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';
SELECT 'quantity非正' AS item, COUNT(*) AS cnt FROM cln_order_item WHERE quantity <= 0;
SELECT 'unit_price负' AS item, COUNT(*) AS cnt FROM cln_order_item WHERE unit_price < 0;
SELECT 'behavior_time缺秒' AS item, COUNT(*) AS cnt FROM cln_user_behavior WHERE length(behavior_time) = 16;
SELECT 'cln_user行数' AS item, COUNT(*) AS cnt FROM cln_user;
SELECT 'cln_order行数' AS item, COUNT(*) AS cnt FROM cln_order;
SELECT 'cln_order_item行数' AS item, COUNT(*) AS cnt FROM cln_order_item;
SELECT 'cln_user_behavior行数' AS item, COUNT(*) AS cnt FROM cln_user_behavior;
