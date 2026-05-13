# Window Functions — Aggregation Without Losing Rows

**Most asked topic in Staff/Senior SQL interviews. Learn this well.**

---

## Why Window Functions?

With GROUP BY, you summarize — but you **lose individual rows**.

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

Rahul, Priya, Amit, Sneha — **gone**. Only summary remains.

**Window functions give you aggregation AND keep every row:**

```sql
SELECT 
  name,
  dept,
  salary,
  AVG(salary) OVER (PARTITION BY dept) as dept_avg
FROM employees;
```

**Result:**
```
name   dept       salary  dept_avg
Rahul  Frontend   50000   52500
Amit   Frontend   55000   52500
Priya  Backend    60000   65000
Sneha  Backend    70000   65000
```

Every row stays. Each row also shows its department average.

That's the power of window functions.

---

## The Core Syntax

```sql
function_name() OVER (
  PARTITION BY column   -- optional: divide into groups
  ORDER BY column       -- optional: define row order
  ROWS/RANGE BETWEEN ... -- optional: define window frame
)
```

- **OVER()** — makes it a window function
- **PARTITION BY** — like GROUP BY but rows are kept
- **ORDER BY** — defines order within each partition
- **ROWS/RANGE** — defines how many rows to include (advanced)

---

## PARTITION BY — Divide Into Groups

```sql
-- Without PARTITION BY: one window = entire table
SELECT name, salary, AVG(salary) OVER () as company_avg
FROM employees;

-- With PARTITION BY: one window per department
SELECT name, dept, salary,
  AVG(salary) OVER (PARTITION BY dept) as dept_avg
FROM employees;
```

**Result:**
```
name   dept       salary  dept_avg
Rahul  Frontend   50000   52500     ← Frontend avg
Amit   Frontend   55000   52500     ← Frontend avg
Priya  Backend    60000   65000     ← Backend avg
Sneha  Backend    70000   65000     ← Backend avg
```

Think of PARTITION BY as: "calculate separately for each group, but show all rows."

---

# PART 1 — Ranking Functions

## ROW_NUMBER() — Unique Sequential Number

Assigns a unique number to each row. No ties — always unique.

```sql
SELECT 
  name, dept, salary,
  ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) as row_num
FROM employees;
```

**Result:**
```
name   dept       salary  row_num
Sneha  Backend    70000   1
Priya  Backend    60000   2
Amit   Frontend   55000   1
Rahul  Frontend   50000   2
```

Even if two rows have same salary — they get different numbers. 1, 2, 3... always.

**Use case: Get exactly the Nth row per group**

```sql
-- Get TOP 1 earner per department
WITH ranked AS (
  SELECT name, dept, salary,
    ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) as rn
  FROM employees
)
SELECT name, dept, salary
FROM ranked
WHERE rn = 1;
```

---

## RANK() — Ranking With Gaps

Assigns rank. **Ties get same rank. Next rank skips.**

```sql
SELECT 
  name, dept, salary,
  RANK() OVER (PARTITION BY dept ORDER BY salary DESC) as rnk
FROM employees;
```

If two employees have same salary:
```
name    salary  rank
Sneha   70000   1
Priya   60000   2    ← tied
Amit    60000   2    ← tied (same rank)
Rahul   50000   4    ← skips 3
```

Rank 3 is skipped. That's the gap.

**Use case: Find all employees tied for top position**

```sql
WITH ranked AS (
  SELECT name, salary,
    RANK() OVER (ORDER BY salary DESC) as rnk
  FROM employees
)
SELECT name, salary FROM ranked WHERE rnk = 1;
-- Returns all employees with highest salary
```

---

## DENSE_RANK() — Ranking Without Gaps

Same as RANK() but **no gaps**.

```sql
SELECT 
  name, salary,
  RANK()       OVER (ORDER BY salary DESC) as rank_with_gap,
  DENSE_RANK() OVER (ORDER BY salary DESC) as rank_no_gap
FROM employees;
```

**Result:**
```
name    salary  rank_with_gap  rank_no_gap
Sneha   70000   1              1
Priya   60000   2              2
Amit    60000   2              2
Rahul   50000   4              3    ← no gap here
```

**ROW_NUMBER vs RANK vs DENSE_RANK:**

```
Salaries: 70000, 60000, 60000, 50000

ROW_NUMBER:  1, 2, 3, 4   ← always unique
RANK:        1, 2, 2, 4   ← gap after tie
DENSE_RANK:  1, 2, 2, 3   ← no gap after tie
```

**Which to use:**
- Need unique row per group → `ROW_NUMBER`
- Want to show actual rank with gaps → `RANK`
- Want rank without gaps (leaderboard) → `DENSE_RANK`

