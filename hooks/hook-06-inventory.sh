#!/bin/bash
# HOOK 06 — Inventory Rules Validator
# Kiểm tra quy tắc quản lý tồn kho trong code
# Usage: bash hooks/hook-06-inventory.sh

echo "============================================="
echo "  INVENTORY HOOK — Stock Management Check"
echo "============================================="

SCAN_PATH="src/services"
ISSUES=0

echo ""
echo "[ RULE 1 — Validate stock trước khi thêm vào giỏ ]"
CART_SERVICE="$SCAN_PATH/cart.service.js"
if [ -f "$CART_SERVICE" ]; then
  if grep -q "stock_quantity\|stock.*0\|hết hàng\|out_of_stock" "$CART_SERVICE" 2>/dev/null; then
    echo "  ✅ cart.service — kiểm tra tồn kho khi addItem"
  else
    echo "  ❌ cart.service — THIẾU kiểm tra stock_quantity khi thêm vào giỏ"
    ((ISSUES++))
  fi
else
  echo "  ⏭️  cart.service.js chưa tồn tại"
fi

echo ""
echo "[ RULE 2 — Validate stock trước khi tạo đơn hàng ]"
ORDER_SERVICE="$SCAN_PATH/order.service.js"
if [ -f "$ORDER_SERVICE" ]; then
  if grep -q "stock_quantity" "$ORDER_SERVICE" 2>/dev/null; then
    echo "  ✅ order.service — validate stock trước createOrder"
  else
    echo "  ❌ order.service — THIẾU validate stock trước createOrder"
    ((ISSUES++))
  fi
else
  echo "  ⏭️  order.service.js chưa tồn tại"
fi

echo ""
echo "[ RULE 3 — Trừ kho sau khi xác nhận đơn ]"
ADMIN_SERVICE="$SCAN_PATH/admin.service.js"
if [ -f "$ADMIN_SERVICE" ]; then
  if grep -q "stock_quantity.*-\|stock_quantity - " "$ADMIN_SERVICE" 2>/dev/null; then
    echo "  ✅ admin.service — có logic trừ stock khi order confirmed"
  else
    echo "  ❌ admin.service — THIẾU logic trừ stock"
    ((ISSUES++))
  fi
fi

if [ -f "$SCAN_PATH/payment.service.js" ]; then
  if grep -q "stock_quantity.*-\|stock_quantity - " "$SCAN_PATH/payment.service.js" 2>/dev/null; then
    echo "  ✅ payment.service — có logic trừ stock khi VNPay success"
  fi
fi

echo ""
echo "[ RULE 4 — Hoàn kho khi hủy đơn ]"
for svc in "$SCAN_PATH/order.service.js" "$SCAN_PATH/admin.service.js"; do
  if [ -f "$svc" ]; then
    name=$(basename "$svc")
    if grep -q "stock_quantity.*+" "$svc" 2>/dev/null; then
      echo "  ✅ $name — có logic hoàn kho khi cancel"
    else
      echo "  ⚠️  $name — chưa thấy logic hoàn kho (kiểm tra thủ công)"
    fi
  fi
done

echo ""
echo "[ RULE 5 — Không để stock âm ]"
ALL_SERVICES=$(find "$SCAN_PATH" -name "*.js" 2>/dev/null)
for svc in $ALL_SERVICES; do
  name=$(basename "$svc")
  # Tìm UPDATE giảm stock không có WHERE GREATEST hoặc check âm
  UNSAFE=$(grep -n "stock_quantity.*-\|stock_quantity - quantity" "$svc" 2>/dev/null | grep -v "GREATEST\|COALESCE\|IF\|WHERE.*stock\|//")
  if [ -n "$UNSAFE" ]; then
    echo "  ⚠️  $name — có thể trừ kho không check âm:"
    echo "$UNSAFE" | head -3 | while read line; do echo "     $line"; done
    echo "     → Đảm bảo validate stock >= quantity trước khi trừ"
  fi
done

echo ""
echo "[ RULE 6 — SET out_of_stock khi stock = 0 ]"
OOS_SET=$(grep -rn "out_of_stock" "$SCAN_PATH" --include="*.js" 2>/dev/null | grep -v "//")
if [ -n "$OOS_SET" ]; then
  echo "  ✅ Có SET status = 'out_of_stock' khi stock = 0"
else
  echo "  ❌ Thiếu logic SET status = 'out_of_stock' khi stock = 0"
  ((ISSUES++))
fi

echo ""
echo "[ RULE 7 — Restore active khi hoàn kho ]"
RESTORE_ACTIVE=$(grep -rn "active.*out_of_stock\|status.*active.*stock" "$SCAN_PATH" --include="*.js" 2>/dev/null | grep -v "//")
if [ -n "$RESTORE_ACTIVE" ]; then
  echo "  ✅ Có logic restore status='active' khi hoàn kho"
else
  echo "  ⚠️  Chưa thấy logic restore status='active' sau khi hoàn kho"
fi

echo ""
echo "============================================="
if [ $ISSUES -gt 0 ]; then
  echo "  ❌ $ISSUES inventory rules bị vi phạm"
  exit 1
else
  echo "  ✅ Inventory rules đúng"
  exit 0
fi
echo "============================================="
