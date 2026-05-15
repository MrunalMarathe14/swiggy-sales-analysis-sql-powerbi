SELECT * FROM swiggy_data

--data cleaning and validation--
--Null checks
SELECT * FROM swiggy_data;

-- Data Validation & Cleaning

-- Null Check
SELECT
    SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant,
    SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_dish,
    SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
    SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM swiggy_data;

-- Blank or Empty Strings

SELECT *
FROM swiggy_data
WHERE
    State = ''
    OR City = ''
    OR Restaurant_Name = ''
    OR Location = ''
    OR Category = ''
    OR Dish_Name = ''
    OR Price_INR = ''
    OR Rating = ''
    OR Rating_Count = '';
--Duplicate Detection
SELECT 
    State,
    City,
    order_date,
    restaurant_name,
    location,
    category,
    dish_name,
    price_INR,
    rating,
    rating_count,
    COUNT(*) AS duplicate_count
FROM swiggy_data
GROUP BY 
    State,
    City,
    order_date,
    restaurant_name,
    location,
    category,
    dish_name,
    price_INR,
    rating,
    rating_count
HAVING COUNT(*) > 1;

-- 2. Delete Duplicate Records
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY 
                   State,
                   City,
                   order_date,
                   restaurant_name,
                   location,
                   category,
                   dish_name,
                   price_INR,
                   rating,
                   rating_count
               ORDER BY 
                   (SELECT NULL)
           ) AS rn
    FROM swiggy_data
)
DELETE FROM CTE
WHERE rn > 1;

--  Create Date Dimension Table
CREATE TABLE dim_date (
    date_id INT IDENTITY(1,1) PRIMARY KEY,
    full_date DATE,
    year INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT,
    day INT,
    week INT
);

--  Create Location Dimension Table
CREATE TABLE dim_location (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    state VARCHAR(100),
    city VARCHAR(100),
    location VARCHAR(200)
);

--  Create Restaurant Dimension Table
CREATE TABLE dim_restaurant (
    restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
    restaurant_name VARCHAR(200)
);

--  Create Category Dimension Table
CREATE TABLE dim_category (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    category VARCHAR(200)
);
--  Create Dish Dimension Table
CREATE TABLE dim_dish (
    dish_id INT IDENTITY(1,1) PRIMARY KEY,
    dish_name VARCHAR(200)
);

SELECT * FROM swiggy_data

--  Fact Table
CREATE TABLE fact_swiggy_orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,

    date_id INT,
    location_id INT,
    restaurant_id INT,
    category_id INT,
    dish_id INT,

    price_INR DECIMAL(10,2),
    rating DECIMAL(4,2),
    rating_count INT,

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
    FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
    FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
);

SELECT * FROM fact_swiggy_orders


-- =====================================================
-- INSERT DATA INTO DIMENSION TABLES
-- =====================================================

-- 1. Insert Data into Date Dimension
INSERT INTO dim_date (
    full_date,
    year,
    month,
    month_name,
    quarter,
    day,
    week
)
SELECT DISTINCT
    order_date,
    YEAR(order_date),
    MONTH(order_date),
    DATENAME(MONTH, order_date),
    DATEPART(QUARTER, order_date),
    DAY(order_date),
    DATEPART(WEEK, order_date)
FROM swiggy_data
WHERE order_date IS NOT NULL;

SELECT * FROM dim_date

-- 2. Insert Data into Location Dimension
INSERT INTO dim_location (
    state,
    city,
    location
)
SELECT DISTINCT
    state,
    city,
    location
FROM swiggy_data
WHERE state IS NOT NULL
  AND city IS NOT NULL
  AND location IS NOT NULL;

 
-- INSERT DATA INTO RESTAURANT DIMENSION


INSERT INTO dim_restaurant (
    restaurant_name
)
SELECT DISTINCT
    restaurant_name
FROM swiggy_data;


-- INSERT DATA INTO CATEGORY DIMENSION

INSERT INTO dim_category (
    category
)
SELECT DISTINCT
    category
FROM swiggy_data;

-- =====================================================
-- INSERT DATA INTO DISH DIMENSION
-- =====================================================

INSERT INTO dim_dish (
    dish_name
)
SELECT DISTINCT
    dish_name
FROM swiggy_data;

-- =====================================================
-- INSERT DATA INTO FACT TABLE
-- =====================================================

