-- ============================================================
-- 云购生活数仓项目 · 第2周清洗（四）—— 字段拆分合并 + 编码映射（子任务3）
-- 输入：ydsh_ods.cln_*
-- 输出：
--   ydsh_ods.cln_order_final  —— 合并 order_date + order_time → order_timestamp
--   ydsh_dwd.dim_member_level —— 会员等级编码映射
--   ydsh_dwd.dim_pay_type     —— 支付方式编码映射
-- ============================================================

-- ---------- 1. 订单日期时间合并 ----------
USE ydsh_ods;

DROP TABLE IF EXISTS cln_order_final;
CREATE TABLE cln_order_final AS
SELECT
  order_id, user_id, store_id, order_date, order_time,
  concat(order_date, ' ', order_time) AS order_timestamp,
  pay_amount, discount_amount, pay_type, order_status, channel
FROM cln_order;

-- 验证
SELECT 'cln_order_final行数' AS item, COUNT(*) AS cnt FROM cln_order_final;
SELECT 'order_timestamp样例' AS item, order_timestamp AS val FROM cln_order_final LIMIT 5;

-- ---------- 2. 编码映射表（建到 DWD 库） ----------
CREATE DATABASE IF NOT EXISTS ydsh_dwd;
USE ydsh_dwd;

-- 会员等级编码映射
DROP TABLE IF EXISTS dim_member_level;
CREATE TABLE dim_member_level (
  level_code INT COMMENT '等级编码',
  level_name STRING COMMENT '等级名称'
) COMMENT '会员等级编码映射表'
STORED AS ORC;

INSERT INTO dim_member_level VALUES
  (1, '普通会员'),
  (2, '银卡会员'),
  (3, '金卡会员'),
  (4, '钻石会员');

-- 支付方式编码映射
DROP TABLE IF EXISTS dim_pay_type;
CREATE TABLE dim_pay_type (
  pay_type_code INT COMMENT '支付方式编码',
  pay_type_name STRING COMMENT '支付方式名称'
) COMMENT '支付方式编码映射表'
STORED AS ORC;

INSERT INTO dim_pay_type VALUES
  (1, '微信支付'),
  (2, '支付宝'),
  (3, '银行卡'),
  (4, '货到付款'),
  (5, '其他');

-- 验证
SELECT 'dim_member_level' AS tbl, level_code, level_name FROM dim_member_level;
SELECT 'dim_pay_type' AS tbl, pay_type_code, pay_type_name FROM dim_pay_type;
