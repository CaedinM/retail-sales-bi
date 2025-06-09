-- This view will be used in many of our churn analysis queries
CREATE OR REPLACE VIEW customer_last_purchase AS
SELECT customers.customer_id, MAX(invoice_date) AS last_purchase_date
    FROM customers
    JOIN invoice_items ON customers.customer_id = invoice_items.customer_id
    JOIN invoices ON invoices.invoice_no = invoice_items.invoice_no
    GROUP BY customers.customer_id;


-- get date of most recent data to display on dashboard
CREATE OR REPLACE VIEW data_refresh_date AS
SELECT MAX(invoice_date) AS data_current_date
FROM invoices;


-- kpi summary view for dashboard
CREATE OR REPLACE VIEW kpi_summary AS
WITH customer_last_purchase AS (
    SELECT customers.customer_id, MAX(invoice_date) AS last_purchase_date
    FROM customers
    JOIN invoice_items ON customers.customer_id = invoice_items.customer_id
    JOIN invoices ON invoices.invoice_no = invoice_items.invoice_no
    GROUP BY customers.customer_id
),
churn_counts AS (
    SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN last_purchase_date < (SELECT MAX(invoice_date) FROM invoices) - INTERVAL '3 months' THEN 1 ELSE 0 END) AS churned_customers
    FROM customer_last_purchase
)
SELECT SUM(quantity * unit_price) AS total_revenue, 
(SELECT total_customers FROM churn_counts) AS unique_customers, 
COUNT(DISTINCT ii.invoice_no) AS total_orders, 
(SELECT churned_customers FROM churn_counts) AS churned_customers,
(SELECT churned_customers FROM churn_counts)::DECIMAL / (SELECT total_customers FROM churn_counts) AS churn_rate,
SUM(CASE WHEN DATE_TRUNC('month', invoice_date) = DATE_TRUNC('month', (SELECT MAX(invoice_date) FROM invoices)) THEN (quantity * unit_price) ELSE 0 END) AS revenue_this_month
FROM invoice_items ii
JOIN products p ON ii.stock_code = p.stock_code
JOIN invoices i ON ii.invoice_no = i.invoice_no

-- verify view with:
SELECT * FROM kpi_summary;

-- basic kpi summary by month
SELECT 
    DATE_TRUNC('month', i.invoice_date) AS month,
    SUM(quantity) AS orders,
    SUM(quantity * unit_price) AS revenue,
    COUNT(customer_id) AS unique_customers
FROM invoice_items ii
JOIN invoices i ON ii.invoice_no = i.invoice_no
JOIN products p ON p.stock_code = ii.stock_code
GROUP BY month
ORDER BY month DESC;


-- monthly KPI summary view for dashboard
-- normally we could just use the CURRENT_DATE keyword to find the date, but since this dataset is old, we will pretend the latest invoice date is the current date.
CREATE OR REPLACE VIEW monthly_kpi_summary AS
WITH max_date AS (SELECT MAX(invoice_date)::DATE AS max_date FROM invoices),
cutoff AS (SELECT EXTRACT(DAY FROM max_date) AS cutoff_day FROM max_date),
max_month AS (
    SELECT DATE_TRUNC('month', max_date) AS current_month
    FROM max_date
),
current_month_data AS (
    SELECT ii.*, i.invoice_date, p.*
    FROM invoice_items ii
    JOIN invoices i ON ii.invoice_no = i.invoice_no
    JOIN products p ON ii.stock_code = p.stock_code
    JOIN max_month mm ON DATE_TRUNC('month', i.invoice_date) = mm.current_month
    JOIN cutoff ON EXTRACT(DAY FROM i.invoice_date) <= cutoff.cutoff_day
),
prior_month_data AS (
    SELECT ii.*, i.invoice_date, p.*
    FROM invoice_items ii
    JOIN invoices i ON ii.invoice_no = i.invoice_no
    JOIN products p ON ii.stock_code = p.stock_code
    JOIN max_month mm ON DATE_TRUNC('month', i.invoice_date) = mm.current_month - INTERVAL '1 month'
    JOIN cutoff ON EXTRACT(DAY FROM i.invoice_date) <= cutoff.cutoff_day
),
current_revenue AS (
    SELECT SUM(quantity * unit_price) AS revenue_this_month
    FROM current_month_data
),
prior_revenue AS (
    SELECT SUM(quantity * unit_price) AS revenue_prior_month
    FROM prior_month_data
)
SELECT 
(SELECT revenue_this_month FROM current_revenue) AS revenue_this_month,
COUNT(DISTINCT current_month_data.invoice_no) AS orders_this_month,
COUNT(DISTINCT current_month_data.customer_id) AS customers_this_month,
((SELECT revenue_this_month FROM current_revenue) - (SELECT revenue_prior_month FROM prior_revenue)) AS revenue_change_vs_prior_month
FROM current_month_data;

