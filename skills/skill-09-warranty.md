# SKILL 09 — Warranty Request

## Mục tiêu
Customer gửi yêu cầu bảo hành cho sản phẩm đã mua. Admin xem và xử lý.

## Files cần tạo
```
src/controllers/warranty.controller.js
src/services/warranty.service.js
src/routes/warranty.routes.js
src/views/pages/warranty/form.ejs
src/views/admin/warranty/index.ejs
src/views/admin/warranty/detail.ejs
```

---

## Bước 1 — warranty.service.js

```javascript
const pool = require('../config/database');

const VALID_TRANSITIONS = {
  pending:    ['approved', 'rejected'],
  approved:   ['processing'],
  rejected:   [],
  processing: ['completed'],
  completed:  []
};

async function canSubmitWarranty(userId, productId, orderId) {
  // Đơn phải completed và thuộc user
  const [orders] = await pool.query(
    "SELECT o.created_at FROM orders o WHERE o.id = ? AND o.user_id = ? AND o.order_status = 'completed'",
    [orderId, userId]
  );
  if (!orders.length) return { allowed: false, reason: 'Đơn hàng chưa hoàn thành hoặc không tồn tại' };

  // Product nằm trong order
  const [items] = await pool.query(
    'SELECT oi.id FROM order_items oi WHERE oi.order_id = ? AND oi.product_id = ?',
    [orderId, productId]
  );
  if (!items.length) return { allowed: false, reason: 'Sản phẩm không thuộc đơn hàng này' };

  // Kiểm tra thời hạn bảo hành
  const [products] = await pool.query('SELECT warranty_months FROM products WHERE id = ?', [productId]);
  if (products.length && products[0].warranty_months > 0) {
    const completedAt = new Date(orders[0].created_at);
    const expiresAt = new Date(completedAt.setMonth(completedAt.getMonth() + products[0].warranty_months));
    if (new Date() > expiresAt) {
      return { allowed: false, reason: `Sản phẩm đã hết thời hạn bảo hành (${products[0].warranty_months} tháng)` };
    }
  }

  return { allowed: true };
}

async function createWarrantyRequest(userId, { product_id, order_id, issue_description }) {
  if (!issue_description?.trim()) return { success: false, error: 'Vui lòng mô tả vấn đề' };

  const check = await canSubmitWarranty(userId, product_id, order_id);
  if (!check.allowed) return { success: false, error: check.reason };

  await pool.query(
    'INSERT INTO warranty_requests (user_id, product_id, order_id, issue_description) VALUES (?, ?, ?, ?)',
    [userId, product_id, order_id, issue_description.trim()]
  );
  return { success: true };
}

async function getUserWarrantyRequests(userId) {
  const [rows] = await pool.query(
    `SELECT wr.*, p.name AS product_name, pi.image_url AS product_image, o.order_code
     FROM warranty_requests wr
     JOIN products p ON wr.product_id = p.id
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
     JOIN orders o ON wr.order_id = o.id
     WHERE wr.user_id = ? ORDER BY wr.created_at DESC`,
    [userId]
  );
  return rows;
}

// Admin
async function getAllWarrantyRequests({ status, page = 1 }) {
  const pageSize = 20;
  const offset = (page - 1) * pageSize;
  const where = status ? 'WHERE wr.status = ?' : '';
  const params = status ? [status, pageSize, offset] : [pageSize, offset];

  const [rows] = await pool.query(
    `SELECT wr.*, p.name AS product_name, u.full_name AS customer_name, o.order_code
     FROM warranty_requests wr
     JOIN products p ON wr.product_id = p.id
     JOIN users u ON wr.user_id = u.id
     JOIN orders o ON wr.order_id = o.id
     ${where} ORDER BY wr.created_at DESC LIMIT ? OFFSET ?`,
    params
  );
  return rows;
}

async function updateWarrantyStatus(id, newStatus, adminNote) {
  const [rows] = await pool.query('SELECT status FROM warranty_requests WHERE id = ?', [id]);
  if (!rows.length) return { success: false, error: 'Không tìm thấy yêu cầu bảo hành' };

  const currentStatus = rows[0].status;
  if (!VALID_TRANSITIONS[currentStatus]?.includes(newStatus)) {
    return { success: false, error: `Không thể chuyển từ "${currentStatus}" sang "${newStatus}"` };
  }

  await pool.query(
    'UPDATE warranty_requests SET status = ?, admin_note = ?, updated_at = NOW() WHERE id = ?',
    [newStatus, adminNote || null, id]
  );
  return { success: true };
}

module.exports = { createWarrantyRequest, getUserWarrantyRequests, getAllWarrantyRequests, updateWarrantyStatus };
```

---

## Bước 2 — warranty.controller.js

