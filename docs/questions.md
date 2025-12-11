<img src="../../Snowflake_Logo.svg" width="200">

# Mister Car Wash - Sample Questions

These questions are designed to test the capabilities of the Mister Car Wash Intelligence Agent across its three main domains: **Structured Analytics (Cortex Analyst)**, **Unstructured Search (Cortex Search)**, and **Predictive Analytics (ML Models)**.

---

## 1. Simple Questions (Structured Data)
*Target: SV_MEMBER_INTELLIGENCE, SV_OPERATIONAL_INTELLIGENCE*

1.  **"How many active members do we have?"**
    *   *Verifies:* Basic filtering on `MEMBERS` table.
2.  **"What is the total revenue from wash transactions?"**
    *   *Verifies:* Aggregation on `WASH_TRANSACTIONS`.
3.  **"What is the average tunnel length across all stores?"**
    *   *Verifies:* Aggregation on `LOCATIONS`.
4.  **"How many equipment maintenance events were recorded?"**
    *   *Verifies:* Counting records in `EQUIPMENT_MAINTENANCE`.
5.  **"What is the average customer rating from feedback?"**
    *   *Verifies:* Aggregation on `CUSTOMER_FEEDBACK`.

---

## 2. Complex Questions (Joins & Grouping)
*Target: SV_MEMBER_INTELLIGENCE (with Locations link), SV_OPERATIONAL_INTELLIGENCE*

1.  **"Show total revenue and wash count by city."**
    *   *Verifies:* Join between `WASH_TRANSACTIONS` and `LOCATIONS` (via the semantic view fix).
2.  **"Compare average customer rating by membership tier."**
    *   *Verifies:* Join between `CUSTOMER_FEEDBACK` and `MEMBERS`.
3.  **"Analyze maintenance costs by equipment type. Show total cost and event count."**
    *   *Verifies:* Grouping and multiple aggregations on `EQUIPMENT_MAINTENANCE`.
4.  **"Which weather condition generates the most revenue?"**
    *   *Verifies:* Grouping by `weather_condition` dimension in transactions.
5.  **"Show me the top 5 locations by active member count."**
    *   *Verifies:* Aggregation, sorting, and limiting results.

---

## 3. ML Model Questions (Predictive)
*Target: SQL Wrapper Functions calling Snowpark ML Models*

1.  **"Predict churn risk for active members."**
    *   *Calls:* `PREDICT_CHURN_RISK(status_filter='ACTIVE')`
    *   *Model:* Logistic Regression (Churn)
2.  **"Which conveyor belts are at risk of failure?"**
    *   *Calls:* `PREDICT_EQUIPMENT_FAILURE(equipment_type_filter='CONVEYOR')`
    *   *Model:* Random Forest (Maintenance)
3.  **"Identify upsell opportunities for BASE_UNLIMITED members."**
    *   *Calls:* `PREDICT_UPSELL_OPPORTUNITY(tier_filter='BASE_UNLIMITED')`
    *   *Model:* Logistic Regression (Upsell)
4.  **"Predict failure risk for all PUMP_STATION equipment."**
    *   *Calls:* `PREDICT_EQUIPMENT_FAILURE(equipment_type_filter='PUMP_STATION')`
5.  **"What is the churn risk for PAUSED members?"**
    *   *Calls:* `PREDICT_CHURN_RISK(status_filter='PAUSED')`

---

## 4. Unstructured Search Questions
*Target: Cortex Search Services*

1.  **"Search for maintenance logs related to broken chains."**
    *   *Target:* `MAINTENANCE_LOG_SEARCH` (Technician Notes)
2.  **"Find customer feedback about long wait times."**
    *   *Target:* `CUSTOMER_FEEDBACK_SEARCH` (Comments)
3.  **"Show me critical maintenance issues involving motors."**
    *   *Target:* `MAINTENANCE_LOG_SEARCH` filtering by severity/content.

