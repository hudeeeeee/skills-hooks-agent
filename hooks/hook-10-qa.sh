#!/bin/bash
# HOOK 10 — Final QA Checklist
# Chạy sau khi hoàn thành mỗi skill
# Usage: bash hooks/hook-10-qa.sh <skill-number>

SKILL=${1:-"?"}
echo "============================================="
echo "  FINAL QA HOOK — Skill $SKILL Complete"
echo "============================================="

SCAN_PATH="src"
PASS=0
FAIL=0
WARN=0

ok()   { echo "  ✅ $1"; ((PASS++)); }
fail() { echo "  ❌ $1"; ((FAIL++)); }
warn() { echo "  ⚠️  $1"; ((WARN++)); }

echo ""
echo "[ ROUTES — tồn tại và đúng cấu trúc ]"

check_route_file() {
  local file="$SCAN_PATH/routes/$1"
  if [ -f "$file" ]; then
    ok "$1 exists"
  else
    fail "$1 MISSING"
  fi
}

check_route_file "index.routes.js"
check_route_file "auth.routes.js"
check_route_file "product.routes.js"
check_route_file "cart.routes.js"
check_route_file "order.routes.js"
check_route_file "payment.routes.js"
check_route_file "review.routes.js"
check_route_file "admin.routes.js"

echo ""
echo "[ CONTROLLERS ]"
for ctrl in auth product cart order payment review warranty; do
  if [ -f "$SCAN_PATH/controllers/$ctrl.controller.js" ]; then
    ok "$ctrl.controller.js"
  else
    warn "$ctrl.controller.js chưa tồn tại (cần nếu dùng)"
  fi
done

for admin_ctrl in dashboard product order user review; do
  if [ -d "$SCAN_PATH/controllers/admin" ]; then
    ok "admin/ directory"
    break
  fi
done

echo ""
echo "[ SERVICES ]"
for svc in auth product cart order payment review warranty admin; do
  if [ -f "$SCAN_PATH/services/$svc.service.js" ]; then
    ok "$svc.service.js"
  else
    warn "$svc.service.js chưa tồn tại"
  fi
done

echo ""
echo "[ VIEWS — critical pages ]"
REQUIRED_VIEWS=(
  "pages/home.ejs"
  "pages/products/index.ejs"
  "pages/products/detail.ejs"
  "pages/cart.ejs"
  "pages/checkout.ejs"
  "pages/orders/index.ejs"
  "pages/orders/detail.ejs"
  "auth/login.ejs"
  "auth/register.ejs"
  "errors/404.ejs"
  "errors/403.ejs"
  "errors/500.ejs"
  "admin/dashboard.ejs"
  "admin/products/index.ejs"
  "admin/orders/index.ejs"
  "admin/orders/detail.ejs"
  "admin/users/index.ejs"
  "admin/reviews/index.ejs"
)
for view in "${REQUIRED_VIEWS[@]}"; do
  if [ -f "$SCAN_PATH/views/$view" ]; then
    ok "views/$view"
  else
    warn "views/$view chưa tồn tại"
  fi
done

echo ""
echo "[ SECURITY ]"

# bcrypt
BCRYPT=$(grep -rn "bcrypt\|password\.hash\|password\.compare" "$SCAN_PATH/services/auth.service.js" 2>/dev/null | head -1)
[ -n "$BCRYPT" ] && ok "bcrypt dùng trong auth.service" || fail "auth.service THIẾU bcrypt"

# Không lưu plain password
PLAIN_PASS=$(grep -rn "INSERT.*password\b" "$SCAN_PATH" --include="*.js" 2>/dev/null | grep -v "hash\|bcrypt\|//" | head -1)
[ -z "$PLAIN_PASS" ] && ok "Không thấy INSERT plain password" || fail "Có thể INSERT plain password"

# Admin middleware
[ -f "$SCAN_PATH/middlewares/admin.middleware.js" ] && ok "admin.middleware.js tồn tại" || fail "admin.middleware.js MISSING"
[ -f "$SCAN_PATH/middlewares/auth.middleware.js" ]  && ok "auth.middleware.js tồn tại"  || fail "auth.middleware.js MISSING"

