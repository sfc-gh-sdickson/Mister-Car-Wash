-- ============================================================================
-- Mister Car Wash Intelligence Agent - Cortex Search Service Setup
-- ============================================================================
-- Purpose: Create Cortex Search services for unstructured data
--          (Technician Notes and Customer Feedback)
-- Syntax: Verified against Snowflake SQL Reference
-- ============================================================================

USE DATABASE MISTER_CAR_WASH_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE MISTER_CAR_WASH_WH;

-- ============================================================================
-- Step 1: Enable Change Tracking (Required for Cortex Search)
-- ============================================================================
ALTER TABLE EQUIPMENT_MAINTENANCE SET CHANGE_TRACKING = TRUE;
ALTER TABLE CUSTOMER_FEEDBACK SET CHANGE_TRACKING = TRUE;

-- ============================================================================
-- Step 2: Create Maintenance Log Search Service
-- ============================================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE MAINTENANCE_LOG_SEARCH
  ON technician_notes
  ATTRIBUTES equipment_type, maintenance_type, severity, location_id
  WAREHOUSE = MISTER_CAR_WASH_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Search service for equipment maintenance logs and repairs'
AS SELECT
    maintenance_id,
    technician_notes,
    equipment_type,
    maintenance_type,
    severity,
    location_id,
    maintenance_date,
    cost
FROM EQUIPMENT_MAINTENANCE;

-- ============================================================================
-- Step 3: Create Customer Feedback Search Service
-- ============================================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE CUSTOMER_FEEDBACK_SEARCH
  ON comments
  ATTRIBUTES sentiment_label, rating, location_id
  WAREHOUSE = MISTER_CAR_WASH_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Search service for customer feedback and reviews'
AS SELECT
    feedback_id,
    comments,
    sentiment_label,
    rating,
    location_id,
    visit_date,
    nps_score
FROM CUSTOMER_FEEDBACK;

-- ============================================================================
-- Display confirmation
-- ============================================================================
SELECT 'Cortex Search services created successfully' AS status;

