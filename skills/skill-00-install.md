# SKILL 00 — Install & Project Init

## Mục tiêu
Khởi tạo thư mục project, cài toàn bộ dependencies, tạo cấu trúc thư mục trống, cấu hình .gitignore.

## Chạy TRƯỚC skill-01. Không skip.

---

## Bước 1 — Tạo thư mục project

```bash
mkdir electroshop
cd electroshop
npm init -y
```

---

## Bước 2 — Cài Production Dependencies (version cố định)

```bash
npm install \
  express@4.18.2 \
  ejs@3.1.10 \
  mysql2@3.9.7 \
  bcrypt@5.1.1 \
  express-session@1.18.0 \
  connect-flash@0.1.1 \
  multer@1.4.5-lts.1 \
  dotenv@16.4.5 \
  slugify@1.6.6
```

### Giải thích từng package

| Package | Version | Dùng cho |
|---------|---------|---------|
| express | 4.18.2 | Web framework chính |
| ejs | 3.1.10 | Template engine render HTML |
| mysql2 | 3.9.7 | MySQL driver, Promise/async-await, prepared statements |
| bcrypt | 5.1.1 | Hash mật khẩu (rounds=10) |
| express-session | 1.18.0 | Session management (đăng nhập) |
| connect-flash | 0.1.1 | Flash message success/error |
| multer | 1.4.5-lts.1 | Upload ảnh sản phẩm (LTS = bản vá bảo mật) |
| dotenv | 16.4.5 | Load biến môi trường từ .env |
| slugify | 1.6.6 | Tạo slug URL từ tên sản phẩm/danh mục |

### Không cần cài (built-in Node.js >= 18)

| Module | Dùng cho |
|--------|---------|
| `crypto` | HMAC-SHA512 cho VNPay signature |
| `path` | Xử lý đường dẫn file |
| `querystring` | Build VNPay payment URL query string |

---

## Bước 3 — Cài Dev Dependencies

```bash
npm install --save-dev \
  nodemon@3.1.3
```

| Package | Version | Dùng cho |
|---------|---------|---------|
| nodemon | 3.1.3 | Auto-restart server khi sửa code (dev only) |

---

## Bước 3b — Kiểm tra package.json sau khi cài

Sau khi chạy xong npm install, `package.json` phải có **đúng** các dependencies sau.
Nếu thiếu package nào, cài bổ sung bằng lệnh `npm install <package>@<version>`:

```json
{
  "name": "electroshop",
  "version": "1.0.0",
  "description": "Website TMDT Ban Do Dien Tu - Do An Tot Nghiep",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "db:schema": "mysql -u root -p electronics_shop < database/schema.sql",
    "db:seed": "mysql -u root -p electronics_shop < database/seed.sql",
    "db:hash": "node database/generate-hash.js"
  },
  "dependencies": {
    "bcrypt": "^5.1.1",
    "connect-flash": "^0.1.1",
    "dotenv": "^16.4.5",
    "ejs": "^3.1.10",
    "express": "^4.18.2",
    "express-session": "^1.18.0",
    "multer": "^1.4.5-lts.1",
    "mysql2": "^3.9.7",
    "slugify": "^1.6.6"
  },
  "devDependencies": {
    "nodemon": "^3.1.3"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

> **Lưu ý `multer`:** Phải dùng `1.4.5-lts.1` — đây là bản LTS vá lỗ hổng bảo mật.
> Không dùng multer `2.x` (breaking changes, API khác).

---

## Bước 3c — Verify packages sau khi cài

```bash
node -e "
const required = [
  'express', 'ejs', 'mysql2', 'bcrypt',
  'express-session', 'connect-flash',
  'multer', 'dotenv', 'slugify'
];
let ok = true;
required.forEach(pkg => {
  try {
    const p = require(pkg);
    const v = require('./node_modules/' + pkg + '/package.json').version;
    console.log('✅', pkg, '@' + v);
  } catch(e) {
    console.log('❌', pkg, '— MISSING, chạy: npm install ' + pkg);
    ok = false;
  }
});
// Built-in check
['crypto','path','querystring'].forEach(mod => {
  try { require(mod); console.log('✅', mod, '(built-in)'); }
  catch(e) { console.log('❌', mod, '— Node.js version quá cũ?'); }
});
if (!ok) process.exit(1);
"
```

---

## Bước 4 — Cập nhật package.json scripts

Mở `package.json`, thay `"scripts"`:

```json
"scripts": {
  "start": "node server.js",
  "dev": "nodemon server.js",
  "db:schema": "mysql -u root -p $DB_NAME < database/schema.sql",
  "db:seed": "mysql -u root -p $DB_NAME < database/seed.sql",
  "db:hash": "node database/generate-hash.js"
}
```

---

## Bước 5 — Tạo cấu trúc thư mục đầy đủ

```bash
# Config
mkdir -p src/config

# Controllers
mkdir -p src/controllers/admin

# Middlewares
mkdir -p src/middlewares

# Models
mkdir -p src/models

# Routes
mkdir -p src/routes

# Services
mkdir -p src/services

# Utils
mkdir -p src/utils

