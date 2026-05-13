# Indexes — Making Your Queries Fast

**How to speed up database queries 10x, 100x, or even 1000x with simple commands.**

---

## The Problem Indexes Solve

Imagine a phone directory with 10 million people:

### Without Index (SLOW):

```
Looking for "Rahul Singh" phone number

Method: Read every single entry
Start: Check "Aaa, Aardvark" - not it
       Check "Aaa, Aaron" - not it
       Check "Aba, Alice" - not it
       ...read 5 million entries...
       Check "Rah, Rahul Singh" - FOUND!

Time taken: 5 seconds (read half the book)
```

### With Index (FAST):

```
Looking for "Rahul Singh" phone number

Method: Use alphabetical index at back of book
Look at index: R ──► page 1500
Turn to page 1500
Find "Rahul Singh" in seconds

Time taken: < 0.01 seconds
```

**That's what database indexes do.**

---

## What is an Index?

An **index is a sorted list with pointers to actual data**.

```
Without Index:
Table: employees
┌────────┬──────────┬────────┐
│ emp_id │ name     │ salary │
├────────┼──────────┼────────┤
│ 15     │ Rahul    │ 85000  │
│ 3      │ Priya    │ 92000  │
│ 21     │ Amit     │ 78000  │
│ 7      │ Sneha    │ 65000  │
└────────┴──────────┴────────┘
(Random order)

To find salary=85000: Check every row (slow)
```

With Index on salary:

```
Index: salary
┌────────┬─────────────────┐
│ salary │ pointer to row  │
├────────┼─────────────────┤
│ 65000  │ ─────► row 4    │
│ 78000  │ ─────► row 3    │
│ 85000  │ ─────► row 1    │
│ 92000  │ ─────► row 2    │
└────────┴─────────────────┘
(Sorted order)

To find salary=85000: Jump directly to it (fast)
```

---

## How Indexes Work Internally

Most databases use **B-Tree** (Balanced Tree) structure:

```
                    [Root Node]
                   /            \
            [50000-75000]    [75000-100000]
           /    |    \         /    |    \
         [40k] [60k] [70k]  [80k] [90k] [100k]
         │      │     │      │     │      │
         ↓      ↓     ↓      ↓     ↓      ↓
        rows   rows  rows   rows  rows   rows
```

**How it finds data:**
1. Start at root
2. Is 85000 here? No
3. Go to right branch (75000-100000)
4. Is 85000 here? No
5. Go to 80k-90k node
6. Found! Jump to row

**Time: O(log n)** — very fast even for millions of rows

---

## Creating Indexes

### Basic Syntax

```sql
CREATE INDEX index_name ON table_name(column_name);
```

### Example: Index on Salary

```sql
CREATE INDEX idx_salary ON employees(salary);
```

Now queries like this are FAST:

```sql
SELECT name FROM employees WHERE salary > 80000;
-- Uses index, instant result
```

---

## Types of Indexes

### 1. Single Column Index

Index on one column:

```sql
CREATE INDEX idx_email ON users(email);

-- Fast queries:
SELECT * FROM users WHERE email = 'rahul@example.com';
```

---

### 2. Composite (Multi-column) Index

Index on multiple columns:

```sql
CREATE INDEX idx_dept_salary ON employees(dept_id, salary);

-- Fast queries:
SELECT name FROM employees 
WHERE dept_id = 10 AND salary > 80000;

-- Fast queries:
SELECT name FROM employees 
WHERE dept_id = 10;

-- NOT fast (wrong order):
SELECT name FROM employees 
WHERE salary > 80000;  -- Index doesn't help here
```

**Order matters!** Put most-filtered columns first.

---

### 3. Unique Index

Ensures values are unique + speeds up searches:

```sql
CREATE UNIQUE INDEX idx_email ON users(email);

-- Now: No two users can have same email
-- Also: Finding by email is fast
```

---

### 4. Full-Text Index

For text searching (searching within text):

```sql
CREATE FULLTEXT INDEX idx_description ON products(description);

-- Fast text searches:
SELECT * FROM products 
WHERE MATCH(description) AGAINST('laptop' IN BOOLEAN MODE);
```

---

## When to Create Indexes

### Create Index When:

