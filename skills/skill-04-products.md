# SKILL 04 — Product Catalog

## Mục tiêu
Trang chủ, danh sách sản phẩm, tìm kiếm, lọc, phân trang, chi tiết sản phẩm.

## Files cần tạo
```
src/controllers/product.controller.js
src/services/product.service.js
src/routes/product.routes.js
src/views/pages/home.ejs
src/views/pages/products/index.ejs
src/views/pages/products/detail.ejs
src/views/partials/product-card.ejs
src/views/partials/pagination.ejs
```

---

## Bước 1 — product.service.js

```javascript
const pool = require('../config/database');
const { paginate } = require('../utils/paginate');

// Base query lấy sản phẩm kèm ảnh chính
const BASE_PRODUCT_SQL = `
  SELECT p.*, c.name AS category_name, c.slug AS category_slug,
         pi.image_url AS main_image
  FROM products p
  JOIN categories c ON p.category_id = c.id
  LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
  WHERE p.status != 'inactive'
`;

async function getProducts({ keyword, category, brand, minPrice, maxPrice,
                              onSale, inStock, sort = 'newest', page = 1 }) {
  const where = ['p.status != "inactive"'];
  const params = [];

  if (keyword) {
    where.push('(p.name LIKE ? OR p.brand LIKE ?)');
    params.push(`%${keyword}%`, `%${keyword}%`);
  }
  if (category) { where.push('c.slug = ?'); params.push(category); }
  if (brand) { where.push('p.brand = ?'); params.push(brand); }
  if (minPrice) { where.push('COALESCE(p.sale_price, p.price) >= ?'); params.push(minPrice); }
  if (maxPrice) { where.push('COALESCE(p.sale_price, p.price) <= ?'); params.push(maxPrice); }
  if (onSale === '1') where.push('p.sale_price IS NOT NULL');
  if (inStock === '1') where.push('p.stock_quantity > 0');

  const sortMap = {
    newest:     'p.created_at DESC',
    price_asc:  'COALESCE(p.sale_price, p.price) ASC',
    price_desc: 'COALESCE(p.sale_price, p.price) DESC',
    rating:     'p.avg_rating DESC',
    popular:    'p.review_count DESC'
  };
  const orderBy = sortMap[sort] || sortMap.newest;

  const whereClause = `WHERE ${where.join(' AND ')}`;

  // Đếm tổng
  const [countRows] = await pool.query(
    `SELECT COUNT(*) AS cnt FROM products p JOIN categories c ON p.category_id = c.id ${whereClause}`,
    params
  );
  const { offset, pageSize, ...paginInfo } = paginate(countRows[0].cnt, page, 12);

  // Lấy sản phẩm
  const [products] = await pool.query(
    `SELECT p.*, c.name AS category_name, c.slug AS category_slug,
            pi.image_url AS main_image
     FROM products p
     JOIN categories c ON p.category_id = c.id
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
     ${whereClause}
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`,
    [...params, pageSize, offset]
  );

  return { products, pagination: { ...paginInfo, page: paginInfo.page, pageSize, offset } };
}

async function getProductBySlug(slug) {
  const [rows] = await pool.query(
    `SELECT p.*, c.name AS category_name, c.slug AS category_slug
     FROM products p JOIN categories c ON p.category_id = c.id
     WHERE p.slug = ? AND p.status != 'inactive'`,
    [slug]
  );
  if (!rows.length) return null;
  const product = rows[0];

  // Lấy tất cả ảnh
  const [images] = await pool.query(
    'SELECT * FROM product_images WHERE product_id = ? ORDER BY is_main DESC, sort_order',
    [product.id]
  );
  product.images = images;

  // Lấy 5 review mới nhất (visible)
  const [reviews] = await pool.query(
    `SELECT r.*, u.full_name FROM reviews r JOIN users u ON r.user_id = u.id
     WHERE r.product_id = ? AND r.status = 'visible'
     ORDER BY r.created_at DESC LIMIT 5`,
    [product.id]
  );
  product.reviews = reviews;

  // Sản phẩm liên quan (cùng danh mục)
  const [related] = await pool.query(
    `SELECT p.*, pi.image_url AS main_image
     FROM products p
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
     WHERE p.category_id = ? AND p.id != ? AND p.status = 'active'
     ORDER BY RAND() LIMIT 4`,
    [product.category_id, product.id]
  );
  product.related = related;

  return product;
}

async function getFeaturedProducts() {
  // Trang chủ: 8 sản phẩm sale, 8 mới nhất, 8 rating cao
  const [onSale] = await pool.query(
    `SELECT p.*, pi.image_url AS main_image FROM products p
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
     WHERE p.sale_price IS NOT NULL AND p.status = 'active'
     ORDER BY (p.price - p.sale_price) DESC LIMIT 8`
  );
  const [newest] = await pool.query(
    `SELECT p.*, pi.image_url AS main_image FROM products p
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
     WHERE p.status = 'active' ORDER BY p.created_at DESC LIMIT 8`
  );
  const [topRated] = await pool.query(
    `SELECT p.*, pi.image_url AS main_image FROM products p
     LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.is_main = 1
     WHERE p.status = 'active' AND p.review_count > 0
     ORDER BY p.avg_rating DESC LIMIT 8`
  );
  return { onSale, newest, topRated };
}

async function getAllCategories() {
  const [rows] = await pool.query(
    "SELECT * FROM categories WHERE status = 'active' ORDER BY sort_order"
  );
  return rows;
}

async function getAllBrands() {
  const [rows] = await pool.query(
    "SELECT DISTINCT brand FROM products WHERE brand IS NOT NULL AND status = 'active' ORDER BY brand"
  );
  return rows.map(r => r.brand);
}

module.exports = { getProducts, getProductBySlug, getFeaturedProducts, getAllCategories, getAllBrands };
```

