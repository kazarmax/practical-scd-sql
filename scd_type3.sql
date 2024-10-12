-- Step 1: Creating and populating the dim_customers table

-- Drop the table if it already exists to avoid duplication errors
DROP TABLE IF EXISTS dim_customers_scd3;

-- Create dim_customers_scd3 table
CREATE TABLE dim_customers_scd3 (
    row_id SERIAL PRIMARY KEY,    -- Surrogate key that auto-increments
    customer_id INT UNIQUE,       -- Add UNIQUE constraint on customer_id
    first_name VARCHAR(50),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    previous_phone VARCHAR(20),   -- Column to store previous phone number
    email VARCHAR(100),
    previous_email VARCHAR(100)   -- Column to store previous email
);

-- Insert initial data into dim_customers_scd3
INSERT INTO dim_customers_scd3 (customer_id, first_name, last_name, phone, previous_phone, email, previous_email)
VALUES 
    (1001, 'John', 'Doe', '555-1234', NULL, 'john.doe@example.com', NULL),
    (1002, 'Jane', 'Smith', '555-5678', NULL, 'jane.smith@example.com', NULL),
    (1003, 'James', 'Brown', '555-8765', NULL, 'james.brown@example.com', NULL);


-- Step 2: Creating and populatin the staging_customers table

-- Drop the table if it already exists to avoid duplication errors
DROP TABLE IF EXISTS staging_customers_scd3;

-- Create staging_customers_scd3 table
CREATE TABLE staging_customers_scd3 (
    row_id SERIAL PRIMARY KEY,    -- Surrogate key that auto-increments
    customer_id INT UNIQUE,       -- Add UNIQUE constraint on customer_id
    first_name VARCHAR(50),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100)
);

-- Insert new and updated records into staging_customers_scd3
INSERT INTO staging_customers_scd3 (customer_id, first_name, last_name, phone, email)
VALUES 
    (1001, 'John', 'Doe', '555-4321', 'john.doe@newemail.com'),    -- Updated phone and email for existing customer
    (1002, 'Jane', 'Smith', '555-9999', 'jane.smith@newemail.com'),-- Updated phone and email for existing customer
    (1004, 'Emily', 'Davis', '555-1111', 'emily.davis@example.com'); -- New customer record


-- Step 3: Manual Implementation of SCD Type 1

-- Update the existing records with new phone and email, while preserving the previous values
UPDATE dim_customers_scd3
SET previous_phone = phone,  -- Move current phone to previous_phone
    phone = '555-4321',      -- Update to new phone
    previous_email = email,  -- Move current email to previous_email
    email = 'john.doe@newemail.com'
WHERE customer_id = 1001;

UPDATE dim_customers_scd3
SET previous_phone = phone,  -- Move current phone to previous_phone
    phone = '555-9999',      -- Update to new phone
    previous_email = email,  -- Move current email to previous_email
    email = 'jane.smith@newemail.com'
WHERE customer_id = 1002;

-- Insert new customer (no previous values to store for a new customer)
INSERT INTO dim_customers_scd3 (customer_id, first_name, last_name, phone, previous_phone, email, previous_email)
VALUES (1004, 'Emily', 'Davis', '555-1111', NULL, 'emily.davis@example.com', NULL);


-- Step 4: Automating SCD Type 1 Updates

-- Upsert from staging_customers_scd3 to dim_customers_scd3
INSERT INTO dim_customers_scd3 (customer_id, first_name, last_name, phone, previous_phone, email, previous_email)
SELECT customer_id, first_name, last_name, phone, NULL AS previous_phone, email, NULL AS previous_email
FROM staging_customers_scd3
ON CONFLICT (customer_id)  -- Conflict target is `customer_id`
DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    previous_phone = dim_customers_scd3.phone,   -- Move current phone to previous_phone
    phone = EXCLUDED.phone,                      -- Update with new phone
    previous_email = dim_customers_scd3.email,   -- Move current email to previous_email
    email = EXCLUDED.email;                      -- Update with new email
