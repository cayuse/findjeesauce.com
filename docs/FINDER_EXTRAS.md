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
| `POST /admin/sightings/:id/(approve\|reject)` | status | Basic auth (`jee` / ADMIN_PASSWORD) + Rails CSRF token | one update |

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
- **Photos.** The browser redraws the photo to a 1600px JPEG (canvas), which
  drops metadata; the server then strips APP1–APP15/COM segments anyway in pure
  Ruby (app/models/jpeg.rb, no libvips) and refuses anything that isn't a
  JPEG. Kept in Postgres (no volume, no Active Storage). Nothing shows until
  approved at /admin/sightings; reject deletes the bytes. Approved photos are
  served by `GET /sightings/:id/photo` (image/jpeg, nosniff, cached a day).
  We don't decode the image server-side, so a crafted file is passed to
  browsers as-is after review. If that's too much, veto photos and keep the
  one-tap "I found it".
- **/admin** (demand map, asks, link status, photo queue): HTTP Basic, 404
  when ADMIN_PASSWORD is unset. Secret in
  /home/sauce/secrets/findjeesauce/admin.env (group sauce, 660), wired via
  .kamal/secrets-common and config/deploy.yml.

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

## Still needed from rep / jeedata: last delivered

The Store table and feed reader accept `last_delivered_on` (YYYY-MM-DD) per
store and show it when present. Rep's /api/v1/stores doesn't send it yet;
rep should add it from jeedata's published.store_pull_through (latest KeHE /
UNFI delivery date per store, via the store crosswalk).
