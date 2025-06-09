-- Basic counts of tables
SELECT COUNT(*)

-- 1. Total sales: "What is our total sales?"
SELECT SUM(quantity * unit_price) AS total_sales
FROM invoice_items
JOIN products ON invoice_items.stock_code = products.stock_code;

-- 2. Total customers: "How many unique customers have bought from us"
SELECT COUNT(*) AS customers
FROM customers;

-- 3. Total sales by country: "Where do most of our sales come from?"
SELECT country, SUM(quantity * unit_price) AS total_sales
FROM invoice_items
JOIN customers ON invoice_items.customer_id = customers.customer_id
JOIN products ON invoice_items.stock_code = products.stock_code
GROUP BY country
ORDER BY total_sales DESC;


-- 4. Total quantity sold by product: "What is our most popular product?"
SELECT invoice_items.stock_code, description, SUM(quantity) AS total_quantity
FROM invoice_items
JOIN products ON invoice_items.stock_code = products.stock_code
GROUP BY invoice_items.stock_code, description
ORDER BY total_sales DESC;


-- 5. Total sales by customer: "Who are our most valuable customers?"
SELECT customer_id, SUM(quantity * unit_price) AS total_sales
FROM invoice_items
JOIN products ON invoice_items.stock_code = products.stock_code
GROUP BY customer_id
ORDER BY total_sales DESC;

-- 6. Monthly revenue over time
SELECT DATE_TRUNC('month', invoices.invoice_date) AS month, 
COUNT(DISTINCT invoices.invoice_no) AS orders, 
COUNT(DISTINCT invoice_items.customer_id) AS unique_customers,
SUM(quantity * unit_price) AS revenue
FROM invoice_items
JOIN invoices ON invoices.invoice_no = invoice_items.invoice_no
JOIN products ON products.stock_code = invoice_items.stock_code
GROUP BY month
ORDER BY month DESC;

-- 7. 7-day revenue rolling average
WITH daily_revenue AS (
SELECT invoice_date::DATE, SUM(quantity * unit_price) AS daily_revenue
FROM invoices i
JOIN invoice_items ii ON i.invoice_no = ii.invoice_no
JOIN products p ON p.stock_code = ii.stock_code
GROUP BY invoice_date::DATE
)
SELECT invoice_date,
daily_revenue,
ROUND(AVG(daily_revenue) OVER (
    ORDER BY invoice_date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2
) AS seven_day_rolling_avg
FROM daily_revenue
ORDER BY invoice_date DESC;