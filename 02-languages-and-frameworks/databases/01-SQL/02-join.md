# JOIN - Combining Data From Multiple Tables

**This is the MOST important topic in SQL.**

---

## Why JOIN Matters

Imagine you have two lists:

**List 1: Employees**
```
emp_id  name       dept_id
1       Rahul      10
2       Priya      20
3       Amit       10
4       Sneha      NULL
```

**List 2: Departments**
```
dept_id  dept_name
10       Frontend
20       Backend
30       DevOps
40       Design
```

You want to know: **"Who works in which department?"**

You need to match `emp.dept_id` with `dept.dept_id`.

That's a JOIN.

---

## The Problem JOINs Solve

Without JOIN, you'd do:
```
1. Get all employees
2. Loop through each employee
3. For each employee, find their department
4. Combine the results
```

This is slow and bad.

With JOIN:
```
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;
```

Done. Fast. Clean.

---

## Core Concept

**JOIN means: Match rows from two tables using a relationship**

The relationship is the connection between them.

Example:
- Employee table has `dept_id`
- Department table has `dept_id` (PRIMARY KEY)
- They match on this column

---

## The 4 Types of JOIN

### 1️⃣ INNER JOIN (Match Only)

**Question: Show employees WITH their departments**

```sql
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d 
  ON e.dept_id = d.dept_id;
```

**Result:**
```
name       dept_name
Rahul      Frontend
Priya      Backend
Amit       Frontend
```

**What happened:**
- Rahul (dept_id=10) matched with Frontend (dept_id=10) ✅
- Priya (dept_id=20) matched with Backend (dept_id=20) ✅
- Amit (dept_id=10) matched with Frontend (dept_id=10) ✅
- Sneha (dept_id=NULL) — NO MATCH, removed ❌
- Design (dept_id=40) — NO MATCHING EMPLOYEE, removed ❌

**When to use:**
- You only want matching records
- "Show me customers WITH orders"
- "Show me products THAT HAVE reviews"

**Visual:**
```
Employees          Departments
  1 Rahul--10---->10 Frontend  ✅
  2 Priya--20---->20 Backend   ✅
  3 Amit ---10---/
  4 Sneha--NULL
                  30 DevOps
                  40 Design
```

Only the connecting lines appear in INNER JOIN.

---

### 2️⃣ LEFT JOIN (All Left + Matching Right)

**Question: Show ALL employees, with their department if they have one**

```sql
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d 
  ON e.dept_id = d.dept_id;
```

**Result:**
```
name       dept_name
Rahul      Frontend
Priya      Backend
Amit       Frontend
Sneha      NULL
```

**What happened:**
- Rahul (dept_id=10) matched with Frontend ✅
- Priya (dept_id=20) matched with Backend ✅
- Amit (dept_id=10) matched with Frontend ✅
- Sneha (dept_id=NULL) — NO MATCH, but kept with NULL ✅
- Design (dept_id=40) — NO MATCHING EMPLOYEE, removed ❌

**When to use:**
- You want all records from left table
- Missing data shows as NULL
- "Show me ALL customers, with orders if they have any"
- "Show me ALL employees, even those without a department"

**Visual:**
```
Employees          Departments
  1 Rahul--10---->10 Frontend
  2 Priya--20---->20 Backend
  3 Amit ---10---/
  4 Sneha--NULL    (NULL)
                  30 DevOps
                  40 Design
```

All left table rows appear, unmatched show NULL.

---

### 3️⃣ RIGHT JOIN (All Right + Matching Left)

**Question: Show ALL departments, with employees if they have any**

```sql
SELECT e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d 
  ON e.dept_id = d.dept_id;
```

**Result:**
```
name       dept_name
Rahul      Frontend
Amit       Frontend
Priya      Backend
NULL       DevOps
NULL       Design
```

**What happened:**
- Frontend matches with Rahul and Amit ✅
- Backend matches with Priya ✅
- DevOps has NO MATCHING EMPLOYEE, appears with NULL ✅
- Design has NO MATCHING EMPLOYEE, appears with NULL ✅
- Sneha (unmatched left) — removed ❌

