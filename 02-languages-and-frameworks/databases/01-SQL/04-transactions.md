# Transactions — Keeping Data Safe and Consistent

**How to group SQL changes so they all succeed together or all fail together.**

---

## The Problem Transactions Solve

Imagine you're transferring money from one account to another:

```
Account A: 1000
Account B: 0

Goal: Transfer 500 from A to B
Expected result: A=500, B=500
```

Without transactions (DISASTER):

```
Step 1: Remove 500 from Account A
  Account A: 500
  Account B: 0

Step 2: Computer crashes here!

Step 3: Add 500 to Account B
  (Never happens)

Result: 
  Account A: 500 (money gone)
  Account B: 0   (never arrived)
  
DISASTER: Money lost!
```

With transactions (SAFE):

```
BEGIN TRANSACTION

Step 1: Remove 500 from Account A
Step 2: Add 500 to Account B
Step 3: COMMIT (save everything)

If anything fails:
  ROLLBACK (undo everything)

Result:
  Either: A=500, B=500 (success)
  Or: A=1000, B=0 (nothing changed)
  
No disaster possible.
```

---

## What is a Transaction?

A transaction is a **group of SQL statements that must all succeed or all fail together**.

Think of it like:
- Buy coffee + get receipt = transaction
- Either you get both or you get neither
- You don't get coffee without paying
- You don't pay without getting coffee

---

## Basic Transaction Syntax

```sql
BEGIN TRANSACTION;
-- or just: BEGIN;

  -- SQL statements here
  INSERT INTO ...;
  UPDATE ...;
  DELETE FROM ...;

COMMIT;
-- or ROLLBACK;
```

---

## Simple Example

### Setup
```sql
CREATE TABLE accounts (
  account_id INT PRIMARY KEY,
  owner VARCHAR(50),
  balance INT
);

INSERT INTO accounts VALUES
(1, 'Rahul', 1000),
(2, 'Priya', 500);
```

### Transaction: Transfer Money

```sql
BEGIN TRANSACTION;

UPDATE accounts SET balance = balance - 500 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 500 WHERE account_id = 2;

COMMIT;
```

**What happened:**
1. Both updates executed
2. COMMIT saved both changes permanently

**Result:**
```
account_id  owner   balance
1           Rahul   500     ← 500 removed
2           Priya   1000    ← 500 added
```

---

## COMMIT — Save Changes

COMMIT means: "I'm happy with these changes. Save them permanently."

```sql
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

COMMIT;
-- Changes are now permanent
-- Even if computer crashes, changes are saved
```

After COMMIT:
- Changes are **permanent**
- Other users can see the changes
- Cannot be undone (must update again if needed)

---

## ROLLBACK — Undo Changes

ROLLBACK means: "Something went wrong. Undo everything since BEGIN."

```sql
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
-- Check: Does account_id 2 exist?
SELECT * FROM accounts WHERE account_id = 2;
-- Result: account_id 2 doesn't exist!

ROLLBACK;
-- Undo the UPDATE
-- account_id 1 balance stays unchanged
```

After ROLLBACK:
- All changes since BEGIN are **undone**
- Database is back to before BEGIN
- Like nothing happened

---

## Real Example: Payroll Processing

```sql
BEGIN TRANSACTION;

-- Step 1: Deduct from company account
UPDATE accounts 
SET balance = balance - 50000 
WHERE account_id = 999;  -- Company account

-- Step 2: Add to employee 1
UPDATE accounts 
SET balance = balance + 25000 
WHERE account_id = 1;

-- Step 3: Add to employee 2
UPDATE accounts 
SET balance = balance + 25000 
WHERE account_id = 2;

-- Step 4: Record the transaction
INSERT INTO payroll_history VALUES 
(NULL, '2024-01-15', 50000, 'Processed');

-- If all 4 steps succeed, save everything
COMMIT;

-- If any step fails, undo all
-- ROLLBACK;
```

