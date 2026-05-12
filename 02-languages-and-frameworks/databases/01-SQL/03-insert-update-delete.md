# INSERT, UPDATE, DELETE — Modifying Data

**How to safely add, change, and remove data from database.**

---

## Important: These Are Dangerous

SELECT is read-only — it just looks at data.

INSERT, UPDATE, DELETE **change data permanently**.

One mistake = data lost forever.

So we learn **safety first**.

---

## Understanding the Data Structure

Before modifying, understand relationships:

```
departments table:
┌─────────┬───────────────┐
│ dept_id │ dept_name     │
├─────────┼───────────────┤
│ 10      │ Frontend      │
│ 20      │ Backend       │
│ 30      │ DevOps        │
└─────────┴───────────────┘

employees table:
┌────────┬──────────┬────────┬─────────┐
│ emp_id │ name     │ salary │ dept_id │
├────────┼──────────┼────────┼─────────┤
│ 1      │ Rahul    │ 85000  │ 10      │
│ 2      │ Priya    │ 92000  │ 20      │
│ 3      │ Amit     │ 78000  │ 10      │
└────────┴──────────┴────────┴─────────┘
```

**Important:** dept_id in employees **references** dept_id in departments.

This is called **Foreign Key** — creates relationship.

---

# INSERT — Add New Data

## Basic INSERT

```sql
INSERT INTO employees (emp_id, name, salary, dept_id)
VALUES (4, 'Sneha', 65000, 30);
```

**What it does:**
- Goes to employees table
- Adds a new row
- Sets emp_id=4, name='Sneha', salary=65000, dept_id=30

**Result:**
```
emp_id  name     salary  dept_id
1       Rahul    85000   10
2       Priya    92000   20
3       Amit     78000   10
4       Sneha    65000   30  ← NEW ROW
```

---

## Syntax Explained

```sql
INSERT INTO employees (emp_id, name, salary, dept_id)
           ↑ table    ↑ columns you're filling
VALUES (4, 'Sneha', 65000, 30);
↑ values for those columns (in same order)
```

**Important:**
- Column order in parentheses
- Must match values order
- All values in quotes if text

---

## Correct Order for INSERT

When dept_id references departments:

```
❌ WRONG — Will fail with Foreign Key Error
INSERT INTO employees VALUES (5, 'Vikram', 88000, 99);
                                              ↑ dept_id 99 doesn't exist!

✅ RIGHT — Add department first, then employee
INSERT INTO departments VALUES (99, 'Quality');
INSERT INTO employees VALUES (5, 'Vikram', 88000, 99);
```

**Golden Rule #1:**
```
Insert parent table first
Then insert child table
```

Because:
- departments is **parent** (no dependencies)
- employees is **child** (depends on departments)

---

## Multiple Rows at Once

```sql
INSERT INTO employees (emp_id, name, salary, dept_id)
VALUES
(5, 'Vikram', 88000, 30),
(6, 'Neha', 72000, 20),
(7, 'Rohan', 81000, 10);
```

**Result:** All 3 rows added at once.

---

## Inserting NULL Values

```sql
INSERT INTO employees (emp_id, name, salary, dept_id)
VALUES (8, 'John', 70000, NULL);
```

Result:
```
emp_id  name    salary  dept_id
8       John    70000   NULL    ← No department
```

This works IF dept_id column allows NULL.

---

## Column Not Required?

If you skip a column:

```sql
INSERT INTO employees (emp_id, name, salary)
VALUES (9, 'Jane', 75000);
-- dept_id not specified
```

Result:
```
emp_id  name    salary  dept_id
9       Jane    75000   NULL    ← Gets NULL automatically
```

---

## Common INSERT Mistakes

### Mistake 1: Wrong Data Type

```sql
-- ❌ WRONG - salary is number, not text
INSERT INTO employees VALUES (10, 'Bob', 'eighty-five thousand', 20);

-- ✅ RIGHT - salary as number
INSERT INTO employees VALUES (10, 'Bob', 85000, 20);
```

---

### Mistake 2: Duplicate Primary Key

```sql
-- ❌ WRONG - emp_id 1 already exists
INSERT INTO employees VALUES (1, 'Someone', 70000, 20);
-- Error: Primary key violation

-- ✅ RIGHT - use new emp_id
INSERT INTO employees VALUES (11, 'Someone', 70000, 20);
```

