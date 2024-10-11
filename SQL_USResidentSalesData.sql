-- CREATE TABLES
CREATE TABLE customer(
	customer_id INTEGER PRIMARY KEY,
	customer_name VARCHAR(50)
);

SELECT*
FROM customer;

CREATE TABLE product(
	product_id INTEGER PRIMARY KEY,
	product_name VARCHAR(50)
);

SELECT*
FROM product;

CREATE TABLE region(
	statecode CHAR(4),
	state VARCHAR(50),
	region VARCHAR(50)
);

SELECT*
FROM region;


CREATE TABLE sales(
	order_number VARCHAR(500),
	sales_channel VARCHAR(500),
	warehouse VARCHAR(500),
	procured_date DATE,
	order_date DATE,
	ship_date DATE,
	delivery_date DATE,
	currency_code CHAR(6),
	sales_team_id INTEGER,
	customer_id INTEGER,
	store_id INTEGER,
	product_id INTEGER,
	order_quantity INTEGER,
	discount DECIMAL(1000,100),
	unit_price VARCHAR(500),
	unit_cost VARCHAR(500)	
);
SELECT*
FROM sales

CREATE TABLE salesteam(
	salesteam_id INTEGER PRIMARY KEY,
	sales_team VARCHAR(50),
	region VARCHAR(50)
);


CREATE TABLE storelocation(
	store_id INTEGER PRIMARY KEY,
	city_name VARCHAR(500),
	county VARCHAR(500),
	state_code CHAR(6),
	state VARCHAR(500),
	type VARCHAR(500),
	latitude NUMERIC(1000,100),
	longitude NUMERIC(1000,100),
	area_code INTEGER,
	population INTEGER,
	household_income INTEGER,
	median_income INTEGER,
	land_area NUMERIC,
	watrer_area INTEGER,
	timezone VARCHAR(500)
);

-- DATA CLEANING & MANIPULATION
SELECT*
FROM customer;

UPDATE customer
SET customer_name = REPLACE(customer_name, ',', '');


SELECT DISTINCT region
FROM region;

SELECT*
FROM sales;

-- To approximate discount column to 2 decimal places
ALTER TABLE sales
ALTER COLUMN discount TYPE NUMERIC(20,2);

-- To convert unit_price and unit_cost from VARCHAR to NUMERIC
ALTER TABLE sales
ALTER COLUMN unit_price
SET DATA TYPE NUMERIC(20,2)
USING  REPLACE(unit_price, ',', '')::NUMERIC(20,2);

ALTER TABLE sales
ALTER COLUMN unit_cost
SET DATA TYPE NUMERIC(20,2)
USING  REPLACE(unit_cost, ',', '')::NUMERIC(20,2);


SELECT*
FROM storelocation;

-- To rename Watrer area to water_area
ALTER TABLE storelocation
RENAME COLUMN watrer_area TO water_area;

-- Splitting county column by delimiter /
WITH cte AS (
SELECT store_id, city_name, state_code, state, type, latitude, longitude, area_code, population,
	household_income, median_income, land_area, water_area, timezone,
	UNNEST(string_to_array(county, '/')) AS split_value,
FROM storelocation
)
SELECT store_id, split_value, city_name, state_code, state, type, latitude, longitude, area_code, population,
	household_income, median_income, land_area, water_area, timezone
INTO store_location
FROM cte;

-- Check the new table
SELECT*
FROM store_location;

-- DROP store_location
DROP TABLE store_location;


-- Splitting county column by delimiter /
WITH cte AS (
SELECT store_id, city_name, state_code, state, type, latitude, longitude, area_code, population,
	household_income, median_income, land_area, water_area,
	string_to_array(county, '/') AS split_array1,
	string_to_array(timezone, '/') AS split_array2
FROM storelocation
)
SELECT store_id, split_array1, split_array2, city_name, state_code, state, type, latitude, longitude, area_code, population,
	household_income, median_income, land_area, water_area,
	split_array1[1] AS first_part,
	split_array2[2] AS second_part
INTO store_location
FROM cte;


-- Check
SELECT*
FROM store_location;

-- DROP COLUMNs split_array1 & split_array2
ALTER TABLE store_location
DROP COLUMN split_array1, 
DROP COLUMN split_array2;

-- Rename SPLIT_VALUE to county
ALTER TABLE store_location
RENAME COLUMN first_part TO county

ALTER TABLE store_location
RENAME COLUMN second_part TO timezone;

