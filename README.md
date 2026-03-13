# QuickBite Express — Crisis Impact & Recovery Analysis

## 📌 Executive Summary

In June 2025, QuickBite Express experienced a severe operational and reputational crisis caused by a food safety backlash and a delivery infrastructure outage.

The result:
- Sharp customer contraction  
- Revenue collapse  
- Delivery delays  
- Rating deterioration  

This project diagnoses the root cause of the revenue decline and proposes a data-driven recovery strategy using SQL, Python, and Tableau.

---

## 🎯 Business Objective

This analysis focused on:

- Identifying the primary driver of revenue collapse  
- Measuring behavioral changes across Pre-Crisis, Crisis, and Recovery phases  
- Evaluating operational breakdown impact  
- Designing strategic recovery recommendations  

---

## 🗂 Data Model & Structure

The dataset follows a **star schema architecture**.

### Fact Tables
- `fact_orders` — 1 row per order  
- `fact_order_items` — 1 row per item within an order  
- `fact_delivery_performance` — 1 row per delivery record  
- `fact_ratings` — 1 row per order rating  

### Dimension Tables
- `dim_customer`  
- `dim_restaurant`  
- `dim_menu_item`  
- `dim_date` (created during transformation)  

All analysis was conducted at the correct grain level to prevent double-counting and aggregation bias.

---

## 🧠 Analytical Framework

### Phase Segmentation
- **Pre-Crisis:** Before June 2025  
- **Crisis:** June 2025  
- **Post-Crisis:** July 2025 onward  

### Revenue Decomposition

Revenue was broken into structural drivers:
Revenue = Active Customers × Order Frequency × Average Order Value (AOV)


This allowed isolation of the true driver of decline rather than relying on surface-level revenue trends.

### Cohort Retention Analysis

May 2025 was used as a fixed baseline cohort.

Retention was measured by tracking how many May-active customers continued ordering in:
- June (Crisis)
- July (Post-Crisis)

This ensured consistent time-window comparison.

---

## 📊 Key Findings

- Active customers declined by ~90% during the crisis phase.  
- AOV remained stable (~351) across all phases.  
- Order frequency remained approximately 1.0 with minimal variation.  
- Delivery times increased sharply during the crisis period.  
- Customer ratings deteriorated significantly.  
- May cohort retention dropped sharply in June, indicating immediate disengagement.

### Core Diagnosis

Revenue decline was driven primarily by **customer volume contraction**, not reduced basket size or engagement intensity.

Churn was broad-based, suggesting a systemic trust shock rather than isolated service dissatisfaction.

---

## 📈 Operational Insights

- Demand collapse occurred immediately following the crisis trigger.  
- Retention differences across customer segments were minor relative to total churn magnitude.  
- Post-crisis recovery shows partial reactivation but not full restoration of the pre-crisis customer base.  

---

## 🚀 Strategic Recommendations

- Prioritize reactivation of high-frequency pre-crisis customers.  
- Strengthen SLA monitoring and delivery reliability.  
- Rebuild platform trust through visible safety compliance measures.  
- Allocate recovery investments toward high-value customer segments.  
- Continuously monitor cohort-based retention during recovery.  

---

## 🛠 Tools & Techniques

- **SQL** — Data cleaning, transformation, aggregation  
- **Python (Pandas, Matplotlib/Seaborn)** — Exploratory analysis  
- **Tableau** — Executive recovery dashboard  
- **Star Schema Modeling** — Structured analytical design  
- **Cohort Analysis** — Retention measurement  

---

## 📂 Repository Structure
quickbite-express-crisis-recovery/
├─ notebooks/
├─ sql/
├─ assets/
├─ data/
└─ README.md


- SQL scripts are executed sequentially.
- Dashboard screenshots are available in the `assets` folder.

---

## ⚠ Assumptions & Limitations

- Retention is measured using the May cohort continuation into subsequent months.  
- Revenue per order is assumed correctly recorded in fact tables.  
- Full raw datasets are not included in this repository.  

---

## 🎯 Project Outcome

This case study demonstrates:

- Structured business problem framing  
- Revenue driver decomposition  
- Cohort-based retention analysis  
- Crisis impact diagnosis  
- Executive-level dashboard storytelling  

The project simulates a real-world recovery scenario and presents actionable insights suitable for leadership decision-making.