**Key point:** Either all 4 happen or none happen. No partial state.

---

## Savepoints — Partial Rollback

Some databases allow SAVEPOINT (not all):

```sql
BEGIN;

INSERT INTO table1 VALUES (1, 'First');

SAVEPOINT sp1;
-- From here, we can rollback just to sp1

INSERT INTO table2 VALUES (2, 'Second');

-- Oops! table2 insert failed or we don't want it
ROLLBACK TO sp1;
-- Undo only table2 insert
-- table1 insert still there

INSERT INTO table3 VALUES (3, 'Third');

COMMIT;
-- table1 and table3 committed
-- table2 not committed
```

**Note:** Not all databases support SAVEPOINT. Check your database.

---

# ACID — Transaction Properties

## What is ACID?

4 properties that make transactions safe:

### A — Atomicity (All or Nothing)

"Atomic" means indivisible.

Either:
- All changes happen ✅
- Or no changes happen ❌

No partial state.

```
Example (Atomic):
Transfer 500 from A to B
Step 1: Remove 500 from A
Step 2: Add 500 to B
COMMIT

Either both step happen, or neither.
Not possible: Step 1 done, Step 2 not done.

Example (Not Atomic):
If you stop after Step 1 and crash
Money is lost.
Transaction prevents this.
```

---

### C — Consistency (Valid State)

Database rules are always followed.

Example:

```sql
CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  salary INT CHECK (salary > 0)
);

BEGIN;
INSERT INTO employees VALUES (1, 50000);  ✅ Valid
INSERT INTO employees VALUES (2, -5000);  ❌ Violates CHECK
COMMIT;

Result: Both inserted fail (Atomicity)
Database stays valid (no negative salary)
```

---

### I — Isolation (Independent Transactions)

Transactions don't interfere with each other.

```
Transaction 1:
BEGIN;
UPDATE account SET balance = 1000;
-- Still in transaction

Transaction 2 (different connection):
BEGIN;
SELECT balance FROM account;
-- What does it see?
-- (Depends on isolation level)

The transactions are isolated — don't see each other's uncommitted changes.
```

---

### D — Durability (Permanent)

Once COMMIT happens, changes stay saved forever.

Even if:
- Computer crashes
- Power goes out
- Disaster happens

Changes are **permanently saved**.

```sql
BEGIN;
UPDATE ... ;
COMMIT;
-- Now even if lightning strikes, data is safe
```

---

# Common Transaction Scenarios

## Scenario 1: Bank Transfer (Safe)

```sql
BEGIN TRANSACTION;

-- Verify both accounts exist
SELECT balance FROM accounts WHERE account_id = 1;
SELECT balance FROM accounts WHERE account_id = 2;

-- Verify account 1 has enough money
SELECT balance FROM accounts WHERE account_id = 1;
-- If balance < 500, ROLLBACK

-- If all checks pass, do transfer
UPDATE accounts SET balance = balance - 500 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 500 WHERE account_id = 2;

-- Record transaction
INSERT INTO transaction_log VALUES (NULL, 1, 2, 500, NOW());

COMMIT;
```

---

## Scenario 2: Inventory Update

```sql
BEGIN TRANSACTION;

-- Step 1: Check inventory
SELECT quantity FROM products WHERE product_id = 1;
-- If quantity < 10, ROLLBACK

-- Step 2: Reduce inventory
UPDATE products SET quantity = quantity - 10 WHERE product_id = 1;

-- Step 3: Add to order
INSERT INTO orders VALUES (NULL, 1, 10, NOW());

-- Step 4: Update order status
UPDATE orders SET status = 'Confirmed' WHERE order_id = LAST_INSERT_ID();

COMMIT;
```

---

## Scenario 3: Employee Transfer Between Departments

