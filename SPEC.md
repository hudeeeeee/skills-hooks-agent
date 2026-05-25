# SPEC: WEBSITE THƯƠNG MẠI ĐIỆN TỬ BÁN ĐỒ ĐIỆN TỬ
## Đồ Án Tốt Nghiệp

---

## MỤC LỤC

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Kiến trúc hệ thống](#2-kiến-trúc-hệ-thống)
3. [Cơ sở dữ liệu](#3-cơ-sở-dữ-liệu)
4. [Vai trò & Phân quyền](#4-vai-trò--phân-quyền)
5. [Luồng tổng quan hệ thống](#5-luồng-tổng-quan-hệ-thống)
6. [Skills](#6-skills)
7. [Hooks](#7-hooks)
8. [State Machines](#8-state-machines)
9. [Acceptance Criteria](#9-acceptance-criteria)
10. [Seed Data](#10-seed-data)
11. [Prompt ngắn cho Agent](#11-prompt-ngắn-cho-agent)

---

## 1. TỔNG QUAN DỰ ÁN

### 1.1 Mục tiêu

Xây dựng website thương mại điện tử bán đồ điện tử phục vụ nhu cầu mua sắm trực tuyến. Sản phẩm bao gồm điện thoại, laptop, tablet, tai nghe, TV, thiết bị gaming, máy ảnh, đồng hồ thông minh và phụ kiện điện tử.

### 1.2 Phạm vi chức năng

```
KHÁCH HÀNG:
  - Xem / tìm kiếm / lọc sản phẩm
  - Đăng ký / đăng nhập / quản lý tài khoản
  - Giỏ hàng → Đặt hàng → Thanh toán
  - Theo dõi đơn hàng / hủy đơn
  - Đánh giá sản phẩm
  - Gửi yêu cầu bảo hành

QUẢN TRỊ VIÊN:
  - Quản lý danh mục / sản phẩm / tồn kho
  - Quản lý đơn hàng / trạng thái giao hàng
  - Quản lý người dùng
  - Xem thống kê doanh thu
  - Quản lý đánh giá / bảo hành
```

### 1.3 Công nghệ Stack

```
BACKEND:
  Runtime      : Node.js
  Framework    : Express.js
  View Engine  : EJS
  Auth         : express-session + bcrypt
  Upload       : multer
  Env          : dotenv
  DB Client    : mysql2

DATABASE:
  RDBMS        : MySQL
  Admin Tool   : phpMyAdmin hoặc MySQL Workbench

FRONTEND:
  Markup       : HTML5 + EJS partials
  Style        : CSS3 + Bootstrap 5
  Script       : Vanilla JavaScript

PAYMENT:
  COD          : mặc định
  Bank Transfer: hướng dẫn chuyển khoản thủ công
  VNPay        : sandbox (tuỳ chọn)
```

---

## 2. KIẾN TRÚC HỆ THỐNG

### 2.1 Sơ đồ tổng quan

```
┌─────────────────────────────────────────────────────────┐
│                      CLIENT BROWSER                     │
│   HTML/CSS/JS  ←→  EJS Rendered Pages  ←→  AJAX calls  │
└───────────────────────────┬─────────────────────────────┘
                            │ HTTP Request/Response
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    EXPRESS.JS SERVER                    │
│                                                         │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Routes  │→ │ Middlewares  │→ │   Controllers    │  │
│  └──────────┘  └──────────────┘  └────────┬─────────┘  │
│                                           │             │
│                                  ┌────────▼─────────┐  │
│                                  │    Services      │  │
│                                  └────────┬─────────┘  │
│                                           │             │
│                                  ┌────────▼─────────┐  │
│                                  │     Models       │  │
│                                  └────────┬─────────┘  │
└───────────────────────────────────────────┼─────────────┘
                            │ SQL Queries
                            ▼
┌─────────────────────────────────────────────────────────┐
│                      MySQL DATABASE                     │
│  users │ products │ orders │ payments │ reviews │ ...   │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                 FILE SYSTEM (uploads/)                  │
│              Ảnh sản phẩm lưu local disk                │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Cấu trúc thư mục dự án

```
project-root/
│
├── src/
│   ├── config/
│   │   ├── database.js          # Kết nối MySQL (mysql2/promise pool)
│   │   └── env.js               # Load và validate biến môi trường
│   │
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── product.controller.js
│   │   ├── cart.controller.js
│   │   ├── order.controller.js
│   │   ├── payment.controller.js
│   │   ├── review.controller.js
│   │   ├── warranty.controller.js
│   │   └── admin/
│   │       ├── dashboard.controller.js
│   │       ├── product.controller.js
│   │       ├── order.controller.js
│   │       ├── user.controller.js
│   │       └── review.controller.js
│   │
│   ├── middlewares/
│   │   ├── auth.middleware.js    # requireAuth — redirect /login nếu chưa đăng nhập
│   │   ├── admin.middleware.js   # requireAdmin — 403 nếu không phải admin
│   │   ├── upload.middleware.js  # multer config: jpg/png, max 5MB
│   │   └── error.middleware.js   # Global error handler
│   │
│   ├── models/
│   │   ├── User.js
│   │   ├── Category.js
│   │   ├── Product.js
│   │   ├── ProductImage.js
│   │   ├── Cart.js
│   │   ├── CartItem.js
│   │   ├── Order.js
│   │   ├── OrderItem.js
│   │   ├── Payment.js
│   │   ├── Review.js
│   │   ├── Address.js
│   │   └── WarrantyRequest.js
│   │
│   ├── routes/
│   │   ├── index.routes.js      # Mount tất cả routes
│   │   ├── auth.routes.js
│   │   ├── product.routes.js
│   │   ├── cart.routes.js
│   │   ├── order.routes.js
│   │   ├── payment.routes.js
│   │   ├── review.routes.js
│   │   └── admin.routes.js
│   │
│   ├── services/
│   │   ├── auth.service.js
│   │   ├── product.service.js
│   │   ├── cart.service.js
│   │   ├── order.service.js
│   │   ├── payment.service.js
│   │   └── review.service.js
│   │
│   ├── views/
│   │   ├── layouts/
│   │   │   ├── main.ejs         # Layout công khai: header + footer
│   │   │   └── admin.ejs        # Layout admin: sidebar + topbar
│   │   ├── partials/
│   │   │   ├── header.ejs
│   │   │   ├── footer.ejs
│   │   │   ├── navbar.ejs
│   │   │   ├── flash.ejs        # Thông báo success/error
│   │   │   └── pagination.ejs
│   │   ├── pages/
│   │   │   ├── home.ejs
│   │   │   ├── products/
│   │   │   ├── cart.ejs
│   │   │   ├── checkout.ejs
│   │   │   ├── orders/
│   │   │   └── profile/
│   │   ├── auth/
│   │   │   ├── login.ejs
│   │   │   ├── register.ejs
│   │   │   └── forgot-password.ejs
│   │   └── admin/
│   │       ├── dashboard.ejs
│   │       ├── products/
│   │       ├── orders/
│   │       ├── users/
│   │       └── reviews/
│   │
│   └── utils/
│       ├── password.js          # bcrypt hash/compare
│       ├── slug.js              # Tạo slug từ tên sản phẩm/danh mục
│       ├── formatCurrency.js    # Format VND
│       ├── paginate.js          # Helper phân trang
│       └── validators.js        # Validate email, phone, số lượng
│
├── public/
│   ├── css/
│   ├── js/
│   ├── images/
│   └── uploads/                 # Ảnh sản phẩm upload
│
├── database/
│   ├── schema.sql               # DDL toàn bộ bảng
│   └── seed.sql                 # Dữ liệu mẫu
│
├── .env                         # Biến môi trường (không commit)
├── .env.example                 # Template .env
├── app.js                       # Khởi tạo Express app
├── server.js                    # Listen port
└── README.md
```

---

## 3. CƠ SỞ DỮ LIỆU

### 3.1 Danh sách bảng

| STT | Bảng | Mô tả |
|-----|------|-------|
| 1 | users | Tài khoản khách hàng và admin |
| 2 | addresses | Địa chỉ giao hàng của user |
| 3 | categories | Danh mục sản phẩm (hỗ trợ nested) |
| 4 | products | Sản phẩm |
| 5 | product_images | Ảnh sản phẩm (nhiều ảnh / sản phẩm) |
| 6 | carts | Giỏ hàng (1 user - 1 cart active) |
| 7 | cart_items | Chi tiết sản phẩm trong giỏ |
| 8 | orders | Đơn hàng |
| 9 | order_items | Chi tiết sản phẩm trong đơn |
| 10 | payments | Giao dịch thanh toán |
| 11 | reviews | Đánh giá sản phẩm |
| 12 | warranty_requests | Yêu cầu bảo hành |

### 3.2 Chi tiết từng bảng

#### Bảng: users

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| full_name | VARCHAR(100) | NOT NULL | Họ tên đầy đủ |
| email | VARCHAR(150) | NOT NULL, UNIQUE | Email đăng nhập |
| phone | VARCHAR(15) | NULL | Số điện thoại |
| password_hash | VARCHAR(255) | NOT NULL | bcrypt hash |
| role | ENUM('customer','admin') | NOT NULL, DEFAULT 'customer' | Vai trò |
| status | ENUM('active','blocked') | NOT NULL, DEFAULT 'active' | Trạng thái |
| avatar_url | VARCHAR(255) | NULL | Ảnh đại diện |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | DATETIME | ON UPDATE CURRENT_TIMESTAMP | |

#### Bảng: addresses

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| user_id | INT UNSIGNED | FK → users.id | |
| receiver_name | VARCHAR(100) | NOT NULL | Tên người nhận |
| receiver_phone | VARCHAR(15) | NOT NULL | SĐT người nhận |
| province | VARCHAR(100) | NOT NULL | Tỉnh/Thành phố |
| district | VARCHAR(100) | NOT NULL | Quận/Huyện |
| ward | VARCHAR(100) | NOT NULL | Phường/Xã |
| detail | VARCHAR(255) | NOT NULL | Số nhà, tên đường |
| is_default | TINYINT(1) | DEFAULT 0 | Địa chỉ mặc định |

#### Bảng: categories

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL | Tên danh mục |
| slug | VARCHAR(120) | NOT NULL, UNIQUE | URL-friendly |
| description | TEXT | NULL | Mô tả |
| parent_id | INT UNSIGNED | FK → categories.id, NULL | Danh mục cha |
| image_url | VARCHAR(255) | NULL | Ảnh danh mục |
| status | ENUM('active','inactive') | DEFAULT 'active' | |
| sort_order | INT | DEFAULT 0 | Thứ tự hiển thị |

#### Bảng: products

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| category_id | INT UNSIGNED | FK → categories.id | |
| name | VARCHAR(200) | NOT NULL | Tên sản phẩm |
| slug | VARCHAR(220) | NOT NULL, UNIQUE | URL-friendly |
| brand | VARCHAR(100) | NULL | Thương hiệu |
| sku | VARCHAR(50) | NULL, UNIQUE | Mã sản phẩm |
| price | DECIMAL(15,0) | NOT NULL | Giá gốc (VND) |
| sale_price | DECIMAL(15,0) | NULL | Giá khuyến mãi |
| stock_quantity | INT | NOT NULL, DEFAULT 0 | Tồn kho |
| description | TEXT | NULL | Mô tả chi tiết |
| specifications | TEXT | NULL | Thông số kỹ thuật (JSON string) |
| warranty_months | INT | DEFAULT 0 | Thời gian bảo hành (tháng) |
| avg_rating | DECIMAL(3,2) | DEFAULT 0.00 | Rating trung bình |
| review_count | INT | DEFAULT 0 | Số lượt đánh giá |
| status | ENUM('active','inactive','out_of_stock') | DEFAULT 'active' | |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | DATETIME | ON UPDATE CURRENT_TIMESTAMP | |

```
INDEX: (category_id), (slug), (status), (brand), FULLTEXT(name, description)
```

#### Bảng: product_images

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| product_id | INT UNSIGNED | FK → products.id, ON DELETE CASCADE | |
| image_url | VARCHAR(255) | NOT NULL | Đường dẫn ảnh |
| is_main | TINYINT(1) | DEFAULT 0 | Ảnh đại diện |
| sort_order | INT | DEFAULT 0 | Thứ tự hiển thị |

#### Bảng: carts

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| user_id | INT UNSIGNED | FK → users.id, UNIQUE | 1 cart / user |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | DATETIME | ON UPDATE CURRENT_TIMESTAMP | |

#### Bảng: cart_items

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| cart_id | INT UNSIGNED | FK → carts.id, ON DELETE CASCADE | |
| product_id | INT UNSIGNED | FK → products.id | |
| quantity | INT | NOT NULL, DEFAULT 1 | |
| price_at_time | DECIMAL(15,0) | NOT NULL | Giá lúc thêm vào giỏ |
| UNIQUE | | (cart_id, product_id) | Không trùng product trong 1 giỏ |

#### Bảng: orders

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| user_id | INT UNSIGNED | FK → users.id | |
| order_code | VARCHAR(20) | NOT NULL, UNIQUE | Mã đơn hàng (ORD-YYYYMMDD-XXXXX) |
| subtotal | DECIMAL(15,0) | NOT NULL | Tổng tiền hàng |
| shipping_fee | DECIMAL(15,0) | DEFAULT 0 | Phí vận chuyển |
| discount_amount | DECIMAL(15,0) | DEFAULT 0 | Giảm giá |
| total_amount | DECIMAL(15,0) | NOT NULL | Tổng thanh toán |
| order_status | ENUM('pending','confirmed','processing','shipping','completed','cancelled') | DEFAULT 'pending' | |
| payment_status | ENUM('unpaid','pending','paid','failed','refunded') | DEFAULT 'unpaid' | |
| shipping_name | VARCHAR(100) | NOT NULL | Tên người nhận |
| shipping_phone | VARCHAR(15) | NOT NULL | SĐT người nhận |
| shipping_address | TEXT | NOT NULL | Địa chỉ giao hàng (full text) |
| note | TEXT | NULL | Ghi chú đơn hàng |
| cancelled_reason | VARCHAR(255) | NULL | Lý do hủy |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | DATETIME | ON UPDATE CURRENT_TIMESTAMP | |

#### Bảng: order_items

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| order_id | INT UNSIGNED | FK → orders.id, ON DELETE CASCADE | |
| product_id | INT UNSIGNED | FK → products.id | |
| product_name | VARCHAR(200) | NOT NULL | Snapshot tên lúc đặt |
| product_image | VARCHAR(255) | NULL | Snapshot ảnh lúc đặt |
| price | DECIMAL(15,0) | NOT NULL | Giá lúc đặt |
| quantity | INT | NOT NULL | |
| total_price | DECIMAL(15,0) | NOT NULL | price × quantity |

#### Bảng: payments

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| order_id | INT UNSIGNED | FK → orders.id, UNIQUE | 1 payment / order |
| payment_method | ENUM('cod','bank_transfer','vnpay','momo') | NOT NULL | |
| payment_status | ENUM('unpaid','pending','paid','failed','refunded') | DEFAULT 'unpaid' | |
| transaction_code | VARCHAR(100) | NULL | Mã giao dịch gateway |
| amount | DECIMAL(15,0) | NOT NULL | |
| paid_at | DATETIME | NULL | Thời điểm thanh toán thành công |
| gateway_response | TEXT | NULL | Raw response từ cổng |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | |

#### Bảng: reviews

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| user_id | INT UNSIGNED | FK → users.id | |
| product_id | INT UNSIGNED | FK → products.id | |
| order_id | INT UNSIGNED | FK → orders.id | Đảm bảo đã mua hàng |
| rating | TINYINT | NOT NULL, CHECK(1..5) | 1 đến 5 sao |
| comment | TEXT | NULL | Bình luận |
| status | ENUM('visible','hidden','pending') | DEFAULT 'visible' | |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | |
| UNIQUE | | (user_id, product_id, order_id) | 1 đánh giá / sản phẩm / đơn |

#### Bảng: warranty_requests

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| user_id | INT UNSIGNED | FK → users.id | |
| product_id | INT UNSIGNED | FK → products.id | |
| order_id | INT UNSIGNED | FK → orders.id | |
| issue_description | TEXT | NOT NULL | Mô tả lỗi/vấn đề |
| status | ENUM('pending','approved','rejected','processing','completed') | DEFAULT 'pending' | |
| admin_note | TEXT | NULL | Ghi chú từ admin |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | |
| updated_at | DATETIME | ON UPDATE CURRENT_TIMESTAMP | |

### 3.3 SQL DDL Skeleton

```sql
-- Chạy theo thứ tự để tránh lỗi FK
CREATE DATABASE IF NOT EXISTS household_shop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE household_shop;

CREATE TABLE users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(15),
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('customer','admin') NOT NULL DEFAULT 'customer',
  status ENUM('active','blocked') NOT NULL DEFAULT 'active',
  avatar_url VARCHAR(255),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE addresses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  receiver_name VARCHAR(100) NOT NULL,
  receiver_phone VARCHAR(15) NOT NULL,
  province VARCHAR(100) NOT NULL,
  district VARCHAR(100) NOT NULL,
  ward VARCHAR(100) NOT NULL,
  detail VARCHAR(255) NOT NULL,
  is_default TINYINT(1) DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE categories (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(120) NOT NULL UNIQUE,
  description TEXT,
  parent_id INT UNSIGNED,
  image_url VARCHAR(255),
  status ENUM('active','inactive') DEFAULT 'active',
  sort_order INT DEFAULT 0,
  FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
);

CREATE TABLE products (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id INT UNSIGNED NOT NULL,
  name VARCHAR(200) NOT NULL,
  slug VARCHAR(220) NOT NULL UNIQUE,
  brand VARCHAR(100),
  sku VARCHAR(50) UNIQUE,
  price DECIMAL(15,0) NOT NULL,
  sale_price DECIMAL(15,0),
  stock_quantity INT NOT NULL DEFAULT 0,
  description TEXT,
  specifications TEXT,
  warranty_months INT DEFAULT 0,
  avg_rating DECIMAL(3,2) DEFAULT 0.00,
  review_count INT DEFAULT 0,
  status ENUM('active','inactive','out_of_stock') DEFAULT 'active',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id),
  INDEX idx_category (category_id),
  INDEX idx_status (status),
  INDEX idx_brand (brand),
  FULLTEXT INDEX ft_search (name, description)
);

CREATE TABLE product_images (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id INT UNSIGNED NOT NULL,
  image_url VARCHAR(255) NOT NULL,
  is_main TINYINT(1) DEFAULT 0,
  sort_order INT DEFAULT 0,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE carts (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE cart_items (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cart_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  price_at_time DECIMAL(15,0) NOT NULL,
  UNIQUE KEY uq_cart_product (cart_id, product_id),
  FOREIGN KEY (cart_id) REFERENCES carts(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE orders (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  order_code VARCHAR(20) NOT NULL UNIQUE,
  subtotal DECIMAL(15,0) NOT NULL,
  shipping_fee DECIMAL(15,0) DEFAULT 0,
  discount_amount DECIMAL(15,0) DEFAULT 0,
  total_amount DECIMAL(15,0) NOT NULL,
  order_status ENUM('pending','confirmed','processing','shipping','completed','cancelled') DEFAULT 'pending',
  payment_status ENUM('unpaid','pending','paid','failed','refunded') DEFAULT 'unpaid',
  shipping_name VARCHAR(100) NOT NULL,
  shipping_phone VARCHAR(15) NOT NULL,
  shipping_address TEXT NOT NULL,
  note TEXT,
  cancelled_reason VARCHAR(255),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_order_status (order_status),
  INDEX idx_user_orders (user_id)
);

CREATE TABLE order_items (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  product_name VARCHAR(200) NOT NULL,
  product_image VARCHAR(255),
  price DECIMAL(15,0) NOT NULL,
  quantity INT NOT NULL,
  total_price DECIMAL(15,0) NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE TABLE payments (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id INT UNSIGNED NOT NULL UNIQUE,
  payment_method ENUM('cod','bank_transfer','vnpay','momo') NOT NULL,
  payment_status ENUM('unpaid','pending','paid','failed','refunded') DEFAULT 'unpaid',
  transaction_code VARCHAR(100),
  amount DECIMAL(15,0) NOT NULL,
  paid_at DATETIME,
  gateway_response TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id)
);

CREATE TABLE reviews (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  order_id INT UNSIGNED NOT NULL,
  rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  status ENUM('visible','hidden','pending') DEFAULT 'visible',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_user_product_order (user_id, product_id, order_id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (order_id) REFERENCES orders(id)
);

CREATE TABLE warranty_requests (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  order_id INT UNSIGNED NOT NULL,
  issue_description TEXT NOT NULL,
  status ENUM('pending','approved','rejected','processing','completed') DEFAULT 'pending',
  admin_note TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (order_id) REFERENCES orders(id)
);
```

---

## 4. VAI TRÒ & PHÂN QUYỀN

### 4.1 Ma trận phân quyền

| Chức năng | Guest | Customer | Admin |
|-----------|:-----:|:--------:|:-----:|
| Xem trang chủ | ✅ | ✅ | ✅ |
| Xem danh sách sản phẩm | ✅ | ✅ | ✅ |
| Xem chi tiết sản phẩm | ✅ | ✅ | ✅ |
| Tìm kiếm / lọc sản phẩm | ✅ | ✅ | ✅ |
| Đăng ký tài khoản | ✅ | ❌ | ❌ |
| Đăng nhập | ✅ | ✅ | ✅ |
| Đăng xuất | ❌ | ✅ | ✅ |
| Cập nhật thông tin cá nhân | ❌ | ✅ | ✅ |
| Đổi mật khẩu | ❌ | ✅ | ✅ |
| Quản lý địa chỉ | ❌ | ✅ | ❌ |
| Thêm vào giỏ hàng | ❌ | ✅ | ❌ |
| Xem / cập nhật giỏ hàng | ❌ | ✅ | ❌ |
| Đặt hàng | ❌ | ✅ | ❌ |
| Xem lịch sử đơn hàng | ❌ | ✅ | ❌ |
| Hủy đơn hàng | ❌ | ✅ | ✅ |
| Đánh giá sản phẩm | ❌ | ✅ (sau khi completed) | ❌ |
| Gửi yêu cầu bảo hành | ❌ | ✅ | ❌ |
| Truy cập trang /admin/* | ❌ | ❌ | ✅ |
| Quản lý sản phẩm | ❌ | ❌ | ✅ |
| Quản lý danh mục | ❌ | ❌ | ✅ |
| Quản lý đơn hàng | ❌ | ❌ | ✅ |
| Quản lý người dùng | ❌ | ❌ | ✅ |
| Xem thống kê | ❌ | ❌ | ✅ |
| Ẩn/hiện đánh giá | ❌ | ❌ | ✅ |
| Xử lý bảo hành | ❌ | ❌ | ✅ |

---

## 5. LUỒNG TỔNG QUAN HỆ THỐNG

### 5.1 Luồng mua hàng từ đầu đến cuối

```
[Guest vào website]
        │
        ▼
[Xem trang chủ] ──→ [Xem danh mục] ──→ [Tìm kiếm/lọc]
        │
        ▼
[Xem chi tiết sản phẩm]
        │
        ├─── Chưa đăng nhập ──→ [Trang đăng nhập] ──→ [Đăng nhập thành công]
        │                                                        │
        └─── Đã đăng nhập ───────────────────────────────────────┘
                                                                 │
                                                                 ▼
                                                    [Thêm vào giỏ hàng]
                                                                 │
                                                                 ▼
                                                    [Xem giỏ hàng]
                                                    Cập nhật số lượng / xóa item
                                                                 │
                                                                 ▼
                                                    [Trang Checkout]
                                                    - Chọn địa chỉ giao hàng
                                                    - Chọn phương thức thanh toán
                                                    - Xem tổng tiền
                                                    - Nhập ghi chú
                                                                 │
                                                    ┌────────────┼────────────┐
                                                    ▼            ▼            ▼
                                                  [COD]    [Bank Transfer] [VNPay]
                                                    │            │            │
                                                    ▼            ▼            ▼
                                              unpaid/pending  pending    redirect gateway
                                                    │            │            │
                                                    └────────────┴────────────┘
                                                                 │
                                                                 ▼
                                                    [Đơn hàng được tạo]
                                                    order_status = pending
                                                                 │
                                                                 ▼
                                                    [Admin xác nhận đơn]
                                                    order_status = confirmed
                                                                 │
                                                                 ▼
                                                    [Chuẩn bị → Giao hàng]
                                                    processing → shipping
                                                                 │
                                                                 ▼
                                                    [Hoàn thành đơn]
                                                    order_status = completed
                                                                 │
                                                                 ▼
                                                    [Customer đánh giá sản phẩm]
```

### 5.2 Luồng Admin

```
[Admin đăng nhập /admin/login]
        │
        ▼
[Dashboard] ──────────────────────────────────────────────────────────┐
        │                                                              │
        ├──→ [Quản lý Sản phẩm]                                       │
        │         ├── Thêm sản phẩm (upload ảnh, chọn danh mục)       │
        │         ├── Sửa sản phẩm                                     │
        │         ├── Cập nhật tồn kho                                 │
        │         └── Ẩn / Xóa sản phẩm                               │
        │                                                              │
        ├──→ [Quản lý Danh mục]                                        │
        │         ├── Thêm / Sửa / Xóa danh mục                       │
        │         └── Sắp xếp thứ tự hiển thị                         │
        │                                                              │
        ├──→ [Quản lý Đơn hàng]                                        │
        │         ├── Xem danh sách (lọc theo trạng thái)              │
        │         ├── Xem chi tiết đơn                                 │
        │         ├── Cập nhật order_status                            │
        │         ├── Xác nhận thanh toán (bank transfer)              │
        │         └── Hủy đơn                                          │
        │                                                              │
        ├──→ [Quản lý Người dùng]                                      │
        │         ├── Xem danh sách                                    │
        │         └── Khóa / Mở khóa tài khoản                        │
        │                                                              │
        ├──→ [Quản lý Đánh giá]                                        │
        │         ├── Xem tất cả đánh giá                              │
        │         └── Ẩn / Hiện đánh giá                               │
        │                                                              │
        └──→ [Thống kê]  ←────────────────────────────────────────────┘
                  ├── Doanh thu theo ngày / tháng
                  ├── Số đơn hoàn thành / hủy
                  ├── Sản phẩm bán chạy
                  └── Sản phẩm sắp hết hàng
```

---

## 6. SKILLS

---

### SKILL 01 — Project Setup

**Mục tiêu:** Khởi tạo project Node.js/Express đủ để chạy được trang đầu tiên.

**Checklist:**

```
[ ] npm init, cài Express, EJS, mysql2, bcrypt, express-session, multer, dotenv
[ ] Cấu hình app.js: view engine EJS, static public/, body parser, session
[ ] Cấu hình database.js: mysql2 connection pool
[ ] Tạo file .env.example với các biến: DB_HOST, DB_PORT, DB_USER, DB_PASS, DB_NAME, SESSION_SECRET, PORT
[ ] Tạo layout main.ejs và admin.ejs
[ ] Tạo partial header.ejs, footer.ejs, navbar.ejs, flash.ejs
[ ] Tạo route GET / → render home.ejs
[ ] Test: node server.js → http://localhost:3000 không lỗi
```

**Cấu hình app.js cần có:**

```javascript
// Theo thứ tự quan trọng
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'src/views'));
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(session({ secret: process.env.SESSION_SECRET, resave: false, saveUninitialized: false }));
app.use(/* flash middleware */);
app.use(/* set res.locals.user từ session */);
```

---

### SKILL 02 — Database Schema & Seed

**Mục tiêu:** Tạo toàn bộ bảng và dữ liệu mẫu đủ để test các luồng chính.

**Checklist:**

```
[ ] Chạy schema.sql → tạo đủ 12 bảng không lỗi
[ ] Chạy seed.sql → có admin, 5 danh mục, 10+ sản phẩm, 2 customer
[ ] Kiểm tra FK không lỗi
[ ] Kiểm tra UNIQUE constraint hoạt động
[ ] Test kết nối từ app bằng pool.query('SELECT 1')
```

**Seed data tối thiểu:** xem Mục 10.

---

### SKILL 03 — Authentication

**Mục tiêu:** Đăng ký / đăng nhập / đăng xuất hoạt động, session bảo vệ route.

#### Flow: Đăng ký

```
BƯỚC 1 — Client gửi form
  POST /register
  Body: { full_name, email, phone, password, confirm_password }

BƯỚC 2 — Controller validate
  - full_name không rỗng
  - email đúng định dạng
  - phone 10-11 số (tuỳ chọn)
  - password >= 8 ký tự
  - confirm_password === password
  → Nếu lỗi: render lại form với flash error

BƯỚC 3 — Service kiểm tra email
  SELECT id FROM users WHERE email = ?
  → Nếu đã tồn tại: flash "Email đã được sử dụng", return

BƯỚC 4 — Hash password & tạo user
  const hash = await bcrypt.hash(password, 10)
  INSERT INTO users (full_name, email, phone, password_hash) VALUES (...)

BƯỚC 5 — Redirect
  → redirect /login với flash "Đăng ký thành công"
```

#### Flow: Đăng nhập

```
BƯỚC 1 — Client gửi form
  POST /login
  Body: { email, password }

BƯỚC 2 — Controller validate
  - email không rỗng
  - password không rỗng
  → Nếu lỗi: render lại form

BƯỚC 3 — Service tìm user
  SELECT * FROM users WHERE email = ?
  → Nếu không tìm thấy: flash "Sai email hoặc mật khẩu"

BƯỚC 4 — So sánh password
  const match = await bcrypt.compare(password, user.password_hash)
  → Nếu false: flash "Sai email hoặc mật khẩu"

BƯỚC 5 — Kiểm tra status
  → Nếu user.status = 'blocked': flash "Tài khoản bị khoá"

BƯỚC 6 — Tạo session
  req.session.userId = user.id
  req.session.userRole = user.role

BƯỚC 7 — Redirect theo role
  → role = 'admin': redirect /admin/dashboard
  → role = 'customer': redirect / hoặc trang trước đó
```

#### Flow: Đăng xuất

```
POST /logout
  req.session.destroy()
  → redirect /login
```

#### Middleware requireAuth

```
function requireAuth(req, res, next) {
  if (!req.session.userId) {
    return res.redirect('/login?returnUrl=' + encodeURIComponent(req.originalUrl));
  }
  next();
}
```

#### Middleware requireAdmin

```
function requireAdmin(req, res, next) {
  if (!req.session.userId) return res.redirect('/login');
  if (req.session.userRole !== 'admin') return res.status(403).render('errors/403');
  next();
}
```

**Checklist:**

```
[ ] GET /register → form đăng ký
[ ] POST /register → validate, hash, insert, redirect
[ ] GET /login → form đăng nhập
[ ] POST /login → validate, compare, session, redirect
[ ] POST /logout → destroy session, redirect
[ ] Middleware requireAuth block route /cart, /orders, /checkout
[ ] Middleware requireAdmin block route /admin/*
[ ] Password không bao giờ lưu plain text
```

---

### SKILL 04 — Product Catalog

**Mục tiêu:** Hiển thị sản phẩm, tìm kiếm, lọc, phân trang, xem chi tiết.

#### Flow: Danh sách sản phẩm

```
BƯỚC 1 — Client gửi request
  GET /products?keyword=&category=&brand=&minPrice=&maxPrice=&sort=&page=

BƯỚC 2 — Controller chuẩn hoá params
  - keyword: trim, escape
  - category: parse int
  - minPrice / maxPrice: parse float, đảm bảo min <= max
  - sort: whitelist ['price_asc','price_desc','newest','rating']
  - page: parse int, default 1

BƯỚC 3 — Service build query
  Base: SELECT p.*, c.name as category_name, pi.image_url as main_image
        FROM products p
        JOIN categories c ON p.category_id = c.id
        LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
        WHERE p.status = 'active'

  Nếu keyword: AND (p.name LIKE ? OR p.description LIKE ?)
  Nếu category: AND p.category_id = ?
  Nếu brand: AND p.brand = ?
  Nếu minPrice: AND COALESCE(p.sale_price, p.price) >= ?
  Nếu maxPrice: AND COALESCE(p.sale_price, p.price) <= ?
  ORDER BY: theo sort param
  LIMIT 12 OFFSET (page-1)*12

BƯỚC 4 — Đếm tổng
  SELECT COUNT(*) → tính totalPages

BƯỚC 5 — Render
  res.render('pages/products/index', { products, pagination, filters, categories })
```

#### Flow: Chi tiết sản phẩm

```
BƯỚC 1
  GET /products/:slug

BƯỚC 2 — Service tìm sản phẩm
  SELECT p.*, c.name as category_name
  FROM products p JOIN categories c ON p.category_id = c.id
  WHERE p.slug = ? AND p.status != 'inactive'

BƯỚC 3 — Lấy ảnh
  SELECT * FROM product_images WHERE product_id = ? ORDER BY is_main DESC, sort_order

BƯỚC 4 — Lấy đánh giá (paginated)
  SELECT r.*, u.full_name FROM reviews r JOIN users u ON r.user_id = u.id
  WHERE r.product_id = ? AND r.status = 'visible'
  ORDER BY r.created_at DESC LIMIT 5

BƯỚC 5 — Sản phẩm liên quan (cùng danh mục)
  SELECT ... FROM products WHERE category_id = ? AND id != ? AND status = 'active' LIMIT 4

BƯỚC 6 — Render chi tiết
  Bao gồm: ảnh gallery, tên, giá, tồn kho, mô tả, thông số, đánh giá, sản phẩm liên quan
```

**Bộ lọc hỗ trợ:**

```
keyword   : tìm kiếm full-text tên + mô tả
category  : id danh mục
brand     : tên thương hiệu
minPrice  : giá tối thiểu (theo sale_price hoặc price)
maxPrice  : giá tối đa
rating    : rating tối thiểu (avg_rating >= ?)
inStock   : chỉ lấy stock_quantity > 0
onSale    : chỉ lấy sale_price IS NOT NULL
sort      : price_asc | price_desc | newest | rating
page      : số trang (default 1)
```

**Checklist:**

```
[ ] GET / → trang chủ: sản phẩm nổi bật, mới nhất, khuyến mãi
[ ] GET /products → danh sách, có pagination
[ ] GET /products?keyword=... → tìm kiếm đúng
[ ] GET /products?category=1 → lọc theo danh mục
[ ] GET /products/:slug → chi tiết sản phẩm
[ ] GET /categories/:slug → sản phẩm theo danh mục
[ ] Sản phẩm hết hàng hiển thị "Hết hàng", không cho thêm giỏ
[ ] Hiển thị giá khuyến mãi khi có sale_price
```

---

### SKILL 05 — Cart

**Mục tiêu:** Giỏ hàng hoạt động đúng: thêm, cập nhật, xóa, tính tiền.

#### Flow: Thêm vào giỏ hàng

```
BƯỚC 1
  POST /cart/add
  Body: { product_id, quantity }
  Middleware: requireAuth

BƯỚC 2 — Validate
  - product_id: số nguyên dương
  - quantity: số nguyên, >= 1

BƯỚC 3 — Kiểm tra sản phẩm
  SELECT id, price, sale_price, stock_quantity, status FROM products WHERE id = ?
  → Nếu không tìm thấy: 404
  → Nếu status = 'inactive': báo lỗi
  → Nếu stock_quantity = 0: flash "Sản phẩm hết hàng"

BƯỚC 4 — Lấy hoặc tạo cart
  SELECT id FROM carts WHERE user_id = ?
  → Nếu không có: INSERT INTO carts (user_id) VALUES (?)

BƯỚC 5 — Kiểm tra cart_item đã tồn tại chưa
  SELECT id, quantity FROM cart_items WHERE cart_id = ? AND product_id = ?

  Nếu đã có:
    new_quantity = existing.quantity + quantity
    → Nếu new_quantity > stock_quantity: flash "Vượt quá số lượng tồn kho"
    → Cập nhật: UPDATE cart_items SET quantity = ? WHERE id = ?

  Nếu chưa có:
    → Nếu quantity > stock_quantity: flash "Vượt quá số lượng tồn kho"
    → INSERT INTO cart_items (cart_id, product_id, quantity, price_at_time) VALUES (...)
    price_at_time = COALESCE(sale_price, price)

BƯỚC 6 — Response
  → AJAX: return JSON { success: true, cartCount }
  → Form submit: redirect /cart với flash "Đã thêm vào giỏ hàng"
```

#### Flow: Cập nhật số lượng

```
BƯỚC 1
  PATCH /cart/items/:id
  Body: { quantity }
  Middleware: requireAuth

BƯỚC 2 — Kiểm tra cart_item thuộc user hiện tại
  SELECT ci.*, c.user_id FROM cart_items ci JOIN carts c ON ci.cart_id = c.id
  WHERE ci.id = ?
  → Nếu c.user_id != req.session.userId: 403

BƯỚC 3 — Validate quantity
  → quantity < 1: xóa item
  → quantity > stock_quantity: báo lỗi

BƯỚC 4 — Cập nhật
  UPDATE cart_items SET quantity = ? WHERE id = ?

BƯỚC 5 — Response JSON
  { success: true, itemTotal, cartTotal, cartCount }
```

#### Flow: Xóa khỏi giỏ hàng

```
DELETE /cart/items/:id
Middleware: requireAuth

→ Kiểm tra item thuộc cart của user
→ DELETE FROM cart_items WHERE id = ?
→ Response JSON { success: true, cartCount }
```

**Checklist:**

```
[ ] GET /cart → hiển thị giỏ hàng, subtotal, shipping_fee, total
[ ] POST /cart/add → thêm đúng, không vượt tồn kho
[ ] PATCH /cart/items/:id → cập nhật số lượng đúng
[ ] DELETE /cart/items/:id → xóa đúng
[ ] Nếu giỏ rỗng → hiển thị empty state và link về trang sản phẩm
[ ] Cart item của user A không thể bị xóa bởi user B
[ ] Giá trong giỏ = sale_price nếu có, ngược lại = price
```

---

### SKILL 06 — Checkout & Order

**Mục tiêu:** Tạo đơn hàng từ giỏ hàng, quản lý vòng đời đơn.

#### Flow: Trang Checkout

```
BƯỚC 1
  GET /checkout
  Middleware: requireAuth

BƯỚC 2 — Lấy cart hiện tại
  SELECT ci.*, p.name, p.stock_quantity, pi.image_url, ci.price_at_time
  FROM cart_items ci
  JOIN products p ON ci.product_id = p.id
  LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
  JOIN carts c ON ci.cart_id = c.id
  WHERE c.user_id = ?

  → Nếu giỏ rỗng: redirect /cart

BƯỚC 3 — Kiểm tra tồn kho real-time
  Với mỗi item: nếu p.stock_quantity < ci.quantity → flash cảnh báo

BƯỚC 4 — Lấy địa chỉ của user
  SELECT * FROM addresses WHERE user_id = ? ORDER BY is_default DESC

BƯỚC 5 — Render
  res.render('pages/checkout', { cartItems, addresses, subtotal, shippingFee, total })
```

#### Flow: Đặt hàng

```
BƯỚC 1
  POST /orders
  Middleware: requireAuth
  Body: { address_id OR (shipping_name, shipping_phone, shipping_address), payment_method, note }

BƯỚC 2 — Validate input
  - Địa chỉ giao hàng hợp lệ
  - payment_method trong ['cod','bank_transfer','vnpay','momo']

BƯỚC 3 — Validate cart & tồn kho (lần 2)
  Với mỗi item trong cart:
    SELECT stock_quantity FROM products WHERE id = ?
    → Nếu stock_quantity < item.quantity: báo lỗi, không tạo đơn

BƯỚC 4 — Bắt đầu DATABASE TRANSACTION

BƯỚC 5 — Tính toán
  subtotal = SUM(item.price_at_time * item.quantity)
  shipping_fee = subtotal >= 500000 ? 0 : 30000  (hoặc cố định)
  total_amount = subtotal + shipping_fee - discount_amount

BƯỚC 6 — Tạo order
  order_code = 'ORD-' + YYYYMMDD + '-' + randomCode(5)
  INSERT INTO orders (...) VALUES (...)

BƯỚC 7 — Tạo order_items
  Với mỗi cart item:
    INSERT INTO order_items (order_id, product_id, product_name, product_image, price, quantity, total_price)

BƯỚC 8 — Tạo payment record
  INSERT INTO payments (order_id, payment_method, payment_status, amount)
  - COD: payment_status = 'unpaid'
  - bank_transfer: payment_status = 'pending'
  - vnpay/momo: payment_status = 'pending'

BƯỚC 9 — Xóa cart
  DELETE FROM cart_items WHERE cart_id = ?

BƯỚC 10 — COMMIT transaction

BƯỚC 11 — Xử lý theo payment_method
  COD → redirect /orders/{order_code}?success=1
  bank_transfer → redirect /payment/bank-info/{order_code}
  vnpay/momo → redirect URL từ PaymentService

BƯỚC ROLLBACK — Nếu bất kỳ bước nào thất bại:
  ROLLBACK → flash error → redirect /checkout
```

#### Flow: Hủy đơn hàng

```
POST /orders/:orderCode/cancel
Middleware: requireAuth
Body: { reason }

BƯỚC 1 — Tìm đơn hàng
  SELECT * FROM orders WHERE order_code = ? AND user_id = ?
  → Nếu không tìm thấy: 404

BƯỚC 2 — Kiểm tra cho phép hủy
  → Chỉ cho hủy nếu order_status IN ('pending', 'confirmed')
  → Nếu status khác: flash "Không thể hủy đơn hàng này"

BƯỚC 3 — Cập nhật
  UPDATE orders SET order_status = 'cancelled', cancelled_reason = ? WHERE id = ?
  UPDATE payments SET payment_status = 'refunded' WHERE order_id = ? AND payment_status = 'paid'

BƯỚC 4 — Hoàn tồn kho (nếu đơn đã confirmed)
  Với mỗi order_item:
    UPDATE products SET stock_quantity = stock_quantity + quantity WHERE id = ?
    Nếu stock_quantity > 0 và status = 'out_of_stock': cập nhật status = 'active'

BƯỚC 5
  redirect /orders/{order_code} với flash "Đơn hàng đã được hủy"
```

**Checklist:**

```
[ ] GET /checkout → hiển thị giỏ, địa chỉ, phương thức thanh toán
[ ] POST /orders → tạo order + order_items + payment trong 1 transaction
[ ] Cart bị xóa sau khi tạo đơn thành công
[ ] Tồn kho được validate trước khi tạo đơn
[ ] order_code unique, format rõ ràng
[ ] GET /orders → lịch sử đơn hàng của user hiện tại
[ ] GET /orders/:orderCode → chi tiết đơn hàng
[ ] POST /orders/:orderCode/cancel → hủy đơn đúng điều kiện
[ ] User chỉ xem được đơn của chính mình
```

---

### SKILL 07 — Payment

**Mục tiêu:** Xử lý thanh toán theo từng phương thức, cập nhật trạng thái đúng.

#### Flow: COD

```
Khi tạo đơn với payment_method = 'cod':
  orders.payment_status = 'unpaid'
  payments.payment_status = 'unpaid'

Khi admin xác nhận đã thu tiền:
  PATCH /admin/orders/:id/payment
  → UPDATE payments SET payment_status = 'paid', paid_at = NOW() WHERE order_id = ?
  → UPDATE orders SET payment_status = 'paid' WHERE id = ?
```

#### Flow: Chuyển khoản ngân hàng

```
BƯỚC 1 — Sau khi tạo đơn
  redirect /payment/bank-info/:orderCode

BƯỚC 2 — Hiển thị thông tin chuyển khoản
  - Số tài khoản: [lấy từ .env]
  - Tên chủ TK: [lấy từ .env]
  - Ngân hàng: [lấy từ .env]
  - Nội dung CK: order_code
  - Số tiền: total_amount (format VND)
  - QR code (tuỳ chọn)
  - Thời hạn thanh toán: 24 giờ

BƯỚC 3 — Admin kiểm tra và xác nhận
  PATCH /admin/orders/:id/confirm-payment
  Body: { transaction_code }
  → UPDATE payments SET payment_status = 'paid', transaction_code = ?, paid_at = NOW()
  → UPDATE orders SET payment_status = 'paid', order_status = 'confirmed'

BƯỚC 4 — Nếu quá hạn không thanh toán
  Admin hủy đơn: order_status = 'cancelled', payment_status = 'failed'
```

#### Flow: VNPay Sandbox

```
BƯỚC 1 — Tạo payment URL
  POST /payment/vnpay/create
  → PaymentService tạo VNPAY URL với:
     vnp_Amount = total_amount * 100
     vnp_TxnRef = order_code
     vnp_ReturnUrl = /payment/vnpay/return
     vnp_IpnUrl = /payment/vnpay/ipn
     vnp_SecureHash = HMAC-SHA512 của query string

  → redirect sang VNPAY URL

BƯỚC 2 — User thanh toán trên VNPAY

BƯỚC 3 — VNPAY callback về ReturnUrl
  GET /payment/vnpay/return?vnp_ResponseCode=00&vnp_TxnRef=ORD-...&...
  → Verify SecureHash
  → Nếu vnp_ResponseCode = '00': thanh toán thành công
  → Cập nhật payment_status = 'paid', order_status = 'confirmed'
  → redirect /orders/{order_code}?success=1

BƯỚC 4 — IPN (server-to-server)
  POST /payment/vnpay/ipn
  → Verify SecureHash
  → Cập nhật database (ưu tiên hơn ReturnUrl)
  → Response: { RspCode: '00', Message: 'Confirm Success' }

QUAN TRỌNG:
  - KHÔNG cập nhật DB chỉ dựa vào ReturnUrl (dễ giả mạo)
  - PHẢI verify SecureHash trước mọi thao tác cập nhật
  - Idempotent: nếu đã paid rồi thì không update lại
```

**Checklist:**

```
[ ] COD: tạo đơn thành công, payment_status = unpaid
[ ] Bank: trang hướng dẫn CK hiển thị đủ thông tin
[ ] Admin xác nhận CK thủ công được
[ ] VNPay sandbox: tạo URL đúng, verify hash, cập nhật DB đúng
[ ] Không có 2 payment record cho 1 order
[ ] payment.paid_at được set đúng thời điểm
```

---

### SKILL 08 — Reviews & Ratings

**Mục tiêu:** Customer đánh giá sản phẩm sau khi đơn hoàn thành.

#### Flow: Kiểm tra quyền đánh giá

```
BƯỚC 1 — User click "Đánh giá" trong trang chi tiết đơn hàng

BƯỚC 2 — Kiểm tra điều kiện:
  Điều kiện 1: user đã đăng nhập (session.userId)
  Điều kiện 2: order_id thuộc về user
    SELECT id FROM orders WHERE id = ? AND user_id = ? AND order_status = 'completed'
    → Không tìm thấy: 403

  Điều kiện 3: product_id nằm trong order đó
    SELECT id FROM order_items WHERE order_id = ? AND product_id = ?
    → Không tìm thấy: 403

  Điều kiện 4: chưa đánh giá sản phẩm này trong đơn này
    SELECT id FROM reviews WHERE user_id = ? AND product_id = ? AND order_id = ?
    → Đã tồn tại: flash "Bạn đã đánh giá sản phẩm này"
```

#### Flow: Tạo đánh giá

```
BƯỚC 1
  POST /reviews
  Middleware: requireAuth
  Body: { product_id, order_id, rating, comment }

BƯỚC 2 — Chạy kiểm tra quyền (như trên)

BƯỚC 3 — Validate
  - rating: số nguyên 1-5
  - comment: max 1000 ký tự (tuỳ chọn)

BƯỚC 4 — Insert
  INSERT INTO reviews (user_id, product_id, order_id, rating, comment) VALUES (...)

BƯỚC 5 — Cập nhật avg_rating và review_count của sản phẩm
  UPDATE products SET
    avg_rating = (SELECT AVG(rating) FROM reviews WHERE product_id = ? AND status = 'visible'),
    review_count = (SELECT COUNT(*) FROM reviews WHERE product_id = ? AND status = 'visible')
  WHERE id = ?

BƯỚC 6
  → flash "Cảm ơn bạn đã đánh giá!" → redirect /orders/{order_code}
```

**Checklist:**

```
[ ] Chỉ cho đánh giá sau khi order_status = 'completed'
[ ] Mỗi sản phẩm trong 1 đơn chỉ đánh giá 1 lần
[ ] Rating 1-5, không cho giá trị ngoài khoảng
[ ] avg_rating và review_count cập nhật sau mỗi review mới
[ ] Admin có thể ẩn review (status = 'hidden')
[ ] Review ẩn không tính vào avg_rating
```

---

### SKILL 09 — Warranty Request

**Mục tiêu:** Customer gửi yêu cầu bảo hành, admin xử lý.

#### Flow: Gửi yêu cầu bảo hành

```
BƯỚC 1
  POST /warranty
  Middleware: requireAuth
  Body: { product_id, order_id, issue_description }

BƯỚC 2 — Validate điều kiện
  - order thuộc user, order_status = 'completed'
  - product nằm trong order
  - Kiểm tra thời hạn bảo hành nếu có:
    completed_date + warranty_months > NOW()

BƯỚC 3 — Insert
  INSERT INTO warranty_requests (user_id, product_id, order_id, issue_description)

BƯỚC 4
  → flash "Yêu cầu bảo hành đã được gửi" → redirect /orders/{order_code}
```

#### Flow: Admin xử lý bảo hành

```
GET /admin/warranty → danh sách tất cả yêu cầu (lọc theo status)
GET /admin/warranty/:id → chi tiết yêu cầu

PATCH /admin/warranty/:id/status
Body: { status, admin_note }
→ Chỉ cho phép transition hợp lệ:
  pending → approved
  pending → rejected
  approved → processing
  processing → completed
```

**Checklist:**

```
[ ] Chỉ gửi bảo hành cho đơn completed
[ ] Kiểm tra thời hạn bảo hành nếu warranty_months > 0
[ ] Admin xem danh sách và cập nhật trạng thái
[ ] Transition trạng thái theo đúng luồng
```

---

### SKILL 10 — Admin Dashboard

**Mục tiêu:** Admin quản lý toàn bộ dữ liệu và xem thống kê.

#### Flow: Thêm sản phẩm

```
BƯỚC 1
  GET /admin/products/create → render form

BƯỚC 2
  POST /admin/products
  Middleware: requireAdmin
  Body: { name, category_id, brand, price, sale_price, stock_quantity, description, specifications, warranty_months }
  Files: images[] (multer)

BƯỚC 3 — Validate
  - name không rỗng
  - category_id tồn tại trong DB
  - price > 0
  - sale_price < price nếu có
  - stock_quantity >= 0
  - Ảnh: tối thiểu 1 ảnh, mime jpg/png/webp, max 5MB/ảnh

BƯỚC 4 — Tạo slug
  slug = slugify(name) + '-' + timestamp (đảm bảo unique)

BƯỚC 5 — Upload ảnh
  Với mỗi file: lưu vào /public/uploads/products/{filename}

BƯỚC 6 — Transaction
  INSERT INTO products (...)
  Với mỗi ảnh: INSERT INTO product_images (product_id, image_url, is_main)
    → File đầu tiên: is_main = 1

BƯỚC 7
  → redirect /admin/products với flash "Đã thêm sản phẩm"
```

#### Flow: Cập nhật trạng thái đơn hàng

```
PATCH /admin/orders/:id/status
Middleware: requireAdmin
Body: { order_status }

BƯỚC 1 — Lấy đơn hàng
  SELECT * FROM orders WHERE id = ?

BƯỚC 2 — Validate transition (xem Hook 05)

BƯỚC 3 — Nếu status mới = 'confirmed' và payment_method = 'cod':
  Trừ tồn kho (chạy trong transaction):
    Với mỗi order_item:
      UPDATE products SET stock_quantity = stock_quantity - quantity WHERE id = ?
      Nếu stock_quantity = 0: UPDATE products SET status = 'out_of_stock' WHERE id = ?

BƯỚC 4 — Cập nhật order
  UPDATE orders SET order_status = ?, updated_at = NOW() WHERE id = ?

BƯỚC 5
  → redirect /admin/orders/{id} với flash "Cập nhật thành công"
```

#### Dashboard thống kê

```
Queries cần thiết:

1. Tổng doanh thu (đơn completed + paid):
   SELECT SUM(total_amount) FROM orders
   WHERE order_status = 'completed' AND payment_status = 'paid'

2. Doanh thu theo tháng (12 tháng gần nhất):
   SELECT MONTH(created_at) as month, SUM(total_amount) as revenue
   FROM orders WHERE order_status = 'completed' AND payment_status = 'paid'
   AND created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
   GROUP BY MONTH(created_at)

3. Số đơn theo trạng thái:
   SELECT order_status, COUNT(*) as count FROM orders GROUP BY order_status

4. Sản phẩm bán chạy:
   SELECT p.name, SUM(oi.quantity) as total_sold
   FROM order_items oi JOIN products p ON oi.product_id = p.id
   JOIN orders o ON oi.order_id = o.id
   WHERE o.order_status = 'completed'
   GROUP BY oi.product_id ORDER BY total_sold DESC LIMIT 10

5. Sản phẩm sắp hết hàng:
   SELECT id, name, stock_quantity FROM products
   WHERE stock_quantity <= 10 AND status != 'inactive'
   ORDER BY stock_quantity ASC LIMIT 10
```

**Checklist:**

```
[ ] requireAdmin bảo vệ mọi route /admin/*
[ ] CRUD sản phẩm: thêm/sửa/xóa/ẩn
[ ] Upload ảnh: validate mime + size, lưu đúng thư mục
[ ] CRUD danh mục
[ ] Danh sách đơn hàng: lọc theo status, tìm theo order_code
[ ] Cập nhật order_status theo đúng transition
[ ] Xác nhận thanh toán (bank transfer / COD)
[ ] Danh sách user: khóa/mở tài khoản
[ ] Dashboard: 5 thống kê cốt lõi hiển thị đúng
[ ] Ẩn/hiện đánh giá
[ ] Xem và xử lý warranty request
```

---

### SKILL 11 — UI/UX Pages

**Mục tiêu:** Giao diện đầy đủ, responsive, nhất quán.

#### Trang công khai

| Route | File View | Mô tả |
|-------|-----------|-------|
| GET / | pages/home.ejs | Trang chủ: banner, featured, newest, sale |
| GET /products | pages/products/index.ejs | Danh sách + bộ lọc sidebar |
| GET /products/:slug | pages/products/detail.ejs | Chi tiết: gallery, thông số, reviews |
| GET /categories/:slug | pages/products/index.ejs | Reuse danh sách, filter by category |
| GET /search | pages/products/index.ejs | Reuse danh sách, filter by keyword |
| GET /cart | pages/cart.ejs | Giỏ hàng, cập nhật real-time |
| GET /checkout | pages/checkout.ejs | Form đặt hàng |
| GET /orders | pages/orders/index.ejs | Lịch sử đơn hàng |
| GET /orders/:code | pages/orders/detail.ejs | Chi tiết đơn + action (hủy, đánh giá) |
| GET /profile | pages/profile/index.ejs | Thông tin cá nhân |
| GET /profile/addresses | pages/profile/addresses.ejs | Quản lý địa chỉ |
| GET /login | auth/login.ejs | Form đăng nhập |
| GET /register | auth/register.ejs | Form đăng ký |
| GET /forgot-password | auth/forgot-password.ejs | Form quên mật khẩu |

#### Trang Admin

| Route | File View | Mô tả |
|-------|-----------|-------|
| GET /admin/login | admin/login.ejs | Đăng nhập admin riêng biệt |
| GET /admin/dashboard | admin/dashboard.ejs | Thống kê tổng quan |
| GET /admin/products | admin/products/index.ejs | Danh sách sản phẩm |
| GET /admin/products/create | admin/products/form.ejs | Form thêm |
| GET /admin/products/:id/edit | admin/products/form.ejs | Form sửa |
| GET /admin/categories | admin/categories/index.ejs | Quản lý danh mục |
| GET /admin/orders | admin/orders/index.ejs | Danh sách đơn hàng |
| GET /admin/orders/:id | admin/orders/detail.ejs | Chi tiết + cập nhật trạng thái |
| GET /admin/users | admin/users/index.ejs | Danh sách user |
| GET /admin/reviews | admin/reviews/index.ejs | Quản lý đánh giá |
| GET /admin/warranty | admin/warranty/index.ejs | Quản lý bảo hành |

#### Yêu cầu UI mỗi trang

```
Bắt buộc có:
  - Header thống nhất (logo, nav, cart icon, user menu)
  - Footer thống nhất
  - Breadcrumb cho trang sâu hơn 1 cấp
  - Flash message (success/error) hiển thị và tự ẩn sau 3 giây
  - Empty state khi không có dữ liệu (icon + text + CTA)
  - Loading state khi submit form (disable button + spinner)
  - Responsive: mobile 375px, tablet 768px, desktop 1200px

Trang sản phẩm:
  - Lazy load ảnh
  - Giá format VND (1.500.000 đ)
  - Badge "Hết hàng" / "Giảm X%"
  - Rating stars hiển thị trực quan

Trang giỏ hàng:
  - Cập nhật quantity không reload trang (AJAX)
  - Tổng tiền cập nhật real-time

Trang admin:
  - Sidebar navigation
  - Breadcrumb
  - Data table có phân trang và tìm kiếm
  - Confirm dialog trước khi xóa / hủy
```

---

### SKILL 12 — API Route Map

**Bảng đầy đủ tất cả routes:**

| Method | Path | Middleware | Controller | Mô tả |
|--------|------|-----------|------------|-------|
| GET | / | — | home.controller | Trang chủ |
| GET | /products | — | product.controller | Danh sách |
| GET | /products/:slug | — | product.controller | Chi tiết |
| GET | /categories/:slug | — | product.controller | By danh mục |
| GET | /search | — | product.controller | Tìm kiếm |
| GET | /login | guest | auth.controller | Form đăng nhập |
| POST | /login | guest | auth.controller | Xử lý đăng nhập |
| GET | /register | guest | auth.controller | Form đăng ký |
| POST | /register | guest | auth.controller | Xử lý đăng ký |
| POST | /logout | auth | auth.controller | Đăng xuất |
| GET | /forgot-password | guest | auth.controller | Form quên MK |
| POST | /forgot-password | guest | auth.controller | Gửi email reset |
| GET | /profile | auth | user.controller | Thông tin cá nhân |
| POST | /profile | auth | user.controller | Cập nhật thông tin |
| POST | /profile/change-password | auth | user.controller | Đổi mật khẩu |
| GET | /profile/addresses | auth | address.controller | Danh sách địa chỉ |
| POST | /profile/addresses | auth | address.controller | Thêm địa chỉ |
| PUT | /profile/addresses/:id | auth | address.controller | Sửa địa chỉ |
| DELETE | /profile/addresses/:id | auth | address.controller | Xóa địa chỉ |
| GET | /cart | auth | cart.controller | Xem giỏ hàng |
| POST | /cart/add | auth | cart.controller | Thêm vào giỏ |
| PATCH | /cart/items/:id | auth | cart.controller | Cập nhật số lượng |
| DELETE | /cart/items/:id | auth | cart.controller | Xóa khỏi giỏ |
| DELETE | /cart/clear | auth | cart.controller | Xóa toàn bộ giỏ |
| GET | /checkout | auth | order.controller | Trang checkout |
| POST | /orders | auth | order.controller | Tạo đơn hàng |
| GET | /orders | auth | order.controller | Lịch sử đơn |
| GET | /orders/:code | auth | order.controller | Chi tiết đơn |
| POST | /orders/:code/cancel | auth | order.controller | Hủy đơn |
| GET | /payment/bank-info/:code | auth | payment.controller | Hướng dẫn CK |
| POST | /payment/vnpay/create | auth | payment.controller | Tạo VNPay URL |
| GET | /payment/vnpay/return | — | payment.controller | VNPay callback |
| POST | /payment/vnpay/ipn | — | payment.controller | VNPay IPN |
| POST | /reviews | auth | review.controller | Tạo đánh giá |
| POST | /warranty | auth | warranty.controller | Gửi bảo hành |
| GET | /admin/login | guestAdmin | admin/auth.controller | Admin login |
| POST | /admin/login | guestAdmin | admin/auth.controller | Xử lý admin login |
| GET | /admin/dashboard | adminAuth | admin/dashboard | Dashboard |
| GET | /admin/products | adminAuth | admin/product | Danh sách SP |
| GET | /admin/products/create | adminAuth | admin/product | Form thêm SP |
| POST | /admin/products | adminAuth | admin/product | Tạo SP |
| GET | /admin/products/:id/edit | adminAuth | admin/product | Form sửa SP |
| PUT | /admin/products/:id | adminAuth | admin/product | Cập nhật SP |
| DELETE | /admin/products/:id | adminAuth | admin/product | Xóa/ẩn SP |
| GET | /admin/categories | adminAuth | admin/category | Danh sách DM |
| POST | /admin/categories | adminAuth | admin/category | Thêm DM |
| PUT | /admin/categories/:id | adminAuth | admin/category | Sửa DM |
| DELETE | /admin/categories/:id | adminAuth | admin/category | Xóa DM |
| GET | /admin/orders | adminAuth | admin/order | Danh sách đơn |
| GET | /admin/orders/:id | adminAuth | admin/order | Chi tiết đơn |
| PATCH | /admin/orders/:id/status | adminAuth | admin/order | Cập nhật status |
| PATCH | /admin/orders/:id/confirm-payment | adminAuth | admin/order | Xác nhận CK |
| GET | /admin/users | adminAuth | admin/user | Danh sách user |
| PATCH | /admin/users/:id/status | adminAuth | admin/user | Khóa/mở TK |
| GET | /admin/reviews | adminAuth | admin/review | Danh sách review |
| PATCH | /admin/reviews/:id/status | adminAuth | admin/review | Ẩn/hiện review |
| GET | /admin/warranty | adminAuth | admin/warranty | Danh sách BH |
| PATCH | /admin/warranty/:id/status | adminAuth | admin/warranty | Cập nhật BH |

---

## 7. HOOKS

---

### HOOK 01 — Pre-build Hook

Trước khi code bất kỳ skill nào, kiểm tra:

```
[ ] Skill này phụ thuộc bảng nào? → đảm bảo bảng đã có trong schema.sql
[ ] Skill này cần route nào? → đăng ký trong routes file tương ứng
[ ] Skill này cần controller / service mới không?
[ ] Skill này cần view mới không? → tạo file trước khi viết logic
[ ] Skill này có cần middleware auth / admin không?
[ ] Skill này có ảnh hưởng tồn kho / trạng thái đơn / thanh toán không?
[ ] Skill này có cần validate input không? → xác định field và rule
[ ] Skill này có cần database transaction không?
[ ] Skill này có side effect gì? (cập nhật bảng khác, gửi email, ...)
```

---

### HOOK 02 — Security Hook

Áp dụng cho MỌI skill có nhận input từ người dùng:

```
PASSWORD:
  [ ] Không bao giờ lưu plain password
  [ ] Hash với bcrypt, rounds = 10
  [ ] Compare bằng bcrypt.compare(), không so sánh string

INPUT VALIDATION:
  [ ] Validate email đúng format (regex hoặc thư viện)
  [ ] Validate phone: 10-11 số, chỉ chứa chữ số
  [ ] Validate quantity: số nguyên dương
  [ ] Validate price: số dương, tối đa 15 chữ số
  [ ] Validate rating: 1 <= rating <= 5
  [ ] Trim tất cả string input trước khi lưu

SQL INJECTION:
  [ ] KHÔNG bao giờ nối string SQL trực tiếp với input user
  [ ] Dùng prepared statements: pool.query('SELECT * FROM users WHERE id = ?', [id])
  [ ] Dùng whitelist cho sort fields, không dùng input trực tiếp

XSS:
  [ ] EJS mặc định escape HTML với <%= %>
  [ ] Chỉ dùng <%- %> khi chắc chắn nội dung an toàn
  [ ] Không render HTML từ input user chưa sanitize

AUTHORIZATION:
  [ ] User chỉ truy cập tài nguyên của chính mình
  [ ] Mọi query nhạy cảm phải có WHERE user_id = req.session.userId
  [ ] Admin route phải qua requireAdmin middleware
  [ ] Không expose userId trong URL nếu có thể (dùng session)

FILE UPLOAD:
  [ ] Whitelist MIME type: image/jpeg, image/png, image/webp
  [ ] Giới hạn kích thước: max 5MB / file
  [ ] Đổi tên file khi lưu (không dùng tên gốc từ client)
  [ ] Lưu ngoài public/ nếu file nhạy cảm

ENVIRONMENT:
  [ ] Không hardcode credential trong code
  [ ] Không expose .env ra client
  [ ] SESSION_SECRET phải là chuỗi ngẫu nhiên đủ dài (32+ ký tự)
```

---

### HOOK 03 — Database Transaction Hook

Các nghiệp vụ BẮT BUỘC dùng transaction:

```
DANH SÁCH:
  1. Tạo đơn hàng (order + order_items + payment + clear cart)
  2. Hủy đơn (update order + update payment + hoàn tồn kho)
  3. Xác nhận đơn COD (update status + trừ tồn kho)
  4. Xác nhận thanh toán (update payment + update order)
  5. Xóa sản phẩm có liên quan nhiều bảng
  6. Cập nhật payment từ gateway callback

TEMPLATE:
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // các thao tác DB

    await conn.commit();
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }

QUY TẮC:
  [ ] Mọi bước trong transaction phải await
  [ ] Luôn có rollback trong catch
  [ ] Luôn release connection trong finally
  [ ] Không throw lỗi bên trong transaction mà không rollback
```

---

### HOOK 04 — UI Consistency Hook

Sau khi viết xong mỗi trang, kiểm tra:

```
LAYOUT:
  [ ] Header đúng layout (main.ejs hoặc admin.ejs)
  [ ] Footer hiển thị đúng
  [ ] Breadcrumb hiển thị đúng trên trang sâu hơn 1 cấp
  [ ] Flash message hiển thị và tự ẩn

STATE:
  [ ] Empty state: khi không có dữ liệu (giỏ rỗng, không có đơn, ...)
  [ ] Loading state: button disable khi submit form
  [ ] Error state: hiển thị lỗi validation ngay dưới field
  [ ] Success state: redirect + flash message

RESPONSIVE:
  [ ] Mobile 375px: không bị overflow, button đủ lớn (min 44px)
  [ ] Tablet 768px: layout điều chỉnh đúng
  [ ] Desktop 1200px: không quá rộng, centered

DATA FORMAT:
  [ ] Giá tiền: format VND (1.500.000 đ)
  [ ] Ngày giờ: format dd/MM/yyyy HH:mm
  [ ] Rating: hiển thị sao màu vàng
  [ ] Trạng thái đơn: badge màu theo trạng thái
```

---

### HOOK 05 — Order State Transition Hook

Khi cập nhật order_status, PHẢI kiểm tra transition hợp lệ:

```
BẢNG TRANSITION HỢP LỆ:

Trạng thái hiện tại  | Cho phép chuyển sang
---------------------|----------------------------------
pending              | confirmed, cancelled
confirmed            | processing, cancelled
processing           | shipping, cancelled
shipping             | completed, cancelled
completed            | (không cho phép thay đổi)
cancelled            | (không cho phép thay đổi)

LOGIC KIỂM TRA:
  const validTransitions = {
    'pending':    ['confirmed', 'cancelled'],
    'confirmed':  ['processing', 'cancelled'],
    'processing': ['shipping', 'cancelled'],
    'shipping':   ['completed', 'cancelled'],
    'completed':  [],
    'cancelled':  []
  };

  if (!validTransitions[currentStatus].includes(newStatus)) {
    throw new Error('Chuyển trạng thái không hợp lệ');
  }

LƯU Ý:
  - Customer chỉ được hủy khi status IN ('pending', 'confirmed')
  - Admin được hủy thêm khi status = 'processing'
  - Khi hủy đơn đã confirmed: hoàn tồn kho
  - Khi hoàn thành: cho phép đánh giá sản phẩm
```

---

### HOOK 06 — Inventory Hook

Quy tắc quản lý tồn kho:

```
KHI THÊM VÀO GIỎ:
  [ ] Kiểm tra stock_quantity >= quantity muốn thêm
  [ ] Kiểm tra product.status != 'inactive'
  [ ] Nếu stock_quantity = 0: từ chối, hiển thị "Hết hàng"

KHI TẠO ĐƠN HÀNG:
  [ ] Validate lại tồn kho (không tin tưởng giỏ hàng cũ)
  [ ] Với COD: trừ kho khi admin confirmed
  [ ] Với online payment: trừ kho khi payment_status = 'paid'

SAU KHI TRỪ KHO:
  [ ] Nếu stock_quantity = 0: SET status = 'out_of_stock'

KHI HỦY ĐƠN:
  [ ] Nếu đơn đã confirmed (kho đã bị trừ): hoàn lại kho
    UPDATE products SET stock_quantity = stock_quantity + quantity
  [ ] Nếu stock_quantity > 0 sau khi hoàn và status = 'out_of_stock':
    SET status = 'active'

KHÔNG BAO GIỜ:
  [ ] Để stock_quantity < 0
  [ ] Trừ kho trước khi transaction hoàn tất
  [ ] Trừ kho 2 lần cho cùng 1 order
```

---

### HOOK 07 — Payment Hook

Quy tắc xử lý thanh toán:

```
NGUYÊN TẮC:
  [ ] KHÔNG set payment_status = 'paid' chỉ dựa vào client request
  [ ] VNPay/MoMo: PHẢI verify SecureHash/signature trước khi cập nhật DB
  [ ] Bank transfer: PHẢI admin confirm thủ công
  [ ] COD: payment_status ban đầu là 'unpaid', admin set 'paid' khi thu tiền

IDEMPOTENCY:
  [ ] Nếu IPN callback đến 2 lần: chỉ xử lý lần đầu
    Kiểm tra: IF payment_status != 'paid' THEN update
  [ ] Log mọi callback từ gateway vào payments.gateway_response

MỘT ORDER - MỘT PAYMENT:
  [ ] payments.order_id có UNIQUE constraint
  [ ] Không tạo payment mới nếu order đã có payment pending

REFUND:
  [ ] Khi hủy đơn đã paid: SET payment_status = 'refunded'
  [ ] Thực tế hoàn tiền thủ công hoặc qua gateway API (ngoài scope)
```

---

### HOOK 08 — Review Permission Hook

Trước khi cho phép tạo review, kiểm tra ĐỦ CÁC ĐIỀU KIỆN:

```
function canReview(userId, productId, orderId) {
  BƯỚC 1: Order thuộc user và completed
    SELECT id FROM orders
    WHERE id = :orderId AND user_id = :userId AND order_status = 'completed'
    → Không có: return { allowed: false, reason: 'Đơn hàng không hợp lệ' }

  BƯỚC 2: Product nằm trong order
    SELECT id FROM order_items
    WHERE order_id = :orderId AND product_id = :productId
    → Không có: return { allowed: false, reason: 'Sản phẩm không thuộc đơn hàng này' }

  BƯỚC 3: Chưa review
    SELECT id FROM reviews
    WHERE user_id = :userId AND product_id = :productId AND order_id = :orderId
    → Có rồi: return { allowed: false, reason: 'Bạn đã đánh giá sản phẩm này' }

  → return { allowed: true }
}

VALIDATE RATING:
  [ ] Kiểu số nguyên
  [ ] 1 <= rating <= 5
  [ ] Không cho 0 hoặc null
```

---

### HOOK 09 — Admin Permission Hook

Bảo vệ toàn bộ route /admin/*:

```
MIDDLEWARE CHAIN cho admin routes:
  router.use(requireAuth);   // Phải đăng nhập
  router.use(requireAdmin);  // Phải là admin

requireAdmin:
  function requireAdmin(req, res, next) {
    if (!req.session.userId) {
      return res.redirect('/login?returnUrl=' + encodeURIComponent(req.path));
    }
    if (req.session.userRole !== 'admin') {
      return res.status(403).render('errors/403', {
        message: 'Bạn không có quyền truy cập trang này'
      });
    }
    next();
  }

KHÔNG ĐƯỢC:
  [ ] Tin tưởng role từ query string hay body
  [ ] Chỉ kiểm tra đăng nhập mà không kiểm tra role
  [ ] Cho customer truy cập /admin/*

ADMIN SESSION:
  [ ] Session timeout admin: 2 giờ không hoạt động
  [ ] Log hoạt động admin quan trọng (xóa sản phẩm, hủy đơn, ...)
```

---

### HOOK 10 — Final QA Hook

Sau khi build xong mỗi skill, chạy checklist này:

```
ROUTES:
  [ ] Tất cả route trong Skill 12 hoạt động, không 404
  [ ] Route sai method trả về 405
  [ ] Route không tồn tại trả về 404 đẹp

VIEWS:
  [ ] View render không lỗi EJS syntax
  [ ] Không có variable undefined trong template
  [ ] Tất cả link trong trang dẫn đến đúng route

FORMS:
  [ ] Form submit đúng action và method
  [ ] Input có name attribute đúng
  [ ] CSRF (nếu có) hoạt động

VALIDATE:
  [ ] Input rỗng hiển thị lỗi, không crash server
  [ ] Input quá dài bị truncate hoặc báo lỗi
  [ ] Giá trị âm bị từ chối

DATABASE:
  [ ] INSERT thành công
  [ ] FK constraint không bị vi phạm
  [ ] Data hiển thị đúng sau khi lưu

AUTHORIZATION:
  [ ] User chưa đăng nhập bị redirect /login
  [ ] Customer bị 403 khi vào /admin/*
  [ ] User A không xem được đơn hàng của user B

MOBILE:
  [ ] Trang không bị overflow ngang ở 375px
  [ ] Form dùng được trên mobile

CONSOLE:
  [ ] Không có error trong browser console
  [ ] Không có error trong server log (nodemon/node)

EDGE CASES:
  [ ] Giỏ hàng rỗng → empty state
  [ ] Tìm kiếm không có kết quả → empty state
  [ ] Trang cuối pagination không bị out of range
  [ ] Sản phẩm hết hàng → không cho mua
```

---

## 8. STATE MACHINES

### 8.1 Đơn hàng (order_status)

```
TRẠNG THÁI      MÔ TẢ                    AI CẬP NHẬT
─────────────────────────────────────────────────────
pending         Mới tạo, chờ xác nhận    Hệ thống tự động
confirmed       Admin đã xác nhận         Admin
processing      Đang chuẩn bị hàng        Admin
shipping        Đã giao cho shipper        Admin
completed       Khách đã nhận hàng         Admin
cancelled       Đã hủy                    Customer / Admin

TRANSITION HỢP LỆ:
  pending    ──→  confirmed   (Admin xác nhận)
  pending    ──→  cancelled   (Customer hoặc Admin hủy)
  confirmed  ──→  processing  (Admin chuẩn bị hàng)
  confirmed  ──→  cancelled   (Admin hủy)
  processing ──→  shipping    (Admin bàn giao shipper)
  processing ──→  cancelled   (Admin hủy)
  shipping   ──→  completed   (Admin xác nhận giao thành công)
  shipping   ──→  cancelled   (Giao thất bại, hoàn đơn)

CUỐI CÙNG (không chuyển tiếp được):
  completed  ──→  (không được thay đổi)
  cancelled  ──→  (không được thay đổi)
```

### 8.2 Thanh toán (payment_status)

```
TRẠNG THÁI      MÔ TẢ
───────────────────────────────────────────────────────
unpaid          COD chưa thu tiền
pending         Chờ thanh toán (bank transfer / gateway)
paid            Đã thanh toán thành công
failed          Thanh toán thất bại
refunded        Đã hoàn tiền

TRANSITION:
  [COD]
  unpaid → paid   (Admin xác nhận đã thu tiền khi giao hàng)

  [Bank Transfer]
  pending → paid  (Admin xác nhận đã nhận CK)
  pending → failed (Quá hạn, admin hủy đơn)

  [VNPay/MoMo]
  pending → paid   (Gateway callback thành công, verify signature)
  pending → failed (Gateway callback thất bại)

  [Refund]
  paid → refunded  (Khi hủy đơn đã thanh toán)
```

### 8.3 Bảo hành (warranty_requests.status)

```
TRẠNG THÁI      MÔ TẢ
────────────────────────────────────────
pending         Mới gửi, chờ xét duyệt
approved        Admin chấp nhận
rejected        Admin từ chối
processing      Đang xử lý bảo hành
completed       Đã hoàn tất bảo hành

TRANSITION:
  pending    → approved    (Admin chấp nhận)
  pending    → rejected    (Admin từ chối)
  approved   → processing  (Admin bắt đầu xử lý)
  processing → completed   (Admin hoàn tất)
```

---

## 9. ACCEPTANCE CRITERIA

Website được coi là hoàn thành khi TOÀN BỘ checklist sau đạt:

### 9.1 Chức năng khách hàng

```
[ ] Guest xem trang chủ, danh sách sản phẩm, chi tiết sản phẩm
[ ] Guest tìm kiếm và lọc sản phẩm theo keyword, danh mục, giá
[ ] Guest chưa đăng nhập bị redirect /login khi vào /cart, /checkout, /orders
[ ] User đăng ký tài khoản mới thành công
[ ] User đăng nhập với email/password đúng thành công
[ ] User đăng nhập sai password thấy lỗi, không vào được
[ ] User bị khóa tài khoản thấy thông báo khi đăng nhập
[ ] User đăng xuất xóa session
[ ] User cập nhật thông tin cá nhân thành công
[ ] User đổi mật khẩu thành công
[ ] Customer thêm sản phẩm vào giỏ hàng
[ ] Customer cập nhật số lượng trong giỏ
[ ] Customer xóa sản phẩm khỏi giỏ
[ ] Không cho thêm quá số lượng tồn kho
[ ] Sản phẩm hết hàng không cho thêm vào giỏ
[ ] Customer đặt hàng COD thành công
[ ] Customer đặt hàng bank transfer, thấy thông tin chuyển khoản
[ ] Cart bị xóa sau khi đặt hàng thành công
[ ] Customer xem lịch sử đơn hàng của mình
[ ] Customer xem chi tiết đơn hàng
[ ] Customer hủy đơn khi status = pending hoặc confirmed
[ ] Customer không hủy được đơn đã completed
[ ] Customer đánh giá sản phẩm sau khi đơn completed
[ ] Customer không đánh giá được nếu chưa mua hoặc đơn chưa completed
[ ] Customer không đánh giá 2 lần cùng 1 sản phẩm trong 1 đơn
```

### 9.2 Chức năng Admin

```
[ ] Admin đăng nhập vào /admin/dashboard
[ ] Customer bị 403 khi truy cập /admin/*
[ ] Admin thêm sản phẩm với ảnh thành công
[ ] Admin sửa sản phẩm thành công
[ ] Admin ẩn sản phẩm (status = inactive)
[ ] Admin cập nhật tồn kho sản phẩm
[ ] Admin thêm / sửa / xóa danh mục
[ ] Admin xem danh sách đơn hàng, lọc theo trạng thái
[ ] Admin xem chi tiết đơn hàng
[ ] Admin cập nhật order_status theo đúng transition
[ ] Admin không thể cập nhật order đã completed
[ ] Admin xác nhận thanh toán bank transfer
[ ] Admin xem danh sách user
[ ] Admin khóa tài khoản user
[ ] Admin xem và ẩn đánh giá không phù hợp
[ ] Dashboard hiển thị: tổng doanh thu, số đơn theo trạng thái, SP bán chạy
```

### 9.3 Kỹ thuật & Bảo mật

```
[ ] Password được hash bcrypt, không lưu plain text
[ ] SQL injection không thực hiện được (dùng prepared statement)
[ ] XSS không thực hiện được (EJS escape mặc định)
[ ] User A không xem được đơn hàng / địa chỉ của user B
[ ] Transaction rollback khi tạo đơn thất bại giữa chừng
[ ] Tồn kho không bao giờ âm
[ ] Upload ảnh giới hạn mime type và kích thước
[ ] Biến môi trường không expose ra client
[ ] Tất cả route trả về đúng HTTP status code
[ ] Trang lỗi 404 / 403 / 500 hiển thị đẹp, không lộ stack trace
[ ] Giao diện responsive trên mobile 375px
[ ] Không có lỗi nghiêm trọng trong server log và browser console
```

---

## 10. SEED DATA

### 10.1 Admin User

```sql
INSERT INTO users (full_name, email, phone, password_hash, role, status) VALUES
('Admin Hệ Thống', 'admin@household.com', '0901234567',
 '$2b$10$[bcrypt hash của "Admin@123456"]', 'admin', 'active');
```

Password plain text: `Admin@123456`

### 10.2 Customer mẫu

```sql
INSERT INTO users (full_name, email, phone, password_hash, role, status) VALUES
('Nguyễn Văn An', 'customer1@example.com', '0912345678',
 '$2b$10$[bcrypt hash của "Customer@123"]', 'customer', 'active'),
('Trần Thị Bình', 'customer2@example.com', '0923456789',
 '$2b$10$[bcrypt hash của "Customer@123"]', 'customer', 'active');
```

### 10.3 Danh mục (8 danh mục chính)

```sql
INSERT INTO categories (name, slug, description, status, sort_order) VALUES
('Điện thoại & Phụ kiện', 'dien-thoai-phu-kien', 'Smartphone, case, sạc, cáp', 'active', 1),
('Laptop & Máy tính bảng', 'laptop-may-tinh-bang', 'Laptop, tablet, máy tính xách tay', 'active', 2),
('Âm thanh & Tai nghe', 'am-thanh-tai-nghe', 'Tai nghe, loa bluetooth, soundbar', 'active', 3),
('TV & Màn hình', 'tv-man-hinh', 'Smart TV, màn hình máy tính, máy chiếu', 'active', 4),
('Gaming & Console', 'gaming-console', 'Console, tay cầm, gaming gear, PC gaming', 'active', 5),
('Thiết bị đeo thông minh', 'thiet-bi-deo-thong-minh', 'Smartwatch, vòng tay thông minh', 'active', 6),
('Máy ảnh & Quay phim', 'may-anh-quay-phim', 'Máy ảnh mirrorless, DSLR, action cam', 'active', 7),
('Thiết bị mạng & Lưu trữ', 'thiet-bi-mang-luu-tru', 'Router, switch, ổ cứng, USB', 'active', 8);
```

### 10.4 Sản phẩm mẫu (10 sản phẩm)

```sql
-- category_id: 1=Điện thoại, 2=Laptop/Tablet, 3=Âm thanh, 4=TV/Màn hình,
--              5=Gaming, 6=Đồng hồ thông minh, 7=Máy ảnh, 8=Mạng/Lưu trữ
INSERT INTO products (category_id, name, slug, brand, sku, price, sale_price, stock_quantity, description, specifications, warranty_months, status) VALUES
(1, 'Apple iPhone 15 Pro Max 256GB', 'apple-iphone-15-pro-max-256gb', 'Apple', 'SP001', 34990000, 32990000, 30,
 'Chip A17 Pro, màn hình Super Retina XDR 6.7", camera 48MP, Dynamic Island, titanium frame',
 '{"cpu":"A17 Pro","ram":"8GB","storage":"256GB","display":"6.7 Super Retina XDR","camera":"48MP+12MP+12MP","battery":"4422mAh"}',
 12, 'active'),

(1, 'Samsung Galaxy S24 Ultra 512GB', 'samsung-galaxy-s24-ultra-512gb', 'Samsung', 'SP002', 31990000, NULL, 25,
 'Chip Snapdragon 8 Gen 3, màn hình 6.8" Dynamic AMOLED, camera 200MP, bút S Pen, AI Galaxy',
 '{"cpu":"Snapdragon 8 Gen 3","ram":"12GB","storage":"512GB","display":"6.8 Dynamic AMOLED 2X","camera":"200MP+50MP+10MP+12MP","battery":"5000mAh"}',
 12, 'active'),

(2, 'Apple MacBook Air 13" M2 8GB 256GB', 'apple-macbook-air-13-m2-8gb-256gb', 'Apple', 'SP003', 27990000, 25990000, 20,
 'Chip Apple M2, màn hình Liquid Retina 13.6", pin 18 giờ, không quạt tản nhiệt, siêu mỏng nhẹ',
 '{"cpu":"Apple M2","ram":"8GB","storage":"256GB SSD","display":"13.6 Liquid Retina","battery":"18h","weight":"1.24kg"}',
 12, 'active'),

(2, 'ASUS ROG Strix G16 RTX 4060 Gaming', 'asus-rog-strix-g16-rtx-4060', 'ASUS', 'SP004', 32990000, 29990000, 15,
 'Intel Core i7-13650HX, RTX 4060 8GB, RAM 16GB DDR5, SSD 512GB, màn hình 165Hz QHD',
 '{"cpu":"Intel i7-13650HX","ram":"16GB DDR5","storage":"512GB NVMe","gpu":"RTX 4060 8GB","display":"16 QHD 165Hz","weight":"2.5kg"}',
 24, 'active'),

(3, 'Sony WH-1000XM5 Wireless Headphones', 'sony-wh-1000xm5-wireless', 'Sony', 'SP005', 8490000, 7490000, 40,
 'Chống ồn chủ động hàng đầu, pin 30 giờ, kết nối multipoint, codec LDAC hi-res audio',
 '{"type":"Over-ear","connectivity":"Bluetooth 5.2","battery":"30h","anc":"Yes","codec":"LDAC, AAC, SBC","weight":"250g"}',
 12, 'active'),

(4, 'Samsung 55" QLED 4K Smart TV QN90C', 'samsung-55-qled-4k-qn90c', 'Samsung', 'SP006', 22990000, 19990000, 10,
 'Neo QLED 4K, Quantum Matrix Technology, 144Hz, Gaming Hub, Tizen OS, Dolby Atmos',
 '{"size":"55 inch","resolution":"4K 3840x2160","panel":"Neo QLED","refresh":"144Hz","os":"Tizen","hdr":"HDR10+ Dolby Vision"}',
 24, 'active'),

(5, 'Sony PlayStation 5 Slim Disc Edition', 'sony-playstation-5-slim-disc', 'Sony', 'SP007', 13990000, NULL, 12,
 'PS5 Slim phiên bản đọc đĩa, SSD 1TB, 120fps, ray tracing, DualSense controller',
 '{"cpu":"AMD Zen 2 8-core","gpu":"AMD RDNA 2 10.3 TFLOPS","storage":"1TB SSD","resolution":"Up to 8K","fps":"120fps"}',
 12, 'active'),

(6, 'Apple Watch Series 9 GPS 45mm', 'apple-watch-series-9-gps-45mm', 'Apple', 'SP008', 10990000, 9990000, 35,
 'Chip S9, Always-On Retina display, đo SpO2, ECG, nhiệt độ cơ thể, pin 18 giờ, WatchOS 10',
 '{"chip":"S9","display":"45mm Always-On Retina","gps":"Yes","health":"SpO2 ECG Temperature","battery":"18h","water":"50m WR"}',
 12, 'active'),

(7, 'Sony Alpha A7 IV Mirrorless Camera Body', 'sony-alpha-a7-iv-mirrorless-body', 'Sony', 'SP009', 65990000, 61990000, 5,
 'Full-frame 33MP BSI-CMOS, Eye AF tiên tiến, quay 4K 60fps, IBIS 5.5 stops, Dual CFexpress slot',
 '{"sensor":"33MP Full-frame BSI-CMOS","iso":"100-51200","video":"4K 60fps","stabilization":"5.5-stop IBIS","mount":"Sony E","weight":"659g"}',
 12, 'active'),

(8, 'TP-Link Deco XE75 WiFi 6E Mesh (2-pack)', 'tp-link-deco-xe75-wifi6e-2pack', 'TP-Link', 'SP010', 5990000, 5490000, 20,
 'WiFi 6E Tri-band, tốc độ 5400Mbps, phủ sóng 557m², AI-Driven Mesh, PoE port, dễ cài đặt qua app',
 '{"standard":"WiFi 6E AXE5400","bands":"Tri-band 6GHz+5GHz+2.4GHz","coverage":"557m2","ports":"2.5G WAN, 1G LAN","features":"AI Mesh, PoE"}',
 24, 'active');
```

### 10.5 Tạo hash password cho seed

```javascript
// Script để tạo hash (chạy một lần)
const bcrypt = require('bcrypt');

async function generateHashes() {
  const adminHash = await bcrypt.hash('Admin@123456', 10);
  const customerHash = await bcrypt.hash('Customer@123', 10);
  console.log('Admin hash:', adminHash);
  console.log('Customer hash:', customerHash);
}

generateHashes();
// Thay giá trị hash vào seed.sql
```

---

## 11. PROMPT NGẮN CHO AGENT

Sử dụng prompt sau để giao việc cho coding agent:

```
Bạn là full-stack engineer. Build lại hoàn toàn website thương mại điện tử bán đồ gia dụng theo spec này.

STACK:
- Backend: Node.js + Express.js
- View: EJS template engine
- Database: MySQL (mysql2 driver, connection pool)
- Auth: express-session + bcrypt (rounds=10)
- Upload: multer (jpg/png/webp, max 5MB)
- CSS: Bootstrap 5

KIẾN TRÚC:
- Pattern: Controller → Service → Model (raw SQL với prepared statements)
- Tách routes, controllers, services, models rõ ràng
- Cấu trúc thư mục theo spec mục 2.2

BUILD THEO THỨTỰ (skill 01 → 12):
1. Project Setup + layout EJS
2. Database schema (chạy được schema.sql + seed.sql)
3. Authentication (register/login/logout/session/bcrypt)
4. Product Catalog (list/filter/search/detail)
5. Cart (add/update/remove/validate stock)
6. Checkout & Order (create order với transaction)
7. Payment (COD + bank transfer, VNPay sandbox tuỳ chọn)
8. Reviews (permission check + avg_rating update)
9. Warranty Request
10. Admin Dashboard (CRUD SP + quản lý đơn + thống kê)
11. UI/UX (responsive, empty state, flash message)
12. Final QA

BẮT BUỘC:
- Mọi route có input user: validate + prepared statement
- Mọi nghiệp vụ quan trọng: database transaction
- Admin route: requireAdmin middleware
- Password: bcrypt, không lưu plain text
- Order state: chỉ cho phép transition hợp lệ (xem Hook 05)
- Tồn kho: không để âm, cập nhật khi confirm/cancel đơn

OUTPUT BẮT BUỘC:
- README.md: cài đặt Node.js, tạo .env từ .env.example, chạy schema.sql + seed.sql, npm start
- .env.example với đầy đủ biến
- database/schema.sql (DDL 12 bảng)
- database/seed.sql (1 admin + 2 customer + 5 danh mục + 10 sản phẩm)
```

---

*Spec version 1.0 — Đồ án tốt nghiệp — Website TMĐT Đồ Gia Dụng*
