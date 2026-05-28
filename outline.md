Outline báo cáo chính xác dựa trên **BaoCao_DATN_FINAL.docx**.

---

# ĐỒ ÁN TỐT NGHIỆP

# ỨNG DỤNG AI AGENT TRONG VIỆC XÂY DỰNG TRANG WEB BÁN ĐỒ ĐIỆN TỬ

---

## THÔNG TIN ĐỀ TÀI

* **Tên đề tài:** Ứng dụng AI Agent trong việc xây dựng trang web bán đồ điện tử
* **Lĩnh vực:** Thương mại điện tử, phát triển ứng dụng web
* **Công nghệ sử dụng:** Node.js, Express.js, EJS, MySQL, Bootstrap, JavaScript
* **Công cụ hỗ trợ phát triển:** AI Agent
* **Cơ sở dữ liệu:** MySQL
* **Đối tượng người dùng:** Khách vãng lai, khách hàng, quản trị viên
* **Sản phẩm kinh doanh:** Điện thoại, laptop, tablet, tai nghe, TV, gaming, máy ảnh, đồng hồ thông minh, phụ kiện điện tử

---

# MỤC LỤC

## PHẦN MỞ ĐẦU

1. Lý do chọn đề tài
2. Mục tiêu đề tài
3. Đối tượng và phạm vi nghiên cứu
4. Phương pháp thực hiện
5. Bố cục báo cáo

## CHƯƠNG 1: CƠ SỞ LÝ THUYẾT

1.1. Tổng quan về thương mại điện tử
  - 1.1.1. Khái niệm thương mại điện tử
  - 1.1.2. Đặc điểm của website thương mại điện tử
  - 1.1.3. Vai trò của thương mại điện tử
1.2. Đặc thù của website bán đồ điện tử
1.3. AI Agent trong phát triển phần mềm
  - 1.3.1. Khái niệm AI Agent
  - 1.3.2. Mô hình hợp tác BA – AI Agent
  - 1.3.3. Lợi ích và hạn chế khi dùng AI Agent
1.4. Công nghệ sử dụng
  - 1.4.1. Node.js
  - 1.4.2. Express.js
  - 1.4.3. EJS (Embedded JavaScript Templates)
  - 1.4.4. MySQL và mysql2
  - 1.4.5. Các thư viện hỗ trợ
1.5. Quy trình phát triển có hỗ trợ AI Agent
1.6. Mô hình kinh doanh thương mại điện tử
1.7. Khảo sát và so sánh hệ thống tương tự
1.8. Kiến trúc MVC và biến thể Controller-Service-Model
1.9. Bảo mật ứng dụng web – OWASP Top 10 liên quan
1.10. Transaction và tính toàn vẹn dữ liệu trong TMĐT

## CHƯƠNG 2: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

2.1. Yêu cầu hệ thống
  - 2.1.1. Yêu cầu chức năng
  - 2.1.2. Yêu cầu phi chức năng
2.2. Tác nhân hệ thống
2.3. Ma trận phân quyền
2.4. Use case tổng quát
2.5. Đặc tả use case chi tiết
  - 2.5.1. Use case Đăng ký
  - 2.5.2. Use case Đăng nhập
  - 2.5.3. Use case Đặt hàng
  - 2.5.4. Use case Quản lý giỏ hàng
  - 2.5.5. Use case Đánh giá sản phẩm
  - 2.5.6. Use case Gửi yêu cầu bảo hành
2.6. Thiết kế cơ sở dữ liệu
  - 2.6.1. Danh sách bảng
  - 2.6.2. Sơ đồ ERD
  - 2.6.3. Mô tả chi tiết bảng chính
2.7. State machine
  - 2.7.1. Trạng thái đơn hàng (order_status)
  - 2.7.2. Trạng thái thanh toán (payment_status)
  - 2.7.3. Trạng thái yêu cầu bảo hành
2.8. Kiến trúc hệ thống
2.9. Thiết kế bảo mật
2.10. Sequence diagram bổ sung
  - 2.10.1. Tìm kiếm và lọc sản phẩm
  - 2.10.2. Hủy đơn hàng
  - 2.10.3. Admin cập nhật trạng thái đơn hàng
2.11. Activity diagram bổ sung
  - 2.11.1. Luồng đặt hàng và thanh toán tổng thể
  - 2.11.2. Luồng xử lý đơn hàng phía Admin

## CHƯƠNG 3: CHƯƠNG TRÌNH DEMO

3.1. Môi trường triển khai
3.2. Cấu trúc thư mục dự án
3.3. Giao diện phía khách hàng
  - 3.3.1. Trang chủ
  - 3.3.2. Trang danh sách và tìm kiếm sản phẩm
  - 3.3.3. Trang chi tiết sản phẩm
  - 3.3.4. Đăng ký và đăng nhập
  - 3.3.5. Giỏ hàng
  - 3.3.6. Trang checkout
  - 3.3.7. Thanh toán
  - 3.3.8. Lịch sử và chi tiết đơn hàng
  - 3.3.9. Đánh giá sản phẩm
  - 3.3.10. Gửi yêu cầu bảo hành
  - 3.3.11. Dữ liệu sản phẩm mẫu trong hệ thống
3.4. Giao diện trang quản trị (Admin)
  - 3.4.1. Đăng nhập admin
  - 3.4.2. Dashboard thống kê
  - 3.4.3. Quản lý sản phẩm
  - 3.4.4. Quản lý đơn hàng
  - 3.4.5. Quản lý người dùng
  - 3.4.6. Quản lý đánh giá và bảo hành
3.5. Các đoạn code nghiệp vụ quan trọng
  - 3.5.1. Middleware xác thực và phân quyền
  - 3.5.2. Transaction tạo đơn hàng
  - 3.5.3. Kiểm tra quyền đánh giá
  - 3.5.4. Kiểm tra transition trạng thái đơn hàng
3.6. Danh sách API Route
3.7. Hướng dẫn cài đặt và chạy hệ thống
  - 3.7.1. Yêu cầu phần mềm
  - 3.7.2. Các bước cài đặt cơ bản
  - 3.7.3. Chuẩn bị lại seed data từ crawler (nếu cần tái tạo)
  - 3.7.4. Cài đặt VNPay Sandbox với Ngrok
  - 3.7.5. Kiểm thử thanh toán VNPay Sandbox
  - 3.7.6. Triển khai bằng Docker

## CHƯƠNG 4: KIỂM THỬ VÀ ĐÁNH GIÁ

4.1. Mục tiêu và phương pháp kiểm thử
4.2. Kiểm thử chức năng
  - 4.2.1. Module xác thực
  - 4.2.2. Module sản phẩm
  - 4.2.3. Module giỏ hàng
  - 4.2.4. Module đặt hàng
  - 4.2.5. Module đánh giá và bảo hành
4.3. Kiểm thử bảo mật
4.4. Kiểm thử transaction và toàn vẹn dữ liệu
4.5. Kiểm thử giao diện và responsive
4.6. Kiểm thử quy trình AI Agent
4.7. Kết quả và đánh giá tổng thể
  - 4.7.1. Chức năng đã hoàn thành
  - 4.7.2. Acceptance Criteria theo SPEC.md

## KẾT LUẬN

* Hạn chế
* Hướng phát triển

## TÀI LIỆU THAM KHẢO

## PHỤ LỤC

* Phụ lục A – Cấu trúc cơ sở dữ liệu đầy đủ
* Phụ lục B – Bảng danh sách route đầy đủ
* Phụ lục C – Cấu hình .env.example
* Phụ lục D – Seed data tài khoản mặc định

---

# PHẦN MỞ ĐẦU

## 1. Lý do chọn đề tài

