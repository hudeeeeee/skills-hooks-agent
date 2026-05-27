# SKILL 08 — Reviews & Ratings

## Mục tiêu
Customer đánh giá sản phẩm sau khi đơn completed. Cập nhật avg_rating. Admin ẩn review.

## Files cần tạo
```
src/controllers/review.controller.js
src/services/review.service.js
src/routes/review.routes.js
src/views/pages/reviews/create.ejs
```

---

## Bước 1 — review.service.js

```javascript
const pool = require('../config/database');

async function canReview(userId, productId, orderId) {
  // Điều kiện 1: order thuộc user và completed
  const [orders] = await pool.query(
    "SELECT id FROM orders WHERE id = ? AND user_id = ? AND order_status = 'completed'",
    [orderId, userId]
  );
  if (!orders.length) return { allowed: false, reason: 'Đơn hàng chưa hoàn thành hoặc không tồn tại' };

  // Điều kiện 2: product nằm trong order
  const [items] = await pool.query(
    'SELECT id FROM order_items WHERE order_id = ? AND product_id = ?',
    [orderId, productId]
  );
  if (!items.length) return { allowed: false, reason: 'Sản phẩm không thuộc đơn hàng này' };

  // Điều kiện 3: chưa review
  const [existing] = await pool.query(
    'SELECT id FROM reviews WHERE user_id = ? AND product_id = ? AND order_id = ?',
    [userId, productId, orderId]
  );
  if (existing.length) return { allowed: false, reason: 'Bạn đã đánh giá sản phẩm này' };

  return { allowed: true };
}

async function createReview(userId, { product_id, order_id, rating, comment }) {
  const ratingNum = parseInt(rating);
  if (!ratingNum || ratingNum < 1 || ratingNum > 5) {
    return { success: false, error: 'Điểm đánh giá phải từ 1 đến 5' };
  }

  const check = await canReview(userId, product_id, order_id);
  if (!check.allowed) return { success: false, error: check.reason };

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    await conn.query(
      'INSERT INTO reviews (user_id, product_id, order_id, rating, comment) VALUES (?, ?, ?, ?, ?)',
      [userId, product_id, order_id, ratingNum, comment?.trim() || null]
    );

    // Cập nhật avg_rating và review_count (chỉ tính visible)
    await conn.query(
      `UPDATE products SET
         avg_rating = (SELECT AVG(rating) FROM reviews WHERE product_id = ? AND status = 'visible'),
         review_count = (SELECT COUNT(*) FROM reviews WHERE product_id = ? AND status = 'visible')
       WHERE id = ?`,
      [product_id, product_id, product_id]
    );

    await conn.commit();
    return { success: true };
  } catch (err) {
    await conn.rollback();
    return { success: false, error: 'Đánh giá thất bại' };
  } finally {
    conn.release();
  }
}

async function getProductReviews(productId, page = 1) {
  const pageSize = 5;
  const offset = (page - 1) * pageSize;
  const [reviews] = await pool.query(
    `SELECT r.*, u.full_name FROM reviews r JOIN users u ON r.user_id = u.id
     WHERE r.product_id = ? AND r.status = 'visible'
     ORDER BY r.created_at DESC LIMIT ? OFFSET ?`,
    [productId, pageSize, offset]
  );
  const [[{ cnt }]] = await pool.query(
    "SELECT COUNT(*) AS cnt FROM reviews WHERE product_id = ? AND status = 'visible'", [productId]
  );
  return { reviews, totalPages: Math.ceil(cnt / pageSize), page, total: cnt };
}

// Admin: thay đổi status review
async function setReviewStatus(reviewId, status) {
  const valid = ['visible', 'hidden', 'pending'];
  if (!valid.includes(status)) return { success: false, error: 'Trạng thái không hợp lệ' };

  const [rows] = await pool.query('SELECT product_id FROM reviews WHERE id = ?', [reviewId]);
  if (!rows.length) return { success: false, error: 'Không tìm thấy đánh giá' };
  const productId = rows[0].product_id;

  await pool.query('UPDATE reviews SET status = ? WHERE id = ?', [status, reviewId]);

  // Recalculate avg_rating sau khi ẩn/hiện review
  await pool.query(
    `UPDATE products SET
       avg_rating = COALESCE((SELECT AVG(rating) FROM reviews WHERE product_id = ? AND status = 'visible'), 0),
       review_count = (SELECT COUNT(*) FROM reviews WHERE product_id = ? AND status = 'visible')
     WHERE id = ?`,
    [productId, productId, productId]
  );

  return { success: true };
}

module.exports = { canReview, createReview, getProductReviews, setReviewStatus };
```

