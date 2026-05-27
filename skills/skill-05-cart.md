# SKILL 05 — Cart

## Mục tiêu
Giỏ hàng hoạt động đầy đủ: thêm / cập nhật / xóa / tính tiền. AJAX update không reload.

## Files cần tạo
```
src/controllers/cart.controller.js
src/services/cart.service.js
src/routes/cart.routes.js
src/views/pages/cart.ejs
public/js/cart.js
```

---

## Bước 1 — cart.service.js

```javascript
const pool = require('../config/database');

async function getOrCreateCart(userId) {
  let [rows] = await pool.query('SELECT id FROM carts WHERE user_id = ?', [userId]);
  if (rows.length) return rows[0].id;
  const [result] = await pool.query('INSERT INTO carts (user_id) VALUES (?)', [userId]);
  return result.insertId;
}

async function getCartItems(userId) {
  const [rows] = await pool.query(
    `SELECT ci.id, ci.quantity, ci.price_at_time,
            p.id AS product_id, p.name, p.slug, p.stock_quantity,
            p.price, p.sale_price, p.status,
            pi.image_url AS main_image
     FROM cart_items ci
     JOIN carts c ON ci.cart_id = c.id
     JOIN products p ON ci.product_id = p.id
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
     WHERE c.user_id = ?
     ORDER BY ci.id DESC`,
    [userId]
  );
  return rows;
}

async function getCartSummary(userId) {
  const items = await getCartItems(userId);
  const subtotal = items.reduce((sum, i) => sum + i.price_at_time * i.quantity, 0);
  const SHIPPING_THRESHOLD = 2000000;
  const shipping_fee = subtotal >= SHIPPING_THRESHOLD ? 0 : 50000;
  const total = subtotal + shipping_fee;
  const count = items.reduce((sum, i) => sum + i.quantity, 0);
  return { items, subtotal, shipping_fee, total, count };
}

async function addItem(userId, productId, quantity) {
  quantity = parseInt(quantity);
  if (!quantity || quantity < 1) return { success: false, error: 'Số lượng không hợp lệ' };

  // Kiểm tra sản phẩm
  const [products] = await pool.query(
    "SELECT id, price, sale_price, stock_quantity, status FROM products WHERE id = ?",
    [productId]
  );
  if (!products.length || products[0].status === 'inactive') {
    return { success: false, error: 'Sản phẩm không tồn tại' };
  }
  const product = products[0];
  if (product.stock_quantity === 0) {
    return { success: false, error: 'Sản phẩm đã hết hàng' };
  }

  const cartId = await getOrCreateCart(userId);
  const price = product.sale_price || product.price;

  // Kiểm tra đã có trong giỏ chưa
  const [existing] = await pool.query(
    'SELECT id, quantity FROM cart_items WHERE cart_id = ? AND product_id = ?',
    [cartId, productId]
  );

  if (existing.length) {
    const newQty = existing[0].quantity + quantity;
    if (newQty > product.stock_quantity) {
      return { success: false, error: `Chỉ còn ${product.stock_quantity} sản phẩm trong kho` };
    }
    await pool.query('UPDATE cart_items SET quantity = ? WHERE id = ?', [newQty, existing[0].id]);
  } else {
    if (quantity > product.stock_quantity) {
      return { success: false, error: `Chỉ còn ${product.stock_quantity} sản phẩm trong kho` };
    }
    await pool.query(
      'INSERT INTO cart_items (cart_id, product_id, quantity, price_at_time) VALUES (?, ?, ?, ?)',
      [cartId, productId, quantity, price]
    );
  }

  const summary = await getCartSummary(userId);
  return { success: true, cartCount: summary.count };
}

async function updateItem(userId, itemId, quantity) {
  quantity = parseInt(quantity);

  // Xác nhận item thuộc cart của user này
  const [rows] = await pool.query(
    `SELECT ci.id, ci.product_id FROM cart_items ci
     JOIN carts c ON ci.cart_id = c.id
     WHERE ci.id = ? AND c.user_id = ?`,
    [itemId, userId]
  );
  if (!rows.length) return { success: false, error: 'Không tìm thấy mục trong giỏ hàng' };

  if (quantity < 1) {
    return removeItem(userId, itemId);
  }

  // Kiểm tra tồn kho
  const [stock] = await pool.query('SELECT stock_quantity FROM products WHERE id = ?', [rows[0].product_id]);
  if (quantity > stock[0].stock_quantity) {
    return { success: false, error: `Chỉ còn ${stock[0].stock_quantity} sản phẩm` };
  }

  await pool.query('UPDATE cart_items SET quantity = ? WHERE id = ?', [quantity, itemId]);
  const summary = await getCartSummary(userId);
  const [item] = await pool.query('SELECT price_at_time FROM cart_items WHERE id = ?', [itemId]);
  const itemTotal = item[0].price_at_time * quantity;

  return { success: true, cartCount: summary.count, subtotal: summary.subtotal,
           shipping_fee: summary.shipping_fee, total: summary.total, itemTotal };
}

async function removeItem(userId, itemId) {
  const [rows] = await pool.query(
    `SELECT ci.id FROM cart_items ci JOIN carts c ON ci.cart_id = c.id
     WHERE ci.id = ? AND c.user_id = ?`,
    [itemId, userId]
  );
  if (!rows.length) return { success: false, error: 'Không tìm thấy mục trong giỏ hàng' };

  await pool.query('DELETE FROM cart_items WHERE id = ?', [itemId]);
  const summary = await getCartSummary(userId);
  return { success: true, cartCount: summary.count, subtotal: summary.subtotal,
           shipping_fee: summary.shipping_fee, total: summary.total };
}

async function clearCart(userId) {
  const cartId = await getOrCreateCart(userId);
  await pool.query('DELETE FROM cart_items WHERE cart_id = ?', [cartId]);
}

module.exports = { getCartSummary, addItem, updateItem, removeItem, clearCart, getOrCreateCart };
```