**When to use:**
- You want all records from right table
- Missing data shows as NULL
- "Show me ALL departments, with employees if they work there"
- "Show me ALL products, with sales if they have any"

**Visual:**
```
Employees          Departments
  1 Rahul--10---->10 Frontend
  2 Priya--20---->20 Backend
  3 Amit ---10---/
  4 Sneha--NULL  30 DevOps    (NULL)
                  40 Design   (NULL)
```

All right table rows appear, unmatched show NULL.

---

### 4️⃣ FULL OUTER JOIN (All Rows From Both)

**Question: Show everything — all employees AND all departments, even if no match**

```sql
SELECT e.name, d.dept_name
FROM employees e
FULL OUTER JOIN departments d 
  ON e.dept_id = d.dept_id;
```

**Result:**
```
name       dept_name
Rahul      Frontend
Amit       Frontend
Priya      Backend
Sneha      NULL
NULL       DevOps
NULL       Design
```

**What happened:**
- All matching rows ✅
- Sneha (unmatched left) — kept ✅
- DevOps (unmatched right) — kept ✅
- Design (unmatched right) — kept ✅

**When to use:**
- Audit: Find mismatches
- "Show me all employees and all departments"
- "Find everything, especially what doesn't match"
- Data migration validation

**Visual:**
```
Employees          Departments
  1 Rahul--10---->10 Frontend
  2 Priya--20---->20 Backend
  3 Amit ---10---/
  4 Sneha--NULL  30 DevOps
                  40 Design
```

Every row from both tables appears (unmatched show NULL).

---

## Quick Decision Matrix

```
Question: "Show me ___"

"customers WITH orders" 
  → INNER JOIN (only matched)

"customers, with orders if they have any"
  → LEFT JOIN (all customers)

"orders, with customers even if not found"
  → RIGHT JOIN (all orders)

"customers AND orders, even if no match"
  → FULL OUTER JOIN (everything)

"Find customers who never ordered"
  → LEFT JOIN + WHERE right.id IS NULL

"Find orders with no valid customer"
  → RIGHT JOIN + WHERE left.id IS NULL

"Find all mismatches"
  → FULL OUTER JOIN + WHERE left.id IS NULL OR right.id IS NULL
```

---

## The ON Clause (Most Important)

The `ON` tells database which columns to match.

**Example:**
```sql
ON e.dept_id = d.dept_id
   ↑         ↑  ↑         ↑
   employee  =  department columns to match
   table        table
```

**Common mistake: Wrong ON condition**

```sql
-- WRONG (will give wrong results)
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_name;
                                         ↑ dept_name is wrong!

-- RIGHT
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
                                         ↑ primary key
```

---

## Real-World Examples

### Example 1: E-commerce

```sql
-- Question: Show all orders with customer names

SELECT o.order_id, c.name, o.total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;

Result:
order_id  name      total_amount
1         Rahul     5000
2         Priya     3000
3         Amit      4500
```

### Example 2: School System

```sql
-- Question: Show all students with their teacher and marks

SELECT s.name, t.name as teacher, m.marks
FROM students s
INNER JOIN classes c ON s.class_id = c.class_id
INNER JOIN teachers t ON c.teacher_id = t.teacher_id
INNER JOIN marks m ON s.student_id = m.student_id AND c.class_id = m.class_id;

Result:
name       teacher     marks
Rahul      Sharma      95
Priya      Sharma      88
Amit       Kumar       92
```

### Example 3: Finding Mismatches

```sql
-- Question: Show all employees WITHOUT a department

SELECT e.name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

Result:
name
Sneha

(Only Sneha has no department)
```

### Example 4: Complete Audit

```sql
-- Question: Show everything - find mismatches

SELECT 
  COALESCE(e.name, 'NO EMPLOYEE') as employee,
  COALESCE(d.dept_name, 'NO DEPARTMENT') as department
FROM employees e
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.employee_id IS NULL OR d.dept_id IS NULL;

Result (mismatches only):
employee      department
Sneha         NO DEPARTMENT
NO EMPLOYEE   DevOps
NO EMPLOYEE   Design
```

---

## Common Mistakes

### Mistake 1: Confusing LEFT and RIGHT

❌ Wrong:
```sql
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id;

-- This shows all departments (LEFT table), not all employees!
```

