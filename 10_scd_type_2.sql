-- 10 | Slowly Changing Dimension Type 2
-- THEORY
-- SCD Type 2 preserves historical attribute versions instead of overwriting them.
-- Expire the old current row (VALID_TO, IS_CURRENT = FALSE) and insert a new row.
-- A reliable production load also handles duplicate/out-of-order source changes,
-- multiple changes per key in a batch, and transaction retries.

-- Reset the two SCD practice tables and seed initial customer versions.
CREATE OR REPLACE TABLE LEARNING_DB.DATA_ENGINEERING.CUSTOMER_DIM (
    CUSTOMER_ID VARCHAR,
    CUSTOMER_NAME VARCHAR,
    CITY VARCHAR,
    VALID_FROM TIMESTAMP_NTZ,
    VALID_TO TIMESTAMP_NTZ,
    IS_CURRENT BOOLEAN
);

INSERT INTO LEARNING_DB.DATA_ENGINEERING.CUSTOMER_DIM
    (CUSTOMER_ID, CUSTOMER_NAME, CITY, VALID_FROM, VALID_TO, IS_CURRENT)
VALUES
    ('C001', 'Asha', 'Pune', '2026-01-01 00:00:00', NULL, TRUE),
    ('C002', 'Ravi', 'Mumbai', '2026-01-01 00:00:00', NULL, TRUE),
    ('C003', 'Mina', 'Delhi', '2026-01-01 00:00:00', NULL, TRUE);

CREATE OR REPLACE TABLE LEARNING_DB.DATA_ENGINEERING.CUSTOMER_CHANGES (
    CUSTOMER_ID VARCHAR,
    CUSTOMER_NAME VARCHAR,
    CITY VARCHAR,
    CHANGED_AT TIMESTAMP_NTZ
);

INSERT INTO LEARNING_DB.DATA_ENGINEERING.CUSTOMER_CHANGES
    (CUSTOMER_ID, CUSTOMER_NAME, CITY, CHANGED_AT)
VALUES
    ('C001', 'Asha', 'Bengaluru', '2026-11-01 09:00:00'),
    ('C004', 'Dev', 'Hyderabad', '2026-11-01 10:00:00');

-- Expire changed current versions and insert new current versions atomically.
BEGIN TRANSACTION;

UPDATE LEARNING_DB.DATA_ENGINEERING.CUSTOMER_DIM AS dim
SET
    VALID_TO = changes.CHANGED_AT,
    IS_CURRENT = FALSE
FROM LEARNING_DB.DATA_ENGINEERING.CUSTOMER_CHANGES AS changes
WHERE dim.CUSTOMER_ID = changes.CUSTOMER_ID
  AND dim.IS_CURRENT = TRUE
  AND (
      dim.CUSTOMER_NAME <> changes.CUSTOMER_NAME
      OR dim.CITY <> changes.CITY
  );

INSERT INTO LEARNING_DB.DATA_ENGINEERING.CUSTOMER_DIM
    (CUSTOMER_ID, CUSTOMER_NAME, CITY, VALID_FROM, VALID_TO, IS_CURRENT)
SELECT
    changes.CUSTOMER_ID,
    changes.CUSTOMER_NAME,
    changes.CITY,
    changes.CHANGED_AT,
    NULL,
    TRUE
FROM LEARNING_DB.DATA_ENGINEERING.CUSTOMER_CHANGES AS changes
WHERE NOT EXISTS (
    SELECT 1
    FROM LEARNING_DB.DATA_ENGINEERING.CUSTOMER_DIM AS current_dim
    WHERE current_dim.CUSTOMER_ID = changes.CUSTOMER_ID
      AND current_dim.IS_CURRENT = TRUE
      AND current_dim.CUSTOMER_NAME = changes.CUSTOMER_NAME
      AND current_dim.CITY = changes.CITY
);

COMMIT;

-- Verify old and current versions; C001 should have two rows.
SELECT CUSTOMER_ID, CUSTOMER_NAME, CITY, VALID_FROM, VALID_TO, IS_CURRENT
FROM LEARNING_DB.DATA_ENGINEERING.CUSTOMER_DIM
ORDER BY CUSTOMER_ID, VALID_FROM;