INSERT INTO fact_swiggy_orders (
    date_id,
    price_INR,
    rating,
    rating_count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
)
SELECT
    dd.date_id,
    s.price_INR,
    s.rating,
    s.rating_count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM swiggy_data s
JOIN dim_date dd
    ON dd.full_date = s.order_date
JOIN dim_location dl
    ON dl.state = s.state
   AND dl.city = s.city
   AND dl.location = s.location
JOIN dim_restaurant dr
    ON dr.restaurant_name = s.restaurant_name
JOIN dim_category dc
    ON dc.category = s.category
JOIN dim_dish dsh
    ON dsh.dish_name = s.dish_name;


-- =====================================================
-- VIEW FACT TABLE
-- =====================================================

SELECT *
FROM fact_swiggy_orders;

-- =====================================================
-- VIEW FINAL STAR SCHEMA DATA
-- =====================================================

SELECT *
FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
JOIN dim_location l
    ON f.location_id = l.location_id
JOIN dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
JOIN dim_category c
    ON f.category_id = c.category_id
JOIN dim_dish di
    ON f.dish_id = di.dish_id;


--KPI'S 
--TOTAL ORDERS

SELECT 
    COUNT(*) AS total_orders
FROM fact_swiggy_orders;


-- TOTAL REVENUE IN INR MILLION
SELECT 
    FORMAT(SUM(CONVERT(FLOAT, price_INR)) / 1000000, 'N2') 
    + ' INR Million' AS total_revenue
FROM fact_swiggy_orders;


-- AVERAGE DISH PRICE
SELECT 
    FORMAT(AVG(CONVERT(FLOAT, price_INR)), 'N2') 
    + ' INR' AS average_dish_price
FROM fact_swiggy_orders;

-- AVERAGE RATING
SELECT 
    ROUND(AVG(rating), 2) AS average_rating
FROM fact_swiggy_orders
WHERE rating IS NOT NULL;


-- MONTHLY ORDERS
SELECT 
    d.year,
    d.month,
    d.month_name,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
GROUP BY 
    d.year,
    d.month,
    d.month_name
ORDER BY 
    d.year,
    d.month;

-- QUARTERLY ORDERS
SELECT 
    d.year,
    d.quarter,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
GROUP BY 
    d.year,
    d.quarter
ORDER BY 
    d.year,
    d.quarter;

-- YEARLY ORDERS
SELECT 
    d.year,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
GROUP BY 
    d.year
ORDER BY 
    d.year;

--Monthly Revenue
SELECT 
    d.year,
    d.month,
    d.month_name,
    ROUND(SUM(f.price_INR), 2) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
GROUP BY 
    d.year,
    d.month,
    d.month_name
ORDER BY 
    d.year,
    d.month;

--YEARWISE GROWTH 
SELECT 
    d.year,
    COUNT(f.order_id) AS total_orders,
    ROUND(SUM(f.price_INR), 2) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
GROUP BY 
    d.year
ORDER BY 
    d.year;

--Day-of-Week Order Patterns
SELECT 
    DATENAME(WEEKDAY, d.full_date) AS day_name,
    DATEPART(WEEKDAY, d.full_date) AS day_number,
    COUNT(f.order_id) AS total_orders,
    ROUND(SUM(f.price_INR), 2) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
GROUP BY 
    DATENAME(WEEKDAY, d.full_date),
    DATEPART(WEEKDAY, d.full_date)
ORDER BY 
    day_number;

--Location-Based Analysis
--Top 10 Cities by Order Volume
SELECT TOP 10
    l.city,
    l.state,
    COUNT(f.order_id) AS total_orders,
    ROUND(SUM(f.price_INR), 2) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_location l
    ON f.location_id = l.location_id
GROUP BY 
    l.city,
    l.state
ORDER BY 
    total_orders DESC;

--Revenue Contribution by State
SELECT 
    l.state,
    COUNT(f.order_id) AS total_orders,
    ROUND(SUM(f.price_INR), 2) AS total_revenue,
    ROUND(
        SUM(f.price_INR) * 100.0 / 
        SUM(SUM(f.price_INR)) OVER (), 
        2
    ) AS revenue_contribution_percentage
FROM fact_swiggy_orders f
JOIN dim_location l
    ON f.location_id = l.location_id
GROUP BY 
    l.state
ORDER BY 
    total_revenue DESC;

    --Top Locations by Revenue
SELECT TOP 10
    l.state,
    l.city,
    l.location,
    COUNT(f.order_id) AS total_orders,
    ROUND(SUM(f.price_INR), 2) AS total_revenue,
    ROUND(AVG(f.rating), 2) AS average_rating