```sql
BEGIN TRANSACTION;

-- Step 1: Check employee exists
SELECT * FROM employees WHERE emp_id = 5;
-- If not found, ROLLBACK

-- Step 2: Check new department exists
SELECT * FROM departments WHERE dept_id = 30;
-- If not found, ROLLBACK

-- Step 3: Update employee's department
UPDATE employees SET dept_id = 30 WHERE emp_id = 5;

-- Step 4: Update old department head count
UPDATE departments SET emp_count = emp_count - 1 WHERE dept_id = 10;

-- Step 5: Update new department head count
UPDATE departments SET emp_count = emp_count + 1 WHERE dept_id = 30;

-- Step 6: Record the transfer
INSERT INTO transfer_history VALUES (NULL, 5, 10, 30, NOW());

COMMIT;
```

---

## Scenario 4: E-commerce Order (Complex)

```sql
BEGIN TRANSACTION;

-- Step 1: Create order
INSERT INTO orders (customer_id, order_date, status) 
VALUES (123, NOW(), 'Pending');
SET @order_id = LAST_INSERT_ID();

-- Step 2: Add order items
INSERT INTO order_items VALUES (@order_id, 1, 2, 500);  -- Product 1, qty 2
INSERT INTO order_items VALUES (@order_id, 3, 1, 1000); -- Product 3, qty 1

-- Step 3: Process payment
INSERT INTO payments VALUES (NULL, @order_id, 2000, 'Credit Card', 'Success');

-- Step 4: Update inventory
UPDATE products SET quantity = quantity - 2 WHERE product_id = 1;
UPDATE products SET quantity = quantity - 1 WHERE product_id = 3;

-- Step 5: Confirm order
UPDATE orders SET status = 'Confirmed' WHERE order_id = @order_id;

COMMIT;
```

---

# Isolation Levels

Different levels of protection from other transactions:

## 1. READ UNCOMMITTED (Dangerous)

Can see uncommitted changes from other transactions.

```
Transaction A:
  UPDATE balance = 1000
  -- Not committed yet

Transaction B:
  SELECT balance  -- Sees 1000!
  -- But if Transaction A rolls back, data is wrong (dirty read)
```

**Use:** Never in production

---

## 2. READ COMMITTED (Default)

Only see committed changes.

```
Transaction A:
  UPDATE balance = 1000
  -- Not committed yet

Transaction B:
  SELECT balance  -- Doesn't see 1000 yet
  -- Safe: only sees committed data

Transaction A:
  COMMIT

Transaction B:
  SELECT balance  -- Now sees 1000
  -- Safe
```

**Use:** Most common, good default

---

## 3. REPEATABLE READ

Same data stays same within transaction.

```
Transaction A:
  SELECT balance = 1000
  
Transaction B:
  UPDATE balance = 2000
  COMMIT

Transaction A:
  SELECT balance = 1000  -- Still sees 1000!
  -- Even though B updated it
  -- Data is repeatable
```

**Use:** When consistency is critical

---

## 4. SERIALIZABLE (Strictest)

Transactions run one at a time, completely isolated.

```
Transaction A runs completely
Then Transaction B runs completely
(Like single-threaded)

Safest but slowest.
```

**Use:** When safety is more important than speed

---

## Setting Isolation Level

```sql
-- Set for current session
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Or for single transaction
BEGIN TRANSACTION;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- ... SQL statements
COMMIT;
```

---

# Transaction Best Practices

## 1. Keep Transactions Short

❌ Bad:
```sql
BEGIN TRANSACTION;
INSERT INTO table1 ...;
INSERT INTO table2 ...;
-- Wait for user input here (5 minutes!)
-- Locks held whole time
INSERT INTO table3 ...;
COMMIT;
```

✅ Good:
```sql
-- Do checks first
IF check1 FAIL THEN EXIT
IF check2 FAIL THEN EXIT

-- Then quick transaction
BEGIN TRANSACTION;
INSERT INTO table1 ...;
INSERT INTO table2 ...;
INSERT INTO table3 ...;
COMMIT;
```

---

## 2. Use Proper Isolation Level

```sql
-- Data integrity critical
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Speed is important
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Never use
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
```

