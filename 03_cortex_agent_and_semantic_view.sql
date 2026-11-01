-- 03 | Cortex Agent and semantic view
-- THEORY
-- Cortex Agents orchestrate configured tools to answer questions.
-- Query structured data uses a semantic view or semantic model for business
-- context; a regular SQL view is not itself a semantic view.
-- This worksheet documents the SQL data source. Create the semantic view and
-- configure the Agent in Snowsight because those steps are UI workflows.
--
-- Agent setup practiced:
--   1. Create ORDER_REVENUE_AGENT in LEARNING_DB.DATA_ENGINEERING.
--   2. Configure a clear description, orchestration instructions, and response rules.
--   3. Create ORDER_REVENUE_SEMANTIC using DAILY_ORDER_REVENUE as its source.
--   4. Include ORDER_DATE as a dimension and DAILY_REVENUE as a measure.
--   5. Add it under Configuration > Tools > Query structured data.
--   6. Preview access was denied for the trial account; do not treat a draft
--      agent as a verified working agent or publish just to bypass that limit.
--
-- Suggested tool description:
-- "Answer questions about daily order revenue by order date. The data contains
-- ORDER_DATE and DAILY_REVENUE only; it cannot answer individual-order or
-- cancellation questions."

-- Verify the regular SQL view that supplies the semantic view.
SELECT ORDER_DATE, DAILY_REVENUE
FROM LEARNING_DB.DATA_ENGINEERING.DAILY_ORDER_REVENUE
ORDER BY ORDER_DATE;
