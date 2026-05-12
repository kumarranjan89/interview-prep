# SQL Basics — SELECT and WHERE

**Everything you need to start writing SQL queries.**

---

## What is SQL?

SQL = Structured Query Language

Simple meaning: A way to **ask questions to a database and get answers**.

Think of it like asking:
- "Show me all employees"
- "Show me employees earning more than 50000"
- "Show me employees in the Frontend department"

SQL lets you ask these questions.

---

## The Database Structure

Before you write SQL, understand what you're querying:

### Table (Like Excel sheet)

```
employees table:
┌────────┬──────────┬────────┬────────┐
│ emp_id │ name     │ salary │ dept   │
├────────┼──────────┼────────┼────────┤
│ 1      │ Rahul    │ 85000  │ IT     │
│ 2      │ Priya    │ 92000  │ HR     │
│ 3      │ Amit     │ 78000  │ IT     │
│ 4      │ Sneha    │ 65000  │ Sales  │
└────────┴──────────┴────────┴────────┘
```

- **Row** = One employee (horizontal)
- **Column** = One attribute (vertical)
- **Cell** = Single value (e.g., "Rahul")

---

## SELECT — Get Data

### Most Basic Query

```sql
SELECT * FROM employees;
```

What it means:
- `SELECT *` = Get ALL columns
- `FROM employees` = From the employees table

Result:
```
emp_id  name     salary  dept
1       Rahul    85000   IT
2       Priya    92000   HR
3       Amit     78000   IT
4       Sneha    65000   Sales
```

---

## Specific Columns (Not *)

### Better Practice: Get Only What You Need

```sql
SELECT name, salary FROM employees;
```

Result:
```
name     salary
Rahul    85000
Priya    92000
Amit     78000
Sneha    65000
```