---

## Bước 2 — product.controller.js

```javascript
const productService = require('../services/product.service');

// GET /
const getHome = async (req, res) => {
  const featured = await productService.getFeaturedProducts();
  const categories = await productService.getAllCategories();
  res.render('pages/home', { title: 'ElectroShop - Đồ Điện Tử Chính Hãng', ...featured, categories });
};

// GET /products
const getProducts = async (req, res) => {
  const { keyword, category, brand, minPrice, maxPrice, onSale, inStock, sort, page } = req.query;
  const { products, pagination } = await productService.getProducts({
    keyword, category, brand, minPrice, maxPrice, onSale, inStock, sort, page: parseInt(page) || 1
  });
  const categories = await productService.getAllCategories();
  const brands = await productService.getAllBrands();

  res.render('pages/products/index', {
    title: keyword ? `Kết quả: "${keyword}"` : 'Tất cả sản phẩm',
    products, pagination, categories, brands, filters: req.query
  });
};

// GET /products/:slug
const getProductDetail = async (req, res) => {
  const product = await productService.getProductBySlug(req.params.slug);
  if (!product) return res.status(404).render('errors/404', { title: 'Sản phẩm không tìm thấy' });

  res.render('pages/products/detail', {
    title: product.name,
    product
  });
};

// GET /categories/:slug  (reuse trang products/index)
const getByCategory = async (req, res) => {
  const categories = await productService.getAllCategories();
  const cat = categories.find(c => c.slug === req.params.slug);
  if (!cat) return res.status(404).render('errors/404', { title: 'Danh mục không tìm thấy' });

  const { products, pagination } = await productService.getProducts({
    category: req.params.slug, ...req.query, page: parseInt(req.query.page) || 1
  });
  const brands = await productService.getAllBrands();

  res.render('pages/products/index', {
    title: cat.name,
    products, pagination, categories, brands,
    filters: { ...req.query, category: req.params.slug },
    currentCategory: cat
  });
};

module.exports = { getHome, getProducts, getProductDetail, getByCategory };
```

---

## Bước 3 — product.routes.js

```javascript
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/product.controller');

router.get('/', ctrl.getHome);
router.get('/products', ctrl.getProducts);
router.get('/products/:slug', ctrl.getProductDetail);
router.get('/categories/:slug', ctrl.getByCategory);
router.get('/search', (req, res) => res.redirect('/products?' + new URLSearchParams(req.query)));

module.exports = router;
```

---

## Bước 4 — Partial: partials/product-card.ejs

