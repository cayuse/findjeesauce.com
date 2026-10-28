# Finder extras: ask your store, demand map, freshness, link checks, "I found it"

Built 2026-10-28 from docs/STORE_FINDER_STUDY.md (proposals 3–7), at Joel's
request: "let's try them all and then let Dave veto stuff that has security
problems or heaviness / processing problems."

## For cayuse: what to review (and veto)

The site was read-only (app/middleware/read_only.rb). It now accepts POST on
exactly these paths; every other non-GET is still a 405 before routing, and
spec/requests/read_only_spec.rb pins the list.

| Path | What it stores | Guard | Weight |
|---|---|---|---|
| `POST /stores/:id/shares` | store id, channel, time | 20/h per IP | one insert |
| `POST /asks` | chain, flavor, ZIP, point rounded to 0.1° | 10/h per IP, chain allow-list | one insert |
| `POST /stores/:id/sightings` | store id, flavor, optional JPEG ≤ 3 MB | 5/h per IP; photo needs the OK box | one insert; photo stored as bytea |
| `POST /clicks` | where a buy button went (known hosts only), store id, flavor, UTM spot | 60/h per IP | one insert |
| `POST /admin/sightings/:id/(approve\|reject)` | status | team sign-in + Rails CSRF token | one update |

Also new, with no POST:
- **Search logging (GET side effect).** Each searched results page inserts one
  `searches` row: typed ZIP, point rounded to ~7 mi, flavor, counts. No query
  text, no IP. Bots (by user agent) are skipped. Failures are swallowed so a
  search never breaks. Growth: one row per search; prune with a recurring job
  if it ever matters.
- **Nightly link check** (`CheckLinksJob`, 4am Central, recurring.yml): about
  20 outbound GETs a night, 10s/15s timeouts, up to 5 redirects. A link is hidden only after two
  404/410s in a row; 403/429/5xx (H-E-B's bot wall) are "unsure" and change
  nothing. Albertsons returns 200 for any product URL, so it can't catch a
  delisted Albertsons product.
- **Shared-link opens (GET side effect).** Opening a `?shared=1&via=…` link
  inserts one `share_opens` row (store, channel). No IP; bots skipped.
- **Photos: SWITCHED OFF 2026-10-28** (`SIGHTING_PHOTOS` unset). Joel's
  question for you: is it worth it, and if so, should photos live somewhere
  apart from our data? The idea: a private bucket (Cloudflare R2 or GCS,
  rep already uses GCS for expense media) with short-lived presigned PUTs
  from the browser, so bytes never touch our app or Postgres; the admin page
  shows pending photos through short-lived signed GETs; approve copies or
  flags it public, reject deletes it. Your call whether that's worth
  building, or photos stay off. The code below is what exists today.
- **Photos (as built).** The browser redraws the photo to a 1600px JPEG (canvas), which
  drops metadata; the server then strips APP1–APP15/COM segments anyway in pure
  Ruby (app/models/jpeg.rb, no libvips) and refuses anything that isn't a
  JPEG. Kept in Postgres (no volume, no Active Storage). Nothing shows until
  approved at /admin/sightings; reject deletes the bytes. Approved photos are
  served by `GET /sightings/:id/photo` (image/jpeg, nosniff, cached a day).
  We don't decode the image server-side, so a crafted file is passed to
  browsers as-is after review. If that's too much, veto photos and keep the
  one-tap "I found it".
- **/admin, the team page** (demand map, asks, buy clicks, shares/opens,
  link status, photo queue). Two ways in:
  - **Google sign-in (wanted, needs you):** app/models/google_sign_in.rb, a
    hand-rolled OIDC code flow (no gem), GETs only. Reuses rep's OAuth client
    (Internal: only our Workspace org) and adds our own allow-list
    (GoogleSignIn::TEAM, or ADMIN_EMAILS): dave, joel, porter, stephen,
    jack @jeesauce.com and ryan@goodlovinfoods.com. 12-hour session cookie
    (encrypted, secure, httponly). **To turn on:** add
    `https://findjeesauce.com/auth/google_oauth2/callback` and
    `https://test.findjeesauce.com/auth/google_oauth2/callback` to the
    client's redirect URIs, set `ADMIN_GOOGLE_SIGN_IN: "1"` in
    config/deploy.yml, redeploy. Then the password stops working.
  - **Until then:** HTTP Basic, user `jee`, ADMIN_PASSWORD from
    /home/sauce/secrets/findjeesauce/admin.env. 404 if neither is set.

CSRF is skipped on the three public POSTs on purpose: they're counters posted
from plain pages and the jeesauce.com frame with no session, and a forged one
can only add a row (rate-limited). Admin keeps CSRF.

## What shoppers see

- **Ask your store** when nothing is within 50 miles, or none nearby has the
  chosen flavor, or a store page doesn't list it: a ready-made request with
  flavors and UPCs, Copy, and buttons to H-E-B's contact form (pick "In-store
  shopping → Product request") and the Albertsons / Safeway / Jewel-Osco help
  pages. Counted per chain (a copy with no chain tap counts as "other").
- **Freshness**: "Delivered Oct 2026 · Spotted by a shopper 3 days ago" on
  cards and store pages; never "in stock". A call-ahead line under results.
- **I found it!** on store pages: optional flavor, optional photo; approved
  photos show as "Spotted by shoppers".

## Still needed from rep: the shelf signal

findjeesauce reads `stocked_recently` (true/false) per store from rep's feed
and shows "● In stock: <this month>" when true. Never a date: a date ages
("delivered 8/28" reads as old product in November). Rep keeps the evidence
(dates, sources, quantities) on its side for the team; the public feed gets
only the yes/no. Until rep sends it, nothing shows.

## Measuring (2026-10-28)

- jeesauce.com links carry `utm_source=findjeesauce&utm_medium=store_finder`
  `&utm_campaign=find_jeesauce&utm_content=<spot>`: Shopify's reports show
  finder orders, by spot (header, finder-tile, store-page-tile, …).
- Buy clicks (Click) by retailer, by store for H-E-B, and jeesauce.com clicks
  by spot, on /admin.
- Share links say how they were sent (`via=text|email|whatsapp|link|sheet`);
  /admin shows sent vs opened per channel.
- **Idea: H-E-B eCom.** jeedata has H-E-B's Circana data per store. Compare
  each store's eCom sales week by week against "Buy at H-E-B" clicks for
  that store (/admin lists them) to see whether the finder moves online
  orders. A jeedata job, not a finder one.

## Possible next: "Not near you yet?" request-and-notify flow

Owner's idea, 2026-10-28; a build of its own, parked here. When a search finds
nothing: "No stores near you stock JeeSauce yet." The shopper either
1. picks a store near them from a list (any grocery store, not just ours:
   needs a catalog of other stores, e.g. Google Places nearby search, or the
   chains' own store lists for H-E-B / Albertsons banners / Kroger etc.), then
   gets that chain's product-request form with our request ready to paste
   (low-hanging fruit: the chains we already link), and/or
2. leaves an email to be told when that store starts carrying it (the owner
   is fine storing emails people choose to give). Needs: an opt-in
   confirmation email, an unsubscribe link, a sender, and a job that emails
   when that store turns active in rep's feed. Rep would also get the
   requested stores as prospects ("N shoppers asked for this store").
Size: medium to large (store catalog, email sending, CAN-SPAM basics).
