# SKILL 10 — Admin Dashboard

## Mục tiêu
Admin quản lý sản phẩm, danh mục, đơn hàng, người dùng, đánh giá. Dashboard thống kê.

## Files cần tạo
```
src/controllers/admin/dashboard.controller.js
src/controllers/admin/product.controller.js
src/controllers/admin/order.controller.js
src/controllers/admin/user.controller.js
src/controllers/admin/review.controller.js
src/services/admin.service.js
src/routes/admin.routes.js
src/views/admin/dashboard.ejs
src/views/admin/products/index.ejs
src/views/admin/products/form.ejs
src/views/admin/orders/index.ejs
src/views/admin/orders/detail.ejs
src/views/admin/users/index.ejs
src/views/admin/reviews/index.ejs
src/views/layouts/admin.ejs
```

---

## Bước 1 — src/views/layouts/admin.ejs

```html
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><%= typeof title !== 'undefined' ? title + ' | Admin' : 'Admin Panel' %></title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.2/font/bootstrap-icons.css" rel="stylesheet">
  <link href="/css/admin.css" rel="stylesheet">
</head>
<body class="bg-light">
  <!-- Topbar -->
  <nav class="navbar navbar-dark bg-dark px-3 fixed-top" style="z-index:1030">
    <a class="navbar-brand fw-bold" href="/admin/dashboard">
      <i class="bi bi-lightning-charge-fill text-warning"></i> Admin Panel
    </a>
    <div class="ms-auto d-flex gap-3 align-items-center">
      <a href="/" target="_blank" class="text-white-50 small"><i class="bi bi-box-arrow-up-right"></i> Xem website</a>
      <form action="/logout" method="POST">
        <button class="btn btn-outline-light btn-sm">Đăng xuất</button>
      </form>
    </div>
  </nav>

  <div class="d-flex" style="margin-top:56px">
    <!-- Sidebar -->
    <nav class="bg-white shadow-sm" style="width:240px; min-height:calc(100vh - 56px); position:sticky; top:56px">
      <ul class="nav flex-column py-3">
        <li class="nav-item">
          <a class="nav-link px-4 <%= locals.activePage === 'dashboard' ? 'active fw-bold text-primary' : 'text-dark' %>"
             href="/admin/dashboard"><i class="bi bi-speedometer2 me-2"></i>Dashboard</a>
        </li>
        <li class="nav-item">
          <a class="nav-link px-4 <%= locals.activePage === 'products' ? 'active fw-bold text-primary' : 'text-dark' %>"
             href="/admin/products"><i class="bi bi-box-seam me-2"></i>Sản phẩm</a>
        </li>
        <li class="nav-item">
          <a class="nav-link px-4 <%= locals.activePage === 'categories' ? 'active fw-bold text-primary' : 'text-dark' %>"
             href="/admin/categories"><i class="bi bi-tags me-2"></i>Danh mục</a>
        </li>
        <li class="nav-item">
          <a class="nav-link px-4 <%= locals.activePage === 'orders' ? 'active fw-bold text-primary' : 'text-dark' %>"
             href="/admin/orders"><i class="bi bi-receipt me-2"></i>Đơn hàng</a>
        </li>
        <li class="nav-item">
          <a class="nav-link px-4 <%= locals.activePage === 'users' ? 'active fw-bold text-primary' : 'text-dark' %>"
             href="/admin/users"><i class="bi bi-people me-2"></i>Người dùng</a>
        </li>
        <li class="nav-item">
          <a class="nav-link px-4 <%= locals.activePage === 'reviews' ? 'active fw-bold text-primary' : 'text-dark' %>"
             href="/admin/reviews"><i class="bi bi-star me-2"></i>Đánh giá</a>
        </li>
        <li class="nav-item">
          <a class="nav-link px-4 <%= locals.activePage === 'warranty' ? 'active fw-bold text-primary' : 'text-dark' %>"
             href="/admin/warranty"><i class="bi bi-shield-check me-2"></i>Bảo hành</a>
        </li>
      </ul>
    </nav>

    <!-- Content -->
    <main class="flex-grow-1 p-4">
      <%- include('../partials/flash') %>
      <%- body %>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
```

