# SKILL 11 — UI/UX Consistency

## Mục tiêu
Giao diện nhất quán, responsive, có đủ trạng thái (empty/error/loading), UX tốt.

---

## Checklist tổng quát mỗi trang

```
LAYOUT:
[ ] Header (navbar) giống nhau trên mọi trang public
[ ] Footer đầy đủ: logo, danh mục, liên hệ, mạng xã hội
[ ] Breadcrumb trên trang sâu hơn 1 cấp (/products/:slug, /orders/:code, /admin/*)
[ ] Flash message hiển thị và tự ẩn sau 4 giây

STATES:
[ ] Empty state: icon + text mô tả + CTA (Giỏ rỗng, Không có đơn, Không có KQ tìm kiếm)
[ ] Loading: button submit disabled + spinner khi POST form
[ ] Error: hiển thị lỗi validation ngay dưới field input
[ ] Success: flash message màu xanh, redirect

RESPONSIVE:
[ ] Mobile 375px: không bị overflow ngang
[ ] Button/tap target >= 44px
[ ] Navigation mobile: hamburger menu
[ ] Product card: 2 cột trên mobile, 3 cột tablet, 4 cột desktop
[ ] Cart: layout dọc trên mobile
[ ] Checkout: layout dọc trên mobile

DATA FORMAT:
[ ] Giá tiền: 34.990.000đ (toLocaleString vi-VN)
[ ] Ngày: dd/mm/yyyy HH:mm
[ ] Rating: sao màu vàng + số đánh giá
[ ] Trạng thái đơn: badge màu đúng
```

---

## CSS cần thêm vào public/css/style.css

```css
/* Product card */
.product-card { transition: transform 0.2s, box-shadow 0.2s; }
.product-card:hover { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.12) !important; }
.product-thumb { width: 100%; height: 200px; object-fit: cover; }

/* Star rating */
.text-star { color: #ffc107; }

/* Breadcrumb */
.breadcrumb-item + .breadcrumb-item::before { content: "›"; }

/* Toast notification */
.toast-notification {
  position: fixed; bottom: 1rem; right: 1rem;
  z-index: 9999; min-width: 250px; animation: slideIn 0.3s ease;
}
@keyframes slideIn { from { transform: translateX(100%); opacity: 0; } to { transform: translateX(0); opacity: 1; } }

/* Button loading */
.btn-loading { pointer-events: none; opacity: 0.7; }
.btn-loading::after { content: ""; display: inline-block; width: 12px; height: 12px;
  border: 2px solid currentColor; border-top-color: transparent;
  border-radius: 50%; animation: spin 0.6s linear infinite; margin-left: 6px; }
@keyframes spin { to { transform: rotate(360deg); } }

/* Admin sidebar */
.nav-link.active { background: #f0f4ff; border-radius: 8px; }

/* Empty state */
.empty-state { padding: 3rem; text-align: center; color: #6c757d; }
.empty-state i { font-size: 3rem; opacity: 0.4; }

/* Mobile fixes */
@media (max-width: 576px) {
  .product-thumb { height: 150px; }
  .navbar-brand { font-size: 1rem; }
  .cart-summary { position: static !important; }
}
```

---

## JS loading state (thêm vào main.js)

```javascript
// Auto-disable submit button khi form submit (tránh double-submit)
document.querySelectorAll('form:not([data-no-loading])').forEach(form => {
  form.addEventListener('submit', () => {
    const btn = form.querySelector('[type="submit"]');
    if (btn) {
      btn.disabled = true;
      btn.classList.add('btn-loading');
      const originalText = btn.textContent;
      btn.textContent = 'Đang xử lý...';
      // Reset sau 10s phòng trường hợp lỗi
      setTimeout(() => {
        btn.disabled = false;
        btn.classList.remove('btn-loading');
        btn.textContent = originalText;
      }, 10000);
    }
  });
});
```

---

## Trang chủ home.ejs — cấu trúc

