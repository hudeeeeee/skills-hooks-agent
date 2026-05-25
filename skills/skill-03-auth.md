# SKILL 03 — Authentication

## Mục tiêu
Register / Login / Logout hoạt động. Session bảo vệ route. Middleware phân quyền.

## Files cần tạo/sửa
```
src/controllers/auth.controller.js
src/services/auth.service.js
src/routes/auth.routes.js          (mount vào index.routes.js)
src/views/auth/login.ejs
src/views/auth/register.ejs
src/views/auth/forgot-password.ejs
```

---

## Bước 1 — auth.service.js

```javascript
const pool = require('../config/database');
const { hash, compare } = require('../utils/password');
const { validateEmail, validatePhone, validatePassword } = require('../utils/validators');

async function register({ full_name, email, phone, password, confirm_password }) {
  const errors = [];
  if (!full_name || full_name.trim().length < 2) errors.push('Họ tên ít nhất 2 ký tự');
  if (!validateEmail(email)) errors.push('Email không hợp lệ');
  if (phone && !validatePhone(phone)) errors.push('Số điện thoại không hợp lệ');
  if (!validatePassword(password)) errors.push('Mật khẩu ít nhất 8 ký tự');
  if (password !== confirm_password) errors.push('Mật khẩu xác nhận không khớp');
  if (errors.length) return { success: false, errors };

  const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email.toLowerCase()]);
  if (existing.length) return { success: false, errors: ['Email đã được sử dụng'] };

  const password_hash = await hash(password);
  const [result] = await pool.query(
    'INSERT INTO users (full_name, email, phone, password_hash) VALUES (?, ?, ?, ?)',
    [full_name.trim(), email.toLowerCase(), phone || null, password_hash]
  );
  return { success: true, userId: result.insertId };
}

async function login({ email, password }) {
  if (!email || !password) return { success: false, error: 'Vui lòng nhập đầy đủ thông tin' };

  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email.toLowerCase()]);
  if (!rows.length) return { success: false, error: 'Email hoặc mật khẩu không đúng' };

  const user = rows[0];
  if (user.status === 'blocked') return { success: false, error: 'Tài khoản của bạn đã bị khoá' };

  const match = await compare(password, user.password_hash);
  if (!match) return { success: false, error: 'Email hoặc mật khẩu không đúng' };

  // Không trả về password_hash ra ngoài
  const { password_hash, ...safeUser } = user;
  return { success: true, user: safeUser };
}

async function changePassword(userId, { current_password, new_password, confirm_new_password }) {
  if (!validatePassword(new_password)) return { success: false, error: 'Mật khẩu mới ít nhất 8 ký tự' };
  if (new_password !== confirm_new_password) return { success: false, error: 'Mật khẩu xác nhận không khớp' };

  const [rows] = await pool.query('SELECT password_hash FROM users WHERE id = ?', [userId]);
  if (!rows.length) return { success: false, error: 'Người dùng không tồn tại' };

  const match = await compare(current_password, rows[0].password_hash);
  if (!match) return { success: false, error: 'Mật khẩu hiện tại không đúng' };

  const newHash = await hash(new_password);
  await pool.query('UPDATE users SET password_hash = ? WHERE id = ?', [newHash, userId]);
  return { success: true };
}

module.exports = { register, login, changePassword };
```

---

## Bước 2 — auth.controller.js

```javascript
const authService = require('../services/auth.service');

// GET /login
const getLogin = (req, res) => {
  if (req.session.user) return res.redirect('/');
  res.render('auth/login', { title: 'Đăng nhập', returnUrl: req.query.returnUrl || '/' });
};

// POST /login
const postLogin = async (req, res) => {
  const { email, password } = req.body;
  const result = await authService.login({ email, password });

  if (!result.success) {
    req.flash('error', result.error);
    return res.redirect('/login');
  }

  req.session.user = result.user;
  const returnUrl = req.body.returnUrl || '/';

  if (result.user.role === 'admin') return res.redirect('/admin/dashboard');
  res.redirect(returnUrl);
};

// GET /register
const getRegister = (req, res) => {
  if (req.session.user) return res.redirect('/');
  res.render('auth/register', { title: 'Đăng ký tài khoản' });
};

// POST /register
const postRegister = async (req, res) => {
  const result = await authService.register(req.body);

  if (!result.success) {
    req.flash('error', result.errors.join('. '));
    return res.redirect('/register');
  }

  req.flash('success', 'Đăng ký thành công! Vui lòng đăng nhập.');
  res.redirect('/login');
};

// POST /logout
const logout = (req, res) => {
  req.session.destroy(() => res.redirect('/login'));
};

// GET /profile/change-password
const getChangePassword = (req, res) => {
  res.render('profile/change-password', { title: 'Đổi mật khẩu' });
};

// POST /profile/change-password
const postChangePassword = async (req, res) => {
  const result = await authService.changePassword(req.session.user.id, req.body);
  if (!result.success) {
    req.flash('error', result.error);
    return res.redirect('/profile/change-password');
  }
  req.flash('success', 'Đổi mật khẩu thành công');
  res.redirect('/profile');
};

module.exports = { getLogin, postLogin, getRegister, postRegister, logout, getChangePassword, postChangePassword };
```

---

## Bước 3 — auth.routes.js

```javascript
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/auth.controller');
const { requireAuth } = require('../middlewares/auth.middleware');

router.get('/login', ctrl.getLogin);
router.post('/login', ctrl.postLogin);
router.get('/register', ctrl.getRegister);
router.post('/register', ctrl.postRegister);
router.post('/logout', requireAuth, ctrl.logout);
router.get('/profile/change-password', requireAuth, ctrl.getChangePassword);
router.post('/profile/change-password', requireAuth, ctrl.postChangePassword);

module.exports = router;
```