Thương mại điện tử ngày càng phát triển mạnh mẽ, nhu cầu mua sắm trực tuyến của người dùng không ngừng gia tăng, đặc biệt trong lĩnh vực đồ điện tử – nhóm sản phẩm có giá trị cao, nhiều thông số kỹ thuật, yêu cầu bảo hành rõ ràng và cần quy trình quản lý tồn kho chính xác.

Bên cạnh đó, sự phát triển của trí tuệ nhân tạo, đặc biệt là các công cụ **AI Agent hỗ trợ lập trình**, đã mở ra hướng tiếp cận mới trong quá trình xây dựng phần mềm. Người thực hiện có thể xây dựng đặc tả hệ thống rõ ràng, chia nhỏ thành từng nhiệm vụ và sử dụng AI Agent để hỗ trợ sinh mã, kiểm tra và hoàn thiện từng chức năng.

Từ những lý do trên, em lựa chọn đề tài **"Ứng dụng AI Agent trong việc xây dựng trang web bán đồ điện tử"** nhằm áp dụng kiến thức về lập trình web, cơ sở dữ liệu, phân tích thiết kế hệ thống và khai thác AI Agent trong quy trình phát triển phần mềm hiện đại.

---

## 2. Mục tiêu đề tài

Mục tiêu chính là xây dựng website thương mại điện tử bán đồ điện tử hoàn chỉnh, đáp ứng nhu cầu mua sắm trực tuyến của khách hàng và hỗ trợ quản trị viên quản lý hoạt động kinh doanh.

Các mục tiêu cụ thể:

* Xây dựng website bán đồ điện tử bằng **Node.js, Express.js, EJS và MySQL**.
* Xây dựng chức năng đăng ký, đăng nhập, đăng xuất và phân quyền người dùng.
* Cho phép khách hàng xem, tìm kiếm, lọc và xem chi tiết sản phẩm.
* Xây dựng chức năng giỏ hàng, đặt hàng và quản lý đơn hàng.
* Hỗ trợ thanh toán COD, chuyển khoản ngân hàng và VNPay sandbox.
* Cho phép khách hàng đánh giá sản phẩm sau khi mua hàng thành công.
* Cho phép khách hàng gửi yêu cầu bảo hành đối với sản phẩm đã mua.
* Xây dựng trang quản trị để admin quản lý sản phẩm, danh mục, đơn hàng, người dùng, đánh giá, bảo hành và thống kê doanh thu.
* Áp dụng các nguyên tắc bảo mật: bcrypt, prepared statements, phân quyền middleware, transaction.
* Sử dụng **AI Agent** để hỗ trợ phát triển hệ thống theo từng module, kết hợp hooks kiểm tra chất lượng mã nguồn.

---

## 3. Đối tượng và phạm vi nghiên cứu

### Đối tượng nghiên cứu

Website thương mại điện tử bán đồ điện tử, bao gồm các nghiệp vụ: quản lý sản phẩm, giỏ hàng, đặt hàng, thanh toán, đánh giá, bảo hành và quản trị hệ thống.

### Phạm vi chức năng

**Khách vãng lai:** Xem trang chủ, danh sách sản phẩm, tìm kiếm, lọc, xem chi tiết, đăng ký, đăng nhập.

**Khách hàng:** Quản lý thông tin cá nhân, địa chỉ giao hàng, giỏ hàng, đặt hàng, thanh toán, xem lịch sử đơn, hủy đơn, đánh giá sản phẩm, gửi bảo hành.

**Quản trị viên:** Đăng nhập trang quản trị, xem dashboard, quản lý danh mục, sản phẩm, tồn kho, đơn hàng, thanh toán, người dùng, đánh giá, bảo hành.

---

## 4. Phương pháp thực hiện

1. Khảo sát yêu cầu website TMĐT bán đồ điện tử.
2. Xây dựng đặc tả hệ thống chi tiết (SPEC.md).
3. Thiết kế kiến trúc tổng thể và cơ sở dữ liệu MySQL.
4. Chia nhỏ quá trình phát triển thành 13 skill/module.
5. Sử dụng AI Agent hỗ trợ xây dựng từng module theo đúng thứ tự.
6. Kiểm tra trước và sau mỗi module bằng hook validation.
7. Kiểm thử chức năng, bảo mật, giao diện và chỉnh sửa lỗi.
8. Hoàn thiện và viết báo cáo.

---

## 5. Bố cục báo cáo

* **Chương 1:** Cơ sở lý thuyết – tổng quan TMĐT, AI Agent, công nghệ, quy trình phát triển.
* **Chương 2:** Phân tích và thiết kế hệ thống – yêu cầu, use case, CSDL, kiến trúc, bảo mật.
* **Chương 3:** Chương trình demo – giao diện, code nghiệp vụ, API route, hướng dẫn cài đặt.
* **Chương 4:** Kiểm thử và đánh giá – kiểm thử chức năng, bảo mật, transaction, giao diện, AI Agent.

---

# CHƯƠNG 1: CƠ SỞ LÝ THUYẾT

## 1.1. Tổng quan về thương mại điện tử

### 1.1.1. Khái niệm thương mại điện tử

Thương mại điện tử là hình thức thực hiện các hoạt động mua bán hàng hóa, dịch vụ thông qua môi trường internet. Người bán đăng tải thông tin sản phẩm, quản lý đơn hàng và tiếp cận khách hàng trực tuyến; người mua tìm kiếm, lựa chọn, đặt hàng và thanh toán mà không cần đến cửa hàng trực tiếp.

### 1.1.2. Đặc điểm của website thương mại điện tử

* Hiển thị danh sách, phân loại và tìm kiếm sản phẩm.
* Trang chi tiết sản phẩm với ảnh, giá, thông số, mô tả.
* Chức năng giỏ hàng, đặt hàng và thanh toán.
* Quản lý tài khoản người dùng và theo dõi trạng thái đơn hàng.
* Hệ thống quản trị dành cho admin.
* Đánh giá, nhận xét và chăm sóc sau bán hàng.

### 1.1.3. Vai trò của thương mại điện tử

Giúp doanh nghiệp mở rộng kênh bán hàng, giảm chi phí vận hành, tiếp cận khách hàng nhanh hơn. Đối với khách hàng: mua sắm mọi lúc mọi nơi, so sánh giá cả và tham khảo đánh giá trước khi mua.

---

## 1.2. Đặc thù của website bán đồ điện tử

* Sản phẩm có giá trị cao, nhiều thông số kỹ thuật.
* Người dùng quan tâm nhiều đến thương hiệu.
* Cần quản lý tồn kho chính xác, tránh bán vượt kho.
* Cần hiển thị rõ chính sách bảo hành.
* Cần đánh giá sản phẩm để tăng độ tin cậy.
* Cần nhiều phương thức thanh toán.
* Cần quy trình xử lý đơn hàng và bảo hành chặt chẽ.

**Nhóm sản phẩm:** Điện thoại, Laptop, Tablet, Tai nghe, TV, Gaming, Máy ảnh, Đồng hồ thông minh, Phụ kiện điện tử.

**Thương hiệu:** Apple, Samsung, Sony, ASUS, Dell, LG, TP-Link, Xiaomi, JBL, Canon.

---

## 1.3. AI Agent trong phát triển phần mềm

### 1.3.1. Khái niệm AI Agent

AI Agent là hệ thống trí tuệ nhân tạo có khả năng nhận input, lý luận và thực hiện hành động để đạt mục tiêu. Trong phát triển phần mềm, AI Agent (như Claude Code) đóng vai trò trợ lý lập trình: hiểu đặc tả, sinh mã nguồn, kiểm tra lỗi và hoàn thiện chức năng theo yêu cầu.

### 1.3.2. Mô hình hợp tác BA – AI Agent