---

## Bước 2 — review.controller.js

```javascript
const reviewService = require('../services/review.service');
const pool = require('../config/database');

// GET /reviews/create?product_id=&order_id=
const getCreateReview = async (req, res) => {
  const { product_id, order_id } = req.query;
  const [products] = await pool.query('SELECT name, slug FROM products WHERE id = ?', [product_id]);
  if (!products.length) return res.status(404).render('errors/404', { title: 'Sản phẩm không tìm thấy' });

  const check = await reviewService.canReview(req.session.user.id, product_id, order_id);
  if (!check.allowed) {
    req.flash('error', check.reason);
    return res.redirect('back');
  }

  res.render('pages/reviews/create', {
    title: 'Đánh giá sản phẩm',
    product: products[0],
    product_id,
    order_id
  });
};

// POST /reviews
const postCreateReview = async (req, res) => {
  const result = await reviewService.createReview(req.session.user.id, req.body);
  if (!result.success) {
    req.flash('error', result.error);
    return res.redirect('back');
  }
  req.flash('success', 'Cảm ơn bạn đã đánh giá sản phẩm!');
  // Query order_code từ order_id (không dùng hidden field)
  const [orderRows] = await pool.query('SELECT order_code FROM orders WHERE id = ?', [req.body.order_id]);
  const redirectTo = orderRows.length ? `/orders/${orderRows[0].order_code}` : '/orders';
  res.redirect(redirectTo);
};

module.exports = { getCreateReview, postCreateReview };
```

---

## Bước 3 — review.routes.js

```javascript
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/review.controller');
const { requireAuth } = require('../middlewares/auth.middleware');

router.get('/reviews/create', requireAuth, ctrl.getCreateReview);
router.post('/reviews', requireAuth, ctrl.postCreateReview);

module.exports = router;
```

---

## Bước 4 — reviews/create.ejs (trang đánh giá riêng)

```html
<%- include('../../partials/top') %>
<div class="row justify-content-center">
  <div class="col-md-6">
    <div class="card border-0 shadow-sm">
      <div class="card-body p-4">
        <h5 class="fw-bold mb-1">Đánh giá sản phẩm</h5>
        <p class="text-muted mb-4">
          <a href="/products/<%= product.slug %>"><%= product.name %></a>
        </p>
        <form action="/reviews" method="POST">
          <input type="hidden" name="product_id" value="<%= product_id %>">
          <input type="hidden" name="order_id" value="<%= order_id %>">
          <div class="mb-3">
            <label class="form-label fw-medium">Số sao <span class="text-danger">*</span></label>
            <div class="d-flex gap-2 mb-2" id="star-rating">
              <% for(let i=1; i<=5; i++) { %>
                <button type="button" class="btn btn-outline-warning star-btn" data-value="<%= i %>">
                  <i class="bi bi-star"></i> <%= i %>
                </button>
              <% } %>
            </div>
            <input type="hidden" name="rating" id="rating-input" required>
          </div>
          <div class="mb-3">
            <label class="form-label fw-medium">Nhận xét</label>
            <textarea name="comment" class="form-control" rows="4"
                      placeholder="Chia sẻ trải nghiệm của bạn..."></textarea>
          </div>
          <button type="submit" class="btn btn-warning w-100">Gửi đánh giá</button>
        </form>
      </div>
    </div>
  </div>
</div>
<script>
document.querySelectorAll('.star-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const val = parseInt(btn.dataset.value);
    document.getElementById('rating-input').value = val;
    document.querySelectorAll('.star-btn').forEach((b, i) => {
      b.classList.toggle('btn-warning', i < val);
      b.classList.toggle('btn-outline-warning', i >= val);
    });
  });
});
</script>
<%- include('../../partials/bot') %>
```

---

## Bước 5 — Nút "Đánh giá" trong orders/detail.ejs

> **UX thực tế:** Không dùng modal inline. Nút "Đánh giá" là link đến trang riêng `/reviews/create?product_id=&order_id=`.

Trong `src/views/pages/orders/detail.ejs`, với mỗi order_item:

