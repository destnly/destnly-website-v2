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
test "$(wc -l < app-ads.txt | tr -d ' ')" = "1"
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
  for path in / /privacy /terms /child-safety /account-deletion /contact /robots.txt /sitemap.xml /app-ads.txt /site.webmanifest; do
    status="$(curl -L -sS -o /dev/null -w '%{http_code}' "$base$path")"
    test "$status" = "200" || { echo "$path returned HTTP $status" >&2; exit 1; }
  done

  content_type="$(curl -sSI "$base/app-ads.txt" | tr -d '\r' | awk -F': ' 'tolower($1)=="content-type" {print tolower($2)}' | tail -1)"
  [[ "$content_type" == text/plain* ]] || { echo "app-ads.txt content type is $content_type" >&2; exit 1; }
  test "$(curl -sS "$base/app-ads.txt")" = "$expected_seller"
fi

echo "Website integration checks passed."
