# Aggregation, Subqueries & CTEs — Summarizing and Nesting Data

**These three work together. Learn them as a group.**

---

## Why This Matters

JOINs combine tables horizontally (more columns).  
Aggregation + Subqueries + CTEs work vertically — **summarizing, filtering, and organizing results**.

Real interview questions almost always combine all three.

---

# PART 1 — Aggregation

## What is Aggregation?

Aggregation = **summarizing many rows into one number**.

Without aggregation:
```
emp_id  name    salary  dept
1       Rahul   50000   Frontend
2       Priya   60000   Backend
3       Amit    55000   Frontend
4       Sneha   70000   Backend
```

With aggregation:
```
dept       avg_salary  total_employees
Frontend   52500       2
Backend    65000       2
```

Many rows → few summary rows.

---

## The 5 Core Aggregate Functions

```sql
COUNT()   -- How many rows?
SUM()     -- Total of a column
AVG()     -- Average of a column
MIN()     -- Smallest value
MAX()     -- Largest value
```

### Examples:

```sql
-- How many employees total?
SELECT COUNT(*) FROM employees;
-- Result: 4

-- What is total salary bill?
SELECT SUM(salary) FROM employees;
-- Result: 235000

-- What is average salary?
SELECT AVG(salary) FROM employees;
-- Result: 58750

-- Who has lowest salary?
SELECT MIN(salary) FROM employees;
-- Result: 50000

-- Who has highest salary?
SELECT MAX(salary) FROM employees;
-- Result: 70000
```

---

## GROUP BY — The Most Important Clause

Without GROUP BY, aggregate functions return **one row for the whole table**.

With GROUP BY, they return **one row per group**.

**Question: What is average salary per department?**

```sql
SELECT dept, AVG(salary) as avg_salary
FROM employees
GROUP BY dept;
```

**Result:**
```
dept       avg_salary
Frontend   52500
Backend    65000
```

**What happened:**
- All Frontend rows grouped → averaged → one row
- All Backend rows grouped → averaged → one row

**Rule: Every column in SELECT must be either:**
1. Inside an aggregate function, OR
2. In the GROUP BY clause

```sql
-- WRONG ❌
SELECT name, dept, AVG(salary)
FROM employees
GROUP BY dept;
-- ERROR: name is not in GROUP BY and not aggregated

-- RIGHT ✅
SELECT dept, AVG(salary)
FROM employees
GROUP BY dept;
```

---

## HAVING — Filter After Grouping

`WHERE` filters **before** grouping.  
`HAVING` filters **after** grouping.

**Question: Show departments where average salary > 55000**

```sql
SELECT dept, AVG(salary) as avg_salary
FROM employees
GROUP BY dept
HAVING AVG(salary) > 55000;
```

**Result:**
```
dept     avg_salary
Backend  65000
```

Frontend (52500) was removed — below 55000.

**WHERE vs HAVING:**

```sql
-- WHERE: filter rows before grouping
SELECT dept, AVG(salary)
FROM employees
WHERE dept != 'DevOps'       -- remove DevOps rows first
GROUP BY dept
HAVING AVG(salary) > 55000;  -- then filter groups

-- Rule: Can't use aggregate in WHERE
-- WRONG ❌
WHERE AVG(salary) > 55000

-- RIGHT ✅
HAVING AVG(salary) > 55000
```

---

## COUNT(*) vs COUNT(column)

```sql
-- COUNT(*) — counts ALL rows including NULLs
SELECT COUNT(*) FROM employees;
-- Result: 4

-- COUNT(column) — counts only NON-NULL values
SELECT COUNT(dept_id) FROM employees;
-- Result: 3 (Sneha has NULL dept_id, not counted)
```

**COUNT(DISTINCT column) — count unique values:**

```sql
SELECT COUNT(DISTINCT dept) FROM employees;
-- Result: 2 (Frontend, Backend)
```

---

## Real-World Aggregation Examples

### E-commerce: Sales Summary

```sql
-- Total revenue per product category
SELECT 
  p.category,
  COUNT(oi.order_item_id) as total_orders,
  SUM(oi.quantity * oi.price) as total_revenue,
  AVG(oi.price) as avg_price
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
HAVING SUM(oi.quantity * oi.price) > 100000
ORDER BY total_revenue DESC;
```

### HR: Department Summary

```sql
-- Departments with more than 5 employees
SELECT 
  dept,
  COUNT(*) as headcount,
  AVG(salary) as avg_salary,
  MAX(salary) as top_salary,
  MIN(salary) as bottom_salary
FROM employees
GROUP BY dept
HAVING COUNT(*) > 5
ORDER BY avg_salary DESC;
```

---

# PART 2 — Subqueries

## What is a Subquery?

A subquery is **a query inside another query**.

