-- Step 1: Creating and populating the dim_customers table

-- Drop the table if it already exists
DROP TABLE IF EXISTS dim_customers_scd2;

-- Create dim_customers table with a unique constraint on customer_id
CREATE TABLE dim_customers_scd2 (
    row_id SERIAL PRIMARY KEY,    -- Surrogate key that auto-increments
    customer_id INT,
    first_name VARCHAR(50),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE DEFAULT NULL,
    is_current CHAR(1) DEFAULT 'Y'
);

INSERT INTO dim_customers_scd2 (customer_id, first_name, last_name, phone, email)
VALUES 
    (1001, 'John', 'Doe', '555-1234', 'john.doe@example.com'),
    (1002, 'Jane', 'Smith', '555-5678', 'jane.smith@example.com'),
    (1003, 'James', 'Brown', '555-8765', 'james.brown@example.com');


-- Step 2: Creating and populatin the staging_customers table

-- Drop the table if it already exists
DROP TABLE IF EXISTS staging_customers_scd2;

-- Create staging_customers table
CREATE TABLE staging_customers_scd2 (
    row_id SERIAL PRIMARY KEY,    -- Surrogate key that auto-increments
    customer_id INT,
    first_name VARCHAR(50),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100)
);

INSERT INTO staging_customers_scd2 (customer_id, first_name, last_name, phone, email)
VALUES 
    (1001, 'John', 'Doe', '555-4321', 'john.doe@newemail.com'),   -- Updated email and phone for existing customer
    (1002, 'Jane', 'Smith', '555-9999', 'jane.smith@newemail.com'), -- Updated phone and email for existing customer
    (1004, 'Emily', 'Davis', '555-1111', 'emily.davis@example.com'); -- New customer record


-- Step 3: Manual Implementation of SCD Type 1

UPDATE dim_customers_scd2
SET end_date = CURRENT_DATE,
    is_current = 'N'
WHERE customer_id IN (1001, 1002);

INSERT INTO dim_customers_scd2 (
  customer_id, 
  first_name, 
  last_name, 
  phone, 
  email
)
SELECT 
  customer_id, 
  first_name, 
  last_name, 
  phone, 
  email
FROM staging_customers_scd2;


-- Step 4: Automating SCD Type 1 Updates

-- Close out old records by setting end_date and is_current = 'N' 
-- for existing customers who have changes
UPDATE dim_customers_scd2
SET end_date = CURRENT_DATE,
    is_current = 'N'
WHERE customer_id IN (
    SELECT staging.customer_id
    FROM staging_customers_scd2 staging
    JOIN dim_customers_scd2 dim
      ON staging.customer_id = dim.customer_id
      AND dim.is_current = 'Y'  -- Only update the current records
    WHERE 
        staging.first_name <> dim.first_name OR
        staging.last_name <> dim.last_name OR
        staging.phone <> dim.phone OR
        staging.email <> dim.email
);

-- Insert new records (updated or new customers)
INSERT INTO dim_customers_scd2 (
  customer_id, 
  first_name, 
  last_name, 
  phone, 
  email,
  start_date,
  end_date,
  is_current
)
SELECT 
  staging.customer_id,
  staging.first_name,
  staging.last_name,
  staging.phone,
  staging.email,
  CURRENT_DATE,    -- Start date for the new record
  NULL,            -- End date is NULL for current records
  'Y'              -- Mark the record as the current version
FROM staging_customers_scd2 staging
LEFT JOIN dim_customers_scd2 dim
  ON staging.customer_id = dim.customer_id
  AND dim.is_current = 'Y'  -- Only compare against the current records
WHERE dim.customer_id IS NULL  -- Insert if the customer is new
   OR (
     staging.first_name <> dim.first_name OR
     staging.last_name <> dim.last_name OR
     staging.phone <> dim.phone OR
     staging.email <> dim.email
   );
