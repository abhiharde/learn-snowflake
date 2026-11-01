-- 05 | Micro-partition pruning and Query Profile
-- THEORY
-- Snowflake stores table data in micro-partitions and keeps metadata about them.
-- A selective predicate can prune partitions whose metadata proves they cannot
-- contain qualifying rows. Scattered values can make pruning less effective.
-- Warehouse resizing does not change pruning; clustering can help some large,
-- repeatedly queried tables but has maintenance and compute costs.

-- Create a synthetic table with dates interleaved across rows.
CREATE OR REPLACE TABLE LEARNING_DB.DATA_ENGINEERING.PRUNING_DEMO_LARGE AS
WITH generated_ids AS (
    SELECT SEQ4() AS ROW_ID
    FROM TABLE(GENERATOR(ROWCOUNT => 1000000))
)
SELECT
    ROW_ID,
    DATEADD(DAY, MOD(ROW_ID, 365), '2025-01-01'::DATE) AS ORDER_DATE,
    UNIFORM(10, 500, RANDOM())::NUMBER(10, 2) AS AMOUNT,
    SHA2(TO_VARCHAR(ROW_ID) || ':1', 256)
      || SHA2(TO_VARCHAR(ROW_ID) || ':2', 256)
      || SHA2(TO_VARCHAR(ROW_ID) || ':3', 256)
      || SHA2(TO_VARCHAR(ROW_ID) || ':4', 256) AS PAYLOAD
FROM generated_ids;

-- Query one date in the mixed-order table, then inspect TableScan in Query Profile.
SELECT ORDER_DATE, COUNT(*) AS ORDER_COUNT, SUM(AMOUNT) AS TOTAL_AMOUNT
FROM LEARNING_DB.DATA_ENGINEERING.PRUNING_DEMO_LARGE
WHERE ORDER_DATE = '2025-06-15'
GROUP BY ORDER_DATE;

-- Build a copy loaded in date order to compare partition pruning.
CREATE OR REPLACE TABLE LEARNING_DB.DATA_ENGINEERING.PRUNING_DEMO_ORDERED AS
SELECT ROW_ID, ORDER_DATE, AMOUNT
FROM LEARNING_DB.DATA_ENGINEERING.PRUNING_DEMO_LARGE
ORDER BY ORDER_DATE, ROW_ID;

-- Run the same predicate and compare partitions scanned/total in Query Profile.
SELECT ORDER_DATE, COUNT(*) AS ORDER_COUNT, SUM(AMOUNT) AS TOTAL_AMOUNT
FROM LEARNING_DB.DATA_ENGINEERING.PRUNING_DEMO_ORDERED
WHERE ORDER_DATE = '2025-06-15'
GROUP BY ORDER_DATE;

-- A smaller scan is evidence of pruning; cache percentage is a separate metric.
