# SQL Interview Questions

## How to Use This File

**1 week before interview:** Read all questions once
**1 day before interview:** Read answers carefully
**Morning of interview:** Skim Golden Answers section

Each question has:
- Question (what they ask)
- What they really want to know
- Answer (how to respond)
- Red flag (what NOT to say)

---

# SECTION 1: Core SQL
## (They still ask these — answer confidently)

---

### Q1. Difference between INNER JOIN, LEFT JOIN, RIGHT JOIN?

**What they want:** Do you really understand, or just memorize?

**Answer:**
```
INNER JOIN: Returns only matching rows from both tables.
Use when: You need data that exists in both tables.

LEFT JOIN: Returns all rows from left table, NULL for unmatched right.
Use when: You want all records from main table, optionally related data.

RIGHT JOIN: Returns all rows from right table, NULL for unmatched left.
Rarely used — usually rewrite as LEFT JOIN by swapping tables.

FULL OUTER JOIN: All rows from both, NULL where no match.
Use when: Audit — find mismatches between two datasets.
```

**Real example to give:**
```
In our employee management system, I used LEFT JOIN to show 
all employees even if they hadn't been assigned to a project yet.
INNER JOIN would have excluded them.
```

**Red flag:** Just saying "LEFT shows all from left table" without why.

---

### Q2. What is a self join? When did you use it?

**What they want:** Have you seen real hierarchical data problems?

**Answer:**
```
Self join is joining a table with itself.
Used for hierarchical data — like org charts.

Example:
employees table has:
- emp_id
- name
- manager_id (references emp_id of same table)

Query: Find each employee with their manager name:

SELECT 
  e.name as employee,
  m.name as manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

LEFT JOIN because CEO has no manager (NULL).
```

**Red flag:** Never having used it, no real example.

---

### Q3. Difference between WHERE and HAVING?

**What they want:** Do you understand execution order?

**Answer:**
```
WHERE: Filters rows BEFORE grouping
HAVING: Filters groups AFTER GROUP BY

Example:
SELECT dept_id, AVG(salary) as avg_sal
FROM employees
WHERE status = 'active'        -- Filter rows first
GROUP BY dept_id
HAVING AVG(salary) > 80000;   -- Then filter groups

WHERE can't use aggregate functions (COUNT, SUM, AVG).
HAVING can.

Wrong:
WHERE AVG(salary) > 80000  -- Error!

Right:
HAVING AVG(salary) > 80000 -- Correct
```

**Red flag:** Saying they're the same or confusing which comes first.

---

### Q4. What is the difference between DELETE, TRUNCATE, DROP?

**What they want:** Do you know the risks and can't-undo scenarios?

**Answer:**
```
DELETE:
- Removes specific rows
- Has WHERE clause
- Can be rolled back (in transaction)
- Slow on large tables (logs each row)
DELETE FROM employees WHERE dept_id = 10;

TRUNCATE:
- Removes ALL rows
- No WHERE clause
- Cannot be rolled back (in most databases)
- Very fast (doesn't log each row)
TRUNCATE TABLE temp_logs;

DROP:
- Removes entire table structure
- All data, indexes, constraints gone
- Cannot be rolled back
DROP TABLE old_archive;

Rule I follow:
DELETE = surgical removal (use with WHERE)
TRUNCATE = empty table fast (staging/temp tables)
DROP = remove table completely (rare, very careful)
```

**Red flag:** Not knowing TRUNCATE can't be rolled back.

---

### Q5. What are indexes? How do you decide which columns to index?

**What they want:** Practical judgment, not just theory.

**Answer:**
```
Index is a sorted data structure that speeds up data retrieval.
Think of book index — jump to page directly vs reading every page.

My decision criteria for indexing:

Index when:
1. Column is in WHERE clause frequently
2. Column is in JOIN condition (foreign keys always)
3. Column is in ORDER BY on large tables
4. Column has high cardinality (many unique values)

Don't index when:
1. Small table (< 10,000 rows)
2. Low cardinality (gender: M/F — only 2 values)
3. Columns rarely used in queries
4. Table has heavy INSERT/UPDATE (index slows writes)

In our Oracle project, we had a performance issue where 
a customer search was taking 8 seconds.
Added composite index on (customer_name, status).
Query dropped to 200ms.
```

