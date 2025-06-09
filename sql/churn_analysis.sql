-- Our churn rate will likely be 100% using the real current date because this dataset has not been updated in a long time.
-- Lets find out what date the latest invoice is from and pretend this is our current date
SELECT MAX(invoice_date) AS most_recent_invoice_date 
FROM invoices;

-- Our most recent invoice is from 2011-12-09 12:50:00.000.
-- We will pretend this is our current date for determining churned customers.


-- 1. Identify churned customers: "Which customers have not made a purchase in the last 3 months?"
SELECT COUNT(customer_id) AS churned_customers
FROM customer_last_purchase
WHERE last_purchase_date < (SELECT MAX(invoice_date) FROM invoices) - INTERVAL '3 months';


-- 2. Calculate churn rate: "What percentage of customers have churned?"
SELECT COUNT(*) AS total_customers,
SUM(CASE WHEN last_purchase_date < (SELECT MAX(invoice_date) FROM invoices) - INTERVAL '3 months' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN last_purchase_date < (SELECT MAX(invoice_date) FROM invoices) - INTERVAL '3 months' THEN 1 ELSE 0 END)::DECIMAL / COUNT(*) * 100, 2) AS churn_rate
FROM customer_last_purchase;

-- This returns a churn rate of 33.17%


-- 3. Customer value churn "Are we losing high value customers or just casual/one-time buyers?"
-- find total revenue from each customer_id
WITH customer_revenue AS (
    SELECT customer_id, SUM(quantity * unit_price) AS total_revenue
    FROM invoice_items
    JOIN products ON invoice_items.stock_code = products.stock_code
    GROUP BY customer_id
),
-- flag churned customers
churn_flagged AS (
    SELECT clp.customer_id, cr.total_revenue,
    CASE
    WHEN last_purchase_date < (SELECT MAX(invoice_date) FROM invoices) - INTERVAL '3 months' THEN 'Churned'
    ELSE 'Active'
    END AS churn_status
    FROM customer_last_purchase AS clp
    JOIN customer_revenue AS cr ON clp.customer_id = cr.customer_id
),
-- find median total revenue among all customers
median_revenue AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_revenue) AS median
    FROM customer_revenue
),
-- group customers into "high value" or "low value"
value_grouped AS (
    SELECT customer_id, total_revenue, churn_status,
    CASE
    WHEN total_revenue >= (SELECT median FROM median_revenue) THEN 'high value'
    ELSE 'low value'
    END AS value_group
    FROM churn_flagged
),
churn_vals AS (
    SELECT value_group, COUNT(*) AS total_customers,
    SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND((SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)) * 100, 2) AS churn_rate
    FROM value_grouped
    GROUP BY value_group
)
SELECT value_group, total_customers, churned_customers, churn_rate,
ROUND(churned_customers::NUMERIC / SUM(churned_customers) OVER () * 100, 2) AS percent_of_total_churn
FROM churn_vals;

-- ~74.28% of churn is "low value" customers who have spent less than the median


-- 4. Churn rates by country: "Where are customers churning the most?"
-- flag churned customers
WITH churn_flagged AS (
    SELECT clp.customer_id, country,
    CASE 
        WHEN last_purchase_date < (SELECT MAX(invoice_date) FROM invoices) - INTERVAL '3 months' THEN 'Churned'
        ELSE 'Active'
    END AS churn_status
    FROM customer_last_purchase AS clp
    JOIN customers ON clp.customer_id = customers.customer_id
),
churn_vals AS (
    SELECT country, COUNT(*) AS total_customers,
    SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND((SUM(CASE WHEN churn_status = 'Churned' THEN 1 ELSE 0 END)::DECIMAL / COUNT(*)) * 100, 2) AS churn_rate
    FROM churn_flagged
    GROUP BY country
)
SELECT country, total_customers, churned_customers, churn_rate,
ROUND(churned_customers::NUMERIC / SUM(churned_customers) OVER () * 100, 2) AS percent_of_total_churn
FROM churn_vals
WHERE total_customers >= 10
ORDER BY percent_of_total_churn DESC;

