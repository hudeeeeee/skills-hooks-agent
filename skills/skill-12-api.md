# SKILL 12 — API Route Audit & Final Wiring

## Mục tiêu
Kiểm tra toàn bộ routes đã đủ, mount đúng, middleware đúng. Wiring hoàn chỉnh.

---

## Bước 1 — index.routes.js hoàn chỉnh

```javascript
const express = require('express');
const router = express.Router();

// Public routes
router.use('/', require('./product.routes'));
router.use('/', require('./auth.routes'));

// Protected routes (auth check nằm trong từng route file)
router.use('/', require('./cart.routes'));
router.use('/', require('./order.routes'));
router.use('/', require('./payment.routes'));
router.use('/', require('./review.routes'));
router.use('/', require('./warranty.routes'));
router.use('/', require('./profile.routes'));

// Admin routes
router.use('/admin', require('./admin.routes'));

module.exports = router;
```

---

## Bước 2 — Route audit checklist

Với mỗi route dưới đây, xác nhận: **tồn tại**, **middleware đúng**, **controller tồn tại**, **view tồn tại**.

### Public (không cần auth)

| Method | Path | Middleware | Status |
|--------|------|-----------|--------|
| GET | / | — | [ ] |
| GET | /products | — | [ ] |
| GET | /products/:slug | — | [ ] |
| GET | /categories/:slug | — | [ ] |
| GET | /search | — | [ ] |
| GET | /login | — | [ ] |
| POST | /login | — | [ ] |
| GET | /register | — | [ ] |
| POST | /register | — | [ ] |

### Protected (requireAuth)

| Method | Path | Middleware | Status |
|--------|------|-----------|--------|
| POST | /logout | requireAuth | [ ] |
| GET | /cart | requireAuth | [ ] |
| POST | /cart/add | requireAuth | [ ] |
| PATCH | /cart/items/:id | requireAuth | [ ] |
| DELETE | /cart/items/:id | requireAuth | [ ] |
| GET | /checkout | requireAuth | [ ] |
| POST | /orders | requireAuth | [ ] |
| GET | /orders | requireAuth | [ ] |
| GET | /orders/:code | requireAuth | [ ] |
| POST | /orders/:code/cancel | requireAuth | [ ] |
| GET | /payment/bank-info/:code | requireAuth | [ ] |
| GET | /payment/vnpay/create | requireAuth | [ ] |
| GET | /payment/vnpay/return | — | [ ] |
| POST | /payment/vnpay/ipn | — | [ ] |
| POST | /reviews | requireAuth | [ ] |
| POST | /warranty | requireAuth | [ ] |
| GET | /profile | requireAuth | [ ] |
| POST | /profile | requireAuth | [ ] |
| GET | /profile/addresses | requireAuth | [ ] |
| POST | /profile/addresses | requireAuth | [ ] |
| PUT | /profile/addresses/:id | requireAuth | [ ] |
| DELETE | /profile/addresses/:id | requireAuth | [ ] |
| GET | /profile/change-password | requireAuth | [ ] |
| POST | /profile/change-password | requireAuth | [ ] |

### Admin (requireAdmin)

| Method | Path | Middleware | Status |
|--------|------|-----------|--------|
| GET | /admin/dashboard | requireAdmin | [ ] |
| GET | /admin/products | requireAdmin | [ ] |
| GET | /admin/products/create | requireAdmin | [ ] |
| POST | /admin/products | requireAdmin + upload | [ ] |
| GET | /admin/products/:id/edit | requireAdmin | [ ] |
| POST | /admin/products/:id | requireAdmin + upload | [ ] |
| POST | /admin/products/:id/delete | requireAdmin | [ ] |
| GET | /admin/categories | requireAdmin | [ ] |
| POST | /admin/categories | requireAdmin | [ ] |
| POST | /admin/categories/:id | requireAdmin | [ ] |
| POST | /admin/categories/:id/delete | requireAdmin | [ ] |
| GET | /admin/orders | requireAdmin | [ ] |
| GET | /admin/orders/:id | requireAdmin | [ ] |
| POST | /admin/orders/:id/status | requireAdmin | [ ] |
| POST | /admin/orders/:id/confirm-payment | requireAdmin | [ ] |
| GET | /admin/users | requireAdmin | [ ] |
| POST | /admin/users/:id/status | requireAdmin | [ ] |
| GET | /admin/reviews | requireAdmin | [ ] |
| POST | /admin/reviews/:id/status | requireAdmin | [ ] |
| GET | /admin/warranty | requireAdmin | [ ] |
| POST | /admin/warranty/:id/status | requireAdmin | [ ] |

---

## Bước 3 — profile.routes.js (nếu chưa có)

