import scrapy
from scrapy.crawler import CrawlerProcess
from scrapy.signalmanager import dispatcher
from scrapy import signals
import logging
import re
import json


# ── Helpers ──────────────────────────────────────────────────────────────────

VI_MAP = str.maketrans(
    'àáảãạăắặằẳẵâấậầẩẫèéẻẽẹêếệềểễìíỉĩịòóỏõọôốộồổỗơớợờởỡùúủũụưứựừửữỳýỷỹỵđ'
    'ÀÁẢÃẠĂẮẶẰẲẴÂẤẬẦẨẪÈÉẺẼẸÊẾỆỀỂỄÌÍỈĨỊÒÓỎÕỌÔỐỘỒỔỖƠỚỢỜỞỠÙÚỦŨỤƯỨỰỪỬỮỲÝỶỸỴĐ'
    'ÀÁẢÃẠĂẮẶẰẲẴÂẤẬẦẨẪÈÉẺẼẸÊẾỆỀỂỄÌÍỈĨỊÒÓỎÕỌÔỐỘỒỔỖƠỚỢỜỞỠÙÚỦŨỤƯỨỰỪỬỮỲÝỶỸỴĐ',
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
)

_CORRECT_VI = {
    'à':'a','á':'a','ả':'a','ã':'a','ạ':'a',
    'ă':'a','ắ':'a','ặ':'a','ằ':'a','ẳ':'a','ẵ':'a',
    'â':'a','ấ':'a','ậ':'a','ầ':'a','ẩ':'a','ẫ':'a',
    'è':'e','é':'e','ẻ':'e','ẽ':'e','ẹ':'e',
    'ê':'e','ế':'e','ệ':'e','ề':'e','ể':'e','ễ':'e',
    'ì':'i','í':'i','ỉ':'i','ĩ':'i','ị':'i',
    'ò':'o','ó':'o','ỏ':'o','õ':'o','ọ':'o',
    'ô':'o','ố':'o','ộ':'o','ồ':'o','ổ':'o','ỗ':'o',
    'ơ':'o','ớ':'o','ợ':'o','ờ':'o','ở':'o','ỡ':'o',
    'ù':'u','ú':'u','ủ':'u','ũ':'u','ụ':'u',
    'ư':'u','ứ':'u','ự':'u','ừ':'u','ử':'u','ữ':'u',
    'ỳ':'y','ý':'y','ỷ':'y','ỹ':'y','ỵ':'y','đ':'d',
}
_CORRECT_VI.update({k.upper(): v for k, v in _CORRECT_VI.items()})


def slugify(text: str) -> str:
    for char, rep in _CORRECT_VI.items():
        text = text.replace(char, rep)
    text = text.lower()
    text = re.sub(r'[^a-z0-9]+', '-', text).strip('-')
    return text[:220]


def parse_price(text: str | None) -> int | None:
    if not text:
        return None
    digits = re.sub(r'[^\d]', '', text)
    return int(digits) if digits else None


BRANDS = [
    'Apple', 'Samsung', 'ASUS', 'Dell', 'HP', 'Lenovo', 'MSI',
    'Acer', 'LG', 'Sony', 'Xiaomi', 'Oppo', 'Vivo', 'Realme', 'Nokia',
    'Huawei', 'OnePlus', 'Motorola', 'Honor', 'Tecno', 'Meizu', 'Nubia',
    'Nothing', 'Infinix', 'Itel', 'TCL', 'ZTE',
]

# Tên sản phẩm không chứa brand name nhưng vẫn thuộc brand đó
_BRAND_ALIASES = {
    'iphone': 'Apple',
    'macbook': 'Apple',
    'ipad': 'Apple',
    'airpods': 'Apple',
    'galaxy': 'Samsung',
    'pixel': 'Google',
    'redmi': 'Xiaomi',
    'poco': 'Xiaomi',
}

def extract_brand(name: str) -> str | None:
    lower = name.lower()
    for alias, brand in _BRAND_ALIASES.items():
        if alias in lower:
            return brand
    for b in BRANDS:
        if b.lower() in lower:
            return b
    return None


CATEGORY_MAP = {
    'mobile': 1,
    'laptop': 2,
}


# ── Spider ────────────────────────────────────────────────────────────────────

