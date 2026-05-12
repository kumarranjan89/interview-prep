# Data Modeling — Designing Your Database

**The thing that scares people but is actually simple.**

---

## Why You're Scared

You think:
- "I don't know how many tables to make"
- "I don't know what columns to include"
- "I don't know how to relate tables"
- "I'll design it wrong and regret it later"

Truth:
- **It's not hard, just logical**
- **Same thought process every time**
- **If you mess up, you can fix it**
- **There's no "perfect" design, just "good enough"**

---

## What is Data Modeling?

Planning what tables you need and how they connect.

**Before you write SQL to create tables, you think first.**

Like:
- Architect makes blueprint before building house
- You design database before creating it

---

## The 3 Steps (That's It)

### Step 1: Identify Entities

What things do you need to track?

**Example: School System**

Things you track:
- Students
- Teachers
- Classes
- Marks
- Attendance

Each becomes a **table**.

---

### Step 2: Identify Attributes

What properties does each thing have?

**Student has:**
- Student ID (unique identifier)
- Name
- Email
- Phone
- Class (which class they're in)
- Admission date

**Teacher has:**
- Teacher ID
- Name
- Email
- Subject they teach
- Years of experience

Each becomes a **column**.

---

### Step 3: Identify Relationships

How do entities connect?

**Student to Class:**
- One student is in ONE class
- One class has MANY students
- Relationship: **1-to-Many**

**Teacher to Class:**
- One teacher teaches ONE or MORE classes
- One class has ONE teacher
- Relationship: **1-to-Many**

**Student to Marks:**
- One student has MANY marks
- One mark belongs to ONE student
- Relationship: **1-to-Many**

---

## That's It. Now Let's Design.

---

# Real Example: School Management System

## Step 1: Identify Entities

```
✓ Students
✓ Teachers
✓ Classes
✓ Marks
✓ Subjects
✓ Attendance
```

## Step 2: Define Attributes

### Students Table
```
student_id (unique identifier)
name
email
phone
date_of_birth
admission_date
class_id (which class they're in)
```

### Teachers Table
```
teacher_id (unique identifier)
name
email
phone
subject_id (what subject they teach)
experience_years
salary
```

### Classes Table
```
class_id (unique identifier)
class_name (e.g., "10A", "12B")
teacher_id (who's the class teacher)
room_number
max_capacity
```

### Subjects Table
```
subject_id (unique identifier)
subject_name (e.g., "Math", "English")
description
credits
```

### Marks Table
```
mark_id (unique identifier)
student_id (which student)
subject_id (which subject)
exam_date
marks_obtained
total_marks
percentage
```

### Attendance Table
```
attendance_id (unique identifier)
student_id (which student)
class_date
present_or_absent
remarks
```

## Step 3: Define Relationships

```
Students ─── belongs to ─── Classes
                              │
                              │ taught by
                              │
Teachers ─── teaches ─── Subjects

Students ─── gets ─── Marks ─── in ─── Subjects

Students ─── attends ─── Attendance
```

---

# Visualizing the Design

```
┌─────────────────┐
│    Students     │
├─────────────────┤
│ student_id (PK) │
│ name            │
│ email           │
│ class_id (FK)   │◄───────┐
└─────────────────┘        │
         │                  │
         │ gets             │
         ▼                  │
┌─────────────────┐        │
│     Marks       │        │
├─────────────────┤        │
│ mark_id (PK)    │        │
│ student_id (FK) │        │
│ subject_id (FK) │        │
│ marks_obtained  │        │
└─────────────────┘        │
         │                  │
         │ in               │
         ▼                  │
┌─────────────────┐        │
│    Subjects     │        │
├─────────────────┤        │
│ subject_id (PK) │        │
│ subject_name    │        │
└─────────────────┘        │
         ▲                  │
         │ teaches          │
         │                  │
┌─────────────────┐        │
│    Teachers     │        │
├─────────────────┤        │
│ teacher_id (PK) │        │
│ name            │        │
│ subject_id (FK) │        │
└─────────────────┘        │
                           │
                    ┌──────────────┐
                    │   Classes    │
                    ├──────────────┤
                    │ class_id(PK) │
                    │ class_name   │
                    │ teacher_id   │
                    └──────────────┘
```

---

# Simple Example: E-commerce

## Step 1: What do we track?

```
✓ Customers
✓ Products
✓ Orders
✓ Order Items
✓ Payments
✓ Categories
```

## Step 2: Attributes

### Customers
```
customer_id
name
email
phone
address
city
country
```

### Products
```
product_id
product_name
description
price
category_id
stock_quantity
created_date
```

### Categories
```
category_id
category_name
description
```

### Orders
```
order_id
customer_id
order_date
total_amount
status (pending, confirmed, shipped, delivered)
```

### Order Items
```
order_item_id
order_id
product_id
quantity
unit_price
subtotal
```

### Payments
```
payment_id
order_id
amount
payment_method
payment_date
status (pending, success, failed)
```

## Step 3: Relationships

```
Customers ─── places ─── Orders ─── has ─── Order Items ─── contains ─── Products ─── belongs to ─── Categories

Orders ─── has ─── Payments
```

---

# Key Concepts

## Primary Key (PK)

**Unique identifier for each row.**

```sql
CREATE TABLE students (
  student_id INT PRIMARY KEY,  ← Primary Key
  name VARCHAR(50),
  email VARCHAR(100)
);
```

Rules:
- Must be unique (no duplicates)
- Must not be NULL
- Should not change

**Example:**
- student_id = 1 identifies Rahul
- student_id = 2 identifies Priya
- No two students can have same ID

---

## Foreign Key (FK)

**Reference to another table's primary key.**

```sql
CREATE TABLE marks (
  mark_id INT PRIMARY KEY,
  student_id INT,
  subject_id INT,
  marks_obtained INT,
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
);
```

What it means:
- student_id in marks table must exist in students table
- Prevents invalid data (no marks for non-existent student)

---

## Relationships

### One-to-Many (Most Common)

One parent → Many children

```
Teacher ──── teaches ──── Classes
  (1)                        (many)

One teacher can teach multiple classes
```

```sql
CREATE TABLE classes (
  class_id INT PRIMARY KEY,
  class_name VARCHAR(50),
  teacher_id INT,
  FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id)
);
```

---

### Many-to-Many

Many left ←→ Many right

```
Students ───── take ───── Subjects
  (many)                    (many)

One student can take many subjects
One subject can have many students
```

Solution: Create a **Junction Table**

```sql
CREATE TABLE student_subjects (
  student_id INT,
  subject_id INT,
  enrollment_date DATE,
  PRIMARY KEY (student_id, subject_id),
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
);
```

---

### One-to-One (Rare)

One left → One right

```
Employee ──── has ──── Office
  (1)              (1)

Each employee has one office
Each office belongs to one employee
```

```sql
CREATE TABLE offices (
  office_id INT PRIMARY KEY,
  office_number VARCHAR(20),
  employee_id INT UNIQUE,  ← UNIQUE means one-to-one
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);
```

---

# Common Design Mistakes

## Mistake 1: Storing Repeating Data

❌ BAD Design:

```
students table:
┌────────┬─────────┬──────────────────────────┐
│ stu_id │ name    │ subjects                 │
├────────┼─────────┼──────────────────────────┤
│ 1      │ Rahul   │ Math, English, Science   │ ← BAD!
│ 2      │ Priya   │ Math, Hindi, Art         │ ← BAD!
└────────┴─────────┴──────────────────────────┘

Problems:
- Hard to search (find students taking Math)
- Hard to update (what if subject name changes?)
- Hard to count (how many students take Math?)
```

✅ GOOD Design:

```
students table:
┌────────┬─────────┐
│ stu_id │ name    │
├────────┼─────────┤
│ 1      │ Rahul   │
│ 2      │ Priya   │
└────────┴─────────┘

subjects table:
┌──────┬─────────┐
│ sub_ │ name    │
├──────┼─────────┤
│ 1    │ Math    │
│ 2    │ English │
│ 3    │ Science │
└──────┴─────────┘

enrollments table:
┌────────┬────────┐
│ stu_id │ sub_id │
├────────┼────────┤
│ 1      │ 1      │ ← Rahul takes Math
│ 1      │ 2      │ ← Rahul takes English
│ 1      │ 3      │ ← Rahul takes Science
│ 2      │ 1      │ ← Priya takes Math
│ 2      │ 4      │ ← Priya takes Hindi
└────────┴────────┘
```

---

## Mistake 2: Not Using Primary Keys

❌ BAD:
```sql
CREATE TABLE students (
  name VARCHAR(50),
  email VARCHAR(100)
  -- No primary key!
);
```

Problems:
- Duplicate names allowed
- Can't uniquely identify a student
- Relationships break

✅ GOOD:
```sql
CREATE TABLE students (
  student_id INT PRIMARY KEY,
  name VARCHAR(50),
  email VARCHAR(100)
);
```

---

## Mistake 3: Wrong Relationships

❌ BAD (says one student can only be in one class):
```sql
CREATE TABLE students (
  student_id INT PRIMARY KEY,
  class_id INT  -- What if student changes class?
);
```

✅ GOOD (tracks enrollment history):
```sql
CREATE TABLE enrollments (
  enrollment_id INT PRIMARY KEY,
  student_id INT,
  class_id INT,
  enrollment_date DATE,
  end_date DATE,
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  FOREIGN KEY (class_id) REFERENCES classes(class_id)
);
```

---

## Mistake 4: Too Much Data in One Table

❌ BAD:
```
orders table:
order_id, customer_name, customer_email, customer_phone, 
product_name, product_price, quantity, total_amount, 
payment_method, payment_date, shipping_address, shipping_city
-- Everything crammed in one table!
```

Problems:
- Data repetition (customer info repeated for each order)
- Hard to update
- Wasted storage

✅ GOOD (normalize into multiple tables):
```
customers table: customer info
products table: product info
orders table: order info (references customers)
order_items table: what's in each order (references products)
payments table: payment info
```

---

# The Design Process (Step by Step)

## Example: Hotel Booking System

### Step 1: Write Down Everything

What do we need to track?
- Guests who make reservations
- Hotels with details
- Rooms in each hotel
- Bookings (reservations)
- Payments for bookings
- Reviews/ratings

### Step 2: List Attributes for Each

**Guests:**
- guest_id, name, email, phone, country, preferred_language

**Hotels:**
- hotel_id, name, address, city, country, star_rating, contact_phone

**Rooms:**
- room_id, hotel_id, room_number, room_type, price_per_night, capacity, amenities

**Bookings:**
- booking_id, guest_id, room_id, check_in_date, check_out_date, status

**Payments:**
- payment_id, booking_id, amount, payment_date, payment_method, status

**Reviews:**
- review_id, guest_id, hotel_id, rating, comment, review_date

### Step 3: Draw Relationships

```
Guests ──── makes ──── Bookings ──── for ──── Rooms ──── in ──── Hotels
 (1)          (many)      (1)            (1)      (1)       (many)   (1)

Bookings ──── has ──── Payments
  (1)           (many)

Guests ──── writes ──── Reviews ──── about ──── Hotels
 (many)              (many)              (many)
```

### Step 4: Create SQL

```sql
CREATE TABLE guests (
  guest_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100),
  phone VARCHAR(20),
  country VARCHAR(50)
);

CREATE TABLE hotels (
  hotel_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  address VARCHAR(200),
  city VARCHAR(50),
  star_rating INT,
  contact_phone VARCHAR(20)
);

CREATE TABLE rooms (
  room_id INT PRIMARY KEY AUTO_INCREMENT,
  hotel_id INT NOT NULL,
  room_number VARCHAR(10),
  room_type VARCHAR(50),
  price_per_night INT,
  capacity INT,
  FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);

CREATE TABLE bookings (
  booking_id INT PRIMARY KEY AUTO_INCREMENT,
  guest_id INT NOT NULL,
  room_id INT NOT NULL,
  check_in_date DATE,
  check_out_date DATE,
  status VARCHAR(20),
  FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
  FOREIGN KEY (room_id) REFERENCES rooms(room_id)
);

CREATE TABLE payments (
  payment_id INT PRIMARY KEY AUTO_INCREMENT,
  booking_id INT NOT NULL,
  amount INT,
  payment_date DATE,
  payment_method VARCHAR(50),
  status VARCHAR(20),
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

CREATE TABLE reviews (
  review_id INT PRIMARY KEY AUTO_INCREMENT,
  guest_id INT NOT NULL,
  hotel_id INT NOT NULL,
  rating INT,
  comment TEXT,
  review_date DATE,
  FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
  FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);
```

Done. That's it. No magic. Just logic.

---

# Key Questions to Ask

When designing, always ask:

### 1. What am I tracking?
- What entities exist?
- What things do I need to store?

### 2. What properties matter?
- What data do I need about each entity?
- What's important and what's not?

### 3. How do they relate?
- Does A need to know about B?
- Is it 1-to-1, 1-to-many, or many-to-many?

### 4. Can I join them later?
- If data is in separate tables, can I join them when needed?
- Yes? Then separate.
- No? Then maybe they should be together.

### 5. Does this prevent bad data?
- Can invalid data enter?
- Do relationships prevent it?

---

# Common Design Patterns

## Pattern 1: User/Account System

```
users table:
  user_id (PK)
  username (unique)
  email (unique)
  password_hash
  created_date

profiles table:
  profile_id (PK)
  user_id (FK)
  first_name
  last_name
  phone
  address
  profile_picture

Why separate?
- Keep user credentials separate from personal info
- Security: limit who sees password_hash
- Flexibility: add profile info without touching users
```

---

## Pattern 2: Hierarchical Data

```
categories table:
  category_id (PK)
  category_name
  parent_category_id (FK to itself!)

Example:
Electronics (id=1)
  ├─ Phones (id=2, parent=1)
  │  ├─ iPhone (id=4, parent=2)
  │  └─ Android (id=5, parent=2)
  └─ Laptops (id=3, parent=1)
```

---

## Pattern 3: Audit Trail

```
employees table:
  employee_id (PK)
  name
  salary

salary_history table:
  history_id (PK)
  employee_id (FK)
  old_salary
  new_salary
  change_date
  changed_by

Why?
- Track all changes
- Who changed it, when
- Can revert if needed
```

---

# Practice Design Exercise

## Design: Online Library System

Think about what you need:

1. **Identify entities** (users, books, authors, etc.)
2. **List attributes** (what info about each)
3. **Draw relationships** (1-to-1, 1-to-many, many-to-many)
4. **Write SQL** (CREATE TABLE statements)

Requirements:
- Users can borrow books
- Books have authors (one book can have multiple authors)
- Librarians track who borrowed what, when
- Users can review books
- System tracks available copies

**Try designing this yourself first, then see solution below.**

---

## Solution: Online Library System

### Entities
```
✓ Users (members)
✓ Books
✓ Authors
✓ Borrowing (who borrowed what when)
✓ Reviews
✓ Copies (physical copies of each book)
```

### SQL Design

```sql
CREATE TABLE authors (
  author_id INT PRIMARY KEY AUTO_INCREMENT,
  author_name VARCHAR(100),
  biography TEXT
);

CREATE TABLE books (
  book_id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(200),
  isbn VARCHAR(20) UNIQUE,
  publication_date DATE,
  total_copies INT
);

CREATE TABLE book_authors (
  book_id INT,
  author_id INT,
  PRIMARY KEY (book_id, author_id),
  FOREIGN KEY (book_id) REFERENCES books(book_id),
  FOREIGN KEY (author_id) REFERENCES authors(author_id)
);

CREATE TABLE copies (
  copy_id INT PRIMARY KEY AUTO_INCREMENT,
  book_id INT,
  barcode VARCHAR(50) UNIQUE,
  status VARCHAR(20),  -- available, borrowed, damaged
  FOREIGN KEY (book_id) REFERENCES books(book_id)
);

CREATE TABLE users (
  user_id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  email VARCHAR(100),
  phone VARCHAR(20),
  membership_date DATE
);

CREATE TABLE borrowings (
  borrowing_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT,
  copy_id INT,
  borrow_date DATE,
  due_date DATE,
  return_date DATE,
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (copy_id) REFERENCES copies(copy_id)
);

CREATE TABLE reviews (
  review_id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT,
  book_id INT,
  rating INT,
  comment TEXT,
  review_date DATE,
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (book_id) REFERENCES books(book_id)
);
```

---

# The Fear Ends Here

## Why you were scared:

```
"I don't know how many tables"
→ Count entities. That's how many tables.

"I don't know what columns"
→ List properties of each entity. Those are columns.

"I don't know relationships"
→ Ask: Does one X have many Y? That's the relationship.

"I'll design it wrong"
→ You can change it. It's not set in stone.
```

## Truth:

**Data modeling is just organized thinking.**

You already think like this:
- "A student is in a class"
- "A teacher teaches many students"
- "A student takes many subjects"

That's all data modeling is.

---

# Summary

```
Step 1: Identify entities (things you track)
Step 2: List attributes (properties of each)
Step 3: Find relationships (how they connect)
Step 4: Create tables (write SQL)

Repeat for every new system.
```

---

# What's Next?

After data modeling:
- Move to 06-indexes.md (speed optimization)
- Then 07-optimization.md (query tuning)

But practice these designs first. Design 3 systems:
1. School
2. E-commerce
3. Hotel

Good luck! 🚀