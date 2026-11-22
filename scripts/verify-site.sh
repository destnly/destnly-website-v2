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
grep -Fxq "$expected_seller" app-ads.txt
grep -Fq '<link rel="canonical" href="https://destnly.com/">' index.html
grep -Fq 'Sitemap: https://destnly.com/sitemap.xml' robots.txt
grep -Fxq 'destnly.com' CNAME
grep -Fxq 'https://www.destnly.com/* https://destnly.com/:splat 301!' _redirects
if grep -Fq 'https://www.destnly.com' index.html robots.txt sitemap.xml; then
  echo "Canonical www URL remains in machine-readable metadata" >&2
  exit 1
fi

python3 -m json.tool site.webmanifest >/dev/null
if [[ -n "${BASE_URL:-}" ]]; then
  base="${BASE_URL%/}"
  for path in / /privacy /terms /child-safety /account-deletion /contact /robots.txt /sitemap.xml /app-ads.txt /.well-known/assetlinks.json /site.webmanifest; do
    status="$(curl -L -sS -o /dev/null -w '%{http_code}' "$base$path")"
    test "$status" = "200" || { echo "$path returned HTTP $status" >&2; exit 1; }
  done

  content_type="$(curl -sSI "$base/app-ads.txt" | tr -d '\r' | awk -F': ' 'tolower($1)=="content-type" {print tolower($2)}' | tail -1)"
  [[ "$content_type" == text/plain* ]] || { echo "app-ads.txt content type is $content_type" >&2; exit 1; }
  deployed_ads="$(mktemp)"
  deployed_assetlinks="$(mktemp)"
  asset_headers="$(mktemp)"
  trap 'rm -f "$deployed_ads" "$deployed_assetlinks" "$asset_headers"' EXIT
  curl -sS "$base/app-ads.txt" > "$deployed_ads"
  cmp -s app-ads.txt "$deployed_ads" || { echo "Deployed app-ads.txt differs from the repository" >&2; exit 1; }

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
  deployed_sitemap="$(curl -sS "$base/sitemap.xml")"
  if grep -Fq 'https://www.destnly.com' <<< "$deployed_sitemap"; then
    echo "Production sitemap contains www URLs" >&2
    exit 1
  fi

  www_base="${WWW_BASE_URL:-https://www.destnly.com}"
  redirect_headers="$(curl -sS -o /dev/null -D - "${www_base%/}/privacy?smoke=canonical-host")"
  redirect_status="$(awk 'toupper($1) ~ /^HTTP\// {code=$2} END {print code}' <<< "$redirect_headers")"
  test "$redirect_status" = "301" || { echo "www canonical redirect returned HTTP $redirect_status" >&2; exit 1; }
  redirect_location="$(tr -d '\r' <<< "$redirect_headers" | awk -F': ' 'tolower($1)=="location" {print $2}' | tail -1)"
  test "$redirect_location" = 'https://destnly.com/privacy?smoke=canonical-host' || {
    echo "www canonical redirect location is $redirect_location" >&2
    exit 1
  }
fi

echo "Website integration checks passed."
