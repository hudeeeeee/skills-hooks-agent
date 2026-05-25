#!/bin/bash
# HOOK 04 — UI Consistency Check
# Kiểm tra các view có đủ yếu tố UI cần thiết
# Usage: bash hooks/hook-04-ui.sh [views-path]

VIEWS=${1:-"src/views"}
echo "============================================="
echo "  UI CONSISTENCY HOOK — $VIEWS"
echo "============================================="

ISSUES=0

check_view() {
  local file="$1"
  local checks=("${@:2}")
  local name=$(basename "$file")
  local file_issues=0

  for check in "${checks[@]}"; do
    local pattern="${check%%|*}"
    local desc="${check##*|}"
    if ! grep -q "$pattern" "$file" 2>/dev/null; then
      echo "  ⚠️  $name: thiếu $desc"
      ((file_issues++))
      ((ISSUES++))
    fi
  done

  if [ $file_issues -eq 0 ]; then
    echo "  ✅ $name"
  fi
}

echo ""
echo "[ LAYOUT FILES ]"
check_view "$VIEWS/layouts/main.ejs" \
  "bootstrap|Bootstrap|CDN|Tailwind|stylesheet|PASS|css" \
  "CSS framework" \
  "navbar\|header\|include" \
  "navbar/header include" \
  "flash\|include.*flash" \
  "flash message include" \
  "bootstrap.bundle\|bootstrap.min.js\|/js/main" \
  "JS include"

check_view "$VIEWS/layouts/admin.ejs" \
  "sidebar\|nav-link\|admin" \
  "sidebar navigation" \
  "dashboard\|products\|orders\|users" \
  "admin menu items" \
  "flash\|include.*flash" \
  "flash message include"

echo ""
echo "[ PARTIALS ]"
for partial in navbar flash footer breadcrumb pagination; do
  if [ -f "$VIEWS/partials/$partial.ejs" ]; then
    echo "  ✅ partials/$partial.ejs"
  else
    echo "  ❌ partials/$partial.ejs MISSING"
    ((ISSUES++))
  fi
done

echo ""
echo "[ EMPTY STATES — trang có danh sách ]"
LIST_VIEWS=(
  "$VIEWS/pages/products/index.ejs"
  "$VIEWS/pages/cart.ejs"
  "$VIEWS/pages/orders/index.ejs"
)
for view in "${LIST_VIEWS[@]}"; do
  if [ -f "$view" ]; then
    name=$(basename "$view")
    if grep -q "length === 0\|\.length == 0\|empty\|Trống\|trống\|Không có\|không có" "$view" 2>/dev/null; then
      echo "  ✅ $name — có empty state"
    else
      echo "  ⚠️  $name — thiếu empty state"
      ((ISSUES++))
    fi
  fi
done

echo ""
echo "[ LOADING STATE — form submit ]"
FORM_VIEWS=$(find "$VIEWS" -name "*.ejs" 2>/dev/null | xargs grep -l "method=\"POST\"\|method='POST'" 2>/dev/null)
for view in $FORM_VIEWS; do
  name=$(basename "$view")
  if grep -q "disabled\|loading\|spinner\|btn-loading\|data-no-loading" "$view" 2>/dev/null; then
    echo "  ✅ $name — form có loading protection"
  else
    echo "  ℹ️  $name — xem xét thêm loading state (main.js auto-handles)"
  fi
done

echo ""
echo "[ RESPONSIVE — viewport meta ]"
LAYOUT_FILES=$(find "$VIEWS/layouts" -name "*.ejs" 2>/dev/null)
for layout in $LAYOUT_FILES; do
  name=$(basename "$layout")
  if grep -q "viewport\|width=device-width" "$layout" 2>/dev/null; then
    echo "  ✅ $name — có viewport meta"
  else
    echo "  ❌ $name — thiếu viewport meta tag"
    ((ISSUES++))
  fi
done

echo ""
echo "[ CURRENCY FORMAT — kiểm tra format đúng ]"
FORMAT_ISSUES=$(grep -rn "\.price\b\|\.total\b\|\.amount\b\|\.subtotal\b" "$VIEWS" --include="*.ejs" 2>/dev/null | grep -v "toLocaleString\|formatCurrency\|//\|name\|type\|placeholder" | head -5)
if [ -n "$FORMAT_ISSUES" ]; then
  echo "  ⚠️  Một số giá trị tiền có thể chưa format:"
  echo "$FORMAT_ISSUES" | while read line; do echo "     $line"; done
  ((ISSUES++))
else
  echo "  ✅ Giá tiền được format đúng"
fi

echo ""
echo "[ IMAGE FALLBACK ]"
IMG_NO_FALLBACK=$(grep -rn "<img" "$VIEWS" --include="*.ejs" 2>/dev/null | grep -v "onerror\|no-image\|//" | head -5)
if [ -n "$IMG_NO_FALLBACK" ]; then
  echo "  ℹ️  Một số img tag chưa có onerror fallback:"
  echo "$IMG_NO_FALLBACK" | head -3 | while read line; do echo "     $line"; done
else
  echo "  ✅ Img tags có fallback"
fi

echo ""
echo "============================================="
if [ $ISSUES -gt 0 ]; then
  echo "  ⚠️  $ISSUES UI issues cần xem xét"
else
  echo "  ✅ UI consistency check passed"
fi
echo "============================================="