**Red flag:** "Index everything" or not knowing about write overhead.

---

### Q6. What is a composite index? What is column order importance?

**What they want:** Do you understand how composite indexes actually work?

**Answer:**
```
Composite index is index on multiple columns.

CREATE INDEX idx_dept_salary ON employees(dept_id, salary);

Column order MATTERS:
Index works from LEFT to RIGHT.

This index helps:
WHERE dept_id = 10                        -- Uses index
WHERE dept_id = 10 AND salary > 80000     -- Uses index fully

This does NOT use the index:
WHERE salary > 80000                      -- Skips first column (dept_id)

Rule: Put most selective / most filtered column first.
If you filter by dept_id in 90% of queries, it goes first.
```

**Red flag:** Not knowing column order matters.

---

# SECTION 2: Advanced SQL
## (This separates juniors from seniors)

---

### Q7. What are window functions? Give a real use case.

**What they want:** Senior-level SQL knowledge.

**Answer:**
```
Window functions perform calculations across a set of rows 
related to current row, WITHOUT collapsing them like GROUP BY.

Syntax:
function() OVER (PARTITION BY col ORDER BY col)

Common ones:
- ROW_NUMBER() — unique number per row
- RANK() — rank with gaps for ties
- DENSE_RANK() — rank without gaps
- LAG() — access previous row value
- LEAD() — access next row value
- SUM() OVER — running total

Real use case I had:
Needed top 3 employees per department by salary.

SELECT * FROM (
  SELECT 
    name,
    salary,
    dept_id,
    ROW_NUMBER() OVER (
      PARTITION BY dept_id 
      ORDER BY salary DESC
    ) as rank_in_dept
  FROM employees
) ranked
WHERE rank_in_dept <= 3;

Without window functions, this requires complex subqueries.
With window functions, clean and efficient.
```

**Red flag:** Never used them, only know GROUP BY.

---

### Q8. What is a CTE? When would you use it over a subquery?

**What they want:** Do you write maintainable SQL?

**Answer:**
```
CTE = Common Table Expression.
Named temporary result set within a query.

WITH dept_avg AS (
  SELECT dept_id, AVG(salary) as avg_salary
  FROM employees
  GROUP BY dept_id
)
SELECT e.name, e.salary, da.avg_salary
FROM employees e
JOIN dept_avg da ON e.dept_id = da.dept_id
WHERE e.salary > da.avg_salary;

When CTE over subquery:

1. Readability — CTE is named, purpose is clear
2. Reuse — CTE can be referenced multiple times in same query
3. Recursive queries — CTE supports recursion (subquery doesn't)
4. Debugging — Easier to isolate and test each CTE

In production I prefer CTE because:
- Other developers can read it
- Easier to maintain
- Database optimizes it as efficiently as subquery
```

**Red flag:** Not knowing CTEs exist, or always using subqueries.

---

### Q9. What is query execution order in SQL?

**What they want:** Deep understanding of how SQL actually runs.

**Answer:**
```
Most people think SQL runs in the order they write it.
It doesn't.

Actual execution order:

1. FROM — identify tables
2. JOIN — combine tables
3. WHERE — filter rows
4. GROUP BY — group rows
5. HAVING — filter groups
6. SELECT — choose columns
7. DISTINCT — remove duplicates
8. ORDER BY — sort
9. LIMIT — restrict rows

Why this matters:

You can't use SELECT alias in WHERE:
SELECT salary * 12 as annual FROM employees
WHERE annual > 1000000;  -- Error! SELECT runs after WHERE

Correct:
SELECT salary * 12 as annual FROM employees
WHERE salary * 12 > 1000000;  -- Must repeat expression

You can use SELECT alias in ORDER BY:
SELECT salary * 12 as annual FROM employees
ORDER BY annual DESC;  -- Works! ORDER BY runs after SELECT
```

**Red flag:** Not knowing WHERE runs before SELECT.

---

### Q10. How do you find and fix an N+1 query problem?

