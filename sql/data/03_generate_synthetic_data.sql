-- ============================================================================
-- Mister Car Wash Intelligence Agent - Synthetic Data Generation
-- ============================================================================
-- Purpose: Generate realistic data for testing and ML models
-- Rules:
-- 1. Use UNIFORM with constant arguments only
-- 2. Use GENERATOR with constant ROWCOUNT only
-- 3. Use SEQ4 only within GENERATOR
-- 4. Ensure varied distribution for status/category columns
-- ============================================================================

USE DATABASE MISTER_CAR_WASH_INTELLIGENCE;
USE SCHEMA RAW;
USE WAREHOUSE MISTER_CAR_WASH_WH;

-- ============================================================================
-- 1. Generate LOCATIONS (50 Stores)
-- ============================================================================
INSERT INTO LOCATIONS (location_id, city, state, zip_code, region, tunnel_length_ft, open_date, manager_name, status)
SELECT
    'LOC' || LPAD(SEQ4(), 3, '0') AS location_id,
    CASE MOD(SEQ4(), 5)
        WHEN 0 THEN 'Tucson'
        WHEN 1 THEN 'Phoenix'
        WHEN 2 THEN 'Orlando'
        WHEN 3 THEN 'Houston'
        ELSE 'Atlanta'
    END AS city,
    CASE MOD(SEQ4(), 5)
        WHEN 0 THEN 'AZ'
        WHEN 1 THEN 'AZ'
        WHEN 2 THEN 'FL'
        WHEN 3 THEN 'TX'
        ELSE 'GA'
    END AS state,
    '85' || LPAD(UNIFORM(0, 999, RANDOM()), 3, '0') AS zip_code,
    CASE MOD(SEQ4(), 3)
        WHEN 0 THEN 'WEST'
        WHEN 1 THEN 'SOUTH'
        ELSE 'SOUTHEAST'
    END AS region,
    UNIFORM(80, 150, RANDOM()) AS tunnel_length_ft,
    DATEADD(day, -UNIFORM(365, 3650, RANDOM()), CURRENT_DATE()) AS open_date,
    'Manager_' || SEQ4() AS manager_name,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 90 THEN 'OPEN'
        WHEN UNIFORM(1, 100, RANDOM()) <= 95 THEN 'RENOVATION'
        ELSE 'CLOSED'
    END AS status
FROM TABLE(GENERATOR(ROWCOUNT => 50));

-- ============================================================================
-- 2. Generate MEMBERS (5,000 Members)
-- ============================================================================
INSERT INTO MEMBERS (member_id, home_location_id, join_date, membership_tier, vehicle_type, status, cancellation_date, ltv_score)
SELECT
    'MEM' || LPAD(SEQ4(), 6, '0') AS member_id,
    'LOC' || LPAD(UNIFORM(0, 49, RANDOM()), 3, '0') AS home_location_id,
    DATEADD(day, -UNIFORM(30, 1000, RANDOM()), CURRENT_DATE()) AS join_date,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 20 THEN 'TITANIUM'
        WHEN UNIFORM(1, 100, RANDOM()) <= 50 THEN 'PLATINUM'
        ELSE 'BASE_UNLIMITED'
    END AS membership_tier,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 40 THEN 'SEDAN'
        WHEN UNIFORM(1, 100, RANDOM()) <= 70 THEN 'SUV'
        WHEN UNIFORM(1, 100, RANDOM()) <= 90 THEN 'TRUCK'
        ELSE 'VAN'
    END AS vehicle_type,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 80 THEN 'ACTIVE'
        WHEN UNIFORM(1, 100, RANDOM()) <= 95 THEN 'CANCELLED'
        ELSE 'PAUSED'
    END AS status,
    NULL AS cancellation_date, -- Default to NULL
    (UNIFORM(100, 2000, RANDOM()) / 10.0)::FLOAT AS ltv_score
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