---

### Mistake 3: Foreign Key Violation

```sql
-- ❌ WRONG - dept_id 999 doesn't exist
INSERT INTO employees VALUES (12, 'Alice', 80000, 999);
-- Error: Foreign key constraint

-- ✅ RIGHT - use existing dept_id
INSERT INTO employees VALUES (12, 'Alice', 80000, 30);
```

---

# UPDATE — Change Existing Data

## Basic UPDATE

```sql
UPDATE employees
SET salary = 90000
WHERE emp_id = 1;
```

**What it does:**
- Finds employee with emp_id = 1 (Rahul)
- Changes salary to 90000

**Before:**
```
emp_id  name    salary
1       Rahul   85000
```

**After:**
```
emp_id  name    salary
1       Rahul   90000   ← Changed
```

---

## Syntax Explained

```sql
UPDATE employees
↑ which table

SET salary = 90000
    ↑ column = new value

WHERE emp_id = 1;
      ↑ which row(s) to update
```

---

## Update Multiple Columns

```sql
UPDATE employees
SET salary = 90000, dept_id = 20
WHERE emp_id = 1;
```

**Before:**
```
emp_id  name    salary  dept_id
1       Rahul   85000   10
```

**After:**
```
emp_id  name    salary  dept_id
1       Rahul   90000   20      ← Both changed
```

---

## Update Multiple Rows

```sql
UPDATE employees
SET salary = salary + 5000
WHERE dept_id = 10;
```

**What it does:**
- Finds all employees in dept_id = 10
- Adds 5000 to each salary

**Before:**
```
emp_id  name    salary  dept_id
1       Rahul   85000   10
3       Amit    78000   10
7       Rohan   81000   10
```

**After:**
```
emp_id  name    salary  dept_id
1       Rahul   90000   10      ← +5000
3       Amit    83000   10      ← +5000
7       Rohan   86000   10      ← +5000
```

---

## Update Using Conditions

```sql
UPDATE employees
SET salary = 100000
WHERE salary < 80000 AND dept_id = 20;
```

**Updates:** Employees in dept_id=20 AND earning < 80000

---

## Critical: The WHERE Clause

### ❌ BIGGEST MISTAKE: Forgetting WHERE

```sql
-- ❌ WRONG - No WHERE clause
UPDATE employees SET salary = 100000;

-- Result: ALL employees get 100000 salary!
-- DISASTER!
```

**After:**
```
emp_id  name    salary  dept_id
1       Rahul   100000  10
2       Priya   100000  20
3       Amit    100000  10
4       Sneha   100000  30
... (ALL changed)
```

### ✅ RIGHT: Always Use WHERE

```sql
-- ✅ RIGHT - Has WHERE clause
UPDATE employees 
SET salary = 100000
WHERE emp_id = 1;

-- Result: Only Rahul updated
```

---

## Safety First: Test Before UPDATE

**Golden Rule #2:**
```
Before UPDATE, SELECT first to see what will change
```

```sql
-- STEP 1: See what you'll change
SELECT * FROM employees WHERE dept_id = 10;

-- Check results (are these the right rows?)
-- If yes, proceed to STEP 2

-- STEP 2: Do the UPDATE
UPDATE employees SET salary = salary + 5000 WHERE dept_id = 10;
```

---

## Common UPDATE Mistakes

### Mistake 1: Wrong WHERE Condition

```sql
-- ❌ WRONG - Updates wrong person
UPDATE employees SET salary = 90000 WHERE name = 'Rahul';
-- What if 2 people named Rahul?

-- ✅ RIGHT - Use unique ID
UPDATE employees SET salary = 90000 WHERE emp_id = 1;
```

---

### Mistake 2: Comparing NULL Wrong

```sql
-- ❌ WRONG - NULL comparisons don't work
UPDATE employees SET dept_id = 30 WHERE dept_id = NULL;
-- Updates nothing!

-- ✅ RIGHT
UPDATE employees SET dept_id = 30 WHERE dept_id IS NULL;
```

---

### Mistake 3: Logic Error

```sql
-- ❌ WRONG logic
UPDATE employees SET salary = 75000 
WHERE salary = 75000;
-- This does nothing (already 75000)

-- ✅ RIGHT
UPDATE employees SET salary = 75000 
WHERE salary < 60000;
-- Raises low salaries to 75000
```

