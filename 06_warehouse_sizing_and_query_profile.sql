-- 06 | Warehouse sizing and Query Profile diagnosis
-- THEORY
-- A larger warehouse provides more compute to an individual workload.
-- Multi-cluster warehouses are primarily a concurrency scaling option.
-- Diagnose the bottleneck before resizing: execution time, queued time, bytes,
-- partitions, and cache are different signals. More compute can cost more credits.
-- This lesson only inspects the warehouse; it does not resize or schedule it.

-- Inspect size, state, auto-suspend, and auto-resume.
SHOW WAREHOUSES LIKE 'COMPUTE_WH';

-- Review recent pruning-demo query timing and byte metrics.
-- Partition counts are inspected in each query's Query Profile, not this function.
SELECT
    START_TIME,
    QUERY_TEXT,
    WAREHOUSE_SIZE,
    EXECUTION_TIME / 1000 AS EXECUTION_SECONDS,
    QUEUED_OVERLOAD_TIME / 1000 AS QUEUED_SECONDS,
    BYTES_SCANNED
FROM TABLE(LEARNING_DB.INFORMATION_SCHEMA.QUERY_HISTORY(
    END_TIME_RANGE_START => DATEADD('hour', -2, CURRENT_TIMESTAMP()),
    RESULT_LIMIT => 100
))
WHERE QUERY_TEXT ILIKE '%PRUNING_DEMO%'
ORDER BY START_TIME DESC;

-- In Query Profile, compare partitions scanned/total and check for queue time.