# Views
mkdir -p src/views/layouts
mkdir -p src/views/partials
mkdir -p src/views/pages/products
mkdir -p src/views/pages/orders
mkdir -p src/views/pages/profile
mkdir -p src/views/pages/payment
mkdir -p src/views/pages/warranty
mkdir -p src/views/auth
mkdir -p src/views/errors
mkdir -p src/views/admin/products
mkdir -p src/views/admin/orders
mkdir -p src/views/admin/users
mkdir -p src/views/admin/reviews
mkdir -p src/views/admin/warranty
mkdir -p src/views/admin/categories

# Public assets
mkdir -p public/css
mkdir -p public/js
mkdir -p public/images
mkdir -p public/uploads

# Database scripts
mkdir -p database
```

Lệnh gộp 1 dòng (Linux/Mac):

```bash
mkdir -p src/{config,controllers/admin,middlewares,models,routes,services,utils} \
  src/views/{layouts,partials,auth,errors} \
  src/views/pages/{products,orders,profile,payment,warranty} \
  src/views/admin/{products,orders,users,reviews,warranty,categories} \
  public/{css,js,images,uploads} \
  database
```

---

## Bước 6 — Tạo .gitignore

```bash
cat > .gitignore << 'EOF'
# Dependencies
node_modules/

# Environment
.env
.env.local
.env.production

# Uploads (giữ thư mục, ignore nội dung)
public/uploads/*
!public/uploads/.gitkeep

# Logs
*.log
npm-debug.log*

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
EOF
```

---

## Bước 7 — Tạo placeholder files

```bash
# Giữ thư mục uploads trong git
touch public/uploads/.gitkeep

# Placeholder ảnh
touch public/images/no-image.png
# (copy ảnh placeholder thực vào đây sau)
```

---

## Bước 8 — Tạo .env từ template

```bash
cat > .env.example << 'EOF'
# Server
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASS=
DB_NAME=electronics_shop

# Session (đổi thành chuỗi ngẫu nhiên dài >= 32 ký tự)
SESSION_SECRET=change-this-to-random-32-char-string

# Upload
UPLOAD_DIR=public/uploads
MAX_FILE_SIZE=5242880

# Payment - Bank Transfer
BANK_ACCOUNT_NUMBER=0123456789
BANK_ACCOUNT_NAME=NGUYEN VAN A
BANK_NAME=Vietcombank

# VNPay Sandbox (để trống nếu không dùng)
VNPAY_TMN_CODE=
VNPAY_HASH_SECRET=
VNPAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNPAY_RETURN_URL=http://localhost:3000/payment/vnpay/return
VNPAY_IPN_URL=http://localhost:3000/payment/vnpay/ipn
EOF

# Copy sang .env thực
cp .env.example .env
echo "⚠️  Mở .env và điền DB_PASS + SESSION_SECRET"
```

---

## Bước 9 — Tạo MySQL database

```bash
# Đăng nhập MySQL
mysql -u root -p

# Trong MySQL shell:
CREATE DATABASE IF NOT EXISTS electronics_shop
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

SHOW DATABASES;  -- xác nhận electronics_shop có trong list
EXIT;
```

---

## Bước 10 — Verify cài đặt

```bash
# Kiểm tra Node packages
node -e "
const pkgs = ['express','ejs','mysql2','bcrypt','express-session','connect-flash','multer','dotenv','slugify'];
pkgs.forEach(p => {
  try { require(p); console.log('✅', p); }
  catch(e) { console.log('❌', p, '— chưa cài'); }
});
"

# Kiểm tra kết nối MySQL
node -e "
require('dotenv').config();
const mysql = require('mysql2/promise');
mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME
}).query('SELECT 1').then(() => {
  console.log('✅ MySQL connected');
  process.exit(0);
}).catch(e => {
  console.log('❌ MySQL error:', e.message);
  process.exit(1);
});
"
```

---

## Bước 11 — Tạo file tạm để test server

```bash
cat > app.js << 'EOF'
const express = require('express');
require('dotenv').config();
const app = express();
app.get('/', (req, res) => res.send('ElectroShop — OK'));
module.exports = app;
EOF

cat > server.js << 'EOF'
const app = require('./app');
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server: http://localhost:${PORT}`));
EOF

node server.js
# Kết quả: Server: http://localhost:3000
# http://localhost:3000 → "ElectroShop — OK"
```

> app.js và server.js này sẽ được viết lại hoàn chỉnh ở Skill 01.

---

## Checklist xác nhận ✅

```
[x] node_modules/ tồn tại
[x] npm install không có ERROR (warning OK)
[x] package.json có đúng 9 dependencies + 1 devDependency
[x] multer version = 1.4.5-lts.1 (không phải 2.x)
[x] Tất cả thư mục trong Bước 5 tồn tại
[x] .env tồn tại và đã điền DB_PASS
[x] SESSION_SECRET đã đổi khỏi default
[x] .gitignore tồn tại, có node_modules và .env
[x] public/uploads/.gitkeep tồn tại
[x] Database electronics_shop tồn tại trong MySQL
[x] node verify-script (Bước 3c) → 9 packages ✅ + 3 built-in ✅
[x] MySQL connection test (Bước 10) → ✅ connected
[x] node server.js → "Server: http://localhost:3000"
[x] curl http://localhost:3000 hoặc browser → "ElectroShop — OK"
```

## Sau khi xong: chạy Skill 01

```bash
bash ../hooks/hook-01-prebuild.sh 01
```

Nếu pass → bắt đầu `skills/skill-01-setup.md`.
