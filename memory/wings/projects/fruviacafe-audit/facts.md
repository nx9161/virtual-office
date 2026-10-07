# fruviacafe-audit — facts.md

War-room QA audit of live site https://fruviacafe.com (2026-10-06), commissioned to support owner's pitch to the cafe owner as a prospective client.

## Target facts (all VERIFIED read-only unless noted)
- Site: Fruvia Cafe (NJ, phone (856) 448-0098). Custom ASP.NET MVC 5.2 (.NET 4.0.30319) behind Cloudflare; white-label tenant of PW Foods (pwfoods.net) QSR platform (INFERRED tenant relationship).
- Pages: `/`, `/ourmenu`, `/aboutus`, `/contactus`, `/career`, `/career/apply`, `/cart`, `/Privacy-Policy`, `/productdetails/...`.
- Stack currency: jQuery 3.7.1, Bootstrap 5.3.3, Slick 1.8.1 current; MVC 5.2 on .NET Framework = security-only servicing.
- TLS 1.3 valid; http→https 301 OK; gzip; no mixed content. www subdomain dead (no DNS).
- Privacy Policy exists at /Privacy-Policy ("Last Updated: Sep 14, 2026"); GA4 G-HB9WWE24WM on all pages; no cookie-consent UI observed.

## Critical findings (verified)
- C1–C4: passwords (login/register) and PII (contact + job forms incl. home addresses) transmitted in GET query strings; no anti-forgery tokens site-wide; GET-based mutations CSRF-able.
- H1: no privacy notice/consent at collection on either form (footer policy link only).
- H2: eval(res) on /Home/GetContactMap response (ContactUs.js).
- H3: resume upload via /CVfile.ashx, client-only controls; server-side validation unknown (INFERRED gap).
- H4: all six security headers missing; H5: sitemap.xml lists wrong domains (fordsfoodmarket.com, psbfresh.com); H6: broken ~/ images; H7: /contactus shows "--" placeholders; H8: no h1/lang/canonical; H11: multi-MB PNGs, mass missing alt text; H12: verbose ASP.NET errors + version headers.
- Full register: 4 Critical, 12 High, 14 Medium, 6 Low (see ~/workspace/fruviacafe-audit/findings-register.md).
- AI Red Team: no AI attack surface — N/A (explicit).
- AppSec verdict: BLOCK (as release candidate). Tech Law: sales-intelligence memo, not legal advice.

## Deliverables
- ~/workspace/fruviacafe-audit/findings-register.md
- ~/workspace/fruviacafe-audit/legal-actions-memo.md
- ~/workspace/fruviacafe-audit/rebuild-proposal-pricing.md (T1 $2.5–4K, T2 $6.5–12K, T3 $12–18K + $300–600/mo)
- ~/workspace/fruviacafe-audit/pitch-script.md

## Constraints / open items (need live browser or vendor)
- Form submission behavior, mobile rendering, contrast, LCP/CLS/INP, cross-browser parity: NT read-only.
- Server-side resume validation, password hashing, edge rate limiting, resume URL accessibility: need vendor code review.
- No contact made with site owner; read-only audit; no PRs.
