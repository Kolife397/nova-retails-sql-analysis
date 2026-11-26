-- ============================================================================
-- NOVA RETAIL | BUSINESS ANALYSIS
-- SQL dialect: SQLite
-- Purpose: Business performance analysis using the NOVA Retail dataset
-- Prerequisite: Load the NOVA Retail dataset tables before running this script.
-- Sections: A. Business | B. Product | C. Customer | D. Employee
--           E. Order | F. Payment Method | G. Delivery and Fulfilment
-- ============================================================================

-- ============================================================================
-- SECTION A: BUSINESS PERFORMANCE
-- ============================================================================

-- A1. Total net revenue from completed orders
SELECT
    SUM(
        p.unit_price * i.quantity *
        (1 - (i.discount_pct * 1.0) / 100)
    ) AS net_revenue
FROM order_items i
INNER JOIN products p
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON i.order_id = o.order_id
WHERE o.order_status = 'Completed';

-- A2. Total number of completed orders
SELECT
    COUNT(*) AS completed_orders
FROM orders
WHERE order_status = 'Completed';

-- A3. Average order value (AOV) for completed orders
SELECT
    ROUND(
        1.0 * SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) / COUNT(DISTINCT o.order_id),
        2
    ) AS AOV
FROM order_items i
INNER JOIN products p
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON i.order_id = o.order_id
WHERE o.order_status = 'Completed';

-- A4. Total units sold in completed orders
SELECT
    SUM(i.quantity) AS units_sold
FROM order_items i
INNER JOIN orders o
    ON i.order_id = o.order_id
WHERE o.order_status = 'Completed';

-- A5. Monthly net revenue from completed orders
SELECT
    STRFTIME('%Y-%m', o.order_date) AS order_month,
    SUM(
        p.unit_price * i.quantity *
        (1 - (i.discount_pct * 1.0) / 100)
    ) AS net_revenue
FROM order_items i
INNER JOIN products p
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON i.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY STRFTIME('%Y-%m', o.order_date)
ORDER BY order_month;

-- A6. Gross revenue, net revenue, and total discount value for completed orders
SELECT
    SUM(p.unit_price * i.quantity) AS gross_revenue,
    SUM(
        p.unit_price * i.quantity *
        (1 - (i.discount_pct * 1.0) / 100)
    ) AS net_revenue,
    SUM(
        p.unit_price * i.quantity * (i.discount_pct * 1.0) / 100
    ) AS total_discount_value
FROM order_items i
INNER JOIN products p
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON i.order_id = o.order_id
WHERE o.order_status = 'Completed';


-- ============================================================================
-- SECTION B: PRODUCT PERFORMANCE ANALYSIS
-- ============================================================================

-- B1. Product performance by net revenue, units sold, and completed orders
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(
        p.unit_price * i.quantity *
        (1 - (i.discount_pct * 1.0) / 100)
    ) AS net_revenue,
    SUM(i.quantity) AS units_sold,
    COUNT(DISTINCT o.order_id) AS completed_orders
FROM order_items i
INNER JOIN products p
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON i.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY net_revenue DESC, units_sold DESC;

-- B2. Top 10 products by net revenue
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(
        p.unit_price * i.quantity *
        (1 - (i.discount_pct * 1.0) / 100)
    ) AS net_revenue,
    SUM(i.quantity) AS units_sold,
    COUNT(DISTINCT o.order_id) AS completed_orders
FROM order_items i
INNER JOIN products p
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON i.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY net_revenue DESC
LIMIT 10;

-- B3. Highest net-revenue product in each product category
WITH product_revenue AS (
    SELECT
        p.product_id,
        p.category,
        p.product_name,
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) AS net_revenue
    FROM order_items i
    INNER JOIN products p
        ON i.product_id = p.product_id
    INNER JOIN orders o
        ON i.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.product_id, p.category, p.product_name
),
ranked_products AS (
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY net_revenue DESC
        ) AS category_rank,
        category,
        product_name,
        net_revenue
    FROM product_revenue
)
SELECT
    category_rank,
    category,
    product_name,
    net_revenue
FROM ranked_products
WHERE category_rank = 1
ORDER BY category;

-- B4. Product gross revenue, net revenue, and discount value
SELECT
    p.product_id,
    p.product_name,
    p.category,
    ROUND(SUM(p.unit_price * i.quantity), 2) AS gross_revenue,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue,
    ROUND(
        SUM(p.unit_price * i.quantity * (i.discount_pct * 1.0) / 100),
        2
    ) AS discount_value
FROM order_items i
INNER JOIN products p
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON i.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY discount_value DESC;