-- Approximate latitude & longitude to 3 decimal places
ALTER TABLE store_location
ALTER COLUMN latitude TYPE NUMERIC(20,3);

ALTER TABLE store_location
ALTER COLUMN longitude TYPE NUMERIC(20,3);

-- DROP TABLE called storelocation
DROP TABLE storelocation;


-- CREATE RELATIONSHIP BETWEEN TABLES
SELECT*
FROM store_location;

SELECT*
FROM sales;

ALTER TABLE sales
ADD CONSTRAINT FK_Sales_Order_Customer 
FOREIGN KEY (customer_id) REFERENCES customer(customer_id);

ALTER TABLE sales
ADD CONSTRAINT FK_Sales_Order_Product 
FOREIGN KEY (product_id) REFERENCES product(product_id);

-- RENAME salesteam_id in salesteam
ALTER TABLE salesteam
RENAME COLUMN salesteam_id TO sales_team_id;

ALTER TABLE sales
ADD CONSTRAINT FK_Sales_Order_Team 
FOREIGN KEY (sales_team_id) REFERENCES salesteam(sales_team_id);

-- PART 1: SALES ANALYSIS
-- In sales table, create a Measure called Sales Total that multiplies the Unit Price with Order Quantity.
SELECT (unit_price*order_quantity) AS sales_total
FROM sales;

--2. What is the total sales from the entire transaction?
WITH cte AS (
SELECT *, (unit_price*order_quantity) AS sales_total
FROM sales
)
SELECT SUM(sales_total)
FROM cte;


--3. In the Sales table, create a Measure called Sales Total Cost that multiplies the Unit Cost with Order Quantity.
SELECT (unit_cost * order_quantity) AS sales_total_cost
FROM sales;

--4. What is the total of the sales_total_cost of the expenses made to produce products?
WITH cte AS (
SELECT *, (unit_cost * order_quantity) AS sales_total_cost
FROM sales
)
SELECT SUM(sales_total_cost)
FROM cte;

--5. In the Sales table, create a Measure called Sales Net Profit that calculated the difference between 
-- Sales Total with Sales Total Cost?
WITH cte AS (
SELECT *, (unit_price * order_quantity) AS sales_total
FROM sales
),
cte2 AS (
SELECT *, (unit_cost * order_quantity) AS sales_total_cost
FROM sales
)
SELECT (cte.sales_total - cte2.sales_total_cost) AS sales_net_profit
FROM cte
INNER JOIN cte2 ON cte2.order_number = cte.order_number;

--6. What is the total sales net profit?
WITH cte AS (
SELECT *, (unit_price * order_quantity) AS sales_total
FROM sales
),
cte2 AS (
SELECT *, (unit_cost * order_quantity) AS sales_total_cost
FROM sales
),
cte3 AS (SELECT (cte.sales_total - cte2.sales_total_cost) AS sales_net_profit
FROM cte
INNER JOIN cte2 ON cte2.order_number = cte.order_number
)
SELECT SUM(sales_net_profit) AS total_sales_net_profit
FROM cte3;

--7. What customer has the most Sales Net Profit over the whole timeline of data, and what is the dollar value? 
WITH cte AS (
SELECT c.customer_name, s.order_number, c.customer_id, s.order_quantity, s.unit_price, s.unit_cost
FROM customer c
INNER JOIN sales s ON c.customer_id = s.customer_id
)
SELECT cte.customer_name, SUM((cte.unit_price * cte.order_quantity) - (cte.unit_cost * cte.order_quantity)) AS total_sales_net_profit
FROM cte
GROUP BY customer_name
ORDER BY total_sales_net_profit DESC;

--8. What customer has the most Sales Net Profit in the month of July 2019 OrderDate, and what is the dollar value?
WITH cte AS (
SELECT c.customer_name, s.order_date, c.customer_id, s.order_quantity, s.unit_price, s.unit_cost
FROM customer c
INNER JOIN sales s ON c.customer_id = s.customer_id
WHERE EXTRACT(Month FROM s.order_date)=7 AND EXTRACT(Year FROM s.order_date)=2019
)
SELECT cte.customer_name, SUM((cte.unit_price * cte.order_quantity) - (cte.unit_cost * cte.order_quantity)) AS total_sales_net_profit
FROM cte
GROUP BY customer_name
ORDER BY total_sales_net_profit DESC
LIMIT 1;