-- verify view with:
SELECT * FROM monthly_kpi_summary;

-- monthly revenue/orders/customers view for dashboard
CREATE OR REPLACE VIEW monthly_revenue AS
SELECT DATE_TRUNC('month', invoices.invoice_date) AS month, 
COUNT(DISTINCT invoices.invoice_no) AS orders, 
COUNT(DISTINCT invoice_items.customer_id) AS unique_customers,
SUM(quantity * unit_price) AS revenue
FROM invoice_items
JOIN invoices ON invoices.invoice_no = invoice_items.invoice_no
JOIN products ON products.stock_code = invoice_items.stock_code
GROUP BY month
ORDER BY month DESC
LIMIT 12;


-- most popular products all time
CREATE OR REPLACE VIEW popular_products AS
SELECT ii.stock_code, description AS item, SUM(quantity) AS quantity_sold
FROM products p
JOIN invoice_items ii ON p.stock_code = ii.stock_code
GROUP BY ii.stock_code, description
ORDER BY quantity_sold DESC;


-- biggest markets by country
CREATE OR REPLACE VIEW biggest_markets AS
SELECT country, 
COUNT(DISTINCT invoice_no) AS orders, 
SUM(quantity * unit_price) AS revenue
FROM invoice_items ii
JOIN customers c ON ii.customer_id = c.customer_id
JOIN products p ON ii.stock_code = p.stock_code
GROUP BY country
ORDER BY revenue DESC;


--invoices summary for daily parameterization in Tableau
CREATE OR REPLACE VIEW daily_kpis AS
SELECT CAST(invoice_date AS DATE) AS date, 
COUNT(DISTINCT ii.invoice_no) AS orders, 
COUNT(DISTINCT customer_id) AS customers, 
SUM(quantity * unit_price) AS revenue
FROM invoice_items ii
JOIN invoices i ON ii.invoice_no = i.invoice_no
JOIN products p ON ii.stock_code = p.stock_code
GROUP BY date;

-- recent orders
CREATE OR REPLACE VIEW recent_orders AS
SELECT 
    ii.invoice_no,
    i.invoice_date AS invoice_date,
    SUM(ii.quantity) AS quantity,
    SUM(ii.quantity * p.unit_price) AS revenue
FROM invoice_items ii
JOIN invoices i ON ii.invoice_no = i.invoice_no
JOIN products p ON ii.stock_code = p.stock_code
GROUP BY ii.invoice_no, i.invoice_date
ORDER BY i.invoice_date DESC;

-- calendar revenue heatmap
CREATE OR REPLACE VIEW revenue_heatmap AS
WITH daily_revenue as (
SELECT
i.invoice_date::date AS date,
SUM(ii.quantity) AS items_ordered, 
SUM(quantity * unit_price) AS revenue
FROM invoice_items ii
JOIN invoices i ON ii.invoice_no = i.invoice_no
JOIN products p ON ii.stock_code = p.stock_code
GROUP BY i.invoice_date::date
)
SELECT
c.day,
COALESCE(items_ordered, 0) AS items_ordered,
COALESCE(revenue, 0) AS revenue
FROM calendar_scaffold c
LEFT JOIN daily_revenue dr ON c.day = dr.date
ORDER BY c.day DESC;