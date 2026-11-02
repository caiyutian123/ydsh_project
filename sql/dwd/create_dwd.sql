-- ============================================================
-- 云购生活数仓项目 · DWD 层建模 DDL（子任务6）
-- 库：ydsh_dwd（另建 ydsh_dws / ydsh_ads 空库，支撑四层架构）
-- 维度表：dim_user / dim_product / dim_store / dim_date
-- 事实表：dwd_order（按 order_date 分区）
--         dwd_order_item（按 order_id 分 8 桶）
--         dwd_user_behavior（按 behavior_date 分区）
-- 存储格式：ORC（列式存储，支撑分析型查询）
-- ============================================================

CREATE DATABASE IF NOT EXISTS ydsh_dwd;
CREATE DATABASE IF NOT EXISTS ydsh_dws;
CREATE DATABASE IF NOT EXISTS ydsh_ads;

USE ydsh_dwd;

-- ---------- 用户维度表 ----------
DROP TABLE IF EXISTS dim_user;
CREATE TABLE dim_user (
  user_id           STRING COMMENT '用户ID',
  user_name         STRING COMMENT '用户名',
  gender            STRING COMMENT '性别(男/女/未知)',
  age               INT    COMMENT '年龄',
  province          STRING COMMENT '省份',
  city              STRING COMMENT '城市',
  region            STRING COMMENT '地区(省份-城市)',
  register_date     STRING COMMENT '注册日期',
  member_level      STRING COMMENT '会员等级名称',
  member_level_code INT    COMMENT '会员等级编码',
  phone             STRING COMMENT '手机号',
  email             STRING COMMENT '邮箱'
) COMMENT '用户维度表'
STORED AS ORC;

-- ---------- 商品维度表 ----------
DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
  product_id   STRING COMMENT '商品ID',
  product_name STRING COMMENT '商品名称',
  category     STRING COMMENT '一级品类',
  sub_category STRING COMMENT '二级品类',
  brand        STRING COMMENT '品牌',
  price        DOUBLE COMMENT '售价',
  cost         DOUBLE COMMENT '成本',
  stock        INT    COMMENT '库存',
  status       STRING COMMENT '状态',
  launch_date  STRING COMMENT '上架日期'
) COMMENT '商品维度表'
STORED AS ORC;

-- ---------- 门店维度表 ----------
DROP TABLE IF EXISTS dim_store;
CREATE TABLE dim_store (
  store_id   STRING COMMENT '门店ID',
  store_name STRING COMMENT '门店名称',
  province   STRING COMMENT '省份',
  city       STRING COMMENT '城市',
  district   STRING COMMENT '区县',
  address    STRING COMMENT '详细地址',
  open_date  STRING COMMENT '开业日期',
  area       DOUBLE COMMENT '面积(㎡)',
  manager    STRING COMMENT '店长'
) COMMENT '门店维度表'
STORED AS ORC;

-- ---------- 日期维度表 ----------
DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date (
  date_id      INT    COMMENT '日期ID(yyyyMMdd)',
  date_str     STRING COMMENT '日期(yyyy-MM-dd)',
  year         INT    COMMENT '年',
  quarter      INT    COMMENT '季度',
  month        INT    COMMENT '月',
  day          INT    COMMENT '日',
  week_of_year INT    COMMENT '年内第几周',
  day_of_week  INT    COMMENT '星期(1=周一..7=周日)',
  is_weekend   INT    COMMENT '是否周末(0/1)'
) COMMENT '日期维度表'
STORED AS ORC;

-- ---------- 订单事实表（按下单日期分区） ----------
DROP TABLE IF EXISTS dwd_order;
CREATE TABLE dwd_order (
  order_id        STRING COMMENT '订单ID',
  user_id         STRING COMMENT '用户ID',
  store_id        STRING COMMENT '门店ID',
  order_timestamp STRING COMMENT '下单时间戳(yyyy-MM-dd HH:mm:ss)',
  pay_amount      DOUBLE COMMENT '实付金额',
  discount_amount DOUBLE COMMENT '优惠金额',
  pay_type        STRING COMMENT '支付方式',
  pay_type_code   INT    COMMENT '支付方式编码',
  order_status    STRING COMMENT '订单状态',
  channel         STRING COMMENT '下单渠道'
) COMMENT '订单事实表'
PARTITIONED BY (order_date STRING COMMENT '下单日期')
STORED AS ORC;

-- ---------- 订单明细事实表（按 order_id 分 8 桶，优化 JOIN） ----------
DROP TABLE IF EXISTS dwd_order_item;
CREATE TABLE dwd_order_item (
  item_id    STRING COMMENT '明细ID',
  order_id   STRING COMMENT '订单ID',
  product_id STRING COMMENT '商品ID',
  quantity   INT    COMMENT '购买数量',
  unit_price DOUBLE COMMENT '成交单价',
  discount   DOUBLE COMMENT '明细优惠'
) COMMENT '订单明细事实表'
CLUSTERED BY (order_id) INTO 8 BUCKETS
STORED AS ORC;

-- ---------- 用户行为事实表（按行为日期分区） ----------
DROP TABLE IF EXISTS dwd_user_behavior;
CREATE TABLE dwd_user_behavior (
  behavior_id   STRING COMMENT '行为ID',
  user_id       STRING COMMENT '用户ID',
  product_id    STRING COMMENT '商品ID',
  behavior_type STRING COMMENT '行为类型(浏览/加购/收藏/购买)',
  behavior_time STRING COMMENT '行为时间',
  session_id    STRING COMMENT '会话ID'
) COMMENT '用户行为事实表'
PARTITIONED BY (behavior_date STRING COMMENT '行为日期')
STORED AS ORC;

SHOW TABLES;