---

## Bước 2 — cart.controller.js

```javascript
const cartService = require('../services/cart.service');

const getCart = async (req, res) => {
  const summary = await cartService.getCartSummary(req.session.user.id);
  res.render('pages/cart', { title: 'Giỏ hàng', ...summary });
};

const addToCart = async (req, res) => {
  const { product_id, quantity } = req.body;
  const result = await cartService.addItem(req.session.user.id, product_id, quantity || 1);

  if (req.headers['content-type']?.includes('application/json') || req.headers['x-requested-with']) {
    return res.json(result);
  }

  if (!result.success) req.flash('error', result.error);
  else req.flash('success', 'Đã thêm vào giỏ hàng');
  res.redirect('back');
};

const updateItem = async (req, res) => {
  const result = await cartService.updateItem(req.session.user.id, req.params.id, req.body.quantity);
  res.json(result);
};

const removeItem = async (req, res) => {
  const result = await cartService.removeItem(req.session.user.id, req.params.id);
  res.json(result);
};

const clearCart = async (req, res) => {
  await cartService.clearCart(req.session.user.id);
  req.flash('success', 'Đã xóa giỏ hàng');
  res.redirect('/cart');
};

module.exports = { getCart, addToCart, updateItem, removeItem, clearCart };
```

---

## Bước 3 — cart.routes.js

```javascript
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/cart.controller');
const { requireAuth } = require('../middlewares/auth.middleware');

router.use(requireAuth);
router.get('/cart', ctrl.getCart);
router.post('/cart/add', ctrl.addToCart);
router.patch('/cart/items/:id', ctrl.updateItem);
router.delete('/cart/items/:id', ctrl.removeItem);
router.delete('/cart/clear', ctrl.clearCart);

module.exports = router;
```

---

## Bước 4 — Middleware: inject cartCount vào mọi response

Thêm vào `app.js` sau session middleware:

```javascript
const cartService = require('./src/services/cart.service');
app.use(async (req, res, next) => {
  if (req.session.user) {
    try {
      const summary = await cartService.getCartSummary(req.session.user.id);
      res.locals.cartCount = summary.count;
    } catch { res.locals.cartCount = 0; }
  } else {
    res.locals.cartCount = 0;
  }
  next();
});
```

---

## Bước 5 — View: pages/cart.ejs

