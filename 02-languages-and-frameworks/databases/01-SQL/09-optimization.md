# Query Optimization — Making Slow Queries Fast

**How to find slow queries, understand why they're slow, and fix them.**

---

## Why Optimization Matters

Real scenario:

```
Without optimization:
- Page loads in 8 seconds
- Users leave
- Server overloaded
- Company loses money

With optimization:
- Same page loads in 0.2 seconds
- Users happy
- Server relaxed
- Business runs smooth
```

**Same data. Same query. Just written differently.**

---

## The Optimization Process

Always follow this order:

```
Step 1: Find slow query
Step 2: EXPLAIN the query
Step 3: Identify the problem
Step 4: Fix it
Step 5: Verify improvement
```

Never skip steps. Never guess.

---

# EXPLAIN — Your Most Important Tool

## What is EXPLAIN?

Shows you HOW the database executes your query.

```sql
EXPLAIN SELECT name FROM employees WHERE salary > 80000;
```

Output:

```
id | table     | type  | possible_keys | key        | rows   | Extra
1  | employees | range | idx_salary    | idx_salary | 245    | Using index
```

---

## Reading EXPLAIN Output

### `type` column — Most Important

Shows how database scans the table:

```
ALL    → Full table scan (WORST)
       Reads every single row
       Problem: 1M rows = reads 1M rows

index  → Full index scan (BAD)
       Reads entire index
       Better than ALL but still slow

range  → Index range scan (GOOD)
       Reads part of index
       Fast for range queries

ref    → Index lookup (VERY GOOD)
       Uses index to find specific rows
       Fast

eq_ref → Unique index lookup (EXCELLENT)
       One row per index lookup
       Very fast

const  → Single row (BEST)
       Finds exactly 1 row immediately
       Instant
```

**Simple rule:**
```
ALL = Problem. Fix it.
index = Could be better.
range/ref/eq_ref/const = Good.
```

---

### `rows` column

Estimated rows database will read:

```
rows: 1000000 → Reads all 1M rows (BAD)
rows: 245     → Reads only 245 rows (GOOD)
```

Lower is better.

---

### `key` column

Which index was used:

```
key: NULL       → No index used (problem!)
key: idx_salary → Using idx_salary index (good)
```

---

### `Extra` column

Additional info:

```
Using filesort     → Sorting without index (slow)
Using temporary    → Using temp table (slow)
Using index        → Covered by index (fast)
Using where        → Filtering after read
```

---

## Before and After EXPLAIN

### Before optimization:

```sql
EXPLAIN SELECT name, salary 
FROM employees 
WHERE salary > 80000;
```

```
type: ALL
rows: 1000000
key: NULL
Extra: Using where
```

Problem: Full table scan, no index.

### Add index:

```sql
CREATE INDEX idx_salary ON employees(salary);
```

### After optimization:

```sql
EXPLAIN SELECT name, salary 
FROM employees 
WHERE salary > 80000;
```

```
type: range
rows: 245
key: idx_salary
Extra: Using index condition
```

**1000000 → 245 rows. 4000x improvement.**

---

# Common Query Problems and Fixes

## Problem 1: SELECT * (Too Many Columns)

```sql
-- ❌ BAD
SELECT * FROM employees;
-- Reads all columns
-- Transfers unnecessary data
-- Slow on wide tables

-- ✅ GOOD
SELECT emp_id, name, salary FROM employees;
-- Only reads needed columns
-- Less data transfer
-- Faster
```

**When it matters:**
- Table has 50+ columns
- Millions of rows
- Network overhead

---

## Problem 2: No WHERE Clause

```sql
-- ❌ BAD
SELECT name FROM employees;
-- Returns ALL 1M employees
-- Slow + uses lots of memory

-- ✅ GOOD
SELECT name FROM employees WHERE dept_id = 10;
-- Returns only IT employees
-- Fast + less memory
```

---

## Problem 3: WHERE on Calculated Column

```sql
-- ❌ BAD (Index not used)
SELECT name FROM employees 
WHERE salary * 12 > 1000000;
-- Calculation on column = index ignored
-- Full table scan!

-- ✅ GOOD (Index used)
SELECT name FROM employees 
WHERE salary > 83333;
-- Move calculation outside
-- Index works now
```

---

## Problem 4: LIKE with Leading Wildcard

```sql
-- ❌ BAD (Index not used)
SELECT name FROM employees 
WHERE name LIKE '%Rahul%';
-- Leading % = can't use index
-- Full table scan!

-- ✅ GOOD (Index used)
SELECT name FROM employees 
WHERE name LIKE 'Rahul%';
-- No leading % = index works
-- Fast!

-- If you MUST search inside text:
-- Use full-text search instead
CREATE FULLTEXT INDEX idx_name ON employees(name);
SELECT name FROM employees 
WHERE MATCH(name) AGAINST('Rahul');
```

