# Retail Sales Analysis and BI Dashboard
In this project, I built a full-stack retail ETL pipeline using Excel, SQL, PostgreSQL, and Tableau to analyze and visualize business performance for an online retailer. The final deliverable includes interactive dashboards with daily, monthly, and historical insights, providing actionable KPIs for sales, customers, product performance, and revenue trends.

### Tools & Technologies:
**Languages:** SQL  
**Databases:** PostgreSQL  
**Data Modeling Tool:** DBeaver  
**Visualization:** Tableau  
**Data Preparation:** Excel (initial ETL / cleaning)

### Dataset:
**Source:** UCI Online Retail Dataset  
**URL:** https://archive.ics.uci.edu/dataset/352/online+retail   
**Citation:** Chen, D. (2015). Online Retail [Dataset]. UCI Machine Learning Repository. https://doi.org/10.24432/C5BW33  
**Size:** 406,829 rows (transactional data)

### Database Design:
I designed a normalized relational database schema in PostgreSQL, ensuring referential integrity across customer, invoice, and product data data. The schema follows a star-schema-like structure to optimize for analysis and joins.

### Schema:
| Table | Columns | Rows |
|-------|---------|------|
| customers | cusomer_id (PK), country | 4,372 |
| products | stock_code (PK), unit_price | 3,958 |
| invoices | invoice_no (PK), invoice_date | 25,900 |
|invoice_items | invoice_no (FK), customer_id (FK), stock_code (FK), quantity | 406,829 |

* Note: Some referential integrity loss occurred during normalization due to missing customer IDs in original data.

### SQL Analysis:
**Basic Analysis:**
* Total sales
* Total customers
* Sales by country
* Total quantity sold per product
* Sales by customer
* Monthly revenue over time

**Churn Analysis:**  
* Identify churned customers
* Churn rate 
* Churn rate by country
* Customer value churn
    * high-value vs low-value using median total expenditure as cutoff
    * utilized chained CTEs  

**Advanced Analysis:**
* 7 day revenue rolling average over time
    * utilized a window function and CTE
* Calendar heatmap for revenue
    * utilized date scaffolding

**Trend Analysis:**  
* Revenue pacing
* Time-based KPIs (daily, monthly, alltime)
    * orders
    * revenue
    * customers

### Architecture Decisions:
* Created PostgreSQL views to pre-compute KPI metrics.  
* Utilized a live Postgres connection in Tableau for real-time updates
* Utilized parameter controls and calculated fields to dynamically select dates and months for filtering daily and monthly views.
* Built navigation buttons between multiple dashboards to allow user-friendly exploration.

Deliverables:


### Conclusion:
In this project, I was able to simulate building a full business intelligence pipeline from raw data to executive dashboards using real-world data and industry-standard tools. It demonstrates my SQL, data modeling, and Tableau skills applied in a business context.
