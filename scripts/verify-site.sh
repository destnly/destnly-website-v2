#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

required_files=(
  index.html
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
expected_urls = {'https://destnly.com/', *(f'https://destnly.com/{route}/' for route in routes)}
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
if [[ -n "${BASE_URL:-}" ]]; then
  base="${BASE_URL%/}"
  for path in / /privacy /terms /child-safety /account-deletion /contact /robots.txt /sitemap.xml /app-ads.txt "/$indexnow_key.txt" /.well-known/assetlinks.json /site.webmanifest; do
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
  deployed_sitemap="$(curl -sS "$base/sitemap.xml")"
  if grep -Fq 'https://www.destnly.com' <<< "$deployed_sitemap"; then
    echo "Production sitemap contains www URLs" >&2
    exit 1
  fi

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
