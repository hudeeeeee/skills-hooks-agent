# SKILL 01 — Project Setup

## Mục tiêu
Khởi tạo project Node.js/Express đủ để chạy trang đầu tiên, có layout EJS hoàn chỉnh.

## Output kỳ vọng
- `npm start` chạy không lỗi, http://localhost:3000 trả về trang chủ
- Cấu trúc thư mục đúng theo SPEC.md mục 2.2
- Layout EJS cho public và admin tách biệt

---

## Bước 1 — Khởi tạo project

```bash
npm init -y
npm install express ejs mysql2 bcrypt express-session connect-flash multer dotenv slugify
npm install --save-dev nodemon
```

Thêm vào package.json:
```json
"scripts": {
  "start": "node server.js",
  "dev": "nodemon server.js"
}
```

---

## Bước 2 — Cấu trúc thư mục

Tạo đúng cấu trúc này (xem SPEC.md mục 2.2):

```
src/config/database.js
src/config/env.js
src/controllers/         (tạo thư mục, để trống)
src/middlewares/auth.middleware.js
src/middlewares/admin.middleware.js
src/middlewares/upload.middleware.js
src/middlewares/error.middleware.js
src/models/              (tạo thư mục, để trống)
src/routes/index.routes.js
src/services/            (tạo thư mục, để trống)
src/utils/password.js
src/utils/slug.js
src/utils/formatCurrency.js
src/utils/paginate.js
src/utils/validators.js
src/views/layouts/main.ejs
src/views/layouts/admin.ejs
src/views/partials/header.ejs
src/views/partials/footer.ejs
src/views/partials/navbar.ejs
src/views/partials/flash.ejs
src/views/partials/pagination.ejs
src/views/pages/home.ejs
src/views/errors/404.ejs
src/views/errors/403.ejs
src/views/errors/500.ejs
public/css/style.css
public/css/admin.css
public/js/main.js
public/js/cart.js
public/uploads/.gitkeep
database/schema.sql      (tạo ở Skill 02)
database/seed.sql        (tạo ở Skill 02)
app.js
server.js
.env
.env.example
```

---

## Bước 3 — File .env.example

```env
# Server
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASS=
DB_NAME=electronics_shop

# Session
SESSION_SECRET=your-super-secret-key-change-this-in-production

# Upload
UPLOAD_DIR=public/uploads
MAX_FILE_SIZE=5242880

# Payment (Bank Transfer)
BANK_ACCOUNT_NUMBER=0123456789
BANK_ACCOUNT_NAME=NGUYEN VAN A
BANK_NAME=Vietcombank

# VNPay (Sandbox)
VNPAY_TMN_CODE=
VNPAY_HASH_SECRET=
VNPAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNPAY_RETURN_URL=http://localhost:3000/payment/vnpay/return
```

---

## Bước 4 — src/config/database.js

```javascript
const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  charset: 'utf8mb4'
});

module.exports = pool;
```

---

## Bước 5 — app.js

```javascript
const express = require('express');
const session = require('express-session');
const flash = require('connect-flash');
const path = require('path');
require('dotenv').config();

const app = express();

// View engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'src/views'));

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// Body parsing
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// Session
app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 7 * 24 * 60 * 60 * 1000 }  // 7 ngày
}));

// Flash messages
app.use(flash());

// Locals cho tất cả views
app.use((req, res, next) => {
  res.locals.user = req.session.user || null;
  res.locals.success = req.flash('success');
  res.locals.error = req.flash('error');
  next();
});

// Routes
const routes = require('./src/routes/index.routes');
app.use('/', routes);

// Error handlers
const { notFound, errorHandler } = require('./src/middlewares/error.middleware');
app.use(notFound);
app.use(errorHandler);

module.exports = app;
```

---

## Bước 6 — server.js

```javascript
const app = require('./app');
const pool = require('./src/config/database');

const PORT = process.env.PORT || 3000;

async function start() {
  try {
    await pool.query('SELECT 1');
    console.log('Database connected');
    app.listen(PORT, () => {
      console.log(`Server running at http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error('Database connection failed:', err.message);
    process.exit(1);
  }
}