✅ Column is in WHERE clause
```sql
WHERE salary > 50000  ← Index on salary helps
WHERE name = 'Rahul'  ← Index on name helps
```

✅ Column is in JOIN condition
```sql
ON employees.dept_id = departments.dept_id  ← Index on both
```

✅ Column is in ORDER BY
```sql
ORDER BY salary DESC  ← Index on salary helps
```

✅ Column is in GROUP BY
```sql
GROUP BY dept_id  ← Index on dept_id helps
```

✅ Column is searched frequently
```sql
Multiple queries filtering by email  ← Index on email
```

---

### Don't Create Index When:

❌ Column has few unique values
```sql
-- Column: gender (only M, F)
CREATE INDEX idx_gender ON users(gender);
-- Won't help much, index overhead not worth it
```

❌ Column is NULL frequently
```sql
-- Column: optional_phone (mostly NULL)
CREATE INDEX idx_phone ON users(optional_phone);
-- Index doesn't help with NULL searches
```

❌ Table is small (< 1000 rows)
```sql
-- Table has 100 rows
CREATE INDEX idx_x ON small_table(x);
-- Reading 100 rows is already fast
-- Index overhead not worth it
```

❌ Column has very long text
```sql
-- Column: description (500+ characters)
CREATE FULL INDEX idx_desc ON products(description);
-- Index becomes huge, slows INSERT/UPDATE
-- Use full-text search instead
```

---

## Index Trade-offs

### Benefit: Fast SELECT

```sql
CREATE INDEX idx_salary ON employees(salary);

SELECT name FROM employees WHERE salary > 80000;
Before index: 0.5 seconds (scan 1M rows)
After index:  0.001 seconds (jump to matching rows)
```

**50x faster!**

---

### Cost: Slow INSERT/UPDATE/DELETE

```sql
INSERT INTO employees VALUES (10, 'John', 70000, 10);

Without index: Quick (just add row)
With 5 indexes: Slower (must update 5 indexes too)

INSERT time increases 5x
But queries 50x faster
Worth it? Usually YES.
```

---

## Finding Slow Queries

### Use EXPLAIN

```sql
EXPLAIN SELECT name FROM employees WHERE salary > 80000;
```

Result shows:
- rows scanned
- whether index is used
- performance estimate

Example output:

```
id | select_type | table     | type | possible_keys  | key         | rows
1  | SIMPLE      | employees | range| idx_salary     | idx_salary  | 245
```

"rows: 245" means only 245 rows scanned (good!)

Without index:

```
id | select_type | table     | type | possible_keys  | key    | rows
1  | SIMPLE      | employees | ALL  | NULL           | NULL   | 1000000
```

"rows: 1000000" means scanned entire table (bad!)

---

## Real Example: E-commerce Query

### Slow Query (No Index)

```sql
SELECT product_id, name, price 
FROM products 
WHERE category = 'Electronics' 
  AND price > 20000 
  AND available = 1;

EXPLAIN: rows = 500000 (scanned entire table!)
Time: 2 seconds
```

### Add Index

```sql
CREATE INDEX idx_cat_price_avail 
ON products(category, price, available);
```

### Same Query (With Index)

```sql
SELECT product_id, name, price 
FROM products 
WHERE category = 'Electronics' 
  AND price > 20000 
  AND available = 1;

EXPLAIN: rows = 2500 (jumped to relevant rows!)
Time: 0.05 seconds
```

**40x faster!**

---

## Common Index Mistakes

### Mistake 1: Indexing Everything

```sql
-- ❌ BAD
CREATE INDEX idx_id ON table(id);           -- Already primary key!
CREATE INDEX idx_name ON table(name);
CREATE INDEX idx_email ON table(email);
CREATE INDEX idx_phone ON table(phone);
CREATE INDEX idx_address ON table(address);
CREATE INDEX idx_city ON table(city);
CREATE INDEX idx_country ON table(country);

Problems:
- 7 indexes to maintain
- INSERT/UPDATE/DELETE slow
- Storage bloated
- Most indexes rarely used
```

✅ GOOD:

```sql
-- Create only indexes for frequently searched columns
CREATE INDEX idx_email ON table(email);        -- Users search by email
CREATE INDEX idx_category ON table(category);  -- Products filtered by category
```

