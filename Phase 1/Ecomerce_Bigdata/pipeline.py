import sqlite3
import pandas as pd

# 1. Establish a live connection to your SQLite database
conn = sqlite3.connect('ecommerce.db')

# Query 1: Performance by Category
q1_sql = """
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
"""
df_category_perf = pd.read_sql_query(q1_sql, conn)


# Query 3: Month-over-Month Revenue Trend
q3_sql = """
WITH monthly_revenue AS (
    SELECT 
        STRFTTIME('%Y-%m', o.order_date) AS order_month,
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
"""
df_mom_trend = pd.read_sql_query(q3_sql, conn)


# Query 4: Return Rate by Category
q4_sql = """
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
"""
df_return_rates = pd.read_sql_query(q4_sql, conn)


# Query 9: Payment Method Mix by Country
q9_sql = """
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
"""
df_payment_mix = pd.read_sql_query(q9_sql, conn)

# Close connection when finished querying
conn.close()

# Verify your dataframes are ready
print("--- Extracted Data Summary ---")
print("1. Category Performance rows:", len(df_category_perf))
print("2. MoM Trend rows:", len(df_mom_trend))
print("3. Return Rates rows:", len(df_return_rates))
print("4. Payment Mix rows:", len(df_payment_mix))


# Add this to the bottom of pipeline.py
df_category_perf.to_csv('category_performance.csv', index=False)
df_mom_trend.to_csv('mom_trend.csv', index=False)
df_return_rates.to_csv('return_rates.csv', index=False)
df_payment_mix.to_csv('payment_mix.csv', index=False)

print("Data exported to CSV successfully!")


import pandas as pd
import sqlite3

conn = sqlite3.connect('ecommerce.db')

# Example: Check for missing or unexpected values across extracted data
print("--- Missing Values Check ---")
print(df_category_perf.isnull().sum())

# Inspect return rates/negative quantities summary
print("\n--- Summary Statistics for Return Rates ---")
print(df_return_rates.describe())
