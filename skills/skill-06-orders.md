# SKILL 06 — Checkout & Orders

## Mục tiêu
Tạo đơn hàng từ giỏ (transaction), quản lý vòng đời đơn, lịch sử đơn hàng, hủy đơn.

## Files cần tạo
```
src/controllers/order.controller.js
src/services/order.service.js
src/routes/order.routes.js
src/views/pages/checkout.ejs
src/views/pages/orders/index.ejs
src/views/pages/orders/detail.ejs
```

---

## Bước 1 — order.service.js

```javascript
const pool = require('../config/database');
const cartService = require('./cart.service');

// Sinh mã đơn hàng: ORD-YYYYMMDD-XXXXX
function generateOrderCode() {
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const rand = Math.random().toString(36).substring(2, 7).toUpperCase();
  return `ORD-${date}-${rand}`;
}

async function createOrder(userId, { address_id, shipping_name, shipping_phone, shipping_address,
                                     payment_method, note }) {
  // Validate payment_method
  const validMethods = ['cod', 'bank_transfer', 'vnpay', 'momo'];
  if (!validMethods.includes(payment_method)) {
    return { success: false, error: 'Phương thức thanh toán không hợp lệ' };
  }

  // Lấy địa chỉ nếu dùng address_id
  let finalName = shipping_name, finalPhone = shipping_phone, finalAddress = shipping_address;
  if (address_id) {
    const [addrRows] = await pool.query(
      'SELECT * FROM addresses WHERE id = ? AND user_id = ?', [address_id, userId]
    );
    if (!addrRows.length) return { success: false, error: 'Địa chỉ không hợp lệ' };
    const addr = addrRows[0];
    finalName = addr.recipient_name;
    finalPhone = addr.phone;
    finalAddress = `${addr.address_line}, ${addr.ward}, ${addr.district}, ${addr.province}`;
  }
  if (!finalName || !finalPhone || !finalAddress) {
    return { success: false, error: 'Vui lòng nhập đầy đủ thông tin giao hàng' };
  }

  // Lấy giỏ hàng
  const { items } = await cartService.getCartSummary(userId);
  if (!items.length) return { success: false, error: 'Giỏ hàng trống' };

  // Validate tồn kho (lần cuối trước transaction)
  for (const item of items) {
    const [rows] = await pool.query('SELECT stock_quantity, status FROM products WHERE id = ?', [item.product_id]);
    if (!rows.length || rows[0].status === 'inactive') {
      return { success: false, error: `Sản phẩm "${item.name}" không còn tồn tại` };
    }
    if (rows[0].stock_quantity < item.quantity) {
      return { success: false, error: `"${item.name}" chỉ còn ${rows[0].stock_quantity} sản phẩm` };
    }
  }

  // Tính tiền
  const subtotal = items.reduce((s, i) => s + i.price_at_time * i.quantity, 0);
  const shipping_fee = subtotal >= 2000000 ? 0 : 50000;
  const total_amount = subtotal + shipping_fee;

  const orderCode = generateOrderCode();
  const paymentStatus = payment_method === 'cod' ? 'unpaid' : 'pending';

  // === DATABASE TRANSACTION ===
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // 1. Tạo order
    const [orderResult] = await conn.query(
      `INSERT INTO orders (user_id, order_code, subtotal, shipping_fee, total_amount,
        order_status, payment_status, shipping_name, shipping_phone, shipping_address, note)
       VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?, ?)`,
      [userId, orderCode, subtotal, shipping_fee, total_amount, paymentStatus,
       finalName, finalPhone, finalAddress, note || null]
    );
    const orderId = orderResult.insertId;

    // 2. Tạo order_items
    for (const item of items) {
      await conn.query(
        `INSERT INTO order_items (order_id, product_id, product_name, product_image, price, quantity, total_price)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [orderId, item.product_id, item.name, item.main_image, item.price_at_time,
         item.quantity, item.price_at_time * item.quantity]
      );
    }

    // 3. Tạo payment record
    await conn.query(
      'INSERT INTO payments (order_id, payment_method, payment_status, amount) VALUES (?, ?, ?, ?)',
      [orderId, payment_method, paymentStatus, total_amount]
    );

    // 4. Xóa giỏ hàng
    const [cartRows] = await conn.query('SELECT id FROM carts WHERE user_id = ?', [userId]);
    if (cartRows.length) {
      await conn.query('DELETE FROM cart_items WHERE cart_id = ?', [cartRows[0].id]);
    }

    await conn.commit();
    return { success: true, orderCode, orderId, payment_method };

  } catch (err) {
    await conn.rollback();
    console.error('Create order error:', err);
    return { success: false, error: 'Đặt hàng thất bại, vui lòng thử lại' };
  } finally {
    conn.release();
  }
}

