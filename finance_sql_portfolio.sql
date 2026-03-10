-- ============================================================
--  FINANCE ANALYST SQL PORTFOLIO
--  Author: Ekene Ozonuwe
--  Stack: SQLite (syntax compatible with PostgreSQL / SQL Server)
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- 1. REVENUE TREND ANALYSIS
--    Monthly revenue growth with MoM % change
-- ────────────────────────────────────────────────────────────

WITH monthly_revenue AS (
    SELECT
        strftime('%Y-%m', order_date)   AS month,
        SUM(revenue)                    AS total_revenue
    FROM sales
    GROUP BY 1
),
lagged AS (
    SELECT
        month,
        total_revenue,
        LAG(total_revenue) OVER (ORDER BY month) AS prev_revenue
    FROM monthly_revenue
)
SELECT
    month,
    total_revenue,
    prev_revenue,
    ROUND(
        (total_revenue - prev_revenue) * 100.0 / prev_revenue, 2
    ) AS mom_growth_pct
FROM lagged
ORDER BY month;


-- ────────────────────────────────────────────────────────────
-- 2. CUSTOMER COHORT RETENTION
--    % of first-month customers who returned each month
-- ────────────────────────────────────────────────────────────

WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(strftime('%Y-%m', order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
activity AS (
    SELECT
        o.customer_id,
        f.cohort_month,
        strftime('%Y-%m', o.order_date)    AS activity_month
    FROM orders o
    JOIN first_purchase f USING (customer_id)
)
SELECT
    cohort_month,
    activity_month,
    COUNT(DISTINCT customer_id)                        AS active_customers,
    ROUND(
        COUNT(DISTINCT customer_id) * 100.0 /
        FIRST_VALUE(COUNT(DISTINCT customer_id))
            OVER (PARTITION BY cohort_month ORDER BY activity_month),
        1
    ) AS retention_pct
FROM activity
GROUP BY cohort_month, activity_month
ORDER BY cohort_month, activity_month;


-- ────────────────────────────────────────────────────────────
-- 3. P&L SUMMARY — BUDGET VS ACTUAL VARIANCE
-- ────────────────────────────────────────────────────────────

SELECT
    department,
    category,
    SUM(CASE WHEN type = 'actual' THEN amount END)  AS actual,
    SUM(CASE WHEN type = 'budget' THEN amount END)  AS budget,
    SUM(CASE WHEN type = 'actual' THEN amount END)
        - SUM(CASE WHEN type = 'budget' THEN amount END) AS variance,
    ROUND(
        (SUM(CASE WHEN type = 'actual' THEN amount END)
            - SUM(CASE WHEN type = 'budget' THEN amount END))
        * 100.0
        / NULLIF(SUM(CASE WHEN type = 'budget' THEN amount END), 0),
        2
    ) AS variance_pct
FROM financials
WHERE fiscal_year = 2024
GROUP BY department, category
ORDER BY ABS(variance) DESC;


-- ────────────────────────────────────────────────────────────
-- 4. ROLLING 3-MONTH AVERAGE REVENUE (moving average)
-- ────────────────────────────────────────────────────────────

SELECT
    month,
    total_revenue,
    ROUND(
        AVG(total_revenue) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_3m_avg
FROM monthly_revenue   -- CTE from query #1
ORDER BY month;


-- ────────────────────────────────────────────────────────────
-- 5. TOP 10% CUSTOMERS BY LIFETIME VALUE (PERCENTILE)
-- ────────────────────────────────────────────────────────────

WITH customer_ltv AS (
    SELECT
        customer_id,
        SUM(revenue)   AS lifetime_value,
        COUNT(*)       AS total_orders,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order
    FROM orders
    GROUP BY customer_id
),
ranked AS (
    SELECT *,
        NTILE(10) OVER (ORDER BY lifetime_value DESC) AS decile
    FROM customer_ltv
)
SELECT *
FROM ranked
WHERE decile = 1
ORDER BY lifetime_value DESC;


-- ────────────────────────────────────────────────────────────
-- 6. ACCOUNTS RECEIVABLE AGING REPORT
-- ────────────────────────────────────────────────────────────

SELECT
    customer_id,
    invoice_id,
    invoice_date,
    due_date,
    amount_due,
    amount_paid,
    amount_due - amount_paid AS balance,
    JULIANDAY('now') - JULIANDAY(due_date) AS days_overdue,
    CASE
        WHEN JULIANDAY('now') - JULIANDAY(due_date) <= 0   THEN 'Current'
        WHEN JULIANDAY('now') - JULIANDAY(due_date) <= 30  THEN '1–30 days'
        WHEN JULIANDAY('now') - JULIANDAY(due_date) <= 60  THEN '31–60 days'
        WHEN JULIANDAY('now') - JULIANDAY(due_date) <= 90  THEN '61–90 days'
        ELSE '90+ days'
    END AS aging_bucket
FROM invoices
WHERE amount_paid < amount_due
ORDER BY days_overdue DESC;


-- ────────────────────────────────────────────────────────────
-- 7. YEAR-OVER-YEAR REVENUE COMPARISON
-- ────────────────────────────────────────────────────────────

SELECT
    strftime('%m', order_date)                    AS month_num,
    SUM(CASE WHEN strftime('%Y', order_date) = '2023' THEN revenue END) AS revenue_2023,
    SUM(CASE WHEN strftime('%Y', order_date) = '2024' THEN revenue END) AS revenue_2024,
    ROUND(
        (SUM(CASE WHEN strftime('%Y', order_date) = '2024' THEN revenue END)
         - SUM(CASE WHEN strftime('%Y', order_date) = '2023' THEN revenue END))
        * 100.0
        / NULLIF(SUM(CASE WHEN strftime('%Y', order_date) = '2023' THEN revenue END), 0),
        2
    ) AS yoy_growth_pct
FROM sales
GROUP BY 1
ORDER BY 1;
