#!/bin/bash
# HOOK 02 — Security Audit
# Quét code tìm lỗi bảo mật phổ biến
# Usage: bash hooks/hook-02-security.sh [path]

SCAN_PATH=${1:-"src"}
echo "============================================="
echo "  SECURITY HOOK — Scanning: $SCAN_PATH"
echo "============================================="

ISSUES=0

warn() {
  echo "  🚨 $1"
  echo "     → $2"
  ((ISSUES++))
}

info() {
  echo "  ℹ️  $1"
}

echo ""
echo "[ PLAIN PASSWORD CHECK ]"
if grep -rn "password" "$SCAN_PATH" --include="*.js" | grep -v "password_hash\|bcrypt\|compare\|hash\|//\|#\|\.md" | grep -i "INSERT\|UPDATE\|password.*=.*req\." > /dev/null 2>&1; then
  warn "Có thể lưu plain password" "Kiểm tra: grep -rn 'password' $SCAN_PATH --include='*.js'"
else
  echo "  ✅ Không phát hiện plain password insert"
fi

echo ""
echo "[ SQL INJECTION CHECK ]"
SQLI=$(grep -rn "query\s*(\s*[\`'\"].*\+\|query\s*(\s*\`.*\${" "$SCAN_PATH" --include="*.js" 2>/dev/null | grep -v "//")
if [ -n "$SQLI" ]; then
  warn "Nối string trong SQL query" "Các dòng nghi vấn:"
  echo "$SQLI" | head -5 | while read line; do echo "     $line"; done
else
  echo "  ✅ Không phát hiện string concatenation trong SQL"
fi

echo ""
echo "[ XSS CHECK ]"
XSS=$(grep -rn "<%-" "$SCAN_PATH/views" --include="*.ejs" 2>/dev/null | grep -v "include\|partial\|layout\|//\|body\|content")
if [ -n "$XSS" ]; then
  echo "  ⚠️  Tìm thấy <%- (unescaped output) — kiểm tra thủ công:"
  echo "$XSS" | head -10 | while read line; do echo "     $line"; done
  info "<%- chỉ dùng cho include, layout body, hoặc HTML đã sanitize"
else
  echo "  ✅ Không có unescaped output đáng ngờ"
fi

echo ""
echo "[ ENV VARIABLE CHECK ]"
ENV_EXPOSED=$(grep -rn "process\.env\." "$SCAN_PATH/views" --include="*.ejs" 2>/dev/null)
if [ -n "$ENV_EXPOSED" ]; then
  warn "process.env dùng trong view template" "Không expose biến môi trường ra client"
  echo "$ENV_EXPOSED" | head -5 | while read line; do echo "     $line"; done
else
  echo "  ✅ Không expose process.env trong views"
fi

echo ""
echo "[ HARDCODED CREDENTIALS CHECK ]"
HARDCODED=$(grep -rn "password\s*=\s*['\"].\{4,\}['\"]" "$SCAN_PATH" --include="*.js" 2>/dev/null | grep -v "//\|test\|spec\|placeholder\|hash\|mock")
if [ -n "$HARDCODED" ]; then
  warn "Có thể hardcode password/secret" "Dùng process.env thay vì hardcode"
  echo "$HARDCODED" | head -5 | while read line; do echo "     $line"; done
else
  echo "  ✅ Không phát hiện hardcoded credentials"
fi

echo ""
echo "[ UPLOAD MIME CHECK ]"
UPLOAD_NO_FILTER=$(grep -rn "multer\|diskStorage" "$SCAN_PATH" --include="*.js" 2>/dev/null | grep -v "fileFilter\|mimetype")
if [ -n "$UPLOAD_NO_FILTER" ]; then
  warn "Upload middleware có thể thiếu fileFilter" "Thêm fileFilter kiểm tra mimetype"
else
  echo "  ✅ Upload middleware có fileFilter"
fi

echo ""
echo "[ ADMIN ROUTE CHECK ]"
ADMIN_ROUTES=$(grep -rn "router\.\(get\|post\|put\|patch\|delete\)" "$SCAN_PATH/routes/admin.routes.js" 2>/dev/null | wc -l)
ADMIN_AUTH=$(grep -rn "requireAdmin\|router.use(requireAdmin" "$SCAN_PATH/routes/admin.routes.js" 2>/dev/null | wc -l)
if [ "$ADMIN_AUTH" -gt 0 ]; then
  echo "  ✅ Admin routes có requireAdmin middleware ($ADMIN_AUTH occurrences)"
else
  warn "Admin routes có thể thiếu requireAdmin" "Thêm router.use(requireAdmin) đầu admin.routes.js"
fi

echo ""
echo "============================================="
if [ $ISSUES -gt 0 ]; then
  echo "  ⚠️  $ISSUES vấn đề cần xem xét"
else
  echo "  ✅ Security check passed — $ISSUES issues"
fi
echo "============================================="
