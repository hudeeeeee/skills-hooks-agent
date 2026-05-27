# SKILL 00 — Install & Project Init

## Thông tin đồ án

**Sinh viên thực hiện:** Huy Đạt
- Facebook: https://www.facebook.com/hudeeeeeee
- Email: dat1404040404@gmail.com
- Số điện thoại: 0943722051 (Zalo)
- Ngân hàng: 04179934401 - TP Bank

**Trường:** Trường Đại học Mỏ - Địa chất  
**Lớp:** dcctct67-04b  
**Đề tài:** Website thương mại điện tử bán đồ điện tử

**Note:** Thông tin liên hệ hiển thị trong footer website với:
- Icons màu vàng (text-warning)
- Text màu trắng (text-light) trên nền tối
- Facebook link đầu tiên, sau đó phone, email, bank, school, class
- QR code 150px dưới contact info

---

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
mkdir -p public/img

# Database scripts
mkdir -p database
```

Lệnh gộp 1 dòng (Linux/Mac):

```bash
mkdir -p src/{config,controllers/admin,middlewares,models,routes,services,utils} \
  src/views/{layouts,partials,auth,errors} \
  src/views/pages/{products,orders,profile,payment,warranty} \
  src/views/admin/{products,orders,users,reviews,warranty,categories} \
  public/{css,js,images,img} \
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
public/img/*
!public/img/.gitkeep

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
# Giữ thư mục img trong git
touch public/img/.gitkeep

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
UPLOAD_DIR=public/img
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

## Bước 12 — Docker Deployment (Optional)

### 12.1 Tạo Dockerfile

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN mkdir -p public/img
EXPOSE 3000
CMD ["node", "server.js"]
```

### 12.2 docker-compose.yml (Dev — build local)

```yaml
services:
  db:
    image: mysql:8.0
    container_name: electroshop_db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: electronics_shop
      MYSQL_USER: admin123
      MYSQL_PASSWORD: admin123
    volumes:
      - db_data:/var/lib/mysql
      - ./database/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
      - ./database/seed.sql:/docker-entrypoint-initdb.d/02-seed.sql
    ports:
      - "3307:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "admin123", "-padmin123"]
      interval: 5s
      timeout: 5s
      retries: 10

  app:
    build: .
    container_name: electroshop_app
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    env_file: .env
    environment:
      PORT: 3000
      NODE_ENV: production
      DB_HOST: db
      DB_PORT: 3306
      DB_USER: admin123
      DB_PASS: admin123
      DB_NAME: electronics_shop
      SESSION_SECRET: electroshop-secret-key-2024-datn-hude
      UPLOAD_DIR: public/img
      MAX_FILE_SIZE: 5242880
      BANK_ACCOUNT_NUMBER: "0417934401"
      BANK_ACCOUNT_NAME: DO HUY DAT
      BANK_NAME: MB Bank
    ports:
      - "3000:3000"
    volumes:
      - img_data:/app/public/img

  ngrok:
    image: ngrok/ngrok:latest
    container_name: electroshop_ngrok
    restart: unless-stopped
    environment:
      NGROK_AUTHTOKEN: ${NGROK_AUTHTOKEN:-}
    command:
      - "http"
      - "app:3000"
    ports:
      - "4040:4040"
    depends_on:
      - app

volumes:
  db_data:
  img_data:
```

### 12.3 docker-compose.prod.yml (Prod — pull pre-built image)

```yaml
services:
  db:
    image: mysql:8.0
    container_name: electroshop_db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: electronics_shop
      MYSQL_USER: admin123
      MYSQL_PASSWORD: admin123
    volumes:
      - db_data:/var/lib/mysql
      - ./database/schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
      - ./database/seed.sql:/docker-entrypoint-initdb.d/02-seed.sql
    ports:
      - "3307:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "admin123", "-padmin123"]
      interval: 5s
      timeout: 5s
      retries: 10

  app:
    image: haiptjits/electroshop:latest
    container_name: electroshop_app
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      PORT: 3000
      NODE_ENV: production
      DB_HOST: db
      DB_PORT: 3306
      DB_USER: admin123
      DB_PASS: admin123
      DB_NAME: electronics_shop
      SESSION_SECRET: electroshop-secret-key-2024-datn-hude
      UPLOAD_DIR: public/img
      MAX_FILE_SIZE: 5242880
      BANK_ACCOUNT_NUMBER: "0417934401"
      BANK_ACCOUNT_NAME: DO HUY DAT
      BANK_NAME: MB Bank
      VNPAY_TMN_CODE: ${VNPAY_TMN_CODE:-DEMO1234}
      VNPAY_HASH_SECRET: ${VNPAY_HASH_SECRET:-DEMOSECRET1234567890ABCDEF123456}
      VNPAY_URL: ${VNPAY_URL:-https://sandbox.vnpayment.vn/paymentv2/vpcpay.html}
      VNPAY_RETURN_URL: ${VNPAY_RETURN_URL:-http://localhost:3000/payment/vnpay/return}
      VNPAY_IPN_URL: ${VNPAY_IPN_URL:-http://localhost:3000/payment/vnpay/ipn}
      NGROK_AUTHTOKEN: ${NGROK_AUTHTOKEN:-}
    ports:
      - "3000:3000"
    volumes:
      - img_data:/app/public/img

  ngrok:
    image: ngrok/ngrok:latest
    container_name: electroshop_ngrok
    restart: unless-stopped
    environment:
      NGROK_AUTHTOKEN: ${NGROK_AUTHTOKEN:-}
    command:
      - "http"
      - "app:3000"
    ports:
      - "4040:4040"
    depends_on:
      - app

volumes:
  db_data:
  img_data:
```

### 12.4 docker-compose.pull.yml (One-command deploy — pre-seeded DB image)

```yaml
services:
  db:
    image: haiptjits/electroshop-db:latest
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: electronics_shop
      MYSQL_USER: admin123
      MYSQL_PASSWORD: admin123
    volumes:
      - db_data:/var/lib/mysql
    ports:
      - "3307:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "admin123", "-padmin123"]
      interval: 5s
      timeout: 5s
      retries: 10

  app:
    image: haiptjits/electroshop:latest
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      PORT: 3000
      NODE_ENV: production
      DB_HOST: db
      DB_PORT: 3306
      DB_USER: admin123
      DB_PASS: admin123
      DB_NAME: electronics_shop
      SESSION_SECRET: electroshop-secret-key-2024-datn-hude
      UPLOAD_DIR: public/img
      MAX_FILE_SIZE: 5242880
      BANK_ACCOUNT_NUMBER: "0417934401"
      BANK_ACCOUNT_NAME: DO HUY DAT
      BANK_NAME: MB Bank
      VNPAY_TMN_CODE: DEMO1234
      VNPAY_HASH_SECRET: DEMOSECRET1234567890ABCDEF123456
      VNPAY_URL: https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
      VNPAY_RETURN_URL: http://localhost:3000/payment/vnpay/return
      VNPAY_IPN_URL: http://localhost:3000/payment/vnpay/ipn
    ports:
      - "3000:3000"
    volumes:
      - img_data:/app/public/img

  ngrok:
    image: ngrok/ngrok:latest
    container_name: electroshop_ngrok
    restart: unless-stopped
    environment:
      NGROK_AUTHTOKEN: ${NGROK_AUTHTOKEN:-}
    command:
      - "http"
      - "app:3000"
    ports:
      - "4040:4040"
    depends_on:
      - app

volumes:
  db_data:
  img_data:
```

### 12.5 setup.sh (One-command deploy từ bất kỳ máy nào)

```bash
#!/bin/bash
# Tải docker-compose.pull.yml (dùng ảnh pre-seeded DB)
curl -fsSL https://raw.githubusercontent.com/hudeeeeee/website/main/docker-compose.pull.yml -o docker-compose.yml

export NGROK_AUTHTOKEN=<YOUR_NGROK_TOKEN>

docker compose pull
docker compose up -d

echo "Waiting for ngrok..."
for i in $(seq 1 20); do
  URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | \
    python3 -c "import sys,json; data=json.load(sys.stdin); \
    print(next((t['public_url'] for t in data.get('tunnels',[]) \
    if t['public_url'].startswith('https')), ''))" 2>/dev/null)
  if [ -n "$URL" ]; then
    echo ""
    echo "================================"
    echo "Ngrok URL: $URL"
    echo "================================"
    break
  fi
  sleep 1
done

if [ -z "$URL" ]; then
  echo "Ngrok not ready — check http://localhost:4040"
fi
```

### 12.6 Docker Commands

**Dev (build local):**
```bash
docker compose up -d --build
```

**Prod (pull pre-built):**
```bash
docker compose -f docker-compose.prod.yml up -d
```

**One-command deploy (máy mới, không cần source):**
```bash
bash setup.sh
```

**Push images lên Docker Hub:**
```bash
docker build -t haiptjits/electroshop:latest .
docker push haiptjits/electroshop:latest
```

**Docker Hub images:**
- `haiptjits/electroshop:latest` — app image
- `haiptjits/electroshop-db:latest` — MySQL pre-seeded với schema + seed data

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
[x] public/img/.gitkeep tồn tại
[x] Database electronics_shop tồn tại trong MySQL
[x] node verify-script (Bước 3c) → 9 packages ✅ + 3 built-in ✅
[x] MySQL connection test (Bước 10) → ✅ connected
[x] node server.js → "Server: http://localhost:3000"
[x] curl http://localhost:3000 hoặc browser → "ElectroShop — OK"
[x] Docker: docker compose up -d → 3 containers healthy
[x] Docker: curl localhost:4040/api/tunnels → ngrok URL (nếu có NGROK_AUTHTOKEN)
```

## Sau khi xong: chạy Skill 01

```bash
bash ../hooks/hook-01-prebuild.sh 01
```

Nếu pass → bắt đầu `skills/skill-01-setup.md`.