---

## Problem 5: OR Instead of IN

```sql
-- ❌ BAD (Slower)
SELECT name FROM employees 
WHERE dept_id = 10 
   OR dept_id = 20 
   OR dept_id = 30;

-- ✅ GOOD (Faster)
SELECT name FROM employees 
WHERE dept_id IN (10, 20, 30);
-- Cleaner + often faster
-- Index used efficiently
```

---

## Problem 6: NOT IN / NOT EXISTS (Slow)

```sql
-- ❌ BAD (Very slow)
SELECT name FROM employees 
WHERE dept_id NOT IN (
  SELECT dept_id FROM departments WHERE location = 'Bangalore'
);
-- NOT IN with subquery = full scan

-- ✅ GOOD (Fast)
SELECT e.name 
FROM employees e
LEFT JOIN departments d 
  ON e.dept_id = d.dept_id 
  AND d.location = 'Bangalore'
WHERE d.dept_id IS NULL;
-- LEFT JOIN + NULL check = faster
```

---

## Problem 7: Subquery Instead of JOIN

```sql
-- ❌ BAD (Subquery runs for every row)
SELECT name 
FROM employees 
WHERE dept_id IN (
  SELECT dept_id 
  FROM departments 
  WHERE location = 'Bangalore'
);
-- Subquery runs once per employee row
-- Very slow on large tables

-- ✅ GOOD (JOIN runs once)
SELECT e.name 
FROM employees e
INNER JOIN departments d 
  ON e.dept_id = d.dept_id
WHERE d.location = 'Bangalore';
-- Single JOIN operation
-- Much faster
```

---

## Problem 8: Functions on Indexed Columns

```sql
-- ❌ BAD (Index ignored)
SELECT name FROM employees 
WHERE YEAR(hire_date) = 2020;
-- Function on column = index not used

-- ✅ GOOD (Index used)
SELECT name FROM employees 
WHERE hire_date >= '2020-01-01' 
  AND hire_date < '2021-01-01';
-- Range on column = index used
```

---

## Problem 9: DISTINCT Overuse

```sql
-- ❌ BAD (Sorting entire result)
SELECT DISTINCT dept_id FROM employees;
-- DISTINCT = sort + deduplicate
-- Slow on large tables

-- ✅ GOOD (If you just need unique values)
SELECT dept_id FROM departments;
-- Just query the source table directly
-- Already has unique values
```

---

## Problem 10: ORDER BY Without Index

```sql
-- ❌ BAD (Filesort)
SELECT name, salary 
FROM employees 
ORDER BY salary DESC;
-- No index on salary
-- Database sorts in memory (filesort)
-- Slow for millions of rows

-- ✅ GOOD
CREATE INDEX idx_salary ON employees(salary DESC);

SELECT name, salary 
FROM employees 
ORDER BY salary DESC;
-- Uses index, no sorting needed
-- Fast!
```

---

# N+1 Query Problem

## What is N+1?

Running 1 query to get list, then 1 query per item.

```
// Application code (BAD)

departments = SELECT * FROM departments;
// Returns 10 departments

For each department:
  employees = SELECT * FROM employees WHERE dept_id = X;
  // Runs 10 more queries!

Total: 1 + 10 = 11 queries
For 1000 departments = 1001 queries!
```

### Fix: Use JOIN

```sql
-- ✅ GOOD (Single query)
SELECT d.dept_name, e.name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id;
-- 1 query instead of N+1
-- Much faster
```

---

# Using CTEs for Readability and Performance

## Complex Query Without CTE (Hard to Read)

```sql
SELECT e.name, e.salary, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > (
  SELECT AVG(salary) 
  FROM employees e2 
  WHERE e2.dept_id = e.dept_id
)
ORDER BY e.salary DESC;
```

## Same Query With CTE (Clear and Fast)

```sql
WITH dept_avg AS (
  SELECT dept_id, AVG(salary) AS avg_salary
  FROM employees
  GROUP BY dept_id
)
SELECT e.name, e.salary, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN dept_avg da ON e.dept_id = da.dept_id
WHERE e.salary > da.avg_salary
ORDER BY e.salary DESC;
```

Benefits:
- Easier to read
- Database executes CTE once (not per row)
- Often faster

---

# Pagination Optimization

## Bad Pagination (Gets Slower as Page Increases)