---

# DELETE — Remove Data

## Basic DELETE

```sql
DELETE FROM employees
WHERE emp_id = 4;
```

**What it does:**
- Finds employee with emp_id = 4
- Removes that row permanently

**Before:**
```
emp_id  name    salary  dept_id
1       Rahul   85000   10
2       Priya   92000   20
3       Amit    78000   10
4       Sneha   65000   30
```

**After:**
```
emp_id  name    salary  dept_id
1       Rahul   85000   10
2       Priya   92000   20
3       Amit    78000   10
-- Sneha gone
```

---

## Syntax Explained

```sql
DELETE FROM employees
↑ which table

WHERE emp_id = 4;
      ↑ which row(s) to delete
```

---

## Delete Multiple Rows

```sql
DELETE FROM employees
WHERE dept_id = 10;
```

**Deletes:** All employees in dept_id = 10 (Rahul, Amit, Rohan)

---

## ⚠️ MOST DANGEROUS: Forgetting WHERE

### ❌ BIGGEST MISTAKE: No WHERE Clause

```sql
-- ❌ WRONG - No WHERE clause
DELETE FROM employees;

-- Result: ALL employees deleted!
-- ENTIRE TABLE GONE!
```

---

## Safety First: Test Before DELETE

**Golden Rule #3:**
```
Before DELETE, SELECT first to verify what will be deleted
```

```sql
-- STEP 1: See what you'll delete
SELECT * FROM employees WHERE dept_id = 10;

-- Count results
SELECT COUNT(*) FROM employees WHERE dept_id = 10;
-- Result: 3 rows

-- If correct, proceed to STEP 2

-- STEP 2: Do the DELETE
DELETE FROM employees WHERE dept_id = 10;
```

---

## Parent-Child Deletion Rule

When there's a relationship:

```
❌ WRONG - Will fail with Foreign Key Error
DELETE FROM departments WHERE dept_id = 10;
-- Error! employees table still has dept_id = 10

✅ RIGHT - Delete child first, then parent
DELETE FROM employees WHERE dept_id = 10;  -- Remove employees first
DELETE FROM departments WHERE dept_id = 10; -- Then remove department
```

**Golden Rule #4:**
```
Delete child rows first
Then delete parent row
(Opposite of INSERT order)
```

---

## Common DELETE Mistakes

### Mistake 1: Wrong WHERE Condition

```sql
-- ❌ Deletes everyone except emp_id 1
DELETE FROM employees WHERE emp_id != 1;

-- ✅ Correct - Just delete emp_id 1
DELETE FROM employees WHERE emp_id = 1;
```

---

### Mistake 2: No WHERE = Disaster

```sql
-- ❌ NEVER do this
DELETE FROM employees;
-- All 12 employees gone!

-- ✅ Always have WHERE
DELETE FROM employees WHERE emp_id = 1;
```

---

### Mistake 3: Foreign Key Constraint

```sql
-- ❌ WRONG - Fails because employees reference this
DELETE FROM departments WHERE dept_id = 10;
-- Error: Can't delete, employees still exist

-- ✅ RIGHT
DELETE FROM employees WHERE dept_id = 10;  -- First
DELETE FROM departments WHERE dept_id = 10;  -- Then
```

---

# Transactions — Safe Modifications

## What is a Transaction?

A group of changes that must **ALL succeed or ALL fail together**.

```sql
BEGIN TRANSACTION;

DELETE FROM employees WHERE emp_id = 1;
DELETE FROM salary_history WHERE emp_id = 1;

COMMIT;   -- If happy, save both changes
-- OR
ROLLBACK; -- If unhappy, undo both changes
```

---

## Real Example: Employee Transfer

```sql
BEGIN TRANSACTION;

-- Step 1: Remove from old department
UPDATE employees SET dept_id = NULL WHERE emp_id = 1;

-- Step 2: Add to new department
UPDATE employees SET dept_id = 20 WHERE emp_id = 1;

-- Step 3: Add transfer record
INSERT INTO transfer_history VALUES (1, 10, 20, '2024-01-15');

-- If all 3 succeeded, save everything
COMMIT;

-- If any failed, undo all
-- ROLLBACK;
```

---

## Why Transactions?

Imagine bank transfer without transaction:

