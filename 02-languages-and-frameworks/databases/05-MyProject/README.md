# My Project Learnings

Document your real project learnings here.

This is the MOST valuable section.

## 📋 Files

### schema.md
Your project's actual database schema

What to include:
- Project name
- Main tables (table name + what it does)
- Key relationships
- Design decisions

Example:
Project: E-commerce Platform
Database: Oracle
Tables:

- users (id, name, email, status)
- products (id, name, price, category)
- orders (id, user_id, order_date, total)
- order_items (id, order_id, product_id, quantity)

Relationships:

- users has many orders
- orders has many order_items
- order_items references products

Design decisions:

- Normalized to 3NF
- Partitioned orders by date
- Denormalized product_name in order_items for speed



### important-queries.md
Real queries you write daily

What to include:
- Query purpose
- The SQL code
- Why it's important
- Performance notes

Example:
Query 1: Monthly Revenue Report
Purpose: Management dashboard
sqlSELECT 
  DATE_TRUNC(order_date, MONTH) as month,
  SUM(total) as revenue
FROM orders
WHERE status = 'completed'
GROUP BY 1
ORDER BY 1 DESC;
Performance: Uses index on order_date, ~500ms
Query 2: Active Users...

### lessons.md
What you learned from real work

What to include:
- Problem you faced
- How you solved it
- What you learned
- What NOT to do

Example:
Lesson 1: Forgot WHERE in UPDATE
Problem: Updated all users instead of one user
Impact: Had to restore from backup
Learning: Always test UPDATE with SELECT first
Prevention: Now I use transactions for everything
Lesson 2: Missing Index on Frequently Searched Column
Problem: User search was taking 10 seconds
Cause: No index on email column
Solution: CREATE INDEX idx_email ON users(email)
Result: Now 50ms
Learning: Always index columns used in WHERE clause
Lesson 3: Denormalization is Sometimes Necessary
Problem: Reports were too slow even with indexes
Cause: Too many JOINs
Solution: Added product_name to order_items table
Result: 5x faster
Learning: Balance between normalization and performance

## 🎯 Why Keep This Updated

- Most relevant to your job
- Best portfolio material
- Interview examples
- Real problems = best learning

## ⏱ When to Add

Add new entries as you encounter them.

Even small learnings count:
- A bug you fixed
- A query you optimized
- A mistake you made
- A pattern you discovered

## 📊 Update Frequency

- Daily: Add 1-2 lines to lessons
- Weekly: Add 1 important query
- Monthly: Review and update schema if it changed

---