--9. What sales team has the second most Sales Total over the whole timeline of data, and what is the dollar value?  
WITH cte AS (
SELECT st.sales_team, (s.unit_price * s.order_quantity) AS sales_total
FROM sales s
INNER JOIN salesteam st ON s.sales_team_id = st.sales_team_id
)
SELECT cte.sales_team, SUM(cte.sales_total) AS sales_total
FROM cte
GROUP BY cte.sales_team
ORDER BY sales_total DESC
LIMIT 1 OFFSET 1; -- this retrieves the second row from the ordered results


--10.Who sales team has the second most Sales Net Profit over the whole timeline of data, and what is the dollar value?
WITH cte AS (
SELECT st.sales_team, s.order_date, s.order_quantity, s.unit_price, s.unit_cost
FROM salesteam st
INNER JOIN sales s ON st.sales_team_id = s.sales_team_id
)
SELECT cte.sales_team, SUM((cte.unit_price * cte.order_quantity) - (cte.unit_cost * cte.order_quantity)) AS total_sales_net_profit
FROM cte
GROUP BY cte.sales_team
ORDER BY total_sales_net_profit DESC
LIMIT 1 OFFSET 1;

--11. What state has the fourth most Sales Net Profit for the year 2020 OrderDate, and what is the dollar value?
WITH cte AS (
SELECT r.state, s.order_date, s.order_quantity, s.unit_price, s.unit_cost	
FROM region r
INNER JOIN store_location sl ON sl.state_code = r.state_code
INNER JOIN sales s ON sl.store_id = s.store_id
WHERE EXTRACT(YEAR FROM order_date) = 2020
)
SELECT cte.state, 
	SUM((cte.order_quantity * cte.unit_price) - (cte.order_quantity * cte.unit_cost)) AS sales_net_profit
FROM cte
GROUP BY cte.state
ORDER BY sales_net_profit DESC
LIMIT 1 OFFSET 3;

-- 12. What is the average Sales Net Profit per customer over the entire timeline of data?
SELECT AVG(sales_net_profit) AS avg_sales_net_profit
FROM (
    SELECT customer_id, SUM((order_quantity * unit_price) - (order_quantity * unit_cost)) AS sales_net_profit
    FROM sales
    GROUP BY customer_id
) AS customer_profits;

--13. How does the Sales Total vary by product category for the year 2020?
SELECT p.product_name, SUM(s.order_quantity * s.unit_price) AS sales_total
FROM sales s
INNER JOIN product p ON p.product_id = s.product_id
WHERE EXTRACT(YEAR FROM order_date) = 2020
GROUP BY product_name
ORDER BY sales_total DESC;

--14. What is the trend of Sales Net Profit month-over-month for the year 2020?
SELECT DATE_TRUNC('month', order_date) AS month, 
       SUM((order_quantity * unit_price) - (order_quantity * unit_cost)) AS sales_net_profit
FROM sales
WHERE EXTRACT(YEAR FROM order_date) = 2020
GROUP BY month
ORDER BY month;

--15. Which product has the highest Sales Total for each quarter of 2020?
SELECT p.product_name,
       SUM(order_quantity * unit_price) AS sales_total,
       EXTRACT(QUARTER FROM order_date) AS quarter
FROM sales s
INNER JOIN product p ON p.product_id = s.product_id
WHERE EXTRACT(YEAR FROM order_date) = 2020
GROUP BY product_name, quarter
ORDER BY quarter, sales_total DESC
LIMIT 1;

--16. What is the total Sales Net Profit generated by each sales team in 2020?
SELECT st.sales_team, 
       SUM((s.order_quantity * s.unit_price) - (s.order_quantity * s.unit_cost)) AS total_sales_net_profit
FROM sales s
INNER JOIN salesteam st ON s.sales_team_id = st.sales_team_id
WHERE EXTRACT(YEAR FROM s.order_date) = 2020
GROUP BY sales_team;

--17. How many customers made purchases in July 2019, and what is the average Sales Net 
-- Profit per customer for that month?
SELECT COUNT(DISTINCT customer_id) AS num_customers,
       AVG((order_quantity * unit_price) - (order_quantity * unit_cost)) AS avg_sales_net_profit
FROM sales
WHERE EXTRACT(MONTH FROM order_date) = 7 AND EXTRACT(YEAR FROM order_date) = 2019;

--18. What is the distribution of Sales Total across different states in 2020?
SELECT r.state, 
       SUM(s.order_quantity * s.unit_price) AS sales_total
FROM region r
INNER JOIN store_location sl ON r.state_code = sl.state_code
INNER JOIN sales s ON sl.store_id = s.store_id
WHERE EXTRACT(YEAR FROM order_date) = 2020
GROUP BY r.state
ORDER BY sales_total DESC;

