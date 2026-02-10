# 📦 E-Commerce Web App (Mini Project)

This project is a **mini e-commerce web application** built as part of **DBMS studies**. Users can register, browse products, add to cart, checkout, and review orders. The project is fully functional using **PHP, MySQL, HTML, CSS, and JavaScript**.

---

## 🛠️ Features

* User registration & login
* Product browsing and listing
* Add items to shopping cart
* Checkout and order summary
* Order history / view orders
* Basic admin operations (if applicable)
  (*Expand or remove based on your actual functionality*)

---

## 💻 Tech Stack

| Layer    | Technology            |
| -------- | --------------------- |
| Frontend | HTML, CSS, JavaScript |
| Backend  | PHP                   |
| Database | MySQL                 |
| Server   | Apache / XAMPP / WAMP |

---

## 📁 Project Structure

```
├── admin.php
├── cart.php
├── checkout.php
├── config.php
├── db.php
├── home.php
├── index.php
├── logout.php
├── product.php
├── schema_mysql.sql
├── signup.php
├── view_order.php
└── README.md
```

---

## 🚀 Installation & Setup

### Prerequisites

Make sure you have the following installed:

✔ XAMPP / WAMP / LAMP
✔ MySQL
✔ Git (optional)

---

### Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/mhmdmalik/E_commerce.git
   cd E_commerce
   ```

2. **Move files to server**
   Copy contents into your local server’s `htdocs` (XAMPP) or appropriate web root.

3. **Database Setup**

   * Open **phpMyAdmin**
   * Create a new database (e.g., `ecommerce_db`)
   * Import `schema_mysql.sql`
   * This will create tables and sample data

4. **Configure DB**
   Edit `config.php` and update your database credentials:

   ```php
   $host = "localhost";
   $user = "root";
   $pass = "";
   $db   = "ecommerce_db";
   ```

5. **Start Server**

   * Start Apache & MySQL
   * Visit in browser:
     👉 `http://localhost/E_commerce`

---

## 📌 Screenshots


---

## 🧠 What I Learned

* Building **dynamic pages using PHP**
* Performing **CRUD operations** with MySQL
* Form handling and session management
* Connecting frontend to backend logic
* Basic authentication flow

---

## 📈 Future Improvements

You could add any of the following to make this more professional:

✅ Admin dashboard
✅ Image upload support
✅ Product categories & filters
✅ Payment gateway integration
✅ REST API backend

---



