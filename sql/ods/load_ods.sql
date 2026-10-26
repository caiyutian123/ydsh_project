-- ============================================================
-- 云购生活数仓项目 · ODS 层数据导入脚本
-- 数据挂载于 hive-server 容器 /data 目录
-- ============================================================
USE ydsh_ods;

LOAD DATA LOCAL INPATH '/data/ods_user.csv'          INTO TABLE ods_user;
LOAD DATA LOCAL INPATH '/data/ods_product.csv'       INTO TABLE ods_product;
LOAD DATA LOCAL INPATH '/data/ods_store.csv'         INTO TABLE ods_store;
LOAD DATA LOCAL INPATH '/data/ods_order.csv'         INTO TABLE ods_order;
LOAD DATA LOCAL INPATH '/data/ods_order_item.csv'    INTO TABLE ods_order_item;
LOAD DATA LOCAL INPATH '/data/ods_user_behavior.csv' INTO TABLE ods_user_behavior;

-- 行数校验（与数据字典预期对比）
SELECT 'ods_user'          AS tbl, COUNT(*) AS cnt FROM ods_user
UNION ALL SELECT 'ods_product', COUNT(*) FROM ods_product
UNION ALL SELECT 'ods_store',   COUNT(*) FROM ods_store
UNION ALL SELECT 'ods_order',   COUNT(*) FROM ods_order
UNION ALL SELECT 'ods_order_item', COUNT(*) FROM ods_order_item
UNION ALL SELECT 'ods_user_behavior', COUNT(*) FROM ods_user_behavior;