```
1. Hero banner: ảnh nền, tagline "Đồ Điện Tử Chính Hãng", CTA "Mua ngay"
2. Danh mục nhanh: 8 danh mục, icon, responsive grid
3. Section "Đang giảm giá": horizontal scroll trên mobile, grid 4 cột desktop
4. Section "Mới nhất": tương tự
5. Section "Đánh giá cao": tương tự
6. Banner khuyến mãi: 2 cột
7. Footer
```

---

## Footer đầy đủ

```html
<footer class="bg-dark text-light mt-5 py-5">
  <div class="container">
    <div class="row g-4">
      <div class="col-md-3">
        <h5 class="fw-bold"><i class="bi bi-lightning-charge-fill text-warning"></i> ElectroShop</h5>
        <p class="text-muted small">Chuyên cung cấp đồ điện tử chính hãng, giá tốt nhất thị trường.</p>
        <div class="d-flex gap-2 mt-2">
          <a href="#" class="btn btn-outline-light btn-sm"><i class="bi bi-facebook"></i></a>
          <a href="#" class="btn btn-outline-light btn-sm"><i class="bi bi-instagram"></i></a>
          <a href="#" class="btn btn-outline-light btn-sm"><i class="bi bi-youtube"></i></a>
        </div>
      </div>
      <div class="col-md-3">
        <h6 class="fw-bold">Danh mục</h6>
        <ul class="list-unstyled small text-muted">
          <li><a href="/categories/dien-thoai-phu-kien" class="text-muted text-decoration-none">Điện thoại</a></li>
          <li><a href="/categories/laptop-may-tinh-bang" class="text-muted text-decoration-none">Laptop & Tablet</a></li>
          <li><a href="/categories/am-thanh-tai-nghe" class="text-muted text-decoration-none">Âm thanh</a></li>
          <li><a href="/categories/gaming-console" class="text-muted text-decoration-none">Gaming</a></li>
        </ul>
      </div>
      <div class="col-md-3">
        <h6 class="fw-bold">Hỗ trợ</h6>
        <ul class="list-unstyled small text-muted">
          <li>Miễn phí ship đơn ≥ 2.000.000đ</li>
          <li>Bảo hành chính hãng</li>
          <li>Đổi trả trong 7 ngày</li>
          <li>Thanh toán an toàn</li>
        </ul>
      </div>
      <div class="col-md-3">
        <h6 class="fw-bold">Liên hệ</h6>
        <ul class="list-unstyled small text-muted">
          <li><i class="bi bi-telephone me-1"></i> 1800 xxxx</li>
          <li><i class="bi bi-envelope me-1"></i> support@electroshop.com</li>
          <li><i class="bi bi-clock me-1"></i> 8:00 - 21:00 mỗi ngày</li>
        </ul>
      </div>
    </div>
    <hr class="border-secondary mt-4">
    <p class="text-center text-muted small mb-0">© 2024 ElectroShop. Đồ Án Tốt Nghiệp.</p>
  </div>
</footer>
```

---

## Breadcrumb partial

```html
<!-- src/views/partials/breadcrumb.ejs -->
<!-- Usage: <%- include('../partials/breadcrumb', { items: [{label:'Trang chủ',url:'/'},{label:'Sản phẩm',url:'/products'},{label:product.name}] }) %> -->
<nav aria-label="breadcrumb" class="mb-3">
  <ol class="breadcrumb">
    <% items.forEach((item, i) => { %>
      <li class="breadcrumb-item <%= i === items.length-1 ? 'active' : '' %>">
        <% if (item.url && i < items.length-1) { %>
          <a href="<%= item.url %>" class="text-decoration-none"><%= item.label %></a>
        <% } else { %>
          <span class="text-muted text-truncate" style="max-width:200px;display:inline-block"><%= item.label %></span>
        <% } %>
      </li>
    <% }); %>
  </ol>
</nav>
```

---

## Profile page (thông tin cá nhân)