async function getOrdersByUser(userId, page = 1) {
  const pageSize = 10;
  const offset = (page - 1) * pageSize;
  const [orders] = await pool.query(
    `SELECT o.*, COUNT(oi.id) AS item_count
     FROM orders o LEFT JOIN order_items oi ON oi.order_id = o.id
     WHERE o.user_id = ? GROUP BY o.id ORDER BY o.created_at DESC
     LIMIT ? OFFSET ?`,
    [userId, pageSize, offset]
  );
  const [[{ cnt }]] = await pool.query('SELECT COUNT(*) AS cnt FROM orders WHERE user_id = ?', [userId]);
  return { orders, totalPages: Math.ceil(cnt / pageSize), page };
}

async function getOrderDetail(orderCode, userId) {
  const [rows] = await pool.query(
    'SELECT * FROM orders WHERE order_code = ? AND user_id = ?', [orderCode, userId]
  );
  if (!rows.length) return null;
  const order = rows[0];

  const [items] = await pool.query(
    'SELECT * FROM order_items WHERE order_id = ?', [order.id]
  );
  const [payment] = await pool.query(
    'SELECT * FROM payments WHERE order_id = ?', [order.id]
  );
  const [reviews] = await pool.query(
    'SELECT product_id FROM reviews WHERE user_id = ? AND order_id = ?', [userId, order.id]
  );
  const reviewedProductIds = reviews.map(r => r.product_id);

  return { ...order, items, payment: payment[0] || null, reviewedProductIds };
}

async function cancelOrder(orderCode, userId, reason) {
  const [rows] = await pool.query(
    'SELECT * FROM orders WHERE order_code = ? AND user_id = ?', [orderCode, userId]
  );
  if (!rows.length) return { success: false, error: 'Không tìm thấy đơn hàng' };
  const order = rows[0];

  const cancellable = ['pending', 'confirmed'];
  if (!cancellable.includes(order.order_status)) {
    return { success: false, error: 'Đơn hàng này không thể hủy' };
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    await conn.query(
      "UPDATE orders SET order_status = 'cancelled', cancelled_reason = ?, updated_at = NOW() WHERE id = ?",
      [reason || 'Khách hàng hủy đơn', order.id]
    );

    // Nếu đã thanh toán → refund
    if (order.payment_status === 'paid') {
      await conn.query(
        "UPDATE payments SET payment_status = 'refunded' WHERE order_id = ?", [order.id]
      );
    }

    // Hoàn tồn kho nếu đơn đã confirmed (kho đã bị trừ)
    if (order.order_status === 'confirmed') {
      const [items] = await conn.query('SELECT product_id, quantity FROM order_items WHERE order_id = ?', [order.id]);
      for (const item of items) {
        await conn.query(
          "UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?",
          [item.quantity, item.product_id]
        );
        await conn.query(
          "UPDATE products SET status = 'active' WHERE id = ? AND status = 'out_of_stock' AND stock_quantity > 0",
          [item.product_id]
        );
      }
    }

    await conn.commit();
    return { success: true };
  } catch (err) {
    await conn.rollback();
    return { success: false, error: 'Hủy đơn thất bại' };
  } finally {
    conn.release();
  }
}

