# 🏋️‍♂️ FitZone-Gym-Strategic-Performance-Analytics

**Skills demonstrated:** 
  1. database design
  2. SQL Server
  3. T-SQL
  4. Power BI
  5. DAX
  6. data cleaning
  7. business intelligence

**📌 Project Overview**

This project transforms raw gym management data into a 6-page strategic dashboard. The goal was to identify why revenue was declining despite high member loyalty and to uncover hidden operational risks in staffing and equipment maintenance.

**🛠 Tech Stack**

Data Extraction: SQL (Complex Joins & Aggregations)

Visualization: Power BI

Analysis: Business Intelligence & Financial Modeling

**🚀 Key Business Insights**
1. The "Found Money" Strategy (Revenue Growth)
_Discovery_: Identified 74 highly engaged Day Pass members contributing only €928/month.

_Impact_: Proposed a targeted upgrade campaign to Premium tiers, unlocking an 81% revenue increase (€3,882/month) from this segment alone.

2. The Payroll Crisis (Profitability)
_Discovery_: Coach payroll consumes 64% of total revenue, vastly exceeding the 40% industry benchmark.

_Insight_: With classes only 51% full, the gym is paying fixed costs for "empty rooms."

_Recommendation_: Transition to a Variable Pay Model (Base + Per-Head Bonus) to align labor costs with attendance.

3. The 9-Year Maintenance "Time Bomb" (Risk Management)
_Discovery_: 100% of active equipment is overdue for service, with some assets in the high-traffic Functional Zone neglected for over 3,300 days.

_Risk_: High liability and potential for catastrophic failure of a €914K asset base.

**💻 SQL: The "Under the Hood" Logic**

I used SQL to clean and validate the data before visualization. For example, calculating the net profit per session required joining multiple tables (Staffing, Attendance, and Membership) to expose the -€4,000 monthly loss in Functional Training.

<img width="1327" height="239" alt="image" src="https://github.com/user-attachments/assets/ea32c935-0345-468b-867f-15d266c01406" />

**📊 Dashboard Preview**

1. Executive Overview

<img width="1159" height="652" alt="image" src="https://github.com/user-attachments/assets/8c6d793d-d9e4-4d39-9b5b-5c13e843d18a" />

2. Financial Deep Dive

<img width="1161" height="662" alt="image" src="https://github.com/user-attachments/assets/1e2117a4-ada8-44ae-8e13-1d256dc78178" />

3. Growth Opportunities

<img width="1159" height="655" alt="image" src="https://github.com/user-attachments/assets/1e859bef-835f-4c04-a5b6-7d657ca740cc" />

---

**🏁 Conclusion**

By connecting disparate data points—from equipment service dates to coach ratings—this analysis provides a roadmap to stabilize FitZone Gym's revenue and eliminate critical operational liabilities.


---
**Tools & Technologies**

Tool Purpose:

Python: Generating realistic CSV datasets (1,200+ members, 5,000+ attendance records)

SQL Server Express 17	Database engine,
SQL Server Management Studio (SSMS) 22: Schema creation, query development, data import

T-SQL:	All analytical queries — JOINs, CTEs, window functions, subqueries

Power BI Desktop:	Interactive 6-page dashboard with 15+ DAX measures

---
**Database Schema**

The database `GymAnalysis` contains 6 tables in a star-like relational structure:
```
members ──────────── attendance ──────── coaches
   │                                        │
   └──────────── payments          group\_classes
                                        │
                                   equipment
```
**Project Structure**
```
gym-performance-analytics/
│
├── data/
│   ├── members.csv
│   ├── coaches.csv
│   ├── attendance.csv
│   ├── payments.csv
│   ├── equipment.csv
│   └── group\_classes.csv
│
├── sql/
│   ├── 00\_setup\_gym\_db\_SQLSERVER.sql     # Database + schema creation + BULK INSERT
│   └── 01\_gym\_analysis\_queries\_SQLSERVER.sql  # All analytical queries (7 sections)
│
├── powerbi/
│   └── GymPerformanceDashboard.pbix      # Power BI dashboard file
│
└── README.md
```
---
Author [Kristina Avetisian]
Lithuania · [Your LinkedIn URL] · [kristina.emilija.avetisian@gmail.com]

---

This project was built as part of a data analyst portfolio. All data is entirely fictitious and generated programmatically for demonstration purposes.
