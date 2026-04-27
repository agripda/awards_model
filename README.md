
# 📑 FACT (FWO Entitlement Analysis & Compliance Tool)

[![R-Shiny](https://img.shields.io/badge/R-Shiny-blue.svg)](https://shiny.rstudio.com/)
[![Python-ML](https://img.shields.io/badge/Python-Machine%20Learning-green.svg)](https://www.python.org/)
[![License-MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🎯 Project Overview
**FACT** is a high-performance, end-to-end data analytics solution designed to streamline the operations of the **Fair Work Ombudsman (FWO)**. It automates the modeling of **Modern Awards** and **Enterprise Agreements** to detect non-compliance and calculate underpayments from massive employer timesheet datasets.

Beyond a simple calculator, FACT is a **Forensic Analytics Platform** that empowers Inspectors to visualize legal evidence and use Machine Learning to detect patterns of data manipulation or systemic wage theft.

---

## ✨ Key Features

### 1. Automated Entitlement Modeling (R/SQL)
- **Complex Logic Engine:** Handles multi-tiered rules including weekend penalties, overtime (OT) thresholds, and mandatory unpaid break deductions using vectorized operations.
- **Star Schema Architecture:** Utilizes a normalized data model (Fact/Dimension) to optimize query performance and ensure data integrity across large-scale audits.
- **Rule Extensibility:** Designed for regulatory agility; new Award clauses or rate increases can be updated via data configuration without changing the core codebase.

### 2. Interactive Analytics Dashboard (R Shiny)
- **What-if Simulation:** Real-time re-calculation of underpayments when toggling parameters like Award Levels or base hourly rates.
- **Evidence Visualization:** High-impact "Gap Analysis" charts overlaying Actual Pay vs. Legal Entitlements to serve as court-ready evidence.
- **Forensic Reporting:** One-click generation of detailed PDF/Excel reports for litigation support.

### 3. Predictive Regulatory Insights (Python/ML)
- **Anomaly Detection:** Uses **Isolation Forest** algorithms to flag "too-perfect" or suspiciously consistent payroll records that may indicate record tampering.
- **Risk Scoring:** Employs **XGBoost** to rank businesses by "Breach Probability," allowing the FWO to allocate investigative resources to high-risk sectors proactively.

---

## 🛠 Tech Stack

- **Frontend/UI:** R Shiny, Shinydashboard, Plotly (Interactive Visuals)
- **Data Engineering:** R (Tidyverse), SQL (Relational Modeling)
- **Machine Learning:** Python (Scikit-learn, XGBoost)
- **Database:** Azure SQL / Snowflake (Optimized for 1M+ rows)
- **DevOps:** GitHub Actions (CI/CD), Git

---

## 📂 Project Structure

```text
.
├── app/
│   ├── ui.R             # Shiny Dashboard UI definition
│   ├── server.R         # Reactive engine and calculation logic
│   └── global.R         # Data loading and global parameters
├── engine/
│   ├── award_logic.R    # Core R functions for entitlement modeling
│   └── ml_anomaly.py    # Python scripts for fraud & risk detection
├── data/
│   ├── dim_awards.csv   # Award dimension (Metadata & Rules)
│   ├── dim_rates.csv    # Pay rates dimension (Normalized Values)
│   └── sample_fact.csv  # Mock employer timesheet data (Daily Granularity)
├── docs/
│   └── SDD_FACT.md      # Solution Design Document
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
- R (>= 4.0.0)
- Python (>= 3.8)
- R Packages: `shiny`, `tidyverse`, `lubridate`, `plotly`, `DT`
- Python Packages: `pandas`, `scikit-learn`, `xgboost`

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/dkims/FACT-FWO-Tool.git
   ```
2. Install R dependencies:
   ```R
   install.packages(c("shiny", "shinydashboard", "tidyverse", "plotly", "DT"))
   ```
3. Run the Shiny App:
   ```R
   shiny::runApp('app/')
   ```

---

## 💡 Why FACT? (Business Impact)

1. **Precision:** Eliminates manual calculation errors, ensuring legal findings are 100% defensible.
2. **Efficiency:** Reduces the audit time for large-scale enterprises from months to days.
3. **Proactive Regulation:** Transitions the agency from reactive complaint-handling to data-driven proactive enforcement.
