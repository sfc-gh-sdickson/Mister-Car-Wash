-- ============================================================================
-- Mister Car Wash Intelligence Agent - Semantic Views
-- ============================================================================
-- Purpose: Create semantic views for Snowflake Intelligence agents
-- All syntax VERIFIED against Rocket Lab template & Lessons Learned
-- ============================================================================
-- CRITICAL RULE: Dimensions/Metrics: <table_alias>.<SEMANTIC_NAME> AS <PHYSICAL_COLUMN>
-- Example: members.tier AS membership_tier
-- Clause order is MANDATORY: TABLES → RELATIONSHIPS → DIMENSIONS → METRICS → COMMENT
-- ============================================================================

USE DATABASE MISTER_CAR_WASH_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MISTER_CAR_WASH_WH;

-- ============================================================================
-- Semantic View 1: Member Intelligence
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SV_MEMBER_INTELLIGENCE
  TABLES (
    members AS RAW.MEMBERS
      PRIMARY KEY (member_id)
      WITH SYNONYMS ('customers', 'wash club members', 'users')
      COMMENT = 'Unlimited Wash Club members',
    transactions AS RAW.WASH_TRANSACTIONS
      PRIMARY KEY (transaction_id)
      WITH SYNONYMS ('washes', 'visits', 'wash history')
      COMMENT = 'Wash transactions history',
    feedback AS RAW.CUSTOMER_FEEDBACK
      PRIMARY KEY (feedback_id)
      WITH SYNONYMS ('reviews', 'ratings', 'comments')
      COMMENT = 'Customer feedback and ratings',
    locations AS RAW.LOCATIONS
      PRIMARY KEY (location_id)
      WITH SYNONYMS ('stores', 'sites', 'shops')
      COMMENT = 'Wash location details linked to transactions'
  )
  RELATIONSHIPS (
    transactions(member_id) REFERENCES members(member_id),
    feedback(member_id) REFERENCES members(member_id),
    transactions(location_id) REFERENCES locations(location_id)
  )
  DIMENSIONS (
    -- Member dimensions
    members.member_id AS member_id
      WITH SYNONYMS ('customer id', 'id')
      COMMENT = 'Unique member identifier',
    members.join_date AS join_date
      WITH SYNONYMS ('signup date', 'start date')
      COMMENT = 'Date member joined',
    members.tier AS membership_tier
      WITH SYNONYMS ('plan', 'membership level', 'package level')
      COMMENT = 'Membership tier: TITANIUM, PLATINUM, BASE_UNLIMITED',
    members.vehicle_type AS vehicle_type
      WITH SYNONYMS ('car type', 'vehicle')
      COMMENT = 'Type of vehicle: SEDAN, SUV, TRUCK, VAN',
    members.status AS status
      WITH SYNONYMS ('member status', 'account status')
      COMMENT = 'Status: ACTIVE, CANCELLED, PAUSED',
    members.ltv AS ltv_score
      WITH SYNONYMS ('lifetime value', 'value score')
      COMMENT = 'Lifetime Value Score',

    -- Transaction dimensions
    transactions.wash_date AS wash_date
      WITH SYNONYMS ('visit date', 'transaction date')
      COMMENT = 'Date and time of wash',
    transactions.package AS wash_package
      WITH SYNONYMS ('wash type', 'service type')
      COMMENT = 'Wash package purchased/used',
    transactions.weather AS weather_condition
      WITH SYNONYMS ('weather', 'conditions')
      COMMENT = 'Weather condition during wash',

    -- Feedback dimensions
    feedback.visit_date AS visit_date
      WITH SYNONYMS ('review date', 'feedback date')
      COMMENT = 'Date of visit for feedback',
    feedback.sentiment AS sentiment_label
      WITH SYNONYMS ('feeling', 'sentiment')
      COMMENT = 'Sentiment: POSITIVE, NEUTRAL, NEGATIVE',

    -- Location dimensions (Linked via transactions)
    locations.city AS city
      WITH SYNONYMS ('town', 'location city')
      COMMENT = 'City where wash occurred',
    locations.state AS state
      WITH SYNONYMS ('province', 'location state')
      COMMENT = 'State where wash occurred',
    locations.region AS region
      WITH SYNONYMS ('area', 'zone')
      COMMENT = 'Region: WEST, SOUTH, SOUTHEAST'
  )
  METRICS (
    -- Member metrics
    members.total_members AS COUNT(DISTINCT member_id)
      WITH SYNONYMS ('member count', 'customer count')
      COMMENT = 'Total number of members',
    members.avg_ltv AS AVG(ltv_score)
      WITH SYNONYMS ('average value', 'avg ltv')
      COMMENT = 'Average Lifetime Value score',
    
    -- Transaction metrics
    transactions.total_revenue AS SUM(price)
      WITH SYNONYMS ('revenue', 'sales', 'income')
      COMMENT = 'Total revenue from transactions',
    transactions.total_washes AS COUNT(DISTINCT transaction_id)
      WITH SYNONYMS ('wash count', 'visit count')
      COMMENT = 'Total number of washes',
    transactions.avg_duration AS AVG(duration_minutes)
      WITH SYNONYMS ('wash time', 'average duration')
      COMMENT = 'Average duration of wash in minutes',

    -- Feedback metrics
    feedback.avg_rating AS AVG(rating)
      WITH SYNONYMS ('average score', 'star rating')
      COMMENT = 'Average customer rating (1-5)',
    feedback.avg_nps AS AVG(nps_score)
      WITH SYNONYMS ('net promoter score', 'nps')
      COMMENT = 'Average Net Promoter Score'
  )
  COMMENT = 'Member Intelligence - comprehensive view of members, washes, and satisfaction';

