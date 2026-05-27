# SKILL 07 — Payment

## Mục tiêu
COD, bank transfer (hướng dẫn chuyển khoản), VNPay sandbox với ngrok. Verify signature trước khi update DB.

## VNPay Sandbox Requirements
- Ngrok authtoken (free): https://dashboard.ngrok.com/signup
- App tự động fetch ngrok public URL để làm return URL
- Test cards: 9704198526191432198 / NGUYEN VAN A / 07/15 / OTP: 123456

## VNPay Encoding Rules (CRITICAL)
**KHÔNG dùng `querystring.stringify()` - VNPay yêu cầu format đặc biệt:**
1. URL encode với `%20` → `+` (space thành plus, không phải %20)
2. Manual build query string theo thứ tự sort key
3. Timezone GMT+7 cho `vnp_CreateDate`
4. IPv6-mapped IPv4 (`::ffff:x.x.x.x`) → extract phần IPv4 trước khi gửi VNPay
5. IP không phải IPv4 hợp lệ → fallback `127.0.0.1`
5. OrderType = `billpayment` (không phải `other`)
6. SignData và urlParams phải build riêng, giống nhau về encoding

## Files cần tạo
```
src/controllers/payment.controller.js
src/services/payment.service.js
src/routes/payment.routes.js
src/views/pages/payment/bank-info.ejs
src/views/pages/payment/success.ejs
src/views/pages/payment/failed.ejs
```

---

## Bước 1 — payment.service.js

