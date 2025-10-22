# 🏗️ SQL Data Warehouse Project

This repository documents the development of an end-to-end **Data Warehouse (DWH)** solution, from requirements analysis to multi-layered architecture design and data transformation. The project demonstrates how raw data from CRM and ERP sources is ingested, cleaned, transformed, and modeled into analytical structures suitable for business reporting.

---

## 📊 **Data Flow Overview**

The diagram below illustrates the overall data pipeline, showing the movement of data from **source systems** into the **Bronze**, **Silver**, and **Gold** layers.


<img width="814" height="562" alt="Screenshot 2025-10-22 140349" src="https://github.com/user-attachments/assets/bfc62ba0-88b7-4f53-8038-4ada7d675d3c" />










---

## 🧱 **Project Architecture**

### **1. Source Systems**
- **CRM**: Provides customer, product, and sales data.
- **ERP**: Provides operational data such as locations, customer codes, and pricing categories.

### **2. Bronze Layer (Raw Layer)**
- Stores raw ingested data from CRM and ERP systems.
- Minimal transformation — used primarily for archival and traceability.
- Example tables:  
  - `crm_sales_details`  
  - `crm_cust_info`  
  - `crm_prd_info`  
  - `erp_cust_az12`  
  - `erp_loc_a101`  
  - `erp_px_cat_g1v2`

### **3. Silver Layer (Cleansed & Integrated Layer)**
- Cleans and standardizes data using SQL transformations.  
- Handles missing values, removes duplicates, applies business rules.  
- Uses functions like **COALESCE()** and **CASE WHEN** for data quality improvement.
- Example tables:  
  - `crm_sales_details`  
  - `crm_cust_info`  
  - `crm_prd_info`  
  - `erp_cust_az12`  
  - `erp_loc_a101`  
  - `erp_px_cat_g1v2`

### **4. Gold Layer (Analytics Layer)**
- Combines data into business-focused models.
- Enables analytics and reporting through **fact and dimension** tables.
- Example tables:  
  - `fact_sales`  
  - `dim_customers`  
  - `crm_prd_info`

---

## ⚙️ **Tools & Technologies**
- **SQL Server / PostgreSQL** – Data transformation and modeling  
- **Draw.io** – Data architecture and flow diagrams  
- **Excel / CSV** – Sample data and validation  
- **GitHub** – Version control and progress tracking  
- **Notion** – Project task management and documentation  

---

## 📅 **Project Plan**
| Day | Focus Area | Key Deliverables |
|-----|-------------|------------------|
| **Day 1** | Requirements & Architecture | Define data sources, design data flow diagram |
| **Day 2** | Bronze Layer Setup | Create raw ingestion tables and load source data |
| **Day 3** | Silver Layer | Clean, standardize, and integrate datasets |
| **Day 4** | Gold Layer | Build fact and dimension models |
| **Day 5** | Testing & Documentation | Validate data, finalize diagrams, commit all updates |

---

## 🔍 **Key SQL Concepts Applied**
- **COALESCE()** – Handling nulls and default values  
- **JOINS** – Combining CRM and ERP data  
- **CASE WHEN** – Business rule logic  
- **CTEs** – Stepwise transformations  
- **Data Validation Queries** – Row counts, completeness checks  

---