```sql
-- ❌ BAD (Page 1 - fast)
SELECT * FROM orders LIMIT 10 OFFSET 0;

-- ❌ BAD (Page 100000 - very slow)
SELECT * FROM orders LIMIT 10 OFFSET 1000000;
-- Database reads 1,000,010 rows then throws away 1,000,000!
```

## Good Pagination (Always Fast)

```sql
-- ✅ GOOD (Keyset pagination)
-- First page
SELECT * FROM orders 
WHERE order_id > 0
ORDER BY order_id 
LIMIT 10;

-- Next page (use last order_id from previous result)
SELECT * FROM orders 
WHERE order_id > 1234  -- Last ID from previous page
ORDER BY order_id 
LIMIT 10;
-- Always fast, always uses index
```

---

# Query Optimization Checklist

Before writing any query, ask:

```
□ Do I really need SELECT *? 
  → Specify only needed columns

□ Is there a WHERE clause?
  → Always filter when possible

□ Are my JOIN conditions correct?
  → Check ON clause carefully

□ Is any index column wrapped in function?
  → Move calculation outside WHERE

□ Am I using LIKE with leading %?
  → Use full-text search instead

□ Can I replace subquery with JOIN?
  → JOINs are usually faster

□ Am I using ORDER BY on large table?
  → Add index for that column

□ Did I run EXPLAIN?
  → Check type is not ALL
  → Check rows is low

□ Did I test with real data volume?
  → Small data = fast, large data = different story
```

---

# Real World Example: Dashboard Query

## Scenario

Product dashboard needs to show:
- Total orders today
- Revenue today
- Top 5 products
- Recent 10 customers

## Slow Version (Multiple Queries)

```sql
-- Query 1: Total orders
SELECT COUNT(*) FROM orders WHERE order_date = TODAY();

-- Query 2: Revenue
SELECT SUM(total) FROM orders WHERE order_date = TODAY();

-- Query 3: Top products
SELECT product_id, SUM(qty) as total
FROM order_items
GROUP BY product_id
ORDER BY total DESC
LIMIT 5;

-- Query 4: Recent customers
SELECT customer_id, name
FROM customers
ORDER BY created_date DESC
LIMIT 10;

-- 4 separate queries to database = slow
```

## Fast Version (Optimized)

```sql
-- Single CTE combining all
WITH today_orders AS (
  SELECT order_id, total, customer_id
  FROM orders
  WHERE order_date = CURDATE()
),
top_products AS (
  SELECT oi.product_id, SUM(oi.quantity) as total_qty
  FROM order_items oi
  INNER JOIN today_orders o ON oi.order_id = o.order_id
  GROUP BY oi.product_id
  ORDER BY total_qty DESC
  LIMIT 5
)
SELECT
  (SELECT COUNT(*) FROM today_orders) as total_orders,
  (SELECT SUM(total) FROM today_orders) as revenue,
  tp.product_id,
  tp.total_qty
FROM top_products tp;
```

Plus: Make sure these indexes exist:

```sql
CREATE INDEX idx_order_date ON orders(order_date);
CREATE INDEX idx_order_items_order ON order_items(order_id);
```

---

# Practice Exercises

## Setup

```sql
CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  name VARCHAR(50),
  salary INT,
  dept_id INT,
  hire_date DATE
);

CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name VARCHAR(50),
  location VARCHAR(50)
);

-- Insert 10 sample rows
INSERT INTO departments VALUES
(10, 'Frontend', 'Bangalore'),
(20, 'Backend', 'Hyderabad'),
(30, 'DevOps', 'Pune');

INSERT INTO employees VALUES
(1, 'Rahul', 85000, 10, '2020-01-15'),
(2, 'Priya', 92000, 20, '2019-03-20'),
(3, 'Amit', 78000, 10, '2021-06-10'),
(4, 'Sneha', 65000, NULL, '2022-02-05'),
(5, 'Vikram', 88000, 10, '2020-09-12');
```

---

## Exercises

### Exercise 1: EXPLAIN Practice

```
Task:
1. Run EXPLAIN on this query:
   SELECT * FROM employees WHERE salary > 80000;

2. Note: type=ALL, rows=5, key=NULL

3. Add index: CREATE INDEX idx_salary ON employees(salary);

4. Run EXPLAIN again

5. Compare: type, rows, key

Expected improvement:
Before: type=ALL, rows=5
After: type=range, rows=2, key=idx_salary
```

---

### Exercise 2: Fix SELECT *

```sql
-- ❌ BAD query
SELECT * FROM employees WHERE dept_id = 10;

Task:
Rewrite to select only: name, salary, dept_id

-- ✅ Expected solution
SELECT name, salary, dept_id 
FROM employees 
WHERE dept_id = 10;
```

---

### Exercise 3: Replace Subquery with JOIN