```javascript
const pool = require('../config/database');
const crypto = require('crypto');
const querystring = require('querystring');
const http = require('http');

// ─── NGROK DYNAMIC URL ───────────────────────────────────────
async function getNgrokUrl() {
  return new Promise((resolve) => {
    const req = http.get('http://ngrok:4040/api/tunnels', (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const tunnels = JSON.parse(data);
          const httpsTunnel = tunnels.tunnels.find(t => t.proto === 'https');
          resolve(httpsTunnel ? httpsTunnel.public_url : null);
        } catch (e) {
          resolve(null);
        }
      });
    });
    req.on('error', () => resolve(null));
    req.setTimeout(2000, () => {
      req.destroy();
      resolve(null);
    });
  });
}

// ─── BANK TRANSFER ───────────────────────────────────────────
async function getBankInfo(orderCode, userId) {
  const [rows] = await pool.query(
    'SELECT * FROM orders WHERE order_code = ? AND user_id = ?', [orderCode, userId]
  );
  if (!rows.length) return null;
  return {
    order: rows[0],
    bankAccount: process.env.BANK_ACCOUNT_NUMBER,
    bankName: process.env.BANK_NAME,
    accountName: process.env.BANK_ACCOUNT_NAME,
    transferContent: orderCode
  };
}

// Admin gọi khi xác nhận đã nhận tiền
async function confirmBankPayment(orderId, transactionCode, adminId) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [rows] = await conn.query('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (!rows.length) throw new Error('Không tìm thấy đơn hàng');
    const order = rows[0];
    if (order.payment_status === 'paid') throw new Error('Đơn đã được thanh toán');

    await conn.query(
      "UPDATE payments SET payment_status = 'paid', transaction_code = ?, paid_at = NOW() WHERE order_id = ?",
      [transactionCode, orderId]
    );
    await conn.query(
      "UPDATE orders SET payment_status = 'paid', order_status = 'confirmed', updated_at = NOW() WHERE id = ?",
      [orderId]
    );

    // Trừ tồn kho
    const [items] = await conn.query('SELECT product_id, quantity FROM order_items WHERE order_id = ?', [orderId]);
    for (const item of items) {
      await conn.query(
        'UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?',
        [item.quantity, item.product_id]
      );
      await conn.query(
        "UPDATE products SET status = 'out_of_stock' WHERE id = ? AND stock_quantity <= 0",
        [item.product_id]
      );
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

// ─── VNPAY ───────────────────────────────────────────────────
// CRITICAL: VNPay cần URL encoding đặc biệt (%20 → +)
function sortObject(obj) {
  const sorted = {};
  const keys = Object.keys(obj).sort();
  for (let key of keys) {
    sorted[key] = encodeURIComponent(obj[key]).replace(/%20/g, '+');
  }
  return sorted;
}

async function createVNPayUrl(orderCode, amount, ipAddr) {
  const tmnCode = process.env.VNPAY_TMN_CODE;
  const secretKey = process.env.VNPAY_HASH_SECRET;
  let vnpUrl = process.env.VNPAY_URL;

  // Timezone GMT+7 cho Vietnam
  const date = new Date();
  const tzOffset = 7 * 60 * 60 * 1000;
  const vnTime = new Date(date.getTime() + tzOffset);
  const createDate = vnTime.toISOString().replace(/[-T:.Z]/g, '').substring(0, 14);

  // Get ngrok URL dynamically, fallback to env
  let returnUrl = process.env.VNPAY_RETURN_URL;
  const ngrokUrl = await getNgrokUrl();
  if (ngrokUrl) {
    returnUrl = `${ngrokUrl}/payment/vnpay/return`;
  }

  // Localhost → fallback IP (VNPay reject 127.0.0.1)
  const finalIp = (ipAddr === '127.0.0.1' || ipAddr === '::1') ? '113.160.92.202' : ipAddr;

  let vnp_Params = {
    vnp_Version: '2.1.0',
    vnp_Command: 'pay',
    vnp_TmnCode: tmnCode,
    vnp_Amount: Math.floor(amount) * 100,
    vnp_CurrCode: 'VND',
    vnp_TxnRef: orderCode,
    vnp_OrderInfo: 'Thanh toan cho don hang ' + orderCode,
    vnp_OrderType: 'billpayment',  // 'other' → 'billpayment'
    vnp_Locale: 'vn',
    vnp_ReturnUrl: returnUrl,
    vnp_IpAddr: finalIp,
    vnp_CreateDate: createDate
  };

  // Manual query string build (VNPay yêu cầu format đặc biệt)
  const sortedKeys = Object.keys(vnp_Params).sort();
  let signData = '';
  let urlParams = '';
  
  for (let i = 0; i < sortedKeys.length; i++) {
    const key = sortedKeys[i];
    const value = vnp_Params[key];
    if (value !== undefined && value !== null && value !== '') {
      const encodedKey = encodeURIComponent(key).replace(/%20/g, '+');
      const encodedValue = encodeURIComponent(value).replace(/%20/g, '+');
      
      if (signData.length > 0) {
        signData += '&' + encodedKey + '=' + encodedValue;
        urlParams += '&' + encodedKey + '=' + encodedValue;
      } else {
        signData += encodedKey + '=' + encodedValue;
        urlParams += encodedKey + '=' + encodedValue;
      }
    }
  }

  const hmac = crypto.createHmac('sha512', secretKey);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');
  
  const finalUrl = vnpUrl + '?' + urlParams + '&vnp_SecureHash=' + signed;
  console.log('VNPAY URL:', finalUrl);
  return finalUrl;
}

function verifyVNPayReturn(query) {
  const secureHash = query.vnp_SecureHash;
  const params = { ...query };
  delete params.vnp_SecureHash;
  delete params.vnp_SecureHashType;

  // Manual encoding để match với createVNPayUrl
  const sortedKeys = Object.keys(params).sort();
  let signData = '';
  for (let i = 0; i < sortedKeys.length; i++) {
    const key = sortedKeys[i];
    const value = params[key];
    if (value !== undefined && value !== null && value !== '') {
      const encodedKey = encodeURIComponent(key).replace(/%20/g, '+');
      const encodedValue = encodeURIComponent(value).replace(/%20/g, '+');
      if (signData.length > 0) {
        signData += '&' + encodedKey + '=' + encodedValue;
      } else {
        signData += encodedKey + '=' + encodedValue;
      }
    }
  }

  const hmac = crypto.createHmac('sha512', process.env.VNPAY_HASH_SECRET);
  const checkHash = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

  return { valid: secureHash === checkHash, responseCode: query.vnp_ResponseCode };
}

async function handleVNPaySuccess(orderCode, transactionCode) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [rows] = await conn.query('SELECT * FROM orders WHERE order_code = ?', [orderCode]);
    if (!rows.length) throw new Error('Không tìm thấy đơn hàng');
    const order = rows[0];

    // Idempotency check
    if (order.payment_status === 'paid') {
      await conn.commit();
      return { success: true, alreadyPaid: true };
    }

    await conn.query(
      "UPDATE payments SET payment_status = 'paid', transaction_code = ?, paid_at = NOW() WHERE order_id = ?",
      [transactionCode, order.id]
    );
    await conn.query(
      "UPDATE orders SET payment_status = 'paid', order_status = 'confirmed', updated_at = NOW() WHERE id = ?",
      [order.id]
    );

    // Trừ tồn kho
    const [items] = await conn.query('SELECT product_id, quantity FROM order_items WHERE order_id = ?', [order.id]);
    for (const item of items) {
      await conn.query('UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?',
        [item.quantity, item.product_id]);
      await conn.query("UPDATE products SET status = 'out_of_stock' WHERE id = ? AND stock_quantity <= 0",
        [item.product_id]);
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

async function handleVNPayFailed(orderCode) {
  await pool.query(
    "UPDATE payments SET payment_status = 'failed' WHERE order_id = (SELECT id FROM orders WHERE order_code = ?)",
    [orderCode]
  );
  await pool.query(
    "UPDATE orders SET payment_status = 'failed' WHERE order_code = ?",
    [orderCode]
  );
}

module.exports = { getBankInfo, confirmBankPayment, createVNPayUrl, verifyVNPayReturn, handleVNPaySuccess, handleVNPayFailed };
```