---

## 3. Handle Errors

```sql
BEGIN TRANSACTION;

INSERT INTO accounts (id, balance) VALUES (1, 1000);
-- If INSERT fails (e.g., duplicate key)
-- What happens?

COMMIT;
-- The failed INSERT might rollback automatically
-- depending on database

-- Better: explicit error handling
BEGIN TRANSACTION;
  INSERT INTO accounts (id, balance) VALUES (1, 1000);
  IF @@ERROR <> 0 THEN
    ROLLBACK;
    PRINT 'Insert failed'
  ELSE
    COMMIT;
  END IF;
```

---

## 4. Avoid Deadlocks

Deadlock = Two transactions waiting for each other.

```
Transaction A:
  Lock table1
  Waiting for table2...

Transaction B:
  Lock table2
  Waiting for table1...

DEADLOCK! Neither can proceed.
```

**Prevention:**
- Keep transactions short
- Always lock in same order
- Use appropriate isolation level

---

## 5. Don't Mix Manual Commits

```sql
-- ❌ Wrong: confusing
UPDATE employees SET salary = 60000 WHERE emp_id = 1;
COMMIT;

BEGIN TRANSACTION;
UPDATE employees SET salary = 70000 WHERE emp_id = 2;
COMMIT;

-- ✅ Right: consistent style
BEGIN TRANSACTION;
  UPDATE employees SET salary = 60000 WHERE emp_id = 1;
  UPDATE employees SET salary = 70000 WHERE emp_id = 2;
COMMIT;
```

---

# Common Transaction Mistakes

## Mistake 1: Forgetting COMMIT

```sql
-- ❌ Wrong: updates not saved
BEGIN;
UPDATE employees SET salary = 100000 WHERE emp_id = 1;
-- Forgot COMMIT!
-- Changes are not saved
-- Other users can't see changes
-- If you disconnect, changes are lost

-- ✅ Right
BEGIN;
UPDATE employees SET salary = 100000 WHERE emp_id = 1;
COMMIT;
-- Changes saved permanently
```

---

## Mistake 2: Holding Transaction Too Long

```sql
-- ❌ Bad: locks held 10 minutes
BEGIN;
UPDATE big_table SET status = 'processing' ...;
-- Wait for external API (10 minutes)
-- Locks held whole time!
-- Other users blocked
UPDATE big_table SET status = 'done' ...;
COMMIT;

-- ✅ Good: do external call outside transaction
UPDATE big_table SET status = 'pending' WHERE status = NULL LIMIT 1;
-- Do external API call here (no locks)
BEGIN;
UPDATE big_table SET status = 'done' WHERE status = 'pending';
COMMIT;
```

---

## Mistake 3: Wrong Error Handling

```sql
-- ❌ Wrong: might commit even if error
BEGIN;
INSERT INTO table1 ... ;  -- Succeeds
INSERT INTO table2 ... ;  -- Fails
-- What happens? Depends on database
COMMIT;  -- Commits what?

-- ✅ Right: check errors
BEGIN;
INSERT INTO table1 ...;
IF error THEN
  ROLLBACK;
  EXIT;
END;

INSERT INTO table2 ...;
IF error THEN
  ROLLBACK;
  EXIT;
END;

COMMIT;
```

---

## Mistake 4: Nested Transactions (Not Supported)

```sql
-- ❌ Wrong: nested BEGIN not allowed
BEGIN;
  INSERT INTO table1 ...;
  BEGIN;
    INSERT INTO table2 ...;
  COMMIT;
COMMIT;
-- Error: nested transactions not supported (in most databases)

-- ✅ Right: use SAVEPOINT instead
BEGIN;
  INSERT INTO table1 ...;
  SAVEPOINT sp1;
  INSERT INTO table2 ...;
  ROLLBACK TO sp1;  -- Undo only table2
COMMIT;  -- table1 is committed
```

---

# Practice Exercises

## Setup

