#!/bin/bash
# HOOK 01 — Pre-build Checklist
# Chạy trước khi bắt đầu bất kỳ skill nào
# Usage: bash hooks/hook-01-prebuild.sh <skill-number>

SKILL=${1:-"?"}
echo "============================================="
echo "  PRE-BUILD HOOK — Skill $SKILL"
echo "============================================="

PASS=0
FAIL=0

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" > /dev/null 2>&1; then
    echo "  ✅ $desc"
    ((PASS++))
  else
    echo "  ❌ $desc"
    ((FAIL++))
  fi
}

echo ""
echo "[ PROJECT STRUCTURE ]"
check ".env file exists"        "[ -f .env ]"
check ".env.example exists"     "[ -f .env.example ]"
check "app.js exists"           "[ -f app.js ]"
check "server.js exists"        "[ -f server.js ]"
check "src/ directory exists"   "[ -d src ]"
check "public/ directory exists" "[ -d public ]"
check "database/ directory exists" "[ -d database ]"

echo ""
echo "[ NODE DEPENDENCIES ]"
check "node_modules exists"     "[ -d node_modules ]"
check "express installed"       "[ -d node_modules/express ]"
check "mysql2 installed"        "[ -d node_modules/mysql2 ]"
check "bcrypt installed"        "[ -d node_modules/bcrypt ]"
check "express-session installed" "[ -d node_modules/express-session ]"
check "ejs installed"           "[ -d node_modules/ejs ]"
check "multer installed"        "[ -d node_modules/multer ]"
check "dotenv installed"        "[ -d node_modules/dotenv ]"

echo ""
echo "[ DATABASE ]"
check "schema.sql exists"       "[ -f database/schema.sql ]"
check "seed.sql exists"         "[ -f database/seed.sql ]"

echo ""
echo "[ MIDDLEWARES ]"
check "auth middleware exists"  "[ -f src/middlewares/auth.middleware.js ]"
check "admin middleware exists" "[ -f src/middlewares/admin.middleware.js ]"
check "upload middleware exists" "[ -f src/middlewares/upload.middleware.js ]"
check "error middleware exists"  "[ -f src/middlewares/error.middleware.js ]"

echo ""
echo "[ VIEWS ]"
check "layouts/main.ejs exists" "[ -f src/views/layouts/main.ejs ]"
check "layouts/admin.ejs exists" "[ -f src/views/layouts/admin.ejs ]"
check "partials/navbar.ejs"     "[ -f src/views/partials/navbar.ejs ]"
check "partials/flash.ejs"      "[ -f src/views/partials/flash.ejs ]"
check "errors/404.ejs"          "[ -f src/views/errors/404.ejs ]"
check "errors/403.ejs"          "[ -f src/views/errors/403.ejs ]"

echo ""
echo "============================================="
echo "  RESULT: $PASS passed, $FAIL failed"
echo "============================================="
if [ $FAIL -gt 0 ]; then
  echo "  ⚠️  Hoàn thiện các mục FAIL trước khi code Skill $SKILL"
  exit 1
else
  echo "  ✅ Sẵn sàng build Skill $SKILL"
  exit 0
fi
