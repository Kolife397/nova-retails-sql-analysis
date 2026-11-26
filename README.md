# NOVA Retail SQL Analysis

A SQL portfolio project analyzing a synthetic retail dataset to examine business performance, product sales, customer activity, employee performance, order trends, payment methods, and fulfilment-related order statuses.

## Project Overview

This project uses SQLite to explore a fictional retailer's sales and order data. The analysis is organized into 31 queries across seven sections, moving from overall business performance to product, customer, employee, order, payment-method, and delivery/fulfilment analysis.

The goal is to demonstrate practical SQL skills: joining relational tables, aggregating data, calculating business metrics, using common table expressions (CTEs), subqueries, CASE expressions, window functions, and date functions, and organizing queries around business questions.

## Dataset

The project uses a generated, synthetic dataset for learning and portfolio practice. It does not contain real customer or transaction records.

| Table | Description | Row count |
|---|---|---:|
| `customers` | Customer details and customer segments | 100 |
| `employees` | Employee details and sales teams | 15 |
| `products` | Product names, categories, and unit prices | 32 |
| `orders` | Order dates, customers, employees, channels, payment methods, and statuses | 1,000 |
| `order_items` | Products, quantities, and item-level discounts per order | 2,517 |

### Data relationships

- `orders.customer_id` references `customers.customer_id`.
- `orders.employee_id` references `employees.employee_id`.
- `order_items.order_id` references `orders.order_id`.
- `order_items.product_id` references `products.product_id`.

## Tools and SQL Features

- **Database:** SQLite
- **Query language:** SQL (SQLite dialect)
- **Database setup and exploration:** SQLite-compatible SQL editor, such as DB Browser for SQLite
- **Portfolio hosting:** GitHub

SQL techniques used include `SELECT`, filtering with `WHERE`, `INNER JOIN` and `LEFT JOIN`, `GROUP BY`, aggregate functions, `COUNT(DISTINCT ...)`, subqueries, CTEs, `CASE`, `ROW_NUMBER()`, `STRFTIME()`, `ROUND()`, and `COALESCE()`.

## Analysis Sections

| Section | Focus | Queries |
|---|---|---:|
| A | Business performance: revenue, completed orders, average order value, units sold, monthly revenue, and discounts | 6 |
| B | Product performance: product revenue, units sold, completed orders, top products, and discount value | 4 |
| C | Customer analysis: customer-level performance, customer types, revenue contribution, and average orders per customer | 4 |
| D | Employee performance: revenue, revenue contribution, completed orders, average order value, and units sold | 5 |
| E | Order performance: order-status distribution, revenue contribution, and monthly completed-order and revenue trends | 4 |
| F | Payment-method performance: order distribution, revenue, average order value, and contribution metrics | 4 |
| G | Delivery and fulfilment: order-status distribution, revenue by status, payment-method/status combinations, and cancellation rate | 4 |
| **Total** | | **31** |

## Metric Definitions

- **Gross revenue:** `unit_price × quantity`, before item discounts.
- **Net revenue:** `unit_price × quantity`, less the item-level discount.
- **Total discount value:** gross revenue less net revenue.
- **Average order value (AOV):** completed-order net revenue divided by the number of distinct completed orders.
- **Units sold:** sum of item quantities for the selected order population.
- **Contribution percentage:** a group's value divided by the corresponding total, multiplied by 100.

Unless a query explicitly examines all order statuses, sales and revenue metrics are filtered to orders with status `Completed`. Order-status analysis includes the applicable status categories.

## Selected Overall Results

The following baseline results were reproduced from the supplied dataset and business-analysis queries:

| Metric | Result |
|---|---:|
| Completed orders | 936 |
| Net revenue from completed orders | 98,154,275.00 |
| Average order value for completed orders | 104,865.68 |

The dataset does not specify a currency, so the values are shown without a currency symbol.

## Repository Structure

After adding the project files, the repository is intended to follow this structure:

```text
nova-retails-sql-analysis/
├── README.md
├── dataset/
│   └── NOVA_Retail_Dataset.sql
└── sql/
    └── NOVA_Retail_Business_Analysis.sql
```

## How to Run the Project

1. Clone or download this repository.
2. Open a SQLite-compatible database tool, such as DB Browser for SQLite.
3. Open the dataset setup script in the `dataset/` folder and execute it first. This creates and populates the five tables.
4. Open `sql/NOVA_Retail_Business_Analysis.sql`.
5. Run the numbered queries individually or section by section to inspect each result set.

Run the dataset setup script before the analysis script. The analysis queries expect the five tables to exist in the active SQLite database.

## Scope and Limitations

- The dataset is synthetic and intended for SQL practice; results should not be interpreted as real-world company performance.
- The dataset includes order dates and order statuses but does not include delivery dates or shipment-event timestamps. Therefore, actual delivery duration or on-time delivery rates cannot be calculated from the supplied fields.
- Revenue calculations use the listed unit prices, quantities, and item-level discount percentages. The dataset does not state a currency.

---

*Created as a SQL portfolio project using a synthetic retail dataset.*