**What they want:** Have you debugged real application performance issues?

**Answer:**
```
N+1 problem: Running 1 query to get list, 
then 1 query per item in that list.

Example (bad):
-- Get all departments (1 query)
SELECT dept_id, dept_name FROM departments;

-- Then for each department, get employees (N queries)
-- 10 departments = 10 more queries
SELECT name FROM employees WHERE dept_id = 1;
SELECT name FROM employees WHERE dept_id = 2;
... (10 times)

Total: 11 queries for simple task.
With 1000 departments = 1001 queries. Application becomes slow.

Fix: Use JOIN (single query)
SELECT d.dept_name, e.name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id;

1 query. Same result.

In Spring Boot, N+1 is common with JPA LAZY loading.
Fix: Use JOIN FETCH in JPQL, or @EntityGraph annotation.

I've debugged this by:
1. Enabling SQL logging in Spring Boot
2. Counting queries in logs
3. Using LEFT JOIN FETCH to fix
```

**Red flag:** Never heard of N+1 problem.

---

# SECTION 3: Oracle Specific
## (Your current database — know this well)

---

### Q11. What Oracle-specific features have you used?

**What they want:** Real Oracle experience, not just generic SQL.

**Answer:**
```
In our Oracle project I've used:

1. ROWNUM / ROW_NUMBER()
   Pagination before OFFSET/FETCH:
   SELECT * FROM (
     SELECT e.*, ROWNUM rn FROM employees e
   ) WHERE rn BETWEEN 11 AND 20;

2. NVL / NVL2
   Handle NULL values:
   SELECT NVL(commission, 0) FROM employees;
   (Standard SQL uses COALESCE)

3. DECODE
   Case-like expression:
   SELECT DECODE(status, 'A', 'Active', 'I', 'Inactive', 'Unknown')
   FROM employees;

4. SEQUENCE
   Auto-increment (Oracle doesn't have AUTO_INCREMENT):
   CREATE SEQUENCE emp_seq START WITH 1 INCREMENT BY 1;
   INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Rahul', ...);

5. MERGE (UPSERT)
   Insert or Update in one statement:
   MERGE INTO target t
   USING source s ON (t.id = s.id)
   WHEN MATCHED THEN UPDATE SET t.name = s.name
   WHEN NOT MATCHED THEN INSERT VALUES (s.id, s.name);

6. Materialized Views
   Pre-computed query results for reports.
   Used for dashboard queries that were slow.
```

**Red flag:** "I just used standard SQL in Oracle."

---

### Q12. Difference between Oracle ROWNUM and ROW_NUMBER()?

**What they want:** Oracle-specific knowledge.

**Answer:**
```
ROWNUM:
- Pseudo-column assigned BEFORE ORDER BY
- Causes unexpected results if used with ORDER BY directly

Wrong (common mistake):
SELECT * FROM employees 
WHERE ROWNUM <= 5 
ORDER BY salary DESC;
-- Gets random 5 rows, THEN sorts them
-- NOT top 5 by salary!

Correct:
SELECT * FROM (
  SELECT * FROM employees ORDER BY salary DESC
)
WHERE ROWNUM <= 5;
-- Inner query sorts, outer limits

ROW_NUMBER():
- Window function, assigned AFTER ORDER BY
- More predictable behavior

SELECT * FROM (
  SELECT e.*, ROW_NUMBER() OVER (ORDER BY salary DESC) rn
  FROM employees e
)
WHERE rn <= 5;
-- Always correct top 5 by salary

In new Oracle versions (12c+):
SELECT * FROM employees 
ORDER BY salary DESC 
FETCH FIRST 5 ROWS ONLY;
-- Cleanest syntax, like LIMIT
```

**Red flag:** Using ROWNUM with ORDER BY directly.

---

### Q13. What is a materialized view? When did you use it?

**What they want:** Performance optimization experience.

