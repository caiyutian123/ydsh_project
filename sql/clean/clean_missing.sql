-- ============================================================
-- 云购生活数仓项目 · 清洗脚本（一）—— 缺失值处理
-- 输出目标表：dwd_user / dwd_product
-- 策略：
--   ods_user.age       缺失/异常(<=0或>120) → 用有效年龄均值填充
--   ods_user.email     缺失 → 保留空并加标记列 email_missing_flag
--   ods_product.launch_date 缺失 → 用库内上架日期众数(最常见值)补全
-- ============================================================
USE ydsh_ods;

-- ---------- 用户表：缺失值处理 ----------
DROP TABLE IF EXISTS dwd_user;
CREATE TABLE dwd_user AS
SELECT
  user_id,
  user_name,
  gender,
  CASE WHEN age IS NULL OR age <= 0 OR age > 120
       THEN (SELECT CAST(ROUND(AVG(a.age)) AS INT)
             FROM ods_user a
             WHERE a.age IS NOT NULL AND a.age BETWEEN 1 AND 120)
       ELSE age END AS age,
  city,
  province,
  register_date,
  member_level,
  phone,
  CASE WHEN email IS NULL OR email = '' THEN '' ELSE email END AS email,
  CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END AS email_missing_flag
FROM ods_user;

-- 验证：清洗后 age 无空值、无负值、无超120
SELECT 'dwd_user.age 异常值数' AS item, COUNT(*) AS cnt
FROM dwd_user WHERE age IS NULL OR age <= 0 OR age > 120;
SELECT 'dwd_user 缺失邮箱行数(标记=1)' AS item, COUNT(*) AS cnt
FROM dwd_user WHERE email_missing_flag = 1;
SELECT 'dwd_user 总行数' AS item, COUNT(*) AS cnt FROM dwd_user;

-- ---------- 商品表：上架日期缺失补全（取库内众数） ----------
DROP TABLE IF EXISTS dwd_product;
CREATE TABLE dwd_product AS
SELECT
  product_id, product_name, category, sub_category, brand,
  price, cost, stock, status,
  CASE WHEN launch_date IS NULL OR launch_date = ''
       THEN (SELECT ld FROM (
                 SELECT launch_date AS ld, COUNT(*) AS c
                 FROM ods_product
                 WHERE launch_date IS NOT NULL AND launch_date <> ''
                 GROUP BY launch_date ORDER BY c DESC LIMIT 1) mode_t)
       ELSE launch_date END AS launch_date
FROM ods_product;

-- 验证
SELECT 'dwd_product 上架日期空值数' AS item, COUNT(*) AS cnt
FROM dwd_product WHERE launch_date IS NULL OR launch_date = '';
