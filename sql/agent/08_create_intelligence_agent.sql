-- ============================================================================
-- Mister Car Wash Intelligence Agent - Create Snowflake Intelligence Agent
-- ============================================================================
-- Purpose: Create and configure Snowflake Intelligence Agent
-- Execution: Run this after completing steps 01-07 and running the notebook
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE MISTER_CAR_WASH_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MISTER_CAR_WASH_WH;

-- ============================================================================
-- Step 1: Grant Required Permissions for Cortex Analyst
-- ============================================================================
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_ANALYST_USER TO ROLE SYSADMIN;
GRANT USAGE ON DATABASE MISTER_CAR_WASH_INTELLIGENCE TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA MISTER_CAR_WASH_INTELLIGENCE.RAW TO ROLE SYSADMIN;

GRANT REFERENCES, SELECT ON SEMANTIC VIEW MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.SV_MEMBER_INTELLIGENCE TO ROLE SYSADMIN;
GRANT REFERENCES, SELECT ON SEMANTIC VIEW MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.SV_OPERATIONAL_INTELLIGENCE TO ROLE SYSADMIN;

GRANT USAGE ON WAREHOUSE MISTER_CAR_WASH_WH TO ROLE SYSADMIN;

GRANT USAGE ON CORTEX SEARCH SERVICE MISTER_CAR_WASH_INTELLIGENCE.RAW.MAINTENANCE_LOG_SEARCH TO ROLE SYSADMIN;
GRANT USAGE ON CORTEX SEARCH SERVICE MISTER_CAR_WASH_INTELLIGENCE.RAW.CUSTOMER_FEEDBACK_SEARCH TO ROLE SYSADMIN;

GRANT USAGE ON PROCEDURE MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.PREDICT_CHURN_RISK(VARCHAR) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.PREDICT_EQUIPMENT_FAILURE(VARCHAR) TO ROLE SYSADMIN;
GRANT USAGE ON PROCEDURE MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.PREDICT_UPSELL_OPPORTUNITY(VARCHAR) TO ROLE SYSADMIN;

-- ============================================================================
-- Step 2: Create Snowflake Intelligence Agent
-- ============================================================================

CREATE OR REPLACE AGENT MISTER_CAR_WASH_AGENT
  COMMENT = 'Mister Car Wash Intelligence Agent for operations and customer analytics'
  PROFILE = '{"display_name": "Mister Car Wash Agent", "avatar": "car-wash-icon.png", "color": "blue"}'
  FROM SPECIFICATION
  $$
models:
  orchestration: auto

orchestration:
  budget:
    seconds: 60
    tokens: 32000

instructions:
  response: 'You are an analytics assistant for Mister Car Wash. Use Cortex Analyst for structured metrics, Cortex Search for unstructured logs/feedback, and ML tools for predictions.'
  orchestration: 'Route metrics questions to Cortex Analyst. Route log/text questions to Cortex Search. Route prediction questions to ML tools.'
  system: 'Analyze car wash operations, membership data, and predictive maintenance.'
  sample_questions:
    # ========== 5 SIMPLE QUESTIONS (Cortex Analyst) ==========
    - question: 'How many active members do we have?'
      answer: 'I will count distinct member_id filtering by status=ACTIVE.'
    - question: 'What is the total revenue from wash transactions?'
      answer: 'I will sum the total_revenue metric.'
    - question: 'What is the average tunnel length across all stores?'
      answer: 'I will calculate average tunnel_length_ft.'
    - question: 'How many equipment maintenance events were recorded?'
      answer: 'I will count total maintenance events.'
    - question: 'What is the average customer rating from feedback?'
      answer: 'I will average the rating metric from feedback.'
      
    # ========== 5 COMPLEX QUESTIONS (Cortex Analyst) ==========
    - question: 'Show total revenue and wash count by city.'
      answer: 'I will group transactions by city and sum revenue and count washes.'
    - question: 'Compare average customer rating by membership tier.'
      answer: 'I will join feedback with members and average rating grouped by membership_tier.'
    - question: 'Analyze maintenance costs by equipment type. Show total cost and event count.'
      answer: 'I will group equipment maintenance by equipment_type and sum cost and count events.'
    - question: 'Which weather condition generates the most revenue?'
      answer: 'I will group transactions by weather_condition and sum total_revenue, ordering by desc.'
    - question: 'Show me the top 5 locations by active member count.'
      answer: 'I will count active members grouped by home_location_id (store) and take the top 5.'

    # ========== 5 ML MODEL QUESTIONS (Predictions) ==========
    - question: 'Predict churn risk for active members.'
      answer: 'I will call PredictChurnRisk with status_filter=ACTIVE.'
    - question: 'Which conveyor belts are at risk of failure?'
      answer: 'I will call PredictEquipmentFailure with equipment_type_filter=CONVEYOR.'
    - question: 'Identify upsell opportunities for BASE_UNLIMITED members.'
      answer: 'I will call PredictUpsellOpportunity with tier_filter=BASE_UNLIMITED.'
    - question: 'Predict failure risk for all PUMP_STATION equipment.'
      answer: 'I will call PredictEquipmentFailure with equipment_type_filter=PUMP_STATION.'
    - question: 'What is the churn risk for PAUSED members?'
      answer: 'I will call PredictChurnRisk with status_filter=PAUSED.'

