-- 02 | Order events: deduplication and daily revenue
-- THEORY
-- Raw event tables preserve the incoming history. They can contain duplicate
-- deliveries, status changes, and late-arriving records.
-- Deduplicate by EVENT_ID first, then choose the latest event per ORDER_ID.
-- Filter for COMPLETED only after choosing the latest status; otherwise a
-- previously completed but later cancelled order could be counted incorrectly.

CREATE DATABASE IF NOT EXISTS LEARNING_DB;
CREATE SCHEMA IF NOT EXISTS LEARNING_DB.DATA_ENGINEERING;

-- Reset this small practice table and its sample data when starting the lesson.
CREATE OR REPLACE TABLE LEARNING_DB.DATA_ENGINEERING.RAW_ORDER_EVENTS (
    EVENT_ID VARCHAR,
    ORDER_ID VARCHAR,
    CUSTOMER_ID VARCHAR,
    STATUS VARCHAR,
    AMOUNT NUMBER(10, 2),
    EVENT_TS TIMESTAMP_NTZ,
    INGESTED_AT TIMESTAMP_NTZ
);

-- Seed duplicate, status-change, and late-arriving examples.
INSERT INTO LEARNING_DB.DATA_ENGINEERING.RAW_ORDER_EVENTS
    (EVENT_ID, ORDER_ID, CUSTOMER_ID, STATUS, AMOUNT, EVENT_TS, INGESTED_AT)
VALUES
    ('E001', 'O100', 'C001', 'COMPLETED', 120.00,
     '2026-10-30 09:00:00', '2026-10-30 09:01:00'),
    ('E001', 'O100', 'C001', 'COMPLETED', 120.00,
     '2026-10-30 09:00:00', '2026-10-30 09:05:00'),
    ('E002', 'O101', 'C002', 'COMPLETED', 80.00,
     '2026-10-30 10:00:00', '2026-10-30 10:02:00'),
    ('E003', 'O102', 'C001', 'PLACED', 50.00,
     '2026-10-30 11:00:00', '2026-10-30 11:01:00'),
    ('E004', 'O102', 'C001', 'CANCELLED', 50.00,
     '2026-10-30 11:30:00', '2026-10-30 11:31:00'),
    ('E005', 'O103', 'C003', 'COMPLETED', 200.00,
     '2026-10-31 08:00:00', '2026-10-31 08:02:00'),
    ('E006', 'O104', 'C002', 'COMPLETED', 100.00,
     '2026-10-31 09:00:00', '2026-11-01 07:00:00');

-- Inspect one latest-ingested copy per event identifier.
SELECT EVENT_ID, ORDER_ID, STATUS, EVENT_TS, INGESTED_AT
FROM LEARNING_DB.DATA_ENGINEERING.RAW_ORDER_EVENTS
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY EVENT_ID
    ORDER BY INGESTED_AT DESC
) = 1
ORDER BY EVENT_ID;

-- Calculate daily revenue from each order's latest event.
WITH deduplicated_events AS (
    SELECT
        EVENT_ID, ORDER_ID, CUSTOMER_ID, STATUS, AMOUNT, EVENT_TS, INGESTED_AT
    FROM LEARNING_DB.DATA_ENGINEERING.RAW_ORDER_EVENTS
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY EVENT_ID
        ORDER BY INGESTED_AT DESC
    ) = 1
),
latest_order_status AS (
    SELECT ORDER_ID, STATUS, AMOUNT, EVENT_TS, INGESTED_AT
    FROM deduplicated_events
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ORDER_ID
        ORDER BY EVENT_TS DESC, INGESTED_AT DESC, EVENT_ID DESC
    ) = 1
)
SELECT
    TO_DATE(EVENT_TS) AS ORDER_DATE,
    SUM(AMOUNT) AS DAILY_REVENUE
FROM latest_order_status
WHERE STATUS = 'COMPLETED'
GROUP BY TO_DATE(EVENT_TS)
ORDER BY ORDER_DATE;

-- Save the same logic as a reusable regular SQL view.
CREATE OR REPLACE VIEW LEARNING_DB.DATA_ENGINEERING.DAILY_ORDER_REVENUE AS
WITH deduplicated_events AS (
    SELECT
        EVENT_ID, ORDER_ID, CUSTOMER_ID, STATUS, AMOUNT, EVENT_TS, INGESTED_AT
    FROM LEARNING_DB.DATA_ENGINEERING.RAW_ORDER_EVENTS
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY EVENT_ID
        ORDER BY INGESTED_AT DESC
    ) = 1
),
latest_order_status AS (
    SELECT ORDER_ID, STATUS, AMOUNT, EVENT_TS, INGESTED_AT
    FROM deduplicated_events
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY ORDER_ID
        ORDER BY EVENT_TS DESC, INGESTED_AT DESC, EVENT_ID DESC
    ) = 1
)
SELECT
    TO_DATE(EVENT_TS) AS ORDER_DATE,
    SUM(AMOUNT) AS DAILY_REVENUE
FROM latest_order_status
WHERE STATUS = 'COMPLETED'
GROUP BY TO_DATE(EVENT_TS);

-- Verify the reusable view.
SELECT *
FROM LEARNING_DB.DATA_ENGINEERING.DAILY_ORDER_REVENUE
ORDER BY ORDER_DATE;