```javascript
const warrantyService = require('../services/warranty.service');

// POST /warranty
const createWarranty = async (req, res) => {
  const { product_id, order_id, order_code, issue_description } = req.body;
  const result = await warrantyService.createWarrantyRequest(req.session.user.id,
    { product_id, order_id, issue_description });

  if (!result.success) req.flash('error', result.error);
  else req.flash('success', 'Yêu cầu bảo hành đã được gửi. Chúng tôi sẽ phản hồi sớm nhất.');
  res.redirect(`/orders/${order_code}`);
};

// GET /profile/warranty
const getMyWarranty = async (req, res) => {
  const requests = await warrantyService.getUserWarrantyRequests(req.session.user.id);
  res.render('pages/warranty/index', { title: 'Yêu cầu bảo hành', requests });
};

// Admin
const adminListWarranty = async (req, res) => {
  const requests = await warrantyService.getAllWarrantyRequests({ status: req.query.status });
  res.render('admin/warranty/index', { title: 'Quản lý bảo hành', requests, currentStatus: req.query.status });
};

const adminUpdateWarranty = async (req, res) => {
  const result = await warrantyService.updateWarrantyStatus(req.params.id, req.body.status, req.body.admin_note);
  if (!result.success) req.flash('error', result.error);
  else req.flash('success', 'Cập nhật trạng thái thành công');
  res.redirect('/admin/warranty');
};

module.exports = { createWarranty, getMyWarranty, adminListWarranty, adminUpdateWarranty };
```

---

## Bước 3 — Form bảo hành trong trang chi tiết đơn hàng

Thêm vào `orders/detail.ejs` sau phần đánh giá, với điều kiện order completed:

```html
<% if (order.order_status === 'completed') { %>
  <div class="mt-4">
    <h6 class="fw-bold text-warning"><i class="bi bi-shield-check"></i> Yêu cầu bảo hành</h6>
    <% items.forEach(item => { %>
      <% if (item.warranty_months > 0) { %>
        <div class="d-flex justify-content-between align-items-center py-2 border-bottom">
          <span><%= item.product_name %></span>
          <button class="btn btn-outline-warning btn-sm" data-bs-toggle="modal"
                  data-bs-target="#warrantyModal-<%= item.product_id %>">
            Gửi yêu cầu bảo hành
          </button>
          <!-- Modal bảo hành -->
          <div class="modal fade" id="warrantyModal-<%= item.product_id %>" tabindex="-1">
            <div class="modal-dialog">
              <form action="/warranty" method="POST" class="modal-content">
                <div class="modal-header">
                  <h6 class="modal-title">Bảo hành: <%= item.product_name %></h6>
                  <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                  <input type="hidden" name="product_id" value="<%= item.product_id %>">
                  <input type="hidden" name="order_id" value="<%= order.id %>">
                  <input type="hidden" name="order_code" value="<%= order.order_code %>">
                  <div class="mb-3">
                    <label class="form-label fw-bold">Mô tả vấn đề <span class="text-danger">*</span></label>
                    <textarea name="issue_description" class="form-control" rows="4"
                              placeholder="Mô tả chi tiết lỗi/vấn đề bạn gặp phải..." required></textarea>
                  </div>
                </div>
                <div class="modal-footer">
                  <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Hủy</button>
                  <button type="submit" class="btn btn-warning">Gửi yêu cầu</button>
                </div>
              </form>
            </div>
          </div>
        </div>
      <% } %>
    <% }); %>
  </div>
<% } %>
```

---

## Trạng thái bảo hành (dùng trong views)

```javascript
// Thêm vào utils/orderStatus.js
const WARRANTY_STATUS_LABEL = {
  pending:    { label: 'Chờ xét duyệt', badge: 'warning'   },
  approved:   { label: 'Đã chấp nhận',  badge: 'info'      },
  rejected:   { label: 'Từ chối',        badge: 'danger'    },
  processing: { label: 'Đang xử lý',    badge: 'primary'   },
  completed:  { label: 'Hoàn tất',       badge: 'success'   }
};
```

---

## Checklist xác nhận ✅

```
[ ] POST /warranty khi order pending → flash error "chưa hoàn thành"
[ ] POST /warranty khi order completed, product đúng → tạo thành công
[ ] POST /warranty sản phẩm hết hạn bảo hành → flash error
[ ] POST /warranty product không thuộc order → flash error
[ ] GET /profile/warranty → danh sách yêu cầu bảo hành của user
[ ] GET /admin/warranty → admin thấy tất cả yêu cầu
[ ] PATCH /admin/warranty/:id pending→approved → cập nhật đúng
[ ] PATCH /admin/warranty/:id pending→processing → flash error (transition không hợp lệ)
[ ] PATCH /admin/warranty/:id completed→bất kỳ → flash error
[ ] Chỉ hiện nút bảo hành nếu sản phẩm có warranty_months > 0
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 09`