```
❌ WITHOUT TRANSACTION:
UPDATE account_a SET balance = balance - 1000;  -- Money leaves
-- Computer crashes here!
UPDATE account_b SET balance = balance + 1000;  -- Money never arrives
-- Result: Money lost!

✅ WITH TRANSACTION:
BEGIN;
UPDATE account_a SET balance = balance - 1000;
UPDATE account_b SET balance = balance + 1000;
COMMIT;
-- Either both succeed or both undo
```

---

# Complete Safety Checklist

Before any INSERT/UPDATE/DELETE:

```
□ Is this what I want to change?
□ Did I SELECT first to verify?
□ Did I count rows (SELECT COUNT(*))?
□ Do I have WHERE clause? (unless INSERT)
□ Did I check for typos in WHERE?
□ Am I in correct table?
□ For DELETE: parent-child order correct?
□ For INSERT: dependencies exist first?
□ Should this be in a TRANSACTION?
□ Is backup available if something goes wrong?
```

---

# Practice Exercises

Use this setup:

```sql
CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name VARCHAR(50)
);

CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  name VARCHAR(50),
  salary INT,
  dept_id INT,
  FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
(10, 'Frontend'),
(20, 'Backend'),
(30, 'DevOps');

INSERT INTO employees VALUES
(1, 'Rahul', 85000, 10),
(2, 'Priya', 92000, 20),
(3, 'Amit', 78000, 10),
(4, 'Sneha', 65000, NULL);
```

---

## Exercises

### Exercise 1: Insert New Employee

```
Task: Add employee 'Vikram' with salary 88000 in dept_id 30

Expected result after insert:
emp_id  name    salary  dept_id
5       Vikram  88000   30
```

### Exercise 2: Insert Multiple Employees

```
Task: Add Neha (72000, dept 20) and Rohan (81000, dept 10) in one query

Expected: 2 new rows added
```

### Exercise 3: Update Single Employee

```
Task: Increase Rahul's salary to 90000

Expected:
emp_id  name    salary  dept_id
1       Rahul   90000   10   ← Changed from 85000
```

### Exercise 4: Update Multiple Rows

```
Task: Increase all Frontend employees' salary by 5000

Expected: Rahul and Amit get +5000
```

### Exercise 5: Assign Department to Sneha

```
Task: Assign Sneha to dept_id 20

Expected:
emp_id  name    salary  dept_id
4       Sneha   65000   20    ← Changed from NULL
```

### Exercise 6: Delete Single Employee

```
Task: Delete Amit (emp_id = 3)

Expected: Only 1 row deleted (3 rows remain)
```

### Exercise 7: Delete Department's Employees

```
Task: Delete all employees in dept_id 30 first, then delete the department

Expected process:
1. DELETE employees WHERE dept_id = 30
2. DELETE departments WHERE dept_id = 30
3. Verify department is gone
```

### Exercise 8: Update with Condition

```
Task: Increase salary to 85000 for employees earning < 80000

Expected:
- Amit: 78000 → 85000
- Sneha: 65000 → 85000
```

---

# Summary Table

| Operation | Syntax | When to Use | Danger |
|-----------|--------|------------|--------|
| INSERT | INSERT INTO table VALUES | Add new rows | Foreign key violation |
| UPDATE | UPDATE table SET col=val WHERE | Change existing | Forgetting WHERE |
| DELETE | DELETE FROM table WHERE | Remove rows | Forgetting WHERE |
| SELECT | SELECT * FROM table WHERE | Check first | None (read-only) |

---

# Golden Rules (Memorize These)

```
Rule 1: INSERT parent first, child second
Rule 2: Before UPDATE, SELECT to verify
Rule 3: Before DELETE, SELECT to verify
Rule 4: DELETE child first, parent second
Rule 5: ALWAYS use WHERE (except INSERT)
Rule 6: Use TRANSACTIONS for related changes
Rule 7: Never do INSERT/UPDATE/DELETE in production without testing
```

---

# What's Next?

After INSERT/UPDATE/DELETE:
- Move to 04-transactions.md (deeper understanding)
- Then 05-data-modeling.md
- Then practice with real databases

But practice these 8 exercises first — they're critical.

---

## Practice Now

1. Copy setup code above
2. Create table
3. Insert test data
4. Solve all 8 exercises
5. Verify results

**Time: 2-3 hours**

Don't skip practice. INSERT/UPDATE/DELETE are dangerous.

Good luck! 🚀