| Vai trò | Trách nhiệm |
| ------- | ----------- |
| BA (người thực hiện) | Xác định yêu cầu, thiết kế domain, xây dựng spec, quy định công nghệ, kiểm tra kết quả |
| AI Agent | Sinh mã, xây dựng route/controller/service/model/view, triển khai logic nghiệp vụ |

Nguyên tắc: AI Agent không tự ý phát triển ngoài phạm vi spec. Người thực hiện phải kiểm tra, chỉnh sửa và đảm bảo logic nghiệp vụ.

### 1.3.3. Lợi ích và hạn chế khi dùng AI Agent

**Lợi ích:**
* Tăng tốc triển khai, giảm thời gian viết mã lặp lại.
* Hỗ trợ sinh mã chuẩn cấu trúc, ít lỗi cú pháp.
* Dễ dàng triển khai theo spec chi tiết.

**Hạn chế:**
* Cần spec rõ ràng, nếu spec mơ hồ AI Agent có thể sinh sai.
* Vẫn cần người thực hiện kiểm tra logic nghiệp vụ.
* AI Agent có thể không nắm bắt được yêu cầu nghiệp vụ phức tạp nếu không được mô tả đủ chi tiết.

---

## 1.4. Công nghệ sử dụng

### 1.4.1. Node.js

Môi trường chạy JavaScript phía máy chủ, xử lý nhiều yêu cầu đồng thời. Vai trò: xử lý request, kết nối MySQL, xử lý nghiệp vụ, quản lý session, phục vụ trang EJS.

### 1.4.2. Express.js

Framework web phổ biến của Node.js. Vai trò: định nghĩa route, xử lý request/response, tổ chức controller, tích hợp middleware xác thực và phân quyền, xử lý lỗi tập trung.

### 1.4.3. EJS (Embedded JavaScript Templates)

Template engine cho Node.js, nhúng dữ liệu động vào HTML. Dùng để xây dựng layout chung, header/footer/navbar, tất cả các trang giao diện.

### 1.4.4. MySQL và mysql2

MySQL là RDBMS lưu trữ toàn bộ dữ liệu hệ thống. `mysql2` là thư viện Node.js kết nối MySQL, hỗ trợ prepared statements và connection pool.

### 1.4.5. Các thư viện hỗ trợ

| Thư viện | Vai trò |
| -------- | ------- |
| `mysql2` | Kết nối và truy vấn MySQL |
| `express-session` | Quản lý phiên đăng nhập |
| `bcrypt` | Mã hóa và kiểm tra mật khẩu |
| `multer` | Upload ảnh sản phẩm |
| `dotenv` | Quản lý biến môi trường |
| `Bootstrap 5` | Xây dựng giao diện responsive |
| `Vanilla JavaScript` | Xử lý tương tác phía client |

---

## 1.5. Quy trình phát triển có hỗ trợ AI Agent

Hệ thống được chia thành 13 skill theo thứ tự build bắt buộc:

| Bước | Nội dung |
| ---- | -------- |
| Chuẩn bị | Crawl dữ liệu sản phẩm thực tế từ cellphones.com.vn bằng `crawler.py` → sinh `products_raw.json` → convert sang seed data |
| 00 | Cài đặt package, tạo thư mục, cấu hình `.env`, MySQL |
| 01 | Thiết lập project, layout EJS, cấu trúc thư mục |
| 02 | Thiết kế database schema và seed data |
| 03 | Auth: register, login, logout, session, middleware |
| 04 | Product listing, search, filter, detail |
| 05 | Cart: add, update, remove, stock validation |
| 06 | Checkout, create order, history, cancel |
| 07 | COD, bank transfer, VNPay sandbox |
| 08 | Reviews, permission check, rating average |
| 09 | Warranty request và admin processing |
| 10 | Admin dashboard, CRUD product, order management |
| 11 | UI/UX consistency, responsive, empty states |
| 12 | Route audit, missing endpoints, final wiring |

Quy trình tổng quát mỗi skill:
```
Đọc SPEC.md → Đọc skill tương ứng → Chạy prebuild hook
→ AI Agent triển khai code → Người thực hiện kiểm tra
→ Chạy QA hook → Sửa lỗi → Chuyển sang skill tiếp theo
```

---

## 1.6. Mô hình kinh doanh thương mại điện tử

So sánh các mô hình B2C, B2B, C2C và marketplace. Hệ thống trong đề tài theo mô hình **B2C** (Business to Consumer): doanh nghiệp bán trực tiếp cho người tiêu dùng cuối.

---

## 1.7. Khảo sát và so sánh hệ thống tương tự

Khảo sát các website bán đồ điện tử hiện có (Thế Giới Di Động, FPT Shop, CellphoneS). So sánh chức năng để xác định phạm vi xây dựng phù hợp cho đề tài.

---

## 1.8. Kiến trúc MVC và biến thể Controller-Service-Model

Hệ thống sử dụng kiến trúc **Controller-Service-Model** (biến thể của MVC):

```text
Routes → Controllers → Services → Models → MySQL
                                          ↑
                           Views (EJS) ←─┘
```

| Thành phần | Vai trò |
| ---------- | ------- |
| Routes | Định nghĩa URL và HTTP method |
| Controllers | Nhận request, gọi service, trả response |
| Services | Xử lý nghiệp vụ chính |
| Models | Truy vấn cơ sở dữ liệu |
| Views | Giao diện EJS |

---

## 1.9. Bảo mật ứng dụng web – OWASP Top 10 liên quan

Các rủi ro OWASP Top 10 được xử lý trong hệ thống:

* **SQL Injection:** Dùng prepared statements, không nối chuỗi SQL trực tiếp.
* **Broken Authentication:** bcrypt hash mật khẩu, session secure.
* **Broken Access Control:** Middleware `requireAuth`, `requireAdmin`, user chỉ xem resource của mình.
* **Security Misconfiguration:** `.env` cho biến môi trường, không hardcode credentials.
* **XSS:** EJS escape mặc định, không render HTML từ input user.

---

## 1.10. Transaction và tính toàn vẹn dữ liệu trong TMĐT

Transaction được dùng cho các nghiệp vụ quan trọng:

* **Tạo đơn hàng:** INSERT orders + order_items + payments + xóa cart_items trong một transaction.
* **Hủy đơn hàng:** UPDATE order status + hoàn kho trong một transaction.
* `stock_quantity` không bao giờ âm.
* `payment_status = paid` chỉ set sau khi verify callback/gateway hợp lệ.

---

# CHƯƠNG 2: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

## 2.1. Yêu cầu hệ thống

### 2.1.1. Yêu cầu chức năng

**Khách vãng lai (Guest):**

| STT | Chức năng | Mô tả |
| --- | --------- | ----- |
| 1 | Xem trang chủ | Hiển thị banner, danh mục và sản phẩm nổi bật |
| 2 | Xem danh sách sản phẩm | Hiển thị sản phẩm theo phân trang |
| 3 | Tìm kiếm sản phẩm | Tìm sản phẩm theo từ khóa |
| 4 | Lọc sản phẩm | Lọc theo danh mục, thương hiệu, giá, đánh giá |
| 5 | Xem chi tiết sản phẩm | Xem ảnh, giá, thông số, mô tả, đánh giá |
| 6 | Đăng ký | Tạo tài khoản khách hàng |
| 7 | Đăng nhập | Truy cập hệ thống bằng tài khoản đã có |

**Khách hàng (Customer):**