```sql
-- ❌ SLOW (subquery)
SELECT name FROM employees 
WHERE dept_id IN (
  SELECT dept_id FROM departments WHERE location = 'Bangalore'
);

Task: Rewrite using JOIN

-- ✅ Expected solution
SELECT e.name 
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Bangalore';
```

---

### Exercise 4: Fix LIKE Query

```sql
-- ❌ BAD (full scan)
SELECT name FROM employees WHERE name LIKE '%amit%';

Task: 
1. What's the problem?
2. Can you rewrite for better performance?

-- Answer:
-- Problem: Leading % prevents index use
-- If searching from start:
SELECT name FROM employees WHERE name LIKE 'Amit%';
-- Index on name will work
```

---

### Exercise 5: Fix Calculated Column

```sql
-- ❌ BAD (index ignored)
SELECT name FROM employees 
WHERE salary * 1.1 > 90000;

Task: Rewrite without calculation on column

-- ✅ Expected solution
SELECT name FROM employees 
WHERE salary > 81818;
-- (90000 / 1.1 = 81818)
```

---

### Exercise 6: ORDER BY Optimization

```sql
-- Check if this is slow
SELECT name, salary 
FROM employees 
ORDER BY salary DESC 
LIMIT 5;

Task:
1. Run EXPLAIN (check for "Using filesort")
2. Add index to fix it
3. Run EXPLAIN again

-- Solution:
CREATE INDEX idx_salary_desc ON employees(salary DESC);
```

---

### Exercise 7: Fix OR with IN

```sql
-- ❌ BAD
SELECT name FROM employees 
WHERE dept_id = 10 OR dept_id = 20;

Task: Rewrite using IN

-- ✅ Expected solution
SELECT name FROM employees 
WHERE dept_id IN (10, 20);
```

---

### Exercise 8: Full Optimization Task

```sql
-- ❌ Slow query
SELECT * 
FROM employees 
WHERE YEAR(hire_date) = 2020 
  AND dept_id IN (
    SELECT dept_id 
    FROM departments 
    WHERE location != 'Pune'
  )
ORDER BY salary DESC;

Task: Identify all problems, rewrite completely

Problems:
1. SELECT * (specify columns)
2. YEAR() function on column (use range)
3. Subquery (replace with JOIN)

-- ✅ Expected solution
SELECT e.name, e.salary, e.hire_date
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.hire_date >= '2020-01-01'
  AND e.hire_date < '2021-01-01'
  AND d.location != 'Pune'
ORDER BY e.salary DESC;

-- Plus add indexes:
CREATE INDEX idx_hire_date ON employees(hire_date);
CREATE INDEX idx_dept_loc ON departments(location);
```

---

# Summary Table

| Problem | Fix | Improvement |
|---------|-----|-------------|
| SELECT * | Specify columns | Less data transfer |
| No WHERE | Add WHERE clause | Read fewer rows |
| No index | CREATE INDEX | 10-1000x faster |
| Leading % LIKE | Rewrite or full-text | Full scan avoided |
| Function on column | Move calc outside | Index works |
| Subquery | Replace with JOIN | Single pass |
| OR conditions | Use IN | Cleaner + faster |
| OFFSET pagination | Keyset pagination | Always fast |
| N+1 queries | Use JOIN | 1 query instead |
| Missing EXPLAIN | Always check EXPLAIN | Verify improvement |

---

# Golden Rules

```
1. Always run EXPLAIN first
2. Look for type=ALL in EXPLAIN (bad)
3. Look for rows count in EXPLAIN (lower = better)
4. Never use function on indexed column in WHERE
5. Replace subqueries with JOINs where possible
6. Specify columns instead of SELECT *
7. Add index for ORDER BY columns
8. Use IN instead of multiple OR
9. Avoid leading % in LIKE
10. Test with production-like data volume
```

---

## Key Takeaways

- **EXPLAIN** is your best debugging tool
- **type=ALL** means full table scan — always fix this
- **Indexes** make most problems go away
- **JOINs** are faster than subqueries
- **Functions on columns** kill index performance
- **Test with real data** — small tables hide problems

---

## What's Next?

You've completed the SQL Learning Path!

```
✅ 01-basics.md
✅ 02-join.md
✅ 03-agreegation-subquery-cte.md
✅ 04-window-functions.md
✅ 05-insert-update-delete.md
✅ 06-transactions-and-locking.md
✅ 07-data-modeling.md
✅ 08-indexes.md
✅ 09-optimization.md  ← YOU ARE HERE
```

**Next step: Practice Databases**

Go to `04-Practice/` and solve all 40 exercises.

Apply everything you learned here.

Good luck! 🚀