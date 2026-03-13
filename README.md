#### **Quite-Bite Express - Crisis Impact \& Recovery Analysis**

##### 📌 Project Overview

In June 2025, Quick-Bite Express experienced a major operational and reputational crisis driven by safety backlash and a delivery infrastructure outage. This resulted in a sharp desline in customer activity and revenue.

The objective of this project was to:

* Diagnose the root cause of the revenue collapse
* Analyze behavioral changes across pre-crisis, crisis, and recovery phases
* Evaluate operational impact
* Provide data-driven recovery recommendations

This project simulates a real-world business case using SQL, Python, and Tableau.



##### 🗂 Data Model

The dataset follows a star schema structure:



###### Fact Tables



* fact\_orders – 1 row per order
* fact\_order\_items – 1 row per order item
* fact\_delivery\_performance – 1 row per order delivery record
* fact\_ratings – 1 row per order rating



###### Dimension Tables



* dim\_customer
* dim\_restaurant
* dim\_menu\_item
* dim\_date (created during transformation)



The analysis was conducted at the appropriate grain level to avoid double-counting.



##### 🧠 Analytical Framework



###### Phase Definition



* Pre-Crisis: Before June 2025
* Crisis: June 2025
* Post-Crisis: July 2025 onward



###### Revenue Decomposition



Revenue was decomposed into three drivers:

Revenue = Active Customers × Order Frequency × Average Order Value (AOV)



This allowed isolation of the primary driver of decline.



##### 📊 Key Findings



* Active customers declined by \~90% during the crisis phase.
* AOV remained stable (\~351) across all phases.
* Order frequency remained close to 1.0 with minimal variation.
* Delivery time increased sharply during the crisis period.
* Customer ratings dropped significantly during the crisis.
* Retention dropped sharply from the May cohort into June, indicating immediate disengagement.
* Revenue decline was driven primarily by customer volume contraction rather than reduced basket size or engagement.



##### 📈 Operational Insights



* The demand collapse was systemic and platform-wide.
* Retention differences across customer segments were small relative to total churn.
* The data suggests a trust-driven demand shock rather than purely experience-based attrition.
* Post-crisis recovery shows partial customer return but not full restoration of the pre-crisis base.



##### 🚀 Strategic Recommendations



* Prioritize reactivation of high-frequency pre-crisis customers.
* Strengthen operational reliability and SLA monitoring.
* Rebuild trust through visible food safety compliance initiatives.
* Focus recovery investments on high-value customer segments.
* Monitor cohort-based retention continuously during recovery.



##### 🛠 Tools Used



* **SQL** – Data cleaning, transformation, aggregation
* **Python (Pandas, Matplotlib/Seaborn)** – Exploratory analysis
* **Tableau** – Executive recovery dashboard
* **Star Schema Modeling** – Structured analytical design



##### 📂 Repository Structure



quickbite-express-crisis-recovery/

├─ notebooks/

├─ sql/

├─ assets/

├─ data/

└─ README.md



SQL scripts are executed in the order they appear.

Dashboards are available in the assets folder.



##### ⚠ Assumptions \& Limitations



Retention is measured using the May cohort continuation into subsequent months.

Analysis assumes revenue per order is correctly recorded in the fact tables.

Full raw datasets are not included in the repository.



##### 🎯 Outcome



This project demonstrates:



* Business problem framing
* Metric decomposition
* Cohort-based retention analysis
* Crisis impact diagnosis
* Executive-level dashboard storytelling



The analysis simulates a real-world recovery scenario and presents actionable insights for leadership decision-making.



