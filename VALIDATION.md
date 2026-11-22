# Destnly website — build validation (22 Nov 2026)

**Passed, checked from files**
- Static, dependency-free site: all original main-site HTML/CSS/JS and asset files retained.
- Legal policy documents included locally, with full section hierarchy: Privacy (17), Terms (18), Child Safety (8), Account Deletion (6).
- `/privacy/index.html`, `/terms/index.html`, `/child-safety/index.html`, `/account-deletion/index.html`, `/contact/index.html` exist.
- Legacy `privacy.html`, `terms.html`, `child-safety.html`, `account-deletion.html` files also exist.
- Netlify `_redirects` has direct clean-path rewrites.
- No missing local images, stylesheets, or JavaScript references in any HTML page.
- Legal pages use an independent responsive CSS stylesheet (`legal.css`) and responsive layouts at 720px / 1120px.

**Not independently validated**
- HTTP route tests and headless Chromium rendering: blocked by networking policy in this build environment (localhost connection refused / blocked by administrator). Test in deployment preview before going live.
- Mobile Safari / Android WebView render: not tested with real devices.
- Exact byte-for-byte legal text comparison: origin's HTML was not directly downloadable. Policy text was transcribed from publicly rendered pages. Cloudflare-protected original email addresses could not be recovered; `developer@destnly.com` from Google Play listing was substituted. Verify those addresses and compare legal text with original HTML before production.

**Deploy**
- Deploy the contents of this folder as the static website root on Netlify.
- Open all four direct paths and `.html` variants in an incognito browser and inside the mobile app WebView.
- Ensure the production host continues serving HTTPS and that Store policy URL paths point to the new content.