---

## Bước 2 — admin.service.js (Dashboard queries)

```javascript
const pool = require('../config/database');

async function getDashboardStats() {
  // Tổng doanh thu (completed + paid)
  const [[revenue]] = await pool.query(
    "SELECT COALESCE(SUM(total_amount), 0) AS total FROM orders WHERE order_status = 'completed' AND payment_status = 'paid'"
  );

  // Số đơn theo trạng thái
  const [orderStats] = await pool.query(
    'SELECT order_status, COUNT(*) AS cnt FROM orders GROUP BY order_status'
  );
  const orderByStatus = {};
  orderStats.forEach(r => { orderByStatus[r.order_status] = r.cnt; });

  // Doanh thu 7 ngày gần nhất
  const [revenueByDay] = await pool.query(
    `SELECT DATE(created_at) AS day, SUM(total_amount) AS revenue
     FROM orders
     WHERE order_status = 'completed' AND payment_status = 'paid'
       AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
     GROUP BY DATE(created_at)
     ORDER BY day`
  );

  // Top 5 sản phẩm bán chạy
  const [topProducts] = await pool.query(
    `SELECT p.name, SUM(oi.quantity) AS total_sold,
            SUM(oi.total_price) AS total_revenue,
            pi.image_url AS main_image
     FROM order_items oi
     JOIN products p ON oi.product_id = p.id
     JOIN orders o ON oi.order_id = o.id
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
     WHERE o.order_status = 'completed'
     GROUP BY oi.product_id ORDER BY total_sold DESC LIMIT 5`
  );

  // Sản phẩm sắp hết hàng (≤ 5)
  const [lowStock] = await pool.query(
    "SELECT id, name, stock_quantity, brand FROM products WHERE stock_quantity <= 5 AND status != 'inactive' ORDER BY stock_quantity ASC LIMIT 10"
  );

  // Đơn hàng mới nhất (10 đơn)
  const [recentOrders] = await pool.query(
    'SELECT order_code, total_amount, order_status, created_at FROM orders ORDER BY created_at DESC LIMIT 10'
  );

  return {
    totalRevenue: revenue.total,
    orderByStatus,
    revenueByDay,
    topProducts,
    lowStock,
    recentOrders
  };
}

// Admin product functions
async function getAdminProducts({ keyword, category, status, page = 1 }) {
  const pageSize = 20;
  const offset = (page - 1) * pageSize;
  const where = ['1=1'];
  const params = [];

  if (keyword) { where.push('p.name LIKE ?'); params.push(`%${keyword}%`); }
  if (category) { where.push('p.category_id = ?'); params.push(category); }
  if (status) { where.push('p.status = ?'); params.push(status); }

  const whereClause = `WHERE ${where.join(' AND ')}`;
  const [products] = await pool.query(
    `SELECT p.*, c.name AS category_name, pi.image_url AS main_image
     FROM products p
     JOIN categories c ON p.category_id = c.id
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
     ${whereClause} ORDER BY p.created_at DESC LIMIT ? OFFSET ?`,
    [...params, pageSize, offset]
  );
  const [[{ cnt }]] = await pool.query(
    `SELECT COUNT(*) AS cnt FROM products p ${whereClause}`, params
  );
  return { products, total: cnt, page, totalPages: Math.ceil(cnt / pageSize) };
}

async function createProduct(data, imageFiles) {
  const { name, category_id, brand, sku, price, sale_price, stock_quantity,
          description, specifications, warranty_months } = data;

  const slugify = require('slugify');
  const slug = slugify(name, { lower: true, locale: 'vi', strict: true })
             + '-' + Date.now();

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [result] = await conn.query(
      `INSERT INTO products (category_id, name, slug, brand, sku, price, sale_price,
        stock_quantity, description, specifications, warranty_months)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [category_id, name.trim(), slug, brand || null, sku || null,
       price, sale_price || null, stock_quantity || 0,
       description || null, specifications || null, warranty_months || 0]
    );
    const productId = result.insertId;

    for (let i = 0; i < imageFiles.length; i++) {
      await conn.query(
        'INSERT INTO product_images (product_id, image_url, is_main, sort_order) VALUES (?, ?, ?, ?)',
        [productId, '/uploads/' + imageFiles[i].filename, i === 0 ? 1 : 0, i]
      );
    }

    await conn.commit();
    return { success: true, productId };
  } catch (err) {
    await conn.rollback();
    return { success: false, error: err.message };
  } finally {
    conn.release();
  }
}