-- PART 2: COST ANALYSIS
--1. In the Sales table, create a Measure called Product Profit that calculates the difference between 
-- the Unit Price and Unit Cost. 
SELECT unit_price, unit_cost, (unit_price - unit_cost) AS product_profit
FROM sales;

-- 2. What is the Total Product Profit from the entire timeline?
SELECT SUM(unit_price - unit_cost) AS total_product_profit
FROM sales;

--3. What product has the most Product Profit, and what is the dollar value?
WITH cte AS (
SELECT p.product_name, s.unit_price, s.unit_cost
FROM product p
INNER JOIN sales s ON p.product_id = s.product_id
)
SELECT cte.product_name,
	SUM(cte.unit_price - cte.unit_cost) AS top_most_product
FROM cte
GROUP BY cte.product_name
ORDER BY top_most_product DESC
LIMIT 1;

--4. What product has the least Product Profit, and what is the dollar value? 
WITH cte AS (
SELECT p.product_name, s.unit_price, s.unit_cost
FROM product p
INNER JOIN sales s ON p.product_id = s.product_id
)
SELECT cte.product_name,
	SUM(cte.unit_price - cte.unit_cost) AS bottom_most_product
FROM cte
GROUP BY cte.product_name
ORDER BY bottom_most_product
LIMIT 1;

--5. What is the dollar value of Product Profit for Outdoor Furniture?
WITH cte AS (
SELECT p.product_name, s.unit_price, s.unit_cost
FROM product p
INNER JOIN sales s ON p.product_id = s.product_id
)
SELECT cte.product_name,
	SUM(cte.unit_price - cte.unit_cost) AS product_profit
FROM cte
WHERE cte.product_name ILIKE '%Outdoor Furniture%'
GROUP BY cte.product_name;

--6. What is the average Product Profit for each product category?
SELECT product_name, 
       ROUND(AVG(unit_price - unit_cost), 2) AS avg_product_profit
FROM sales s
INNER JOIN product p ON s.product_id = p.product_id
GROUP BY product_name;

--7. How does Product Profit vary across different states?
SELECT state, 
       AVG(unit_price - unit_cost) AS avg_product_profit
FROM sales
GROUP BY state;

--8. What are the top 5 products with the highest Product Profit margin?
SELECT product_id, product_name 
FROM product
WHERE product_id IN (
	SELECT product_id
	FROM sales
	GROUP BY product_id
	ORDER BY  AVG(unit_price - unit_cost) DESC
	LIMIT 5
);

--9. What is the total Product Profit for all products sold in Q1 of 2020?
SELECT SUM(order_quantity * (unit_price - unit_cost)) AS total_product_profit
FROM sales
WHERE EXTRACT(YEAR FROM order_date) = 2020 AND EXTRACT(QUARTER FROM order_date) = 1;

--10. How does the Product Profit for Outdoor Furniture compare to other categories?
SELECT p.product_name, 
       ROUND(AVG(unit_price - unit_cost), 2) AS avg_product_profit
FROM sales s
INNER JOIN product p ON s.product_id = p.product_id
GROUP BY p.product_name
HAVING product_name = 'Outdoor Furniture' OR product_name IS NOT NULL
ORDER BY avg_product_profit DESC;

-- Part 3: Shipping Analysis 
--1. In the Sales table, create a Measure called Days from Order to Delivery that calculates the 
-- difference in Days between OrderDate and DeliveryDate.
SELECT order_date, delivery_date, (delivery_date - order_date) AS days_from_order_2_delivery
FROM sales;

--2. In the Sales table, create a Measure called Delivery Under 15 Days that outputs a value of 1 if 
-- Days from Order to Delivery is less than 15, otherwise output 0.
WITH cte AS (
SELECT order_date, delivery_date, (delivery_date - order_date) AS days_from_order_2_delivery
FROM sales
)
SELECT cte.days_from_order_2_delivery,
	CASE
	WHEN cte.days_from_order_2_delivery < 15 THEN 1
	ELSE 0
	END AS Delivery_under_15_days
FROM cte;

--3. In the Sales table, create a Measure called Count of Rows that counts the number of orders.
SELECT COUNT(order_number) AS count_of_rows
FROM sales;

