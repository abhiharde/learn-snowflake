-- 01 | Snowflake architecture
-- THEORY
-- Snowflake separates storage, compute, and cloud services.
-- Storage holds compressed columnar micro-partitions and their metadata.
-- Virtual warehouses provide compute and can be scaled independently.
-- Cloud services coordinate metadata, authentication, optimization, and transactions.
-- Separate warehouses can isolate ingestion and reporting workloads.

-- Check the account, region, active role, and active warehouse for this session.
SELECT
    CURRENT_ACCOUNT() AS ACCOUNT_NAME,
    CURRENT_REGION() AS REGION,
    CURRENT_ROLE() AS ACTIVE_ROLE,
    CURRENT_WAREHOUSE() AS ACTIVE_WAREHOUSE;

-- Inspect the warehouse configuration without changing it.
SHOW WAREHOUSES LIKE 'COMPUTE_WH';