module.exports = { createOrder, getOrdersByUser, getOrderDetail, cancelOrder };
```

---

## Bước 2 — order.controller.js

```javascript
const orderService = require('../services/order.service');
const cartService = require('../services/cart.service');
const pool = require('../config/database');

const getCheckout = async (req, res) => {
  const { items, subtotal, shipping_fee, total } = await cartService.getCartSummary(req.session.user.id);
  if (!items.length) {
    req.flash('error', 'Giỏ hàng trống, không thể thanh toán');
    return res.redirect('/cart');
  }
  const [addresses] = await pool.query(
    'SELECT * FROM addresses WHERE user_id = ? ORDER BY is_default DESC', [req.session.user.id]
  );
  res.render('pages/checkout', { title: 'Đặt hàng', items, subtotal, shipping_fee, total, addresses });
};

const postOrder = async (req, res) => {
  const result = await orderService.createOrder(req.session.user.id, req.body);
  if (!result.success) {
    req.flash('error', result.error);
    return res.redirect('/checkout');
  }
  if (result.payment_method === 'bank_transfer') {
    return res.redirect(`/payment/bank-info/${result.orderCode}`);
  }
  if (result.payment_method === 'vnpay') {
    return res.redirect(`/payment/vnpay/create?orderCode=${result.orderCode}`);
  }
  req.flash('success', 'Đặt hàng thành công!');
  res.redirect(`/orders/${result.orderCode}`);
};

const getOrders = async (req, res) => {
  const data = await orderService.getOrdersByUser(req.session.user.id, parseInt(req.query.page) || 1);
  res.render('pages/orders/index', { title: 'Đơn hàng của tôi', ...data });
};

const getOrderDetail = async (req, res) => {
  const order = await orderService.getOrderDetail(req.params.code, req.session.user.id);
  if (!order) return res.status(404).render('errors/404', { title: 'Không tìm thấy đơn hàng' });
  res.render('pages/orders/detail', { title: `Đơn hàng ${order.order_code}`, order });
};

const cancelOrder = async (req, res) => {
  const result = await orderService.cancelOrder(req.params.code, req.session.user.id, req.body.reason);
  if (!result.success) req.flash('error', result.error);
  else req.flash('success', 'Đã hủy đơn hàng thành công');
  res.redirect(`/orders/${req.params.code}`);
};