**Answer:**
```
Materialized view stores the actual query result physically.
Regular view runs query every time.
Materialized view returns pre-computed result.

When to use:
- Complex reports queried frequently
- Aggregations on large tables
- Data doesn't change every second

Example from our project:
Monthly revenue dashboard was running complex query
on 50M order records — taking 45 seconds.

Solution:
CREATE MATERIALIZED VIEW monthly_revenue AS
SELECT 
  TRUNC(order_date, 'MONTH') as month,
  SUM(total_amount) as revenue,
  COUNT(*) as order_count
FROM orders
GROUP BY TRUNC(order_date, 'MONTH');

Refreshed nightly:
EXEC DBMS_MVIEW.REFRESH('monthly_revenue', 'C');

Dashboard now loads in 0.2 seconds.

Trade-off: Data is not real-time (stale by up to 24 hours).
Acceptable for monthly reports.
```

**Red flag:** Never heard of it, or not knowing the staleness trade-off.

---

# SECTION 4: Database Design
## (Principal Engineer level questions)

---

### Q14. How do you design a database for a new feature?

**What they want:** Your thought process, not just SQL syntax.

**Answer:**
```
My process:

1. Understand requirements first
   - What data do we need to store?
   - What queries will be run?
   - What's the expected data volume?
   - What are the relationships?

2. Identify entities and relationships
   - List all things we track
   - Map 1-to-1, 1-to-many, many-to-many

3. Normalize to 3NF
   - Remove repeating groups (1NF)
   - Remove partial dependencies (2NF)
   - Remove transitive dependencies (3NF)

4. Consider denormalization
   - If reports are slow due to too many JOINs
   - If read performance is critical
   - Document WHY you denormalized

5. Plan indexes
   - Foreign keys always indexed
   - WHERE clause columns indexed
   - Composite indexes for common filter combinations

6. Review with team
   - Show ER diagram
   - Ask: what queries will run on this?
   - Add missing columns, adjust relationships

Real example:
When adding order tracking feature, I:
- Listed: orders, tracking_events, locations, carriers
- Designed relationships first on paper
- Normalized to 3NF
- Added indexes on order_id and status columns
- Reviewed with backend developer
- Only then wrote CREATE TABLE statements
```

**Red flag:** "I just start writing CREATE TABLE."

---

### Q15. When would you denormalize a database?

**What they want:** You understand trade-offs, not just rules.

**Answer:**
```
Normalization removes redundancy and ensures data integrity.
But sometimes it's the right choice to denormalize.

When to denormalize:

1. Read performance is critical
   Too many JOINs making queries slow.
   Solution: Store redundant data to avoid JOINs.

2. Reporting tables / Data warehouses
   Analytics tables are often denormalized.
   OLAP (analytics) vs OLTP (transactions) design.

3. Aggregated values queried frequently
   Instead of calculating SUM every time:
   Store running total in separate column.

Real example:
We had order_items table with unit_price and quantity.
Total amount was calculated every time with:
SELECT SUM(quantity * unit_price) ...

This was in every report query, joining 3 tables.

Solution: Added total_amount column to orders table.
Updated when order items change (trigger or application logic).
Queries became 3x simpler and faster.

Trade-off I documented:
+ Faster reads
+ Simpler queries
- Must update in two places (application responsibility)
- Risk of inconsistency if not handled carefully
```

**Red flag:** "Always normalize" or "never denormalize."

---

### Q16. How do you handle schema changes in production?

**What they want:** Have you worked in real production environments?

**Answer:**
```
Schema changes in production need careful handling.
Wrong approach = downtime, data loss, broken application.

My approach:

1. Never DROP columns immediately
   Application might still use old column.
   Keep for 2-3 releases, then remove.

2. Add nullable columns only
   ALTER TABLE employees ADD phone VARCHAR(20);
   NOT NULL columns fail on existing rows.

3. Use database migrations
   Flyway or Liquibase — version control for schema.
   Each change is a numbered migration file.
   Rollback is documented.

4. Test on staging first
   Run migration on copy of production data.
   Verify application works.

5. Take backup before migration

6. For big table changes:
   Don't ALTER large table directly (locks table).
   Instead:
   - Create new table with new schema
   - Copy data in batches
   - Switch application to new table
   - Drop old table

7. Coordinate with deployment
   Schema change and code change must be compatible.
   Old code works with new schema.
   New code works with new schema.

We used Flyway in our Spring Boot project.
Every schema change was a V1__add_phone_column.sql file.
Applied automatically on application startup.
```