start();
```

---

## Bước 7 — Middlewares

**src/middlewares/auth.middleware.js:**
```javascript
function requireAuth(req, res, next) {
  if (!req.session.user) {
    req.flash('error', 'Vui lòng đăng nhập để tiếp tục');
    return res.redirect('/login?returnUrl=' + encodeURIComponent(req.originalUrl));
  }
  next();
}
module.exports = { requireAuth };
```

**src/middlewares/admin.middleware.js:**
```javascript
function requireAdmin(req, res, next) {
  if (!req.session.user) return res.redirect('/login');
  if (req.session.user.role !== 'admin') {
    return res.status(403).render('errors/403', { title: 'Không có quyền truy cập' });
  }
  next();
}
module.exports = { requireAdmin };
```

**src/middlewares/upload.middleware.js:**
```javascript
const multer = require('multer');
const path = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, process.env.UPLOAD_DIR || 'public/uploads'),
  filename: (req, file, cb) => {
    const unique = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, unique + path.extname(file.originalname));
  }
});

const fileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/png', 'image/webp'];
  if (allowed.includes(file.mimetype)) cb(null, true);
  else cb(new Error('Chỉ chấp nhận ảnh JPG, PNG, WebP'), false);
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: parseInt(process.env.MAX_FILE_SIZE) || 5242880 }
});

module.exports = upload;
```

**src/middlewares/error.middleware.js:**
```javascript
function notFound(req, res) {
  res.status(404).render('errors/404', { title: 'Trang không tìm thấy' });
}

function errorHandler(err, req, res, next) {
  console.error(err.stack);
  const status = err.status || 500;
  if (process.env.NODE_ENV === 'production') {
    res.status(status).render('errors/500', { title: 'Lỗi hệ thống' });
  } else {
    res.status(status).json({ error: err.message, stack: err.stack });
  }
}