module.exports = { getCheckout, postOrder, getOrders, getOrderDetail, cancelOrder };
```

---

## Bước 3 — Trạng thái đơn hàng (badge màu)

Dùng trong view:
```javascript
// src/utils/orderStatus.js
const ORDER_STATUS_LABEL = {
  pending:    { label: 'Chờ xác nhận',  badge: 'warning'  },
  confirmed:  { label: 'Đã xác nhận',   badge: 'info'     },
  processing: { label: 'Đang chuẩn bị', badge: 'primary'  },
  shipping:   { label: 'Đang giao',      badge: 'primary'  },
  completed:  { label: 'Hoàn thành',     badge: 'success'  },
  cancelled:  { label: 'Đã hủy',         badge: 'danger'   }
};
const PAYMENT_STATUS_LABEL = {
  unpaid:   { label: 'Chưa thanh toán', badge: 'secondary' },
  pending:  { label: 'Chờ thanh toán',  badge: 'warning'   },
  paid:     { label: 'Đã thanh toán',   badge: 'success'   },
  failed:   { label: 'Thất bại',        badge: 'danger'    },
  refunded: { label: 'Đã hoàn tiền',    badge: 'info'      }
};
module.exports = { ORDER_STATUS_LABEL, PAYMENT_STATUS_LABEL };
```

Inject vào res.locals trong app.js:
```javascript
const { ORDER_STATUS_LABEL, PAYMENT_STATUS_LABEL } = require('./src/utils/orderStatus');
app.use((req, res, next) => {
  res.locals.ORDER_STATUS = ORDER_STATUS_LABEL;
  res.locals.PAYMENT_STATUS = PAYMENT_STATUS_LABEL;
  next();
});
```

---

## Bước 4 — View: pages/orders/index.ejs (cấu trúc)

```html
<h4 class="mb-4">Đơn hàng của tôi</h4>
<% if (orders.length === 0) { %>
  <div class="text-center py-5">
    <i class="bi bi-bag-x fs-1 text-muted"></i>
    <p class="mt-3 text-muted">Bạn chưa có đơn hàng nào</p>
    <a href="/products" class="btn btn-primary">Mua sắm ngay</a>
  </div>
<% } else { %>
  <% orders.forEach(order => { %>
    <div class="card mb-3">
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-start">
          <div>
            <strong><%= order.order_code %></strong>
            <small class="text-muted ms-2"><%= new Date(order.created_at).toLocaleDateString('vi-VN') %></small>
          </div>
          <div>
            <span class="badge bg-<%= ORDER_STATUS[order.order_status].badge %>">
              <%= ORDER_STATUS[order.order_status].label %>
            </span>
          </div>
        </div>
        <div class="mt-2 d-flex justify-content-between align-items-center">
          <span class="text-muted small"><%= order.item_count %> sản phẩm</span>
          <strong class="text-danger"><%= order.total_amount.toLocaleString('vi-VN') %>đ</strong>
        </div>
        <a href="/orders/<%= order.order_code %>" class="btn btn-outline-primary btn-sm mt-2">
          Xem chi tiết
        </a>
      </div>
    </div>
  <% }); %>
<% } %>
```

---

## Checklist xác nhận ✅

```
[x] GET /checkout khi giỏ rỗng → redirect /cart với flash error
[x] GET /checkout → hiển thị địa chỉ user, phương thức thanh toán, tổng tiền
[x] POST /orders COD → tạo order + order_items + payment, xóa cart, redirect /orders/:code
[x] POST /orders → order_code là UNIQUE, format ORD-YYYYMMDD-XXXXX
[x] POST /orders khi stock không đủ → flash error, ROLLBACK, cart không xóa
[x] Transaction: nếu lỗi giữa chừng → ROLLBACK, không có orphan data
[x] GET /orders → danh sách đơn của user, không thấy đơn user khác
[x] GET /orders/:code → chi tiết đầy đủ
[x] GET /orders/:code của user khác → 404
[x] POST /orders/:code/cancel status=pending → hủy được
[x] POST /orders/:code/cancel status=completed → flash error "không thể hủy"
[x] Hủy đơn confirmed → hoàn tồn kho đúng
[x] Badge trạng thái đúng màu
[x] Phí ship = 0 nếu subtotal >= 2,000,000đ
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 06`

---

## Test Cases — Orders

| ID | Input | Expected |
|----|-------|----------|
| TC31 | POST /orders: giỏ hợp lệ, COD | Order tạo, cart xóa, payment_status=unpaid |
| TC32 | POST /orders: giỏ hợp lệ, bank_transfer | Redirect /payment/bank-info/ORD-xxx |
| TC33 | POST /orders: giỏ rỗng | Redirect /cart, không tạo đơn |
| TC34 | POST /orders: stock=0 tại thời điểm checkout | Flash lỗi tồn kho, không tạo đơn, rollback |
| TC35 | GET /orders | Chỉ thấy đơn hàng của chính mình |
| TC36 | GET /orders/ORD-xxx của user khác | 404 hoặc không có kết quả |
| TC37 | POST /orders/ORD-xxx/cancel: status=pending | Hủy thành công |
| TC38 | POST /orders/ORD-xxx/cancel: status=confirmed | Hủy thành công + hoàn kho |
| TC39 | POST /orders/ORD-xxx/cancel: status=completed | Flash "Không thể hủy đơn hàng này" |
| DATA01 | Tạo đơn thành công | orders + order_items + payments tạo cùng transaction |
| DATA02 | Simulate lỗi DB giữa chừng | Rollback toàn bộ, không có record nào được tạo |
| DATA03 | Hủy đơn đã confirmed | stock_quantity hoàn về đúng số lượng |