-- Update cancellation_date for CANCELLED members
UPDATE MEMBERS
SET cancellation_date = DATEADD(day, UNIFORM(30, 300, RANDOM()), join_date)
WHERE status = 'CANCELLED';

-- ============================================================================
-- 3. Generate WASH_TRANSACTIONS (50,000 Transactions)
-- ============================================================================
INSERT INTO WASH_TRANSACTIONS (transaction_id, location_id, member_id, wash_date, wash_package, price, duration_minutes, weather_condition)
SELECT
    'TXN' || LPAD(SEQ4(), 8, '0') AS transaction_id,
    'LOC' || LPAD(UNIFORM(0, 49, RANDOM()), 3, '0') AS location_id,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 70 THEN 'MEM' || LPAD(UNIFORM(0, 4999, RANDOM()), 6, '0')
        ELSE NULL -- 30% Non-members
    END AS member_id,
    DATEADD(minute, -UNIFORM(0, 525600, RANDOM()), CURRENT_TIMESTAMP()) AS wash_date,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 10 THEN 'TITANIUM_360'
        WHEN UNIFORM(1, 100, RANDOM()) <= 30 THEN 'PLATINUM'
        WHEN UNIFORM(1, 100, RANDOM()) <= 60 THEN 'WHEEL_AND_TIRE'
        ELSE 'BASE'
    END AS wash_package,
    0 AS price, -- Placeholder, updated below
    UNIFORM(3, 15, RANDOM()) AS duration_minutes,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 70 THEN 'SUNNY'
        WHEN UNIFORM(1, 100, RANDOM()) <= 85 THEN 'CLOUDY'
        WHEN UNIFORM(1, 100, RANDOM()) <= 95 THEN 'RAINY'
        ELSE 'SNOW'
    END AS weather_condition
FROM TABLE(GENERATOR(ROWCOUNT => 50000));

-- Update prices based on package
UPDATE WASH_TRANSACTIONS SET price = 26.00 WHERE wash_package = 'TITANIUM_360';
UPDATE WASH_TRANSACTIONS SET price = 20.00 WHERE wash_package = 'PLATINUM';
UPDATE WASH_TRANSACTIONS SET price = 15.00 WHERE wash_package = 'WHEEL_AND_TIRE';
UPDATE WASH_TRANSACTIONS SET price = 9.00 WHERE wash_package = 'BASE';
-- Members pay 0 per transaction (subscription), but let's keep the "value" or set to 0. 
-- For revenue calc, members should probably be 0 here if it's transaction revenue, but let's assume this is "retail value" or set to 0 for members.
-- Let's set price to 0 for members to be realistic about "transaction" revenue vs "subscription" revenue.
UPDATE WASH_TRANSACTIONS SET price = 0 WHERE member_id IS NOT NULL;