Mount vào `src/routes/index.routes.js`:
```javascript
const authRoutes = require('./auth.routes');
router.use('/', authRoutes);
```

---

## Bước 4 — View: auth/login.ejs

```html
<div class="row justify-content-center">
  <div class="col-md-5">
    <div class="card shadow-sm">
      <div class="card-body p-4">
        <h4 class="card-title mb-4 text-center">Đăng nhập</h4>
        <form action="/login" method="POST">
          <input type="hidden" name="returnUrl" value="<%= returnUrl %>">
          <div class="mb-3">
            <label class="form-label">Email</label>
            <input type="email" name="email" class="form-control" required autofocus>
          </div>
          <div class="mb-3">
            <label class="form-label">Mật khẩu</label>
            <input type="password" name="password" class="form-control" required>
          </div>
          <button type="submit" class="btn btn-primary w-100">Đăng nhập</button>
        </form>
        <hr>
        <p class="text-center mb-0">
          Chưa có tài khoản? <a href="/register">Đăng ký ngay</a>
        </p>
      </div>
    </div>
  </div>
</div>
```

---

## Bước 5 — View: auth/register.ejs

```html
<div class="row justify-content-center">
  <div class="col-md-6">
    <div class="card shadow-sm">
      <div class="card-body p-4">
        <h4 class="card-title mb-4 text-center">Tạo tài khoản</h4>
        <form action="/register" method="POST">
          <div class="mb-3">
            <label class="form-label">Họ và tên <span class="text-danger">*</span></label>
            <input type="text" name="full_name" class="form-control" required>
          </div>
          <div class="mb-3">
            <label class="form-label">Email <span class="text-danger">*</span></label>
            <input type="email" name="email" class="form-control" required>
          </div>
          <div class="mb-3">
            <label class="form-label">Số điện thoại</label>
            <input type="tel" name="phone" class="form-control" placeholder="10-11 chữ số">
          </div>
          <div class="mb-3">
            <label class="form-label">Mật khẩu <span class="text-danger">*</span></label>
            <input type="password" name="password" class="form-control" minlength="8" required>
          </div>
          <div class="mb-3">
            <label class="form-label">Xác nhận mật khẩu <span class="text-danger">*</span></label>
            <input type="password" name="confirm_password" class="form-control" required>
          </div>
          <button type="submit" class="btn btn-primary w-100">Đăng ký</button>
        </form>
        <hr>
        <p class="text-center mb-0">Đã có tài khoản? <a href="/login">Đăng nhập</a></p>
      </div>
    </div>
  </div>
</div>
```

---

## Bước 6 — Cập nhật navbar cho user đã đăng nhập

Trong `src/views/partials/navbar.ejs`:
```html
<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
  <div class="container">
    <a class="navbar-brand fw-bold" href="/"><i class="bi bi-lightning-charge-fill text-warning"></i> ElectroShop</a>
    <div class="d-flex align-items-center gap-3 ms-auto">
      <!-- Cart icon -->
      <a href="/cart" class="text-white position-relative">
        <i class="bi bi-cart3 fs-5"></i>
        <% if (locals.cartCount && cartCount > 0) { %>
          <span class="badge bg-danger position-absolute top-0 start-100 translate-middle rounded-pill"><%= cartCount %></span>
        <% } %>
      </a>

      <% if (user) { %>
        <div class="dropdown">
          <button class="btn btn-outline-light btn-sm dropdown-toggle" data-bs-toggle="dropdown">
            <i class="bi bi-person-circle"></i> <%= user.full_name.split(' ').pop() %>
          </button>
          <ul class="dropdown-menu dropdown-menu-end">
            <li><a class="dropdown-item" href="/profile">Thông tin cá nhân</a></li>
            <li><a class="dropdown-item" href="/orders">Đơn hàng của tôi</a></li>
            <% if (user.role === 'admin') { %>
              <li><hr class="dropdown-divider"></li>
              <li><a class="dropdown-item text-danger" href="/admin/dashboard">Quản trị</a></li>
            <% } %>
            <li><hr class="dropdown-divider"></li>
            <li>
              <form action="/logout" method="POST">
                <button type="submit" class="dropdown-item text-danger">Đăng xuất</button>
              </form>
            </li>
          </ul>
        </div>
      <% } else { %>
        <a href="/login" class="btn btn-outline-light btn-sm">Đăng nhập</a>
        <a href="/register" class="btn btn-warning btn-sm">Đăng ký</a>
      <% } %>
    </div>
  </div>
</nav>
```

---

## Checklist xác nhận ✅

```
[x] POST /register với email mới → tạo user, redirect /login với flash success
[x] POST /register với email đã tồn tại → flash error, không insert
[x] POST /register với password không khớp → flash error
[x] POST /login đúng thông tin → session được tạo, redirect đúng theo role
[x] POST /login sai password → flash error, không tạo session
[x] POST /login tài khoản blocked → flash "tài khoản bị khoá"
[x] POST /logout → session bị destroy, redirect /login
[x] GET /cart khi chưa đăng nhập → redirect /login?returnUrl=/cart
[x] Sau đăng nhập → redirect về returnUrl đúng
[x] password_hash không bao giờ xuất hiện trong session hoặc view
[x] Admin đăng nhập → redirect /admin/dashboard
[x] Customer đăng nhập → redirect /
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 03`
