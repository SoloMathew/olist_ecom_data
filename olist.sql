-- 1. Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset:


-- 1.	Data type of all columns in the "customers" table.


-- 2.	Get the time range between which the orders were placed.


SELECT
MIN(order_purchase_timestamp) AS start_date,
MAX(order_purchase_timestamp) AS end_date,
CONCAT(DATE_DIFF(MAX(order_purchase_timestamp), MIN(order_purchase_timestamp),DAY)," ","days") AS time_period
FROM
`Olist_SQL_Business_Case.orders`;

-- 3.	Count the Cities & States of customers who ordered during the given period.


SELECT
SUM(count_states) AS count_of_states,
SUM(count_cities) AS count_of_cities
FROM
(SELECT
COUNT(DISTINCT(customer_state)) AS count_states,
COUNT(DISTINCT(customer_city)) AS count_cities
FROM
`Olist_SQL_Business_Case.orders` AS o JOIN `Olist_SQL_Business_Case.customers` AS c
ON o.customer_id = c.customer_id
GROUP BY customer_state);

-- 2. In-depth Exploration:


-- 1.	Is there a growing trend in the no. of orders placed over the past years?


SELECT
EXTRACT(YEAR from order_purchase_timestamp) AS year,
COUNT(order_id) AS order_count
FROM
`Olist_SQL_Business_Case.orders`
GROUP BY year
ORDER BY year;

-- 2.	Can we see some kind of monthly seasonality in terms of the no. of orders being placed?


SELECT
year,
month_name,
order_count
FROM
(SELECT
EXTRACT(YEAR from order_purchase_timestamp) AS year,
EXTRACT(MONTH from order_purchase_timestamp) AS month,
FORMAT_DATE("%B", order_purchase_timestamp) AS month_name,
COUNT(order_id) AS order_count
FROM
`Olist_SQL_Business_Case.orders`
GROUP BY year, month, month_name
ORDER BY year, month) AS temp;

-- 3.	During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)

SELECT
time_of_day,
COUNT(time_of_day) AS order_count
FROM
(SELECT
CASE
WHEN hours >= 0 AND hours < 6 THEN "Dawn"
WHEN hours >= 6 AND hours < 12 THEN "Mornings"
WHEN hours >= 12 AND hours < 18 THEN "Afternoon"
ELSE "Night"
END AS time_of_day
FROM
(SELECT
EXTRACT(HOUR FROM hour) AS hours
FROM
(SELECT
CAST(order_purchase_timestamp AS DATETIME) AS hour
FROM
`Olist_SQL_Business_Case.orders`) AS temp) AS temp1
ORDER BY time_of_day DESC) AS main
GROUP BY time_of_day
ORDER BY order_count DESC;

-- 3.  Evolution of E-commerce orders in the Brazil region:

-- 1.	Get the month on month no. of orders placed in each state.

SELECT
year,
months, 
customer_state,
order_count
FROM
(SELECT
EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
FORMAT_DATE("%B", order_purchase_timestamp) AS months,
customer_state,
COUNT(o.customer_id) AS order_count
FROM
`Olist_SQL_Business_Case.orders` AS o JOIN `Olist_SQL_Business_Case.customers` AS c
ON o.customer_id = c.customer_id
GROUP BY year, month, months, customer_state
ORDER BY year, month, customer_state) AS temp;

-- 2.	How are the customers distributed across all the states?


SELECT
customer_state,
COUNT(customer_id) AS customer_count
FROM
`Olist_SQL_Business_Case.customers`
GROUP BY customer_state
ORDER BY customer_count DESC;

-- 4. Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.

-- 1.	Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).

WITH year_wise AS
(
  SELECT
  EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
  EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
  FORMAT_DATE("%B", order_purchase_timestamp) AS months,
  ROUND(SUM(payment_value),2) AS cost_of_orders
  FROM
  `Olist_SQL_Business_Case.payments` AS p JOIN `Olist_SQL_Business_Case.orders` AS o
  ON p.order_id = o.order_id
  GROUP BY year, month, months
  ORDER BY year, month
),

y2017 AS
(
  SELECT
  year,
  month,
  months,
  cost_of_orders AS cost_2017
  FROM
  year_wise
  WHERE year = 2017
  ORDER BY month
),