**Red flag:** "Just run ALTER TABLE and hope for the best."

---

# SECTION 5: Performance and Scaling
## (This is what separates Principal from Senior)

---

### Q17. How do you debug a slow query in production?

**What they want:** Real debugging experience.

**Answer:**
```
My step-by-step process:

Step 1: Identify the slow query
- Check application logs (Spring Boot slow query log)
- Enable Oracle slow query logging
- Use Oracle AWR (Automatic Workload Repository) report

Step 2: Run EXPLAIN PLAN
EXPLAIN PLAN FOR
SELECT ...slow query...;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

Look for:
- FULL TABLE SCAN (bad)
- High cost operations
- Nested loops on large tables

Step 3: Check indexes
- Are the right indexes there?
- Are they being used?
- Are they fragmented?

Step 4: Check statistics
- Oracle needs up-to-date statistics to choose right plan
EXEC DBMS_STATS.GATHER_TABLE_STATS('schema', 'table_name');

Step 5: Fix options
- Add missing index
- Rewrite query (avoid functions on columns)
- Add hints to force Oracle to use index
- Partition large table
- Materialize expensive subquery

Step 6: Verify
- Run query again after fix
- Compare EXPLAIN PLAN
- Monitor in production for a week

Real example:
A customer search query was taking 12 seconds.
EXPLAIN showed FULL TABLE SCAN on customers table (2M rows).
Created composite index on (name, status).
Query dropped to 0.1 seconds.
```

**Red flag:** "I just added an index and hoped it helped."

---

### Q18. What is database partitioning? Have you used it?

**What they want:** Large-scale experience.

**Answer:**
```
Partitioning divides a large table into smaller physical parts.
But it looks like one table to the application.

Types:

Range Partitioning (most common):
Divide by date range:
CREATE TABLE orders (...)
PARTITION BY RANGE (order_date) (
  PARTITION p2022 VALUES LESS THAN ('2023-01-01'),
  PARTITION p2023 VALUES LESS THAN ('2024-01-01'),
  PARTITION p2024 VALUES LESS THAN ('2025-01-01')
);

Query for 2023 only touches p2023 partition.
Not all 100M rows — partition pruning.

List Partitioning:
Divide by specific values:
PARTITION BY LIST (region) (
  PARTITION north VALUES ('Delhi', 'Punjab'),
  PARTITION south VALUES ('Chennai', 'Bangalore')
);

Benefits:
- Faster queries (partition pruning)
- Easier archiving (drop old partition)
- Parallel operations

In our project:
Order history table had 100M+ rows.
Reports for "last month" were scanning everything.
Added range partitioning by order_date.
Report queries dropped from 30s to 2s.
```

**Red flag:** Never heard of it, no real example.

---

### Q19. OLTP vs OLAP — how does database design differ?

**What they want:** Architectural thinking.

**Answer:**
```
OLTP (Online Transaction Processing):
- Day-to-day operations
- Many small, fast transactions
- INSERT, UPDATE, DELETE heavy
- Normalized (3NF) to avoid anomalies
- Indexes on lookup columns
- Examples: Order processing, banking, HR system

OLAP (Online Analytical Processing):
- Reporting and analytics
- Few large, complex queries
- SELECT heavy
- Denormalized (star schema, snowflake schema)
- Aggregated data
- Examples: Business intelligence, dashboards, reports

Design differences:

OLTP:
- Many tables, normalized
- Foreign keys enforced
- Row-based storage
- Real-time data

OLAP:
- Fewer tables, denormalized
- Fact tables + dimension tables
- Column-based storage (faster aggregations)
- Historical / periodic snapshots

In our project:
Main Oracle DB is OLTP — handles transactions.
We created a separate reporting schema that was denormalized.
Nightly ETL process populated reporting schema.
Dashboard queries ran on reporting schema — fast.
Didn't impact production OLTP performance.
```

**Red flag:** Not knowing the difference.

---

