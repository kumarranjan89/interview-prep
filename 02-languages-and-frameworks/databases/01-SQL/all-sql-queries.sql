-- ============================================================
-- all-sql-queries.sql
-- Complete SQL reference — all 7 topics in one file
-- Copy any query, run in your database
-- ============================================================

-- ============================================================
-- SETUP — Run this first
-- Creates tables and sample data used in all examples
-- ============================================================

CREATE TABLE departments (
  dept_id   INT PRIMARY KEY,
  dept_name VARCHAR(50),
  location  VARCHAR(50),
  budget    INT
);

CREATE TABLE employees (
  emp_id    INT PRIMARY KEY,
  name      VARCHAR(50),
  salary    INT,
  dept_id   INT,
  hire_date DATE,
  FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE salary_history (
  history_id  INT PRIMARY KEY AUTO_INCREMENT,
  emp_id      INT,
  old_salary  INT,
  new_salary  INT,
  change_date DATE,
  FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

CREATE TABLE projects (
  project_id   INT PRIMARY KEY,
  project_name VARCHAR(100),
  dept_id      INT,
  budget       INT,
  FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- Sample Data
INSERT INTO departments VALUES
(10, 'Frontend', 'Bangalore', 500000),
(20, 'Backend',  'Hyderabad', 600000),
(30, 'DevOps',   'Pune',      400000),
(40, 'Design',   'Mumbai',    300000);

INSERT INTO employees VALUES
(1, 'Rahul',  85000, 10, '2020-01-15'),
(2, 'Priya',  92000, 20, '2019-03-20'),
(3, 'Amit',   78000, 10, '2021-06-10'),
(4, 'Sneha',  65000, NULL, '2022-02-05'),
(5, 'Vikram', 88000, 30, '2020-09-12'),
(6, 'Neha',   72000, 20, '2023-01-08');

INSERT INTO projects VALUES
(1, 'App Redesign',   10, 200000),
(2, 'API Migration',  20, 300000),
(3, 'CI/CD Pipeline', 30, 150000);

-- ============================================================
-- TOPIC 1: BASICS — SELECT and WHERE
-- ============================================================

-- Get all rows, all columns
SELECT * FROM employees;

-- Get specific columns only
SELECT name, salary FROM employees;

-- Filter with WHERE
SELECT name, salary FROM employees
WHERE salary > 80000;

-- Equal condition
SELECT name FROM employees
WHERE dept_id = 10;

-- Not equal
SELECT name FROM employees
WHERE dept_id != 10;

-- Less than
SELECT name, salary FROM employees
WHERE salary < 80000;

-- AND condition (both must be true)
SELECT name, salary FROM employees
WHERE dept_id = 10 AND salary > 80000;

-- OR condition (at least one must be true)
SELECT name FROM employees
WHERE dept_id = 10 OR dept_id = 20;

-- IN (cleaner OR)
SELECT name FROM employees
WHERE dept_id IN (10, 20, 30);

-- BETWEEN
SELECT name, salary FROM employees
WHERE salary BETWEEN 70000 AND 90000;

-- LIKE — starts with
SELECT name FROM employees
WHERE name LIKE 'R%';

-- LIKE — ends with
SELECT name FROM employees
WHERE name LIKE '%a';

-- LIKE — contains
SELECT name FROM employees
WHERE name LIKE '%am%';

-- NULL check
SELECT name FROM employees
WHERE dept_id IS NULL;

-- NOT NULL check
SELECT name FROM employees
WHERE dept_id IS NOT NULL;

-- ORDER BY ascending (default)
SELECT name, salary FROM employees
ORDER BY salary;

-- ORDER BY descending
SELECT name, salary FROM employees
ORDER BY salary DESC;

-- LIMIT — top N rows
SELECT name, salary FROM employees
ORDER BY salary DESC
LIMIT 3;

-- Combined query
SELECT name, salary
FROM employees
WHERE dept_id = 10
ORDER BY salary DESC
LIMIT 2;

-- ============================================================
-- TOPIC 2: JOIN
-- ============================================================

-- INNER JOIN — matching rows only
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- LEFT JOIN — all employees, even without department
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- RIGHT JOIN — all departments, even without employees
SELECT e.name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- FULL OUTER JOIN — everything
SELECT e.name, d.dept_name
FROM employees e
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id;

-- Find employees WITHOUT a department
SELECT e.name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

-- Find departments WITH NO employees
SELECT d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

-- Multi-table JOIN
SELECT e.name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;

-- JOIN with WHERE filter
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Bangalore';

-- JOIN with ORDER BY
SELECT e.name, e.salary, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
ORDER BY e.salary DESC;

-- ============================================================
-- TOPIC 3: INSERT, UPDATE, DELETE
-- ============================================================

-- INSERT single row
INSERT INTO departments (dept_id, dept_name, location, budget)
VALUES (50, 'QA', 'Chennai', 250000);

-- INSERT multiple rows at once
INSERT INTO employees (emp_id, name, salary, dept_id, hire_date)
VALUES
(7, 'Rohan', 81000, 10, '2023-05-01'),
(8, 'Kavya', 76000, 20, '2023-06-15');

-- UPDATE single row (always use WHERE)
UPDATE employees
SET salary = 90000
WHERE emp_id = 1;

-- UPDATE multiple columns
UPDATE employees
SET salary = 95000, dept_id = 20
WHERE emp_id = 1;

-- UPDATE multiple rows
UPDATE employees
SET salary = salary + 5000
WHERE dept_id = 10;

-- UPDATE with condition
UPDATE employees
SET salary = 75000
WHERE salary < 70000 AND dept_id = 20;

-- DELETE single row (always use WHERE)
DELETE FROM employees
WHERE emp_id = 8;

-- DELETE multiple rows
DELETE FROM employees
WHERE dept_id = 50;

-- SAFE DELETE — check first, then delete
SELECT * FROM employees WHERE dept_id = 40;    -- Step 1: verify
SELECT COUNT(*) FROM employees WHERE dept_id = 40;  -- Step 2: count
DELETE FROM employees WHERE dept_id = 40;       -- Step 3: delete

-- DELETE with parent-child order
DELETE FROM employees WHERE dept_id = 50;       -- Child first
DELETE FROM departments WHERE dept_id = 50;     -- Parent second

-- ============================================================
-- TOPIC 4: TRANSACTIONS
-- ============================================================

-- Basic transaction
BEGIN TRANSACTION;
  UPDATE employees SET salary = 90000 WHERE emp_id = 1;
  INSERT INTO salary_history (emp_id, old_salary, new_salary, change_date)
  VALUES (1, 85000, 90000, CURDATE());
COMMIT;

-- Rollback example
BEGIN TRANSACTION;
  UPDATE employees SET salary = 50000 WHERE emp_id = 1;
  -- Something went wrong, undo everything
ROLLBACK;

-- Transfer budget between departments
BEGIN TRANSACTION;
  UPDATE departments SET budget = budget - 50000 WHERE dept_id = 10;
  UPDATE departments SET budget = budget + 50000 WHERE dept_id = 20;
COMMIT;

-- Employee department transfer
BEGIN TRANSACTION;
  UPDATE employees SET dept_id = 20 WHERE emp_id = 3;
  INSERT INTO salary_history (emp_id, old_salary, new_salary, change_date)
  VALUES (3, 78000, 78000, CURDATE());
COMMIT;

-- Savepoint (partial rollback)
BEGIN TRANSACTION;
  UPDATE employees SET salary = 95000 WHERE emp_id = 1;
  SAVEPOINT sp1;
  UPDATE employees SET salary = 80000 WHERE emp_id = 2;
  ROLLBACK TO sp1;  -- Undo only emp_id 2 update
COMMIT;             -- emp_id 1 update committed

-- ============================================================
-- TOPIC 5: DATA MODELING
-- ============================================================

-- One-to-many relationship example
CREATE TABLE categories (
  category_id   INT PRIMARY KEY,
  category_name VARCHAR(50)
);

CREATE TABLE products (
  product_id   INT PRIMARY KEY,
  product_name VARCHAR(100),
  price        INT,
  category_id  INT,
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Many-to-many relationship (junction table)
CREATE TABLE students (
  student_id INT PRIMARY KEY,
  name       VARCHAR(50)
);

CREATE TABLE subjects (
  subject_id   INT PRIMARY KEY,
  subject_name VARCHAR(50)
);

CREATE TABLE enrollments (
  student_id      INT,
  subject_id      INT,
  enrollment_date DATE,
  PRIMARY KEY (student_id, subject_id),
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
);

-- One-to-one relationship
CREATE TABLE employee_details (
  detail_id    INT PRIMARY KEY,
  emp_id       INT UNIQUE,
  address      VARCHAR(200),
  emergency_contact VARCHAR(50),
  FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

-- Hierarchical data (self-referencing)
CREATE TABLE org_chart (
  emp_id    INT PRIMARY KEY,
  name      VARCHAR(50),
  manager_id INT,
  FOREIGN KEY (manager_id) REFERENCES org_chart(emp_id)
);

-- Audit trail pattern
CREATE TABLE employee_audit (
  audit_id    INT PRIMARY KEY AUTO_INCREMENT,
  emp_id      INT,
  action      VARCHAR(10),
  changed_at  DATETIME,
  changed_by  VARCHAR(50),
  old_salary  INT,
  new_salary  INT
);

-- ============================================================
-- TOPIC 6: INDEXES
-- ============================================================

-- Create basic index
CREATE INDEX idx_salary ON employees(salary);

-- Create index on foreign key (always do this)
CREATE INDEX idx_emp_dept ON employees(dept_id);

-- Unique index
CREATE UNIQUE INDEX idx_emp_email ON employees(name);

-- Composite index (most filtered column first)
CREATE INDEX idx_dept_salary ON employees(dept_id, salary);

-- Check EXPLAIN before index
EXPLAIN SELECT name FROM employees WHERE salary > 80000;

-- Check EXPLAIN after index (should show key=idx_salary)
EXPLAIN SELECT name FROM employees WHERE salary > 80000;

-- Drop an index
DROP INDEX idx_salary ON employees;

-- Show all indexes on a table
SHOW INDEXES FROM employees;

-- Composite index covers these queries:
SELECT name FROM employees WHERE dept_id = 10;
SELECT name FROM employees WHERE dept_id = 10 AND salary > 80000;
-- But NOT this (wrong order):
-- SELECT name FROM employees WHERE salary > 80000;

-- ============================================================
-- TOPIC 7: OPTIMIZATION
-- ============================================================

-- EXPLAIN — check query plan
EXPLAIN SELECT name, salary FROM employees WHERE dept_id = 10;

-- BAD: SELECT * (avoid)
SELECT * FROM employees WHERE dept_id = 10;

-- GOOD: Specific columns
SELECT name, salary FROM employees WHERE dept_id = 10;

-- BAD: Subquery (slower)
SELECT name FROM employees
WHERE dept_id IN (
  SELECT dept_id FROM departments WHERE location = 'Bangalore'
);

-- GOOD: JOIN (faster)
SELECT e.name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Bangalore';

-- BAD: Function on column (index not used)
SELECT name FROM employees
WHERE YEAR(hire_date) = 2020;

-- GOOD: Range condition (index used)
SELECT name FROM employees
WHERE hire_date >= '2020-01-01'
  AND hire_date < '2021-01-01';

-- BAD: Leading wildcard (full scan)
SELECT name FROM employees WHERE name LIKE '%Rahul%';

-- GOOD: Trailing wildcard (index used)
SELECT name FROM employees WHERE name LIKE 'Rahul%';

-- BAD: Multiple OR
SELECT name FROM employees
WHERE dept_id = 10 OR dept_id = 20 OR dept_id = 30;

-- GOOD: IN (cleaner + faster)
SELECT name FROM employees
WHERE dept_id IN (10, 20, 30);

-- BAD: OFFSET pagination (slow on large pages)
SELECT * FROM employees ORDER BY emp_id LIMIT 10 OFFSET 10000;

-- GOOD: Keyset pagination (always fast)
SELECT * FROM employees
WHERE emp_id > 10000
ORDER BY emp_id
LIMIT 10;

-- GROUP BY with aggregate functions
SELECT dept_id, COUNT(*) as emp_count, AVG(salary) as avg_salary
FROM employees
GROUP BY dept_id;

-- GROUP BY with HAVING (filter after grouping)
SELECT dept_id, AVG(salary) as avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) > 80000;

-- CTE (Common Table Expression) — clean complex queries
WITH dept_avg AS (
  SELECT dept_id, AVG(salary) AS avg_salary
  FROM employees
  GROUP BY dept_id
)
SELECT e.name, e.salary, da.avg_salary
FROM employees e
INNER JOIN dept_avg da ON e.dept_id = da.dept_id
WHERE e.salary > da.avg_salary;

-- Window function — rank employees by salary
SELECT
  name,
  salary,
  dept_id,
  RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) as rank_in_dept
FROM employees;

-- Window function — running total
SELECT
  name,
  salary,
  SUM(salary) OVER (ORDER BY emp_id) as running_total
FROM employees;

-- Subquery in SELECT (use sparingly)
SELECT
  name,
  salary,
  (SELECT AVG(salary) FROM employees) as company_avg
FROM employees;

-- ============================================================
-- QUICK REFERENCE QUERIES
-- ============================================================

-- Count rows
SELECT COUNT(*) FROM employees;

-- Count non-null values
SELECT COUNT(dept_id) FROM employees;

-- Sum
SELECT SUM(salary) FROM employees;

-- Average
SELECT AVG(salary) FROM employees;

-- Min / Max
SELECT MIN(salary), MAX(salary) FROM employees;

-- Group and count
SELECT dept_id, COUNT(*) FROM employees GROUP BY dept_id;

-- Top earner per department
SELECT dept_id, MAX(salary) as top_salary
FROM employees
GROUP BY dept_id;

-- Employees above average salary
SELECT name, salary FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Duplicate check
SELECT name, COUNT(*) as count
FROM employees
GROUP BY name
HAVING COUNT(*) > 1;

-- Date filtering
SELECT name FROM employees
WHERE hire_date >= '2022-01-01';

-- Current date
SELECT name FROM employees
WHERE hire_date = CURDATE();

-- This year's hires
SELECT name FROM employees
WHERE YEAR(hire_date) = YEAR(CURDATE());

-- ============================================================
-- END OF FILE
-- ============================================================