// Admin order management
async function getAdminOrders({ status, keyword, page = 1 }) {
  const pageSize = 20;
  const offset = (page - 1) * pageSize;
  const where = ['1=1'];
  const params = [];

  if (status) { where.push('o.order_status = ?'); params.push(status); }
  if (keyword) { where.push('(o.order_code LIKE ? OR u.full_name LIKE ?)'); params.push(`%${keyword}%`, `%${keyword}%`); }

  const whereClause = `WHERE ${where.join(' AND ')}`;
  const [orders] = await pool.query(
    `SELECT o.*, u.full_name AS customer_name, u.email AS customer_email
     FROM orders o JOIN users u ON o.user_id = u.id
     ${whereClause} ORDER BY o.created_at DESC LIMIT ? OFFSET ?`,
    [...params, pageSize, offset]
  );
  const [[{ cnt }]] = await pool.query(
    `SELECT COUNT(*) AS cnt FROM orders o JOIN users u ON o.user_id = u.id ${whereClause}`, params
  );
  return { orders, total: cnt, page, totalPages: Math.ceil(cnt / pageSize) };
}

const VALID_ORDER_TRANSITIONS = {
  pending:    ['confirmed', 'cancelled'],
  confirmed:  ['processing', 'cancelled'],
  processing: ['shipping', 'cancelled'],
  shipping:   ['completed', 'cancelled'],
  completed:  [],
  cancelled:  []
};

async function updateOrderStatus(orderId, newStatus, adminNote) {
  const [rows] = await pool.query('SELECT * FROM orders WHERE id = ?', [orderId]);
  if (!rows.length) return { success: false, error: 'Không tìm thấy đơn hàng' };
  const order = rows[0];

  if (!VALID_ORDER_TRANSITIONS[order.order_status]?.includes(newStatus)) {
    return { success: false, error: `Không thể chuyển từ "${order.order_status}" sang "${newStatus}"` };
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    await conn.query(
      'UPDATE orders SET order_status = ?, updated_at = NOW() WHERE id = ?',
      [newStatus, orderId]
    );

    // Trừ kho khi confirmed (COD/bank transfer chưa trừ)
    if (newStatus === 'confirmed' && order.payment_method !== 'vnpay' && order.payment_method !== 'momo') {
      const [items] = await conn.query('SELECT product_id, quantity FROM order_items WHERE order_id = ?', [orderId]);
      for (const item of items) {
        await conn.query('UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?',
          [item.quantity, item.product_id]);
        await conn.query("UPDATE products SET status = 'out_of_stock' WHERE id = ? AND stock_quantity <= 0",
          [item.product_id]);
      }
    }

    // Hoàn kho khi hủy sau confirmed
    if (newStatus === 'cancelled' && ['confirmed', 'processing', 'shipping'].includes(order.order_status)) {
      const [items] = await conn.query('SELECT product_id, quantity FROM order_items WHERE order_id = ?', [orderId]);
      for (const item of items) {
        await conn.query('UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?',
          [item.quantity, item.product_id]);
        await conn.query("UPDATE products SET status = 'active' WHERE id = ? AND status = 'out_of_stock' AND stock_quantity > 0",
          [item.product_id]);
      }
    }

    await conn.commit();
    return { success: true };
  } catch (err) {
    await conn.rollback();
    return { success: false, error: err.message };
  } finally {
    conn.release();
  }
}

module.exports = { getDashboardStats, getAdminProducts, createProduct, getAdminOrders, updateOrderStatus };
```

---

## Bước 3 — admin.routes.js

```javascript
const express = require('express');
const router = express.Router();
const { requireAdmin } = require('../middlewares/admin.middleware');
const upload = require('../middlewares/upload.middleware');
const pool = require('../config/database');
const adminService = require('../services/admin.service');
const reviewService = require('../services/review.service');
const warrantyCtrl = require('../controllers/warranty.controller');