y2018 AS
(
  SELECT
  year,
  month,
  months,
  cost_of_orders AS cost_2018
  FROM
  year_wise
  WHERE year = 2018
  ORDER BY month

)

SELECT
months,
cost_2017,
cost_2018,
percentage_difference
FROM
(SELECT
y2017.month AS rowss,
y2017.months,
y2017.cost_2017,
y2018.cost_2018,
ROUND((y2018.cost_2018 - y2017.cost_2017) / y2018.cost_2017,2) AS percentage_difference
FROM
y2017 JOIN y2018
ON y2017.month = y2018.month
ORDER BY rowss) AS temp;


-- 2.	Calculate the Total & Average value of order price for each state.


SELECT
customer_state,
ROUND(SUM(price),2) AS sum_of_orders,
ROUND(AVG(price),2) AS avg_price
FROM
(`Olist_SQL_Business_Case.customers` AS c RIGHT JOIN
(`Olist_SQL_Business_Case.orders` AS o JOIN `Olist_SQL_Business_Case.order_items` AS oi
ON o.order_id = oi.order_id) 
ON c.customer_id = o.customer_id)
GROUP BY customer_state
ORDER BY sum_of_orders;


-- 3.	Calculate the Total & Average value of order freight for each state.

SELECT
customer_state,
ROUND(SUM(freight_value),2) AS sum_of_freight,
ROUND(AVG(freight_value),2) AS avg_freight
FROM
(`Olist_SQL_Business_Case.customers` AS c RIGHT JOIN (`Olist_SQL_Business_Case.orders` AS o JOIN `Olist_SQL_Business_Case.order_items` AS oi
ON o.order_id = oi.order_id) 
ON c.customer_id = o.customer_id)
GROUP BY customer_state
ORDER BY sum_of_freight;

-- 5.  Analysis based on sales, freight and delivery time.


-- 1.	Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.
-- Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
-- Do this in a single query.


SELECT
order_id,
order_purchase_timestamp,
order_delivered_customer_date,
order_estimated_delivery_date,
DATE_DIFF(order_delivered_customer_date, order_purchase_timestamp, day) AS time_to_deliver,
DATE_DIFF(order_estimated_delivery_date, order_delivered_customer_date, day) AS diff_estimated_delivery
FROM
`Olist_SQL_Business_Case.orders`
WHERE order_delivered_customer_date IS NOT NULL
ORDER BY order_purchase_timestamp;


-- 2.	Find out the top 5 states with the highest & lowest average freight value.


WITH highest_frieght AS
(
  SELECT
  customer_state,
  high_avg_freight,
  ROW_NUMBER() OVER(ORDER BY high_avg_freight DESC) AS rowss
  FROM
  (SELECT
  customer_state,
  ROUND(AVG(freight_value),2) AS high_avg_freight
  FROM
  (`Olist_SQL_Business_Case.customers` AS c JOIN
  (`Olist_SQL_Business_Case.orders` AS o JOIN `Olist_SQL_Business_Case.order_items` AS oi
  ON o.order_id = oi.order_id) 
  ON c.customer_id = o.customer_id)
  GROUP BY customer_state
  ORDER BY high_avg_freight DESC
  LIMIT 5) AS temp
),

lowest_freight AS
(
  SELECT
  ROW_NUMBER() OVER(ORDER BY low_avg_freight) AS rowss,
  customer_state,
  low_avg_freight
  FROM
  (SELECT
  customer_state,
  ROUND(AVG(freight_value),2) AS low_avg_freight
  FROM
  (`Olist_SQL_Business_Case.customers` AS c JOIN
  (`Olist_SQL_Business_Case.orders` AS o JOIN `Olist_SQL_Business_Case.order_items` AS oi
  ON o.order_id = oi.order_id) 
  ON c.customer_id = o.customer_id)
  GROUP BY customer_state
  ORDER BY low_avg_freight
  LIMIT 5) AS temp
)

SELECT
h.customer_state,
h.high_avg_freight,
l.customer_state,
l.low_avg_freight
FROM
highest_frieght AS h JOIN lowest_freight AS l
ON h.rowss = l.rowss;


-- 3.	Find out the top 5 states with the highest & lowest average delivery time.


