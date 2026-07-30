-- ==============================================================================
-- E-Commerce SQLite Analytics Queries
-- File: scripts.sql
-- ==============================================================================

-- Query 1: Total revenue, order count, and average order value by product category (net of discounts).
SELECT 
    p.category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))) AS net_total_revenue,
    SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))) / COUNT(DISTINCT oi.order_id) AS avg_order_value
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status != 'Cancelled'
GROUP BY p.category
ORDER BY net_total_revenue DESC;


-- Query 2: Top 20 customers by lifetime spend including city and signup date using a JOIN across customers, orders, and order_items.
SELECT 
    c.customer_id,
    c.name,
    c.city,
    c.signup_date,
    SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))) AS lifetime_spend
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status != 'Cancelled'
GROUP BY c.customer_id, c.name, c.city, c.signup_date
ORDER BY lifetime_spend DESC
LIMIT 20;


-- Query 3: Month-over-month revenue trend and percentage growth for the last 24 months using the LAG window function.
WITH monthly_revenue AS (
    SELECT 
        STRFTIME('%Y-%m', o.order_date) AS order_month,
        SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status != 'Cancelled'
      AND o.order_date >= DATE('now', '-24 months')
    GROUP BY order_month
)
SELECT 
    order_month,
    revenue,
    LAG(revenue, 1) OVER (ORDER BY order_month) AS previous_month_revenue,
    ROUND(
        (revenue - LAG(revenue, 1) OVER (ORDER BY order_month)) 
        / LAG(revenue, 1) OVER (ORDER BY order_month) * 100, 2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY order_month ASC;


-- Query 4: Return rate per product category calculated as the share of order items with negative quantity using a CTE.
WITH category_return_stats AS (
    SELECT 
        p.category,
        COUNT(CASE WHEN oi.quantity < 0 THEN 1 END) AS returned_items_count,
        COUNT(oi.order_item_id) AS total_items_count
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category
)
SELECT 
    category,
    returned_items_count,
    total_items_count,
    ROUND((1.0 * returned_items_count / total_items_count) * 100, 2) AS return_rate_pct
FROM category_return_stats
ORDER BY return_rate_pct DESC;


-- Query 5: Customers who placed at least one order in each of the last 3 calendar quarters.
SELECT 
    c.customer_id,
    c.name,
    c.email
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= DATE('now', '-9 months')
  AND o.status != 'Cancelled'
GROUP BY c.customer_id, c.name, c.email
HAVING COUNT(DISTINCT STRFTIME('%Y-Q', o.order_date) 
               || ((CAST(STRFTIME('%m', o.order_date) AS INTEGER) + 2) / 3)) = 3;


-- Query 6: Top 10 products by average review rating among products with at least 15 reviews.
SELECT 
    p.product_id,
    p.name AS product_name,
    p.category,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(r.review_id) AS review_count
FROM products p
JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.name, p.category
HAVING COUNT(r.review_id) >= 15
ORDER BY avg_rating DESC, review_count DESC
LIMIT 10;


-- Query 7: Average session duration and pages viewed by device type for purchasing customers using an EXISTS subquery.
SELECT 
    ws.device,
    ROUND(AVG(ws.duration_minutes), 2) AS avg_session_duration_mins,
    ROUND(AVG(ws.pages_viewed), 2) AS avg_pages_viewed
FROM web_sessions ws
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = ws.customer_id 
      AND o.status != 'Cancelled'
)
GROUP BY ws.device;


-- Query 8: Dense ranking of products by total net revenue within each product category.
WITH product_revenue AS (
    SELECT 
        p.category,
        p.product_id,
        p.name AS product_name,
        SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))) AS total_revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status != 'Cancelled'
    GROUP BY p.category, p.product_id, p.name
)
SELECT 
    category,
    product_name,
    total_revenue,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) AS category_revenue_rank
FROM product_revenue
ORDER BY category, category_revenue_rank;


-- Query 9: Payment method share of total orders broken down by customer country using window functions.
SELECT 
    c.country,
    o.payment_method,
    COUNT(o.order_id) AS total_orders,
    ROUND(
        100.0 * COUNT(o.order_id) / SUM(COUNT(o.order_id)) OVER (PARTITION BY c.country), 2
    ) AS payment_share_pct
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.country, o.payment_method
ORDER BY c.country, payment_share_pct DESC;


-- Query 10: Gross profit margin and customer cohort analysis by signup year to evaluate customer acquisition profitability over time.
SELECT 
    STRFTIME('%Y', c.signup_date) AS cohort_year,
    COUNT(DISTINCT c.customer_id) AS total_customers_in_cohort,
    SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))) AS net_revenue,
    SUM(oi.quantity * p.cost) AS total_product_cost,
    SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))) - SUM(oi.quantity * p.cost) AS gross_profit,
    ROUND(
        ((SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))) - SUM(oi.quantity * p.cost)) 
        / SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0)))) * 100, 2
    ) AS gross_profit_margin_pct
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status != 'Cancelled'
GROUP BY cohort_year
ORDER BY cohort_year ASC;