```html
<h4 class="mb-4"><i class="bi bi-cart3"></i> Giỏ hàng (<%= count %> sản phẩm)</h4>

<% if (items.length === 0) { %>
  <div class="text-center py-5">
    <i class="bi bi-cart-x fs-1 text-muted"></i>
    <p class="mt-3 text-muted">Giỏ hàng của bạn đang trống</p>
    <a href="/products" class="btn btn-primary">Tiếp tục mua sắm</a>
  </div>
<% } else { %>
  <div class="row">
    <div class="col-lg-8">
      <% items.forEach(item => { %>
        <div class="card mb-3 cart-item" id="cart-item-<%= item.id %>">
          <div class="card-body d-flex gap-3 align-items-center">
            <img src="<%= item.main_image || '/images/no-image.png' %>"
                 width="80" height="80" class="rounded object-fit-cover" alt="">
            <div class="flex-grow-1">
              <a href="/products/<%= item.slug %>" class="fw-bold text-decoration-none text-dark">
                <%= item.name %>
              </a>
              <div class="text-danger mt-1"><%= item.price_at_time.toLocaleString('vi-VN') %>đ</div>
            </div>
            <div class="d-flex align-items-center gap-2">
              <button class="btn btn-outline-secondary btn-sm qty-btn" data-action="minus" data-id="<%= item.id %>">−</button>
              <input type="number" class="form-control form-control-sm text-center qty-input"
                     style="width:60px" value="<%= item.quantity %>" min="1"
                     max="<%= item.stock_quantity %>" data-id="<%= item.id %>">
              <button class="btn btn-outline-secondary btn-sm qty-btn" data-action="plus" data-id="<%= item.id %>">+</button>
            </div>
            <div class="item-total fw-bold text-end" style="min-width:100px">
              <%= (item.price_at_time * item.quantity).toLocaleString('vi-VN') %>đ
            </div>
            <button class="btn btn-link text-danger p-0 remove-item" data-id="<%= item.id %>">
              <i class="bi bi-trash3"></i>
            </button>
          </div>
        </div>
      <% }); %>
    </div>

    <!-- Order Summary -->
    <div class="col-lg-4">
      <div class="card border-0 shadow-sm">
        <div class="card-body">
          <h6 class="fw-bold mb-3">Tóm tắt đơn hàng</h6>
          <div class="d-flex justify-content-between mb-2">
            <span>Tạm tính</span>
            <span id="subtotal"><%= subtotal.toLocaleString('vi-VN') %>đ</span>
          </div>
          <div class="d-flex justify-content-between mb-2">
            <span>Phí vận chuyển</span>
            <span id="shipping">
              <% if (shipping_fee === 0) { %><span class="text-success">Miễn phí</span>
              <% } else { %><%= shipping_fee.toLocaleString('vi-VN') %>đ<% } %>
            </span>
          </div>
          <hr>
          <div class="d-flex justify-content-between fw-bold fs-5">
            <span>Tổng cộng</span>
            <span class="text-danger" id="cart-total"><%= total.toLocaleString('vi-VN') %>đ</span>
          </div>
          <a href="/checkout" class="btn btn-danger w-100 mt-3">
            <i class="bi bi-credit-card"></i> Đặt hàng ngay
          </a>
          <a href="/products" class="btn btn-outline-secondary w-100 mt-2">Tiếp tục mua sắm</a>
        </div>
      </div>
    </div>
  </div>
<% } %>
```

---

## Bước 6 — public/js/cart.js (AJAX update)

