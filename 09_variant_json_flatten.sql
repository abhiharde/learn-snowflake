-- 09 | Semi-structured data: VARIANT, paths, and FLATTEN
-- THEORY
-- VARIANT stores semi-structured values such as JSON.
-- Colon/dot path expressions access nested values; casts convert them to SQL types.
-- LATERAL FLATTEN turns array elements into rows for joins and aggregation.

-- Expand two JSON order items into rows.
WITH payload AS (
    SELECT PARSE_JSON(
        '{"order_id":"O200","customer":{"id":"C009"},"items":[{"sku":"A1","qty":2},{"sku":"B2","qty":1}]}'
    ) AS doc
)
SELECT
    doc:order_id::STRING AS ORDER_ID,
    doc:customer.id::STRING AS CUSTOMER_ID,
    item.value:sku::STRING AS SKU,
    item.value:qty::NUMBER AS QUANTITY
FROM payload,
     LATERAL FLATTEN(INPUT => doc:items) AS item;

-- Calculate a total from JSON line-item quantities and unit prices.
WITH payload AS (
    SELECT PARSE_JSON(
        '{"order_id":"O200","items":[{"sku":"A1","qty":2,"unit_price":12.50},{"sku":"B2","qty":1,"unit_price":8.00}]}'
    ) AS doc
),
order_lines AS (
    SELECT
        doc:order_id::STRING AS ORDER_ID,
        item.value:sku::STRING AS SKU,
        item.value:qty::NUMBER AS QUANTITY,
        item.value:unit_price::NUMBER(10, 2) AS UNIT_PRICE
    FROM payload,
         LATERAL FLATTEN(INPUT => doc:items) AS item
)
SELECT ORDER_ID, SUM(QUANTITY * UNIT_PRICE) AS ORDER_TOTAL
FROM order_lines
GROUP BY ORDER_ID;
