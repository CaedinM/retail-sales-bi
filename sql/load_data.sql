-- load raw data from csv file
psql -d retail_sales -c "\COPY raw_sales FROM 'data/Online Retail Data.csv' DELIMITER ',' CSV HEADER;"

-- populate customers table
INSERT INTO customers (customer_id, country)
SELECT DISTINCT customer_id, country
FROM raw_sales
WHERE customer_id IS NOT NULL
ON CONFLICT (customer_id) DO NOTHING;

-- populate products table
INSERT INTO products (stock_code, description, unit_price)
SELECT DISTINCT stock_code, description, unit_price
FROM raw_sales
WHERE stock_code IS NOT NULL;
ON CONFLICT (stock_code) DO NOTHING;

-- populate invoices table
INSERT INTO invoices (invoice_no, invoice_date)
SELECT DISTINCT invoice_no, invoice_date
FROM raw_sales
WHERE invoice_no IS NOT NULL
ON CONFLICT (invoice_no) DO NOTHING;

-- populate invoice_items table
INSERT INTO invoice_items (invoice_no, stock_code, customer_id, quantity)
SELECT invoice_no, stock_code, customer_id, quantity
FROM raw_sales
WHERE customer_id IS NOT NULL;

-- verify data
SELECT COUNT(*) FROM raw_sales AS raw_sales;
SELECT COUNT(*) FROM customers AS customers;
SELECT COUNT(*) FROM products AS products;
SELECT COUNT(*) FROM invoices AS invoices;
SELECT COUNT(*) FROM invoice_items AS invoice_items;

