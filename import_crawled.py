"""
import_crawled.py
Đọc products_raw.json → insert vào DB electronics_shop
→ append vào database/seed.sql (cả datn/ lẫn website/)
"""

import json
import re
import subprocess
import os

# ── Config ──────────────────────────────────────────────────────────────────
DB_USER   = 'admin123'
DB_PASS   = 'admin123'
DB_NAME   = 'electronics_shop'
JSON_SRC  = '/mnt/c/Users/Admin/datn/products_raw.json'
SEED_PATHS = [
    '/mnt/c/Users/Admin/OneDrive/Attachments/website/database/seed.sql',
    '/mnt/c/Users/Admin/datn/database/seed.sql',
]

# category_id trong crawler → category_id thực trong DB
CATEGORY_FIX = {1: 4, 2: 5}  # mobile→Điện thoại(4), laptop→Laptop(5)

START_ID = 59   # MAX(id) hiện tại = 58

# ── Helpers ──────────────────────────────────────────────────────────────────

def esc(val):
    """Escape string cho MySQL single-quote."""
    if val is None:
        return 'NULL'
    return "'" + str(val).replace('\\', '\\\\').replace("'", "\\'") + "'"

def run_sql(sql: str):
    """Chạy SQL block qua mysql CLI."""
    result = subprocess.run(
        ['mysql', f'-u{DB_USER}', f'-p{DB_PASS}', DB_NAME],
        input=sql.encode('utf-8'),
        capture_output=True,
    )
    if result.returncode != 0:
        err = result.stderr.decode('utf-8', errors='replace')
        # Ignore warning về password trên CLI
        lines = [l for l in err.splitlines() if 'password' not in l.lower() and l.strip()]
        if lines:
            raise RuntimeError('\n'.join(lines))

def get_existing_slugs() -> set:
    result = subprocess.run(
        ['mysql', f'-u{DB_USER}', f'-p{DB_PASS}', DB_NAME, '-sN',
         '-e', 'SELECT slug FROM products;'],
        capture_output=True,
    )
    return set(result.stdout.decode('utf-8').splitlines())

# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    os.makedirs('/mnt/c/Users/Admin/datn/database', exist_ok=True)

    with open(JSON_SRC, encoding='utf-8') as f:
        raw = json.load(f)

    existing_slugs = get_existing_slugs()
    print(f'Existing slugs in DB: {len(existing_slugs)}')

    product_rows  = []
    image_rows    = []
    seen_slugs    = set(existing_slugs)   # track within this batch too

    current_id = START_ID

    for p in raw:
        # ── Category fix ──
        cat_id = CATEGORY_FIX.get(p['category_id'], p['category_id'])

        # ── Slug dedup ──
        slug = p['slug'][:220]
        if slug in seen_slugs:
            base = slug[:210]
            suffix = 1
            while f'{base}-{suffix}' in seen_slugs:
                suffix += 1
            slug = f'{base}-{suffix}'
        seen_slugs.add(slug)

        # ── SKU dedup (NULL nếu conflict) ──
        sku = p.get('sku')

        # ── Truncate image_url nếu > 255 ──
        images = [img[:255] for img in (p.get('images') or []) if img]

        # ── Product row ──
        pid = current_id
        product_rows.append(
            f"({pid}, {cat_id}, {esc(p['name'][:200])}, {esc(slug)}, "
            f"{esc(p.get('brand'))}, {esc(sku)}, "
            f"{p['price']}, "
            f"{'NULL' if not p.get('sale_price') else p['sale_price']}, "
            f"{p.get('stock_quantity', 20)}, "
            f"{esc(p.get('description'))}, "
            f"{esc(p.get('specifications'))}, "
            f"{p.get('warranty_months', 12)}, 'active')"
        )

        # ── Image rows ──
        for i, url in enumerate(images):
            is_main = 1 if i == 0 else 0
            image_rows.append(f"({pid}, {esc(url)}, {is_main}, {i})")

        current_id += 1

    total_products = current_id - START_ID
    print(f'Products to insert: {total_products}')
    print(f'Images to insert:   {len(image_rows)}')

    if not product_rows:
        print('Nothing to insert.')
        return

    # ── Build SQL ────────────────────────────────────────────────────────────
    product_cols = (
        'id, category_id, name, slug, brand, sku, price, sale_price, '
        'stock_quantity, description, specifications, warranty_months, status'
    )

    product_sql = (
        f'INSERT INTO products ({product_cols}) VALUES\n'
        + ',\n'.join(product_rows) + ';\n'
    )

    image_sql = ''
    if image_rows:
        image_sql = (
            'INSERT INTO product_images (product_id, image_url, is_main, sort_order) VALUES\n'
            + ',\n'.join(image_rows) + ';\n'
        )

    block = (
        '\n-- ============================================================\n'
        '-- Crawled products from cellphones.com.vn (import_crawled.py)\n'
        '-- Điện thoại category_id=4, Laptop category_id=5\n'
        f'-- {total_products} products, {len(image_rows)} images\n'
        '-- ============================================================\n'
        + product_sql
        + ('\n' + image_sql if image_sql else '')
    )

    # ── Insert vào DB ────────────────────────────────────────────────────────
    print('\nInserting into DB...')
    try:
        run_sql(block)
        print(f'✓ Inserted {total_products} products, {len(image_rows)} images into DB.')
    except RuntimeError as e:
        print(f'✗ DB insert failed:\n{e}')
        return

    # ── Verify ───────────────────────────────────────────────────────────────
    result = subprocess.run(
        ['mysql', f'-u{DB_USER}', f'-p{DB_PASS}', DB_NAME, '-sN',
         '-e', 'SELECT COUNT(*) FROM products;'],
        capture_output=True,
    )
    total = result.stdout.decode().strip()
    print(f'✓ Total products in DB now: {total}')

    # ── Append vào seed.sql ──────────────────────────────────────────────────
    for seed_path in SEED_PATHS:
        os.makedirs(os.path.dirname(seed_path), exist_ok=True)
        mode = 'a' if os.path.exists(seed_path) else 'w'
        with open(seed_path, 'a', encoding='utf-8') as f:
            f.write(block)
        print(f'✓ Appended to {seed_path}')

    print('\nDone.')

if __name__ == '__main__':
    main()
