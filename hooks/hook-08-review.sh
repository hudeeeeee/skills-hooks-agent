#!/bin/bash
# HOOK 08 — Review Permission Validator
# Kiểm tra quy tắc phân quyền đánh giá sản phẩm
# Usage: bash hooks/hook-08-review.sh

echo "============================================="
echo "  REVIEW PERMISSION HOOK"
echo "============================================="

SCAN_PATH="src"
ISSUES=0

echo ""
echo "[ RULE 1 — Chỉ review sau khi order completed ]"
REVIEW_SVC="$SCAN_PATH/services/review.service.js"
if [ -f "$REVIEW_SVC" ]; then
  if grep -q "completed\|order_status.*=.*'completed'" "$REVIEW_SVC" 2>/dev/null; then
    echo "  ✅ review.service — check order_status = completed"
  else
    echo "  ❌ review.service — THIẾU check order_status = completed"
    ((ISSUES++))
  fi
fi

echo ""
echo "[ RULE 2 — Product phải thuộc order đó ]"
if [ -f "$REVIEW_SVC" ]; then
  if grep -q "order_items\|product_id.*order_id\|thuộc.*đơn\|order.*product" "$REVIEW_SVC" 2>/dev/null; then
    echo "  ✅ review.service — check product trong order"
  else
    echo "  ❌ review.service — THIẾU check product nằm trong order"
    ((ISSUES++))
  fi
fi

echo ""
echo "[ RULE 3 — Không review 2 lần cùng product + order ]"
if [ -f "$REVIEW_SVC" ]; then
  if grep -q "UNIQUE\|đã đánh giá\|already\|existing\|duplicate" "$REVIEW_SVC" 2>/dev/null; then
    echo "  ✅ review.service — check duplicate review"
  else
    # Kiểm tra schema
    if [ -f "database/schema.sql" ] && grep -q "UNIQUE.*user_id.*product_id\|uq_user_product" "database/schema.sql" 2>/dev/null; then
      echo "  ✅ schema.sql — UNIQUE(user_id, product_id, order_id) trong reviews"
    else
      echo "  ❌ Thiếu check hoặc UNIQUE constraint để ngăn duplicate review"
      ((ISSUES++))
    fi
  fi
fi

echo ""
echo "[ RULE 4 — Rating validate 1-5 ]"
if [ -f "$REVIEW_SVC" ]; then
  if grep -q "rating.*1\|rating.*5\|rating.*<\|rating.*>\|BETWEEN\|between" "$REVIEW_SVC" 2>/dev/null; then
    echo "  ✅ review.service — validate rating 1-5"
  else
    echo "  ❌ review.service — THIẾU validate rating range 1-5"
    ((ISSUES++))
  fi
fi

echo ""
echo "[ RULE 5 — Cập nhật avg_rating sau review ]"
if [ -f "$REVIEW_SVC" ]; then
  if grep -q "avg_rating\|AVG.*rating\|review_count" "$REVIEW_SVC" 2>/dev/null; then
    echo "  ✅ review.service — cập nhật avg_rating sau khi tạo review"
  else
    echo "  ❌ review.service — THIẾU cập nhật avg_rating sau review"
    ((ISSUES++))
  fi
fi

echo ""
echo "[ RULE 6 — Recalculate avg_rating khi admin ẩn review ]"
if [ -f "$REVIEW_SVC" ]; then
  ADMIN_HIDE=$(grep -n "setReviewStatus\|status.*hidden\|hidden.*avg\|avg.*hidden" "$REVIEW_SVC" 2>/dev/null | head -3)
  if [ -n "$ADMIN_HIDE" ]; then
    AVG_RECALC=$(grep -n "avg_rating\|AVG" "$REVIEW_SVC" 2>/dev/null | tail -3)
    if [ -n "$AVG_RECALC" ]; then
      echo "  ✅ review.service — recalculate avg_rating khi admin ẩn review"
    else
      echo "  ❌ review.service — THIẾU recalculate avg_rating khi ẩn review"
      ((ISSUES++))
    fi
  fi
fi

echo ""
echo "[ RULE 7 — requireAuth trên route /reviews ]"
REVIEW_ROUTES=$(find "$SCAN_PATH/routes" -name "*.js" 2>/dev/null | xargs grep -l "reviews\|review" 2>/dev/null)
for rf in $REVIEW_ROUTES; do
  name=$(basename "$rf")
  if grep -q "reviews\|review" "$rf" 2>/dev/null; then
    if grep -q "requireAuth" "$rf" 2>/dev/null; then
      echo "  ✅ $name — review routes có requireAuth"
    else
      echo "  ❌ $name — review route thiếu requireAuth"
      ((ISSUES++))
    fi
  fi
done

echo ""
echo "[ RULE 8 — Chỉ visible reviews tính avg_rating ]"
if [ -f "$REVIEW_SVC" ]; then
  if grep -q "status.*visible\|visible.*status\|status = 'visible'" "$REVIEW_SVC" 2>/dev/null; then
    echo "  ✅ review.service — AVG chỉ tính visible reviews"
  else
    echo "  ⚠️  review.service — kiểm tra WHERE status = 'visible' trong AVG query"
  fi
fi

echo ""
echo "============================================="
if [ $ISSUES -gt 0 ]; then
  echo "  ❌ $ISSUES review permission rules bị vi phạm"
  exit 1
else
  echo "  ✅ Review permission rules đúng"
  exit 0
fi
echo "============================================="
