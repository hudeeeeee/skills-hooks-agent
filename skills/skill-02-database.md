# SKILL 02 — Database Schema & Seed Data

## Mục tiêu
Tạo toàn bộ 12 bảng MySQL và dữ liệu mẫu cho website bán đồ điện tử.

## Output kỳ vọng
- `database/schema.sql` chạy không lỗi, tạo đủ 12 bảng
- `database/seed.sql` chạy không lỗi, có đủ dữ liệu test
- Kết nối từ Node.js thành công

---

## Bước 1 — Tạo database/schema.sql

Sao chép toàn bộ SQL DDL từ SPEC.md mục 3.3. Đây là thứ tự ĐÚNG để không lỗi FK:

```
1. users
2. addresses         (FK → users)
3. categories        (FK → categories self-ref)
4. products          (FK → categories)
5. product_images    (FK → products)
6. carts             (FK → users)
7. cart_items        (FK → carts, products)
8. orders            (FK → users)
9. order_items       (FK → orders, products)
10. payments         (FK → orders)
11. reviews          (FK → users, products, orders)
12. warranty_requests (FK → users, products, orders)
```

---

## Bước 2 — Tạo database/seed.sql

```sql
USE electronics_shop;

-- ============================================================
-- ADMIN + CUSTOMERS
-- Admin password: Admin@123456
-- Customer password: Customer@123
-- Hash dưới đây đã verify chạy đúng với bcrypt (node module: bcrypt, not bcryptjs)
-- ============================================================
INSERT INTO users (full_name, email, phone, password_hash, role, status) VALUES
('Admin Hệ Thống', 'admin@electroshop.com', '0901234567',
 '$2b$10$X8PaFcSZ5hdEBDzarAkXp.K5Ydz5edxh85hL2amGcDaXPXkMLEXK.', 'admin', 'active'),
('Nguyễn Văn An', 'an@example.com', '0912345678',
 '$2b$10$YnfDrc1yTTgFf.xoHRvnq.gfUprYgwHH0QnWJ4J6mYmfs2u2K3Wd2', 'customer', 'active'),
('Trần Thị Bình', 'binh@example.com', '0923456789',
 '$2b$10$YnfDrc1yTTgFf.xoHRvnq.gfUprYgwHH0QnWJ4J6mYmfs2u2K3Wd2', 'customer', 'active');

-- ============================================================
-- ADDRESSES
-- Tên cột đúng: recipient_name, phone, address_line (KHÔNG dùng receiver_name/receiver_phone/detail)
-- ============================================================
INSERT INTO addresses (user_id, recipient_name, phone, province, district, ward, address_line, is_default) VALUES
(2, 'Nguyễn Văn An', '0912345678', 'TP. Hồ Chí Minh', 'Quận 1', 'Phường Bến Nghé', '123 Lê Lợi', 1),
(3, 'Trần Thị Bình', '0923456789', 'Hà Nội', 'Quận Cầu Giấy', 'Phường Dịch Vọng', '456 Cầu Giấy', 1);

-- ============================================================
-- CATEGORIES (8 danh mục điện tử)
-- ============================================================
INSERT INTO categories (name, slug, description, status, sort_order) VALUES
('Điện thoại & Phụ kiện', 'dien-thoai-phu-kien', 'Smartphone, case, sạc, cáp', 'active', 1),
('Laptop & Máy tính bảng', 'laptop-may-tinh-bang', 'Laptop, tablet, máy tính xách tay', 'active', 2),
('Âm thanh & Tai nghe', 'am-thanh-tai-nghe', 'Tai nghe, loa bluetooth, soundbar', 'active', 3),
('TV & Màn hình', 'tv-man-hinh', 'Smart TV, màn hình máy tính, máy chiếu', 'active', 4),
('Gaming & Console', 'gaming-console', 'Console, tay cầm, gaming gear, PC gaming', 'active', 5),
('Thiết bị đeo thông minh', 'thiet-bi-deo-thong-minh', 'Smartwatch, vòng tay thông minh', 'active', 6),
('Máy ảnh & Quay phim', 'may-anh-quay-phim', 'Máy ảnh mirrorless, DSLR, action cam', 'active', 7),
('Thiết bị mạng & Lưu trữ', 'thiet-bi-mang-luu-tru', 'Router, switch, ổ cứng, USB', 'active', 8);

-- ============================================================
-- PRODUCTS (10 sản phẩm điện tử — xem SPEC.md mục 10.4 để copy đầy đủ)
-- ============================================================
INSERT INTO products (category_id, name, slug, brand, sku, price, sale_price, stock_quantity, description, specifications, warranty_months, status)
VALUES
(1, 'Apple iPhone 15 Pro Max 256GB', 'apple-iphone-15-pro-max-256gb', 'Apple', 'SP001', 34990000, 32990000, 30,
 'Chip A17 Pro, màn hình Super Retina XDR 6.7", camera 48MP, Dynamic Island',
 '{"cpu":"A17 Pro","ram":"8GB","storage":"256GB","display":"6.7 OLED","camera":"48MP"}',
 12, 'active'),

(1, 'Samsung Galaxy S24 Ultra 512GB', 'samsung-galaxy-s24-ultra-512gb', 'Samsung', 'SP002', 31990000, NULL, 25,
 'Snapdragon 8 Gen 3, 6.8" Dynamic AMOLED, 200MP, S Pen',
 '{"cpu":"Snapdragon 8 Gen 3","ram":"12GB","storage":"512GB","camera":"200MP"}',
 12, 'active'),

(2, 'Apple MacBook Air 13 M2 8GB 256GB', 'apple-macbook-air-13-m2', 'Apple', 'SP003', 27990000, 25990000, 20,
 'Apple M2, 13.6" Liquid Retina, pin 18 giờ, không quạt',
 '{"cpu":"Apple M2","ram":"8GB","storage":"256GB SSD","battery":"18h"}',
 12, 'active'),

(2, 'ASUS ROG Strix G16 RTX 4060', 'asus-rog-strix-g16-rtx4060', 'ASUS', 'SP004', 32990000, 29990000, 15,
 'i7-13650HX, RTX 4060 8GB, 16GB DDR5, QHD 165Hz',
 '{"cpu":"i7-13650HX","gpu":"RTX 4060","ram":"16GB","display":"QHD 165Hz"}',
 24, 'active'),

(3, 'Sony WH-1000XM5 Wireless', 'sony-wh-1000xm5', 'Sony', 'SP005', 8490000, 7490000, 40,
 'ANC hàng đầu, 30h pin, LDAC hi-res, multipoint',
 '{"type":"Over-ear","anc":"Yes","battery":"30h","codec":"LDAC"}',
 12, 'active'),

(4, 'Samsung 55 QLED 4K QN90C', 'samsung-55-qled-4k-qn90c', 'Samsung', 'SP006', 22990000, 19990000, 10,
 'Neo QLED 4K, 144Hz, Gaming Hub, Dolby Atmos',
 '{"size":"55 inch","resolution":"4K","panel":"Neo QLED","refresh":"144Hz"}',
 24, 'active'),

(5, 'Sony PlayStation 5 Slim Disc', 'sony-ps5-slim-disc', 'Sony', 'SP007', 13990000, NULL, 12,
 'PS5 Slim, SSD 1TB, 120fps, ray tracing, DualSense',
 '{"storage":"1TB SSD","fps":"120","features":"Ray Tracing, DualSense"}',
 12, 'active'),

(6, 'Apple Watch Series 9 GPS 45mm', 'apple-watch-series-9-gps-45mm', 'Apple', 'SP008', 10990000, 9990000, 35,
 'Chip S9, Always-On display, SpO2, ECG, WatchOS 10',
 '{"chip":"S9","display":"45mm AMOLED","health":"SpO2 ECG","battery":"18h"}',
 12, 'active'),

(7, 'Sony Alpha A7 IV Mirrorless Body', 'sony-alpha-a7-iv-body', 'Sony', 'SP009', 65990000, 61990000, 5,
 'Full-frame 33MP, Eye AF, 4K 60fps, IBIS 5.5 stops',
 '{"sensor":"33MP Full-frame","video":"4K 60fps","stabilization":"5.5-stop IBIS"}',
 12, 'active'),

(8, 'TP-Link Deco XE75 WiFi 6E 2-pack', 'tp-link-deco-xe75-wifi6e-2pack', 'TP-Link', 'SP010', 5990000, 5490000, 20,
 'WiFi 6E Tri-band, 5400Mbps, phủ 557m², AI Mesh',
 '{"standard":"WiFi 6E","speed":"5400Mbps","coverage":"557m2"}',
 24, 'active');

-- ============================================================
-- PRODUCT IMAGES (placeholder — thay bằng URL thực sau khi upload)
-- ============================================================
INSERT INTO product_images (product_id, image_url, is_main, sort_order) VALUES
(1, '/uploads/iphone15promax.jpg', 1, 0),
(2, '/uploads/galaxys24ultra.jpg', 1, 0),
(3, '/uploads/macbookairm2.jpg', 1, 0),
(4, '/uploads/rogstrixg16.jpg', 1, 0),
(5, '/uploads/sonywh1000xm5.jpg', 1, 0),
(6, '/uploads/samsungtv55.jpg', 1, 0),
(7, '/uploads/ps5slim.jpg', 1, 0),
(8, '/uploads/applewatch9.jpg', 1, 0),
(9, '/uploads/sonya7iv.jpg', 1, 0),
(10, '/uploads/tplinkdeco.jpg', 1, 0);
```

