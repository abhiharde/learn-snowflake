-- 12 | Snowpipe concepts
-- THEORY
-- COPY INTO is commonly orchestrated for scheduled or on-demand batch loads.
-- Snowpipe targets continuous/near-real-time ingestion of arriving files.
-- Automated batch does not require Snowpipe: an orchestrator can detect a
-- nightly file and invoke COPY INTO.
-- Automatic cloud-event ingestion usually requires cloud notification
-- integration/configuration; the REST API is another ingestion option.
-- Snowpipe is not automatically cheaper; choose based on latency, volume, and cost.
--
-- Interview pattern for one large nightly CSV:
-- file watcher/orchestrator -> stage -> COPY INTO -> validate load history/errors.
--
-- No PIPE is created here because cloud integration, notification, account,
-- and billing setup depend on the environment and were not configured in the trial.

-- Inspect files in the practice stage.
LIST @LEARNING_DB.DATA_ENGINEERING.ORDERS_STAGE;

-- Example batch load command invoked by an orchestrator.
-- COPY INTO LEARNING_DB.DATA_ENGINEERING.CSV_ORDERS
-- FROM @LEARNING_DB.DATA_ENGINEERING.ORDERS_STAGE
-- FILES = ('orders.csv')
-- FILE_FORMAT = (FORMAT_NAME = 'LEARNING_DB.DATA_ENGINEERING.ORDERS_CSV_FORMAT')
-- ON_ERROR = 'ABORT_STATEMENT';