-- ============================================================================
-- Semantic View 2: Operational Intelligence
-- ============================================================================
CREATE OR REPLACE SEMANTIC VIEW SV_OPERATIONAL_INTELLIGENCE
  TABLES (
    locations AS RAW.LOCATIONS
      PRIMARY KEY (location_id)
      WITH SYNONYMS ('stores', 'sites', 'shops')
      COMMENT = 'Wash location details',
    equipment AS RAW.EQUIPMENT_MAINTENANCE
      PRIMARY KEY (maintenance_id)
      WITH SYNONYMS ('maintenance logs', 'repairs', 'machinery')
      COMMENT = 'Equipment maintenance records'
  )
  RELATIONSHIPS (
    equipment(location_id) REFERENCES locations(location_id)
  )
  DIMENSIONS (
    -- Location dimensions
    locations.location_id AS location_id
      WITH SYNONYMS ('store id', 'site id')
      COMMENT = 'Unique location identifier',
    locations.city AS city
      WITH SYNONYMS ('town', 'municipality')
      COMMENT = 'City location',
    locations.state AS state
      WITH SYNONYMS ('province', 'territory')
      COMMENT = 'State location',
    locations.region AS region
      WITH SYNONYMS ('area', 'zone')
      COMMENT = 'Region: WEST, SOUTH, SOUTHEAST',
    locations.manager AS manager_name
      WITH SYNONYMS ('store manager', 'boss')
      COMMENT = 'Name of store manager',
    locations.store_status AS status
      WITH SYNONYMS ('operational status', 'is open')
      COMMENT = 'Store status: OPEN, RENOVATION, CLOSED',

    -- Equipment dimensions
    equipment.equipment_type AS equipment_type
      WITH SYNONYMS ('machine type', 'part')
      COMMENT = 'Type: CONVEYOR, BLOWER, BRUSH, PUMP_STATION',
    equipment.maintenance_type AS maintenance_type
      WITH SYNONYMS ('service type', 'repair type')
      COMMENT = 'Type: ROUTINE, REPAIR, REPLACEMENT',
    equipment.severity AS severity
      WITH SYNONYMS ('issue level', 'criticality')
      COMMENT = 'Severity: LOW, MEDIUM, HIGH, CRITICAL'
  )
  METRICS (
    -- Location metrics
    locations.total_stores AS COUNT(DISTINCT location_id)
      WITH SYNONYMS ('store count', 'location count')
      COMMENT = 'Total number of locations',
    locations.avg_tunnel_length AS AVG(tunnel_length_ft)
      WITH SYNONYMS ('average length', 'tunnel size')
      COMMENT = 'Average tunnel length in feet',

    -- Equipment metrics
    equipment.total_maintenance_events AS COUNT(DISTINCT maintenance_id)
      WITH SYNONYMS ('repair count', 'service count')
      COMMENT = 'Total number of maintenance events',
    equipment.total_maintenance_cost AS SUM(cost)
      WITH SYNONYMS ('repair cost', 'maintenance spend')
      COMMENT = 'Total cost of maintenance',
    equipment.avg_days_since_service AS AVG(days_since_last_service)
      WITH SYNONYMS ('service interval', 'average time between service')
      COMMENT = 'Average days since last service'
  )
  COMMENT = 'Operational Intelligence - view of store performance and equipment health';

SELECT 'All semantic views created successfully' AS status;
