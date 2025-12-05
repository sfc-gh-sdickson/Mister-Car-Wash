-- ============================================================================
-- Mister Car Wash Intelligence Agent - Database Setup
-- ============================================================================
-- Purpose: Create database, schema, and warehouse
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Create Warehouse
CREATE WAREHOUSE IF NOT EXISTS MISTER_CAR_WASH_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for Mister Car Wash Intelligence Agent';

-- Create Database
CREATE DATABASE IF NOT EXISTS MISTER_CAR_WASH_INTELLIGENCE;

-- Create Schemas
USE DATABASE MISTER_CAR_WASH_INTELLIGENCE;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;

-- Grant permissions (Optional but good practice)
GRANT USAGE ON DATABASE MISTER_CAR_WASH_INTELLIGENCE TO ROLE SYSADMIN;
GRANT ALL ON SCHEMA RAW TO ROLE SYSADMIN;
GRANT ALL ON SCHEMA ANALYTICS TO ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE MISTER_CAR_WASH_WH TO ROLE SYSADMIN;

SELECT 'Database and Schemas created successfully' AS status;

