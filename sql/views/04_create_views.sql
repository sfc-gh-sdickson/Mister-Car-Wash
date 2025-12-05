-- ============================================================================
-- Mister Car Wash Intelligence Agent - Analytics Views & ML Feature Views
-- ============================================================================
-- Purpose: Create views for analytics and ML model training/inference
-- Rules:
-- 1. Create Feature Views for ML (Single Source of Truth)
-- 2. Feature Views must return NUMERIC features for simplicity/reliability
-- 3. Include LABEL columns for training
-- 4. Filter columns (like ID) should be in WHERE clause or kept separate
-- ============================================================================

USE DATABASE MISTER_CAR_WASH_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MISTER_CAR_WASH_WH;

-- ============================================================================
-- 1. V_MEMBER_ANALYTICS (General Analytics View)
-- ============================================================================
CREATE OR REPLACE VIEW V_MEMBER_ANALYTICS AS
SELECT
    m.member_id,
    m.home_location_id,
    m.membership_tier,
    m.status,
    m.join_date,
    m.ltv_score,
    DATEDIFF(day, m.join_date, CURRENT_DATE()) AS tenure_days,
    COUNT(t.transaction_id) AS total_washes,
    COALESCE(MAX(t.wash_date), m.join_date) AS last_wash_date,
    DATEDIFF(day, COALESCE(MAX(t.wash_date), m.join_date), CURRENT_DATE()) AS days_since_last_wash
FROM MISTER_CAR_WASH_INTELLIGENCE.RAW.MEMBERS m
LEFT JOIN MISTER_CAR_WASH_INTELLIGENCE.RAW.WASH_TRANSACTIONS t ON m.member_id = t.member_id
GROUP BY m.member_id, m.home_location_id, m.membership_tier, m.status, m.join_date, m.ltv_score;

-- ============================================================================
-- 2. V_LOCATION_PERFORMANCE (General Analytics View)
-- ============================================================================
CREATE OR REPLACE VIEW V_LOCATION_PERFORMANCE AS
SELECT
    l.location_id,
    l.city,
    l.region,
    COUNT(DISTINCT t.transaction_id) AS total_transactions,
    SUM(t.price) AS total_revenue,
    AVG(t.duration_minutes) AS avg_wash_duration,
    COUNT(DISTINCT m.member_id) AS active_members
FROM MISTER_CAR_WASH_INTELLIGENCE.RAW.LOCATIONS l
LEFT JOIN MISTER_CAR_WASH_INTELLIGENCE.RAW.WASH_TRANSACTIONS t ON l.location_id = t.location_id
LEFT JOIN MISTER_CAR_WASH_INTELLIGENCE.RAW.MEMBERS m ON l.location_id = m.home_location_id AND m.status = 'ACTIVE'
GROUP BY l.location_id, l.city, l.region;

-- ============================================================================
-- 3. ML FEATURE VIEW: CHURN_RISK_PREDICTOR
-- Features: ltv_score, tenure_days, days_since_last_wash, total_washes
-- Label: is_churned (1 if CANCELLED, 0 if ACTIVE/PAUSED)
-- ============================================================================
CREATE OR REPLACE VIEW V_CHURN_RISK_FEATURES AS
SELECT
    m.member_id, -- Keep ID for joining/filtering, but ML model will ignore it or we select specific cols
    m.ltv_score,
    DATEDIFF(day, m.join_date, CURRENT_DATE()) AS tenure_days,
    DATEDIFF(day, COALESCE(MAX(t.wash_date), m.join_date), CURRENT_DATE()) AS days_since_last_wash,
    COUNT(t.transaction_id) AS total_washes,
    CASE WHEN m.status = 'CANCELLED' THEN 1 ELSE 0 END AS is_churned,
    m.status -- Keep status for filtering
FROM MISTER_CAR_WASH_INTELLIGENCE.RAW.MEMBERS m
LEFT JOIN MISTER_CAR_WASH_INTELLIGENCE.RAW.WASH_TRANSACTIONS t ON m.member_id = t.member_id
GROUP BY m.member_id, m.ltv_score, m.join_date, m.status;

-- ============================================================================
-- 4. ML FEATURE VIEW: EQUIPMENT_FAILURE_PREDICTOR
-- Features: days_since_last_service, cost, severity_score (encoded)
-- Label: failure_risk_label (synthetic based on severity)
-- ============================================================================
CREATE OR REPLACE VIEW V_MAINTENANCE_RISK_FEATURES AS
SELECT
    e.maintenance_id,
    e.equipment_type, -- Filter col
    e.days_since_last_service,
    e.cost AS last_service_cost,
    CASE 
        WHEN e.severity = 'LOW' THEN 1
        WHEN e.severity = 'MEDIUM' THEN 2
        WHEN e.severity = 'HIGH' THEN 3
        ELSE 4
    END AS severity_score,
    CASE 
        WHEN e.severity IN ('HIGH', 'CRITICAL') THEN 1 
        ELSE 0 
    END AS failure_risk_label
FROM MISTER_CAR_WASH_INTELLIGENCE.RAW.EQUIPMENT_MAINTENANCE e;

-- ============================================================================
-- 5. ML FEATURE VIEW: UPSELL_PROPENSITY_SCORER
-- Features: ltv_score, avg_rating, visit_count
-- Label: upsell_label (synthetic)
-- ============================================================================
CREATE OR REPLACE VIEW V_UPSELL_FEATURES AS
SELECT
    m.member_id,
    m.membership_tier, -- Filter col
    m.ltv_score,
    COUNT(t.transaction_id) AS visit_count,
    COALESCE(AVG(f.rating), 3.0) AS avg_rating, -- Handle NULLs
    CASE 
        WHEN m.membership_tier != 'TITANIUM' AND m.ltv_score > 1000 THEN 1
        ELSE 0 
    END AS upsell_label
FROM MISTER_CAR_WASH_INTELLIGENCE.RAW.MEMBERS m
LEFT JOIN MISTER_CAR_WASH_INTELLIGENCE.RAW.WASH_TRANSACTIONS t ON m.member_id = t.member_id
LEFT JOIN MISTER_CAR_WASH_INTELLIGENCE.RAW.CUSTOMER_FEEDBACK f ON m.member_id = f.member_id
GROUP BY m.member_id, m.membership_tier, m.ltv_score;

SELECT 'Analytics and Feature Views created successfully' AS status;

