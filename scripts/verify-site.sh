#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

required_files=(
  index.html
  daily-vibe/index.html
  blog/dating-apps-with-communities/index.html
  stories/index.html
  stories/content.json
  stories/50k-downloads-and-just-getting-started/index.html
  privacy/index.html
  terms/index.html
  child-safety/index.html
  account-deletion/index.html
  contact/index.html
  app-ads.txt
  90f82d84badf447c990f6daa8ac5b073.txt
  robots.txt
  sitemap.xml
  site.webmanifest
  CNAME
  _headers
  _redirects
)

for file in "${required_files[@]}"; do
  test -s "$file" || { echo "Missing or empty: $file" >&2; exit 1; }
done

expected_seller='google.com, pub-5796870987448664, DIRECT, f08c47fec0942fa0'
indexnow_key='90f82d84badf447c990f6daa8ac5b073'
grep -Fxq "$expected_seller" app-ads.txt
test "$(cat "$indexnow_key.txt")" = "$indexnow_key" || {
  echo "IndexNow key file content is incorrect" >&2
  exit 1
}
grep -Fq "/$indexnow_key.txt" _headers
grep -Fq '<link rel="canonical" href="https://destnly.com/">' index.html
grep -Fq '<title>Destnly | Dating, Daily Vibe & Circles</title>' index.html
grep -Fq '<meta name="description" content="Meet new people on Destnly. Share your daily vibe, discover interest-based Circles, explore dating profiles, match and start meaningful conversations.">' index.html
grep -Fq '<meta property="og:title" content="Destnly — Where Stories Begin">' index.html
grep -Fq '<meta property="og:description" content="Meet people beyond the swipe. Share your daily vibe, explore Circles, discover matches and start conversations that matter.">' index.html
grep -Fq '<meta name="twitter:title" content="Destnly — Where Stories Begin">' index.html
grep -Fq '<meta name="twitter:description" content="Meet people beyond the swipe. Share your daily vibe, explore Circles, discover matches and start conversations that matter.">' index.html
grep -Fq 'href="/daily-vibe/" class="inline-link dating-feature-link"' index.html
grep -Fq 'Sitemap: https://destnly.com/sitemap.xml' robots.txt
grep -Fxq 'destnly.com' CNAME
grep -Fxq 'https://www.destnly.com/* https://destnly.com/:splat 301!' _redirects
if grep -Fq 'https://www.destnly.com' index.html robots.txt sitemap.xml; then
  echo "Canonical www URL remains in machine-readable metadata" >&2
  exit 1
fi

python3 -m json.tool site.webmanifest >/dev/null
python3 - <<'PY'
from html.parser import HTMLParser
from pathlib import Path
import xml.etree.ElementTree as ET


routes = ('privacy', 'terms', 'child-safety', 'account-deletion', 'contact')


class CanonicalParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.canonicals = []

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == 'link' and values.get('rel') == 'canonical':
            self.canonicals.append(values.get('href'))


for route in routes:
    expected = f'https://destnly.com/{route}/'
    for page in (Path(f'{route}.html'), Path(route) / 'index.html'):
        parser = CanonicalParser()
        parser.feed(page.read_text(encoding='utf-8'))
        assert parser.canonicals == [expected], f'{page} canonical is {parser.canonicals}, expected {expected}'

namespace = {'sitemap': 'http://www.sitemaps.org/schemas/sitemap/0.9'}
sitemap_urls = {
    node.text for node in ET.parse('sitemap.xml').getroot().findall('sitemap:url/sitemap:loc', namespace)
}
expected_urls = {
    'https://destnly.com/',
    *(f'https://destnly.com/{route}/' for route in routes),
    'https://destnly.com/blog/dating-apps-with-communities/',
    'https://destnly.com/stories/',
    'https://destnly.com/stories/50k-downloads-and-just-getting-started/',
}
assert sitemap_urls == expected_urls, f'unexpected sitemap URLs: {sorted(sitemap_urls)}'
PY
python3 - <<'PY'
from html.parser import HTMLParser
import json


class HomepageParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.title_count = 0
        self.meta = []
        self.canonicals = []
        self.json_ld = []
        self.images = []
        self._in_title = False
        self._in_json_ld = False
        self._json_buffer = []

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == 'title':
            self.title_count += 1
            self._in_title = True
        elif tag == 'meta':
            self.meta.append(values)
        elif tag == 'link' and values.get('rel') == 'canonical':
            self.canonicals.append(values.get('href'))
        elif tag == 'script' and values.get('type') == 'application/ld+json':
            self._in_json_ld = True
            self._json_buffer = []
        elif tag == 'img':
            self.images.append(values)

    def handle_data(self, data):
        if self._in_json_ld:
            self._json_buffer.append(data)

    def handle_endtag(self, tag):
        if tag == 'title':
            self._in_title = False
        elif tag == 'script' and self._in_json_ld:
            self.json_ld.append(json.loads(''.join(self._json_buffer)))
            self._in_json_ld = False


parser = HomepageParser()
with open('index.html', encoding='utf-8') as handle:
    parser.feed(handle.read())

assert parser.title_count == 1, f'expected one title, found {parser.title_count}'
assert parser.canonicals == ['https://destnly.com/'], f'unexpected canonical tags: {parser.canonicals}'
descriptions = [item for item in parser.meta if item.get('name') == 'description']
assert len(descriptions) == 1, f'expected one meta description, found {len(descriptions)}'
robots = ' '.join(item.get('content', '').lower() for item in parser.meta if item.get('name') == 'robots')
assert 'noindex' not in robots, 'homepage contains noindex'
assert len(parser.json_ld) == 1, f'expected one JSON-LD block, found {len(parser.json_ld)}'
assert all(image.get('alt', '').strip() for image in parser.images), 'homepage contains an image with missing or empty alt text'
schema = parser.json_ld[0]
assert schema.get('@context') == 'https://schema.org'
assert schema.get('@type') == 'MobileApplication'
assert schema.get('name') == 'Destnly'
assert schema.get('identifier') == 'com.destnlyapp'
assert schema.get('url') == 'https://destnly.com/'
assert schema.get('downloadUrl') == 'https://play.google.com/store/apps/details?id=com.destnlyapp'
assert schema.get('publisher', {}).get('logo') == 'https://destnly.com/assets/destnly-logo.png'
PY
python3 - <<'PY'
from html.parser import HTMLParser
from pathlib import Path


class FeaturePageParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.titles = []
        self.h1_count = 0
        self.meta = []
        self.canonicals = []
        self.images = []
        self.play_links = []
        self._in_title = False

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == 'title':
            self._in_title = True
        elif tag == 'h1':
            self.h1_count += 1
        elif tag == 'meta':
            self.meta.append(values)
        elif tag == 'link' and values.get('rel') == 'canonical':
            self.canonicals.append(values.get('href'))
        elif tag == 'img':
            self.images.append(values)
        elif tag == 'a' and values.get('href') == 'https://play.google.com/store/apps/details?id=com.destnlyapp':
            self.play_links.append(values)

    def handle_data(self, data):
        if self._in_title:
            self.titles.append(data)

    def handle_endtag(self, tag):
        if tag == 'title':
            self._in_title = False


page = Path('daily-vibe/index.html').read_text(encoding='utf-8')
parser = FeaturePageParser()
parser.feed(page)
assert ''.join(parser.titles).strip() == 'Daily Vibe — Share How You Feel | Destnly'
assert parser.h1_count == 1, f'expected one Daily Vibe H1, found {parser.h1_count}'
assert parser.canonicals == ['https://destnly.com/daily-vibe/'], parser.canonicals
descriptions = [item for item in parser.meta if item.get('name') == 'description']
assert descriptions == [{
    'name': 'description',
    'content': 'Daily Vibe lets you share how you feel for 24 hours, add more context to your profile and help conversations begin more naturally on Destnly.'
}], descriptions
robots = ' '.join(item.get('content', '').lower() for item in parser.meta if item.get('name') == 'robots')
assert 'noindex' not in robots, 'Daily Vibe page contains noindex'
assert all(image.get('alt', '').strip() for image in parser.images), 'Daily Vibe page contains an image without descriptive alt text'
assert parser.play_links, 'Daily Vibe page has no Google Play CTA'
assert '<loc>https://destnly.com/daily-vibe/</loc>' not in Path('sitemap.xml').read_text(encoding='utf-8'), (
    'Daily Vibe must not enter the sitemap before its production URL is verified'
)
PY
python3 - <<'PY'
from html.parser import HTMLParser
from pathlib import Path
import json
import re


class ArticleParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.titles = []
        self.h1 = []
        self.meta = []
        self.canonicals = []
        self.json_ld = []
        self.images = []
        self.play_links = 0
        self.article_text = []
        self._capture = None
        self._in_article = False
        self._json_buffer = []
        self._in_json = False

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == 'title':
            self._capture = 'title'
        elif tag == 'h1':
            self._capture = 'h1'
        elif tag == 'article':
            self._in_article = True
        elif tag == 'meta':
            self.meta.append(values)
        elif tag == 'link' and values.get('rel') == 'canonical':
            self.canonicals.append(values.get('href'))
        elif tag == 'script' and values.get('type') == 'application/ld+json':
            self._in_json = True
            self._json_buffer = []
        elif tag == 'img':
            self.images.append(values)
        elif tag == 'a' and values.get('href') == 'https://play.google.com/store/apps/details?id=com.destnlyapp':
            self.play_links += 1

    def handle_data(self, data):
        if self._capture == 'title':
            self.titles.append(data)
        elif self._capture == 'h1':
            self.h1.append(data)
        if self._in_article:
            self.article_text.append(data)
        if self._in_json:
            self._json_buffer.append(data)

    def handle_endtag(self, tag):
        if tag in ('title', 'h1'):
            self._capture = None
        elif tag == 'article':
            self._in_article = False
        elif tag == 'script' and self._in_json:
            self.json_ld.append(json.loads(''.join(self._json_buffer)))
            self._in_json = False


canonical = 'https://destnly.com/blog/dating-apps-with-communities/'
headline = 'Dating Apps With Communities: A Different Way to Meet People'
description = 'Explore how dating apps with interest-based communities can help people meet through shared interests, start better conversations and connect beyond swiping.'
page = Path('blog/dating-apps-with-communities/index.html').read_text(encoding='utf-8')
parser = ArticleParser()
parser.feed(page)
assert ''.join(parser.titles).strip() == f'{headline} | Destnly'
assert ''.join(parser.h1).strip() == headline
assert parser.canonicals == [canonical], parser.canonicals
assert [item for item in parser.meta if item.get('name') == 'description'] == [{'name': 'description', 'content': description}]
robots = ' '.join(item.get('content', '').lower() for item in parser.meta if item.get('name') == 'robots')
assert 'noindex' not in robots, 'article contains noindex'
assert len(parser.json_ld) == 1, f'expected one JSON-LD block, found {len(parser.json_ld)}'
schema = parser.json_ld[0]
assert schema.get('@type') == 'BlogPosting'
assert schema.get('headline') == headline
assert schema.get('datePublished') == '2026-11-23'
assert schema.get('dateModified') == '2026-11-23'
assert schema.get('mainEntityOfPage', {}).get('@id') == canonical
assert schema.get('publisher', {}).get('name') == 'Nexquard Technology Private Limited'
assert schema.get('publisher', {}).get('logo', {}).get('url') == 'https://destnly.com/assets/destnly-logo.png'
assert all('alt' in image for image in parser.images), 'article contains an image without an alt attribute'
assert parser.play_links >= 2, 'article page is missing a Google Play link in navigation or content'
word_count = len(re.findall(r"\b[\w’'-]+\b", ' '.join(parser.article_text)))
assert 800 <= word_count <= 1100, f'article body is {word_count} words; expected 800–1100'
assert f'<loc>{canonical}</loc>' in Path('sitemap.xml').read_text(encoding='utf-8')
assert 'href="/stories/">Stories</a>' in Path('index.html').read_text(encoding='utf-8')
PY
python3 - <<'PY'
from html.parser import HTMLParser
from pathlib import Path
import json
import re