```html
<% /* Dùng: <%- include('../partials/product-card', { product }) %> */ %>
<div class="card product-card h-100 border-0 shadow-sm">
  <div class="position-relative">
    <a href="/products/<%= product.slug %>">
      <img src="<%= product.main_image || '/images/no-image.png' %>"
           class="card-img-top product-thumb" alt="<%= product.name %>"
           loading="lazy" onerror="this.src='/images/no-image.png'">
    </a>
    <% if (product.sale_price) { %>
      <% const discount = Math.round((1 - product.sale_price / product.price) * 100); %>
      <span class="badge bg-danger position-absolute top-0 end-0 m-2">-<%= discount %>%</span>
    <% } %>
    <% if (product.stock_quantity === 0) { %>
      <div class="position-absolute bottom-0 start-0 end-0 bg-dark bg-opacity-50 text-white text-center py-1 small">
        Hết hàng
      </div>
    <% } %>
  </div>
  <div class="card-body d-flex flex-column">
    <small class="text-muted"><%= product.brand %></small>
    <h6 class="card-title mt-1 mb-auto">
      <a href="/products/<%= product.slug %>" class="text-decoration-none text-dark">
        <%= product.name %>
      </a>
    </h6>
    <div class="mt-2">
      <% if (product.avg_rating > 0) { %>
        <small class="text-warning">
          <% for(let i=1; i<=5; i++) { %>
            <i class="bi bi-star<%= i <= Math.round(product.avg_rating) ? '-fill' : '' %>"></i>
          <% } %>
          (<%= product.review_count %>)
        </small>
      <% } %>
      <div class="mt-1">
        <% if (product.sale_price) { %>
          <span class="fw-bold text-danger fs-6"><%= product.sale_price.toLocaleString('vi-VN') %>đ</span>
          <del class="text-muted small ms-1"><%= product.price.toLocaleString('vi-VN') %>đ</del>
        <% } else { %>
          <span class="fw-bold text-danger fs-6"><%= product.price.toLocaleString('vi-VN') %>đ</span>
        <% } %>
      </div>
    </div>
    <% if (product.stock_quantity > 0) { %>
      <form action="/cart/add" method="POST" class="mt-2 add-to-cart-form">
        <input type="hidden" name="product_id" value="<%= product.id %>">
        <input type="hidden" name="quantity" value="1">
        <button type="submit" class="btn btn-outline-primary btn-sm w-100">
          <i class="bi bi-cart-plus"></i> Thêm vào giỏ
        </button>
      </form>
    <% } else { %>
      <button class="btn btn-secondary btn-sm w-100 mt-2" disabled>Hết hàng</button>
    <% } %>
  </div>
</div>
```

---

## Bước 5 — View: pages/products/index.ejs (cấu trúc)

```html
<div class="row">
  <!-- Sidebar bộ lọc -->
  <div class="col-lg-3 mb-4">
    <form id="filter-form" action="/products" method="GET">
      <!-- Giữ keyword nếu có -->
      <% if (filters.keyword) { %>
        <input type="hidden" name="keyword" value="<%= filters.keyword %>">
      <% } %>

      <div class="card border-0 shadow-sm p-3">
        <h6 class="fw-bold">Danh mục</h6>
        <% categories.forEach(cat => { %>
          <div class="form-check">
            <input class="form-check-input" type="radio" name="category"
                   value="<%= cat.slug %>" id="cat-<%= cat.id %>"
                   <%= filters.category === cat.slug ? 'checked' : '' %>
                   onchange="document.getElementById('filter-form').submit()">
            <label class="form-check-label" for="cat-<%= cat.id %>"><%= cat.name %></label>
          </div>
        <% }); %>

        <hr>
        <h6 class="fw-bold">Khoảng giá (đ)</h6>
        <div class="row g-1">
          <div class="col"><input type="number" name="minPrice" class="form-control form-control-sm"
                                  placeholder="Từ" value="<%= filters.minPrice || '' %>"></div>
          <div class="col"><input type="number" name="maxPrice" class="form-control form-control-sm"
                                  placeholder="Đến" value="<%= filters.maxPrice || '' %>"></div>
        </div>

        <hr>
        <h6 class="fw-bold">Thương hiệu</h6>
        <% brands.forEach(brand => { %>
          <div class="form-check">
            <input class="form-check-input" type="checkbox" name="brand"
                   value="<%= brand %>" <%= filters.brand === brand ? 'checked' : '' %>
                   onchange="document.getElementById('filter-form').submit()">
            <label class="form-check-label"><%= brand %></label>
          </div>
        <% }); %>

        <hr>
        <div class="form-check">
          <input class="form-check-input" type="checkbox" name="onSale" value="1"
                 <%= filters.onSale === '1' ? 'checked' : '' %>
                 onchange="document.getElementById('filter-form').submit()">
          <label class="form-check-label">Đang giảm giá</label>
        </div>
        <div class="form-check">
          <input class="form-check-input" type="checkbox" name="inStock" value="1"
                 <%= filters.inStock === '1' ? 'checked' : '' %>
                 onchange="document.getElementById('filter-form').submit()">
          <label class="form-check-label">Còn hàng</label>
        </div>

        <button type="submit" class="btn btn-primary btn-sm w-100 mt-2">Lọc</button>
        <a href="/products" class="btn btn-outline-secondary btn-sm w-100 mt-1">Xoá bộ lọc</a>
      </div>
    </form>
  </div>

  <!-- Danh sách sản phẩm -->
  <div class="col-lg-9">
    <!-- Sort bar -->
    <div class="d-flex justify-content-between align-items-center mb-3">
      <span class="text-muted"><%= pagination.totalItems %> sản phẩm</span>
      <select name="sort" form="filter-form" class="form-select form-select-sm w-auto"
              onchange="document.getElementById('filter-form').submit()">
        <option value="newest" <%= filters.sort === 'newest' ? 'selected' : '' %>>Mới nhất</option>
        <option value="price_asc" <%= filters.sort === 'price_asc' ? 'selected' : '' %>>Giá thấp → cao</option>
        <option value="price_desc" <%= filters.sort === 'price_desc' ? 'selected' : '' %>>Giá cao → thấp</option>
        <option value="rating" <%= filters.sort === 'rating' ? 'selected' : '' %>>Đánh giá cao</option>
      </select>
    </div>

    <% if (products.length === 0) { %>
      <div class="text-center py-5">
        <i class="bi bi-search fs-1 text-muted"></i>
        <p class="mt-3 text-muted">Không tìm thấy sản phẩm phù hợp</p>
        <a href="/products" class="btn btn-outline-primary">Xem tất cả sản phẩm</a>
      </div>
    <% } else { %>
      <div class="row row-cols-2 row-cols-md-3 g-3">
        <% products.forEach(product => { %>
          <div class="col"><%- include('../../partials/product-card', { product }) %></div>
        <% }); %>
      </div>
      <%- include('../../partials/pagination', { pagination, query: filters }) %>
    <% } %>
  </div>
</div>
```

