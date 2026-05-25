#!/bin/bash
# HOOK 07 — Payment Rules Validator
# Kiểm tra quy tắc xử lý thanh toán
# Usage: bash hooks/hook-07-payment.sh

echo "============================================="
echo "  PAYMENT HOOK — Payment Rules Check"
echo "============================================="

SCAN_PATH="src"
ISSUES=0

echo ""
echo "[ RULE 1 — VNPay: phải verify SecureHash trước khi update DB ]"
PAYMENT_SVC="$SCAN_PATH/services/payment.service.js"
PAYMENT_CTRL="$SCAN_PATH/controllers/payment.controller.js"

for file in "$PAYMENT_SVC" "$PAYMENT_CTRL"; do
  if [ -f "$file" ]; then
    name=$(basename "$file")
    if grep -q "SecureHash\|verifyVNPay\|hmac\|sha512\|checkHash" "$file" 2>/dev/null; then
      echo "  ✅ $name — có verify signature"
    else
      echo "  ❌ $name — THIẾU verify SecureHash"
      ((ISSUES++))
    fi
  fi
done

echo ""
echo "[ RULE 2 — Idempotency: không update paid nếu đã paid ]"
if [ -f "$PAYMENT_SVC" ]; then
  if grep -q "payment_status.*paid\|alreadyPaid\|idempotent" "$PAYMENT_SVC" 2>/dev/null; then
    echo "  ✅ payment.service — có idempotency check"
  else
    echo "  ❌ payment.service — THIẾU idempotency check (IPN có thể gọi 2 lần)"
    echo "     → Thêm: IF payment_status != 'paid' THEN update"
    ((ISSUES++))
  fi
fi

echo ""
echo "[ RULE 3 — COD: payment_status = unpaid (không tự set paid) ]"
ORDER_SVC="$SCAN_PATH/services/order.service.js"
if [ -f "$ORDER_SVC" ]; then
  COD_PAYMENT=$(grep -n "cod\|COD" "$ORDER_SVC" 2>/dev/null | head -3)
  UNPAID=$(grep -n "unpaid" "$ORDER_SVC" 2>/dev/null | head -1)
  if [ -n "$UNPAID" ]; then
    echo "  ✅ order.service — COD set payment_status = unpaid"
  else
    echo "  ❌ order.service — COD phải set payment_status = 'unpaid'"
    ((ISSUES++))
  fi
fi

echo ""
echo "[ RULE 4 — payment.paid_at chỉ set khi thực sự thanh toán ]"
PAID_AT=$(grep -rn "paid_at.*NOW\|paid_at.*=.*new Date\|paid_at = NOW" "$SCAN_PATH" --include="*.js" 2>/dev/null | grep -v "//")
if [ -n "$PAID_AT" ]; then
  echo "  ✅ paid_at được set đúng (gần NOW())"
  echo "$PAID_AT" | head -3 | while read line; do echo "     $line"; done
else
  echo "  ⚠️  Chưa thấy paid_at = NOW() — đảm bảo set khi payment thành công"
fi

echo ""
echo "[ RULE 5 — UNIQUE constraint payment — 1 order 1 payment ]"
SCHEMA="database/schema.sql"
if [ -f "$SCHEMA" ]; then
  if grep -q "payments.*UNIQUE\|UNIQUE.*order_id.*payments\|order_id.*UNIQUE" "$SCHEMA" 2>/dev/null; then
    echo "  ✅ schema.sql — payments.order_id có UNIQUE constraint"
  else
    echo "  ❌ schema.sql — THIẾU UNIQUE(order_id) trong bảng payments"
    ((ISSUES++))
  fi
fi

echo ""
echo "[ RULE 6 — Không expose VNPay secret key ]"
EXPOSED_KEY=$(grep -rn "VNPAY_HASH_SECRET\|hashSecret\|secretKey" "$SCAN_PATH/views" --include="*.ejs" 2>/dev/null)
if [ -n "$EXPOSED_KEY" ]; then
  echo "  ❌ VNPAY secret key bị expose trong view!"
  echo "$EXPOSED_KEY" | head -3 | while read line; do echo "     $line"; done
  ((ISSUES++))
else
  echo "  ✅ VNPay secret key không bị expose trong view"
fi

echo ""
echo "[ RULE 7 — IPN endpoint không require user auth ]"
PAYMENT_ROUTES="$SCAN_PATH/routes/payment.routes.js"
if [ -f "$PAYMENT_ROUTES" ]; then
  IPN_ROUTE=$(grep -n "ipn\|IPN" "$PAYMENT_ROUTES" 2>/dev/null)
  IPN_AUTH=$(grep -n "ipn\|IPN" "$PAYMENT_ROUTES" 2>/dev/null | grep "requireAuth\|requireAdmin")
  if [ -n "$IPN_ROUTE" ] && [ -z "$IPN_AUTH" ]; then
    echo "  ✅ IPN route không yêu cầu auth (đúng — gateway gọi server-to-server)"
  elif [ -n "$IPN_AUTH" ]; then
    echo "  ❌ IPN route không được có requireAuth (gateway không có session)"
    ((ISSUES++))
  fi
fi

echo ""
echo "[ RULE 8 — Refund khi hủy đơn đã paid ]"
REFUND=$(grep -rn "refunded\|refund" "$SCAN_PATH/services" --include="*.js" 2>/dev/null | grep -v "//")
if [ -n "$REFUND" ]; then
  echo "  ✅ Có xử lý refunded khi hủy đơn đã thanh toán"
else
  echo "  ⚠️  Chưa thấy logic refunded — đảm bảo set payment_status = 'refunded' khi hủy đơn đã paid"
fi

echo ""
echo "============================================="
if [ $ISSUES -gt 0 ]; then
  echo "  ❌ $ISSUES payment rules bị vi phạm"
  exit 1
else
  echo "  ✅ Payment rules đúng"
  exit 0
fi
echo "============================================="
