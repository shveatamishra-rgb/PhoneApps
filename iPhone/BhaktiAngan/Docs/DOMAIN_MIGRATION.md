# Domain migration — bhaktiangan.in → bhaktiangan.com

**Goal:** `bhaktiangan.com` becomes the real, canonical site; `bhaktiangan.in`
permanently **301-redirects** to it (path-preserving). One WordPress install.
Support email becomes `support@bhaktiangan.com`.

Doing this **before** the app is submitted and while the site is days old means
near-zero SEO/relaunch cost. Order matters — follow it top to bottom.

---

## Phase 1 — done now (no dependency on .com)

These are already changed in the repo so no app re-release is ever needed for them:

- [x] App support email → `support@bhaktiangan.com` (`SupportView.swift`).
- [x] App Store metadata doc → `.com` URLs + `.com` support email.
- The app has **no** website-domain dependency otherwise (legal text is in-app;
  Instagram/YouTube/Facebook are handle-based).

⚠️ **Gate:** the `support@bhaktiangan.com` mailbox must exist and
`bhaktiangan.com` must resolve **before** you submit the app or share it.

---

## Phase 2 — you, in Hostinger (I cannot register domains or change DNS/hosting)

1. **Register** `bhaktiangan.com`.
2. **Point it at this hosting** (add the domain to the plan / set DNS). Wait until
   `https://bhaktiangan.com` loads the same site and SSL has issued.
3. **Create the mailbox** `support@bhaktiangan.com` (and SPF/DKIM for `.com`).
   Optionally forward `support@bhaktiangan.in` into it so old mail still arrives.
4. **Make `.com` the primary domain**, then set **Settings → General →
   WordPress Address + Site Address** to `https://bhaktiangan.com`.
   - ⚠️ Do **not** do this before step 2 is verified, or `/wp-admin` can lock you out.
5. **301-redirect `.in` → `.com`.** hPanel → Advanced → Redirects (type 301,
   source `bhaktiangan.in`, target `https://bhaktiangan.com`), covering both
   `www` and non-`www`. If you prefer `.htaccess`, add at the very top:

   ```apache
   <IfModule mod_rewrite.c>
   RewriteEngine On
   RewriteCond %{HTTP_HOST} ^(www\.)?bhaktiangan\.in$ [NC]
   RewriteRule ^(.*)$ https://bhaktiangan.com/$1 [R=301,L]
   </IfModule>
   ```

> Note: redirecting the **website** does not affect **email**. MX records are
> separate — keep `.in` MX live if you still want `support@bhaktiangan.in` to
> receive (e.g. forwarding into the `.com` inbox).

---

## Phase 3 — me, once `.com` resolves (ping me)

- Repoint every internal `https://bhaktiangan.in/...` link → `.com` in the
  homepage, privacy, terms, and contact pages (WP REST).
- Hand over `.com` versions of the WPCode snippets to re-paste:
  - `site_wide_header_bhaktiangan.php`, `site_wide_footer_bhaktiangan.php`
  - `contact_form_handler_bhaktiangan.php` (To/From → `support@bhaktiangan.com`).
- Update Rank Math canonical/sitemap (auto once WP home = `.com`); re-submit.
- Verify: `.in/<any-path>` → `.com/<same-path>` (301), contact form sends a real
  email to `support@bhaktiangan.com`, no mixed-content or redirect loops.

---

## Phase 4 — Google / App Store

- Add `bhaktiangan.com` as a **new property in Google Search Console**, submit the
  `.com` sitemap, and use the **Change of Address** tool from `.in` → `.com`.
- App Store Connect: set Privacy/Terms/Support/Marketing URLs to `.com` and the
  support email to `support@bhaktiangan.com` (no new build required).
