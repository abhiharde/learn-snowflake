-- 13 | Dynamic Tables
-- THEORY
-- A Dynamic Table stores the result of a defining SELECT and refreshes it to
-- meet a target lag. Snowflake manages the refresh pipeline.
-- Streams and Tasks provide explicit change-processing and orchestration logic.
-- Dynamic Table refresh mode determines how Snowflake refreshes the result.
-- A manual REFRESH can be requested for practice. SCHEDULER = DISABLE stops
-- automatic scheduling while leaving the table available for queries.

-- Source table CSV_ORDERS is created and loaded in 11_stages_copy_into_csv.sql.
CREATE OR REPLACE DYNAMIC TABLE LEARNING_DB.DATA_ENGINEERING.CUSTOMER_SALES_DT
    TARGET_LAG = '1 day'
    WAREHOUSE = COMPUTE_WH
AS
SELECT
    CUSTOMER_ID,
    COUNT(*) AS ORDER_COUNT,
    SUM(AMOUNT) AS TOTAL_SPEND
FROM LEARNING_DB.DATA_ENGINEERING.CSV_ORDERS
GROUP BY CUSTOMER_ID;

-- Inspect the customer summary.
SELECT CUSTOMER_ID, ORDER_COUNT, TOTAL_SPEND
FROM LEARNING_DB.DATA_ENGINEERING.CUSTOMER_SALES_DT
ORDER BY CUSTOMER_ID;

-- Example source change; execute once if practicing incremental refresh.
-- INSERT INTO LEARNING_DB.DATA_ENGINEERING.CSV_ORDERS
--     (ORDER_ID, CUSTOMER_ID, AMOUNT, ORDER_TS)
-- VALUES ('O204', 'C010', 30.00, '2026-11-01 10:00:00');

-- Manually refresh after a source change, then query the Dynamic Table again.
-- ALTER DYNAMIC TABLE LEARNING_DB.DATA_ENGINEERING.CUSTOMER_SALES_DT REFRESH;

-- Disable automatic refreshes after practice if you do not need them.
-- ALTER DYNAMIC TABLE LEARNING_DB.DATA_ENGINEERING.CUSTOMER_SALES_DT
--     SET SCHEDULER = DISABLE;