```sql
CREATE TABLE employees (
  emp_id INT PRIMARY KEY,
  name VARCHAR(50),
  salary INT,
  dept_id INT
);

CREATE TABLE salary_history (
  history_id INT PRIMARY KEY AUTO_INCREMENT,
  emp_id INT,
  old_salary INT,
  new_salary INT,
  change_date DATE,
  FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name VARCHAR(50),
  budget INT
);

INSERT INTO departments VALUES
(10, 'Frontend', 500000),
(20, 'Backend', 600000),
(30, 'DevOps', 400000);

INSERT INTO employees VALUES
(1, 'Rahul', 85000, 10),
(2, 'Priya', 92000, 20),
(3, 'Amit', 78000, 10),
(4, 'Sneha', 65000, NULL);
```

---

## Exercises

### Exercise 1: Simple Salary Increase

```
Task: Increase Rahul's salary to 90000
Record the change in salary_history

Use: BEGIN, UPDATE (2 statements), INSERT, COMMIT
```

### Exercise 2: Department Transfer

```
Task: Move Amit from dept_id 10 to dept_id 20

Use: BEGIN, UPDATE (1 statement), COMMIT
Verify: Amit now in dept_id 20
```

### Exercise 3: Rollback Scenario

```
Task: Try to:
1. Increase Priya's salary to 100000
2. Add entry to salary_history
3. Then ROLLBACK

Use: BEGIN, UPDATE, INSERT, ROLLBACK
Verify: Both are undone (salary unchanged, no history entry)
```

### Exercise 4: Multiple Updates

```
Task: Give all Frontend employees 5000 raise

Use: BEGIN, UPDATE, COMMIT
Verify: Rahul and Amit both got raise
```

### Exercise 5: Atomic Transfer

```
Task: Transfer 10000 from Frontend budget to Backend budget

Use: BEGIN, UPDATE (2 statements for each dept), COMMIT
Verify: Frontend down 10000, Backend up 10000
```

### Exercise 6: Error Handling

```
Task: Try to:
1. Update non-existent emp_id
2. Should rollback automatically

Use: BEGIN, UPDATE (with wrong emp_id), COMMIT
Check: Is error handled?
```

### Exercise 7: Complex Transaction

```
Task: 
1. Increase Sneha's salary to 70000
2. Assign her to dept_id 10
3. Record change in salary_history

Use: BEGIN, UPDATE (salary), UPDATE (dept), INSERT, COMMIT
```

### Exercise 8: SAVEPOINT Practice

```
Task (if database supports SAVEPOINT):
1. BEGIN
2. Update Rahul's salary
3. SAVEPOINT sp1
4. Update Priya's salary
5. ROLLBACK TO sp1
6. COMMIT

Result: Rahul's update committed, Priya's not
```

---

# Summary

| Term | Meaning | Use |
|------|---------|-----|
| BEGIN | Start transaction | Before changes |
| COMMIT | Save changes | When happy |
| ROLLBACK | Undo changes | When error |
| SAVEPOINT | Mark point | Partial undo |
| Atomicity | All or nothing | Safety |
| Consistency | Valid state | Rules |
| Isolation | Independent | Concurrent |
| Durability | Permanent | Reliability |

---

# Golden Rules

```
1. Always use transactions for related changes
2. Keep transactions short
3. COMMIT when successful, ROLLBACK on error
4. Check for errors before COMMIT
5. Use appropriate isolation level
6. Don't hold transactions during I/O
7. Lock in same order always
8. SAVEPOINT for partial rollback (if supported)
```

---

# What's Next?

After mastering transactions:
- Move to 05-data-modeling.md
- Then 06-indexes.md
- Then 07-optimization.md

Transactions are foundation for reliable databases.

---

## Practice Now

1. Copy setup code above
2. Create tables
3. Insert test data
4. Solve all 8 exercises
5. Verify results

**Time: 2-3 hours**

Don't skip transactions. They're critical for real-world databases.

Good luck! 🚀