-- ============================================================================
-- 4. Generate EQUIPMENT_MAINTENANCE (2,000 Records)
-- ============================================================================
INSERT INTO EQUIPMENT_MAINTENANCE (maintenance_id, location_id, equipment_type, maintenance_date, maintenance_type, cost, technician_notes, days_since_last_service, severity)
SELECT
    'MNT' || LPAD(SEQ4(), 5, '0') AS maintenance_id,
    'LOC' || LPAD(UNIFORM(0, 49, RANDOM()), 3, '0') AS location_id,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 40 THEN 'CONVEYOR'
        WHEN UNIFORM(1, 100, RANDOM()) <= 60 THEN 'BLOWER'
        WHEN UNIFORM(1, 100, RANDOM()) <= 80 THEN 'BRUSH'
        ELSE 'PUMP_STATION'
    END AS equipment_type,
    DATEADD(day, -UNIFORM(0, 730, RANDOM()), CURRENT_DATE()) AS maintenance_date,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 60 THEN 'ROUTINE'
        WHEN UNIFORM(1, 100, RANDOM()) <= 90 THEN 'REPAIR'
        ELSE 'REPLACEMENT'
    END AS maintenance_type,
    (UNIFORM(100, 5000, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0) AS cost,
    'Technician log entry...' AS technician_notes, -- Placeholder, updated below with realistic text
    UNIFORM(1, 180, RANDOM()) AS days_since_last_service,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 50 THEN 'LOW'
        WHEN UNIFORM(1, 100, RANDOM()) <= 80 THEN 'MEDIUM'
        WHEN UNIFORM(1, 100, RANDOM()) <= 95 THEN 'HIGH'
        ELSE 'CRITICAL'
    END AS severity
FROM TABLE(GENERATOR(ROWCOUNT => 2000));

-- Update technician notes with realistic unstructured data for search
UPDATE EQUIPMENT_MAINTENANCE 
SET technician_notes = CASE 
    WHEN maintenance_type = 'ROUTINE' THEN 
        'Performed routine inspection of ' || equipment_type || '. Checked belt tension and lubrication levels. All readings within normal parameters. Next service due in 30 days.'
    WHEN maintenance_type = 'REPAIR' AND equipment_type = 'CONVEYOR' THEN
        'Emergency repair on main conveyor chain. Linkage #45 snapped causing downtime. Replaced link and re-tensioned system. Checked for debris blockage.'
    WHEN maintenance_type = 'REPAIR' AND equipment_type = 'PUMP_STATION' THEN
        'High pressure pump #2 showing cavitation signs. Replaced seals and intake filter. Pressure restored to 1000 PSI.'
    WHEN maintenance_type = 'REPLACEMENT' THEN
        'Complete replacement of ' || equipment_type || ' motor assembly due to winding burnout. Installed new high-efficiency unit.'
    ELSE 'General maintenance performed. System operational.'
END;

-- ============================================================================
-- 5. Generate CUSTOMER_FEEDBACK (5,000 Records)
-- ============================================================================
INSERT INTO CUSTOMER_FEEDBACK (feedback_id, location_id, member_id, visit_date, rating, nps_score, comments, sentiment_label)
SELECT
    'FDB' || LPAD(SEQ4(), 6, '0') AS feedback_id,
    'LOC' || LPAD(UNIFORM(0, 49, RANDOM()), 3, '0') AS location_id,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 80 THEN 'MEM' || LPAD(UNIFORM(0, 4999, RANDOM()), 6, '0')
        ELSE NULL
    END AS member_id,
    DATEADD(day, -UNIFORM(0, 365, RANDOM()), CURRENT_DATE()) AS visit_date,
    UNIFORM(1, 5, RANDOM()) AS rating,
    UNIFORM(0, 10, RANDOM()) AS nps_score,
    'Customer comment...' AS comments, -- Placeholder
    'NEUTRAL' AS sentiment_label -- Placeholder
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

-- Update comments and sentiment based on rating
UPDATE CUSTOMER_FEEDBACK
SET comments = CASE 
    WHEN rating = 5 THEN 'Absolutely amazing wash! The titanium package is worth every penny. Staff was friendly and the tunnel moved fast.'
    WHEN rating = 4 THEN 'Great wash, but the dryer missed a spot on my bumper. Otherwise very satisfied.'
    WHEN rating = 3 THEN 'Average experience. The wait line was long and the vacuum suction was weak.'
    WHEN rating = 2 THEN 'Not happy. My rims were still dirty after the wheel and tire package. Manager offered a re-wash though.'
    WHEN rating = 1 THEN 'Terrible. Machine scratched my mirror and the soap smelled weird. Cancelling my membership.'
    ELSE comments
END,
sentiment_label = CASE 
    WHEN rating >= 4 THEN 'POSITIVE'
    WHEN rating = 3 THEN 'NEUTRAL'
    ELSE 'NEGATIVE'
END;

SELECT 'Synthetic data generated successfully' AS status;