WITH highest_del_time AS
(
  SELECT
  ROW_NUMBER() OVER(ORDER BY high_delivery_time DESC) AS rowss,
  customer_state,
  high_delivery_time
  FROM
  (SELECT
  customer_state,
  ROUND(AVG(DATE_DIFF(order_delivered_customer_date, order_purchase_timestamp, day)),2) AS high_delivery_time
  FROM
  (`Olist_SQL_Business_Case.customers` AS c JOIN `Olist_SQL_Business_Case.orders` AS o 
  ON c.customer_id = o.customer_id)
  GROUP BY customer_state
  ORDER BY high_delivery_time DESC
  LIMIT 5) AS temp
),

lowest_del_time AS
(
  SELECT
  ROW_NUMBER() OVER(ORDER BY low_delivery_time) AS rowss,
  customer_state,
  low_delivery_time
  FROM
  (SELECT
  customer_state,
  ROUND(AVG(DATE_DIFF(order_delivered_customer_date, order_purchase_timestamp, day)),2) AS low_delivery_time
  FROM
  (`Olist_SQL_Business_Case.customers` AS c JOIN
  (`Olist_SQL_Business_Case.orders` AS o JOIN `Olist_SQL_Business_Case.order_items` AS oi
  ON o.order_id = oi.order_id) 
  ON c.customer_id = o.customer_id)
  GROUP BY customer_state
  ORDER BY low_delivery_time
  LIMIT 5) AS temp
)

SELECT
h.customer_state,
h.high_delivery_time,
l.customer_state,
l.low_delivery_time
FROM
highest_del_time AS h JOIN lowest_del_time AS l
ON h.rowss = l.rowss;


-- 4.	Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.


SELECT 
    customer_state, avg_delivery_speed
FROM
    (SELECT 
        customer_state,
            CASE
                WHEN ROUND(avg_delivery_time - avg_estimated_deliery_time, 2) < 0 THEN CONCAT(ABS(ROUND(avg_delivery_time - avg_estimated_deliery_time, 2)), ' ', 'days early')
                WHEN ROUND(avg_delivery_time - avg_estimated_deliery_time, 2) > 0 THEN CONCAT(ROUND(avg_delivery_time - avg_estimated_deliery_time, 2), ' ', 'days delayed')
                ELSE 'Delivered on time'
            END AS avg_delivery_speed,
            CASE
                WHEN ROUND(avg_delivery_time - avg_estimated_deliery_time, 2) < 0 THEN ROUND(avg_delivery_time - avg_estimated_deliery_time, 2)
                WHEN ROUND(avg_delivery_time - avg_estimated_deliery_time, 2) > 0 THEN ROUND(avg_delivery_time - avg_estimated_deliery_time, 2)
                ELSE 0
            END AS pseudo_del_speed
    FROM
        (SELECT 
        customer_state,
            ROUND(AVG(DATE_DIFF(order_delivered_customer_date, order_purchase_timestamp, day)), 2) AS avg_delivery_time,
            ROUND(AVG(DATE_DIFF(order_estimated_delivery_date, order_purchase_timestamp, day)), 2) AS avg_estimated_deliery_time
    FROM
        (`Olist_SQL_Business_Case.customers` AS c
    JOIN `Olist_SQL_Business_Case.orders` AS o ON c.customer_id = o.customer_id)
    GROUP BY customer_state) AS temp
    ORDER BY pseudo_del_speed
    LIMIT 5) AS main;

-- 6.  Analysis based on the payments:


-- 1.	Find the month on month no. of orders placed using different payment types.



SELECT
year,
months,
payment_type,
order_count
FROM
(SELECT
EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
FORMAT_DATE("%B", order_purchase_timestamp) AS months,
payment_type,
COUNT(p.order_id) AS order_count
FROM
`Olist_SQL_Business_Case.payments` AS p JOIN `Olist_SQL_Business_Case.orders` AS o
ON p.order_id = o.order_id
GROUP BY payment_type, year, month, months
ORDER BY year, month, payment_type) AS temp;

-- 2.	Find the no. of orders placed on the basis of the payment installments that have been paid.



SELECT
payment_installments,
COUNT(DISTINCT (order_id)) AS order_count
FROM
`Olist_SQL_Business_Case.payments`
GROUP BY payment_installments
ORDER BY payment_installments;