class ProductSpider(scrapy.Spider):
    name = 'cellphones'
    start_urls = ['https://cellphones.com.vn/']

    custom_settings = {
        'RETRY_HTTP_CODES': [403, 429, 500, 502, 503, 504],
        'RETRY_TIMES': 5,
        'DOWNLOAD_DELAY': 1,
        'RANDOMIZE_DOWNLOAD_DELAY': True,
        'CONCURRENT_REQUESTS': 4,
        'COOKIES_ENABLED': False,
        'USER_AGENT': (
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/134.0.0.0 Safari/537.36'
        ),
    }

    def parse(self, response):
        for cate in ['mobile', 'laptop']:
            yield scrapy.Request(
                url=f'https://cellphones.com.vn/{cate}.html',
                callback=self.parse_cate,
                meta={'cate': cate},
            )

    def parse_cate(self, response):
        cate = response.meta['cate']

        links = response.xpath('//div[@class="product-info"]/a/@href').getall()
        for href in links:
            if not href.startswith('http'):
                href = 'https://cellphones.com.vn' + href
            yield scrapy.Request(href, callback=self.parse_detail, meta={'cate': cate})

        # Pagination — cellphones dùng ?page=N
        current = response.url
        m = re.search(r'[?&]page=(\d+)', current)
        current_page = int(m.group(1)) if m else 1
        # crawl tối đa 5 trang mỗi category để tránh quá nhiều request
        if current_page < 5 and links:
            base = re.sub(r'([?&]page=\d+)', '', current)
            sep = '&' if '?' in base else '?'
            next_url = f'{base}{sep}page={current_page + 1}'
            yield scrapy.Request(next_url, callback=self.parse_cate, meta={'cate': cate})

    def parse_detail(self, response):
        cate = response.meta['cate']

        # ── Name ──
        name = (
            response.xpath('//div[@class="box-product-name"]/h1/text()').get() or
            response.css('h1::text').get() or ''
        ).strip()
        if not name:
            return

        # ── Price ──
        # sale-price = giá đang bán, base-price = giá gốc (gạch ngang)
        sale_text = response.css('.sale-price::text').get()
        base_text = response.css('.base-price::text').get()

        sale_price_val = parse_price(sale_text)
        base_price_val = parse_price(base_text)

        if base_price_val and sale_price_val and base_price_val > sale_price_val:
            price = base_price_val
            sale_price = sale_price_val
        elif sale_price_val:
            price = sale_price_val
            sale_price = None
        elif base_price_val:
            price = base_price_val
            sale_price = None
        else:
            return  # price NOT NULL — skip

        # ── Brand ──
        brand = extract_brand(name)
        if brand:
            brand = brand.strip()

        # ── SKU ──
        sku_raw = response.css('[class*="sku"]::text').get()
        sku = re.sub(r'[^a-zA-Z0-9]', '', sku_raw.strip())[:50] if sku_raw else None
        sku = sku or None

        # ── Description — giữ nguyên HTML ──
        description = response.xpath('//div[@id="cpsContentSEO"]').get() or None

        # ── Specifications (JSON) ──
        specs: dict[str, str] = {}
        for row in response.css('tr.technical-content-item'):
            k = row.css('td:first-child::text').get('').strip()
            v = ' '.join(row.css('td:last-child p::text').getall()).strip()
            if not v:
                v = row.css('td:last-child::text').get('').strip()
            if k and v:
                specs[k] = v

        specifications = json.dumps(specs, ensure_ascii=False) if specs else None

        # ── Warranty ──
        warranty_months = 12
        for wt in response.xpath('//*[contains(text(),"bảo hành") or contains(text(),"Bảo hành")]/text()').getall():
            m = re.search(r'(\d+)\s*(tháng|năm)', wt, re.IGNORECASE)
            if m:
                n = int(m.group(1))
                if 'năm' in m.group(2).lower():
                    n *= 12
                warranty_months = n
                break

        # ── Images — CDN dùng single-quote, extract original URL từ plain/ ──
        cdn_srcs = re.findall(
            r"'(https://cdn2\.cellphones\.com\.vn/[^']+\.jpg)'",
            response.text
        )
        images = []
        seen = set()
        for src in cdn_srcs:
            # Lấy original URL sau plain/
            m = re.search(r'plain/(https://[^\'"\s]+\.jpg)', src)
            orig = m.group(1) if m else src
            if orig not in seen:
                seen.add(orig)
                images.append(orig)
            if len(images) >= 5:
                break

        yield {
            'category_id': CATEGORY_MAP.get(cate, 1),
            'name': name,
            'slug': slugify(name),
            'brand': brand,
            'sku': sku,
            'price': price,
            'sale_price': sale_price,
            'stock_quantity': 20,
            'description': description,
            'specifications': specifications,
            'warranty_months': warranty_months,
            'status': 'active',
            'images': images,
            '_source_url': response.url,
        }


# ── Runner ────────────────────────────────────────────────────────────────────

def run_index_crawler():
    logging.basicConfig(level=logging.INFO)
    process = CrawlerProcess(settings={
        'LOG_LEVEL': 'INFO',
        'FEEDS': {
            'products_raw.json': {'format': 'json', 'encoding': 'utf8', 'overwrite': True},
        },
    })

    def stop_scrapy():
        process.stop()

    dispatcher.connect(stop_scrapy, signal=signals.spider_closed)
    process.crawl(ProductSpider)
    process.start()


if __name__ == '__main__':
    run_index_crawler()
