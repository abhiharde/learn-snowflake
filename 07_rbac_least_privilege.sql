-- 07 | Role-based access control (RBAC)
-- THEORY
-- Grant privileges to roles, then grant roles to users.
-- A user activates a role; secondary roles can also contribute privileges.
-- Least privilege means granting only the objects and actions required.
-- This example grants a reporting role access to the curated revenue view,
-- not the raw order-events table. Run as a role with grant authority.

CREATE ROLE IF NOT EXISTS ORDER_ANALYST_ROLE;

-- Grant only the required parent-object and warehouse usage privileges.
GRANT USAGE ON DATABASE LEARNING_DB TO ROLE ORDER_ANALYST_ROLE;
GRANT USAGE ON SCHEMA LEARNING_DB.DATA_ENGINEERING TO ROLE ORDER_ANALYST_ROLE;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ORDER_ANALYST_ROLE;

-- Grant SELECT on the curated view; intentionally do not grant raw-table access.
GRANT SELECT ON VIEW LEARNING_DB.DATA_ENGINEERING.DAILY_ORDER_REVENUE
    TO ROLE ORDER_ANALYST_ROLE;

-- Replace <YOUR_USER> with your Snowflake login identifier before running.
-- GRANT ROLE ORDER_ANALYST_ROLE TO USER <YOUR_USER>;

-- Test with only the primary role's privileges.
USE ROLE ORDER_ANALYST_ROLE;
USE SECONDARY ROLES NONE;

-- This query should succeed.
SELECT *
FROM LEARNING_DB.DATA_ENGINEERING.DAILY_ORDER_REVENUE
ORDER BY ORDER_DATE;

-- This query should be denied unless another grant provides raw-table access.
-- SELECT *
-- FROM LEARNING_DB.DATA_ENGINEERING.RAW_ORDER_EVENTS
-- LIMIT 5;

-- Restore the admin role for subsequent lessons.
USE ROLE ACCOUNTADMIN;