---

## NTILE(n) — Divide Into Buckets

Splits rows into n equal buckets.

```sql
-- Divide employees into salary quartiles
SELECT 
  name, salary,
  NTILE(4) OVER (ORDER BY salary) as quartile
FROM employees;
```

**Result:**
```
name   salary  quartile
Rahul  50000   1    ← bottom 25%
Amit   55000   2
Priya  60000   3
Sneha  70000   4    ← top 25%
```

**Use case: Performance buckets, percentile grouping**

```sql
-- Top 25% earners (quartile 4)
WITH buckets AS (
  SELECT name, salary,
    NTILE(4) OVER (ORDER BY salary) as quartile
  FROM employees
)
SELECT name, salary FROM buckets WHERE quartile = 4;
```

---

# PART 2 — Aggregate Window Functions

All standard aggregates work as window functions with OVER().

```sql
SELECT 
  name, dept, salary,
  SUM(salary)   OVER (PARTITION BY dept) as dept_total,
  AVG(salary)   OVER (PARTITION BY dept) as dept_avg,
  COUNT(*)      OVER (PARTITION BY dept) as dept_headcount,
  MAX(salary)   OVER (PARTITION BY dept) as dept_max,
  MIN(salary)   OVER (PARTITION BY dept) as dept_min
FROM employees;
```

**Result:**
```
name   dept      salary  dept_total  dept_avg  headcount  dept_max  dept_min
Rahul  Frontend  50000   105000      52500     2          55000     50000
Amit   Frontend  55000   105000      52500     2          55000     50000
Priya  Backend   60000   130000      65000     2          70000     60000
Sneha  Backend   70000   130000      65000     2          70000     60000
```

**Use case: Show each employee vs department stats in one row**

---

## Running Total — SUM with ORDER BY

Adding ORDER BY to SUM creates a **cumulative/running total**.

```sql
SELECT 
  name, salary,
  SUM(salary) OVER (ORDER BY salary) as running_total
FROM employees
ORDER BY salary;
```

**Result:**
```
name   salary  running_total
Rahul  50000   50000
Amit   55000   105000
Priya  60000   165000
Sneha  70000   235000
```

Each row shows sum of all rows up to and including current row.

**Running total per department:**

```sql
SELECT 
  name, dept, salary,
  SUM(salary) OVER (
    PARTITION BY dept 
    ORDER BY salary
  ) as running_total_in_dept
FROM employees;
```

---

# PART 3 — LAG and LEAD

## LAG() — Look at Previous Row

```sql
LAG(column, offset, default) OVER (ORDER BY column)
```

- **offset** = how many rows back (default: 1)
- **default** = value if no previous row exists

```sql
-- Compare each employee's salary to previous (by salary order)
SELECT 
  name, salary,
  LAG(salary) OVER (ORDER BY salary) as prev_salary,
  salary - LAG(salary) OVER (ORDER BY salary) as salary_jump
FROM employees
ORDER BY salary;
```

**Result:**
```
name   salary  prev_salary  salary_jump
Rahul  50000   NULL         NULL
Amit   55000   50000        5000
Priya  60000   55000        5000
Sneha  70000   60000        10000
```

**Real use case: Month-over-month comparison**

```sql
SELECT 
  month,
  revenue,
  LAG(revenue) OVER (ORDER BY month) as prev_month_revenue,
  revenue - LAG(revenue) OVER (ORDER BY month) as growth,
  ROUND(
    100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) 
    / LAG(revenue) OVER (ORDER BY month), 
    2
  ) as growth_pct
FROM monthly_sales
ORDER BY month;
```

**Result:**
```
month    revenue  prev_revenue  growth   growth_pct
Jan      100000   NULL          NULL     NULL
Feb      120000   100000        20000    20.00%
Mar      115000   120000        -5000    -4.17%
Apr      140000   115000        25000    21.74%
```

---

## LEAD() — Look at Next Row

```sql
LEAD(column, offset, default) OVER (ORDER BY column)
```

Same as LAG but looks **forward** instead of backward.

```sql
-- Show each employee's salary and next higher salary
SELECT 
  name, salary,
  LEAD(salary) OVER (ORDER BY salary) as next_salary,
  LEAD(salary) OVER (ORDER BY salary) - salary as gap_to_next
FROM employees
ORDER BY salary;
```

**Result:**
```
name   salary  next_salary  gap_to_next
Rahul  50000   55000        5000
Amit   55000   60000        5000
Priya  60000   70000        10000
Sneha  70000   NULL         NULL
```

**Real use case: Find sessions/gaps in time-series data**