--4. In the Sales table, create a Measure called Count of Rows Delivery Under 15 Days that counts 
-- the number of orders if Delivery Under 15 Days is equal to 1.
WITH cte AS (
SELECT order_date, delivery_date, (delivery_date - order_date) AS days_from_order_2_delivery
FROM sales
),
cte2 AS (
SELECT cte.days_from_order_2_delivery,
	CASE
	WHEN cte.days_from_order_2_delivery < 15 THEN 1
	ELSE 0
	END AS delivery_under_15_days
FROM cte
)
SELECT COUNT(cte2.delivery_under_15_days) AS count_of_delivery_under_15_days
FROM cte2
WHERE cte2.delivery_under_15_days = 1;

--5. In the Sales table, create a Measure called Delivery Under 15 Days Percent that calculates the 
-- percent of orders delivered under 15 days to 2 decimal places.
WITH cte AS (
SELECT order_number, delivery_date, 
       (delivery_date - order_date) AS days_from_order_to_delivery
FROM sales
),
cte2 AS (
SELECT 
	CASE
	WHEN days_from_order_to_delivery < 15 THEN 1
	ELSE 0
    END AS delivery_under_15_days
FROM cte
),
cte3 AS (
SELECT SUM(delivery_under_15_days) AS delivered_under_15_days,
        COUNT(*) AS total_orders
FROM cte2
)
SELECT ROUND((cte3.delivered_under_15_days * 100.0 / cte3.total_orders), 2) AS Delivery_Under_15_Days_Percent
FROM cte3;


--6. How may orders were delivered on time for the month of April, 2019? 
WITH cte AS (
SELECT order_date, delivery_date, (delivery_date - order_date) AS days_from_order_2_delivery
FROM sales
),
cte2 AS (
SELECT cte.order_date, cte.days_from_order_2_delivery,
	CASE
	WHEN cte.days_from_order_2_delivery < 15 THEN 1
	ELSE 0
	END AS delivery_under_15_days
FROM cte
WHERE EXTRACT(Year FROM cte.order_date)=2019 AND EXTRACT(Month FROM cte.order_date)= 4
)
SELECT SUM(cte2.delivery_under_15_days) AS count_of_delivery_under_15_days
FROM cte2
WHERE cte2.delivery_under_15_days = 1;

--7. What percent of orders were delivered under 15 days for the month of April, 2019? 
WITH cte AS (
SELECT order_date, delivery_date, 
       (delivery_date - order_date) AS days_from_order_to_delivery
FROM sales
),
cte2 AS (
SELECT order_date,
	CASE
	WHEN days_from_order_to_delivery < 15 THEN 1
	ELSE 0
    END AS delivery_under_15_days
FROM cte
),
cte3 AS (
SELECT SUM(delivery_under_15_days) AS delivered_under_15_days,
        COUNT(*) AS total_orders
FROM cte2
WHERE EXTRACT(Year FROM order_date)=2019 AND EXTRACT(Month FROM order_date)= 4
)
SELECT ROUND((delivered_under_15_days * 100.0 / total_orders), 2) AS Delivery_Under_15_Days_Percent
FROM cte3;