---

### Mistake 2: Wrong Column Order

```sql
-- ❌ BAD (Wrong order)
CREATE INDEX idx_salary_dept ON employees(salary, dept_id);

-- This helps:
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 10;

-- This does NOT help:
SELECT * FROM employees WHERE dept_id = 10;  -- Index not used!
```

✅ GOOD (Correct order):

```sql
-- Filter columns first, then range columns
CREATE INDEX idx_dept_salary ON employees(dept_id, salary);

-- Both these queries use index:
SELECT * FROM employees WHERE dept_id = 10 AND salary > 50000;
SELECT * FROM employees WHERE dept_id = 10;
```

---

### Mistake 3: Index on Calculated Column

```sql
-- ❌ BAD (Index not used)
CREATE INDEX idx_half_salary ON employees(salary / 2);

SELECT * FROM employees WHERE salary / 2 > 25000;
-- Index not used because of calculation

-- ✅ GOOD
CREATE INDEX idx_salary ON employees(salary);

SELECT * FROM employees WHERE salary > 50000;
-- Index used!
```

---

### Mistake 4: Too Many Composite Indexes

```sql
-- ❌ BAD
CREATE INDEX idx_a_b ON table(a, b);
CREATE INDEX idx_a_b_c ON table(a, b, c);
CREATE INDEX idx_a_b_c_d ON table(a, b, c, d);

Problems:
- Redundant (first index covered by second)
- Too many to maintain
- Confusing which to use
```

✅ GOOD:

```sql
-- One comprehensive index covers all cases
CREATE INDEX idx_a_b_c_d ON table(a, b, c, d);

-- This uses the index:
SELECT * FROM table WHERE a = 1 AND b = 2 AND c = 3 AND d = 4;

-- These also use it:
SELECT * FROM table WHERE a = 1 AND b = 2;
SELECT * FROM table WHERE a = 1;
```

---

## Dropping Indexes

Remove unused or slow indexes:

```sql
-- See all indexes
SHOW INDEXES FROM employees;

-- Drop index
DROP INDEX idx_salary ON employees;

-- Or
DROP INDEX idx_salary;
```

---

## Index Maintenance

### Check Index Effectiveness

```sql
-- See which indexes are used
SELECT * FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE OBJECT_SCHEMA = 'your_database'
ORDER BY COUNT_READ DESC;

-- Drop unused indexes
-- Rebuild fragmented indexes
```

### Rebuild Index (Periodically)

```sql
-- Optimize table (rebuilds indexes)
OPTIMIZE TABLE employees;

-- Or manually
ANALYZE TABLE employees;
```

---

## Index Strategies for Common Scenarios

### Scenario 1: User Authentication

```sql
CREATE UNIQUE INDEX idx_email ON users(email);
CREATE UNIQUE INDEX idx_username ON users(username);

-- Fast lookups:
SELECT * FROM users WHERE email = 'rahul@example.com';
SELECT * FROM users WHERE username = 'rahul123';
```

---

### Scenario 2: Product Search

```sql
CREATE INDEX idx_category ON products(category);
CREATE INDEX idx_category_price ON products(category, price);
CREATE INDEX idx_name ON products(name);  -- For LIKE searches

-- Fast queries:
SELECT * FROM products WHERE category = 'Electronics';
SELECT * FROM products WHERE category = 'Electronics' AND price > 50000;
SELECT * FROM products WHERE name LIKE 'iPad%';
```

---

### Scenario 3: Order History

```sql
CREATE INDEX idx_customer_date ON orders(customer_id, order_date DESC);

-- Fast queries:
SELECT * FROM orders 
WHERE customer_id = 123 
ORDER BY order_date DESC;
```

---

### Scenario 4: Time-Series Data

```sql
CREATE INDEX idx_date ON logs(log_date DESC);

-- Fast queries:
SELECT * FROM logs WHERE log_date > '2024-01-01';
SELECT * FROM logs WHERE log_date BETWEEN '2024-01-01' AND '2024-01-31';
```

---

## Practice Exercises

### Exercise 1: Identify Slow Query

```sql
SELECT name, salary FROM employees 
WHERE dept_id = 10 AND salary > 80000;

Current: 0.8 seconds (1M rows)

Question: What index would help?
Answer: CREATE INDEX idx_dept_salary ON employees(dept_id, salary);
```

