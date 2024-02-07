# Olist E-Commerce Sales Data Analysis

## Table of Contents

- [Project Overview](#project-overview)
- [Data Sources](#data-sources)
- [Tools](#tools)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Data Analysis](#data-analysis)
- [Results](#results)
- [Recommendations](#recommendations)
- [Reference](#reference)

### Project Overview
---

This particular data analysis project focuses on the operations of Olist in Brazil and provides insightful information about 100,000 orders placed between 2016 and 2018. By analyzing this extensive dataset, it becomes possible to gain valuable insights into Olist's operations in Brazil.

![image] (https://github.com/SoloMathew/olist_ecom_data/blob/main/olist_dashboard_snap.png)

### Data Sources

The data is available in 8 csv files:

customers.csv,
sellers.csv,
order_items.csv,
geolocation.csv,
payments.csv,
reviews.csv,
orders.csv,
products.csv

![image](https://github.com/SoloMathew/olist_ecom_data/blob/main/schema.png)

### Tools

- BigQuery - Data Analysis
- Tableau - Data Visiualisation ([Viz Link](https://public.tableau.com/app/profile/solomon.mathew/viz/olist_17072536116760/Dashboard1))

### Exploratory Data Analysis

EDA involved exploring the sales data to answer key questions, such as:

- What is the data type of each table?
- What is the order timeline range?
- From how many cities and states orders were placed?

### Data Analysis

#### Some Interesting Queries

**Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).**

```sql
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
ROUND((y2018.cost_2018 - y2017.cost_2017) / y2018.cost_2018,2) AS percentage_difference
FROM
y2017 JOIN y2018
ON y2017.month = y2018.month
ORDER BY rowss) AS temp;
```

**Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.**

```sql
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
```

### Results

The analysis results are summarized as follows:
1. The average freight value and delivery time are directly proportional to each other for the top and bottom five states in Brazil.
2. State SP has the maximum count of orders on a month-on-month basis, it is also the most populous state.
3. Brazilians have ordered the maximum during the afternoon, followed closely by night and mornings.
4. There has been an increasing trend in the order count from the year 2017 to 2018.

### Recommendations

Based on the analysis, we recommend the following actions:
- Afternoons would be the best time of the day for Olist to run their campaigns or any promotional events.
- For the states where actual delivery times are faster as compared to their estimated delivery time, we can either reduce the estimated time, thereby making the customer feel more valued. Or we can reduce the freight charges for these states, thereby reducing the total cost per order.

### Reference
- [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
