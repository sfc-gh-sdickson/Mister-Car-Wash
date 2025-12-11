<img src="Snowflake_Logo.svg" width="200">

# Mister Car Wash Intelligence Agent

A Snowflake Intelligence solution tailored for Mister Car Wash business operations, featuring Cortex Analyst (Structured Data), Cortex Search (Unstructured Data), and Machine Learning (Predictive Analytics).

## Overview

This solution provides a comprehensive analytics agent capable of answering questions about:
- **Membership & Churn**: Unlimited Wash Club performance and churn risk.
- **Operations**: Store performance, revenue, and tunnel efficiency.
- **Maintenance**: Equipment health, failure predictions, and technician logs.
- **Customer Experience**: Feedback sentiment and upsell opportunities.

## Directory Structure

```
Mister Car Wash/
├── notebooks/
│   ├── environment.yml                # Conda environment for Snowpark
│   └── mister_car_wash_training.ipynb # ML Model training notebook
└── sql/
    ├── setup/
    │   ├── 01_database_and_schema.sql
    │   └── 02_create_tables.sql
    ├── data/
    │   └── 03_generate_synthetic_data.sql
    ├── views/
    │   ├── 04_create_views.sql        # Analytics & ML Feature Views
    │   └── 05_create_semantic_views.sql
    ├── search/
    │   └── 06_create_cortex_search.sql
    ├── ml/
    │   └── 07_create_model_wrapper_functions.sql
    └── agent/
        └── 08_create_intelligence_agent.sql
```

## Setup Instructions

### 1. Database & Data Setup
Run the SQL scripts in the `sql/` directory in the following order using Snowsight:

1.  **`sql/setup/01_database_and_schema.sql`**: Creates `MISTER_CAR_WASH_INTELLIGENCE` database.
2.  **`sql/setup/02_create_tables.sql`**: Creates tables for locations, members, transactions, etc.
3.  **`sql/data/03_generate_synthetic_data.sql`**: Generates realistic synthetic data for testing.
4.  **`sql/views/04_create_views.sql`**: Creates standard views and **ML Feature Views** (Single Source of Truth).
5.  **`sql/views/05_create_semantic_views.sql`**: Creates Semantic Views for Cortex Analyst.
6.  **`sql/search/06_create_cortex_search.sql`**: Creates Cortex Search services for unstructured text (Logs, Feedback).

### 2. Machine Learning Training
1.  Navigate to **Projects > Notebooks** in Snowsight.
2.  Import `notebooks/mister_car_wash_training.ipynb`.
3.  Ensure `notebooks/environment.yml` packages are installed (snowflake-ml-python, etc.).
4.  Run all cells to train and register the 3 ML models:
    -   `CHURN_RISK_PREDICTOR`
    -   `EQUIPMENT_FAILURE_PREDICTOR`
    -   `UPSELL_PROPENSITY_SCORER`

### 3. Agent Deployment
1.  **`sql/ml/07_create_model_wrapper_functions.sql`**: Creates SQL Stored Procedures to expose ML models as tools.
2.  **`sql/agent/08_create_intelligence_agent.sql`**: Creates the `MISTER_CAR_WASH_AGENT` with all tools and sample questions.

## Verification
- **Semantic Views**: Syntax verified as `table.semantic_name AS physical_column`.
- **ML Integration**: Uses Feature Views (`V_..._FEATURES`) to ensure Notebook training data matches Procedure inference data exactly.
- **Data Generation**: Uses `UNIFORM` with constants and `GENERATOR` correctly.

## Sample Questions
The agent is pre-configured with:
- **5 Simple Questions**: "How many active members do we have?"
- **5 Complex Questions**: "Show total revenue and wash count by city."
- **5 ML Questions**: "Predict churn risk for active members."