```sql
-- Find gaps between user sessions > 30 minutes
SELECT 
  user_id,
  session_start,
  LEAD(session_start) OVER (PARTITION BY user_id ORDER BY session_start) as next_session,
  DATEDIFF(
    LEAD(session_start) OVER (PARTITION BY user_id ORDER BY session_start),
    session_start
  ) as gap_minutes
FROM user_sessions;
```

---

# PART 4 — FIRST_VALUE and LAST_VALUE

## FIRST_VALUE() — First Row in Window

```sql
-- Show each employee with the lowest earner in their dept
SELECT 
  name, dept, salary,
  FIRST_VALUE(name) OVER (
    PARTITION BY dept 
    ORDER BY salary
  ) as lowest_earner_in_dept
FROM employees;
```

**Result:**
```
name   dept       salary  lowest_earner_in_dept
Rahul  Frontend   50000   Rahul
Amit   Frontend   55000   Rahul
Priya  Backend    60000   Priya
Sneha  Backend    70000   Priya
```

## LAST_VALUE() — Last Row in Window

⚠️ LAST_VALUE needs a frame clause — otherwise it only sees current row.

```sql
-- WRONG ❌ — returns current row, not last
SELECT name, LAST_VALUE(name) OVER (PARTITION BY dept ORDER BY salary)
FROM employees;

-- RIGHT ✅ — explicit frame
SELECT 
  name, dept, salary,
  LAST_VALUE(name) OVER (
    PARTITION BY dept 
    ORDER BY salary
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  ) as highest_earner_in_dept
FROM employees;
```

---

# PART 5 — Window Frames

Window frame defines **which rows are included** in the calculation.

```sql
ROWS BETWEEN start AND end
```

**Frame boundaries:**
```
UNBOUNDED PRECEDING    -- from very first row of partition
N PRECEDING            -- N rows before current row
CURRENT ROW            -- current row only
N FOLLOWING            -- N rows after current row
UNBOUNDED FOLLOWING    -- to very last row of partition
```

**Common frames:**

```sql
-- All rows in partition (full aggregate)
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

-- Running total (from start to current row)
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- 3-row moving average (previous, current, next)
ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING

-- Last 3 rows including current (rolling window)
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
```

**Moving average example:**

```sql
-- 3-day moving average of sales
SELECT 
  sale_date,
  daily_sales,
  AVG(daily_sales) OVER (
    ORDER BY sale_date
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) as moving_avg_3day
FROM daily_sales;
```

**Result:**
```
date        sales   moving_avg_3day
2024-01-01  1000    1000.00   ← only 1 row
2024-01-02  1200    1100.00   ← avg of 2 rows
2024-01-03  800     1000.00   ← avg of 3 rows
2024-01-04  1500    1166.67   ← avg of rows 2,3,4
2024-01-05  900     1066.67   ← avg of rows 3,4,5
```

---

## Real-World Interview Queries

### Interview Q1: Top N per group

**"Find top 3 highest paid employees in each department"**

```sql
WITH ranked AS (
  SELECT 
    name, dept, salary,
    ROW_NUMBER() OVER (
      PARTITION BY dept 
      ORDER BY salary DESC
    ) as rn
  FROM employees
)
SELECT name, dept, salary
FROM ranked
WHERE rn <= 3;
```

### Interview Q2: Percentage of total

**"Show each employee's salary as % of their department total"**

```sql
SELECT 
  name, dept, salary,
  ROUND(
    100.0 * salary / SUM(salary) OVER (PARTITION BY dept), 
    2
  ) as pct_of_dept_total
FROM employees;
```

**Result:**
```
name   dept       salary  pct_of_dept_total
Rahul  Frontend   50000   47.62%
Amit   Frontend   55000   52.38%
Priya  Backend    60000   46.15%
Sneha  Backend    70000   53.85%
```

### Interview Q3: Month-over-month growth

**"Calculate revenue growth % vs previous month"**

```sql
WITH monthly AS (
  SELECT 
    DATE_FORMAT(order_date, '%Y-%m') as month,
    SUM(amount) as revenue
  FROM orders
  GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
with_prev AS (
  SELECT 
    month, revenue,
    LAG(revenue) OVER (ORDER BY month) as prev_revenue
  FROM monthly
)
SELECT 
  month,
  revenue,
  prev_revenue,
  ROUND(100.0 * (revenue - prev_revenue) / prev_revenue, 2) as growth_pct
FROM with_prev;
```

### Interview Q4: Running rank with dense rank

**"Rank all employees by salary, show ties properly"**

```sql
SELECT 
  name, salary,
  DENSE_RANK() OVER (ORDER BY salary DESC) as salary_rank
FROM employees
ORDER BY salary_rank;
```

