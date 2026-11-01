-- 04 | Streams and Tasks: process order events into current state
-- THEORY
-- A standard stream records table changes using an offset. Changes remain
-- available until a transaction that consumes the stream commits.
-- A task runs SQL using a warehouse. EXECUTE TASK can manually run a standalone
-- task without resuming it; RESUME is for scheduled/triggered task operation.
-- Keep raw event history and MERGE into a curated current-state table.
-- This example expects RAW_ORDER_EVENTS from 02_order_events_dedup_and_revenue.sql.

CREATE TABLE IF NOT EXISTS LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS (
    EVENT_ID VARCHAR,
    ORDER_ID VARCHAR,
    CUSTOMER_ID VARCHAR,
    STATUS VARCHAR,
    AMOUNT NUMBER(10, 2),
    EVENT_TS TIMESTAMP_NTZ,
    INGESTED_AT TIMESTAMP_NTZ
);

-- Include existing raw rows the first time this stream is consumed.
CREATE STREAM IF NOT EXISTS LEARNING_DB.DATA_ENGINEERING.ORDER_EVENTS_STREAM
    ON TABLE LEARNING_DB.DATA_ENGINEERING.RAW_ORDER_EVENTS
    APPEND_ONLY = TRUE
    SHOW_INITIAL_ROWS = TRUE;

-- Inspect pending stream rows. A SELECT is for inspection; DML consumption
-- advances the stream offset only when the consuming transaction commits.
SELECT
    EVENT_ID,
    ORDER_ID,
    STATUS,
    EVENT_TS,
    METADATA$ACTION AS ACTION,
    METADATA$ISUPDATE AS IS_UPDATE
FROM LEARNING_DB.DATA_ENGINEERING.ORDER_EVENTS_STREAM
ORDER BY ORDER_ID, EVENT_TS;

-- Create a manually runnable task. Do not RESUME it for this lesson.
CREATE OR REPLACE TASK LEARNING_DB.DATA_ENGINEERING.PROCESS_ORDER_EVENTS_TASK
    WAREHOUSE = COMPUTE_WH
AS
MERGE INTO LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS AS target
USING (
    WITH deduplicated_events AS (
        -- Keep the most recently ingested copy of each event ID.
        SELECT
            EVENT_ID, ORDER_ID, CUSTOMER_ID, STATUS, AMOUNT, EVENT_TS, INGESTED_AT
        FROM LEARNING_DB.DATA_ENGINEERING.ORDER_EVENTS_STREAM
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY EVENT_ID
            ORDER BY INGESTED_AT DESC
        ) = 1
    ),
    latest_event_per_order AS (
        -- Among this stream batch, select the latest event per order.
        SELECT
            EVENT_ID, ORDER_ID, CUSTOMER_ID, STATUS, AMOUNT, EVENT_TS, INGESTED_AT
        FROM deduplicated_events
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY ORDER_ID
            ORDER BY EVENT_TS DESC, INGESTED_AT DESC, EVENT_ID DESC
        ) = 1
    )
    SELECT * FROM latest_event_per_order
) AS source
ON target.ORDER_ID = source.ORDER_ID
WHEN MATCHED AND (
       source.EVENT_TS > target.EVENT_TS
    OR (source.EVENT_TS = target.EVENT_TS
        AND source.INGESTED_AT > target.INGESTED_AT)
) THEN UPDATE SET
    target.EVENT_ID = source.EVENT_ID,
    target.CUSTOMER_ID = source.CUSTOMER_ID,
    target.STATUS = source.STATUS,
    target.AMOUNT = source.AMOUNT,
    target.EVENT_TS = source.EVENT_TS,
    target.INGESTED_AT = source.INGESTED_AT
WHEN NOT MATCHED THEN INSERT (
    EVENT_ID, ORDER_ID, CUSTOMER_ID, STATUS, AMOUNT, EVENT_TS, INGESTED_AT
) VALUES (
    source.EVENT_ID, source.ORDER_ID, source.CUSTOMER_ID, source.STATUS,
    source.AMOUNT, source.EVENT_TS, source.INGESTED_AT
);

-- Manually run the task once. Wait for task completion before querying results.
EXECUTE TASK LEARNING_DB.DATA_ENGINEERING.PROCESS_ORDER_EVENTS_TASK;

-- Verify one current-state record per order.
SELECT ORDER_ID, STATUS, AMOUNT, EVENT_TS
FROM LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS
ORDER BY ORDER_ID;

-- Example incremental event: run once, then manually execute the task again.
-- INSERT INTO LEARNING_DB.DATA_ENGINEERING.RAW_ORDER_EVENTS
--     (EVENT_ID, ORDER_ID, CUSTOMER_ID, STATUS, AMOUNT, EVENT_TS, INGESTED_AT)
-- VALUES ('E007', 'O101', 'C002', 'CANCELLED', 80.00,
--         '2026-10-30 10:30:00', CURRENT_TIMESTAMP()::TIMESTAMP_NTZ);

-- Check whether stream changes remain after successful processing.
SELECT SYSTEM$STREAM_HAS_DATA(
    'LEARNING_DB.DATA_ENGINEERING.ORDER_EVENTS_STREAM'
) AS HAS_PENDING_CHANGES;

-- Current revenue excludes orders whose latest status is not COMPLETED.
SELECT
    TO_DATE(EVENT_TS) AS ORDER_DATE,
    SUM(AMOUNT) AS DAILY_REVENUE
FROM LEARNING_DB.DATA_ENGINEERING.CURRENT_ORDERS
WHERE STATUS = 'COMPLETED'
GROUP BY TO_DATE(EVENT_TS)
ORDER BY ORDER_DATE;