# SECTION 6: Scenario Based
## (They test your problem-solving)

---

### Q20. You have a query that runs fine on 1000 rows but is slow on 10M rows. What do you do?

**Answer:**
```
First, don't panic. This is expected — behavior changes at scale.

My approach:

1. Reproduce the issue
   - Get explain plan on large data
   - Don't assume — verify

2. Check EXPLAIN PLAN
   - Look for FULL TABLE SCAN
   - Look for high row estimates

3. Check indexes
   - Are they present?
   - Are statistics up-to-date?
   - Are they being used?

4. Look at the query itself
   - Functions on columns in WHERE?
   - Leading wildcard in LIKE?
   - Unnecessary JOINs?
   - SELECT * ?

5. Consider data distribution
   - Is data skewed? (90% rows have same value)
   - Index might not help for low cardinality

6. Options I try in order:
   - Add/fix index (cheapest fix)
   - Rewrite query (avoid function on column)
   - Add partitioning (if date-based data)
   - Materialize expensive subquery
   - Archive old data (if historical data bloating table)

7. Test fix on staging with production-like volume
   Never test on production first.

Key lesson I learned:
Always test with realistic data volume.
Problems hide on small datasets.
```

---

### Q21. How would you design a database for an audit trail?

**Answer:**
```
Requirement: Track all changes to important data.
Who changed what, when, what was the old value.

Two approaches:

Approach 1: Separate audit table (I prefer this)

CREATE TABLE employees_audit (
  audit_id     INT PRIMARY KEY AUTO_INCREMENT,
  emp_id       INT,
  action       VARCHAR(10),  -- INSERT, UPDATE, DELETE
  changed_at   DATETIME,
  changed_by   VARCHAR(50),  -- logged-in user
  old_salary   INT,
  new_salary   INT,
  old_dept_id  INT,
  new_dept_id  INT
);

Triggered automatically via database trigger or application code.

Approach 2: Soft delete + versioning

Instead of DELETE:
UPDATE employees SET is_deleted = 1 WHERE emp_id = 1;

Keep all versions, mark current:
ALTER TABLE employees ADD version INT DEFAULT 1;
ALTER TABLE employees ADD is_current BOOLEAN DEFAULT 1;

On change: INSERT new row, UPDATE old row is_current=0.

Which I use:
For compliance-heavy systems (banking, healthcare): Approach 1.
Separate audit table, immutable records.
Application writes to audit table on every change.
Indexed on emp_id and changed_at for fast lookup.

For general applications: Soft delete + updated_at timestamp.
Simpler, doesn't require separate table.
```

---

# Quick Reference Before Interview

## 5 Things They Always Ask

```
1. Joins — know all 4, give example
2. Indexes — when to create, when not to
3. EXPLAIN — how to read it
4. Transactions — ACID properties
5. Optimization — 3-4 common problems and fixes
```

## 3 Questions You Should Ask Them

```
1. "What is the scale of data in your systems? Millions of rows or billions?"
   (Shows you think about scale)

2. "Do you use any ORM like Hibernate, or raw SQL?"
   (Shows you know real-world stack)

3. "What monitoring do you have for slow queries?"
   (Shows you think about production)
```

## Common Mistakes in Interviews

```
❌ Giving textbook answers without real examples
✅ Always connect to something you've actually done

❌ "I don't know" and stopping
✅ "I haven't done exactly that, but I would approach it by..."

❌ Over-explaining basics
✅ Assume they know basics, go deeper

❌ Not asking clarifying questions
✅ "Is this for OLTP or reporting?" shows senior thinking
```

---

## Final Checklist

Before interview, verify you can answer:

```
□ INNER vs LEFT JOIN with real example
□ WHERE vs HAVING
□ DELETE vs TRUNCATE vs DROP
□ Index — when to create, when not to
□ Composite index column order
□ Window functions — give example
□ CTE — when to use
□ Query execution order
□ N+1 problem and fix
□ Oracle specific: ROWNUM, NVL, SEQUENCE
□ How to debug slow query
□ OLTP vs OLAP difference
□ Audit trail design
```

---

Good luck! 🚀