| STT | Chức năng | Mô tả |
| --- | --------- | ----- |
| 1 | Quản lý thông tin cá nhân | Xem và cập nhật hồ sơ |
| 2 | Quản lý địa chỉ | Thêm, sửa, xóa địa chỉ giao hàng |
| 3 | Thêm vào giỏ hàng | Thêm sản phẩm với số lượng mong muốn |
| 4 | Cập nhật giỏ hàng | Thay đổi số lượng hoặc xóa sản phẩm |
| 5 | Đặt hàng | Tạo đơn hàng từ giỏ hàng |
| 6 | Thanh toán | Chọn COD, chuyển khoản hoặc VNPay |
| 7 | Xem đơn hàng | Xem lịch sử và chi tiết đơn hàng |
| 8 | Hủy đơn | Hủy đơn nếu trạng thái cho phép |
| 9 | Đánh giá sản phẩm | Đánh giá sau khi đơn hoàn thành |
| 10 | Gửi bảo hành | Gửi yêu cầu bảo hành sản phẩm |

**Quản trị viên (Admin):**

| STT | Chức năng | Mô tả |
| --- | --------- | ----- |
| 1 | Dashboard | Xem thống kê doanh thu, đơn hàng, tồn kho |
| 2 | Quản lý danh mục | Thêm, sửa, xóa danh mục |
| 3 | Quản lý sản phẩm | Thêm, sửa, xóa, ẩn sản phẩm |
| 4 | Quản lý ảnh sản phẩm | Upload và cập nhật ảnh |
| 5 | Quản lý tồn kho | Cập nhật số lượng sản phẩm |
| 6 | Quản lý đơn hàng | Xem, lọc, cập nhật trạng thái đơn |
| 7 | Xác nhận thanh toán | Xác nhận COD hoặc chuyển khoản |
| 8 | Quản lý người dùng | Khóa hoặc mở khóa tài khoản |
| 9 | Quản lý đánh giá | Ẩn hoặc hiện đánh giá |
| 10 | Quản lý bảo hành | Xử lý yêu cầu bảo hành |

### 2.1.2. Yêu cầu phi chức năng

* **Hiệu năng:** Phân trang danh sách sản phẩm, index cho trường thường truy vấn (`category_id`, `status`, `brand`, `slug`).
* **Bảo mật:** bcrypt, prepared statements, `requireAdmin` middleware, user chỉ xem resource của mình.
* **Toàn vẹn dữ liệu:** `stock_quantity >= 0`, transaction tạo/hủy đơn, `paid` chỉ set sau verify.
* **Khả năng mở rộng:** Cấu trúc module routes/controllers/services/models/views, dễ thêm voucher, chatbot, vận chuyển.

---

## 2.2. Tác nhân hệ thống

| Tác nhân | Mô tả |
| -------- | ----- |
| Guest | Người dùng chưa đăng nhập |
| Customer | Người dùng đã đăng nhập với vai trò khách hàng |
| Admin | Người quản trị hệ thống |

---

## 2.3. Ma trận phân quyền

| Chức năng | Guest | Customer | Admin |
| --------- | :---: | :------: | :---: |
| Xem trang chủ/sản phẩm | Có | Có | Có |
| Tìm kiếm/lọc sản phẩm | Có | Có | Có |
| Đăng ký | Có | Không | Không |
| Đăng nhập | Có | Có | Có |
| Quản lý hồ sơ | Không | Có | Có |
| Quản lý giỏ hàng | Không | Có | Không |
| Đặt hàng/thanh toán | Không | Có | Không |
| Xem lịch sử đơn | Không | Có | Không |
| Đánh giá sản phẩm | Không | Có | Không |
| Gửi bảo hành | Không | Có | Không |
| Truy cập `/admin/*` | Không | Không | Có |
| Quản lý sản phẩm/đơn/user | Không | Không | Có |
| Xem thống kê | Không | Không | Có |

---

## 2.4. Use case tổng quát

**Guest:** Xem trang chủ, xem/tìm/lọc sản phẩm, xem chi tiết, đăng ký, đăng nhập.

**Customer:** Quản lý thông tin/địa chỉ, giỏ hàng, đặt hàng, thanh toán, xem lịch sử đơn, hủy đơn, đánh giá, gửi bảo hành.

**Admin:** Dashboard, quản lý danh mục/sản phẩm/đơn hàng/người dùng/đánh giá/bảo hành, xem thống kê.

---

## 2.5. Đặc tả use case chi tiết

### 2.5.1. Use case Đăng ký

* **Tác nhân:** Guest
* **Tiền điều kiện:** Người dùng chưa đăng nhập
* **Hậu điều kiện:** Tài khoản được tạo và lưu trong cơ sở dữ liệu

**Luồng chính:** Truy cập form đăng ký → nhập họ tên, email, SĐT, mật khẩu → hệ thống validate → kiểm tra email tồn tại → hash bcrypt → lưu vào bảng `users` → redirect sang trang đăng nhập.

**Ngoại lệ:** Email không hợp lệ, mật khẩu quá ngắn, xác nhận mật khẩu không khớp, email đã dùng.

### 2.5.2. Use case Đăng nhập

* **Tác nhân:** Guest, Customer, Admin
* **Tiền điều kiện:** Đã có tài khoản
* **Hậu điều kiện:** Session đăng nhập được tạo

**Luồng chính:** Nhập email/mật khẩu → kiểm tra email tồn tại → so sánh bcrypt → kiểm tra tài khoản không bị khóa → tạo session → admin redirect `/admin/dashboard`, customer redirect trang chủ.

**Ngoại lệ:** Sai email/mật khẩu, tài khoản bị khóa.

### 2.5.3. Use case Đặt hàng

* **Tác nhân:** Customer
* **Tiền điều kiện:** Đã đăng nhập, có sản phẩm trong giỏ
* **Hậu điều kiện:** Đơn hàng được tạo thành công

**Luồng chính:** Truy cập checkout → hiển thị giỏ hàng và địa chỉ → chọn địa chỉ và phương thức thanh toán → kiểm tra tồn kho lần cuối → BEGIN TRANSACTION → INSERT orders → INSERT order_items → INSERT payments → DELETE cart_items → COMMIT → redirect trang kết quả.

**Ngoại lệ:** Giỏ trống, hết hàng, vượt tồn kho, không có địa chỉ → ROLLBACK.

### 2.5.4. Use case Quản lý giỏ hàng

* **Tác nhân:** Customer
* **Tiền điều kiện:** Đã đăng nhập

**Thêm sản phẩm:** Chọn sản phẩm → nhập số lượng → kiểm tra trạng thái và tồn kho → lấy/tạo giỏ → INSERT cart_items.

**Cập nhật số lượng:** Kiểm tra item thuộc user hiện tại → kiểm tra không vượt tồn kho → UPDATE.

**Xóa sản phẩm:** Kiểm tra item thuộc giỏ của user → DELETE.

### 2.5.5. Use case Đánh giá sản phẩm

* **Tác nhân:** Customer
* **Điều kiện:** Đơn hàng `completed`, sản phẩm nằm trong đơn, chưa đánh giá sản phẩm đó trong đơn, rating 1–5.

**Luồng:** Truy cập chi tiết đơn → chọn sản phẩm → nhập sao và bình luận → INSERT reviews → UPDATE `avg_rating`, `review_count` trên bảng `products`.

### 2.5.6. Use case Gửi yêu cầu bảo hành

* **Tác nhân:** Customer
* **Điều kiện:** Sản phẩm thuộc đơn hoàn thành, còn trong thời hạn bảo hành.

**Luồng:** Truy cập chi tiết đơn → chọn sản phẩm → nhập mô tả lỗi → kiểm tra điều kiện → INSERT warranty_requests → thông báo thành công.

---

## 2.6. Thiết kế cơ sở dữ liệu

### 2.6.1. Danh sách bảng

