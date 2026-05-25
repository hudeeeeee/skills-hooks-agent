#!/bin/bash
# HOOK 03 — Database Transaction Audit
# Kiểm tra các nghiệp vụ quan trọng có dùng transaction không
# Usage: bash hooks/hook-03-transaction.sh

echo "============================================="
echo "  TRANSACTION HOOK — Database Safety Check"
echo "============================================="

SCAN_PATH="src"
ISSUES=0

check_transaction() {
  local service="$1"
  local file="$2"
  local keyword="$3"

  if [ ! -f "$file" ]; then
    echo "  ⏭️  $service ($file chưa tồn tại)"
    return
  fi

  local has_fn=$(grep -n "$keyword" "$file" 2>/dev/null | head -1)
  if [ -z "$has_fn" ]; then
    echo "  ⏭️  $service — function chưa có"
    return
  fi

  local has_transaction=$(grep -n "beginTransaction\|getConnection" "$file" 2>/dev/null | head -1)
  local has_rollback=$(grep -n "rollback" "$file" 2>/dev/null | head -1)
  local has_commit=$(grep -n "commit" "$file" 2>/dev/null | head -1)
  local has_release=$(grep -n "release" "$file" 2>/dev/null | head -1)

  if [ -n "$has_transaction" ] && [ -n "$has_rollback" ] && [ -n "$has_commit" ] && [ -n "$has_release" ]; then
    echo "  ✅ $service — transaction đầy đủ (beginTransaction, commit, rollback, release)"
  else
    echo "  ❌ $service — THIẾU transaction!"
    [ -z "$has_transaction" ] && echo "     → Thiếu: conn.beginTransaction()"
    [ -z "$has_commit"      ] && echo "     → Thiếu: conn.commit()"
    [ -z "$has_rollback"    ] && echo "     → Thiếu: conn.rollback() trong catch"
    [ -z "$has_release"     ] && echo "     → Thiếu: conn.release() trong finally"
    ((ISSUES++))
  fi
}

echo ""
echo "[ CRITICAL OPERATIONS — phải dùng transaction ]"
echo ""

check_transaction \
  "order.service.js :: createOrder" \
  "$SCAN_PATH/services/order.service.js" \
  "createOrder\|async function createOrder"

check_transaction \
  "order.service.js :: cancelOrder" \
  "$SCAN_PATH/services/order.service.js" \
  "cancelOrder\|async function cancelOrder"

check_transaction \
  "payment.service.js :: handleVNPaySuccess" \
  "$SCAN_PATH/services/payment.service.js" \
  "handleVNPaySuccess\|VNPaySuccess"

check_transaction \
  "payment.service.js :: confirmBankPayment" \
  "$SCAN_PATH/services/payment.service.js" \
  "confirmBankPayment\|confirmBank"

check_transaction \
  "admin.service.js :: updateOrderStatus" \
  "$SCAN_PATH/services/admin.service.js" \
  "updateOrderStatus"

check_transaction \
  "admin.service.js :: createProduct" \
  "$SCAN_PATH/services/admin.service.js" \
  "createProduct"

check_transaction \
  "review.service.js :: createReview" \
  "$SCAN_PATH/services/review.service.js" \
  "createReview"

echo ""
echo "[ TRANSACTION PATTERN CHECK ]"
# Kiểm tra không có pool.query bên trong transaction mà không dùng conn
MIXED=$(grep -rn "pool\.query\|pool\.execute" "$SCAN_PATH/services" --include="*.js" -l 2>/dev/null)
if [ -n "$MIXED" ]; then
  echo ""
  echo "  ℹ️  Files có cả pool.query và có thể có transaction:"
  echo "$MIXED" | while read f; do
    HAS_TRANS=$(grep -c "beginTransaction" "$f" 2>/dev/null || echo 0)
    HAS_POOL=$(grep -c "pool\.query" "$f" 2>/dev/null || echo 0)
    if [ "$HAS_TRANS" -gt 0 ] && [ "$HAS_POOL" -gt 0 ]; then
      echo "  ⚠️  $f — có $HAS_TRANS transaction + $HAS_POOL pool.query → đảm bảo dùng conn.query bên trong transaction"
    fi
  done
fi

echo ""
echo "============================================="
if [ $ISSUES -gt 0 ]; then
  echo "  ❌ $ISSUES nghiệp vụ THIẾU transaction — FIX NGAY"
  exit 1
else
  echo "  ✅ Tất cả nghiệp vụ critical đã có transaction"
  exit 0
fi
echo "============================================="