---

## Bước 2 — payment.controller.js

```javascript
const paymentService = require('../services/payment.service');
const pool = require('../config/database');

// GET /payment/bank-info/:orderCode
const getBankInfo = async (req, res) => {
  const data = await paymentService.getBankInfo(req.params.orderCode, req.session.user.id);
  if (!data) return res.status(404).render('errors/404', { title: 'Không tìm thấy đơn hàng' });
  res.render('pages/payment/bank-info', { title: 'Hướng dẫn thanh toán', ...data });
};

// GET /payment/vnpay/create?orderCode=ORD-...
const createVNPayUrl = async (req, res) => {
  const { orderCode } = req.query;
  const [rows] = await pool.query(
    'SELECT total_amount FROM orders WHERE order_code = ? AND user_id = ?',
    [orderCode, req.session.user.id]
  );
  if (!rows.length) return res.redirect('/orders');

  // Normalize IPv6-mapped IPv4 (e.g. ::ffff:127.0.0.1 → 127.0.0.1)
  let ipAddr = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';
  if (ipAddr.includes('::ffff:')) ipAddr = ipAddr.split(':').pop();
  if (!/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(ipAddr)) ipAddr = '127.0.0.1';
  const url = await paymentService.createVNPayUrl(orderCode, rows[0].total_amount, ipAddr);
  res.redirect(url);
};

// GET /payment/vnpay/return
const vnpayReturn = async (req, res) => {
  const { valid, responseCode } = paymentService.verifyVNPayReturn(req.query);
  const orderCode = req.query.vnp_TxnRef;
  const txnCode = req.query.vnp_TransactionNo;

  if (!valid) {
    req.flash('error', 'Phản hồi thanh toán không hợp lệ');
    return res.redirect('/orders');
  }

  if (responseCode === '00') {
    await paymentService.handleVNPaySuccess(orderCode, txnCode);
    req.flash('success', 'Thanh toán thành công!');
    return res.redirect(`/orders/${orderCode}`);
  } else {
    await paymentService.handleVNPayFailed(orderCode);
    req.flash('error', 'Thanh toán thất bại. Vui lòng thử lại hoặc chọn phương thức khác.');
    return res.redirect(`/orders/${orderCode}`);
  }
};

// POST /payment/vnpay/ipn (server-to-server, không cần auth)
const vnpayIPN = async (req, res) => {
  const { valid, responseCode } = paymentService.verifyVNPayReturn(req.query);
  if (!valid) return res.json({ RspCode: '97', Message: 'Invalid Checksum' });

  const orderCode = req.query.vnp_TxnRef;
  const txnCode = req.query.vnp_TransactionNo;

  if (responseCode === '00') {
    const result = await paymentService.handleVNPaySuccess(orderCode, txnCode);
    if (result.success) return res.json({ RspCode: '00', Message: 'Confirm Success' });
    return res.json({ RspCode: '99', Message: result.error });
  } else {
    await paymentService.handleVNPayFailed(orderCode);
    return res.json({ RspCode: '00', Message: 'Confirm Success' });
  }
};

module.exports = { getBankInfo, createVNPayUrl, vnpayReturn, vnpayIPN };

// TEST ONLY — simulate VNPay success không cần sandbox (dev only)
router.get('/payment/test-vnpay-success/:orderCode', requireAuth, async (req, res) => {
  const result = await paymentService.handleVNPaySuccess(req.params.orderCode, 'TEST_TXN_' + Date.now());
  if (result.success) req.flash('success', 'TEST: Thanh toán thành công!');
  else req.flash('error', result.error);
  res.redirect(`/orders/${req.params.orderCode}`);
});
```

