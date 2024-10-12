# Comprehending SCD Types 1, 2, 3 with SQL

The repo contains hands-on SQL query examples to manually and automatically update dimension tables implementing Slowly Changing Dimensions (SCD) Types 1, 2, and 3 in PostgreSQL.

In the queries, two tables are used:
* `dim_customers` - acts as our main dimension table, which stores the current state of customer data
* `staging_customers` - simulates incoming changes from the source system, such as updates to existing customer records or completely new customers

For a complete step-by-step guide - see 