| STT | Bảng | Mục đích |
| --- | ---- | -------- |
| 1 | `users` | Lưu tài khoản khách hàng và admin |
| 2 | `addresses` | Lưu địa chỉ giao hàng |
| 3 | `categories` | Lưu danh mục sản phẩm |
| 4 | `products` | Lưu thông tin sản phẩm |
| 5 | `product_images` | Lưu ảnh sản phẩm |
| 6 | `carts` | Lưu giỏ hàng của user |
| 7 | `cart_items` | Lưu chi tiết sản phẩm trong giỏ |
| 8 | `orders` | Lưu đơn hàng |
| 9 | `order_items` | Lưu chi tiết đơn hàng |
| 10 | `payments` | Lưu thông tin thanh toán |
| 11 | `reviews` | Lưu đánh giá sản phẩm |
| 12 | `warranty_requests` | Lưu yêu cầu bảo hành |

### 2.6.2. Sơ đồ ERD

ERD 12 bảng với quan hệ chính:
* `users` 1–N `addresses`, `carts`, `orders`, `reviews`, `warranty_requests`
* `categories` 1–N `products`
* `products` 1–N `product_images`, `cart_items`, `order_items`, `reviews`
* `carts` 1–N `cart_items`
* `orders` 1–N `order_items`, 1–1 `payments`

### 2.6.3. Mô tả chi tiết bảng chính

**Bảng `users`:** `id`, `full_name`, `email` (UNIQUE), `phone`, `password_hash`, `role` (customer/admin), `is_blocked`, `created_at`.

**Bảng `products`:** `id`, `category_id` (FK), `name`, `slug` (UNIQUE), `brand`, `price`, `stock_quantity`, `specifications` (JSON), `description`, `avg_rating`, `review_count`, `status` (active/inactive), `created_at`.

**Bảng `orders`:** `id`, `user_id` (FK), `address_id` (FK), `total_amount`, `shipping_fee`, `order_status` (pending/confirmed/processing/shipping/completed/cancelled), `payment_method`, `created_at`.

---

## 2.7. State machine

### 2.7.1. Trạng thái đơn hàng (order_status)

```text
pending → confirmed → processing → shipping → completed
pending → cancelled
confirmed → cancelled
```

| Trạng thái | Ý nghĩa |
| ---------- | ------- |
| `pending` | Đơn hàng mới được tạo |
| `confirmed` | Admin đã xác nhận đơn |
| `processing` | Đơn hàng đang được chuẩn bị |
| `shipping` | Đơn hàng đang giao |
| `completed` | Đơn hàng đã hoàn thành |
| `cancelled` | Đơn hàng đã bị hủy |

### 2.7.2. Trạng thái thanh toán (payment_status)

```text
unpaid → pending → paid
pending → failed
paid → refunded
```

| Trạng thái | Ý nghĩa |
| ---------- | ------- |
| `unpaid` | Chưa thanh toán |
| `pending` | Đang chờ thanh toán hoặc chờ xác nhận |
| `paid` | Đã thanh toán |
| `failed` | Thanh toán thất bại |
| `refunded` | Đã hoàn tiền |

Nguyên tắc: Không set `paid` từ phía client. COD/chuyển khoản: chỉ set `paid` khi admin xác nhận. VNPay: chỉ set `paid` khi verify secure hash hợp lệ.

### 2.7.3. Trạng thái yêu cầu bảo hành

```text
pending → approved → processing → completed
pending → rejected
```

---

## 2.8. Kiến trúc hệ thống

```text
Client Browser
     ↓
Express Routes
     ↓
Middlewares (requireAuth, requireAdmin, multer, error handler)
     ↓
Controllers
     ↓
Services
     ↓
Models
     ↓
MySQL Database
```

| Thành phần | Vai trò |
| ---------- | ------- |
| Routes | Định nghĩa URL và HTTP method |
| Middlewares | Kiểm tra đăng nhập, phân quyền, upload, lỗi |
| Controllers | Nhận request và trả response |
| Services | Xử lý nghiệp vụ chính |
| Models | Truy vấn cơ sở dữ liệu |
| Views | Hiển thị giao diện EJS |
| Utils | Hàm hỗ trợ: format tiền, slug, validate |

---

## 2.9. Thiết kế bảo mật

Ma trận bảo mật theo tầng kiến trúc:

| Tầng | Biện pháp bảo mật |
| ---- | ----------------- |
| Route | `requireAuth`, `requireAdmin` middleware |
| Controller | Kiểm tra ownership (user chỉ xem resource của mình) |
| Service | Prepared statements, whitelist sort fields |
| Model | Không nối chuỗi SQL trực tiếp |
| View | EJS escape mặc định, không render HTML từ input |
| Password | bcrypt hash, không lưu plain text |
| Payment | Verify secure hash trước khi set `paid` |

---

## 2.10. Sequence diagram bổ sung

### 2.10.1. Tìm kiếm và lọc sản phẩm

Client → Routes → ProductController → ProductService (build query động với prepared statements, whitelist sort) → MySQL → trả kết quả phân trang.

### 2.10.2. Hủy đơn hàng

Customer → OrderController → kiểm tra ownership → kiểm tra transition hợp lệ → BEGIN TRANSACTION → UPDATE order_status = cancelled → hoàn kho (UPDATE stock_quantity) → COMMIT.

### 2.10.3. Admin cập nhật trạng thái đơn hàng

Admin → AdminOrderController → kiểm tra `requireAdmin` → kiểm tra transition hợp lệ theo VALID_TRANSITIONS → UPDATE order_status → nếu cần xác nhận thanh toán thì UPDATE payment_status.

---

## 2.11. Activity diagram bổ sung

### 2.11.1. Luồng đặt hàng và thanh toán tổng thể

Bắt đầu → Đăng nhập → Thêm vào giỏ → Xem giỏ hàng → Checkout → Chọn địa chỉ → Chọn phương thức thanh toán → [COD/Chuyển khoản: tạo đơn → pending] / [VNPay: tạo URL → redirect VNPay → callback → verify → tạo đơn paid] → Kết thúc.

### 2.11.2. Luồng xử lý đơn hàng phía Admin

Đăng nhập admin → Xem danh sách đơn → Chọn đơn → Xem chi tiết → Cập nhật trạng thái (theo VALID_TRANSITIONS) → Xác nhận thanh toán nếu cần → Lưu thay đổi.

---

# CHƯƠNG 3: CHƯƠNG TRÌNH DEMO

## 3.1. Môi trường triển khai

| Thành phần | Công nghệ |
| ---------- | --------- |
| Runtime | Node.js 20+ |
| Framework | Express.js |
| Template engine | EJS |
| Database | MySQL 8.0 |
| DB Client | mysql2 |
| Session | express-session |
| Password hashing | bcrypt |
| Upload file | multer |
| Frontend | HTML, CSS, Bootstrap 5, Vanilla JS |
| Tunnel | ngrok (phát triển VNPay) |

---

## 3.2. Cấu trúc thư mục dự án

```text
project-root/
├── src/
│   ├── config/
│   ├── controllers/
│   ├── middlewares/
│   ├── models/
│   ├── routes/
│   ├── services/
│   ├── views/
│   └── utils/
├── public/
│   ├── css/
│   ├── js/
│   ├── images/
│   └── uploads/
├── database/
│   ├── schema.sql
│   └── seed.sql
├── crawler.py          # Scrapy spider crawl cellphones.com.vn → products_raw.json
├── products_raw.json   # Output crawler, dùng để tạo seed data
├── app.js
├── server.js
├── .env
├── .env.example
└── package.json
```

---

## 3.3. Giao diện phía khách hàng

### 3.3.1. Trang chủ

Banner hero, danh mục sản phẩm, sản phẩm nổi bật. Responsive Bootstrap 5.

