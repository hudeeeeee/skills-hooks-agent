#!/bin/bash
# HOOK 09 — Admin Permission Validator
# Kiểm tra tất cả admin routes được bảo vệ đúng
# Usage: bash hooks/hook-09-admin.sh

echo "============================================="
echo "  ADMIN PERMISSION HOOK"
echo "============================================="

SCAN_PATH="src"
ISSUES=0

echo ""
echo "[ requireAdmin middleware implementation ]"
ADMIN_MW="$SCAN_PATH/middlewares/admin.middleware.js"
if [ -f "$ADMIN_MW" ]; then
  if grep -q "role.*admin\|user.role\|requireAdmin" "$ADMIN_MW" 2>/dev/null; then
    echo "  ✅ admin.middleware.js — có kiểm tra role = admin"
    if grep -q "session.user\|req.session" "$ADMIN_MW" 2>/dev/null; then
      echo "  ✅ Lấy role từ session (không từ query/body)"
    else
      echo "  ❌ Middleware không lấy role từ session!"
      ((ISSUES++))
    fi
  else
    echo "  ❌ admin.middleware.js — THIẾU kiểm tra role"
    ((ISSUES++))
  fi
else
  echo "  ❌ admin.middleware.js không tồn tại"
  ((ISSUES++))
fi

echo ""
echo "[ admin.routes.js — có router.use(requireAdmin) ]"
ADMIN_ROUTES="$SCAN_PATH/routes/admin.routes.js"
if [ -f "$ADMIN_ROUTES" ]; then
  # Kiểm tra router.use(requireAdmin) hoặc middleware trên mỗi route
  GLOBAL_PROTECT=$(grep -n "router\.use.*requireAdmin\|app\.use.*admin.*requireAdmin" "$ADMIN_ROUTES" 2>/dev/null | head -1)
  if [ -n "$GLOBAL_PROTECT" ]; then
    echo "  ✅ Global requireAdmin: $GLOBAL_PROTECT"
  else
    # Kiểm tra từng route có requireAdmin không
    TOTAL_ROUTES=$(grep -c "router\.\(get\|post\|put\|patch\|delete\)" "$ADMIN_ROUTES" 2>/dev/null || echo 0)
    PROTECTED_ROUTES=$(grep -c "requireAdmin" "$ADMIN_ROUTES" 2>/dev/null || echo 0)
    echo "  ℹ️  $TOTAL_ROUTES routes, $PROTECTED_ROUTES có requireAdmin"
    if [ "$PROTECTED_ROUTES" -lt "$TOTAL_ROUTES" ] && [ "$PROTECTED_ROUTES" -eq 0 ]; then
      echo "  ❌ Không có route nào có requireAdmin!"
      ((ISSUES++))
    fi
  fi
else
  echo "  ⏭️  admin.routes.js chưa tồn tại"
fi

echo ""
echo "[ index.routes.js — mount admin routes với /admin prefix ]"
INDEX_ROUTES="$SCAN_PATH/routes/index.routes.js"
if [ -f "$INDEX_ROUTES" ]; then
  if grep -q "/admin.*admin.routes\|admin.*routes.*admin" "$INDEX_ROUTES" 2>/dev/null; then
    echo "  ✅ Admin routes được mount tại /admin"
  else
    echo "  ❌ Admin routes không được mount đúng trong index.routes.js"
    ((ISSUES++))
  fi
fi

echo ""
echo "[ 403 error page exists ]"
if [ -f "$SCAN_PATH/views/errors/403.ejs" ]; then
  echo "  ✅ errors/403.ejs tồn tại"
else
  echo "  ❌ errors/403.ejs thiếu"
  ((ISSUES++))
fi

echo ""
echo "[ Admin không thể block admin account ]"
if [ -f "$ADMIN_ROUTES" ]; then
  USER_STATUS=$(grep -n "users.*status\|status.*user\|block\|admin.*role" "$ADMIN_ROUTES" 2>/dev/null | head -3)
  if grep -q "role.*customer\|role.*=.*customer\|AND role" "$ADMIN_ROUTES" 2>/dev/null; then
    echo "  ✅ User status route — có filter role = customer"
  else
    echo "  ⚠️  Kiểm tra thủ công: route /admin/users/:id/status phải có WHERE role = 'customer'"
  fi
fi

echo ""
echo "[ Admin session — không trust role từ body/query ]"
ALL_ADMIN=$(find "$SCAN_PATH" -name "*.js" 2>/dev/null | xargs grep -l "req.body.role\|req.query.role" 2>/dev/null)
if [ -n "$ALL_ADMIN" ]; then
  echo "  ⚠️  Tìm thấy req.body.role hoặc req.query.role — không dùng để phân quyền:"
  echo "$ALL_ADMIN" | while read f; do echo "     $f"; done
  echo "     → Phân quyền chỉ từ req.session.user.role"
else
  echo "  ✅ Role không được lấy từ body/query"
fi

echo ""
echo "[ Admin views không accessible qua direct URL ]"
ADMIN_VIEWS="$SCAN_PATH/views/admin"
if [ -d "$ADMIN_VIEWS" ]; then
  ADMIN_VIEW_COUNT=$(find "$ADMIN_VIEWS" -name "*.ejs" 2>/dev/null | wc -l)
  echo "  ℹ️  $ADMIN_VIEW_COUNT admin views (bảo vệ bởi requireAdmin middleware)"
fi

echo ""
echo "============================================="
if [ $ISSUES -gt 0 ]; then
  echo "  ❌ $ISSUES admin permission issues"
  exit 1
else
  echo "  ✅ Admin permission đúng"
  exit 0
fi
echo "============================================="