**Why better than SELECT *?**
- Faster (less data to transfer)
- Clearer (you see only what you need)
- Safer (don't expose unnecessary data)

---

## WHERE — Filter Data

### Question: Show me employees earning more than 80000

```sql
SELECT name, salary 
FROM employees
WHERE salary > 80000;
```

Result:
```
name     salary
Rahul    85000
Priya    92000
```

**What happened:**
- Got all employees
- Kept only those with salary > 80000
- Removed Amit (78000) and Sneha (65000)

---

## Comparison Operators

Use these in WHERE clause:

```
=      Equal to              WHERE salary = 85000
!=     Not equal to          WHERE dept != 'IT'
>      Greater than          WHERE salary > 50000
<      Less than             WHERE salary < 60000
>=     Greater or equal      WHERE salary >= 80000
<=     Less or equal         WHERE salary <= 80000
```

---

## Examples with Different Operators

### Example 1: Exact Match
```sql
SELECT name FROM employees
WHERE dept = 'IT';

Result:
name
Rahul
Amit
```

### Example 2: Less Than
```sql
SELECT name, salary FROM employees
WHERE salary < 80000;

Result:
name     salary
Amit     78000
Sneha    65000
```

### Example 3: Not Equal
```sql
SELECT name FROM employees
WHERE dept != 'IT';

Result:
name
Priya
Sneha
```

---

## Multiple Conditions

### AND (Both conditions must be true)

Question: Show employees in IT earning > 80000

```sql
SELECT name, salary, dept FROM employees
WHERE dept = 'IT' AND salary > 80000;

Result:
name     salary  dept
Rahul    85000   IT
```

**What happened:**
- Check dept = 'IT' ✓ Rahul, Amit (2 found)
- AND check salary > 80000 ✓ Rahul only (1 found)
- Result: Only Rahul

---

### OR (At least one condition must be true)

Question: Show employees in IT OR HR

```sql
SELECT name, dept FROM employees
WHERE dept = 'IT' OR dept = 'HR';

Result:
name     dept
Rahul    IT
Priya    HR
Amit     IT
```

**What happened:**
- Check dept = 'IT' ✓ Rahul, Amit (2 found)
- OR check dept = 'HR' ✓ Priya (1 found)
- Result: All 3

---

## Real-World Examples

### Example 1: Basic Employee Query

Question: Get all IT employees

```sql
SELECT emp_id, name, salary 
FROM employees
WHERE dept = 'IT';
```

### Example 2: Salary Range

Question: Get employees earning between 70000 and 90000

```sql
SELECT name, salary 
FROM employees
WHERE salary >= 70000 AND salary <= 90000;

Result:
name     salary
Rahul    85000
Amit     78000
```

### Example 3: Multiple OR Conditions

Question: Get employees from IT or HR or Sales

```sql
SELECT name, dept 
FROM employees
WHERE dept = 'IT' 
  OR dept = 'HR' 
  OR dept = 'Sales';
```

---

## String Matching (LIKE)

### Exact Match vs Pattern Match

```sql
-- Exact match (must be exactly 'Rahul')
WHERE name = 'Rahul';

-- Pattern match (starts with 'Ra')
WHERE name LIKE 'Ra%';

-- Pattern match (contains 'ul')
WHERE name LIKE '%ul%';
```

### LIKE Wildcards

```
%    = Any number of characters
_    = Single character
```

### Examples

```sql
-- Names starting with 'R'
WHERE name LIKE 'R%';
-- Matches: Rahul, Rohan, Ravi

-- Names ending with 'a'
WHERE name LIKE '%a';
-- Matches: Priya, Sneha, Neha

-- Names containing 'h'
WHERE name LIKE '%h%';
-- Matches: Rahul, Sneha, Harsh

-- Names with exactly 4 letters
WHERE name LIKE '____';
-- Matches: Amit, Ravi
```

---

## NULL Values

### Understanding NULL

NULL = No value / Unknown value

NOT the same as:
- 0 (zero is a value)
- Empty string (is a value)
- NULL (is truly nothing)

```
Example:
emp_id  name     dept
1       Rahul    IT
2       Priya    NULL     ← No department assigned
3       Amit     IT
```

### Finding NULL

**Wrong way:**
```sql
SELECT name FROM employees
WHERE dept = NULL;
-- This doesn't work! Returns nothing.
```

**Right way:**
```sql
SELECT name FROM employees
WHERE dept IS NULL;

Result:
name
Priya
```

### Finding NOT NULL

```sql
SELECT name FROM employees
WHERE dept IS NOT NULL;

Result:
name
Rahul
Amit
Sneha
```

---

## ORDER BY — Sort Results

### Sort A-Z (Ascending)

```sql
SELECT name FROM employees
ORDER BY name;

Result:
name
Amit
Priya
Rahul
Sneha
```

### Sort Z-A (Descending)

```sql
SELECT name FROM employees
ORDER BY name DESC;

Result:
name
Sneha
Rahul
Priya
Amit
```

### Sort by Number (Low to High)

```sql
SELECT name, salary FROM employees
ORDER BY salary;

Result:
name     salary
Sneha    65000
Amit     78000
Rahul    85000
Priya    92000
```

### Sort by Number (High to Low)

```sql
SELECT name, salary FROM employees
ORDER BY salary DESC;

Result:
name     salary
Priya    92000
Rahul    85000
Amit     78000
Sneha    65000
```

---

## LIMIT — Get Only First N Rows

### Top N Results

```sql
-- Get top 2 employees by salary
SELECT name, salary FROM employees
ORDER BY salary DESC
LIMIT 2;

Result:
name     salary
Priya    92000
Rahul    85000
```

**Use cases:**
- Top 5 products by sales
- Latest 10 orders
- Top 3 customers by spending

---

## Putting It All Together

### Complex Query Example

Question: Get top 2 IT employees by salary

```sql
SELECT name, salary, dept
FROM employees
WHERE dept = 'IT'
ORDER BY salary DESC
LIMIT 2;

Result:
name     salary  dept
Rahul    85000   IT
Amit     78000   IT
```

**Step by step:**
1. `FROM employees` — Start with all employees
2. `WHERE dept = 'IT'` — Filter to IT only (2 rows)
3. `ORDER BY salary DESC` — Sort high to low
4. `LIMIT 2` — Get only top 2

---

## Query Structure (Always This Order)

```sql
SELECT   column1, column2, ...
FROM     table_name
WHERE    condition
ORDER BY column
LIMIT    number;
```

**Important:** This order is FIXED. Don't change it.

### Wrong order:
```sql
-- ❌ This doesn't work
SELECT name FROM employees
LIMIT 2
WHERE dept = 'IT';
```

### Right order:
```sql
-- ✅ This works
SELECT name FROM employees
WHERE dept = 'IT'
LIMIT 2;
```

---

## Common Mistakes

### Mistake 1: Using = with NULL

❌ Wrong:
```sql
WHERE dept = NULL;
-- This returns nothing
```

✅ Right:
```sql
WHERE dept IS NULL;
-- This works
```

---

### Mistake 2: Forgetting Quotes for Text

❌ Wrong:
```sql
WHERE dept = IT;
-- SQL thinks IT is a column name
```

✅ Right:
```sql
WHERE dept = 'IT';
-- Quotes mean "this is text"
```

---

### Mistake 3: Case Sensitivity

Depends on database, but usually:

```sql
-- These are the SAME
WHERE dept = 'IT';
WHERE dept = 'it';
WHERE dept = 'It';

-- All work and find 'IT' department
```

---

### Mistake 4: Confusing AND / OR

❌ Wrong logic:
```sql
-- This asks: dept = IT OR HR (confusing)
WHERE dept = 'IT' OR 'HR';
```

✅ Right:
```sql
-- Clear: dept is IT OR dept is HR
WHERE dept = 'IT' OR dept = 'HR';
```

---

### Mistake 5: SELECT * for Big Tables

❌ Bad:
```sql
SELECT * FROM employees;
-- If table has 1M rows × 50 columns = huge
```

✅ Good:
```sql
SELECT name, salary FROM employees;
-- Only 2 columns, much faster
```

---

## Practice Exercises

Use this data:

```sql
CREATE TABLE employees (
  emp_id INT,
  name VARCHAR(50),
  salary INT,
  dept VARCHAR(20),
  hire_date DATE
);

INSERT INTO employees VALUES
(1, 'Rahul', 85000, 'IT', '2020-01-15'),
(2, 'Priya', 92000, 'HR', '2019-03-20'),
(3, 'Amit', 78000, 'IT', '2021-06-10'),
(4, 'Sneha', 65000, 'Sales', '2022-02-05'),
(5, 'Vikram', 88000, 'IT', '2020-09-12'),
(6, 'Neha', NULL, 'HR', '2023-01-08');
```

### Exercise 1: Get all employees
```
Expected: 6 rows with all columns
Hint: SELECT * FROM employees;
```

### Exercise 2: Get employees earning > 80000
```
Expected: Rahul, Priya, Vikram (3 rows)
Hint: WHERE salary > 80000
```

### Exercise 3: Get IT employees
```
Expected: Rahul, Amit, Vikram (3 rows)
Hint: WHERE dept = 'IT'
```

### Exercise 4: Get IT employees earning > 80000
```
Expected: Rahul, Vikram (2 rows)
Hint: WHERE dept = 'IT' AND salary > 80000
```

### Exercise 5: Sort by salary (highest first)
```
Expected: Priya (92000), Rahul (85000), ...
Hint: ORDER BY salary DESC
```

### Exercise 6: Top 3 employees by salary
```
Expected: Priya, Rahul, Vikram
Hint: ORDER BY salary DESC LIMIT 3
```

### Exercise 7: Get employees with no salary (NULL)
```
Expected: Neha
Hint: WHERE salary IS NULL
```

### Exercise 8: Get employees from HR or Sales
```
Expected: Priya, Sneha, Neha (3 rows)
Hint: WHERE dept = 'HR' OR dept = 'Sales'
```

---

## Summary Table

| Keyword | Purpose | Example |
|---------|---------|---------|
| SELECT | Choose columns | SELECT name, salary |
| FROM | Which table | FROM employees |
| WHERE | Filter rows | WHERE salary > 50000 |
| AND | Both true | WHERE dept = 'IT' AND salary > 80000 |
| OR | At least one true | WHERE dept = 'IT' OR dept = 'HR' |
| LIKE | Pattern match | WHERE name LIKE 'R%' |
| IS NULL | Check for NULL | WHERE dept IS NULL |
| IS NOT NULL | Check not NULL | WHERE dept IS NOT NULL |
| ORDER BY | Sort | ORDER BY salary DESC |
| DESC | Descending order | ORDER BY salary DESC |
| ASC | Ascending order | ORDER BY salary ASC (default) |
| LIMIT | Limit rows | LIMIT 10 |

---

## Key Takeaways

1. **SELECT chooses columns**
2. **FROM picks the table**
3. **WHERE filters rows**
4. **AND = both conditions true**
5. **OR = at least one true**
6. **NULL needs IS NULL (not =)**
7. **TEXT needs quotes ('text')**
8. **ORDER BY sorts results**
9. **LIMIT gets only N rows**
10. **Always use query structure order**

---

## What's Next?

After mastering SELECT and WHERE:
- Move to 02-join.md (most important next step)
- Then 03-insert-update-delete.md
- Then 04-transactions.md

But don't skip JOIN — it's 70% of real SQL work.

---

## Practice Now

1. Copy the data setup above
2. Create table in your database
3. Insert data
4. Solve all 8 exercises
5. Verify your results match expected output

**Time: 2-3 hours**

This is the foundation. Take time to understand.

Good luck! 🚀