FROM fact_swiggy_orders f
JOIN dim_location l
    ON f.location_id = l.location_id
GROUP BY 
    l.state,
    l.city,
    l.location
ORDER BY 
    total_revenue DESC;

--Food Performance Analysis
--Top 10 Restaurants by Orders
SELECT TOP 10
    r.restaurant_name,
    COUNT(f.order_id) AS total_orders,
    ROUND(SUM(f.price_INR), 2) AS total_revenue,
    ROUND(AVG(f.rating), 2) AS average_rating
FROM fact_swiggy_orders f
JOIN dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
GROUP BY 
    r.restaurant_name
ORDER BY 
    total_orders DESC;

--Top 10 Restaurants by Revenue
SELECT TOP 10
    r.restaurant_name,
    COUNT(f.order_id) AS total_orders,
    ROUND(SUM(f.price_INR), 2) AS total_revenue,
    ROUND(AVG(f.rating), 2) AS average_rating
FROM fact_swiggy_orders f
JOIN dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
GROUP BY 
    r.restaurant_name
ORDER BY 
    total_revenue DESC;

--Top Categories by Order Volume
SELECT 
    c.category,
    COUNT(f.order_id) AS total_orders,
    ROUND(SUM(f.price_INR), 2) AS total_revenue,
    ROUND(AVG(f.rating), 2) AS average_rating
FROM fact_swiggy_orders f
JOIN dim_category c
    ON f.category_id = c.category_id
GROUP BY 
    c.category
ORDER BY 
    total_orders DESC;
--Most Ordered Dishes
SELECT TOP 10
    d.dish_name,
    COUNT(f.order_id) AS total_orders,
    ROUND(SUM(f.price_INR), 2) AS total_revenue,
    ROUND(AVG(f.price_INR), 2) AS average_price,
    ROUND(AVG(f.rating), 2) AS average_rating
FROM fact_swiggy_orders f
JOIN dim_dish d
    ON f.dish_id = d.dish_id
GROUP BY 
    d.dish_name
ORDER BY 
    total_orders DESC;

--Cuisine Performance: Orders + Average Rating
SELECT 
    c.category,
    COUNT(f.order_id) AS total_orders,
    ROUND(SUM(f.price_INR), 2) AS total_revenue,
    ROUND(AVG(f.rating), 2) AS average_rating,
    SUM(f.rating_count) AS total_rating_count
FROM fact_swiggy_orders f
JOIN dim_category c
    ON f.category_id = c.category_id
GROUP BY 
    c.category
ORDER BY 
    total_orders DESC;

--Customer Spending Insights
--Spend Bucket Order Distribution
SELECT 
    CASE 
        WHEN price_INR < 100 THEN 'Under 100'
        WHEN price_INR BETWEEN 100 AND 199 THEN '100-199'
        WHEN price_INR BETWEEN 200 AND 299 THEN '200-299'
        WHEN price_INR BETWEEN 300 AND 499 THEN '300-499'
        ELSE '500+'
    END AS spend_bucket,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(price_INR), 2) AS total_revenue,
    ROUND(AVG(price_INR), 2) AS average_price
FROM fact_swiggy_orders
GROUP BY 
    CASE 
        WHEN price_INR < 100 THEN 'Under 100'
        WHEN price_INR BETWEEN 100 AND 199 THEN '100-199'
        WHEN price_INR BETWEEN 200 AND 299 THEN '200-299'
        WHEN price_INR BETWEEN 300 AND 499 THEN '300-499'
        ELSE '500+'
    END
ORDER BY 
    MIN(price_INR);

--Spend Bucket Percentage Distribution
WITH spend_bucket_data AS (
    SELECT 
        CASE 
            WHEN price_INR < 100 THEN 'Under 100'
            WHEN price_INR BETWEEN 100 AND 199 THEN '100-199'
            WHEN price_INR BETWEEN 200 AND 299 THEN '200-299'
            WHEN price_INR BETWEEN 300 AND 499 THEN '300-499'
            ELSE '500+'
        END AS spend_bucket,
        COUNT(order_id) AS total_orders
    FROM fact_swiggy_orders
    GROUP BY 
        CASE 
            WHEN price_INR < 100 THEN 'Under 100'
            WHEN price_INR BETWEEN 100 AND 199 THEN '100-199'
            WHEN price_INR BETWEEN 200 AND 299 THEN '200-299'
            WHEN price_INR BETWEEN 300 AND 499 THEN '300-499'
            ELSE '500+'
        END
)
SELECT 
    spend_bucket,
    total_orders,
    ROUND(
        total_orders * 100.0 / SUM(total_orders) OVER (), 
        2
    ) AS order_percentage