---

## Bước 3 — View: bank-info.ejs

```html
<div class="row justify-content-center">
  <div class="col-md-6">
    <div class="card border-success">
      <div class="card-header bg-success text-white text-center">
        <h5 class="mb-0"><i class="bi bi-bank"></i> Thông tin chuyển khoản</h5>
      </div>
      <div class="card-body">
        <div class="alert alert-warning">
          <i class="bi bi-exclamation-triangle"></i>
          Vui lòng chuyển khoản trong <strong>24 giờ</strong> để giữ đơn hàng.
          Ghi đúng <strong>nội dung chuyển khoản</strong>.
        </div>
        <table class="table table-borderless">
          <tr>
            <td class="text-muted">Ngân hàng</td>
            <td><strong><%= bankName %></strong></td>
          </tr>
          <tr>
            <td class="text-muted">Số tài khoản</td>
            <td><strong class="fs-5 text-primary"><%= bankAccount %></strong></td>
          </tr>
          <tr>
            <td class="text-muted">Chủ tài khoản</td>
            <td><strong><%= accountName %></strong></td>
          </tr>
          <tr>
            <td class="text-muted">Số tiền</td>
            <td><strong class="text-danger fs-5"><%= order.total_amount.toLocaleString('vi-VN') %>đ</strong></td>
          </tr>
          <tr>
            <td class="text-muted">Nội dung CK</td>
            <td>
              <strong class="text-success fs-5 bg-light px-2 py-1 rounded"><%= transferContent %></strong>
              <small class="text-muted d-block mt-1">⚠ Copy chính xác, không thêm ký tự</small>
            </td>
          </tr>
        </table>
        <!-- QR code chuyển khoản nhanh -->
        <div class="mb-4 text-center">
          <p class="text-muted mb-2">Quét mã QR để chuyển khoản nhanh</p>
          <img src="/images/qr.png" alt="QR chuyển khoản" class="img-fluid rounded" style="max-width: 220px;">
        </div>
        <div class="text-center mt-3">
          <a href="/orders/<%= order.order_code %>" class="btn btn-primary">
            Xem đơn hàng
          </a>
        </div>
      </div>
    </div>
  </div>
</div>
```

