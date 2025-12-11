<img src="../../Snowflake_Logo.svg" width="200">

# Mister Car Wash - Cortex Agent Setup Guide

This guide details the step-by-step process to deploy the Snowflake Intelligence Agent for Mister Car Wash.

## Prerequisites

1.  **Snowflake Account** (Enterprise Edition or higher).
2.  **Snowflake Notebooks** enabled.
3.  **Role Privileges**: `SYSADMIN` or higher to create databases, schemas, and warehouses.

## Deployment Steps

### 1. Database & Schema Setup
Run the following scripts in Snowsight to create the foundational objects:

*   `sql/setup/01_database_and_schema.sql`
*   `sql/setup/02_create_tables.sql`

### 2. Data Generation
Populate the tables with synthetic data representing members, transactions, locations, and maintenance logs:

*   `sql/data/03_generate_synthetic_data.sql`

### 3. Analytics & Feature Views
Create standard views and specific ML Feature Views used for model training:

*   `sql/views/04_create_views.sql`

### 4. Semantic Models (Cortex Analyst)
Create the semantic layer that allows the agent to understand business questions:

*   `sql/views/05_create_semantic_views.sql`
    *   *Note:* Ensure `SV_MEMBER_INTELLIGENCE` includes the `LOCATIONS` table link for geographic queries.

### 5. Cortex Search Services
Enable search capabilities for unstructured data (Technician Notes, Customer Feedback):

*   `sql/search/06_create_cortex_search.sql`

### 6. Machine Learning Models
Train and register the predictive models using Snowflake Notebooks:

1.  Navigate to **Projects > Notebooks** in Snowsight.
2.  Import `notebooks/mister_car_wash_training.ipynb`.
3.  Ensure the environment uses the packages listed in `notebooks/environment.yml`.
4.  **Run All Cells** to train:
    *   `CHURN_RISK_PREDICTOR`
    *   `EQUIPMENT_FAILURE_PREDICTOR`
    *   `UPSELL_PROPENSITY_SCORER`

### 7. ML Model Wrappers
Create SQL functions that allow the agent to call these ML models:

*   `sql/ml/07_create_model_wrapper_functions.sql`

### 8. Agent Creation
Finally, assemble all components into the Cortex Agent:

*   `sql/agent/08_create_intelligence_agent.sql`

## Verification

Once deployed, test the agent in Snowsight (**AI & ML > Cortex Agents**) with questions like:
*   "Show total revenue by city."
*   "Predict churn risk for active members."
*   "Find technician notes about conveyor belt repairs."

