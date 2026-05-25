# SKILL 08 — Reviews & Ratings

## Mục tiêu
Customer đánh giá sản phẩm sau khi đơn completed. Cập nhật avg_rating. Admin ẩn review.

## Files cần tạo
```
src/controllers/review.controller.js
src/services/review.service.js
src/routes/review.routes.js
src/views/pages/products/partials/review-form.ejs
src/views/pages/products/partials/review-list.ejs
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

// POST /reviews
const createReview = async (req, res) => {
  const { product_id, order_id, rating, comment, redirect_to } = req.body;
  const result = await reviewService.createReview(req.session.user.id, { product_id, order_id, rating, comment });

  if (!result.success) req.flash('error', result.error);
  else req.flash('success', 'Cảm ơn bạn đã đánh giá sản phẩm!');

  res.redirect(redirect_to || `/orders/${req.body.order_code}`);
};

module.exports = { createReview };
```

---

## Bước 3 — Tích hợp form đánh giá vào trang chi tiết đơn hàng

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
        <% if (order.reviewedProductIds.includes(item.product_id)) { %>
          <span class="badge bg-success"><i class="bi bi-check-circle"></i> Đã đánh giá</span>
        <% } else { %>
          <button class="btn btn-outline-warning btn-sm" data-bs-toggle="modal"
                  data-bs-target="#reviewModal-<%= item.product_id %>">
            <i class="bi bi-star"></i> Đánh giá
          </button>
          <!-- Modal đánh giá -->
          <div class="modal fade" id="reviewModal-<%= item.product_id %>" tabindex="-1">
            <div class="modal-dialog">
              <form action="/reviews" method="POST" class="modal-content">
                <div class="modal-header">
                  <h6 class="modal-title">Đánh giá: <%= item.product_name %></h6>
                  <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                  <input type="hidden" name="product_id" value="<%= item.product_id %>">
                  <input type="hidden" name="order_id" value="<%= order.id %>">
                  <input type="hidden" name="order_code" value="<%= order.order_code %>">
                  <input type="hidden" name="redirect_to" value="/orders/<%= order.order_code %>">
                  <div class="mb-3">
                    <label class="form-label fw-bold">Đánh giá của bạn <span class="text-danger">*</span></label>
                    <div class="star-rating d-flex gap-2 fs-3">
                      <% for(let i=1; i<=5; i++) { %>
                        <input type="radio" name="rating" value="<%= i %>"
                               id="star-<%= item.product_id %>-<%= i %>"
                               class="d-none" required>
                        <label for="star-<%= item.product_id %>-<%= i %>"
                               class="text-muted cursor-pointer star-label"
                               style="cursor:pointer">☆</label>
                      <% } %>
                    </div>
                  </div>
                  <div class="mb-3">
                    <label class="form-label">Nhận xét (tuỳ chọn)</label>
                    <textarea name="comment" class="form-control" rows="3"
                              placeholder="Chia sẻ trải nghiệm của bạn..." maxlength="1000"></textarea>
                  </div>
                </div>
                <div class="modal-footer">
                  <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Hủy</button>
                  <button type="submit" class="btn btn-warning">Gửi đánh giá</button>
                </div>
              </form>
            </div>
          </div>
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
[x] Button "Đánh giá" chỉ xuất hiện khi order_status = completed
[x] Button "Đã đánh giá" sau khi review xong
[ ] Star rating UI hoạt động (hover, click)
[ ] Admin ẩn review → avg_rating được recalculate
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 08`