Think of it as: answer a small question first, then use that answer in the main question.

```sql
SELECT name
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
```

Inner query runs first:
```sql
SELECT AVG(salary) FROM employees
-- Returns: 58750
```

Then outer query uses that result:
```sql
SELECT name FROM employees WHERE salary > 58750
-- Returns: Priya (60000), Sneha (70000)
```

---

## 3 Places to Use Subqueries

### 1. Subquery in WHERE

```sql
-- Find employees earning more than average
SELECT name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Find employees in the same dept as 'Rahul'
SELECT name
FROM employees
WHERE dept_id = (
  SELECT dept_id 
  FROM employees 
  WHERE name = 'Rahul'
);
```

### 2. Subquery in FROM (Derived Table)

```sql
-- Use aggregation result as a table
SELECT dept, avg_salary
FROM (
  SELECT dept, AVG(salary) as avg_salary
  FROM employees
  GROUP BY dept
) as dept_summary
WHERE avg_salary > 55000;
```

The inner query creates a **temporary table** called `dept_summary`.  
Outer query filters it.

### 3. Subquery in SELECT (Scalar Subquery)

```sql
-- Show each employee with company average
SELECT 
  name,
  salary,
  (SELECT AVG(salary) FROM employees) as company_avg,
  salary - (SELECT AVG(salary) FROM employees) as diff_from_avg
FROM employees;
```

**Result:**
```
name   salary  company_avg  diff_from_avg
Rahul  50000   58750        -8750
Priya  60000   58750        +1250
Amit   55000   58750        -3750
Sneha  70000   58750        +11250
```

---

## IN, NOT IN, EXISTS, NOT EXISTS

### IN — value exists in a list

```sql
-- Find employees in Frontend or Backend
SELECT name FROM employees
WHERE dept IN ('Frontend', 'Backend');

-- Find employees in departments that have manager
SELECT name FROM employees
WHERE dept_id IN (
  SELECT dept_id FROM departments WHERE has_manager = true
);
```

### NOT IN — value does NOT exist

```sql
-- Find departments with NO employees
SELECT dept_name FROM departments
WHERE dept_id NOT IN (
  SELECT DISTINCT dept_id 
  FROM employees 
  WHERE dept_id IS NOT NULL  -- important: exclude NULLs
);
```

⚠️ **NOT IN + NULL = danger:**
```sql
-- If subquery returns any NULL, NOT IN returns nothing!
-- Always add WHERE column IS NOT NULL inside NOT IN subquery
```

### EXISTS — faster alternative to IN for large data

```sql
-- Find departments that HAVE at least one employee
SELECT dept_name
FROM departments d
WHERE EXISTS (
  SELECT 1 
  FROM employees e 
  WHERE e.dept_id = d.dept_id
);

-- EXISTS just checks IF rows exist — doesn't care what SELECT returns
-- SELECT 1 is a convention — SELECT * works too
```

### NOT EXISTS

```sql
-- Find departments with NO employees
SELECT dept_name
FROM departments d
WHERE NOT EXISTS (
  SELECT 1 
  FROM employees e 
  WHERE e.dept_id = d.dept_id
);
```

**IN vs EXISTS — when to use which:**

```sql
-- Use IN when subquery returns small list
WHERE dept_id IN (10, 20, 30)

-- Use EXISTS when checking large related table
-- EXISTS stops at first match (faster)
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)
```

---

## Correlated Subquery

A correlated subquery **references the outer query** — runs once per row.

```sql
-- Find employees who earn more than their department average
SELECT name, salary, dept
FROM employees e1
WHERE salary > (
  SELECT AVG(salary)
  FROM employees e2
  WHERE e2.dept = e1.dept  -- references outer query's dept
);
```

For each employee (e1), the inner query calculates avg for **that employee's department**.

**Result:**
```
name   salary  dept
Priya  60000   Backend
Sneha  70000   Backend
```

Rahul (50000) < Frontend avg (52500) → excluded  
Priya (60000) > Backend avg (65000)? No wait — Priya IS included because she's above 60000? Let's be accurate:
- Frontend avg = (50000+55000)/2 = 52500 → Amit (55000) > 52500 ✅
- Backend avg = (60000+70000)/2 = 65000 → Sneha (70000) > 65000 ✅

```
name   salary  dept
Amit   55000   Frontend
Sneha  70000   Backend
```

---

# PART 3 — CTEs (Common Table Expressions)

## What is a CTE?

CTE = a **named temporary result** you define before the main query.

Think of it as: give your subquery a name, then use it like a table.

```sql
WITH dept_avg AS (
  SELECT dept, AVG(salary) as avg_salary
  FROM employees
  GROUP BY dept
)
SELECT e.name, e.salary, d.avg_salary
FROM employees e
INNER JOIN dept_avg d ON e.dept = d.dept
WHERE e.salary > d.avg_salary;
```