> **Lưu ý thực tế:** Ngân hàng thực tế là **MB Bank**, chủ tài khoản **DO HUY DAT**.
> File QR đặt tại `public/images/qr.png`.

---

## Bước 4 — Ngrok Setup cho VNPay Sandbox

VNPay không thể redirect về localhost. Cần ngrok để expose public URL.

### 4.1 Lấy Ngrok Authtoken

1. Đăng ký free: https://dashboard.ngrok.com/signup
2. Copy authtoken: https://dashboard.ngrok.com/get-started/your-authtoken
3. Thêm vào `.env`:
```bash
NGROK_AUTHTOKEN=your_token_here
```

### 4.2 Docker Compose đã có ngrok service

```yaml
ngrok:
  image: ngrok/ngrok:latest
  environment:
    NGROK_AUTHTOKEN: ${NGROK_AUTHTOKEN}
  command: ["http", "app:3000"]
  ports:
    - "4040:4040"
```

### 4.3 Start & lấy public URL

```bash
docker compose up -d
sleep 5
curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"https://[^"]*' | cut -d'"' -f4
```

Kết quả: `https://abc123.ngrok-free.app`

App tự động fetch URL này làm `vnp_ReturnUrl`.

### 4.4 Test VNPay

Thẻ sandbox:
- Card: `9704198526191432198`
- Name: `NGUYEN VAN A`
- Exp: `07/15`
- OTP: `123456`

Luồng: Tạo đơn → VNPay → nhập thẻ → success → callback về ngrok URL → app xử lý → update order paid

---

## Checklist xác nhận ✅

```
[x] COD: order.payment_status = 'unpaid' sau khi tạo đơn
[x] GET /payment/bank-info/:code → hiển thị đúng thông tin ngân hàng
[x] Nội dung CK = order_code (copy-paste rõ ràng)
[x] GET /payment/vnpay/create → tạo URL đúng với amount * 100
[x] SecureHash được tạo đúng (HMAC-SHA512, không dùng encode: false)
[x] GET /payment/vnpay/return?vnp_ResponseCode=00 → verify hash → update paid → redirect success
[x] GET /payment/vnpay/return hash sai → flash error, không update DB
[x] POST /payment/vnpay/ipn → idempotent (gọi 2 lần không update 2 lần)
[x] Sau payment thành công → stock bị trừ đúng
[x] payment.paid_at được set chính xác
[x] Không có 2 payment record cho 1 order
[x] Ngrok URL tự động fetch, không cần hardcode
[x] VNPay sandbox test card hoạt động với ngrok tunnel
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 07`

---

## Test Cases — Payment

| ID | Input | Expected |
|----|-------|----------|
| TC40 | COD: tạo đơn | payment_status=unpaid, order_status=pending |
| TC41 | Bank transfer: tạo đơn | Redirect /payment/bank-info, thấy STK/tên/số tiền/mã đơn |
| TC42 | Admin PATCH confirm-payment với transaction_code | payment=paid, order=confirmed, kho bị trừ |
| TC43 | GET /payment/vnpay/create | Tạo URL đúng, redirect sang VNPay sandbox |
| TC44 | VNPay return: responseCode=00, hash hợp lệ | payment=paid, order=confirmed, kho trừ, redirect success |
| TC45 | VNPay return: hash sai (giả mạo) | Không update DB, flash lỗi |
| TC46 | VNPay return: responseCode≠00 | payment=failed, flash "Thanh toán thất bại" |
| TC47 | VNPay IPN gọi 2 lần (idempotency) | Lần 2 không update lại DB (check payment_status!=paid) |
| TC48 | payments.order_id UNIQUE | Không tạo được 2 payment record cho 1 order |
| TC49 | payment.paid_at | Được set đúng tại thời điểm confirm/callback |
| SEC03 | VNPay callback giả: sửa vnp_ResponseCode=00 không có hash | verifySecureHash thất bại, không update paid |
| DATA04 | Không có 2 payment record | UNIQUE constraint trên payments.order_id |
