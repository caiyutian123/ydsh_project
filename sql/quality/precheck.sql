-- ============================================================
-- 云购生活数仓项目 · 数据质量五维度预评估
-- 维度：完整性 / 唯一性 / 有效性 / 一致性 / 准确性
-- 输出各表空值数、重复数、异常取值分布，作为《数据质量预评估表》依据
-- ============================================================
USE ydsh_ods;

-- ---------- 1. 完整性：空值率扫描（示例：用户表 / 商品表 / 订单表） ----------
-- 用户表：age、email 存在缺失
SELECT 'ods_user.age'   AS col, COUNT(*) AS total,
       SUM(CASE WHEN age IS NULL OR age='' THEN 1 ELSE 0 END) AS null_cnt,
       ROUND(SUM(CASE WHEN age IS NULL OR age='' THEN 1 ELSE 0 END)/COUNT(*),4) AS null_rate
FROM ods_user;

SELECT 'ods_user.email' AS col, COUNT(*) AS total,
       SUM(CASE WHEN email IS NULL OR email='' THEN 1 ELSE 0 END) AS null_cnt
FROM ods_user;

-- 商品表：launch_date 存在缺失
SELECT 'ods_product.launch_date' AS col, COUNT(*) AS total,
       SUM(CASE WHEN launch_date IS NULL OR launch_date='' THEN 1 ELSE 0 END) AS null_cnt
FROM ods_product;

-- 订单表：pay_amount 空值
SELECT 'ods_order.pay_amount' AS col, COUNT(*) AS total,
       SUM(CASE WHEN pay_amount IS NULL OR pay_amount='' THEN 1 ELSE 0 END) AS null_cnt
FROM ods_order;

-- ---------- 2. 唯一性：主键重复扫描 ----------
-- 订单表：order_id 重复（含"整行重复"与"主键重复内容不同"两类）
SELECT 'ods_order.order_id 重复数(按主键)' AS item,
       COUNT(*) AS dup_key_groups,
       SUM(c)  AS dup_rows_total
FROM (SELECT order_id, COUNT(*) c FROM ods_order GROUP BY order_id HAVING COUNT(*)>1) t;

-- 用户行为日志表：behavior_id 重复
SELECT 'ods_user_behavior.behavior_id 重复' AS item, COUNT(*) AS dup_cnt
FROM (SELECT behavior_id, COUNT(*) c FROM ods_user_behavior GROUP BY behavior_id HAVING COUNT(*)>1) t;

-- ---------- 3. 有效性：枚举取值合法性 ----------
SELECT 'order_status 取值分布' AS item, order_status AS val, COUNT(*) AS cnt
FROM ods_order GROUP BY order_status ORDER BY cnt DESC;

SELECT 'pay_type 取值分布' AS item, pay_type AS val, COUNT(*) AS cnt
FROM ods_order GROUP BY pay_type ORDER BY cnt DESC;

SELECT 'behavior_type 取值分布' AS item, behavior_type AS val, COUNT(*) AS cnt
FROM ods_user_behavior GROUP BY behavior_type ORDER BY cnt DESC;

SELECT 'gender 取值分布' AS item, gender AS val, COUNT(*) AS cnt
FROM ods_user GROUP BY gender ORDER BY cnt DESC;

-- ---------- 4. 一致性：格式是否统一（日期格式 / 大小写混用） ----------
-- 注册日期格式分布：预期统一为 YYYY-MM-DD
SELECT 'register_date 非标准格式(YYYY-MM-DD以外)数量' AS item, COUNT(*) AS cnt
FROM ods_user
WHERE register_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

-- 手机号格式：存在 138-9212-7520 带横线形式
SELECT 'phone 非11位纯数字数量' AS item, COUNT(*) AS cnt
FROM ods_user WHERE phone <> '' AND phone NOT REGEXP '^[0-9]{11}$';

-- channel 大小写混用
SELECT 'channel 取值分布' AS item, channel AS val, COUNT(*) AS cnt
FROM ods_order GROUP BY channel ORDER BY cnt DESC;

-- ---------- 5. 准确性：取值是否合理（范围 / 正负 / 超界） ----------
-- 年龄：负值 / 超120
SELECT 'age 异常(<=0 或 >120)' AS item, COUNT(*) AS cnt FROM ods_user
WHERE age IS NOT NULL AND (age <= 0 OR age > 120);

-- 实付金额：负数 / 超大(>100万)
SELECT 'pay_amount 负数' AS item, COUNT(*) AS cnt FROM ods_order WHERE pay_amount < 0;
SELECT 'pay_amount 超大(>5000000)' AS item, COUNT(*) AS cnt FROM ods_order WHERE pay_amount > 5000000;

-- 商品价格：负数
SELECT 'price 负数' AS item, COUNT(*) AS cnt FROM ods_product WHERE price < 0;

-- 明细数量：0 / 负 / 超大
SELECT 'quantity 异常(<=0 或 >50)' AS item, COUNT(*) AS cnt FROM ods_order_item
WHERE quantity <= 0 OR quantity > 50;
