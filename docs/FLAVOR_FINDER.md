# Find by flavor — idea, for Joel to build

Owner, 2026-10-27: "have the flavors clickable and it dims the map or
something, and in some cases it can say 'online only' and push them towards
the store."

**Built 2026-10-27 (first pass):**
- Lid icons as flavor buttons on `/`, `/embed` and store pages; `?flavor=` in the URL.
- Carriers first, the three states, and the sentences below. The nearest carrier is
  offered within 150 miles.
- On the map: the all-stores map shows only carriers, and a search map dims stores
  that don't have the flavor. Pin popups list flavors.
- Chain buttons ("Buy at H-E-B", "Buy at Albertsons") per flavor, and a "Get it
  delivered" row (Instacart / DoorDash / Uber Eats searches).
- All the links live in `app/models/flavor.rb`.

Still open: the mobile map-app layout, and links for Safeway, Jewel-Osco and
Pavilions. The Instacart brand page would replace its search link. This is the
brief; change it as you go.

## What the visitor does

1. **Flavor chips** sit above the map (and above the list on a phone): one per
   flavor, in the lid colours rep already uses for flavours (rep
   `ApplicationHelper::FLAVOR_LIDS`).
2. **Tap a chip:**
   - stores that carry it stay bright and come to the front;
   - stores that don't are dimmed (lower opacity, smaller, behind), not
     hidden: the visitor still sees there's a store nearby;
   - the list re-sorts with carriers first and says so in a sentence:
     "12 stores within 25 miles carry Dilly Dilly."
   - tap again (or "All flavors") to clear.
3. **Online only.** When a flavor is in no store, or in none within reach of
   the search, the result says so and sends them to buy it:
   "Chipotle isn't on a shelf near you yet. Order it online →" (that flavor's
   page on jeesauce.com). Two cases, two sentences:
   - in no store anywhere: "Online only";
   - in stores, just not near this search: "Not near you yet", plus the
     online link, plus the nearest carrier's distance if it's reasonable.
4. **The flavor is in the URL** (`/?flavor=dilly-dilly`, also on `/embed`),
   so a jeesauce.com flavor page can link to "where to buy this one" and a
   shared link opens with the chip already on.

## Honest blanks (this matters)

On the live list (2026-10-27): **1002 stores, 236 with no flavor list at
all.** That means rep doesn't know what they carry, not that they carry
nothing. So a store has three states for a flavor, never two:

| State | When | Shown as |
|---|---|---|
| carries | the flavor is in its list | bright |
| doesn't | it has a list, and the flavor isn't on it | dimmed |
| unknown | it has no list | neutral (not dimmed), "Call ahead: we don't know which flavors they stock" |

Never count an unknown store as a carrier in "12 stores carry…", and never
count it as proof a flavor is "online only".

Flavors in stores on 2026-10-27: Cilantro Lime 766, Original 665, Sun-Dried
Tomato Basil 414, Dilly Dilly 249, Chipotle 133.

## Where the data comes from

- **Which stores carry which flavor:** already here. Rep's feed carries
  `flavors` (names) per store; `stores.flavors` holds it; the public
  `/stores.json` republishes it. No rep change needed.
- **Every flavor that exists, and its shop link:** not in rep's feed. Rep only
  knows flavors that some store carries, so a flavor sold only online never
  appears. Read the jeesauce.com Shopify catalog (Storefront API, the same
  tokenless read jeesauce.com's site uses), or keep a short list in a
  setting if that's simpler at first. Match on the flavor NAME, and expect
  to keep a small alias table: rep says "Sun-Dried Tomato Basil", the shop
  may say it differently.
- Keep it read-only (findjeesauce never writes to rep or Shopify). A slug
  per flavor ("dilly-dilly") is derived from the name, never stored as truth.

## Get it today: delivery and pickup links (idea, owner 2026-10-27)

"Link to Instacart or DoorDash or whatever, so people can get it, and side
income, and H-E-B online." Next to a store that carries the flavor, offer
the ways to have it today:

- **The chain's own online shop** (heb.com curbside/delivery first, then
  others as they matter): a link to our product's page at that chain, so
  the cart is one tap away.
- **Delivery apps** (Instacart, DoorDash, Uber Eats…): a link to that store,
  or to our product at that store, where the app allows it.
- **Our own shop** stays the fallback ("Online only" above).

How to build it honestly:

- **A link appears only where someone checked it works.** A link to an empty
  search or the wrong store is worse than none. Keep a small table of
  verified links (chain × flavor → URL, plus per-store links where an app
  needs them) with who checked it and when, and drop or flag links that
  start failing (a nightly HEAD check is enough).
- **Start with the data in findjeesauce** (it's a storefront concern). If it
  later turns out to be master data (rep owns chains and products), move it
  to rep and publish it in the feed, the same way flavors arrived.
- **Chain product pages first.** One H-E-B product URL per flavor covers
  every H-E-B store, and most of the stores are H-E-B. That's the most
  value for the least upkeep.

**Side income (affiliate links):** some delivery apps run affiliate programs
that pay for a referred first order. Check each app's CURRENT program and its
terms before building on it: what it pays for, whether product or store
links are allowed, and what tracking it needs. Assume no affiliate deal
exists with any grocery chain until one is found. Two rules if we do it:

- **Say so on the page** (US law requires clear disclosure of paid links),
  e.g. "We may earn a small fee when you order through these links."
- **Never let the fee choose the order.** The nearest store that carries it
  comes first, whoever pays.

Study (2026-10-27): docs/AFFILIATE_STUDY.md. Links yes; brand affiliate income
mostly no. Owner: we don't need to name the store, only that they can get it.

Owner calls before building: which apps; whether affiliate links are wanted
on day one or later; who holds the affiliate accounts (a person at JeeSauce,
not the code).

## Mobile ("more mo")

The owner also asked to make the finder feel more like a phone map app, the
way people actually use it standing in a store aisle or a car. One shape:
full-screen map, a bottom sheet with the list that drags up, chips in a
horizontal scroll at the top, "Use my location" as the first thing offered.
Ask the owner what "more mo" meant before building; this is a guess.

## Done means

- Chips work on `/`, `/stores/:id` (its own flavors highlighted) and `/embed`.
- The three states above, with the sentences, and specs pinning them
  (especially: an unknown store never counts as a carrier).
- `?flavor=` round-trips; jeesauce.com can link to it.
- Zero horizontal overflow at 375px; works with JS off (server-side filter on
  the list, no map).