### Exercise 2: Fix With Index

```sql
Original query:
SELECT email FROM users WHERE email = 'test@example.com';
Time: 0.5 seconds (10M users)

Task: Create index and verify it's used

Solution:
CREATE UNIQUE INDEX idx_email ON users(email);
EXPLAIN SELECT email FROM users WHERE email = 'test@example.com';
-- Should show "possible_keys: idx_email"
```

### Exercise 3: Composite Index

```sql
Query:
SELECT * FROM products 
WHERE category = 'Electronics' 
  AND price > 20000 
  AND in_stock = 1;

Current time: 1.5 seconds

Task: Create index to speed up

Solution:
CREATE INDEX idx_cat_price_stock 
ON products(category, price, in_stock);
```

### Exercise 4: When NOT to Index

```sql
Table: small_reference (300 rows)
Column: gender (only M, F, O — 3 unique values)

Question: Should you index gender?
Answer: NO. Too few unique values, table too small. 
        Overhead outweighs benefit.
```

### Exercise 5: ORDER BY Optimization

```sql
Query:
SELECT name, salary FROM employees 
WHERE dept_id = 10 
ORDER BY salary DESC;

Current: 0.3 seconds

Task: Optimize

Solution:
CREATE INDEX idx_dept_salary_desc 
ON employees(dept_id, salary DESC);
-- Now ORDER BY uses index too
```

### Exercise 6: LEFT LIKE Search

```sql
Query:
SELECT * FROM products WHERE name LIKE 'iPad%';

Current: 0.6 seconds

Hint: Index column used in LIKE

Solution:
CREATE INDEX idx_product_name ON products(name);
-- For LIKE with wildcard at end, index helps
```

### Exercise 7: Analyze Query

```sql
Query:
SELECT COUNT(*) FROM orders 
WHERE order_date > '2024-01-01' 
  AND status = 'completed';

Task: EXPLAIN the query, identify bottleneck

Solution:
EXPLAIN SELECT...
-- Check if rows scanned is reasonable
-- If not, create: CREATE INDEX idx_date_status 
-- ON orders(order_date, status);
```

### Exercise 8: Index Strategy Design

```
Table: transactions (100M rows)
Columns: user_id, amount, transaction_date, status

Queries:
1. Find transactions by user: WHERE user_id = X
2. Find transactions by date: WHERE transaction_date > X
3. Find completed transactions by user: WHERE user_id = X AND status = 'completed'

Question: What indexes would you create?

Solution:
CREATE INDEX idx_user_id ON transactions(user_id);
CREATE INDEX idx_date ON transactions(transaction_date);
CREATE INDEX idx_user_status ON transactions(user_id, status);
```

---

## Summary Table

| Scenario | Index Type | Benefit | Cost |
|----------|-----------|---------|------|
| WHERE column = value | Single | Very Fast | Low |
| WHERE col1 = val AND col2 > val | Composite | Very Fast | Medium |
| ORDER BY column | Single | Fast | Low |
| Large table, frequent search | Single | 100x faster | Medium |
| Small table (< 1000 rows) | Any | Minimal | Not worth |
| Few unique values | Any | Minimal | Not worth |

---

## Golden Rules for Indexes

```
1. Index columns in WHERE clause
2. Index columns in JOIN conditions
3. Index columns in ORDER BY
4. Composite indexes: filter columns first
5. Don't index every column
6. Don't index low-cardinality columns
7. Primary key already indexed
8. Foreign keys should be indexed
9. Check EXPLAIN before and after
10. Drop unused indexes
```

---

## Key Takeaways

- Indexes make **SELECT queries 10-1000x faster**
- Indexes cost: **INSERT/UPDATE/DELETE slightly slower**
- Usually worth it: **Fast reads > slow writes**
- Use EXPLAIN to verify index usage
- Don't over-index: **Only index where needed**
- Composite indexes: **Order matters!**

---

## What's Next?

After understanding indexes:
- Move to 09-optimization.md (query tuning)
- Then practice with real databases
- Use EXPLAIN on your own queries

Practice now with these 8 exercises. Don't just read — **actually create indexes and test them.**

Good luck! 🚀