✅ Right:
```sql
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- This shows all employees (LEFT table)
```

**Remember:** LEFT = first table mentioned

---

### Mistake 2: Wrong ON condition

❌ Wrong:
```sql
FROM employees e
INNER JOIN departments d ON e.name = d.dept_name;

-- Comparing name with dept_name! Wrong columns!
```

✅ Right:
```sql
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Same column from both tables
```

---

### Mistake 3: SELECT * with JOIN

❌ Bad:
```sql
SELECT * FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Returns all columns from both tables
-- Duplicates dept_id, might be confusing
```

✅ Good:
```sql
SELECT e.emp_id, e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Only columns you need
-- Clear which table each comes from
```

---

### Mistake 4: Filtering in ON instead of WHERE

❌ Bad:
```sql
FROM employees e
INNER JOIN departments d 
  ON e.dept_id = d.dept_id AND d.dept_name = 'Frontend';

-- This works but is confusing
```

✅ Good:
```sql
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Frontend';

-- Clear: JOIN first, then filter
```

---

## Multiple JOINs (Real Queries)

```sql
-- Show customer orders with product names and reviews

SELECT 
  c.name as customer,
  o.order_id,
  p.product_name,
  oi.quantity,
  r.rating
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
LEFT JOIN reviews r ON p.product_id = r.product_id;

-- LEFT JOIN for reviews because not all products have reviews
```

---

## Practice Exercises

Use the **employees** and **departments** tables below.

### Setup:
```sql
CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name VARCHAR(50)
);

CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  name VARCHAR(50),
  dept_id INT
);

INSERT INTO departments VALUES
(10, 'Frontend'),
(20, 'Backend'),
(30, 'DevOps'),
(40, 'Design');

INSERT INTO employees VALUES
(1, 'Rahul', 10),
(2, 'Priya', 20),
(3, 'Amit', 10),
(4, 'Sneha', NULL),
(5, 'Vikram', 30);
```

### Exercises:

**1. INNER JOIN — Show employees WITH departments**
```
Expected: 4 rows (Rahul, Priya, Amit, Vikram)
Sneha should NOT appear (NULL dept_id)
```

**2. LEFT JOIN — Show ALL employees, with department if any**
```
Expected: 5 rows (all employees)
Sneha should appear with NULL department
```

**3. RIGHT JOIN — Show ALL departments, with employees if any**
```
Expected: 4 rows (all departments)
Design should appear with NULL employee
```

**4. FULL OUTER JOIN — Show everything**
```
Expected: 5 rows (all employees + departments with no employees)
```

**5. Find employees WITHOUT a department**
```
Expected: Just Sneha
Use: LEFT JOIN + WHERE dept_id IS NULL
```

**6. Find departments WITH NO employees**
```
Expected: Just Design
Use: RIGHT JOIN + WHERE emp_id IS NULL
```

---

## Summary

| Type | Left | Right | Unmatched Left | Unmatched Right |
|------|------|-------|---|---|
| INNER | ✅ | ✅ | ❌ | ❌ |
| LEFT | ✅ | ✅ | ✅ | ❌ |
| RIGHT | ✅ | ✅ | ❌ | ✅ |
| FULL | ✅ | ✅ | ✅ | ✅ |

---

## Key Takeaways

1. **JOIN matches rows using relationship**
2. **INNER = only matched**
3. **LEFT = all left + matched**
4. **RIGHT = all right + matched**
5. **FULL = all rows, even unmatched**
6. **ON clause is critical — must be correct**
7. **Most queries use LEFT or INNER**
8. **RIGHT is rarely used (rewrite as LEFT instead)**
9. **FULL is useful for audits**
10. **Always specify table aliases (e.g., e.name not just name)**

---

## What's Next?

After you understand JOINs:
- Move to [03-agreegation-subquery-cte.md](03-agreegation-subquery-cte.md)
- Practice with all 4 practice databases
- You'll see JOINs in every real query

---

## Practice Now

1. Create tables (copy from "Setup" above)
2. Solve 6 exercises
3. Write queries, not just read
4. Check results

**Don't skip this. JOINs are 70% of SQL.**

Good luck! 🚀