```javascript
document.addEventListener('DOMContentLoaded', () => {
  // Thêm vào giỏ từ danh sách sản phẩm (AJAX)
  document.querySelectorAll('.add-to-cart-form').forEach(form => {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const btn = form.querySelector('button[type="submit"]');
      btn.disabled = true;
      try {
        const res = await fetch('/cart/add', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
          body: JSON.stringify({
            product_id: form.querySelector('[name="product_id"]').value,
            quantity: form.querySelector('[name="quantity"]')?.value || 1
          })
        });
        const data = await res.json();
        if (data.success) {
          updateCartBadge(data.cartCount);
          showToast('Đã thêm vào giỏ hàng', 'success');
        } else {
          showToast(data.error, 'danger');
        }
      } catch { showToast('Có lỗi xảy ra', 'danger'); }
      finally { btn.disabled = false; }
    });
  });

  // Thay đổi số lượng trong trang cart
  document.querySelectorAll('.qty-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      const id = btn.dataset.id;
      const input = document.querySelector(`.qty-input[data-id="${id}"]`);
      let qty = parseInt(input.value) + (btn.dataset.action === 'plus' ? 1 : -1);
      if (qty < 1) qty = 1;
      input.value = qty;
      await updateCartItem(id, qty);
    });
  });

  document.querySelectorAll('.qty-input').forEach(input => {
    input.addEventListener('change', () => updateCartItem(input.dataset.id, input.value));
  });

  // Event delegation cho remove-item (tránh lỗi khi element chưa tồn tại)
  document.addEventListener('click', async (e) => {
    const btn = e.target.closest('.remove-item');
    if (!btn) return;
    const id = btn.dataset.id;
    try {
      const res = await fetch(`/cart/items/${id}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        updateCartCount();
        location.reload();
      } else {
        showToast(data.message || 'Có lỗi xảy ra', 'danger');
      }
    } catch(e) {
      showToast('Có lỗi xảy ra', 'danger');
    }
  });

  async function updateCartItem(id, qty) {
    const res = await fetch(`/cart/items/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ quantity: qty })
    });
    const data = await res.json();
    if (data.success) {
      document.querySelector(`#cart-item-${id} .item-total`).textContent =
        data.itemTotal.toLocaleString('vi-VN') + 'đ';
      updateCartTotals(data);
      updateCartBadge(data.cartCount);
    } else {
      showToast(data.error, 'danger');
    }
  }

  function updateCartTotals({ subtotal, shipping_fee, total }) {
    if (document.getElementById('subtotal'))
      document.getElementById('subtotal').textContent = subtotal.toLocaleString('vi-VN') + 'đ';
    if (document.getElementById('cart-total'))
      document.getElementById('cart-total').textContent = total.toLocaleString('vi-VN') + 'đ';
  }

  function updateCartBadge(count) {
    const badge = document.querySelector('.cart-badge');
    if (badge) badge.textContent = count;
  }

  function showToast(msg, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `toast-notification alert alert-${type} position-fixed bottom-0 end-0 m-3`;
    toast.style.zIndex = 9999;
    toast.textContent = msg;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
  }
});
```

---

## Checklist xác nhận ✅

```
[x] GET /cart khi chưa đăng nhập → redirect /login
[x] GET /cart khi giỏ rỗng → hiển thị empty state
[x] POST /cart/add → item xuất hiện trong giỏ, badge cart-count cập nhật
[x] POST /cart/add sản phẩm đã có → tăng quantity, không tạo row mới
[x] POST /cart/add quantity > stock → flash error, không insert
[x] POST /cart/add sản phẩm hết hàng → flash error
[x] PATCH /cart/items/:id → cập nhật quantity, tổng tiền update AJAX
[x] DELETE /cart/items/:id → xóa item, tổng tiền update
[x] Item trong giỏ của user A không bị ảnh hưởng bởi user B
[x] Tổng tiền = SUM(price_at_time * quantity)
[x] Phí vận chuyển = 0 nếu subtotal >= 2,000,000đ, ngược lại 50,000đ
[x] Cart badge trên navbar cập nhật real-time
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 05`

---

## Test Cases — Cart

| ID | Input | Expected |
|----|-------|----------|
| TC20 | POST /cart/add: product_id mới, qty=2 | Thêm vào giỏ, cartCount+2, JSON {success:true} |
| TC21 | POST /cart/add: cùng product_id đã có | Cộng dồn quantity, không tạo record mới |
| TC22 | POST /cart/add: qty > stock_quantity | Flash/JSON lỗi "Vượt quá tồn kho" |
| TC23 | POST /cart/add: sản phẩm status=inactive | Báo lỗi, không thêm |
| TC24 | PATCH /cart/items/:id: qty=3 | itemTotal và cartTotal cập nhật đúng (AJAX) |
| TC25 | DELETE /cart/items/:id | Item xóa, total cập nhật |
| TC26 | Xóa hết items | Empty state + link /products |
| TC27 | User A DELETE item của User B | 403 Forbidden |
| TC28 | subtotal >= 2.000.000đ | shipping_fee = 0 |
| TC29 | subtotal < 2.000.000đ | shipping_fee = 50.000đ |
| TC30 | Giá trong giỏ | Dùng sale_price nếu có, ngược lại dùng price |