tools:
  - tool_spec:
      type: 'cortex_analyst_text_to_sql'
      name: 'MemberAnalyst'
      description: 'Analyzes member data, wash transactions, and feedback'
  - tool_spec:
      type: 'cortex_analyst_text_to_sql'
      name: 'OperationsAnalyst'
      description: 'Analyzes store locations and equipment maintenance'
  - tool_spec:
      type: 'cortex_search'
      name: 'MaintenanceLogSearch'
      description: 'Searches technician maintenance logs and repair notes'
  - tool_spec:
      type: 'cortex_search'
      name: 'FeedbackSearch'
      description: 'Searches customer feedback comments and reviews'
  - tool_spec:
      type: 'generic'
      name: 'PredictChurnRisk'
      description: 'Predicts risk of member cancellation based on usage and LTV'
      input_schema:
        type: 'object'
        properties:
          status_filter:
            type: 'string'
            description: 'Member status to filter (ACTIVE, PAUSED) or null for all'
        required: []
  - tool_spec:
      type: 'generic'
      name: 'PredictEquipmentFailure'
      description: 'Predicts equipment failure risk based on service history'
      input_schema:
        type: 'object'
        properties:
          equipment_type_filter:
            type: 'string'
            description: 'Equipment type to filter (CONVEYOR, BLOWER, etc.) or null for all'
        required: []
  - tool_spec:
      type: 'generic'
      name: 'PredictUpsellOpportunity'
      description: 'Predicts likelihood of members upgrading their tier'
      input_schema:
        type: 'object'
        properties:
          tier_filter:
            type: 'string'
            description: 'Membership tier to filter (BASE_UNLIMITED, etc.) or null for all'
        required: []

tool_resources:
  MemberAnalyst:
    semantic_view: 'MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.SV_MEMBER_INTELLIGENCE'
    execution_environment:
      type: 'warehouse'
      warehouse: 'MISTER_CAR_WASH_WH'
      query_timeout: 60
  OperationsAnalyst:
    semantic_view: 'MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.SV_OPERATIONAL_INTELLIGENCE'
    execution_environment:
      type: 'warehouse'
      warehouse: 'MISTER_CAR_WASH_WH'
      query_timeout: 60
  MaintenanceLogSearch:
    search_service: 'MISTER_CAR_WASH_INTELLIGENCE.RAW.MAINTENANCE_LOG_SEARCH'
    max_results: 5
    title_column: 'equipment_type'
    id_column: 'maintenance_id'
  FeedbackSearch:
    search_service: 'MISTER_CAR_WASH_INTELLIGENCE.RAW.CUSTOMER_FEEDBACK_SEARCH'
    max_results: 5
    title_column: 'sentiment_label'
    id_column: 'feedback_id'
  PredictChurnRisk:
    type: 'procedure'
    identifier: 'MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.PREDICT_CHURN_RISK'
    execution_environment:
      type: 'warehouse'
      warehouse: 'MISTER_CAR_WASH_WH'
      query_timeout: 60
  PredictEquipmentFailure:
    type: 'procedure'
    identifier: 'MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.PREDICT_EQUIPMENT_FAILURE'
    execution_environment:
      type: 'warehouse'
      warehouse: 'MISTER_CAR_WASH_WH'
      query_timeout: 60
  PredictUpsellOpportunity:
    type: 'procedure'
    identifier: 'MISTER_CAR_WASH_INTELLIGENCE.ANALYTICS.PREDICT_UPSELL_OPPORTUNITY'
    execution_environment:
      type: 'warehouse'
      warehouse: 'MISTER_CAR_WASH_WH'
      query_timeout: 60
  $$;

-- ============================================================================
-- Step 3: Verify Agent Creation
-- ============================================================================
SHOW AGENTS LIKE 'MISTER_CAR_WASH_AGENT';

GRANT USAGE ON AGENT MISTER_CAR_WASH_AGENT TO ROLE SYSADMIN;

SELECT 'Mister Car Wash Agent created successfully' AS status;