FROM spend_bucket_data
ORDER BY 
    CASE 
        WHEN spend_bucket = 'Under 100' THEN 1
        WHEN spend_bucket = '100-199' THEN 2
        WHEN spend_bucket = '200-299' THEN 3
        WHEN spend_bucket = '300-499' THEN 4
        ELSE 5
    END;

--Ratings Analysis
--Rating Distribution from 1 to 5
SELECT 
    FLOOR(rating) AS rating_group,
    COUNT(order_id) AS total_orders
FROM fact_swiggy_orders
WHERE rating IS NOT NULL
GROUP BY 
    FLOOR(rating)
ORDER BY 
    rating_group;

--Average Rating by Category
SELECT 
    c.category,
    COUNT(f.order_id) AS total_orders,
    ROUND(AVG(f.rating), 2) AS average_rating,
    SUM(f.rating_count) AS total_rating_count
FROM fact_swiggy_orders f
JOIN dim_category c
    ON f.category_id = c.category_id
WHERE f.rating IS NOT NULL
GROUP BY 
    c.category
ORDER BY 
    average_rating DESC;

--Average Rating by City
SELECT 
    l.city,
    l.state,
    COUNT(f.order_id) AS total_orders,
    ROUND(AVG(f.rating), 2) AS average_rating,
    SUM(f.rating_count) AS total_rating_count
FROM fact_swiggy_orders f
JOIN dim_location l
    ON f.location_id = l.location_id
WHERE f.rating IS NOT NULL
GROUP BY 
    l.city,
    l.state
ORDER BY 
    average_rating DESC;

--Best Performing City + Cuisine Combination
SELECT TOP 10
    l.city,
    l.state,
    c.category,
    COUNT(f.order_id) AS total_orders,
    ROUND(SUM(f.price_INR), 2) AS total_revenue,
    ROUND(AVG(f.rating), 2) AS average_rating
FROM fact_swiggy_orders f
JOIN dim_location l
    ON f.location_id = l.location_id
JOIN dim_category c
    ON f.category_id = c.category_id
GROUP BY 
    l.city,
    l.state,
    c.category
ORDER BY 
    total_orders DESC;

--Highest Revenue Dish in Each City
WITH city_dish_revenue AS (
    SELECT 
        l.city,
        l.state,
        d.dish_name,
        SUM(f.price_INR) AS total_revenue,
        COUNT(f.order_id) AS total_orders,
        ROW_NUMBER() OVER (
            PARTITION BY l.city 
            ORDER BY SUM(f.price_INR) DESC
        ) AS rn
    FROM fact_swiggy_orders f
    JOIN dim_location l
        ON f.location_id = l.location_id
    JOIN dim_dish d
        ON f.dish_id = d.dish_id
    GROUP BY 
        l.city,
        l.state,
        d.dish_name
)
SELECT 
    city,
    state,
    dish_name,
    ROUND(total_revenue, 2) AS total_revenue,
    total_orders
FROM city_dish_revenue
WHERE rn = 1
ORDER BY 
    total_revenue DESC;

--High-Rated Restaurants with Good Order Volume
SELECT 
    r.restaurant_name,
    COUNT(f.order_id) AS total_orders,
    ROUND(AVG(f.rating), 2) AS average_rating,
    ROUND(SUM(f.price_INR), 2) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
WHERE f.rating IS NOT NULL
GROUP BY 
    r.restaurant_name
HAVING 
    COUNT(f.order_id) >= 10
    AND AVG(f.rating) >= 4.0
ORDER BY 
    average_rating DESC,
    total_orders DESC;

--Low-Rated Restaurants with High Order Volume
SELECT 
    r.restaurant_name,
    COUNT(f.order_id) AS total_orders,
    ROUND(AVG(f.rating), 2) AS average_rating,
    ROUND(SUM(f.price_INR), 2) AS total_revenue
FROM fact_swiggy_orders f
JOIN dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
WHERE f.rating IS NOT NULL
GROUP BY 
    r.restaurant_name
HAVING 
    COUNT(f.order_id) >= 10
    AND AVG(f.rating) < 3.5
ORDER BY 
    total_orders DESC;