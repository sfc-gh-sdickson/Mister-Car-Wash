-- ============================================================================
-- Mister Car Wash Intelligence Agent - Table Creation
-- ============================================================================
-- Purpose: Create tables for store operations, members, and transactions
-- Schema: RAW
-- ============================================================================

USE DATABASE MISTER_CAR_WASH_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE MISTER_CAR_WASH_WH;

-- 1. Locations Table (Stores)
CREATE OR REPLACE TABLE LOCATIONS (
    location_id VARCHAR(20) PRIMARY KEY,
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    region VARCHAR(50),
    tunnel_length_ft INTEGER,
    open_date DATE,
    manager_name VARCHAR(100),
    status VARCHAR(20) -- 'OPEN', 'RENOVATION', 'CLOSED'
);

-- 2. Members Table (Unlimited Wash Club)
CREATE OR REPLACE TABLE MEMBERS (
    member_id VARCHAR(20) PRIMARY KEY,
    home_location_id VARCHAR(20) REFERENCES LOCATIONS(location_id),
    join_date DATE,
    membership_tier VARCHAR(50), -- 'TITANIUM', 'PLATINUM', 'BASE_UNLIMITED'
    vehicle_type VARCHAR(50), -- 'SEDAN', 'SUV', 'TRUCK', 'VAN'
    status VARCHAR(20), -- 'ACTIVE', 'CANCELLED', 'PAUSED'
    cancellation_date DATE,
    ltv_score FLOAT -- Lifetime Value Score (synthetic metric for ML)
);

-- 3. Wash Transactions Table
CREATE OR REPLACE TABLE WASH_TRANSACTIONS (
    transaction_id VARCHAR(20) PRIMARY KEY,
    location_id VARCHAR(20) REFERENCES LOCATIONS(location_id),
    member_id VARCHAR(20), -- Nullable for single wash customers
    wash_date TIMESTAMP_NTZ,
    wash_package VARCHAR(50), -- 'TITANIUM_360', 'PLATINUM', 'WHEEL_AND_TIRE', 'BASE'
    price DECIMAL(10, 2),
    duration_minutes INTEGER,
    weather_condition VARCHAR(50), -- 'SUNNY', 'RAINY', 'CLOUDY', 'SNOW'
    FOREIGN KEY (member_id) REFERENCES MEMBERS(member_id)
);

-- 4. Equipment Maintenance Logs (Structured + Unstructured)
-- Used for Cortex Search (technician_notes) and ML (predictive maintenance)
CREATE OR REPLACE TABLE EQUIPMENT_MAINTENANCE (
    maintenance_id VARCHAR(20) PRIMARY KEY,
    location_id VARCHAR(20) REFERENCES LOCATIONS(location_id),
    equipment_type VARCHAR(50), -- 'CONVEYOR', 'BLOWER', 'BRUSH', 'PUMP_STATION'
    maintenance_date DATE,
    maintenance_type VARCHAR(50), -- 'ROUTINE', 'REPAIR', 'REPLACEMENT'
    cost DECIMAL(10, 2),
    technician_notes VARCHAR(16777216), -- Unstructured text for Search
    days_since_last_service INTEGER, -- For ML
    severity VARCHAR(20) -- 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
);

-- 5. Customer Feedback (Structured + Unstructured)
-- Used for Cortex Search (comments) and Sentiment Analysis
CREATE OR REPLACE TABLE CUSTOMER_FEEDBACK (
    feedback_id VARCHAR(20) PRIMARY KEY,
    location_id VARCHAR(20) REFERENCES LOCATIONS(location_id),
    member_id VARCHAR(20) REFERENCES MEMBERS(member_id),
    visit_date DATE,
    rating INTEGER, -- 1-5
    nps_score INTEGER, -- 0-10
    comments VARCHAR(16777216), -- Unstructured text for Search
    sentiment_label VARCHAR(20) -- 'POSITIVE', 'NEUTRAL', 'NEGATIVE'
);

SELECT 'All tables created successfully' AS status;

