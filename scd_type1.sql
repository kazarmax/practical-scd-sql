-- Step 1: Creating and populating the dim_customers table

-- Drop the table if it already exists to avoid duplication errors
DROP TABLE IF EXISTS dim_customers;

-- Create dim_customers table with a unique constraint on customer_id
CREATE TABLE dim_customers (
    row_id SERIAL PRIMARY KEY,    -- Surrogate key that auto-increments
    customer_id INT UNIQUE,       -- Add UNIQUE constraint on customer_id
    first_name VARCHAR(50),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100)
);

INSERT INTO dim_customers (customer_id, first_name, last_name, phone, email)
VALUES 
    (1001, 'John', 'Doe', '555-1234', 'john.doe@example.com'),
    (1002, 'Jane', 'Smith', '555-5678', 'jane.smith@example.com'),
    (1003, 'James', 'Brown', '555-8765', 'james.brown@example.com');


-- Step 2: Creating and populatin the staging_customers table

-- Drop the table if it already exists to avoid duplication errors
DROP TABLE IF EXISTS staging_customers;

-- Create staging_customers table
CREATE TABLE staging_customers (
    row_id SERIAL PRIMARY KEY,    -- Surrogate key that auto-increments
    customer_id INT UNIQUE,       -- Add UNIQUE constraint on customer_id
    first_name VARCHAR(50),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100)
);

INSERT INTO staging_customers (customer_id, first_name, last_name, phone, email)
VALUES 
    (1001, 'John', 'Doe', '555-4321', 'john.doe@newemail.com'),   -- Updated email and phone for existing customer
    (1002, 'Jane', 'Smith', '555-9999', 'jane.smith@newemail.com'), -- Updated phone and email for existing customer
    (1004, 'Emily', 'Davis', '555-1111', 'emily.davis@example.com'); -- New customer record


-- Step 3: Manual Implementation of SCD Type 1
UPDATE dim_customers
SET phone = '555-4321',
    email = 'john.doe@newemail.com'
WHERE customer_id = 1001;

UPDATE dim_customers
SET phone = '555-9999',
    email = 'jane.smith@newemail.com'
WHERE customer_id = 1002;

INSERT INTO dim_customers (customer_id, first_name, last_name, phone, email)
VALUES (1004, 'Emily', 'Davis', '555-1111', 'emily.davis@example.com'); -- New customer record


-- Step 4: Automating SCD Type 1 Updates
-- Upsert from staging_customers to dim_customers
INSERT INTO dim_customers (customer_id, first_name, last_name, phone, email)
SELECT customer_id, first_name, last_name, phone, email
FROM staging_customers
ON CONFLICT (customer_id)  -- Conflict target is `customer_id`
DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email;
