-- 11 | Internal stages, file formats, and COPY INTO
-- THEORY
-- A stage is a location Snowflake can read files from before loading.
-- COPY INTO performs batch loading from staged files into a target table.
-- Load history helps avoid reloading the same staged file, but it is not a
-- complete idempotency strategy for renamed/reprocessed files or replaced targets.
-- Upload orders.csv to the internal stage through Snowsight before running COPY.

CREATE TABLE IF NOT EXISTS LEARNING_DB.DATA_ENGINEERING.CSV_ORDERS (
    ORDER_ID VARCHAR,
    CUSTOMER_ID VARCHAR,
    AMOUNT NUMBER(10, 2),
    ORDER_TS TIMESTAMP_NTZ
);

CREATE FILE FORMAT IF NOT EXISTS LEARNING_DB.DATA_ENGINEERING.ORDERS_CSV_FORMAT
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';

CREATE STAGE IF NOT EXISTS LEARNING_DB.DATA_ENGINEERING.ORDERS_STAGE
    FILE_FORMAT = LEARNING_DB.DATA_ENGINEERING.ORDERS_CSV_FORMAT;

-- Confirm uploaded files before loading.
LIST @LEARNING_DB.DATA_ENGINEERING.ORDERS_STAGE;

-- Load only the named CSV file; abort the statement on a parsing error.
COPY INTO LEARNING_DB.DATA_ENGINEERING.CSV_ORDERS
FROM @LEARNING_DB.DATA_ENGINEERING.ORDERS_STAGE
FILES = ('orders.csv')
FILE_FORMAT = (FORMAT_NAME = 'LEARNING_DB.DATA_ENGINEERING.ORDERS_CSV_FORMAT')
ON_ERROR = 'ABORT_STATEMENT';

-- Verify loaded rows.
SELECT ORDER_ID, CUSTOMER_ID, AMOUNT, ORDER_TS
FROM LEARNING_DB.DATA_ENGINEERING.CSV_ORDERS
ORDER BY ORDER_ID;

-- Re-running the same load may skip the file based on Snowflake load history.
-- Check row count rather than assuming a COPY result means new rows were added.
SELECT COUNT(*) AS ROW_COUNT
FROM LEARNING_DB.DATA_ENGINEERING.CSV_ORDERS;
