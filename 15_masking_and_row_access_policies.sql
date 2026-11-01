-- 15 | Masking policies and row access policies
-- THEORY
-- A masking policy governs returned values in a column.
-- A row access policy governs whether rows are visible.
-- Row access is evaluated before masking when both apply.
-- This is a role-name-based teaching example; production policy design often
-- uses role hierarchies or a controlled entitlement mapping.
-- Run as a role with privileges to create policies and grant object access.

CREATE OR REPLACE TABLE LEARNING_DB.DATA_ENGINEERING.CUSTOMER_PRIVACY_DEMO (
    CUSTOMER_ID VARCHAR,
    EMAIL VARCHAR,
    REGION VARCHAR
);

INSERT INTO LEARNING_DB.DATA_ENGINEERING.CUSTOMER_PRIVACY_DEMO
    (CUSTOMER_ID, EMAIL, REGION)
VALUES
    ('C101', 'ava@example.com', 'WEST'),
    ('C102', 'ben@example.com', 'EAST'),
    ('C103', 'cy@example.com', 'WEST'),
    ('C104', 'diya@example.com', 'NORTH');

CREATE ROLE IF NOT EXISTS WEST_ANALYST_ROLE;

-- Mask email addresses for non-admin roles.
CREATE OR REPLACE MASKING POLICY
    LEARNING_DB.DATA_ENGINEERING.MASK_DEMO_EMAIL
    AS (EMAIL_VALUE VARCHAR)
    RETURNS VARCHAR ->
        CASE
            WHEN CURRENT_ROLE() = 'ACCOUNTADMIN' THEN EMAIL_VALUE
            ELSE '***MASKED***'
        END;

-- Permit ACCOUNTADMIN all rows and WEST_ANALYST_ROLE only WEST rows.
CREATE OR REPLACE ROW ACCESS POLICY
    LEARNING_DB.DATA_ENGINEERING.WEST_REGION_ONLY
    AS (REGION_VALUE VARCHAR)
    RETURNS BOOLEAN ->
        CURRENT_ROLE() = 'ACCOUNTADMIN'
        OR (
            CURRENT_ROLE() = 'WEST_ANALYST_ROLE'
            AND REGION_VALUE = 'WEST'
        );

ALTER TABLE LEARNING_DB.DATA_ENGINEERING.CUSTOMER_PRIVACY_DEMO
    MODIFY COLUMN EMAIL
    SET MASKING POLICY LEARNING_DB.DATA_ENGINEERING.MASK_DEMO_EMAIL;

ALTER TABLE LEARNING_DB.DATA_ENGINEERING.CUSTOMER_PRIVACY_DEMO
    ADD ROW ACCESS POLICY LEARNING_DB.DATA_ENGINEERING.WEST_REGION_ONLY
    ON (REGION);

-- Grant the practice role only what is needed to query this table.
GRANT USAGE ON DATABASE LEARNING_DB TO ROLE WEST_ANALYST_ROLE;
GRANT USAGE ON SCHEMA LEARNING_DB.DATA_ENGINEERING TO ROLE WEST_ANALYST_ROLE;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE WEST_ANALYST_ROLE;
GRANT SELECT ON TABLE LEARNING_DB.DATA_ENGINEERING.CUSTOMER_PRIVACY_DEMO
    TO ROLE WEST_ANALYST_ROLE;

-- Replace <YOUR_USER> with your Snowflake login identifier before running.
-- GRANT ROLE WEST_ANALYST_ROLE TO USER <YOUR_USER>;

-- Test under the restricted role: expected two WEST rows with masked emails.
-- USE ROLE WEST_ANALYST_ROLE;
-- USE SECONDARY ROLES NONE;
-- SELECT CUSTOMER_ID, EMAIL, REGION
-- FROM LEARNING_DB.DATA_ENGINEERING.CUSTOMER_PRIVACY_DEMO
-- ORDER BY CUSTOMER_ID;
--
-- Return to admin after testing:
-- USE ROLE ACCOUNTADMIN;