echo ""
echo "[ DATABASE ]"
[ -f "database/schema.sql" ] && ok "schema.sql" || fail "schema.sql MISSING"
[ -f "database/seed.sql" ]   && ok "seed.sql"   || fail "seed.sql MISSING"

# Transaction cho createOrder
if [ -f "$SCAN_PATH/services/order.service.js" ]; then
  TRANS=$(grep -c "beginTransaction" "$SCAN_PATH/services/order.service.js" 2>/dev/null || echo 0)
  [ "$TRANS" -gt 0 ] && ok "order.service — dùng transaction" || fail "order.service — THIẾU transaction"
fi

echo ""
echo "[ .ENV & CONFIG ]"
[ -f ".env" ]         && ok ".env file"         || fail ".env file MISSING"
[ -f ".env.example" ] && ok ".env.example"       || fail ".env.example MISSING"
[ -f "app.js" ]       && ok "app.js"             || fail "app.js MISSING"
[ -f "server.js" ]    && ok "server.js"          || fail "server.js MISSING"
[ -f "README.md" ]    && ok "README.md"          || warn "README.md chưa có"

# .env trong gitignore
if [ -f ".gitignore" ]; then
  grep -q "\.env$\|\.env\b" ".gitignore" 2>/dev/null && ok ".env trong .gitignore" || warn ".env chưa trong .gitignore"
else
  warn ".gitignore chưa tồn tại"
fi

echo ""
echo "[ STATIC ASSETS ]"
[ -f "public/css/style.css" ]  && ok "public/css/style.css"  || warn "style.css chưa tạo"
[ -f "public/css/admin.css" ]  && ok "public/css/admin.css"  || warn "admin.css chưa tạo"
[ -f "public/js/main.js" ]     && ok "public/js/main.js"     || warn "main.js chưa tạo"
[ -f "public/js/cart.js" ]     && ok "public/js/cart.js"     || warn "cart.js chưa tạo"
[ -d "public/uploads" ]        && ok "public/uploads dir"    || warn "public/uploads chưa tạo"

echo ""
echo "[ SKILL-SPECIFIC CHECK ]"
case $SKILL in
  01) echo "  → Skill 01: Chạy 'node server.js' để xác nhận startup OK" ;;
  02) echo "  → Skill 02: Chạy 'mysql < database/schema.sql' và 'mysql < database/seed.sql'" ;;
  03) echo "  → Skill 03: Test register + login + logout manual" ;;
  04) echo "  → Skill 04: GET /products + search + filter + chi tiết" ;;
  05) echo "  → Skill 05: Add to cart + update + delete, kiểm tra AJAX" ;;
  06) echo "  → Skill 06: Đặt đơn COD, kiểm tra order_items + payment" ;;
  07) echo "  → Skill 07: Bank info page + VNPay URL tạo đúng" ;;
  08) echo "  → Skill 08: Tạo review sau order completed, check avg_rating" ;;
  09) echo "  → Skill 09: Gửi bảo hành, admin cập nhật status" ;;
  10) echo "  → Skill 10: Admin dashboard, CRUD sản phẩm, cập nhật đơn" ;;
  11) echo "  → Skill 11: Test responsive 375px, empty states, flash" ;;
  12) echo "  → Skill 12: Route audit hoàn chỉnh, security headers" ;;
esac

echo ""
echo "[ RUNNING ALL HOOKS ]"
echo "  → bash hooks/hook-02-security.sh"
echo "  → bash hooks/hook-03-transaction.sh"
echo "  → bash hooks/hook-05-order-state.sh"
echo "  → bash hooks/hook-06-inventory.sh"

echo ""
echo "============================================="
echo "  RESULT: ✅ $PASS passed | ❌ $FAIL failed | ⚠️  $WARN warnings"
echo "============================================="
if [ $FAIL -gt 0 ]; then
  echo "  FIX $FAIL issues trước khi chuyển sang skill tiếp theo"
  exit 1
elif [ $WARN -gt 5 ]; then
  echo "  Nhiều warnings — review lại trước khi tiếp tục"
  exit 0
else
  echo "  Skill $SKILL hoàn thành — sẵn sàng skill tiếp theo"
  exit 0
fi
