# Find by flavor — idea, for Joel to build

Owner, 2026-10-27: "have the flavors clickable and it dims the map or
something, and in some cases it can say 'online only' and push them towards
the store." Nothing here is built. This is the brief; change it as you go.

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
