#!/bin/bash
# HOOK 05 — Order State Transition Validator
# Kiểm tra logic chuyển trạng thái đơn hàng trong code
# Usage: bash hooks/hook-05-order-state.sh

echo "============================================="
echo "  ORDER STATE HOOK — Transition Validator"
echo "============================================="

SCAN_PATH="src"
ISSUES=0

echo ""
echo "[ VALID TRANSITIONS TABLE ]"
echo "  pending    → confirmed, cancelled"
echo "  confirmed  → processing, cancelled"
echo "  processing → shipping, cancelled"
echo "  shipping   → completed, cancelled"
echo "  completed  → (không có)"
echo "  cancelled  → (không có)"

echo ""
echo "[ CODE CHECK — VALID_TRANSITIONS object ]"

# Kiểm tra admin.service.js và order.service.js có VALID_TRANSITIONS
for file in \
  "$SCAN_PATH/services/admin.service.js" \
  "$SCAN_PATH/services/order.service.js"; do

  name=$(basename "$file")
  if [ ! -f "$file" ]; then
    echo "  ⏭️  $name (chưa tồn tại)"
    continue
  fi

  if grep -q "VALID_TRANSITIONS\|validTransitions\|cancellable\|order_status.*pending.*confirmed" "$file" 2>/dev/null; then
    echo "  ✅ $name — có transition guard"
  else
    echo "  ❌ $name — THIẾU transition guard!"
    echo "     → Thêm VALID_TRANSITIONS object và validate trước khi UPDATE order_status"
    ((ISSUES++))
  fi
done

echo ""
echo "[ DIRECT STATUS UPDATE CHECK ]"
# Tìm UPDATE orders SET order_status không có validation
DIRECT_UPDATE=$(grep -rn "UPDATE.*orders.*SET.*order_status\|order_status.*=.*'" "$SCAN_PATH" --include="*.js" 2>/dev/null | grep -v "valid\|VALID\|transition\|cancellable\|//")
if [ -n "$DIRECT_UPDATE" ]; then
  echo "  ⚠️  Tìm thấy cập nhật order_status trực tiếp — đảm bảo đã validate trước:"
  echo "$DIRECT_UPDATE" | head -5 | while read line; do echo "     $line"; done
else
  echo "  ✅ Không thấy direct status update không qua validation"
fi

echo ""
echo "[ CANCEL PERMISSION CHECK ]"
# Customer chỉ được cancel pending/confirmed
CANCEL_FILE="$SCAN_PATH/services/order.service.js"
if [ -f "$CANCEL_FILE" ]; then
  if grep -q "pending.*confirmed\|cancellable\|VALID.*cancel\|cancelled.*pending" "$CANCEL_FILE" 2>/dev/null; then
    echo "  ✅ cancelOrder — có check trạng thái được phép hủy"
  else
    echo "  ❌ cancelOrder — thiếu check điều kiện được hủy"
    ((ISSUES++))
  fi
fi

echo ""
echo "[ INVENTORY ON TRANSITION CHECK ]"
ADMIN_SERVICE="$SCAN_PATH/services/admin.service.js"
if [ -f "$ADMIN_SERVICE" ]; then
  HAS_STOCK_DEDUCT=$(grep -n "stock_quantity.*-\|stock_quantity.*minus\|stock.*confirmed" "$ADMIN_SERVICE" 2>/dev/null | head -1)
  HAS_STOCK_RETURN=$(grep -n "stock_quantity.*+\|stock.*cancel\|hoàn.*kho" "$ADMIN_SERVICE" 2>/dev/null | head -1)

  [ -n "$HAS_STOCK_DEDUCT" ] && echo "  ✅ admin.service — trừ kho khi confirmed" || { echo "  ❌ admin.service — thiếu logic trừ kho khi confirmed"; ((ISSUES++)); }
  [ -n "$HAS_STOCK_RETURN" ] && echo "  ✅ admin.service — hoàn kho khi cancelled" || { echo "  ❌ admin.service — thiếu logic hoàn kho khi cancelled"; ((ISSUES++)); }
fi

echo ""
echo "[ OUT_OF_STOCK STATUS CHECK ]"
OOS=$(grep -rn "out_of_stock\|stock_quantity.*<=.*0\|stock_quantity.*=.*0" "$SCAN_PATH" --include="*.js" 2>/dev/null | grep -v "//")
if [ -n "$OOS" ]; then
  echo "  ✅ Có xử lý out_of_stock status"
else
  echo "  ⚠️  Chưa thấy xử lý out_of_stock — thêm logic SET status='out_of_stock' khi stock=0"
  ((ISSUES++))
fi

echo ""
echo "[ REVIEW PERMISSION — completed only ]"
REVIEW_SERVICE="$SCAN_PATH/services/review.service.js"
if [ -f "$REVIEW_SERVICE" ]; then
  if grep -q "completed" "$REVIEW_SERVICE" 2>/dev/null; then
    echo "  ✅ review.service — check order_status = completed"
  else
    echo "  ❌ review.service — thiếu check order_status = completed"
    ((ISSUES++))
  fi
fi

echo ""
echo "============================================="
if [ $ISSUES -gt 0 ]; then
  echo "  ❌ $ISSUES vấn đề cần FIX trong order state logic"
  exit 1
else
  echo "  ✅ Order state logic đúng"
  exit 0
fi
echo "============================================="
