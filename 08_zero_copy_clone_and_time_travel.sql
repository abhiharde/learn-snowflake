-- 08 | Zero-copy cloning and Time Travel
-- THEORY
-- A clone is created quickly by sharing existing micro-partition data initially.
-- Subsequent changes to source and clone are independent; changed data can add storage.
-- Time Travel can query an earlier version or create a separate recovered copy,
-- subject to the object's retention period and privileges.
-- Avoid replacing production tables during recovery; inspect or clone first.

-- Create an independent practice clone.
CREATE TABLE LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS_CLONE
    CLONE LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS;

-- Change only the clone.
UPDATE LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS_CLONE
SET STATUS = 'TEST_ONLY'
WHERE ORDER_ID = 'O100';

-- Compare source and clone to confirm isolation.
SELECT 'SOURCE' AS TABLE_NAME, ORDER_ID, STATUS
FROM LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS
WHERE ORDER_ID = 'O100'
UNION ALL
SELECT 'CLONE' AS TABLE_NAME, ORDER_ID, STATUS
FROM LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS_CLONE
WHERE ORDER_ID = 'O100';

-- Find the UPDATE statement's query ID in Query History.
SELECT QUERY_ID, START_TIME, QUERY_TEXT
FROM TABLE(LEARNING_DB.INFORMATION_SCHEMA.QUERY_HISTORY(RESULT_LIMIT => 100))
WHERE QUERY_TEXT ILIKE '%TEST_ONLY%'
  AND QUERY_TEXT ILIKE '%CURRENT_ORDERS_CLONE%'
ORDER BY START_TIME DESC;

-- Replace the placeholder below with the UPDATE query ID from your account.
-- Query the clone as it existed before that update.
-- SELECT ORDER_ID, STATUS
-- FROM LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS_CLONE
-- BEFORE (STATEMENT => '<UPDATE_QUERY_ID>')
-- WHERE ORDER_ID = 'O100';

-- Optional: create a distinct recovered table rather than overwriting the clone.
-- Replace the placeholder with the same UPDATE query ID.
-- CREATE TABLE LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS_RECOVERED
--     CLONE LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS_CLONE
--     BEFORE (STATEMENT => '<UPDATE_QUERY_ID>');