---

## Bước 3 — Script tạo bcrypt hash

Tạo `database/generate-hash.js`:

```javascript
const bcrypt = require('bcrypt');

async function main() {
  const adminHash = await bcrypt.hash('Admin@123456', 10);
  const customerHash = await bcrypt.hash('Customer@123', 10);

  console.log('-- Thay PLACEHOLDER trong seed.sql bằng các hash sau:');
  console.log('ADMIN hash:   ', adminHash);
  console.log('CUSTOMER hash:', customerHash);
}

main();
```

Chạy: `node database/generate-hash.js` → copy hash vào seed.sql

---

## Bước 4 — Chạy migration

```bash
mysql -u root -p < database/schema.sql
mysql -u root -p electronics_shop < database/seed.sql
```

Hoặc import qua phpMyAdmin.

---

## Bước 5 — Verify kết nối

Thêm vào server.js (test nhanh):
```javascript
const [rows] = await pool.query('SELECT COUNT(*) as cnt FROM products');
console.log('Products in DB:', rows[0].cnt);
```

---

## Checklist xác nhận ✅

```
[ ] schema.sql chạy không lỗi, 12 bảng được tạo
[ ] seed.sql chạy không lỗi
[ ] SELECT COUNT(*) FROM users → 3 rows
[ ] SELECT COUNT(*) FROM products → 10 rows
[ ] SELECT COUNT(*) FROM categories → 8 rows
[ ] FK constraint hoạt động: thử INSERT cart_item với product_id không tồn tại → lỗi FK
[ ] UNIQUE constraint hoạt động: thử INSERT users với email trùng → lỗi UNIQUE
[ ] Pool kết nối từ Node.js: pool.query('SELECT 1') không throw
[ ] Password admin được hash (không phải plain text)
```

## Sau khi xong skill này

Chạy: `bash hooks/hook-10-qa.sh 02`