Same result as a correlated subquery — but **much more readable**.

---

## CTE vs Subquery — Same Result, Different Readability

**Subquery version (hard to read):**
```sql
SELECT e.name, e.salary
FROM employees e
INNER JOIN (
  SELECT dept, AVG(salary) as avg_salary
  FROM employees
  GROUP BY dept
) dept_avg ON e.dept = dept_avg.dept
WHERE e.salary > dept_avg.avg_salary;
```

**CTE version (easy to read):**
```sql
WITH dept_avg AS (
  SELECT dept, AVG(salary) as avg_salary
  FROM employees
  GROUP BY dept
)
SELECT e.name, e.salary
FROM employees e
INNER JOIN dept_avg ON e.dept = dept_avg.dept
WHERE e.salary > dept_avg.avg_salary;
```

Same performance. CTE wins on readability.

---

## Multiple CTEs — Chain Them

```sql
WITH 
-- Step 1: Department averages
dept_avg AS (
  SELECT dept, AVG(salary) as avg_salary
  FROM employees
  GROUP BY dept
),

-- Step 2: High performing departments
high_perf_depts AS (
  SELECT dept
  FROM dept_avg
  WHERE avg_salary > 55000
),

-- Step 3: Employees in those departments
top_employees AS (
  SELECT e.name, e.salary, e.dept
  FROM employees e
  INNER JOIN high_perf_depts h ON e.dept = h.dept
)

-- Final query
SELECT * FROM top_employees
ORDER BY salary DESC;
```

Each CTE builds on the previous one. Like steps in a recipe.

---

## Recursive CTE — For Hierarchical Data

Used for **org charts, category trees, file systems** — anything parent-child.

```sql
-- Employee hierarchy (manager → reports)
WITH RECURSIVE org_chart AS (
  -- Base case: top-level manager (no manager above)
  SELECT emp_id, name, manager_id, 1 as level
  FROM employees
  WHERE manager_id IS NULL

  UNION ALL

  -- Recursive case: find reports of current level
  SELECT e.emp_id, e.name, e.manager_id, oc.level + 1
  FROM employees e
  INNER JOIN org_chart oc ON e.manager_id = oc.emp_id
)
SELECT level, name FROM org_chart
ORDER BY level, name;
```

**Result:**
```
level  name
1      CEO
2      VP Engineering
2      VP Product
3      Rahul
3      Priya
3      Amit
```

**When to use recursive CTE:**
- Org charts
- Category trees (Electronics → Phones → Smartphones)
- File system paths
- Finding all ancestors/descendants

---

## Real-World CTE Examples

### E-commerce: Running Total

```sql
WITH daily_sales AS (
  SELECT 
    DATE(created_at) as sale_date,
    SUM(amount) as daily_total
  FROM orders
  GROUP BY DATE(created_at)
)
SELECT 
  sale_date,
  daily_total,
  SUM(daily_total) OVER (ORDER BY sale_date) as running_total
FROM daily_sales
ORDER BY sale_date;
```

### HR: Rank Employees by Salary in Department

```sql
WITH ranked_employees AS (
  SELECT 
    name,
    dept,
    salary,
    RANK() OVER (PARTITION BY dept ORDER BY salary DESC) as rank_in_dept
  FROM employees
)
SELECT * FROM ranked_employees
WHERE rank_in_dept <= 3;  -- Top 3 in each department
```

---

## Combining All Three — Real Interview Query

**Question: Find the top earning employee in each department, only for departments with more than 2 employees.**

```sql
-- Step 1: Count employees per department
WITH dept_count AS (
  SELECT dept, COUNT(*) as headcount
  FROM employees
  GROUP BY dept
),

-- Step 2: Keep only large departments
large_depts AS (
  SELECT dept
  FROM dept_count
  WHERE headcount > 2
),

-- Step 3: Rank employees by salary within those departments
ranked AS (
  SELECT 
    e.name,
    e.dept,
    e.salary,
    RANK() OVER (PARTITION BY e.dept ORDER BY e.salary DESC) as rnk
  FROM employees e
  INNER JOIN large_depts ld ON e.dept = ld.dept
)

-- Final: Top earner per department
SELECT name, dept, salary
FROM ranked
WHERE rnk = 1;
```

---

## Quick Decision — Which to Use?

```
Need to summarize data?
  → Aggregation (GROUP BY)

Need to filter on aggregated result?
  → HAVING

Need result of one query inside another?
  → Subquery (simple cases)

Subquery getting unreadable?
  → CTE (same result, cleaner)

Need to reuse same subquery multiple times?
  → CTE (write once, use many times)

Need to traverse hierarchy (parent-child)?
  → Recursive CTE

Checking if rows exist (large table)?
  → EXISTS (faster than IN)
```

