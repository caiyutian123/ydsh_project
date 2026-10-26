-- ============================================================
-- 云购生活数仓项目 · ODS 层建表脚本
-- 库：ydsh_ods  |  6 张业务表
-- 约定：逗号分隔、跳过表头(skip.header.line.count='1')
-- ============================================================
USE ydsh_ods;

-- 1) 用户信息表
CREATE TABLE IF NOT EXISTS ods_user (
  user_id       STRING,
  user_name     STRING,
  gender        STRING,
  age           INT,
  city          STRING,
  province      STRING,
  register_date STRING,
  member_level  STRING,
  phone         STRING,
  email         STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');

-- 2) 商品信息表
CREATE TABLE IF NOT EXISTS ods_product (
  product_id    STRING,
  product_name  STRING,
  category      STRING,
  sub_category  STRING,
  brand         STRING,
  price         DOUBLE,
  cost          DOUBLE,
  stock         INT,
  status        STRING,
  launch_date   STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');

-- 3) 门店信息表
CREATE TABLE IF NOT EXISTS ods_store (
  store_id   STRING,
  store_name STRING,
  province   STRING,
  city       STRING,
  district   STRING,
  address    STRING,
  open_date  STRING,
  area       INT,
  manager    STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');

-- 4) 订单主表
CREATE TABLE IF NOT EXISTS ods_order (
  order_id         STRING,
  user_id          STRING,
  store_id         STRING,
  order_date       STRING,
  order_time       STRING,
  pay_amount       DOUBLE,
  discount_amount  DOUBLE,
  pay_type         STRING,
  order_status     STRING,
  channel          STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');

-- 5) 订单明细表
CREATE TABLE IF NOT EXISTS ods_order_item (
  item_id    STRING,
  order_id   STRING,
  product_id STRING,
  quantity   INT,
  unit_price DOUBLE,
  discount   DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');

-- 6) 用户行为日志表
CREATE TABLE IF NOT EXISTS ods_user_behavior (
  behavior_id    STRING,
  user_id        STRING,
  product_id     STRING,
  behavior_type  STRING,
  behavior_time  STRING,
  session_id     STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');
