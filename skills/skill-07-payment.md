# SKILL 07 — Payment

## Mục tiêu
COD, bank transfer (hướng dẫn chuyển khoản), VNPay sandbox. Verify signature trước khi update DB.

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
function sortObject(obj) {
  return Object.keys(obj).sort().reduce((sorted, key) => {
    sorted[key] = obj[key];
    return sorted;
  }, {});
}

function createVNPayUrl(orderCode, amount, ipAddr, returnUrl) {
  const tmnCode = process.env.VNPAY_TMN_CODE;
  const secretKey = process.env.VNPAY_HASH_SECRET;
  const vnpUrl = process.env.VNPAY_URL;

  const date = new Date();
  const createDate = date.toISOString().replace(/[-T:.Z]/g, '').substring(0, 14);

  const params = sortObject({
    vnp_Version: '2.1.0',
    vnp_Command: 'pay',
    vnp_TmnCode: tmnCode,
    vnp_Amount: amount * 100,
    vnp_CurrCode: 'VND',
    vnp_TxnRef: orderCode,
    vnp_OrderInfo: `Thanh toan don hang ${orderCode}`,
    vnp_OrderType: 'other',
    vnp_Locale: 'vn',
    vnp_ReturnUrl: returnUrl || process.env.VNPAY_RETURN_URL,
    vnp_IpAddr: ipAddr,
    vnp_CreateDate: createDate
  });

  const signData = querystring.stringify(params, { encode: false });
  const hmac = crypto.createHmac('sha512', secretKey);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');
  params.vnp_SecureHash = signed;

  return `${vnpUrl}?${querystring.stringify(params, { encode: false })}`;
}

function verifyVNPayReturn(query) {
  const secureHash = query.vnp_SecureHash;
  const params = { ...query };
  delete params.vnp_SecureHash;
  delete params.vnp_SecureHashType;

  const sorted = sortObject(params);
  const signData = querystring.stringify(sorted, { encode: false });
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

  const ipAddr = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  const url = paymentService.createVNPayUrl(orderCode, rows[0].total_amount, ipAddr);
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

---

## Checklist xác nhận ✅

```
[ ] COD: order.payment_status = 'unpaid' sau khi tạo đơn
[ ] GET /payment/bank-info/:code → hiển thị đúng thông tin ngân hàng
[ ] Nội dung CK = order_code (copy-paste rõ ràng)
[ ] GET /payment/vnpay/create → tạo URL đúng với amount * 100
[ ] SecureHash được tạo đúng (HMAC-SHA512)
[ ] GET /payment/vnpay/return?vnp_ResponseCode=00 → verify hash → update paid → redirect success
[ ] GET /payment/vnpay/return hash sai → flash error, không update DB
[ ] POST /payment/vnpay/ipn → idempotent (gọi 2 lần không update 2 lần)
[ ] Sau payment thành công → stock bị trừ đúng
[ ] payment.paid_at được set chính xác
[ ] Không có 2 payment record cho 1 order
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 07`