---

## Common Mistakes

### Mistake 1: Using WHERE instead of HAVING

```sql
-- WRONG ❌
SELECT dept, COUNT(*) as headcount
FROM employees
WHERE COUNT(*) > 2
GROUP BY dept;
-- ERROR: aggregate in WHERE not allowed

-- RIGHT ✅
SELECT dept, COUNT(*) as headcount
FROM employees
GROUP BY dept
HAVING COUNT(*) > 2;
```

### Mistake 2: NOT IN with NULLs

```sql
-- WRONG ❌ — returns nothing if subquery has NULL
SELECT name FROM employees
WHERE dept_id NOT IN (SELECT dept_id FROM departments);
-- If any dept_id is NULL, result is empty!

-- RIGHT ✅
SELECT name FROM employees
WHERE dept_id NOT IN (
  SELECT dept_id FROM departments WHERE dept_id IS NOT NULL
);
```

### Mistake 3: Selecting non-grouped columns

```sql
-- WRONG ❌
SELECT name, dept, AVG(salary)
FROM employees
GROUP BY dept;
-- ERROR: name not in GROUP BY

-- RIGHT ✅
SELECT dept, AVG(salary)
FROM employees
GROUP BY dept;
```

### Mistake 4: CTE not available outside its query

```sql
-- WRONG ❌
WITH my_cte AS (SELECT * FROM employees)
SELECT * FROM orders;

SELECT * FROM my_cte;  -- ERROR: my_cte doesn't exist here

-- RIGHT ✅ — CTE only lives for one query
WITH my_cte AS (SELECT * FROM employees)
SELECT * FROM my_cte;  -- use it in the same query
```

---

## Practice Exercises

### Setup:

```sql
CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  name VARCHAR(50),
  dept VARCHAR(50),
  salary INT,
  manager_id INT
);

INSERT INTO employees VALUES
(1, 'Rahul',  'Frontend', 50000, 5),
(2, 'Priya',  'Backend',  60000, 6),
(3, 'Amit',   'Frontend', 55000, 5),
(4, 'Sneha',  'Backend',  70000, 6),
(5, 'Vikram', 'Frontend', 90000, NULL),
(6, 'Neha',   'Backend',  95000, NULL),
(7, 'Rohit',  'DevOps',   65000, NULL);
```

### Exercises:

**1. Aggregation — Department summary**
```
Show each department with: headcount, avg salary, max salary
Expected: 3 rows (Frontend, Backend, DevOps)
```

**2. HAVING — Filter groups**
```
Show departments where avg salary > 60000
Expected: Backend (65000), DevOps (65000)
```

**3. Subquery in WHERE — Above average earners**
```
Show employees earning more than company average
Expected: Priya, Sneha, Vikram, Neha, Rohit
```

**4. EXISTS — Departments with employees**
```
Using EXISTS, show departments that have at least one employee
```

**5. CTE — Top earner per department**
```
Using CTE + RANK(), find highest paid in each department
Expected: Vikram (Frontend), Sneha... wait, Neha (Backend), Rohit (DevOps)
```

**6. Multiple CTEs — Chain them**
```
Step 1: Find avg salary per dept
Step 2: Find depts above company avg
Step 3: List employees in those depts
```

---

## Summary Table

| Concept | Purpose | Key Clause |
|---|---|---|
| Aggregation | Summarize many rows → few | GROUP BY |
| HAVING | Filter after grouping | HAVING |
| Subquery in WHERE | Filter using another query's result | WHERE col IN (...) |
| Subquery in FROM | Use query result as table | FROM (...) alias |
| EXISTS | Check if related rows exist | WHERE EXISTS (...) |
| CTE | Name a subquery for readability | WITH name AS (...) |
| Recursive CTE | Traverse parent-child data | WITH RECURSIVE |

---

## Key Takeaways

1. **GROUP BY groups rows — aggregate functions summarize them**
2. **HAVING filters groups — WHERE filters rows**
3. **Subquery in WHERE — small lookups**
4. **Subquery in FROM — when you need a temp table**
5. **EXISTS is faster than IN for large related tables**
6. **NOT IN + NULL = empty result — always filter NULLs**
7. **CTE = named subquery — use when query gets complex**
8. **Multiple CTEs = build logic step by step**
9. **Recursive CTE = hierarchy/tree data**
10. **Real queries combine all three — practice that**

---

## What's Next?

- `04-window-functions.md` — RANK, ROW_NUMBER, LAG, LEAD
- Window functions extend aggregation — no GROUP BY needed
- Most asked topic in Staff/Senior interviews

**Don't skip practice. Write the queries — don't just read them.**

Good luck! 🚀