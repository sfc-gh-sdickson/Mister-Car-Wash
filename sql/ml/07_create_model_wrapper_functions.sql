-- ============================================================================
-- Mister Car Wash Intelligence Agent - ML Model Wrappers
-- ============================================================================
-- Purpose: SQL stored procedures to invoke ML models
-- Pattern: EXACTLY matches Rocket Lab / Kratos Defense working example
-- Syntax: Verified against Snowflake SQL Reference
-- ============================================================================

USE DATABASE MISTER_CAR_WASH_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MISTER_CAR_WASH_WH;

-- ============================================================================
-- 1. Churn Risk Predictor Wrapper
-- Model: CHURN_RISK_PREDICTOR
-- Features: ltv_score, tenure_days, days_since_last_wash, total_washes
-- ============================================================================
CREATE OR REPLACE PROCEDURE PREDICT_CHURN_RISK(
    STATUS_FILTER VARCHAR
)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Calls CHURN_RISK_PREDICTOR ML model to predict member cancellation risk'
AS $$
DECLARE
    result_json STRING;
    total_count INTEGER;
    low_risk INTEGER;
    high_risk INTEGER;
    churn_risk_pct FLOAT;
    avg_ltv FLOAT;
BEGIN
    WITH predictions AS (
        WITH m AS MODEL MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.CHURN_RISK_PREDICTOR
        SELECT
            ltv_score,
            m!PREDICT(
                ltv_score,
                tenure_days,
                days_since_last_wash,
                total_washes
            ):CHURN_LABEL::INT AS predicted_churn
        FROM MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.V_CHURN_RISK_FEATURES
        WHERE (:STATUS_FILTER IS NULL OR :STATUS_FILTER = 'NULL' OR :STATUS_FILTER = '' OR UPPER(status) = UPPER(:STATUS_FILTER))
        LIMIT 100
    )
    SELECT
        COUNT(*),
        SUM(CASE WHEN predicted_churn = 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN predicted_churn = 1 THEN 1 ELSE 0 END),
        ROUND(AVG(ltv_score), 2)
    INTO total_count, low_risk, high_risk, avg_ltv
    FROM predictions;

    IF (total_count > 0) THEN
        churn_risk_pct := ROUND(high_risk / total_count * 100, 2);
    ELSE
        churn_risk_pct := 0;
    END IF;

    result_json := OBJECT_CONSTRUCT(
        'prediction_source', 'CHURN_RISK_PREDICTOR ML Model',
        'status_filter', COALESCE(:STATUS_FILTER, 'ALL'),
        'members_analyzed', total_count,
        'predicted_safe', low_risk,
        'predicted_churn_risk', high_risk,
        'churn_risk_pct', churn_risk_pct,
        'avg_ltv_score', avg_ltv
    )::STRING;

    RETURN result_json;
END;
$$;

-- ============================================================================
-- 2. Equipment Failure Predictor Wrapper
-- Model: EQUIPMENT_FAILURE_PREDICTOR
-- Features: days_since_last_service, last_service_cost, severity_score
-- ============================================================================
CREATE OR REPLACE PROCEDURE PREDICT_EQUIPMENT_FAILURE(
    EQUIPMENT_TYPE_FILTER VARCHAR
)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Calls EQUIPMENT_FAILURE_PREDICTOR ML model to predict equipment failure risk'
AS $$
DECLARE
    result_json STRING;
    total_count INTEGER;
    healthy INTEGER;
    at_risk INTEGER;
    failure_risk_pct FLOAT;
    avg_days_service FLOAT;
BEGIN
    WITH predictions AS (
        WITH m AS MODEL MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.EQUIPMENT_FAILURE_PREDICTOR
        SELECT
            days_since_last_service,
            m!PREDICT(
                days_since_last_service,
                last_service_cost,
                severity_score
            ):FAILURE_LABEL::INT AS predicted_failure
        FROM MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.V_MAINTENANCE_RISK_FEATURES
        WHERE (:EQUIPMENT_TYPE_FILTER IS NULL OR :EQUIPMENT_TYPE_FILTER = 'NULL' OR :EQUIPMENT_TYPE_FILTER = '' OR UPPER(equipment_type) = UPPER(:EQUIPMENT_TYPE_FILTER))
        LIMIT 100
    )
    SELECT
        COUNT(*),
        SUM(CASE WHEN predicted_failure = 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN predicted_failure = 1 THEN 1 ELSE 0 END),
        ROUND(AVG(days_since_last_service), 1)
    INTO total_count, healthy, at_risk, avg_days_service
    FROM predictions;

    IF (total_count > 0) THEN
        failure_risk_pct := ROUND(at_risk / total_count * 100, 2);
    ELSE
        failure_risk_pct := 0;
    END IF;

    result_json := OBJECT_CONSTRUCT(
        'prediction_source', 'EQUIPMENT_FAILURE_PREDICTOR ML Model',
        'equipment_type_filter', COALESCE(:EQUIPMENT_TYPE_FILTER, 'ALL'),
        'equipment_analyzed', total_count,
        'predicted_healthy', healthy,
        'predicted_failure_risk', at_risk,
        'failure_risk_pct', failure_risk_pct,
        'avg_days_since_service', avg_days_service
    )::STRING;

    RETURN result_json;
END;
$$;

-- ============================================================================
-- 3. Upsell Propensity Scorer Wrapper
-- Model: UPSELL_PROPENSITY_SCORER
-- Features: ltv_score, visit_count, avg_rating
-- ============================================================================
CREATE OR REPLACE PROCEDURE PREDICT_UPSELL_OPPORTUNITY(
    TIER_FILTER VARCHAR
)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Calls UPSELL_PROPENSITY_SCORER ML model to predict upgrade likelihood'
AS $$
DECLARE
    result_json STRING;
    total_count INTEGER;
    low_propensity INTEGER;
    high_propensity INTEGER;
    upsell_opportunity_pct FLOAT;
    avg_visits FLOAT;
BEGIN
    WITH predictions AS (
        WITH m AS MODEL MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.UPSELL_PROPENSITY_SCORER
        SELECT
            visit_count,
            m!PREDICT(
                ltv_score,
                visit_count,
                avg_rating
            ):UPSELL_LABEL::INT AS predicted_upsell
        FROM MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.V_UPSELL_FEATURES
        WHERE (:TIER_FILTER IS NULL OR :TIER_FILTER = 'NULL' OR :TIER_FILTER = '' OR UPPER(membership_tier) = UPPER(:TIER_FILTER))
        LIMIT 100
    )
    SELECT
        COUNT(*),
        SUM(CASE WHEN predicted_upsell = 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN predicted_upsell = 1 THEN 1 ELSE 0 END),
        ROUND(AVG(visit_count), 1)
    INTO total_count, low_propensity, high_propensity, avg_visits
    FROM predictions;

    IF (total_count > 0) THEN
        upsell_opportunity_pct := ROUND(high_propensity / total_count * 100, 2);
    ELSE
        upsell_opportunity_pct := 0;
    END IF;

    result_json := OBJECT_CONSTRUCT(
        'prediction_source', 'UPSELL_PROPENSITY_SCORER ML Model',
        'tier_filter', COALESCE(:TIER_FILTER, 'ALL'),
        'members_analyzed', total_count,
        'low_opportunity', low_propensity,
        'high_opportunity', high_propensity,
        'upsell_opportunity_pct', upsell_opportunity_pct,
        'avg_visit_count', avg_visits
    )::STRING;

    RETURN result_json;
END;
$$;

SELECT 'Model wrapper procedures created successfully' AS status;

