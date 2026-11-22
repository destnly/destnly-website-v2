# Production routing and association files

## Canonical host

The public canonical origin is `https://destnly.com`. Canonical metadata and
the sitemap must never use the `www` hostname.

The repository contains equivalent host redirects in `_redirects` and
`netlify.toml`. Production is currently proxied by Cloudflare, so Cloudflare
must also apply the redirect before any cache, Worker, or SPA fallback:

- Match: `http.host eq "www.destnly.com"`
- Status: `301`
- Dynamic target: `concat("https://destnly.com", http.request.uri.path)`
- Preserve query string: enabled

Do not match `destnly.com` in this rule; doing so would create a redirect loop.
Purge the Cloudflare cache after enabling the rule and verify a path containing
a query string, not only `/`.

## Android Digital Asset Links

`/.well-known/assetlinks.json` is provided by the backend, not stored in this
website repository. Cloudflare must route this exact path to that backend
before any website cache, Worker, or SPA fallback and preserve the backend's
`application/json` response without redirecting it.

Never copy the local release/upload-key fingerprint into this file. The value
must be copied from Google Play Console under **Setup > App integrity > App
signing key certificate > SHA-256 certificate fingerprint**. If Play signing
key rotation is active for supported Android versions, include every active
Play app-signing SHA-256 fingerprint as documented by Play.

## API-host association endpoint

`devapi.destnly.com` is a separate deployment. The backend source exposes the
same path only when its Android certificate configuration is populated. Its
production deployment must set `ANDROID_CERT_SHA256` to the same Play App
Signing SHA-256 fingerprint list and then redeploy the backend. Do not route
this hostname to the website file or rely on the website deployment to fix it.

## Release verification

Run after the edge/deployment has completed:

```bash
BASE_URL=https://destnly.com \
WWW_BASE_URL=https://www.destnly.com \
./scripts/verify-site.sh
```

The script compares deployed `app-ads.txt` with the repository, validates the
backend-provided Digital Asset Links body and media type, checks canonical
metadata and sitemap URLs, and verifies that `www` redirects permanently while
preserving a path and query string.