router.use(requireAdmin);

// Dashboard
router.get('/dashboard', async (req, res) => {
  const stats = await adminService.getDashboardStats();
  res.render('admin/dashboard', { title: 'Dashboard', activePage: 'dashboard', ...stats });
});

// Products
router.get('/products', async (req, res) => {
  const data = await adminService.getAdminProducts(req.query);
  const [cats] = await pool.query("SELECT * FROM categories WHERE status = 'active'");
  res.render('admin/products/index', { title: 'Quản lý sản phẩm', activePage: 'products', ...data, categories: cats });
});

router.get('/products/create', async (req, res) => {
  const [cats] = await pool.query("SELECT * FROM categories WHERE status = 'active'");
  res.render('admin/products/form', { title: 'Thêm sản phẩm', activePage: 'products', product: null, categories: cats });
});

router.post('/products', upload.array('images', 10), async (req, res) => {
  const result = await adminService.createProduct(req.body, req.files || []);
  if (!result.success) { req.flash('error', result.error); return res.redirect('/admin/products/create'); }
  req.flash('success', 'Đã thêm sản phẩm thành công');
  res.redirect('/admin/products');
});

router.get('/products/:id/edit', async (req, res) => {
  const [[product]] = await pool.query('SELECT * FROM products WHERE id = ?', [req.params.id]);
  if (!product) return res.status(404).render('errors/404', { title: 'Không tìm thấy' });
  const [cats] = await pool.query("SELECT * FROM categories WHERE status = 'active'");
  const [images] = await pool.query('SELECT * FROM product_images WHERE product_id = ? ORDER BY is_main DESC, sort_order', [req.params.id]);
  res.render('admin/products/form', { title: 'Sửa sản phẩm', activePage: 'products', product, categories: cats, images });
});

router.post('/products/:id', upload.array('images', 10), async (req, res) => {
  const { name, category_id, brand, price, sale_price, stock_quantity, description, specifications, warranty_months, status } = req.body;
  await pool.query(
    'UPDATE products SET name=?, category_id=?, brand=?, price=?, sale_price=?, stock_quantity=?, description=?, specifications=?, warranty_months=?, status=?, updated_at=NOW() WHERE id=?',
    [name, category_id, brand||null, price, sale_price||null, stock_quantity, description||null, specifications||null, warranty_months||0, status||'active', req.params.id]
  );
  if (req.files?.length) {
    for (const file of req.files) {
      await pool.query('INSERT INTO product_images (product_id, image_url, is_main) VALUES (?, ?, 0)', [req.params.id, '/uploads/' + file.filename]);
    }
  }
  req.flash('success', 'Đã cập nhật sản phẩm');
  res.redirect('/admin/products');
});

router.post('/products/:id/delete', async (req, res) => {
  // Soft delete nếu đã có trong đơn hàng
  const [[{ cnt }]] = await pool.query('SELECT COUNT(*) AS cnt FROM order_items WHERE product_id = ?', [req.params.id]);
  if (cnt > 0) {
    await pool.query("UPDATE products SET status = 'inactive' WHERE id = ?", [req.params.id]);
    req.flash('success', 'Đã ẩn sản phẩm (đã có đơn hàng liên quan)');
  } else {
    await pool.query('DELETE FROM product_images WHERE product_id = ?', [req.params.id]);
    await pool.query('DELETE FROM products WHERE id = ?', [req.params.id]);
    req.flash('success', 'Đã xóa sản phẩm');
  }
  res.redirect('/admin/products');
});

// Orders
router.get('/orders', async (req, res) => {
  const data = await adminService.getAdminOrders(req.query);
  res.render('admin/orders/index', { title: 'Quản lý đơn hàng', activePage: 'orders', ...data, filters: req.query });
});

router.get('/orders/:id', async (req, res) => {
  const [[order]] = await pool.query('SELECT o.*, u.full_name, u.email FROM orders o JOIN users u ON o.user_id = u.id WHERE o.id = ?', [req.params.id]);
  if (!order) return res.status(404).render('errors/404', { title: 'Không tìm thấy' });
  const [items] = await pool.query('SELECT * FROM order_items WHERE order_id = ?', [order.id]);
  const [[payment]] = await pool.query('SELECT * FROM payments WHERE order_id = ?', [order.id]);
  res.render('admin/orders/detail', { title: `Đơn ${order.order_code}`, activePage: 'orders', order, items, payment });
});