-- ============================================================================
-- SECTION C: CUSTOMER-LEVEL ANALYSIS
-- ============================================================================

-- C1. Customer performance ranked by net revenue
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    SUM(i.quantity) AS units_purchased,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue
FROM order_items i
INNER JOIN products p
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON i.order_id = o.order_id
INNER JOIN customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY net_revenue DESC;

-- C2. Customer performance ranked by completed orders
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue
FROM order_items i
INNER JOIN products p
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON i.order_id = o.order_id
INNER JOIN customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY completed_orders DESC;

-- C3. Net revenue contribution by customer type
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.customer_name,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) AS net_revenue
    FROM order_items i
    INNER JOIN products p
        ON i.product_id = p.product_id
    INNER JOIN orders o
        ON i.order_id = o.order_id
    LEFT JOIN customers c
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
),
customer_types AS (
    SELECT
        customer_id,
        customer_name,
        completed_orders,
        net_revenue,
        CASE
            WHEN completed_orders = 1 THEN 'One-time Customer'
            WHEN completed_orders BETWEEN 2 AND 9 THEN 'Repeat Customer'
            WHEN completed_orders >= 10 THEN 'Frequent Customer'
        END AS customer_type
    FROM customer_metrics
),
revenue_by_type AS (
    SELECT
        customer_type,
        COUNT(*) AS customer_count,
        SUM(completed_orders) AS total_completed_orders,
        SUM(net_revenue) AS total_net_revenue
    FROM customer_types
    GROUP BY customer_type
),
total_revenue AS (
    SELECT
        SUM(net_revenue) AS total_net_revenue
    FROM customer_metrics
)
SELECT
    r.customer_type,
    r.customer_count,
    r.total_completed_orders,
    ROUND(r.total_net_revenue, 2) AS total_net_revenue,
    ROUND(
        100.0 * r.total_net_revenue / t.total_net_revenue,
        2
    ) AS revenue_contribution_pct
FROM revenue_by_type r
CROSS JOIN total_revenue t
ORDER BY r.customer_count DESC;

-- C4. Average number of completed orders per customer by customer type
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.customer_name,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) AS net_revenue
    FROM order_items i
    INNER JOIN products p
        ON i.product_id = p.product_id
    INNER JOIN orders o
        ON i.order_id = o.order_id
    LEFT JOIN customers c
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
),
customer_types AS (
    SELECT
        customer_id,
        customer_name,
        completed_orders,
        CASE
            WHEN completed_orders = 1 THEN 'One-time Customer'
            WHEN completed_orders BETWEEN 2 AND 9 THEN 'Repeat Customer'
            WHEN completed_orders >= 10 THEN 'Frequent Customer'
        END AS customer_type
    FROM customer_metrics
)
SELECT
    customer_type,
    COUNT(*) AS customer_count,
    SUM(completed_orders) AS total_completed_orders,
    ROUND(
        1.0 * SUM(completed_orders) / COUNT(*),
        2
    ) AS average_orders_per_customer
FROM customer_types
GROUP BY customer_type
ORDER BY customer_count DESC;


-- ============================================================================
-- SECTION D: EMPLOYEE PERFORMANCE ANALYSIS
-- ============================================================================

-- D1. Employee performance ranked by net revenue
SELECT
    e.employee_id,
    e.employee_name,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    SUM(i.quantity) AS total_units_sold,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue
FROM order_items i
INNER JOIN products p
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON i.order_id = o.order_id
LEFT JOIN employees e
    ON e.employee_id = o.employee_id
WHERE o.order_status = 'Completed'
GROUP BY e.employee_id, e.employee_name
ORDER BY net_revenue DESC;

-- D2. Employee contribution to total net revenue
WITH total_revenue AS (
    SELECT
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) AS total_net_revenue
    FROM order_items i
    INNER JOIN products p
        ON i.product_id = p.product_id
    INNER JOIN orders o
        ON i.order_id = o.order_id
    WHERE o.order_status = 'Completed'
)
SELECT
    e.employee_id,
    e.employee_name,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue,
    ROUND(
        100.0 * SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) / (SELECT total_net_revenue FROM total_revenue),
        2
    ) AS revenue_contribution_pct
FROM order_items i
INNER JOIN products p
    ON i.product_id = p.product_id
INNER JOIN orders o
    ON i.order_id = o.order_id
LEFT JOIN employees e
    ON e.employee_id = o.employee_id
WHERE o.order_status = 'Completed'
GROUP BY e.employee_id, e.employee_name
ORDER BY revenue_contribution_pct DESC;

-- D3. Employee performance ranked by completed orders
SELECT
    e.employee_id,
    e.employee_name,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    SUM(i.quantity) AS units_sold,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue
FROM order_items i
INNER JOIN orders o
    ON o.order_id = i.order_id
INNER JOIN products p
    ON p.product_id = i.product_id
INNER JOIN employees e
    ON e.employee_id = o.employee_id
WHERE o.order_status = 'Completed'
GROUP BY e.employee_id, e.employee_name
ORDER BY completed_orders DESC;

-- D4. Employee performance ranked by average order value (AOV)
SELECT
    e.employee_id,
    e.employee_name,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue,
    ROUND(
        1.0 * SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) / COUNT(DISTINCT o.order_id),
        2
    ) AS AOV
FROM order_items i
INNER JOIN orders o
    ON o.order_id = i.order_id
INNER JOIN products p
    ON p.product_id = i.product_id
INNER JOIN employees e
    ON e.employee_id = o.employee_id
WHERE o.order_status = 'Completed'
GROUP BY e.employee_id, e.employee_name
ORDER BY AOV DESC;

-- D5. Employee performance ranked by units sold
SELECT
    e.employee_id,
    e.employee_name,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    SUM(i.quantity) AS units_sold,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue
FROM order_items i
INNER JOIN orders o
    ON o.order_id = i.order_id
INNER JOIN products p
    ON p.product_id = i.product_id
INNER JOIN employees e
    ON e.employee_id = o.employee_id
WHERE o.order_status = 'Completed'
GROUP BY e.employee_id, e.employee_name
ORDER BY units_sold DESC;


-- ============================================================================
-- SECTION E: ORDER PERFORMANCE
-- ============================================================================

-- E1. Order distribution by status
WITH total_orders AS (
    SELECT
        COUNT(*) AS total_order_count
    FROM orders
)
SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(
        100.0 * COUNT(*) / (SELECT total_order_count FROM total_orders),
        2
    ) AS pct_order_contribution
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- E2. Net revenue and revenue contribution by order status
WITH total_revenue AS (
    SELECT
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) AS total_net_revenue
    FROM order_items i
    INNER JOIN orders o
        ON o.order_id = i.order_id
    INNER JOIN products p
        ON p.product_id = i.product_id
)
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue,
    ROUND(
        100.0 * SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) / (SELECT total_net_revenue FROM total_revenue),
        2
    ) AS pct_revenue_contribution
FROM order_items i
INNER JOIN orders o
    ON o.order_id = i.order_id
INNER JOIN products p
    ON p.product_id = i.product_id
GROUP BY o.order_status
ORDER BY net_revenue DESC;

-- E3. Monthly percentage of completed orders
WITH total_orders AS (
    SELECT
        STRFTIME('%Y-%m', order_date) AS order_month,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY STRFTIME('%Y-%m', order_date)
),
total_completed_orders AS (
    SELECT
        STRFTIME('%Y-%m', order_date) AS order_month,
        COUNT(*) AS completed_orders
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY STRFTIME('%Y-%m', order_date)
)
SELECT
    t.order_month,
    t.order_count,
    COALESCE(c.completed_orders, 0) AS completed_orders,
    ROUND(
        100.0 * COALESCE(c.completed_orders, 0) / t.order_count,
        2
    ) AS pct_completed_orders
FROM total_orders t
LEFT JOIN total_completed_orders c
    ON t.order_month = c.order_month
ORDER BY t.order_month;

-- E4. Monthly performance trend for completed orders
SELECT
    STRFTIME('%Y-%m', o.order_date) AS order_month,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    SUM(i.quantity) AS units_sold,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS total_net_revenue
FROM order_items i
INNER JOIN orders o
    ON o.order_id = i.order_id
INNER JOIN products p
    ON p.product_id = i.product_id
WHERE o.order_status = 'Completed'
GROUP BY STRFTIME('%Y-%m', o.order_date)
ORDER BY order_month;


-- ============================================================================
-- SECTION F: PAYMENT METHOD PERFORMANCE
-- ============================================================================

-- F1. Order distribution by payment method
WITH total_orders AS (
    SELECT
        COUNT(*) AS total_order_count
    FROM orders
)
SELECT
    payment_method,
    COUNT(*) AS order_count,
    ROUND(
        100.0 * COUNT(*) / (SELECT total_order_count FROM total_orders),
        2
    ) AS pct_order_contribution
FROM orders
GROUP BY payment_method
ORDER BY order_count DESC;

