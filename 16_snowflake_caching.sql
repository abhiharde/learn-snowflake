-- 16 | Snowflake caching
-- THEORY
-- Persisted query results may be reused when Snowflake's eligibility rules are met.
-- A result-cache reuse can avoid executing the query plan and scanning table data.
-- The warehouse data cache can reduce storage reads for a running warehouse;
-- suspending a warehouse clears its local cache.
-- Query Profile indicators are distinct: a TableScan with 0% cache is not a
-- persisted-result reuse. Cache behavior can vary, so verify in Query Details.

-- Run once, then run the exact same query again without changing the source table.
SELECT
    CUSTOMER_ID,
    COUNT(*) AS ORDER_COUNT,
    SUM(AMOUNT) AS TOTAL_SPEND
FROM LEARNING_DB.DATA_ENGINEERING.CSV_ORDERS
GROUP BY CUSTOMER_ID
ORDER BY CUSTOMER_ID;

-- Inspect the second query's details/profile for a result-reuse indicator.
-- If a TableScan appears, review percentage scanned from cache separately.