class StoryParser(HTMLParser):
    def __init__(self):
        super().__init__(); self.title=[]; self.h1=0; self.meta=[]; self.canonicals=[]; self.schemas=[]; self.article=[]; self._title=False; self._article=False; self._json=False; self._buffer=[]
    def handle_starttag(self, tag, attrs):
        values=dict(attrs)
        if tag=='title': self._title=True
        elif tag=='h1': self.h1+=1
        elif tag=='meta': self.meta.append(values)
        elif tag=='link' and values.get('rel')=='canonical': self.canonicals.append(values.get('href'))
        elif tag=='article': self._article=True
        elif tag=='script' and values.get('type')=='application/ld+json': self._json=True; self._buffer=[]
    def handle_data(self, data):
        if self._title: self.title.append(data)
        if self._article: self.article.append(data)
        if self._json: self._buffer.append(data)
    def handle_endtag(self, tag):
        if tag=='title': self._title=False
        elif tag=='article': self._article=False
        elif tag=='script' and self._json: self.schemas.append(json.loads(''.join(self._buffer))); self._json=False

homepage=Path('index.html').read_text(encoding='utf-8')
assert '50,000+ downloads' in homepage
assert 'And we’re just' in homepage
assert 'href="/stories/50k-downloads-and-just-getting-started/"' in homepage
assert '57,000' not in homepage

index=Path('stories/index.html').read_text(encoding='utf-8')
assert '<title>Stories | Destnly</title>' in index
assert '<link rel="canonical" href="https://destnly.com/stories/">' in index
assert index.count('<h1>') == 1

canonical='https://destnly.com/stories/50k-downloads-and-just-getting-started/'
page=Path('stories/50k-downloads-and-just-getting-started/index.html').read_text(encoding='utf-8')
parser=StoryParser(); parser.feed(page)
assert ''.join(parser.title).strip()=='50,000+ Downloads: The Destnly Journey | Destnly'
assert parser.h1==1
assert parser.canonicals==[canonical]
assert [m for m in parser.meta if m.get('name')=='description']==[{'name':'description','content':'Destnly celebrates 50,000+ downloads. Discover our journey, our values and our vision for meaningful dating, friendships and communities.'}]
assert len(parser.schemas)==1
graph=parser.schemas[0].get('@graph',[])
types={item.get('@type') for item in graph}
assert types=={'BlogPosting','BreadcrumbList'}, types
posting=next(item for item in graph if item.get('@type')=='BlogPosting')
assert posting.get('datePublished')=='2026-11-28'
assert posting.get('publisher',{}).get('name')=='Nexquard Technology Private Limited'
assert posting.get('mainEntityOfPage',{}).get('@id')==canonical
words=len(re.findall(r"\b[\w’'-]+\b",' '.join(parser.article)))
assert 450<=words<=650, f'milestone story is {words} words; expected 450–650'
assert 'data-share-story' in page and 'data-story-download' in page
assert '57,000' not in page