---

## Bước 6 — Partial: pagination.ejs

```html
<% if (pagination.totalPages > 1) { %>
<nav class="mt-4">
  <ul class="pagination justify-content-center">
    <li class="page-item <%= !pagination.hasPrev ? 'disabled' : '' %>">
      <a class="page-link" href="?<%= new URLSearchParams({...query, page: pagination.page - 1}) %>">
        <i class="bi bi-chevron-left"></i>
      </a>
    </li>
    <% for (let i = 1; i <= pagination.totalPages; i++) { %>
      <% if (i === 1 || i === pagination.totalPages || (i >= pagination.page - 2 && i <= pagination.page + 2)) { %>
        <li class="page-item <%= i === pagination.page ? 'active' : '' %>">
          <a class="page-link" href="?<%= new URLSearchParams({...query, page: i}) %>"><%= i %></a>
        </li>
      <% } else if (i === pagination.page - 3 || i === pagination.page + 3) { %>
        <li class="page-item disabled"><span class="page-link">…</span></li>
      <% } %>
    <% } %>
    <li class="page-item <%= !pagination.hasNext ? 'disabled' : '' %>">
      <a class="page-link" href="?<%= new URLSearchParams({...query, page: pagination.page + 1}) %>">
        <i class="bi bi-chevron-right"></i>
      </a>
    </li>
  </ul>
</nav>
<% } %>
```

---

## Checklist xác nhận ✅

```
[ ] GET / → trang chủ hiển thị sản phẩm sale, mới nhất, rating cao
[ ] GET /products → danh sách 12 sản phẩm/trang
[ ] GET /products?keyword=iphone → lọc đúng theo tên/brand
[ ] GET /products?category=dien-thoai-phu-kien → lọc đúng danh mục
[ ] GET /products?minPrice=5000000&maxPrice=20000000 → lọc đúng khoảng giá
[ ] GET /products?onSale=1 → chỉ hiện SP giảm giá
[ ] GET /products?sort=price_asc → sắp xếp đúng
[ ] Pagination: trang 2 hiển thị đúng, không crash nếu page > totalPages
[ ] GET /products/:slug sản phẩm tồn tại → chi tiết đầy đủ
[ ] GET /products/slug-khong-ton-tai → 404
[ ] Sản phẩm hết hàng: button "Hết hàng" disabled, không có form add-to-cart
[ ] Sản phẩm có sale_price → hiển thị giá giảm + badge % off
[ ] Ảnh lazy load, fallback /images/no-image.png nếu lỗi
[ ] GET /categories/:slug → render đúng danh mục
[ ] Sản phẩm liên quan hiện ở trang detail
```

## Sau khi xong: `bash hooks/hook-10-qa.sh 04`