### 3.3.2. Trang danh sách và tìm kiếm sản phẩm

Lọc theo danh mục, thương hiệu, khoảng giá, rating. Sắp xếp theo giá/mới nhất/đánh giá. Phân trang.

### 3.3.3. Trang chi tiết sản phẩm

Gallery ảnh, thông số kỹ thuật (JSON), mô tả, đánh giá. Thông số kỹ thuật lưu dạng JSON trong cột `specifications`.

### 3.3.4. Đăng ký và đăng nhập

Form đăng ký (họ tên, email, SĐT, mật khẩu). Form đăng nhập. Validate phía server.

### 3.3.5. Giỏ hàng

Danh sách sản phẩm trong giỏ, cập nhật số lượng AJAX, xóa sản phẩm event delegation. Tính subtotal + phí vận chuyển (miễn phí >= 2tr, phí 50k < 2tr). Empty state khi giỏ trống.

### 3.3.6. Trang checkout

Hiển thị sản phẩm, chọn địa chỉ giao hàng, chọn phương thức thanh toán, tổng thanh toán.

### 3.3.7. Thanh toán

* **COD:** Tạo đơn ngay, `payment_status = unpaid`.
* **Chuyển khoản ngân hàng:** Hiển thị thông tin tài khoản (MB Bank/DO HUY DAT/0417934401), mã QR.
* **VNPay Sandbox:** Redirect sang cổng VNPay, callback về hệ thống, verify secure hash.

### 3.3.8. Lịch sử và chi tiết đơn hàng

Danh sách đơn hàng theo thời gian, filter theo trạng thái. Chi tiết đơn: sản phẩm, trạng thái, thanh toán, nút hủy nếu cho phép.

### 3.3.9. Đánh giá sản phẩm

Form 1–5 sao + bình luận. Hiển thị đánh giá trên trang chi tiết sản phẩm.

### 3.3.10. Gửi yêu cầu bảo hành

Form mô tả lỗi từ trang chi tiết đơn hàng. Kiểm tra sản phẩm còn trong thời gian bảo hành.

### 3.3.11. Dữ liệu sản phẩm mẫu trong hệ thống

Seed data được chuẩn bị qua hai nguồn, tổng cộng **121 sản phẩm** thuộc 10 danh mục:

#### Nguồn 1 — Seed thủ công (`database/seed.sql`)

56 sản phẩm được nhập tay đại diện đa dạng danh mục: Máy lạnh, Máy giặt, Tivi, Điện thoại, Laptop, Tablet, Tủ lạnh, Nồi cơm điện, Nồi chiên không dầu, Bếp điện. Các thương hiệu: Samsung, LG, Sharp, Toshiba, Apple, ASUS, Lenovo, HP. Mỗi sản phẩm kèm 3–5 ảnh local (`/img/products/PXX/`), description HTML, specifications JSON và thông tin bảo hành.

#### Nguồn 2 — Crawl tự động (`crawler.py` + `import_crawled.py`)

65 sản phẩm thực tế crawl từ **cellphones.com.vn** bổ sung vào danh mục **Điện thoại** (37 sản phẩm) và **Laptop** (28 sản phẩm).

**Quy trình crawl:**

| Bước | Công việc | Công cụ |
| ---- | --------- | ------- |
| 1 | Crawl danh mục mobile, laptop từ cellphones.com.vn (tối đa 5 trang/danh mục) | Scrapy |
| 2 | Lấy đầy đủ thông tin từng trang chi tiết sản phẩm | XPath/CSS selector |
| 3 | Sinh `products_raw.json` — 65 bản ghi | Scrapy FEEDS |
| 4 | Đọc JSON, fix category_id, escape SQL, INSERT vào DB | `import_crawled.py` |
| 5 | Append INSERT block vào `database/seed.sql` | Python |

**Dữ liệu thu thập được cho mỗi sản phẩm:**

| Trường | Nguồn trên trang | Ghi chú |
| ------ | --------------- | ------- |
| `name` | `div.box-product-name > h1` | |
| `price` | `.base-price` | Giá gốc |
| `sale_price` | `.sale-price` | Giá khuyến mãi (nếu có) |
| `brand` | Trích xuất từ tên + alias table | iPhone→Apple, Redmi→Xiaomi |
| `description` | `div#cpsContentSEO` | Giữ nguyên HTML |
| `specifications` | `tr.technical-content-item` | Lưu dạng JSON string |
| `warranty_months` | Regex "N tháng/năm" trong trang | Mặc định 12 nếu không tìm thấy |
| `images` | CDN URL từ pattern `plain/` | Tối đa 5 ảnh/sản phẩm, 307 ảnh tổng |
| `slug` | `slugify(name)` — xử lý tiếng Việt | |

**Lưu ý kỹ thuật:** Cột `description` phải là `MEDIUMTEXT` (một số description HTML vượt 65.535 bytes, ví dụ iPhone 17 Pro: 83.910 bytes). Schema đã được cập nhật tương ứng.

---

## 3.4. Giao diện trang quản trị (Admin)

### 3.4.1. Đăng nhập admin

Form đăng nhập riêng cho admin. Middleware `requireAdmin` bảo vệ toàn bộ `/admin/*`.

### 3.4.2. Dashboard thống kê

Tổng doanh thu, doanh thu theo tháng (biểu đồ), số đơn theo trạng thái, sản phẩm bán chạy, sản phẩm sắp hết hàng.

### 3.4.3. Quản lý sản phẩm

Danh sách sản phẩm với phân trang. Form thêm/sửa sản phẩm (tên, danh mục, thương hiệu, giá, tồn kho, thông số JSON, mô tả). Upload ảnh multer. Ẩn/hiện sản phẩm.

### 3.4.4. Quản lý đơn hàng

Danh sách đơn, lọc theo trạng thái, tìm theo mã. Chi tiết đơn và cập nhật trạng thái theo VALID_TRANSITIONS. Xác nhận thanh toán COD/chuyển khoản.

### 3.4.5. Quản lý người dùng

Danh sách người dùng, khóa/mở khóa tài khoản.

### 3.4.6. Quản lý đánh giá và bảo hành

Danh sách đánh giá, ẩn/hiện review. Danh sách yêu cầu bảo hành, cập nhật trạng thái xử lý, ghi chú kết quả.

---

## 3.5. Các đoạn code nghiệp vụ quan trọng

### 3.5.1. Middleware xác thực và phân quyền

```javascript
// requireAuth
function requireAuth(req, res, next) {
  if (!req.session.user) return res.redirect('/auth/login');
  next();
}
// requireAdmin
function requireAdmin(req, res, next) {
  if (!req.session.user || req.session.user.role !== 'admin')
    return res.status(403).render('error', { message: 'Forbidden' });
  next();
}
```

### 3.5.2. Transaction tạo đơn hàng

```javascript
const conn = await pool.getConnection();
await conn.beginTransaction();
try {
  const [orderResult] = await conn.execute('INSERT INTO orders ...', [...]);
  const orderId = orderResult.insertId;
  for (const item of cartItems) {
    await conn.execute('INSERT INTO order_items ...', [...]);
  }
  await conn.execute('INSERT INTO payments ...', [...]);
  await conn.execute('DELETE FROM cart_items WHERE cart_id = ?', [cartId]);
  await conn.commit();
} catch (err) {
  await conn.rollback();
  throw err;
} finally {
  conn.release();
}
```

### 3.5.3. Kiểm tra quyền đánh giá

Điều kiện: đơn hàng `completed`, thuộc về user, sản phẩm nằm trong đơn, chưa có review trong đơn đó.

### 3.5.4. Kiểm tra transition trạng thái đơn hàng