```html
<% items.forEach(item => { %>
  <div class="d-flex gap-3 py-3 border-bottom">
    <img src="<%= item.product_image || '/images/no-image.png' %>" width="70" height="70"
         class="rounded object-fit-cover" alt="">
    <div class="flex-grow-1">
      <div class="fw-bold"><%= item.product_name %></div>
      <small class="text-muted">SL: <%= item.quantity %> × <%= item.price.toLocaleString('vi-VN') %>đ</small>
    </div>
    <div>
      <% if (order.order_status === 'completed') { %>
        <% if (order.reviewedProductIds && order.reviewedProductIds.includes(item.product_id)) { %>
          <span class="badge bg-success"><i class="bi bi-check-circle"></i> Đã đánh giá</span>
        <% } else { %>
          <a href="/reviews/create?product_id=<%= item.product_id %>&order_id=<%= order.id %>"
             class="btn btn-outline-warning btn-sm">
            <i class="bi bi-star"></i> Đánh giá
          </a>
        <% } %>
      <% } %>
    </div>
  </div>
<% }); %>
```

---

## Bước 4 — Star rating JS (thêm vào main.js)

```javascript
// Interactive star rating
document.querySelectorAll('.star-rating').forEach(container => {
  const labels = container.querySelectorAll('.star-label');
  const inputs = container.querySelectorAll('input[type="radio"]');

  labels.forEach((label, i) => {
    label.addEventListener('mouseover', () => {
      labels.forEach((l, j) => l.textContent = j <= i ? '★' : '☆');
      labels.forEach((l, j) => l.style.color = j <= i ? '#ffc107' : '#6c757d');
    });
    label.addEventListener('mouseout', () => {
      const checked = [...inputs].findIndex(inp => inp.checked);
      labels.forEach((l, j) => {
        l.textContent = j <= checked ? '★' : '☆';
        l.style.color = j <= checked ? '#ffc107' : '#6c757d';
      });
    });
    label.addEventListener('click', () => {
      inputs[i].checked = true;
      labels.forEach((l, j) => {
        l.textContent = j <= i ? '★' : '☆';
        l.style.color = j <= i ? '#ffc107' : '#6c757d';
      });
    });
  });
});
```

---

## Checklist xác nhận ✅

```
[x] POST /reviews khi order pending → flash error "chưa hoàn thành"
[x] POST /reviews khi order completed đúng product → tạo review thành công
[x] POST /reviews lần 2 cùng product+order → flash error "đã đánh giá"
[x] POST /reviews product không thuộc order → flash error
[x] rating = 0 hoặc > 5 → flash error validate
[x] Sau khi tạo review: products.avg_rating cập nhật đúng
[x] Sau khi tạo review: products.review_count tăng đúng
[x] Review hiển thị trên trang chi tiết sản phẩm (visible only)
[x] GET /reviews/create?product_id=&order_id= → render form đúng
[x] GET /reviews/create với order chưa completed → flash error, redirect back
[x] Link "Đánh giá" chỉ xuất hiện khi order_status = completed
[x] Link "Đã đánh giá" (badge) sau khi review xong
[x] Star rating button UI (click highlight) hoạt động
[x] POST /reviews khi order pending → flash error "chưa hoàn thành"
[x] POST /reviews khi order completed đúng product → tạo review, redirect /orders/:code
[x] POST /reviews lần 2 cùng product+order → flash error "đã đánh giá"
[x] POST /reviews product không thuộc order → flash error
[x] rating = 0 hoặc > 5 → flash error validate
[x] Sau khi tạo review: products.avg_rating cập nhật đúng
[x] Sau khi tạo review: products.review_count tăng đúng
[x] Review hiển thị trên trang chi tiết sản phẩm (visible only)
[ ] Admin ẩn review → avg_rating được recalculate
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 08`

---

## Test Cases — Reviews

| ID | Input | Expected |
|----|-------|----------|
| TC50 | GET /reviews/create?product_id=X&order_id=Y (completed) | Render form đúng, hiển thị tên SP |
| TC51 | GET /reviews/create: đơn status=shipping | Flash error, redirect back |
| TC52 | POST /reviews: đơn completed, rating=5 | Review lưu, redirect /orders/:code, avg_rating cập nhật |
| TC53 | POST /reviews: đơn status=shipping | Flash "chưa hoàn thành", không lưu |
| TC54 | POST /reviews: review đã tồn tại (user+product+order) | Flash "Đã đánh giá sản phẩm này" |
| TC55 | POST /reviews: rating=6 | Validation lỗi, không lưu |
| TC56 | POST /reviews: rating=0 | Validation lỗi |
| TC57 | POST /reviews: product không nằm trong order | Flash error |
| TC56 | POST /reviews: order của user khác | 403 |
| TC57 | Admin PATCH /admin/reviews/:id/status=hidden | Review ẩn, không tính vào avg_rating |
| TC58 | avg_rating sau khi ẩn review | Tính lại chỉ từ review status=visible |
