# Data Pipeline Project: Snowflake + dbt + Airflow

## 1. Project Overview

This project implements a modern data pipeline using **Snowflake**, **dbt**, and **Apache Airflow**. The pipeline extracts raw data, transforms it into analytics-ready tables using dbt, and schedules/monitors workflows via Airflow.

The purpose is to create a scalable, testable, and maintainable ETL/ELT framework for analytics engineering.

---

## 2. Architecture Diagram

```
   ┌───────────────┐      ┌───────────────┐      ┌───────────────┐      ┌───────────────┐
   │   Data Source │ ---> │   Snowflake   │ ---> │      dbt      │ ---> │  Analytics/BI │
   └───────────────┘      └───────────────┘      └───────────────┘      └───────────────┘
                                ▲                        │
                                │                        ▼
                           ┌───────────────┐      ┌───────────────┐
                           │    Airflow    │ <--- │ dbt Cloud/CLI │
                           └───────────────┘      └───────────────┘
```

**Flow:**

1. Data is loaded into **Snowflake**.
2. **dbt** models transform the data.
3. **Airflow** orchestrates and monitors the dbt runs.
4. Final datasets are available for BI tools.

---

## 3. Prerequisites

- **Snowflake account** (with appropriate warehouse, database, and schema)
- **dbt CLI** installed locally
- **Airflow** environment (local, Astronomer, or MWAA)
- Python 3.9+
- GitHub repository for version control

---

## 4. Step-by-Step Setup

### 4.1 Snowflake Setup

1. Create a warehouse, database, and schema:
```sql
create warehouse if not exists dbt_wh with warehouse_size="small";
create database if not exists dbt_db;
create role if not exists dbt_role;

--quick view into the grants
show grants on warehouse dbt_wh;

grant usage on warehouse dbt_wh to role dbt_role;
grant role dbt_role to user DerrickSimi;
grant all on database dbt_db to role dbt_role;

use role dbt_role;
create schema if not exists dbt_db.dbt_schema;

-- very highlevel statements
-- incase you will want to one day drop your warehouse and database

--use role accountadmin;
--drop warehouse if exists dbt_wh;
--drop database if exists dbt_db;
--drop role if exists dbt_role;

-- show columns in view dbt_db.dbt_schema.int_order_items_summary;
```

### 4.2 dbt Setup

1. Install dbt Snowflake adapter:
   ```bash
   pip install dbt-snowflake
   ```
2. Initialize a dbt project:
   ```bash
   dbt init data_pipeline
   ```
3. Configure `profiles.yml`:
   ```yaml
   my_project:
     target: dev
     outputs:
       dev:
         type: snowflake
         account: <your_account>
         user: <your_user>
         password: <your_password>
         role: <your_role>
         database: dbt_db
         warehouse: adbt_wh
         schema: dbt_schema
         threads: 10
         client_session_keep_alive: False
   ```
4. Create source and staging files
`models/staging/tpch_sources.yml`
```sql
version: 2

sources:
  - name: tpch
    database: snowflake_sample_data
    schema: tpch_sf1
    tables:
      - name: orders
        columns:
          - name: o_orderkey
            tests:
              - unique
              - not_null
      - name: lineitem
        columns:
          - name: l_orderkey
            tests:
              - relationships:
                  to: source('tpch', 'orders')
                  field: o_orderkey
```

5. Create staging models `models/staging/stg_tpch_orders.sql/`
```sql
select
    o_orderkey as order_key,
    o_custkey as customer_key,
    o_orderstatus as status_code,
    o_totalprice as total_price,
    o_orderdate as order_date
from
    {{ source('tpch', 'orders') }}
```

`models/staging/tpch/stg_tpch_line_items.sql/`
```sql
select
    {{
        dbt_utils.generate_surrogate_key([
            'l_orderkey',
            'l_linenumber'
        ])
    }} as order_item_key,
	l_orderkey as order_key,
	l_partkey as part_key,
	l_linenumber as line_number,
	l_quantity as quantity,
	l_extendedprice as extended_price,
	l_discount as discount_percentage,
	l_tax as tax_rate
from
    {{ source('tpch', 'lineitem') }}
```
6. Macros (Don’t repeat yourself or D.R.Y.)
```sql
Create macros/pricing.sql

{% macro discounted_amount(extended_price, discount_percentage, scale=2) %}
    (-1 * {{extended_price}} * {{discount_percentage}})::decimal(16, {{ scale }})
{% endmacro %}

```

7. Transform models (fact tables, data marts)
- - Create Intermediate table models/marts/int_order_items.sql 
```sql
select
    line_item.order_item_key,
    line_item.part_key,
    line_item.line_number,
    line_item.extended_price,
    orders.order_key,
    orders.customer_key,
    orders.order_date,
    {{ discounted_amount('line_item.extended_price', 'line_item.discount_percentage') }} as item_discount_amount
from
    {{ ref('stg_tpch_orders') }} as orders
join
    {{ ref('stg_tpch_line_items') }} as line_item
        on orders.order_key = line_item.order_key
order by
    orders.order_date
```
​
-- Create marts/int_order_items_summary.sql to aggregate info

```sql
select 
    order_key,
    sum(extended_price) as gross_item_sales_amount,
    sum(item_discount_amount) as item_discount_amount
from
    {{ ref('int_order_items') }}
group by
    order_key
```
​
-- create fact model models/marts/fct_orders.sql

```sql
select
    orders.*,
    order_item_summary.gross_item_sales_amount,
    order_item_summary.item_discount_amount
from
    {{ref('stg_tpch_orders')}} as orders
join
    {{ref('int_order_items_summary')}} as order_item_summary
        on orders.order_key = order_item_summary.order_key
order by order_date
```

### 4.3 dbt Testing (Generic and Singular Tests)
- Generic Tests
```yaml
models:
  - name: fct_orders
    columns:
      - name: order_key
        tests:
          - unique
          - not_null
          - relationships:
              to: ref('stg_tpch_orders')
              field: order_key
              severity: warn
      - name: status_code
        tests:
          - accepted_values:
              values: ['P', 'O', 'F']
```

- Build Singular Tests `tests/fct_orders_discount.sql`

```sql
select
    *
from
    {{ref('fct_orders')}}
where
    item_discount_amount > 0
```

- Create `tests/fct_orders_date_valid.sql`

```sql
select
    *
from
    {{ref('fct_orders')}}
where
    date(order_date) > CURRENT_DATE()
    or date(order_date) < date('1990-01-01')

```
- Run tests:
  ```bash
  dbt test
  ```

---

### 4.4 Airflow Setup (Planned for Tomorrow)

1. Install Astronomer CLI:
   ```bash
   curl -sSL https://install.astronomer.io | bash
   ```
2. Initialize project:
   ```bash
   astro dev init
   ```
3. Configure Airflow connections to Snowflake.
4. Create DAG that runs dbt tasks.

---

## 5. Project Structure

```
my_project/
│
├── dags/
│   └── dbt_dag.py
├── models/
│   ├── staging/
│   └── marts/
├── tests/
├── profiles.yml
└── README.md
```

---

## 6. Next Steps

- **Today:** Finalize dbt transformations and tests.
- **Tomorrow:** Integrate Airflow, configure connections, and schedule dbt runs.

---

## 7. References

- [dbt Documentation](https://docs.getdbt.com/)
- [Snowflake Documentation](https://docs.snowflake.com/)
- [Airflow Documentation](https://airflow.apache.org/)
- [Astronomer Docs](https://docs.astronomer.io/)