module.exports = { notFound, errorHandler };
```

---

## Bước 8 — Utils

**src/utils/formatCurrency.js:**
```javascript
function formatCurrency(amount) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
}
module.exports = { formatCurrency };
```

**src/utils/paginate.js:**
```javascript
function paginate(totalItems, currentPage, pageSize = 12) {
  const totalPages = Math.ceil(totalItems / pageSize);
  const page = Math.max(1, Math.min(currentPage, totalPages));
  return {
    page,
    pageSize,
    totalItems,
    totalPages,
    offset: (page - 1) * pageSize,
    hasNext: page < totalPages,
    hasPrev: page > 1
  };
}
module.exports = { paginate };
```

**src/utils/validators.js:**
```javascript
const validateEmail = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
const validatePhone = (phone) => /^[0-9]{10,11}$/.test(phone);
const validatePassword = (pass) => pass && pass.length >= 8;
const validatePositiveInt = (n) => Number.isInteger(Number(n)) && Number(n) > 0;
module.exports = { validateEmail, validatePhone, validatePassword, validatePositiveInt };
```

**src/utils/password.js:**
```javascript
const bcrypt = require('bcrypt');
const ROUNDS = 10;
const hash = (plain) => bcrypt.hash(plain, ROUNDS);
const compare = (plain, hashed) => bcrypt.compare(plain, hashed);
module.exports = { hash, compare };
```

---

## Bước 9 — Layout EJS (Top/Bot Partial Pattern)

> **QUAN TRỌNG:** KHÔNG dùng `<%- include(layout, { body: \`...\` }) %>` — EJS tokenizer crash khi body chứa `<% %>` tags.
> Pattern đúng: mỗi view tự include top/bot partials.

**src/views/partials/top.ejs** (mở HTML, navbar, flash):
```html
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><%= typeof title !== 'undefined' ? title + ' | ElectroShop' : 'ElectroShop - Đồ Điện Tử Chính Hãng' %></title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.2/font/bootstrap-icons.css" rel="stylesheet">
  <link href="/css/style.css" rel="stylesheet">
</head>
<body>
  <%- include('./navbar') %>
  <%- include('./flash') %>
  <main class="container py-4">
```

**src/views/partials/bot.ejs** (đóng main, footer, scripts):
```html
  </main>
  <%- include('./footer') %>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
  <script src="/js/main.js"></script>
</body>
</html>
```

**src/views/partials/admin-top.ejs** (admin layout mở):
```html
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><%= typeof title !== 'undefined' ? title + ' | Admin' : 'Admin | ElectroShop' %></title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.2/font/bootstrap-icons.css" rel="stylesheet">
  <link href="/css/style.css" rel="stylesheet">
</head>
<body>
<div class="d-flex" style="min-height:100vh">
  <!-- Sidebar -->
  <nav class="bg-dark text-white" style="width:220px;min-height:100vh">
    <div class="p-3 border-bottom border-secondary">
      <a href="/admin" class="text-white text-decoration-none fw-bold fs-5">
        <i class="bi bi-lightning-charge-fill text-warning me-1"></i>Admin
      </a>
    </div>
    <ul class="nav flex-column p-2 gap-1">
      <li><a href="/admin/dashboard" class="nav-link text-white-50 hover-white"><i class="bi bi-speedometer2 me-2"></i>Dashboard</a></li>
      <li><a href="/admin/products" class="nav-link text-white-50"><i class="bi bi-box-seam me-2"></i>Sản phẩm</a></li>
      <li><a href="/admin/orders" class="nav-link text-white-50"><i class="bi bi-bag me-2"></i>Đơn hàng</a></li>
      <li><a href="/admin/categories" class="nav-link text-white-50"><i class="bi bi-tags me-2"></i>Danh mục</a></li>
      <li><a href="/admin/users" class="nav-link text-white-50"><i class="bi bi-people me-2"></i>Người dùng</a></li>
      <li><a href="/admin/reviews" class="nav-link text-white-50"><i class="bi bi-star me-2"></i>Đánh giá</a></li>
      <li><a href="/admin/warranty" class="nav-link text-white-50"><i class="bi bi-shield-check me-2"></i>Bảo hành</a></li>
      <li class="mt-3"><a href="/logout" class="nav-link text-danger"><i class="bi bi-box-arrow-right me-2"></i>Đăng xuất</a></li>
    </ul>
  </nav>
  <!-- Main content -->
  <div class="flex-grow-1 p-4 bg-light">
    <%- include('./flash') %>
```

**src/views/partials/admin-bot.ejs** (admin layout đóng):
```html
  </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="/js/main.js"></script>
</body>
</html>
```

**Cách dùng trong mỗi view** (ví dụ `pages/home.ejs`):
```ejs
<%- include('../../partials/top') %>
<h1>Nội dung trang</h1>
<% someArray.forEach(item => { %>
  <p><%= item.name %></p>
<% }); %>
<%- include('../../partials/bot') %>
```

**Cách dùng trong admin view** (ví dụ `admin/products/index.ejs`):
```ejs
<%- include('../../partials/admin-top') %>
<h4>Nội dung admin</h4>
<%- include('../../partials/admin-bot') %>
```

**src/views/partials/flash.ejs:**
```html
<div class="container mt-2">
  <% if (success && success.length > 0) { %>
    <div class="alert alert-success alert-dismissible fade show" role="alert">
      <%= success[0] %>
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  <% } %>
  <% if (error && error.length > 0) { %>
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
      <%= error[0] %>
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  <% } %>
</div>
<script>
  setTimeout(() => {
    document.querySelectorAll('.alert').forEach(el => {
      new bootstrap.Alert(el).close();
    });
  }, 4000);
</script>
```

---

## Bước 10 — Trang chủ tạm + Route kiểm tra

**src/routes/index.routes.js:**
```javascript
const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.render('pages/home', { title: 'Trang chủ', layout: 'main' });
});

module.exports = router;
```

---

## Checklist xác nhận ✅

```
[x] npm install không lỗi
[x] node server.js → "Database connected" + "Server running"
[x] http://localhost:3000 → trả về trang chủ, không lỗi 500
[x] Layout main.ejs render không lỗi EJS syntax
[x] Flash message hiển thị và tự ẩn sau 4 giây
[x] Static files (CSS, JS) load được
[x] req.session.user = null khi chưa đăng nhập → navbar hiển thị "Đăng nhập"
[x] URL không tồn tại → trang 404 đẹp
```

## Sau khi xong skill này

Chạy: `bash hooks/hook-10-qa.sh 01`