content=json.loads(Path('stories/content.json').read_text(encoding='utf-8'))
assert isinstance(content,list) and len(content)>=2
assert any(item.get('slug')=='50k-downloads-and-just-getting-started' and item.get('featured') for item in content)
PY
if [[ -n "${BASE_URL:-}" ]]; then
  base="${BASE_URL%/}"
  for path in / /daily-vibe/ /blog/dating-apps-with-communities/ /stories/ /stories/50k-downloads-and-just-getting-started/ /privacy /terms /child-safety /account-deletion /contact /robots.txt /sitemap.xml /app-ads.txt "/$indexnow_key.txt" /.well-known/assetlinks.json /site.webmanifest; do
    status="$(curl -L -sS -o /dev/null -w '%{http_code}' "$base$path")"
    test "$status" = "200" || { echo "$path returned HTTP $status" >&2; exit 1; }
  done

  content_type="$(curl -sSI "$base/app-ads.txt" | tr -d '\r' | awk -F': ' 'tolower($1)=="content-type" {print tolower($2)}' | tail -1)"
  [[ "$content_type" == text/plain* ]] || { echo "app-ads.txt content type is $content_type" >&2; exit 1; }
  deployed_ads="$(mktemp)"
  deployed_indexnow="$(mktemp)"
  indexnow_headers="$(mktemp)"
  deployed_assetlinks="$(mktemp)"
  asset_headers="$(mktemp)"
  trap 'rm -f "$deployed_ads" "$deployed_indexnow" "$indexnow_headers" "$deployed_assetlinks" "$asset_headers"' EXIT
  curl -sS "$base/app-ads.txt" > "$deployed_ads"
  cmp -s app-ads.txt "$deployed_ads" || { echo "Deployed app-ads.txt differs from the repository" >&2; exit 1; }

  indexnow_status="$(curl -sS -D "$indexnow_headers" -o "$deployed_indexnow" -w '%{http_code}' "$base/$indexnow_key.txt")"
  test "$indexnow_status" = "200" || { echo "IndexNow key returned HTTP $indexnow_status" >&2; exit 1; }
  indexnow_content_type="$(tr -d '\r' < "$indexnow_headers" | awk -F': ' 'tolower($1)=="content-type" {print tolower($2)}' | tail -1)"
  [[ "$indexnow_content_type" == text/plain* ]] || {
    echo "IndexNow key content type is $indexnow_content_type" >&2
    exit 1
  }
  cmp -s "$indexnow_key.txt" "$deployed_indexnow" || {
    echo "Deployed IndexNow key body is incorrect" >&2
    exit 1
  }

  asset_status="$(curl -sS -D "$asset_headers" -o "$deployed_assetlinks" -w '%{http_code}' "$base/.well-known/assetlinks.json")"
  test "$asset_status" = "200" || { echo "assetlinks.json returned HTTP $asset_status" >&2; exit 1; }
  asset_content_type="$(tr -d '\r' < "$asset_headers" | awk -F': ' 'tolower($1)=="content-type" {print tolower($2)}' | tail -1)"
  [[ "$asset_content_type" == application/json* ]] || { echo "assetlinks.json content type is $asset_content_type" >&2; exit 1; }
  python3 -m json.tool "$deployed_assetlinks" >/dev/null
  python3 - "$deployed_assetlinks" <<'PY'
import json
import re
import sys

with open(sys.argv[1], encoding='utf-8') as handle:
    statements = json.load(handle)
