-- create database
CREATE DATABASE reatil_sales;

-- create customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    country TEXT
    );

-- create products table
CREATE TABLE products (
    stock_code TEXT PRIMARY KEY,
    description TEXT,
    unit_price NUMERIC(10, 2)
    );

-- create invoices table
CREATE TABLE invoices (
    invoice_no TEXT PRIMARY KEY,
    invoice_date TIMESTAMP,
    );

-- create invoice_items table
CREATE TABLE invoice_items (
    id SERIAL PRIMARY KEY,
    invoice_no TEXT REFERENCES invoices(invoice_no),
    stock_code TEXT REFERENCES products(stock_code),
    customer_id INT REFERENCES customers(customer_id),
    quantity INT,
    );

 -- create raw_sales table for importing intiial raw data
CREATE TABLE raw_sales (
    invoice_no TEXT,
    stock_code TEXT,
    description TEXT,
    quantity INT,
    invoice_date TIMESTAMP,
    unit_price NUMERIC(10,2),
    customer_id INT,
    country TEXT
    );

-- scaffold table for building calendar heatmaps
CREATE TABLE calendar_scaffold AS
SELECT generate_series(
    '2010-11-01'::date,
    '2011-12-31'::date,
    interval '1 day'
)::date AS day;