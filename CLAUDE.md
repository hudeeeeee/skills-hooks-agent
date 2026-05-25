# DATN — Website TMĐT Bán Đồ Điện Tử

## Tài liệu tham chiếu
- Spec đầy đủ: `SPEC.md`
- Skills: `skills/skill-XX-*.md`
- Hooks (validation scripts): `hooks/hook-XX-*.sh`

## Stack
- Node.js + Express.js + EJS + MySQL (mysql2) + express-session + bcrypt + multer

## Thứ tự build BẮT BUỘC

Build theo đúng thứ tự sau, từng skill một. Không skip, không build song song:

| Bước | Skill File | Nội dung |
|------|-----------|---------|
| 00 | skills/skill-00-install.md | Cài packages, tạo thư mục, .env, MySQL database |
| 01 | skills/skill-01-setup.md | Project setup, cấu trúc thư mục, layout EJS |
| 02 | skills/skill-02-database.md | Database schema 12 bảng + seed data điện tử |
| 03 | skills/skill-03-auth.md | Register, login, logout, session, middleware |
| 04 | skills/skill-04-products.md | Product listing, search, filter, detail page |
| 05 | skills/skill-05-cart.md | Cart: add, update, remove, stock validation |
| 06 | skills/skill-06-orders.md | Checkout, create order, order history, cancel |
| 07 | skills/skill-07-payment.md | COD, bank transfer, VNPay sandbox |
| 08 | skills/skill-08-reviews.md | Review creation, permission check, rating avg |
| 09 | skills/skill-09-warranty.md | Warranty request + admin processing |
| 10 | skills/skill-10-admin.md | Admin dashboard, CRUD product, order mgmt |
| 11 | skills/skill-11-ui.md | UI/UX consistency, responsive, empty states |
| 12 | skills/skill-12-api.md | Route audit, missing endpoints, final wiring |

## Hooks — chạy TRƯỚC và SAU mỗi skill

```
TRƯỚC khi bắt đầu skill: chạy hooks/hook-01-prebuild.sh
SAU khi xong skill:       chạy hooks/hook-10-qa.sh

Khi có input từ user:     đọc hooks/hook-02-security.sh
Khi có DB write phức tạp: đọc hooks/hook-03-transaction.sh
Khi cập nhật đơn hàng:    đọc hooks/hook-05-order-state.sh
Khi thay đổi tồn kho:     đọc hooks/hook-06-inventory.sh
Khi xử lý thanh toán:     đọc hooks/hook-07-payment.sh
Khi tạo review:           đọc hooks/hook-08-review.sh
Khi viết admin route:     đọc hooks/hook-09-admin.sh
Khi viết view/template:   đọc hooks/hook-04-ui.sh
```

## Quy tắc cứng (KHÔNG được vi phạm)

1. Không lưu plain password — bcrypt bắt buộc
2. Không nối string SQL trực tiếp — prepared statements
3. Transaction cho: tạo đơn, hủy đơn, trừ/hoàn kho
4. Route /admin/* phải qua requireAdmin middleware
5. User chỉ xem resource của chính mình
6. stock_quantity không bao giờ âm
7. payment_status = 'paid' chỉ set sau khi verify callback/gateway
8. Order state chỉ transition theo bảng hợp lệ (hook-05)

## Domain: Đồ Điện Tử

Sản phẩm: Điện thoại, Laptop, Tablet, Tai nghe, TV, Gaming, Máy ảnh, Đồng hồ thông minh, Phụ kiện
Thương hiệu: Apple, Samsung, Sony, ASUS, Dell, LG, TP-Link, Xiaomi, JBL, Canon
Giá trị đơn hàng điển hình: 500,000đ — 70,000,000đ
Miễn phí vận chuyển: đơn >= 2,000,000đ
Phí vận chuyển mặc định: 50,000đ
