# US-Residential Sales and Product Analysis Project

## Overview
This project is a comprehensive SQL-based analysis of sales, product profitability, and shipping data. The data is modeled in multiple relational tables, and the goal is to extract meaningful insights by performing various queries related to sales, profit margins, customer activity, product performance, and delivery efficiency. The project involves data cleaning, manipulation, and setting up relationships between tables to enable complex analytical queries.

## Problem Statement
Businesses need to evaluate their sales performance, customer engagement, and product profitability to make informed decisions. Additionally, timely delivery of orders is a key factor in customer satisfaction. This project seeks to address the following questions:

1. What are the overall sales, costs, and net profits?
2. Which customers and products contribute the most to sales and profit?
3. How efficient is the shipping and delivery process?
4. How do sales and profitability vary across different regions, teams, and time periods?

## Skills & Technology Used
- **SQL**: To query, clean, and manipulate data, and create relationships between tables for analysis.
- **PostgreSQL**: Database used to implement the schema and perform the analysis.
- **Data Cleaning**: Performed using SQL functions to remove unwanted characters, standardize formats, and correct inconsistencies.
- **Data Modeling**: Designed multiple tables (customer, product, sales, region, etc.) to represent the data relationships.
- **Analytical Queries**: SQL queries were written to compute metrics like total sales, net profit, product profit, and delivery efficiency.

## Methodology
### 1. Database Setup
We started by creating multiple tables (`customer`, `product`, `region`, `sales`, `salesteam`, `storelocation`) using SQL `CREATE TABLE` statements. These tables store data on customers, products, regions, sales transactions, sales teams, and store locations.

### 2. Data Cleaning & Manipulation
- Cleaned the `customer` table by removing unwanted characters from customer names.
- Updated data types in the `sales` table, specifically converting `unit_price` and `unit_cost` columns from `VARCHAR` to `NUMERIC` for numerical calculations.
- Renamed columns and fixed typos in the `storelocation` table, e.g., renaming `watrer_area` to `water_area`.
- Used SQL functions (`string_to_array`, `UNNEST`) to split columns with multiple values and normalize the data.

### 3. Relationships Between Tables
- Created foreign key constraints to establish relationships between tables:
    - `sales` and `customer`: Related by `customer_id`.
    - `sales` and `product`: Related by `product_id`.
    - `sales` and `salesteam`: Related by `sales_team_id`.

### 4. Sales, Cost, and Profit Analysis
- Computed **Sales Total**, **Sales Total Cost**, and **Sales Net Profit** by multiplying `order_quantity` with `unit_price` and `unit_cost`.
- Identified the top-performing customers and products based on net profit.
- Analyzed trends in sales performance by team, product category, and time (monthly and quarterly breakdowns).
  
### 5. Shipping Analysis
- Created measures to calculate the number of days from order placement to delivery.
- Calculated the percentage of orders delivered within 15 days, along with counts of on-time deliveries for specific months (e.g., April 2019).
  
### 6. Profitability Analysis
- Computed **Product Profit** as the difference between `unit_price` and `unit_cost`.
- Determined which products had the highest and lowest profit margins.
- Analyzed profitability trends across different states and product categories.

### Key Queries
- Total sales, costs, and profits for each year and region.
- Top customers by net profit.
- Shipping efficiency measured by delivery timelines.
- Product profitability analysis across various time periods and regions.

## Conclusion
This project provided in-depth insights into sales performance, customer profitability, and shipping efficiency. We determined the top customers and products in terms of profit, as well as the overall profitability trends over time. The results also revealed the shipping efficiency and the timeliness of deliveries, enabling the business to address potential delays and improve customer satisfaction.

## Acknowledgements
- **PostgreSQL** for providing the database system to implement the project.
- **SQL documentation** for guidance on query writing, data manipulation, and performance optimization.
- **Data Analysts** who contributed to the project structure and insights.

## Future Improvements
- **Data Visualization**: The insights can be further enhanced by visualizing trends and patterns using tools like Power BI or Tableau.
- **Performance Optimization**: Some of the complex queries can be optimized for faster execution on large datasets.
- **Automated Reporting**: Implement automated reporting to generate summaries on a regular basis for business decision-makers.
