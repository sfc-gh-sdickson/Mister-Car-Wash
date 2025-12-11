<img src="../../Snowflake_Logo.svg" width="200">

# Mister Car Wash - Snowflake Migration POC Plan

**Goal:** Demonstrate that Snowflake can replace the "POS Ecosystem" and "Customer Directory" pipelines currently in Domo, delivering higher performance, lower latency, and reduced costs compared to the current $346K/year contract.

---

## 1. Executive Summary

| Challenge | Current State (Domo) | Target State (Snowflake) |
| :--- | :--- | :--- |
| **Latency** | 4-6.5 Hours (Customer Directory) | **< 15 Minutes** (Near Real-Time) |
| **Complexity** | 4 Fragmented ETLs (1of3, 2of3...) | **1 Unified Pipeline** (Dynamic Tables) |
| **Ingestion** | Full Reload (No CDC support) | **Incremental CDC** (Streams) |
| **Cost** | ~$50/day (Legacy Credits) | **< $20/day** (Consumption) |
| **Viz** | Data moved & materialized in Domo | **Live Federation** (Zero Copy) |

---

## 2. Success Criteria (KPIs)

Based on the provided metrics, the POC will be evaluated against these targets:

1.  **POS Pipeline Performance:**
    *   *Current:* 1.5h ingestion + 45m ETL (Total ~2.5h)
    *   *Target:* End-to-end processing in **< 30 minutes**.
2.  **Customer Directory Freshness:**
    *   *Current:* 4-6.5 hours latency.
    *   *Target:* Marketing-ready data availability in **< 15 minutes**.
3.  **SCD Type 2 Efficiency:**
    *   *Current:* Manual "intense processing" (~30 mins).
    *   *Target:* Automated Type 2 history tracking via Merge/Streams.
4.  **Cost Efficiency:**
    *   *Current:* 43 Credits/day (~$50/day).
    *   *Target:* Demonstrate significantly lower credit consumption for the same workload.

---

## 3. POC Architecture

### Step 1: Ingestion & CDC (Solving "Full Reloads")
*   **The Problem:** Domo connectors reload the entire 7M row customer table hourly.
*   **The Snowflake Solution:**
    *   Load the baseline "Complete Dataset" (4.5GB) once.
    *   Load "Differential Datasets" (1M rows) into a staging table.
    *   Use **Snowflake Streams** to process *only* the changes, eliminating the 6 credit/hour overage penalty.

### Step 2: Unified POS Pipeline
*   **The Problem:** The "1of3, 2of3, 3of3" architecture exists solely to work around Domo's processing limits.
*   **The Snowflake Solution:**
    *   Create a single **Dynamic Table** (`POS_MATERIALIZED`) that joins `Tickets` and `TicketDetails`.
    *   Snowflake's engine handles the 40M row join natively without needing arbitrary date partitions.
    *   *Action:* Use the **Argos Converter** to translate the Domo Magic ETL JSON to Snowflake SQL.

### Step 3: Automated SCD Type 2 (Customer History)
*   **The Problem:** Complex logic required to track customer changes over time.
*   **The Snowflake Solution:**
    *   Implement a `MERGE` statement triggered by the Stream.
    *   Logic:
        1.  **Update:** Close out old records (`Effective_End_Date = NOW()`) where hash differs.
        2.  **Insert:** Add new active records (`Effective_Start_Date = NOW()`).

### Step 4: Visualization (Federation)
*   **The Problem:** Paying for "Materialized Row Credits" to store data in Domo.
*   **The Snowflake Solution:**
    *   Configure Domo's **Federated Adapter** to query Snowflake directly.
    *   Data remains in Snowflake; Domo acts as a visualization layer only.
    *   *Metric:* Time from data change to dashboard refresh (< 1 minute).

---

## 4. Test Plan (The Script)

1.  **Baseline Load:**
    *   Load the 4.5GB anonymized CSV using `COPY INTO`.
    *   *Success Metric:* < 15 minutes.
2.  **Differential Load (CDC):**
    *   Load the 1M row "change file" and trigger the SCD Type 2 pipeline.
    *   *Success Metric:* < 5 minutes.
3.  **Unified Transformation:**
    *   Run the consolidated POS SQL transformation (joining Tickets/Details).
    *   *Success Metric:* < 30 minutes.
4.  **Cost Analysis:**
    *   Run `WAREHOUSE_METERING_HISTORY` to calculate exact POC cost.

---

## 5. Business Value (The "Closer")

*   **Marketing Agility:** Enabling Marketing to react to customer behavior in 15 minutes allows for immediate win-back offers and personalized engagement, which is impossible with a 6-hour delay.
*   **Operational Simplicity:** Reducing 4+ pipelines to 1 reduces maintenance overhead for Jim & Jorge, allowing them to focus on optimization rather than "fixing broken ETLs."
*   **Future Proofing:** Eliminates the risk of "Row Count Overage" charges (7B rows) as the business scales.