```javascript
const VALID_TRANSITIONS = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['processing', 'cancelled'],
  processing: ['shipping'],
  shipping: ['completed'],
};
```

---

## 3.6. Danh sách API Route

| Method | Path | Mô tả |
| ------ | ---- | ----- |
| GET | `/` | Trang chủ |
| GET | `/products` | Danh sách sản phẩm |
| GET | `/products/:slug` | Chi tiết sản phẩm |
| GET | `/auth/register` | Form đăng ký |
| POST | `/auth/register` | Xử lý đăng ký |
| GET | `/auth/login` | Form đăng nhập |
| POST | `/auth/login` | Xử lý đăng nhập |
| POST | `/auth/logout` | Đăng xuất |
| GET | `/cart` | Xem giỏ hàng |
| POST | `/cart/items` | Thêm vào giỏ |
| PUT | `/cart/items/:id` | Cập nhật số lượng |
| DELETE | `/cart/items/:id` | Xóa khỏi giỏ |
| GET | `/checkout` | Trang checkout |
| POST | `/orders` | Tạo đơn hàng |
| GET | `/orders` | Lịch sử đơn |
| GET | `/orders/:id` | Chi tiết đơn |
| POST | `/orders/:id/cancel` | Hủy đơn |
| GET | `/payment/vnpay` | Tạo URL VNPay |
| GET | `/payment/vnpay/return` | Callback VNPay |
| POST | `/reviews` | Tạo đánh giá |
| POST | `/warranty` | Gửi yêu cầu bảo hành |
| GET/POST | `/admin/*` | Tất cả route quản trị |

---

## 3.7. Hướng dẫn cài đặt và chạy hệ thống

### 3.7.1. Yêu cầu phần mềm

| Phần mềm | Phiên bản |
| -------- | --------- |
| Node.js | >= 18 |
| MySQL | >= 8.0 |
| npm | >= 9 |

### 3.7.2. Các bước cài đặt cơ bản

```bash
git clone <repo-url>
cd project
npm install
# Tạo file .env từ .env.example, điền thông tin DB
mysql -u root -p < database/schema.sql
mysql -u root -p < database/seed.sql
npm start
```

`database/seed.sql` đã bao gồm toàn bộ 121 sản phẩm (seed thủ công + crawled). Không cần chạy thêm bước nào.

Tài khoản mặc định sau seed:
* Admin: `admin@electroshop.com` / `Admin@123456`
* Customer: `an@example.com` / `Customer@123`

### 3.7.3. Chuẩn bị lại seed data từ crawler (nếu cần tái tạo)

Trong trường hợp cần crawl lại dữ liệu mới từ cellphones.com.vn (ví dụ sản phẩm đã thay đổi giá, thêm sản phẩm mới), thực hiện theo các bước sau:

**Bước 1 — Chạy crawler:**

```bash
pip install scrapy        # Cài Scrapy nếu chưa có
python3 crawler.py        # Crawl → sinh products_raw.json
```

`crawler.py` crawl hai danh mục điện thoại và laptop từ cellphones.com.vn, tối đa 5 trang/danh mục, `DOWNLOAD_DELAY=1s` để tránh bị chặn. Output: `products_raw.json`.

**Bước 2 — Import vào DB và cập nhật seed:**

```bash
python3 import_crawled.py
```

Script thực hiện:
1. Đọc `products_raw.json`
2. Map category: mobile → `category_id=4` (Điện thoại), laptop → `category_id=5` (Laptop)
3. Kiểm tra slug trùng với sản phẩm hiện có, tự thêm suffix nếu conflict
4. Sinh câu lệnh `INSERT INTO products` và `INSERT INTO product_images` với escaped SQL đúng chuẩn
5. Chạy INSERT trực tiếp vào DB đang kết nối
6. Append block SQL vào `database/seed.sql` để các máy khác pull về có đủ dữ liệu

**Cấu hình kết nối trong `import_crawled.py`:**

```python
DB_USER = 'admin123'
DB_PASS = 'admin123'
DB_NAME = 'electronics_shop'
PORT    = '3306'    # Đổi thành '3307' nếu dùng Docker
```

**Lưu ý schema:** Cột `description` trong bảng `products` phải là `MEDIUMTEXT` (không phải `TEXT`) vì một số description HTML từ cellphones.com.vn có kích thước vượt 65.535 bytes. Schema đã được cập nhật. Nếu chạy trên DB cũ chưa migrate:

```sql
ALTER TABLE products MODIFY COLUMN description MEDIUMTEXT;
```

**Kết quả sau khi chạy xong:**

| Hạng mục | Số lượng |
| -------- | -------- |
| Tổng sản phẩm trong DB | 121 |
| Seed thủ công (10 danh mục) | 56 |
| Crawled từ cellphones.com.vn | 65 |
| Ảnh sản phẩm crawled | 307 |
| Danh mục Điện thoại (cat 4) | 42 sản phẩm |
| Danh mục Laptop (cat 5) | 33 sản phẩm |

### 3.7.3. Cài đặt VNPay Sandbox với Ngrok

```bash
ngrok http 3000
# Copy URL https://xxxx.ngrok.io
# Điền vào .env: VNPAY_RETURN_URL và VNPAY_IPN_URL
```

Ngrok tạo đường hầm HTTPS từ internet → localhost:3000 để VNPay callback hoạt động trong môi trường phát triển.

### 3.7.4. Kiểm thử thanh toán VNPay Sandbox

Thông tin thẻ test:
* Ngân hàng: NCB
* Số thẻ: `9704198526191432198`
* Tên chủ thẻ: `NGUYEN VAN A`
* Ngày hết hạn: `07/15`
* Mã OTP: `123456`

### 3.7.5. Triển khai bằng Docker

Ba file docker-compose phục vụ ba kịch bản:

```bash
# Development (build từ source)
docker compose up -d --build

# Production (pull image từ Docker Hub)
docker compose -f docker-compose.prod.yml up -d

# One-command deploy (image pre-seeded)
docker compose -f docker-compose.pull.yml up -d
```

**One-command deploy (không cần source code):**
```bash
bash setup.sh
# Sau 30–60 giây terminal hiển thị URL ngrok
```

Ba service: `db` (MySQL 8.0, port 3307), `app` (Node.js port 3000), `ngrok` (HTTPS tunnel). Ảnh sản phẩm lưu trong Docker named volume `img_data`.

---

# CHƯƠNG 4: KIỂM THỬ VÀ ĐÁNH GIÁ

## 4.1. Mục tiêu và phương pháp kiểm thử

**Mục tiêu:** Đảm bảo website hoạt động đúng yêu cầu, dữ liệu xử lý chính xác, phân quyền đúng, các nghiệp vụ quan trọng (đặt hàng, thanh toán, tồn kho, đánh giá, bảo hành) không gây sai lệch dữ liệu.

**Phương pháp:** Kiểm thử thủ công theo từng module, kiểm thử bảo mật bằng cách inject dữ liệu bất thường, kiểm thử giao diện trên nhiều kích thước màn hình.

---

## 4.2. Kiểm thử chức năng

### 4.2.1. Module xác thực

| Test case | Kết quả |
| --------- | ------- |
| Đăng ký email hợp lệ | Đạt |
| Đăng ký email đã tồn tại | Đạt |
| Đăng nhập sai mật khẩu | Đạt |
| Tài khoản bị khóa | Đạt |
| Admin redirect `/admin/dashboard` | Đạt |

### 4.2.2. Module sản phẩm

Tìm kiếm theo từ khóa, lọc theo danh mục/thương hiệu/giá/rating, phân trang, xem chi tiết. Tất cả đạt.

### 4.2.3. Module giỏ hàng

Thêm sản phẩm hợp lệ, thêm vượt tồn kho (từ chối), cập nhật số lượng, xóa sản phẩm. Tất cả đạt.