```javascript
const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { requireAuth } = require('../middlewares/auth.middleware');

router.use(requireAuth);

router.get('/profile', async (req, res) => {
  const [[user]] = await pool.query('SELECT id,full_name,email,phone,avatar_url,created_at FROM users WHERE id = ?', [req.session.user.id]);
  res.render('pages/profile/index', { title: 'Thông tin cá nhân', profileUser: user });
});

router.post('/profile', async (req, res) => {
  const { full_name, phone } = req.body;
  await pool.query('UPDATE users SET full_name = ?, phone = ?, updated_at = NOW() WHERE id = ?',
    [full_name?.trim(), phone || null, req.session.user.id]);
  // Cập nhật session
  req.session.user.full_name = full_name?.trim();
  req.flash('success', 'Đã cập nhật thông tin');
  res.redirect('/profile');
});

router.get('/profile/addresses', async (req, res) => {
  const [addresses] = await pool.query('SELECT * FROM addresses WHERE user_id = ? ORDER BY is_default DESC', [req.session.user.id]);
  res.render('pages/profile/addresses', { title: 'Địa chỉ giao hàng', addresses });
});

router.post('/profile/addresses', async (req, res) => {
  const { receiver_name, receiver_phone, province, district, ward, detail, is_default } = req.body;
  if (is_default) {
    await pool.query('UPDATE addresses SET is_default = 0 WHERE user_id = ?', [req.session.user.id]);
  }
  await pool.query(
    'INSERT INTO addresses (user_id, receiver_name, receiver_phone, province, district, ward, detail, is_default) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [req.session.user.id, receiver_name, receiver_phone, province, district, ward, detail, is_default ? 1 : 0]
  );
  req.flash('success', 'Đã thêm địa chỉ');
  res.redirect('/profile/addresses');
});

router.delete('/profile/addresses/:id', async (req, res) => {
  await pool.query('DELETE FROM addresses WHERE id = ? AND user_id = ?', [req.params.id, req.session.user.id]);
  res.json({ success: true });
});

module.exports = router;
```

---

## Bước 4 — Kiểm tra error handling

```javascript
// Wrap async controller để không bị unhandled promise rejection
// Dùng wrapper này thay vì try/catch lặp lại:
function asyncHandler(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}
module.exports = { asyncHandler };

// Dùng trong routes:
router.get('/products', asyncHandler(ctrl.getProducts));
```

---

## Bước 5 — Kiểm tra security headers

Thêm vào app.js:

```javascript
// Basic security headers (production)
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  next();
});
```

---

## Bước 6 — README.md

Tạo README.md với nội dung:

```markdown
# ElectroShop — Website TMĐT Đồ Điện Tử

## Cài đặt

### Yêu cầu
- Node.js >= 18
- MySQL >= 8.0
- phpMyAdmin (tuỳ chọn)

### Bước 1: Clone và cài dependencies
npm install

### Bước 2: Cấu hình môi trường
cp .env.example .env
# Chỉnh sửa .env: DB_HOST, DB_USER, DB_PASS, DB_NAME, SESSION_SECRET

### Bước 3: Tạo database
mysql -u root -p -e "CREATE DATABASE electronics_shop CHARACTER SET utf8mb4;"
mysql -u root -p electronics_shop < database/schema.sql

### Bước 4: Tạo bcrypt hash và seed data
node database/generate-hash.js
# Copy hash vào database/seed.sql (thay PLACEHOLDER)
mysql -u root -p electronics_shop < database/seed.sql

### Bước 5: Chạy project
npm run dev       # Development (nodemon)
npm start         # Production

## Tài khoản mặc định
Admin: admin@electroshop.com / Admin@123456
Customer: an@example.com / Customer@123

## Cấu trúc thư mục
Xem SPEC.md mục 2.2
```

---

## Checklist xác nhận ✅ (Final QA)

```
ROUTES:
[ ] Tất cả route trong bảng audit tồn tại, không 404
[ ] POST route không accessible qua GET
[ ] Route không tồn tại → 404 đẹp

SECURITY:
[ ] Không có plain password trong DB
[ ] /admin/* bị block với customer (403) và guest (redirect login)
[ ] User A không xem đơn/địa chỉ user B
[ ] SQL injection không thực hiện được
[ ] XSS input được escape

BUSINESS LOGIC:
[ ] Order flow đầy đủ: tạo → xác nhận → giao → hoàn thành
[ ] Stock không bao giờ âm
[ ] Payment chỉ set paid sau verify
[ ] Review chỉ sau completed

PRODUCTION READY:
[ ] .env không commit (trong .gitignore)
[ ] Upload dir trong .gitignore (giữ .gitkeep)
[ ] NODE_ENV=production ẩn stack trace
[ ] README.md đầy đủ hướng dẫn
[ ] package.json có start script
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 12`
