-- ============================================================================
-- Mister Car Wash Intelligence Agent - ML Model Functions
-- ============================================================================
-- Purpose: Creates SQL UDF wrappers for ML model inference
-- Pattern: Matches Origence working example (Function + MODEL!PREDICT syntax)
-- Syntax: Verified against Snowflake SQL Reference and Origence template
-- ============================================================================

USE DATABASE MISTER_CAR_WASH_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MISTER_CAR_WASH_WH;

-- ============================================================================
-- Function 1: Predict Churn Risk
-- ============================================================================
-- Returns: Summary string with churn risk distribution
-- Input: status_filter (ACTIVE, PAUSED, or NULL)
-- Analyzes 100 members from portfolio
-- Model: CHURN_RISK_PREDICTOR
-- Features: LTV_SCORE, TENURE_DAYS, DAYS_SINCE_LAST_WASH, TOTAL_WASHES

CREATE OR REPLACE FUNCTION PREDICT_CHURN_RISK(status_filter VARCHAR)
RETURNS VARCHAR
AS
$$
    SELECT 
        'Total Members Analyzed: ' || COUNT(*) ||
        ', Predicted Safe: ' || SUM(CASE WHEN pred:PREDICTED_CHURN::INT = 0 THEN 1 ELSE 0 END) ||
        ', Predicted At-Risk: ' || SUM(CASE WHEN pred:PREDICTED_CHURN::INT = 1 THEN 1 ELSE 0 END) ||
        ', Risk Rate: ' || ROUND(SUM(CASE WHEN pred:PREDICTED_CHURN::INT = 1 THEN 1 ELSE 0 END)::FLOAT / NULLIF(COUNT(*), 0) * 100, 1) || '%'
    FROM (
        SELECT 
            CHURN_RISK_PREDICTOR!PREDICT(
                ltv_score, tenure_days, days_since_last_wash, total_washes
            ) as pred
        FROM MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.V_CHURN_RISK_FEATURES
        WHERE status_filter IS NULL OR status = status_filter
        LIMIT 100
    )
$$;

-- ============================================================================
-- Function 2: Predict Equipment Failure
-- ============================================================================
-- Returns: Summary string with failure risk statistics
-- Input: equipment_type_filter (CONVEYOR, BLOWER, BRUSH, PUMP_STATION, or NULL)
-- Analyzes 100 equipment records
-- Model: EQUIPMENT_FAILURE_PREDICTOR
-- Features: DAYS_SINCE_LAST_SERVICE, LAST_SERVICE_COST, SEVERITY_SCORE

CREATE OR REPLACE FUNCTION PREDICT_EQUIPMENT_FAILURE(equipment_type_filter VARCHAR)
RETURNS VARCHAR
AS
$$
    SELECT 
        'Total Equipment Analyzed: ' || COUNT(*) ||
        ', Healthy: ' || SUM(CASE WHEN pred:PREDICTED_FAILURE::INT = 0 THEN 1 ELSE 0 END) ||
        ', At Risk of Failure: ' || SUM(CASE WHEN pred:PREDICTED_FAILURE::INT = 1 THEN 1 ELSE 0 END) ||
        ', Failure Risk Rate: ' || ROUND(SUM(CASE WHEN pred:PREDICTED_FAILURE::INT = 1 THEN 1 ELSE 0 END)::FLOAT / NULLIF(COUNT(*), 0) * 100, 1) || '%'
    FROM (
        SELECT 
            EQUIPMENT_FAILURE_PREDICTOR!PREDICT(
                days_since_last_service, last_service_cost, severity_score
            ) as pred
        FROM MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.V_MAINTENANCE_RISK_FEATURES
        WHERE equipment_type_filter IS NULL OR equipment_type = equipment_type_filter
        LIMIT 100
    )
$$;

-- ============================================================================
-- Function 3: Predict Upsell Opportunity
-- ============================================================================
-- Returns: Summary string with upsell propensity
-- Input: tier_filter (BASE_UNLIMITED, PLATINUM, or NULL)
-- Analyzes 100 members
-- Model: UPSELL_PROPENSITY_SCORER
-- Features: LTV_SCORE, VISIT_COUNT, AVG_RATING

CREATE OR REPLACE FUNCTION PREDICT_UPSELL_OPPORTUNITY(tier_filter VARCHAR)
RETURNS VARCHAR
AS
$$
    SELECT 
        'Total Members Analyzed: ' || COUNT(*) ||
        ', Low Propensity: ' || SUM(CASE WHEN pred:PREDICTED_UPSELL::INT = 0 THEN 1 ELSE 0 END) ||
        ', High Propensity: ' || SUM(CASE WHEN pred:PREDICTED_UPSELL::INT = 1 THEN 1 ELSE 0 END) ||
        ', Upsell Opportunity Rate: ' || ROUND(SUM(CASE WHEN pred:PREDICTED_UPSELL::INT = 1 THEN 1 ELSE 0 END)::FLOAT / NULLIF(COUNT(*), 0) * 100, 1) || '%'
    FROM (
        SELECT 
            UPSELL_PROPENSITY_SCORER!PREDICT(
                ltv_score, visit_count, avg_rating
            ) as pred
        FROM MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.V_UPSELL_FEATURES
        WHERE tier_filter IS NULL OR membership_tier = tier_filter
        LIMIT 100
    )
$$;

-- ============================================================================
-- Verification Tests
-- ============================================================================
SELECT '🔄 Testing ML functions...' as status;

-- These will only work if models are trained and registered!
-- SELECT PREDICT_CHURN_RISK(NULL) as churn_result;
-- SELECT PREDICT_EQUIPMENT_FAILURE(NULL) as failure_result;
-- SELECT PREDICT_UPSELL_OPPORTUNITY(NULL) as upsell_result;

SELECT '✅ ML functions created successfully. Run notebook to train models before testing.' as final_status;
