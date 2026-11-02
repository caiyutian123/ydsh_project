-- ============================================================
-- 云购生活数仓项目 · 第2周清洗（二）—— 枚举字段标准化（子任务1）
-- 输入：ydsh_ods.ods_*
-- 输出：ydsh_ods.stg_*（枚举已统一、表头行已剔除、category 已去空格）
-- 规范值域（统一为中文标准值）：
--   gender        → 男 / 女 / 未知
--   member_level  → 普通会员 / 银卡会员 / 金卡会员 / 钻石会员
--   pay_type      → 微信支付 / 支付宝 / 银行卡 / 货到付款 / 其他
--   order_status  → 已完成 / 已支付 / 待支付 / 退款中 / 已取消
--   channel       → APP / PC官网 / 小程序 / 门店
--   behavior_type → 浏览 / 加购 / 收藏 / 购买
-- 说明：映射统一按 lower(取值) 匹配，覆盖中英文与大小写脏值；
--      ODS 各表第 1 行为 csv 表头，stg 层一律剔除。
-- ============================================================
USE ydsh_ods;

-- ---------- 用户表：gender / member_level ----------
DROP TABLE IF EXISTS stg_user;
CREATE TABLE stg_user AS
SELECT
  user_id, user_name,
  CASE WHEN lower(gender) IN ('男','m','male') THEN '男'
       WHEN lower(gender) IN ('女','f','female') THEN '女'
       ELSE '未知' END AS gender,
  age, city, province, register_date,
  CASE WHEN lower(member_level) IN ('金卡会员','gold','金卡') THEN '金卡会员'
       WHEN lower(member_level) IN ('银卡会员','silver','银卡') THEN '银卡会员'
       WHEN lower(member_level) IN ('钻石会员','钻石') THEN '钻石会员'
       ELSE '普通会员' END AS member_level,
  phone, email
FROM ods_user
WHERE user_id <> 'user_id';

-- ---------- 商品表：category 去首尾空格（brand 扫描无空格/大小写脏值，仍做防御性 trim） ----------
DROP TABLE IF EXISTS stg_product;
CREATE TABLE stg_product AS
SELECT
  product_id, trim(product_name) AS product_name,
  trim(category) AS category, trim(sub_category) AS sub_category,
  trim(brand) AS brand,
  price, cost, stock, trim(status) AS status, launch_date
FROM ods_product
WHERE product_id <> 'product_id';

-- ---------- 门店表：文本字段防御性 trim ----------
DROP TABLE IF EXISTS stg_store;
CREATE TABLE stg_store AS
SELECT
  store_id, trim(store_name) AS store_name, trim(province) AS province,
  trim(city) AS city, trim(district) AS district, trim(address) AS address,
  open_date, area, trim(manager) AS manager
FROM ods_store
WHERE store_id <> 'store_id';

-- ---------- 订单表：pay_type / order_status / channel ----------
DROP TABLE IF EXISTS stg_order;
CREATE TABLE stg_order AS
SELECT
  order_id, user_id, store_id, order_date, order_time, pay_amount, discount_amount,
  CASE WHEN lower(pay_type) IN ('微信支付','微信','wechat') THEN '微信支付'
       WHEN lower(pay_type) IN ('支付宝','alipay') THEN '支付宝'
       WHEN pay_type = '银行卡' THEN '银行卡'
       WHEN pay_type = '货到付款' THEN '货到付款'
       ELSE '其他' END AS pay_type,
  CASE WHEN order_status IN ('1','完成','已完成') THEN '已完成'
       WHEN order_status IN ('已支付','已付款') THEN '已支付'
       WHEN order_status IN ('2','待支付') THEN '待支付'
       WHEN order_status IN ('3','退款中') THEN '退款中'
       WHEN lower(order_status) IN ('4','cancelled','已取消') THEN '已取消'
       ELSE '未知' END AS order_status,
  CASE WHEN lower(channel) = 'app' THEN 'APP'
       WHEN lower(channel) IN ('pc','pc官网') THEN 'PC官网'
       WHEN channel = '小程序' THEN '小程序'
       WHEN channel = '门店' THEN '门店'
       ELSE '其他' END AS channel
FROM ods_order
WHERE order_id <> 'order_id';

-- ---------- 订单明细表：无枚举字段，仅剔除表头 ----------
DROP TABLE IF EXISTS stg_order_item;
CREATE TABLE stg_order_item AS
SELECT item_id, order_id, product_id, quantity, unit_price, discount
FROM ods_order_item
WHERE item_id <> 'item_id';

-- ---------- 用户行为表：behavior_type ----------
DROP TABLE IF EXISTS stg_user_behavior;
CREATE TABLE stg_user_behavior AS
SELECT
  behavior_id, user_id, product_id,
  CASE WHEN lower(behavior_type) IN ('pv','浏览') THEN '浏览'
       WHEN lower(behavior_type) IN ('cart','加购') THEN '加购'
       WHEN lower(behavior_type) IN ('fav','收藏') THEN '收藏'
       WHEN lower(behavior_type) IN ('buy','购买') THEN '购买'
       ELSE '其他' END AS behavior_type,
  behavior_time, session_id
FROM ods_user_behavior
WHERE behavior_id <> 'behavior_id';

-- ---------- 验证：清洗后取值应收敛到规范值域 ----------
SELECT 'gender' AS field, gender AS val, COUNT(*) AS cnt FROM stg_user GROUP BY gender;
SELECT 'member_level' AS field, member_level AS val, COUNT(*) AS cnt FROM stg_user GROUP BY member_level;
SELECT 'pay_type' AS field, pay_type AS val, COUNT(*) AS cnt FROM stg_order GROUP BY pay_type;
SELECT 'order_status' AS field, order_status AS val, COUNT(*) AS cnt FROM stg_order GROUP BY order_status;
SELECT 'channel' AS field, channel AS val, COUNT(*) AS cnt FROM stg_order GROUP BY channel;
SELECT 'behavior_type' AS field, behavior_type AS val, COUNT(*) AS cnt FROM stg_user_behavior GROUP BY behavior_type;
SELECT 'category' AS field, category AS val, COUNT(*) AS cnt FROM stg_product GROUP BY category;