### 4.2.4. Module đặt hàng

Tạo đơn hợp lệ, rollback khi lỗi giữa chừng, hủy đơn pending/confirmed, hủy đơn processing (từ chối). Tất cả đạt.

### 4.2.5. Module đánh giá và bảo hành

Đánh giá sau đơn completed, từ chối đánh giá đơn chưa completed, gửi bảo hành hợp lệ, admin xử lý bảo hành. Tất cả đạt.

---

## 4.3. Kiểm thử bảo mật

| Nội dung | Cách kiểm thử | Kết quả |
| -------- | ------------- | ------- |
| Mật khẩu | Kiểm tra bảng `users` | Hash bcrypt, không plain text |
| SQL Injection | Nhập `' OR 1=1 --` vào form | Prepared statements, không lỗi |
| Phân quyền admin | Customer truy cập `/admin` | Bị chặn 403 |
| User ownership | User A xem đơn User B | Không được phép |
| XSS | Nhập `<script>` vào comment | EJS escape, không thực thi |
| Upload ảnh | Upload file .exe | Multer từ chối |
| Payment callback | Giả lập hash sai | Không cập nhật `paid` |

---

## 4.4. Kiểm thử transaction và toàn vẹn dữ liệu

| STT | Trường hợp | Kết quả |
| --- | ---------- | ------- |
| 1 | Tạo đơn thành công | orders + order_items + payments được tạo, cart_items xóa |
| 2 | Tạo đơn lỗi giữa chừng | Rollback toàn bộ |
| 3 | Đặt số lượng vượt tồn kho | Không cho đặt |
| 4 | Hủy đơn đã xác nhận | Hoàn lại tồn kho |
| 5 | `stock_quantity` | Không âm |

---

## 4.5. Kiểm thử giao diện và responsive

| Màn hình | Kết quả |
| -------- | ------- |
| Desktop 1920px | Đạt |
| Laptop 1366px | Đạt |
| Tablet 768px | Đạt |
| Mobile 375px | Đạt |

---

## 4.6. Kiểm thử quy trình AI Agent

| Nội dung | Mục tiêu | Kết quả |
| -------- | -------- | ------- |
| Chạy prebuild hook | Kiểm tra điều kiện trước khi build | Đạt |
| Chạy QA hook | Kiểm tra sau khi hoàn thành skill | Đạt |
| Build đúng thứ tự 13 skill | Không bỏ qua module | Đạt |
| Security hook | Không vi phạm bảo mật | Đạt |
| Transaction hook | Nghiệp vụ DB phức tạp an toàn | Đạt |
| Admin hook | Route admin có middleware | Đạt |
| Inventory hook | Tồn kho không âm | Đạt |

---

## 4.7. Kết quả và đánh giá tổng thể

### 4.7.1. Chức năng đã hoàn thành

**Phía khách hàng:** Đăng ký/đăng nhập/đăng xuất, xem/tìm/lọc sản phẩm, giỏ hàng, đặt hàng, thanh toán COD/chuyển khoản/VNPay, lịch sử đơn, hủy đơn, đánh giá, bảo hành.

**Phía admin:** Dashboard thống kê, quản lý danh mục/sản phẩm/tồn kho/đơn hàng/người dùng/đánh giá/bảo hành, upload ảnh, xác nhận thanh toán.

**Về quy trình:** Spec chi tiết, 13 skill rõ ràng, hooks kiểm soát chất lượng, AI Agent hỗ trợ triển khai.

### 4.7.2. Acceptance Criteria theo SPEC.md

Tất cả acceptance criteria trong SPEC.md đã được hoàn thành: phân quyền 3 role, transaction tạo/hủy đơn, stock không âm, VNPay verify hash, bcrypt password, prepared statements, state machine đơn hàng đúng.

---

# KẾT LUẬN

Đề tài **"Ứng dụng AI Agent trong việc xây dựng trang web bán đồ điện tử"** đã xây dựng thành công một hệ thống website bán hàng trực tuyến với đầy đủ các chức năng cơ bản dành cho khách hàng và quản trị viên.

Hệ thống cho phép khách hàng xem, tìm kiếm, lọc sản phẩm, quản lý giỏ hàng, đặt hàng, thanh toán (COD, chuyển khoản, VNPay sandbox), theo dõi đơn hàng, đánh giá sản phẩm và gửi yêu cầu bảo hành. Quản trị viên quản lý danh mục, sản phẩm, tồn kho, đơn hàng, người dùng, đánh giá, bảo hành và thống kê doanh thu.

Điểm nổi bật: quy trình phát triển có sự hỗ trợ của **AI Agent**, kết hợp spec chi tiết, 13 skill có thứ tự và hooks kiểm tra, giúp triển khai có kiểm soát, giảm lỗi và tăng hiệu quả.

## Hạn chế

* VNPay mới ở môi trường sandbox.
* Chưa tích hợp đơn vị vận chuyển thực tế.
* Chưa có voucher/mã giảm giá.
* Chưa có chatbot tư vấn hoặc gợi ý sản phẩm AI.
* Chưa triển khai email xác thực và quên mật khẩu hoàn chỉnh.
* AI Agent hỗ trợ sinh mã nhưng vẫn cần người thực hiện kiểm tra logic nghiệp vụ.

## Hướng phát triển

* Tích hợp thanh toán thật (VNPay, Momo).
* Tích hợp đơn vị vận chuyển (GHN, GHTK).
* Bổ sung voucher, flash sale.
* Bổ sung chatbot AI tư vấn sản phẩm.
* Bổ sung hệ thống gợi ý dựa trên hành vi người dùng.
* Email thông báo đơn hàng và xác thực tài khoản.
* Tối ưu SEO và hiệu năng truy vấn.
* Deploy lên cloud/server production.
* Monitoring và log hệ thống.

---

# TÀI LIỆU THAM KHẢO

1. Tài liệu Node.js – nodejs.org
2. Tài liệu Express.js – expressjs.com
3. Tài liệu EJS – ejs.co
4. Tài liệu MySQL – dev.mysql.com
5. Tài liệu Bootstrap 5 – getbootstrap.com
6. Tài liệu bcrypt – npmjs.com/package/bcrypt
7. Tài liệu mysql2 – npmjs.com/package/mysql2
8. Tài liệu VNPay Sandbox – sandbox.vnpayment.vn
9. Tài liệu OWASP Top 10 – owasp.org
10. Đặc tả hệ thống `SPEC.md` của đề tài.

---

# PHỤ LỤC

## Phụ lục A – Cấu trúc cơ sở dữ liệu đầy đủ

Schema 12 bảng: `users`, `addresses`, `categories`, `products`, `product_images`, `carts`, `cart_items`, `orders`, `order_items`, `payments`, `reviews`, `warranty_requests`.

## Phụ lục B – Bảng danh sách route đầy đủ

Danh sách đầy đủ tất cả route public, customer và admin của hệ thống.

## Phụ lục C – Cấu hình .env.example

```env
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=electroshop
SESSION_SECRET=your-secret-key
VNPAY_TMN_CODE=
VNPAY_HASH_SECRET=
VNPAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
VNPAY_RETURN_URL=http://localhost:3000/payment/vnpay/return
BANK_NAME=MB Bank
BANK_ACCOUNT_NAME=DO HUY DAT
BANK_ACCOUNT_NUMBER=0417934401
```

## Phụ lục D – Seed data tài khoản mặc định

| Vai trò | Email | Mật khẩu |
| ------- | ----- | -------- |
| Admin | admin@electroshop.com | Admin@123456 |
| Customer (1) | an@example.com | Customer@123 |
| Customer (2) | binh@example.com | Customer@123 |