-- F2. Completed-order net revenue performance by payment method
WITH total_revenue AS (
    SELECT
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) AS total_net_revenue
    FROM order_items i
    INNER JOIN orders o
        ON o.order_id = i.order_id
    INNER JOIN products p
        ON p.product_id = i.product_id
    WHERE o.order_status = 'Completed'
)
SELECT
    o.payment_method,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    SUM(i.quantity) AS units_sold,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue,
    ROUND(
        100.0 * SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) / (SELECT total_net_revenue FROM total_revenue),
        2
    ) AS pct_revenue_contribution
FROM order_items i
INNER JOIN orders o
    ON o.order_id = i.order_id
INNER JOIN products p
    ON p.product_id = i.product_id
WHERE o.order_status = 'Completed'
GROUP BY o.payment_method
ORDER BY net_revenue DESC;

-- F3. Average order value (AOV) by payment method
SELECT
    o.payment_method,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue,
    ROUND(
        1.0 * SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) / COUNT(DISTINCT o.order_id),
        2
    ) AS AOV
FROM order_items i
INNER JOIN orders o
    ON o.order_id = i.order_id
INNER JOIN products p
    ON p.product_id = i.product_id
WHERE o.order_status = 'Completed'
GROUP BY o.payment_method
ORDER BY AOV DESC;

-- F4. Payment method contribution to completed orders and net revenue
WITH total_revenue AS (
    SELECT
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) AS total_net_revenue
    FROM order_items i
    INNER JOIN orders o
        ON o.order_id = i.order_id
    INNER JOIN products p
        ON p.product_id = i.product_id
    WHERE o.order_status = 'Completed'
),
total_orders AS (
    SELECT
        COUNT(*) AS total_order_count
    FROM orders
    WHERE order_status = 'Completed'
)
SELECT
    o.payment_method,
    COUNT(DISTINCT o.order_id) AS completed_orders,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue,
    ROUND(
        100.0 * COUNT(DISTINCT o.order_id) /
        (SELECT total_order_count FROM total_orders),
        2
    ) AS pct_order_contribution,
    ROUND(
        100.0 * SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ) / (SELECT total_net_revenue FROM total_revenue),
        2
    ) AS pct_revenue_contribution
FROM order_items i
INNER JOIN orders o
    ON o.order_id = i.order_id
INNER JOIN products p
    ON p.product_id = i.product_id
WHERE o.order_status = 'Completed'
GROUP BY o.payment_method
ORDER BY pct_revenue_contribution DESC;


-- ============================================================================
-- SECTION G: DELIVERY AND FULFILMENT
-- ============================================================================

-- G1. Order distribution by status
WITH total_orders AS (
    SELECT
        COUNT(*) AS total_order_count
    FROM orders
)
SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(
        100.0 * COUNT(*) / (SELECT total_order_count FROM total_orders),
        2
    ) AS pct_order_contribution
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- G2. Net revenue by order status
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(
        SUM(
            p.unit_price * i.quantity *
            (1 - (i.discount_pct * 1.0) / 100)
        ),
        2
    ) AS net_revenue
FROM order_items i
INNER JOIN orders o
    ON o.order_id = i.order_id
INNER JOIN products p
    ON p.product_id = i.product_id
GROUP BY o.order_status
ORDER BY net_revenue DESC;

-- G3. Order counts by payment method and order status
SELECT
    payment_method,
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY payment_method, order_status
ORDER BY order_count DESC;

-- G4. Cancellation rate by payment method
WITH total_orders AS (
    SELECT
        payment_method,
        COUNT(*) AS total_order_count
    FROM orders
    GROUP BY payment_method
),
completed AS (
    SELECT
        payment_method,
        COUNT(*) AS completed_orders
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY payment_method
),
pending AS (
    SELECT
        payment_method,
        COUNT(*) AS pending_orders
    FROM orders
    WHERE order_status = 'Pending'
    GROUP BY payment_method
),
cancelled AS (
    SELECT
        payment_method,
        COUNT(*) AS cancelled_orders
    FROM orders
    WHERE order_status = 'Cancelled'
    GROUP BY payment_method
)
SELECT
    t.payment_method,
    COALESCE(c.completed_orders, 0) AS completed_orders,
    COALESCE(p.pending_orders, 0) AS pending_orders,
    COALESCE(x.cancelled_orders, 0) AS cancelled_orders,
    t.total_order_count,
    ROUND(
        100.0 * COALESCE(x.cancelled_orders, 0) / t.total_order_count,
        2
    ) AS cancellation_rate
FROM total_orders t
LEFT JOIN completed c
    ON t.payment_method = c.payment_method
LEFT JOIN pending p
    ON t.payment_method = p.payment_method
LEFT JOIN cancelled x
    ON t.payment_method = x.payment_method
ORDER BY cancellation_rate DESC;

-- ============================================================================
-- END OF NOVA RETAIL BUSINESS ANALYSIS
-- ============================================================================