matching = [
    statement for statement in statements
    if statement.get('target', {}).get('namespace') == 'android_app'
    and statement.get('target', {}).get('package_name') == 'com.destnlyapp'
]
assert matching, 'deployed assetlinks.json is missing com.destnlyapp'
assert any('delegate_permission/common.handle_all_urls' in statement.get('relation', []) for statement in matching), (
    'deployed assetlinks.json is missing the App Links relationship'
)
fingerprints = [
    fingerprint
    for statement in matching
    for fingerprint in statement.get('target', {}).get('sha256_cert_fingerprints', [])
]
assert fingerprints, 'deployed assetlinks.json has no SHA-256 certificate fingerprint'
assert all(re.fullmatch(r'(?:[0-9A-F]{2}:){31}[0-9A-F]{2}', fingerprint) for fingerprint in fingerprints), (
    'deployed assetlinks.json has a malformed SHA-256 fingerprint'
)
PY

  homepage="$(curl -sS "$base/")"
  grep -Fq '<link rel="canonical" href="https://destnly.com/">' <<< "$homepage" || {
    echo "Production homepage canonical is not https://destnly.com/" >&2
    exit 1
  }
  grep -Fq '<title>Destnly | Dating, Daily Vibe & Circles</title>' <<< "$homepage" || {
    echo "Production homepage title is not the expected SEO title" >&2
    exit 1
  }
  grep -Fq '<meta property="og:title" content="Destnly — Where Stories Begin">' <<< "$homepage" || {
    echo "Production homepage Open Graph title is not the expected SEO title" >&2
    exit 1
  }
  daily_vibe="$(curl -sS "$base/daily-vibe/")"
  grep -Fq '<link rel="canonical" href="https://destnly.com/daily-vibe/">' <<< "$daily_vibe" || {
    echo "Production Daily Vibe canonical is incorrect" >&2
    exit 1
  }
  grep -Fq '<title>Daily Vibe — Share How You Feel | Destnly</title>' <<< "$daily_vibe" || {
    echo "Production Daily Vibe title is incorrect" >&2
    exit 1
  }
  article="$(curl -sS "$base/blog/dating-apps-with-communities/")"
  grep -Fq '<link rel="canonical" href="https://destnly.com/blog/dating-apps-with-communities/">' <<< "$article" || {
    echo "Production article canonical is incorrect" >&2
    exit 1
  }
  grep -Fq '<title>Dating Apps With Communities: A Different Way to Meet People | Destnly</title>' <<< "$article" || {
    echo "Production article title is incorrect" >&2
    exit 1
  }
  deployed_sitemap="$(curl -sS "$base/sitemap.xml")"
  if grep -Fq 'https://www.destnly.com' <<< "$deployed_sitemap"; then
    echo "Production sitemap contains www URLs" >&2
    exit 1
  fi
  grep -Fq '<loc>https://destnly.com/blog/dating-apps-with-communities/</loc>' <<< "$deployed_sitemap" || {
    echo "Production sitemap is missing the article URL" >&2
    exit 1
  }

  canonical_routes=(privacy terms child-safety account-deletion contact)
  for route in "${canonical_routes[@]}"; do
    redirect_headers="$(curl -sS -o /dev/null -D - "$base/$route?source=seo%20audit")"
    redirect_status="$(awk 'toupper($1) ~ /^HTTP\// {code=$2} END {print code}' <<< "$redirect_headers")"
    test "$redirect_status" = "308" || {
      echo "/$route did not preserve the existing HTTP 308 redirect (returned $redirect_status)" >&2
      exit 1
    }
    redirect_location="$(tr -d '\r' <<< "$redirect_headers" | awk -F': ' 'tolower($1)=="location" {print $2}' | tail -1)"
    test "$redirect_location" = "/$route/?source=seo%20audit" || {
      echo "/$route redirect did not preserve its path and query: $redirect_location" >&2
      exit 1
    }

    final_headers="$(curl -sS -o /dev/null -D - "$base/$route/")"
    final_status="$(awk 'toupper($1) ~ /^HTTP\// {code=$2} END {print code}' <<< "$final_headers")"
    test "$final_status" = "200" || {
      echo "/$route/ returned HTTP $final_status instead of a direct 200" >&2
      exit 1
    }
    final_page="$(curl -sS "$base/$route/")"
    grep -Fq "<link rel=\"canonical\" href=\"https://destnly.com/$route/\">" <<< "$final_page" || {
      echo "/$route/ does not declare its final trailing-slash canonical" >&2
      exit 1
    }
    grep -Fq "<loc>https://destnly.com/$route/</loc>" <<< "$deployed_sitemap" || {
      echo "Production sitemap is missing https://destnly.com/$route/" >&2
      exit 1
    }
  done

  www_base="${WWW_BASE_URL:-https://www.destnly.com}"
  redirect_cases=(
    '/|https://destnly.com/'
    '/privacy|https://destnly.com/privacy'
    '/contact?source=google|https://destnly.com/contact?source=google'
    '/privacy%2Fnotice?source=encoded%20path|https://destnly.com/privacy%2Fnotice?source=encoded%20path'
  )
  for redirect_case in "${redirect_cases[@]}"; do
    request_path="${redirect_case%%|*}"
    expected_location="${redirect_case#*|}"
    redirect_headers="$(curl -sS -o /dev/null -D - "${www_base%/}${request_path}")"
    redirect_status="$(awk 'toupper($1) ~ /^HTTP\// {code=$2} END {print code}' <<< "$redirect_headers")"
    [[ "$redirect_status" == "301" || "$redirect_status" == "308" ]] || {
      echo "www canonical redirect for $request_path returned HTTP $redirect_status" >&2
      exit 1
    }
    redirect_location="$(tr -d '\r' <<< "$redirect_headers" | awk -F': ' 'tolower($1)=="location" {print $2}' | tail -1)"
    test "$redirect_location" = "$expected_location" || {
      echo "www canonical redirect for $request_path points to $redirect_location" >&2
      exit 1
    }
  done
fi

echo "Website integration checks passed."