router.post('/orders/:id/status', async (req, res) => {
  const result = await adminService.updateOrderStatus(req.params.id, req.body.order_status);
  if (!result.success) req.flash('error', result.error);
  else req.flash('success', 'Cập nhật trạng thái thành công');
  res.redirect(`/admin/orders/${req.params.id}`);
});

// Users
router.get('/users', async (req, res) => {
  const keyword = req.query.keyword || '';
  const page = parseInt(req.query.page) || 1;
  const offset = (page - 1) * 20;
  const where = keyword ? 'WHERE full_name LIKE ? OR email LIKE ?' : '';
  const params = keyword ? [`%${keyword}%`, `%${keyword}%`] : [];
  const [users] = await pool.query(`SELECT id,full_name,email,phone,role,status,created_at FROM users ${where} ORDER BY created_at DESC LIMIT 20 OFFSET ?`, [...params, offset]);
  res.render('admin/users/index', { title: 'Quản lý người dùng', activePage: 'users', users, keyword });
});

router.post('/users/:id/status', async (req, res) => {
  const { status } = req.body;
  if (!['active', 'blocked'].includes(status)) { req.flash('error', 'Trạng thái không hợp lệ'); return res.redirect('/admin/users'); }
  await pool.query('UPDATE users SET status = ? WHERE id = ? AND role = "customer"', [status, req.params.id]);
  req.flash('success', status === 'blocked' ? 'Đã khoá tài khoản' : 'Đã mở khoá tài khoản');
  res.redirect('/admin/users');
});

// Reviews
router.get('/reviews', async (req, res) => {
  const [reviews] = await pool.query(
    'SELECT r.*, u.full_name, p.name AS product_name FROM reviews r JOIN users u ON r.user_id = u.id JOIN products p ON r.product_id = p.id ORDER BY r.created_at DESC LIMIT 50'
  );
  res.render('admin/reviews/index', { title: 'Quản lý đánh giá', activePage: 'reviews', reviews });
});

router.post('/reviews/:id/status', async (req, res) => {
  await reviewService.setReviewStatus(req.params.id, req.body.status);
  req.flash('success', 'Đã cập nhật trạng thái đánh giá');
  res.redirect('/admin/reviews');
});

// Warranty
router.get('/warranty', warrantyCtrl.adminListWarranty);
router.post('/warranty/:id/status', warrantyCtrl.adminUpdateWarranty);

module.exports = router;
```

---

## Checklist xác nhận ✅

```
[ ] GET /admin/dashboard → hiển thị: tổng doanh thu, số đơn theo trạng thái, top 5 SP, low stock
[ ] GET /admin/products → danh sách có phân trang, tìm kiếm, lọc theo danh mục/trạng thái
[ ] GET /admin/products/create → form đầy đủ
[ ] POST /admin/products → tạo sản phẩm + upload ảnh thành công
[ ] POST /admin/products/:id → cập nhật sản phẩm đúng
[ ] POST /admin/products/:id/delete SP có đơn → status=inactive, không xóa cứng
[ ] POST /admin/products/:id/delete SP chưa có đơn → xóa cứng + xóa ảnh
[ ] GET /admin/orders → lọc theo status, tìm theo order_code/tên khách
[ ] GET /admin/orders/:id → chi tiết đầy đủ
[ ] POST /admin/orders/:id/status valid transition → update thành công + trừ/hoàn kho
[ ] POST /admin/orders/:id/status invalid transition → flash error
[ ] GET /admin/users → danh sách users
[ ] POST /admin/users/:id/status → block/unblock
[ ] Không cho block admin account
[ ] GET /admin/reviews → danh sách đánh giá
[ ] POST /admin/reviews/:id/status → ẩn/hiện, avg_rating recalculate
[ ] Customer truy cập /admin/* → 403
[ ] Chưa đăng nhập truy cập /admin/* → redirect /login
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 10`