--8. Is the percent of orders delivered on time for the month of April, 2019 less than or greater than 
-- the average percent of orders delivered under 15 days for the whole timeline of data?
WITH cte AS (
    SELECT order_date, delivery_date,
           (delivery_date - order_date) AS days_from_order_to_delivery
    FROM sales
    WHERE EXTRACT(YEAR FROM order_date) = 2019 
      AND EXTRACT(MONTH FROM order_date) = 4
)
SELECT ROUND((SUM(CASE WHEN days_from_order_to_delivery <= 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) AS Delivery_On_Time_Percent
FROM cte;

WITH cte AS (
    SELECT order_date, delivery_date,
           (delivery_date - order_date) AS days_from_order_to_delivery
    FROM sales
)
SELECT ROUND((SUM(CASE WHEN days_from_order_to_delivery < 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) AS Average_Delivery_Under_15_Days_Percent
FROM cte;

--9. What is the average delivery time (Days from Order to Delivery) for each month in 2019?
SELECT DATE_TRUNC('month', order_date) AS month, 
       ROUND(AVG(delivery_date - order_date), 2) AS avg_delivery_time
FROM sales
WHERE EXTRACT(YEAR FROM order_date) = 2019
GROUP BY month
ORDER BY month;

--10. How does the percentage of orders delivered under 15 days vary by sales team?
SELECT st.sales_team, 
       ROUND(COUNT(CASE WHEN  (delivery_date - order_date) < 15 THEN 1 END) * 100.0 
	   / COUNT(*), 2) AS percent_delivered_under_15_days
FROM sales s
INNER JOIN salesteam st ON s.sales_team_id = st.sales_team_id
GROUP BY sales_team
ORDER BY percent_delivered_under_15_days;

--11. What is the average number of orders delivered on time for each product?
SELECT product_name, 
       ROUND(AVG(on_time_orders), 2) AS avg_num_on_time_orders
FROM (
    SELECT p.product_name,
           COUNT(CASE WHEN (s.delivery_date - s.order_date) < 15 THEN 1 END) AS on_time_orders
    FROM sales s
    INNER JOIN product p ON s.product_id = p.product_id
    GROUP BY p.product_name, s.product_id
) AS on_time_delivery
GROUP BY product_name;


--12. Which month in 2019 had the highest percentage of orders delivered under 15 days?
SELECT DATE_TRUNC('month', order_date) AS month, 
       ROUND(COUNT(CASE WHEN (delivery_date - order_date) < 15 THEN 1 END) * 100.0 / 
	   COUNT(*), 2) AS percent_delivered_under_15_days
FROM sales
WHERE EXTRACT(YEAR FROM order_date) = 2019
GROUP BY month
ORDER BY percent_delivered_under_15_days DESC
LIMIT 1;

--13. How does the average Days from Order to Delivery compare between different customers?
SELECT customer_name, 
       ROUND(AVG(delivery_date - order_date), 2) AS avg_days_to_delivery
FROM sales s
INNER JOIN customer c ON s.customer_id = c.customer_id
GROUP BY customer_name
ORDER BY  avg_days_to_delivery DESC;

-- Warehouse Analysis
--1. What is the total Sales Net Profit generated from each warehouse?
SELECT warehouse, SUM((order_quantity * unit_price) - (order_quantity * unit_cost)) AS total_sales_net_profit
FROM Sales
GROUP BY warehouse
ORDER BY total_sales_net_profit DESC;

-- 2. Which warehouse has the highest average Sales Total?
WITH cte AS (
    SELECT warehouse, 
           (SUM((order_quantity * unit_price) - (order_quantity * unit_cost))) / COUNT(*) AS avg_sales_total
    FROM Sales
    GROUP BY warehouse
)
SELECT warehouse, 
       ROUND(avg_sales_total, 2) AS avg_sales_total
FROM cte
ORDER BY avg_sales_total DESC
LIMIT 1;


-- Sales Channel Analysis
--1. How does the Sales Total vary by sales channel?
SELECT sales_channel, SUM((order_quantity * unit_price) - (order_quantity * unit_cost)) AS Total_Sales
FROM Sales
GROUP BY sales_channel
ORDER BY Total_Sales DESC;

--2. Which sales channel has the highest Sales Net Profit?
SELECT sales_channel, SUM((order_quantity * unit_price) - (order_quantity * unit_cost)) AS Total_Net_Profit
FROM Sales
GROUP BY sales_channel
ORDER BY Total_Net_Profit DESC
LIMIT 1;

-- Discount Analysis
--1. What is the average Sales Total for orders with discounts compared to those without?
SELECT 
    CASE WHEN discount > 0 THEN 'With Discount' ELSE 'Without Discount' END AS Discount_Status,
    ROUND(AVG((order_quantity * unit_price) - (order_quantity * unit_cost)), 2) AS Average_Sales_Total
FROM Sales
GROUP BY Discount_Status;

--2. How much revenue was lost due to discounts across all sales?
SELECT SUM(discount * Order_Quantity) AS Total_Discount_Loss
FROM Sales;

-- Procurement and Shipping Analysis
--1. What is the average time taken from procurement to shipping for each product?
SELECT product_id, ROUND(AVG(ship_date - procured_date), 2) AS Average_Procurement_To_Shipping_Days
FROM Sales
GROUP BY product_id;

--2. How many orders were shipped late (i.e., after the expected delivery date)?
SELECT COUNT(order_number) AS Late_Shipments
FROM Sales
WHERE ship_date > delivery_date;

-- Order Number Analysis
--1. What is the total Sales Net Profit for each order number?
SELECT order_number, SUM((order_quantity * unit_price) - (order_quantity * unit_cost)) AS Total_Net_Profit
FROM Sales
GROUP BY order_number;

--2. How many unique orders were placed in each sales channel?
SELECT sales_channel, COUNT(DISTINCT order_number) AS Unique_Orders
FROM Sales
GROUP BY sales_channel
ORDER BY Unique_Orders DESC;