### Interview Q5: Find gaps in sequence

**"Find missing order IDs in a sequence"**

```sql
WITH ordered AS (
  SELECT 
    order_id,
    LEAD(order_id) OVER (ORDER BY order_id) as next_order_id
  FROM orders
)
SELECT 
  order_id as gap_starts_after,
  next_order_id as gap_ends_before,
  next_order_id - order_id - 1 as missing_count
FROM ordered
WHERE next_order_id - order_id > 1;
```

---

## Window Function vs GROUP BY — Choose Correctly

```sql
-- GROUP BY: Summary only, rows collapsed
SELECT dept, AVG(salary)
FROM employees
GROUP BY dept;
-- 2 rows returned (one per dept)

-- Window: Summary + detail, rows kept
SELECT name, dept, salary, AVG(salary) OVER (PARTITION BY dept)
FROM employees;
-- 4 rows returned (all employees)

-- Use GROUP BY when: you only need summary
-- Use Window when: you need summary AND row-level detail
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
  join_date DATE
);

INSERT INTO employees VALUES
(1, 'Rahul',  'Frontend', 50000, '2020-01-15'),
(2, 'Priya',  'Backend',  60000, '2019-03-10'),
(3, 'Amit',   'Frontend', 55000, '2021-06-01'),
(4, 'Sneha',  'Backend',  70000, '2018-11-20'),
(5, 'Vikram', 'Frontend', 90000, '2017-07-05'),
(6, 'Neha',   'Backend',  95000, '2016-02-28'),
(7, 'Rohit',  'DevOps',   65000, '2020-09-14');

CREATE TABLE monthly_sales (
  month VARCHAR(7),
  revenue INT
);

INSERT INTO monthly_sales VALUES
('2024-01', 100000),
('2024-02', 120000),
('2024-03', 115000),
('2024-04', 140000),
('2024-05', 135000),
('2024-06', 160000);
```

### Exercises:

**1. ROW_NUMBER — Top earner per department**
```
Find the #1 highest paid employee in each department
Expected: Vikram (Frontend), Neha (Backend), Rohit (DevOps)
```

**2. RANK vs DENSE_RANK — Tie handling**
```
Add a second employee with same salary as Priya (60000)
Show RANK and DENSE_RANK differences
```

**3. Running total — Cumulative salary**
```
Order employees by join_date
Show cumulative salary cost as each employee was hired
```

**4. LAG — Month-over-month growth**
```
Using monthly_sales table
Show each month's revenue and growth % vs previous month
```

**5. Salary vs department**
```
Show each employee with:
- Their salary
- Their department average
- Difference from department average
- Their rank within department
```

**6. NTILE — Performance buckets**
```
Divide all employees into 3 performance buckets by salary
Label them: 'Low', 'Mid', 'High'
```

---

## Summary Table

| Function | Purpose | Handles Ties |
|---|---|---|
| ROW_NUMBER() | Unique sequential number | No (always unique) |
| RANK() | Rank with gaps on ties | Yes (gaps) |
| DENSE_RANK() | Rank without gaps on ties | Yes (no gaps) |
| NTILE(n) | Divide into n buckets | — |
| SUM() OVER | Running/partition total | — |
| AVG() OVER | Running/partition average | — |
| LAG() | Access previous row value | — |
| LEAD() | Access next row value | — |
| FIRST_VALUE() | First row in window | — |
| LAST_VALUE() | Last row in window | — |

---

## Key Takeaways

1. **Window functions keep all rows — GROUP BY collapses them**
2. **OVER() makes any function a window function**
3. **PARTITION BY = GROUP BY but rows are kept**
4. **ORDER BY inside OVER = defines row order within window**
5. **ROW_NUMBER = always unique, RANK = gaps, DENSE_RANK = no gaps**
6. **LAG = previous row, LEAD = next row**
7. **Running total = SUM() with ORDER BY inside OVER()**
8. **LAST_VALUE needs ROWS BETWEEN frame — gotcha!**
9. **Top N per group = ROW_NUMBER + CTE + WHERE rn <= N**
10. **Most interview questions combine: CTE + Window + Filter**

---

## What's Next?

- `05-insert-update-delete.md` — writing data, not just reading
- `06-transactions-and-locking.md` — data safety and concurrency
- `07-indexing-and-optimization.md` — make queries fast

**Practice tip: The top 3 interview patterns are:**
1. Top N per group (ROW_NUMBER)
2. Month-over-month growth (LAG)
3. Running totals (SUM OVER ORDER BY)

**Write these from memory. These will come up.**

Good luck! 🚀