```
Routes:
GET  /profile         → form xem + sửa thông tin
POST /profile         → update full_name, phone
GET  /profile/addresses    → danh sách địa chỉ
POST /profile/addresses    → thêm địa chỉ mới
PUT  /profile/addresses/:id → sửa địa chỉ
DELETE /profile/addresses/:id → xóa địa chỉ
GET  /profile/change-password → form đổi MK
POST /profile/change-password → xử lý đổi MK
```

---

## Checklist xác nhận ✅

```
[x] Trang chủ: 3 section sản phẩm hiển thị đúng
[x] Footer đầy đủ, responsive
[x] Breadcrumb đúng trên /products/:slug và /orders/:code
[x] Flash message tự ẩn sau 4 giây
[x] Submit button disabled khi đang xử lý
[x] Empty state trên: giỏ rỗng, không có đơn, không có kết quả tìm kiếm
[x] Mobile 375px: không overflow, tap target đủ lớn
[x] Product grid: 2 cột mobile, 3 tablet, 4 desktop
[x] Giá format đúng: 34.990.000đ
[x] Ngày format đúng: dd/mm/yyyy
[x] Rating stars hiển thị đúng màu
[x] Ảnh sản phẩm: fallback /images/no-image.png khi lỗi
[x] Lazy loading ảnh hoạt động
[x] Không có lỗi console trên bất kỳ trang nào
[x] Smooth transitions và hover effects (buttons, cards, links)
[x] Fade-in animation cho product cards
[x] Brand filter removed from products listing page
[x] Images now stored in /img/products/ instead of /uploads/products/
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 11`

---

## Test Cases — UI/UX & Responsive

| ID | Tên test | Input | Expected | Loại |
|----|----------|-------|----------|------|
| TC81 | Trang chủ hiển thị desktop | Chrome 1920×1080 | Layout đúng, không overflow, nav hiển thị đủ | UI |
| TC82 | Trang chủ responsive mobile | Chrome DevTools 375×812 (iPhone) | Hamburger menu, ảnh co dãn, không scroll ngang | UI |
| TC83 | Trang chủ responsive tablet | 768×1024 | Grid 2 cột, layout không vỡ | UI |
| TC84 | Empty state giỏ hàng | Giỏ hàng rỗng | Hiển thị icon + "Giỏ hàng trống" + nút mua sắm | UI |
| TC85 | Empty state kết quả tìm kiếm | Tìm từ không có kết quả | "Không tìm thấy sản phẩm" + gợi ý từ khóa khác | UI |
| TC86 | Loading state | Mạng chậm, fetch dữ liệu | Skeleton/spinner hiển thị, không blank trắng | UI |
| TC87 | Thông báo thành công | Thêm vào giỏ hàng | Toast/alert "Đã thêm vào giỏ hàng" tự biến mất sau 3s | UI |
| TC88 | Thông báo lỗi | Đặt hàng thất bại | Alert đỏ hiển thị message lỗi rõ ràng | UI |
| TC89 | Phân trang sản phẩm | 50+ sản phẩm | Pagination đúng, trang active highlight | UI |
| TC90 | Breadcrumb navigation | Vào trang chi tiết SP | Breadcrumb đúng: Home > Category > Product | UI |
| TC91 | Hình ảnh broken | src ảnh không tồn tại | Fallback image hoặc icon placeholder | UI |
| TC92 | Form validation real-time | Nhập email sai format | Border đỏ + hint ngay khi blur, không cần submit | UI |
| TC93 | Dark mode (nếu có) | Toggle dark mode | Tất cả màu sắc chuyển đúng, text readable | UI |
| TC94 | Accessibility — alt text | Inspect ảnh sản phẩm | Tất cả <img> có alt attribute | Accessibility |
| TC95 | Page title mỗi trang | Xem trang khác nhau | <title> thay đổi đúng theo trang | UI |
| UI01 | Font chữ nhất quán | Inspect toàn site | Chỉ dùng 1-2 font family, không font random | UI |
| UI02 | Color scheme nhất quán | Inspect button/link | Primary color đồng nhất, không màu lạ | UI |

