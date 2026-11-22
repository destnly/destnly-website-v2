# Website integration recovery audit

Audit date: 22 November 2026  
Compared revisions: pre-revamp main `471d60a`, revamp `4108518`, merge `67d03dc`

The current visual design and legal content were preserved. Local, uncommitted contact-address corrections were not reverted.

| Integration | Before revamp | State after revamp | Action in this change | Evidence |
| --- | --- | --- | --- | --- |
| AdMob `app-ads.txt` | Present, but mixed the Destnly seller with hundreds of unrelated generated reseller entries | Deleted | Restored the single verified direct seller declaration | Mobile app `app.json`, Android manifest, iOS plist, and ad-unit config all use publisher `5796870987448664` |
| Website `ads.txt` | Present as a large generated seller list | Deleted | Not restored | No website ad tag or web-ad configuration exists; the historical file did not contain Destnly's verified publisher |
| `robots.txt` | Apex-domain sitemap | Revamp changed it to `www` | Restored the apex canonical sitemap URL | `https://destnly.com` is the specified primary origin |
| `sitemap.xml` | Included obsolete pages | Only the homepage, using `www` | Rebuilt with current public routes and apex URLs | Current route inventory and `_redirects` |
| Canonical/Open Graph | Mixed origins | Homepage used `www`; legal pages used apex | Standardized homepage, social metadata, and JSON-LD to apex | Primary-origin requirement |
| Web manifest | Present but referenced deleted assets | Deleted | Recreated using the current Destnly logo and theme | Current asset dimensions and brand colors |
| Android App Links | No website association file found | Absent | Not fabricated | Mobile Android manifest currently exposes custom `destnly://` links, not `https://destnly.com` App Links; production Play signing SHA-256 is not in either repository |
| iOS Universal Links | API domain configured in app entitlements | Website file absent | Documented as infrastructure work | App entitlement is `applinks:devapi.destnly.com`, so its AASA file belongs on that host |
| Google OAuth | Android/iOS clients exist in the app repository | No website callback or secret in this site | No frontend secret or fake verification file added | Mobile Firebase config; OAuth console settings are external |
| Search Console/Bing | No historical HTML file or meta token found | None in repository | No token invented | Full Git history search |
| Analytics/tag manager | No active website integration found | None | Not introduced | Adding tracking requires a real property ID plus consent/privacy review |
| Security headers | Not present historically | Basic Netlify headers present | Retained; added exact content types and cache rules for machine-readable files | Current `_headers` |
| Host canonicalization | Not explicit | Both hosts could be served | Added permanent `www` to apex redirect | Primary-origin requirement |

## External-console checks before production

1. In Google Play Console, confirm the developer website is `https://destnly.com` so AdMob crawls `https://destnly.com/app-ads.txt`.
2. In AdMob, confirm publisher ID `pub-5796870987448664` and re-crawl the app-ads file after deployment.
3. In Google Cloud/Firebase, verify the existing Android package is `com.destnlyapp`, its SHA fingerprints are current, and the OAuth consent-screen homepage, privacy, and terms URLs use the apex domain.
4. In Search Console and Bing Webmaster Tools, retain DNS verification if already configured. Add a repository token only if the console supplies the exact value.
5. If Android HTTPS App Links are required, add matching intent filters first and obtain the Play App Signing SHA-256 fingerprint before publishing `/.well-known/assetlinks.json`.
6. Serve the Apple association file from `https://devapi.destnly.com/.well-known/apple-app-site-association` or update the app entitlement and backend together. This static website cannot validate that API-host deployment.
7. Run `BASE_URL=https://deploy-preview.example ./scripts/verify-site.sh` on a deployment preview, then repeat with `https://destnly.com` after release.

## Intentionally not recovered

- The historical bulk `ads.txt` and `app-ads.txt` reseller inventory. Only the seller tied to the verified Destnly AdMob account was retained.
- Obsolete sitemap URLs for removed pages.
- Historical manifest icon paths that no longer exist.
- Verification tokens, signing fingerprints, analytics IDs, or OAuth secrets that cannot be proven from source.
