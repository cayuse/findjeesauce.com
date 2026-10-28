# Store finders that sell: a study for findjeesauce.com

Prepared 2026-10-28. Web research only.

**Built since (2026-10-28):** proposals 1 and 2. Every store card and store page has "Send this store to a friend": the phone's share sheet, copy link, and Text it / Email it, which open the shopper's own apps. We never send mail or see an address. A shared link opens the store's page with a "A friend sent you this store" banner and previews as a card. The "JeeSauce love spread N times" counter started at 0 and counts a completed share-sheet share, a copy, or a press of Text it / Email it (we can't see whether the text or email was actually sent). It's rate-limited to 20 per hour per IP. It's the one write findjeesauce accepts (see app/middleware/read_only.rb). Proposals 3 onward are open.

**Where findjeesauce.com stands today** (fetched 2026-10-28): ZIP/city search with "Use my location", five flavor filters, retailer callouts (H-E-B, Albertsons, Safeway, Jewel-Osco), links to Instacart, DoorDash and Uber Eats, an "order online" link to jeesauce.com, and an honest headline counter: "On the shelf at 1,005 stores in 20 states". At the time of the study there were no share buttons, no availability disclaimer and no request form.

**How sure each claim is.** Some vendor facts come from third-party comparison or review sites, not from the vendors. Those are marked *(secondary)*. Several brand locators load through JavaScript, so I identified the vendor by fetching the page HTML and searching it for vendor script names.

---

## 1. What other brands do

| Brand | Locator page | What it does / vendor found |
|---|---|---|
| OLIPOP | https://drinkolipop.com/pages/store-locator | Flavor-first locator ("Select a flavor below to view where to buy"). Plain disclaimer: "All products are subject to availability. Please contact your retailer to ensure products are in stock." Has an Instacart button. Also runs a rewards program ("Earn Rewards") and a reported "Give $15, Get $15" referral offer *(secondary: referralcodes.com)*. |
| Fly By Jing | https://flybyjing.com/pages/store-locator | Uses the **Aisle** store locator (`cdn.gotoaisle.com/store-locators-v1`). That locator puts SMS cash-back offers on the map pins. |
| Ithaca Hummus (closest category comp) | https://ithacahummus.com/pages/wheretobuy | **Destini** locator (`destini-locator` embed). |
| Kerrygold USA | https://www.kerrygoldusa.com/store-locator/ | **Destini** locator (`destinilocators.com/kerrygold`). |
| Liquid Death | https://liquiddeath.com/pages/where-to-buy | Store locator built into the main site and tied to the "Country Club" loyalty program. Members earn "Skulls" for purchases, sharing with friends, posting, reviews and referrals. Retail purchases count only when the member submits a receipt (https://www.rivo.io/blog/liquid-death-country-club-loyalty-program *(secondary)*). |
| Siete | https://sietefoods.com/shop#locate | "Store Locator – Find Us Near You" section on the shop page. Pairs it with a social follow prompt ("Let's take our friend-CHIP to the next level!"). |
| Sabra | https://www.strauss-group.com/faq/where-can-i-find-sabras-products-locally | Standard ZIP locator. The sabra.com page blocked automated fetches (403). |
| Graza | https://www.graza.co/pages/store-locator | Uses a Stockist-type locator. Graza also has a 10% affiliate program *(secondary: linkclicky)*. |
| Ben & Jerry's, Talenti, Oatly, Poppi | (blocked or moved pages) | Ben & Jerry's is known for a flavor-level "Flavor Locator". I couldn't confirm the vendor details because the pages returned 403 or 404. |
| Entenmann's Little Bites | https://www.surveymonkey.com/r/JKDYCLK | "Social Spotters" campaign: creators photographed the product in the store aisle so followers knew where to find it. Tied to a sweepstakes. |

## 2. Where-to-buy platforms

| Platform | What it is | Why brands use it | Cost / fit for a small brand |
|---|---|---|---|
| **Destini** (https://destini.co/where-to-buy/, https://destini.co/product-locators/) | Product-level grocery locator. Store results come from syndicated data (NielsenIQ, IRI/Circana, SPINS), and it adds online-retailer tabs, flavor/pack filters, "Consumer Requests" forms shown when no store is nearby (https://support.destini.co/hc/en-us/articles/360035464813-What-are-Consumer-Requests), and search-demand analytics by region. | Results are tied to real sales data. Search logs by ZIP give the sales team a demand map to show buyers. | No public pricing. Reported at **$1.1k–2.1k/month**, and new items can take 6–8 weeks to appear (https://www.storelocators.com/compare/destini-vs-storelocators *(secondary)*). Too expensive for JeeSauce, but its *features* are worth copying. |
| **MikMak** (https://mikmak.com/where-to-buy), now owned by SPINS (https://www.adweek.com/brand-marketing/retail-data-firm-spins-acquires-mikmak/) | "Buy now" overlays that send shoppers to 7,000+ retailers from ads, social posts and brand sites. Includes shopper-journey analytics. | Measures which media leads to retailer checkout clicks. | Built for enterprise clients (L'Oréal, Hershey's). Not worth it at JeeSauce's size. |
| **PriceSpider / ChannelSight / Shoppable** (https://www.channelsight.com/channelsight-vs-pricespider, https://www.g2.com/compare/channelsight-vs-shoppable-where-to-buy) | Buy-now buttons that check retailer stock, plus digital-shelf analytics. Shoppable adds a multi-retailer cart (https://martechseries.com/mobile/mobile-marketing/e-commerce-and-mobile-commerce/shoppable-instant-shop-to-empower-the-creator-economy-with-a-new-commerce-platform/). | They hide retailer links that are out of stock or broken, so shoppers don't hit dead ends. | Enterprise and mostly e-commerce focused. The idea to copy is **automatic link checking**. |
| **Instacart Developer Platform (IDP)** (https://company.instacart.com/business/developers, https://docs.instacart.com/developer_platform_api/) | Free API that creates Instacart recipe and shopping-list links matched to nearby retailers' inventory. Affiliate commissions are paid through Impact (https://docs.instacart.com/developer_platform_api/guide/concepts/launch_activities/conversions_and_payments). The general affiliate program pays up to about $10 per new customer *(secondary: https://marketplace.referly.so/affiliate-programs/instacart)*. | Turns "Instacart search" into a ready-to-checkout cart for the shopper's own store, and can pay JeeSauce for it. | **Free; medium effort.** The best match for JeeSauce's online handoff. Instacart **Carrot Ads / brand pages** are paid retail media; skip them for now (https://cpgguys.buzzsprout.com/1146830/11109687-brand-pages-shoppable-display-ads-with-instacart-s-ryan-mayward). |
| **Aisle** (https://gotoaisle.com/, https://www.gotoaisle.com/blog/beverage-brand-here-are-5-reasons-to-use-aisle-this-summer) | SMS cash-back. The shopper texts to claim an offer, buys at any store, texts a receipt photo and gets paid by Venmo/PayPal. Can be built into the store locator. | Proves an in-store purchase happened and captures first-party phone numbers. Aisle reports about 26% average conversion for beverage brands (June–Aug 2023). | Reported **about $499/month** plus the cost of the rebates *(secondary: storelocators.com/compare/aisle-vs-storelocators)*. Worth considering later for "try it free" launch pushes. |
| **Fetch** (https://www.digitalcommerce360.com/2023/10/04/infographic-general-mills-incentivizes-customers-through-mobile-app-fetch/) | Receipt-scanning rewards app with sponsored brand offers. | Drives trial and reports purchase data. | Paid campaigns; I found no public pricing for small brands. |
| **WeStock** (https://www.westock.io/post/westock-connecting-brands-with-retailers, https://westock.helpscoutdocs.com/article/20-using-your-request-form) | "Crowdstocking": shoppers request brands at their store, and the requests are organized for retail buyers. | Turns shopper demand into evidence for buyers. Their advice: put a "Request our product here" link on the store-locator page and promote it once or twice a month. | Reported **$79/month** for brands, free for retailers and shoppers *(secondary: thespoon.tech)*. JeeSauce can build the same thing itself. |
| **Retailer request forms** | H-E-B accepts customer product requests through its Contact form (In-store shopping → Product request), asking for the store, product name, manufacturer and UPC: https://www.heb.com/help/in-store/how-do-i-request-a-product-to-be-added (*instructions from the search snippet; the page itself is rendered with JavaScript*). | Free and goes straight to the retailer. JeeSauce can **pre-fill the details** so the shopper only has to paste them. | Free. |

## 3. Patterns, why they work, and what they cost

| # | Pattern | Who does it | Why it helps | Effort / cost for a small brand |
|---|---|---|---|---|
| P1 | **Flavor-first search + availability disclaimer** | OLIPOP, Destini clients, Ben & Jerry's | Shoppers usually want a specific flavor. A disclaimer sets honest expectations and cuts down on "it wasn't there" anger. | S. JeeSauce already has flavor filters; it only needs the disclaimer and freshness info. |
| P2 | **Results backed by sales data** | Destini (NielsenIQ/SPINS) | A store listing that comes from real sell-through data is more trustworthy. | Expensive through Destini. **JeeSauce already has KeHE/UNFI sell-through data**, so it can show "last delivery" dates itself. |
| P3 | **Online handoff with stock awareness** | MikMak, PriceSpider, ChannelSight, Shoppable, Instacart IDP | Catches shoppers who would rather order delivery, and avoids sending them to empty search results. | Instacart IDP is free; the others are enterprise-priced. |
| P4 | **"Request it at your store"** | Destini Consumer Requests, WeStock, H-E-B form | Turns a no-results search into a demand signal that can be shown to buyers. | S–M to build in-house. |
| P5 | **Search-demand map** | Destini Signals / analytics | Searches from ZIPs with no stores are evidence of unmet demand for distribution pitches. | S if search logs are aggregated by ZIP with no personal data stored. |
| P6 | **Receipt-verified rebates** | Aisle (Fly By Jing), Fetch, Liquid Death Country Club | Confirms an in-store purchase happened; drives trial. | M–L; about $500/month plus rebates. |
| P7 | **Referral / loyalty points** | OLIPOP ($15/$15), Liquid Death (Skulls for sharing) | Lowers acquisition cost for direct-to-consumer sales. | M. Note: offering rewards for sharing brings in CAN-SPAM and disclosure rules (see §4). |
| P8 | **"Spotted it" photos / sighting maps** | Entenmann's Social Spotters; fan-run maps like Attayo and the Wet n Wild sightings map (https://hunted.space/product/attayo, https://www.zeemaps.com/world-of-maps/?p=18); "What's in Stock" (https://uwaterloo.ca/news/whats-stock) | Free social proof, ready-made social posts, and a stream of fresh in-stock confirmations. | M, including moderation. |
| P9 | **Native share + honest counter** | McDonald's "Over 99 Billion Sold" (count stopped updating in 1994 and became "Billions and Billions Served": https://www.marketplace.org/2017/05/26/how-many-burgers-has-mcdonalds-actually-sold, https://www.mentalfloss.com/food/fast-food/14-facts-you-might-not-know-about-mcdonalds) | A counter shows social proof; sharing a specific store answers the friend's "where do I get it?" immediately. Use the **Web Share API** (the phone's own share sheet). An old, widely cited stat says only about 0.2% of mobile users ever tap traditional share buttons, while the native sheet offers the apps people actually use (https://css-tricks.com/?p=288685). | S. |
| P10 | **Launch / "now at" announcements and "tell me when it's near me" alerts** | Common at launches; Destini-style alerts | Turns no-result searches into future buyers when a new store opens nearby. | M. Requires opt-in. |
| P11 | **Printed request cards / QR shelf talkers** | WeStock advises QR codes at events and on printed materials | Lets shoppers request the product in person; a QR code at the shelf leads to the store's page. | S. |

## 4. Things that need care

1. **Collecting friends' emails ("send to a friend" forms).** Don't do it. If the site sends the email, JeeSauce may count as the "sender" under CAN-SPAM. If JeeSauce gives *anything of value* (points, sweepstakes entries, discounts) for sharing, it is the sender regardless of how the message is sent and must include opt-out and honor suppressions (FTC 2008 rule: https://olshanlaw.com/Advertising-Law-Blog/FTC-Position-Forward-Friend, https://www.ftc.gov/node/43504). Simply encouraging people to share, with no reward, does not create sender liability. **Recommendation:** use `navigator.share()` or copy-link, so the shopper sends the message from their own phone and JeeSauce never sees the friend's details. Don't reward shares. Reward only *purchases by the referred friend*, through a proper referral tool, if ever.
2. **Fake or inflated counters.** The FTC's 2024 rule (16 CFR 465.8) bans buying or distributing fake "indicators of social media influence" (likes, shares, views) used to misrepresent importance for commercial purposes (https://www.federalregister.gov/documents/2024/08/22/2024-18519/trade-regulation-rule-on-the-use-of-consumer-reviews-and-testimonials, https://www.bclplaw.com/en-US/events-insights-news/what-the-ftcs-final-rule-means-for-fake-indicators-of-social-media-influence-and-fake-review-websites.html). A seeded or padded on-site counter is also a general deceptive-practice risk. **Rules for the "Spread the love" counter:**
   - Start at 0, or at a real backfilled number with a stated source.
   - Count a share only when `navigator.share()` resolves successfully (a cancel throws `AbortError`, so it isn't counted) or the link was actually copied.
   - Rate-limit by IP/session to stop bots and self-inflation.
   - Label it plainly, e.g. "times a JeeSauce store was shared from this site".
   - Rounding down ("1,200+") is fine. Rounding up is not.
3. **Affiliate disclosure.** If Instacart IDP/Impact links earn commission, add a short, clear notice next to the links, e.g. "We may earn a small commission from Instacart orders." This follows the FTC Endorsement Guides.
4. **Retailer link breakage.** H-E-B and Albertsons product URLs and IDs change, and items get delisted. Check them every night and hide or fall back to a search URL when one fails (this is the core idea behind PriceSpider and ChannelSight).
5. **In-stock claims.** Never say "in stock". Say "carried at this store", plus "last delivered <date>" or "last spotted by a shopper <date>", and keep a "call ahead" disclaimer like OLIPOP's. Delivery data shows the product reached the store, not that it's on the shelf today. Shopper reports can be wrong; show how old each one is and expire them.
6. **User-uploaded photos and reports.** Moderate them before they appear. Strip location metadata (EXIF GPS) from photos. Show first names or initials only. Get a license grant in the terms before reusing photos in marketing.
7. **Location data.** "Use my location" coordinates should not be stored. Aggregate demand logs to ZIP level. Disclose this in the privacy policy (CCPA if California traffic is meaningful).
8. **Rebates / sweepstakes.** State sweepstakes rules apply. Rebate offers need clear terms.

## 5. Ranked proposals for findjeesauce.com

Ranked by value per unit of effort, with cheap, fun and honest ideas first.

| Rank | Proposal | Effort | Metric it moves |
|---|---|---|---|
| 1 | **"Send this store to a friend" via native share sheet + copy-link fallback.** Each store gets a shareable page, e.g. `/s/<store-slug>?f=<flavor>`, with a preview image showing the store name, address, flavors and the JeeSauce lid. No friend emails collected. | S | Shares per search; visits from shared links; new-visitor share |
| 2 | **Honest "Spread the love" counter.** Counts only completed shares (resolved `share()` or a real copy), rate-limited, never seeded, plainly labeled, rounded down. Optionally pair it with the existing "1,005 stores in 20 states" line as a pair of honest numbers. | S | Share rate (social proof); trust |
| 3 | **"Not near you yet? Ask your store" for searches with no nearby results.** One tap opens the retailer's request form (H-E-B's contact form, etc.) with copy-ready text: product, UPC, flavors, KeHE/UNFI item info. JeeSauce logs only *ZIP + chain* to measure demand. | S–M | Request count by ZIP/chain; new stores won where requests clustered |
| 4 | **Demand heatmap from search logs** (ZIP-level, no personal data). Shows which ZIPs search and come up empty and which flavors get filtered, to take into buyer meetings (Destini's "Signals", built in-house). | S | New-store pitches backed by data; store count |
| 5 | **Honest freshness labels + disclaimer.** "Last delivered: Oct 2026" per store from KeHE/UNFI sell-through, "call ahead" note, and stores without recent deliveries hidden or shown faded. | S–M | Fewer "wasn't there" complaints; locator → store-visit satisfaction |
| 6 | **Nightly retailer-link checker.** Check H-E-B, Albertsons, Instacart, DoorDash and Uber Eats links; fall back to a search URL and alert on failure. | S | Broken-link rate → 0; click-through to retailer |
| 7 | **"I found it!" one-tap confirmation** per store and flavor, with an optional moderated photo ("Spotted it"). Feeds "last spotted by a shopper N days ago" and a fun "sightings" gallery. | M | Weekly confirmations; user photos for social; freshness coverage |
| 8 | **Printable request card / QR shelf talker.** A PDF the shopper hands to a store manager ("Please stock JeeSauce: UPCs, distributor info") and a QR at the shelf linking to that store's page. | S | Requests; QR scans; new stores |
| 9 | **Instacart Developer Platform shopping-list link** pre-filled with the chosen flavor(s) for the shopper's local retailer, replacing the plain Instacart search link. Commission via Impact, with disclosure. | M | Delivery click-to-cart; affiliate revenue |
| 10 | **"Tell me when it's at my store" alert** with double opt-in for the shopper's own email or SMS, plus a "New near you" launch map and "Now at" badges when new stores go live. | M | Alert signups; conversion at launch |
| 11 | **Flavor-level share card / "my flavor" badge** ("I'm a Dilly Dilly person – find it near you"), shareable through the same share sheet. | S–M | Shares; flavor-filter use |
| 12 | **(Later) Receipt-verified "try it" rebate** via Aisle or Fetch for new markets. | L ($500/month+) | Trial purchases; first-party phone numbers |

Not recommended now: enterprise where-to-buy suites (Destini, MikMak, PriceSpider, ChannelSight) and paid Instacart Carrot Ads/brand pages, because the cost is too high for the stage. Also not recommended: "enter your friend's email" forms and rewarding people for sharing (CAN-SPAM and FTC rule risk).

## Sources

- https://destini.co/where-to-buy/ · https://destini.co/product-locators/ · https://support.destini.co/hc/en-us/articles/360035464813-What-are-Consumer-Requests
- https://www.storelocators.com/compare/destini-vs-storelocators · https://www.storelocators.com/compare/aisle-vs-storelocators
- https://mikmak.com/where-to-buy · https://www.adweek.com/brand-marketing/retail-data-firm-spins-acquires-mikmak/
- https://www.channelsight.com/channelsight-vs-pricespider · https://www.g2.com/compare/channelsight-vs-shoppable-where-to-buy
- https://martechseries.com/mobile/mobile-marketing/e-commerce-and-mobile-commerce/shoppable-instant-shop-to-empower-the-creator-economy-with-a-new-commerce-platform/
- https://company.instacart.com/business/developers · https://docs.instacart.com/developer_platform_api/ · https://docs.instacart.com/developer_platform_api/guide/concepts/launch_activities/conversions_and_payments · https://marketplace.referly.so/affiliate-programs/instacart · https://cpgguys.buzzsprout.com/1146830/11109687-brand-pages-shoppable-display-ads-with-instacart-s-ryan-mayward
- https://gotoaisle.com/ · https://www.gotoaisle.com/blog/beverage-brand-here-are-5-reasons-to-use-aisle-this-summer
- https://www.westock.io/post/westock-connecting-brands-with-retailers · https://westock.helpscoutdocs.com/article/20-using-your-request-form · https://thespoon.tech/tag/westock
- https://www.heb.com/help/in-store/how-do-i-request-a-product-to-be-added
- https://drinkolipop.com/pages/store-locator · https://flybyjing.com/pages/store-locator · https://ithacahummus.com/pages/wheretobuy · https://www.kerrygoldusa.com/store-locator/ · https://liquiddeath.com/pages/where-to-buy · https://sietefoods.com/shop · https://www.graza.co/pages/store-locator · https://www.strauss-group.com/faq/where-can-i-find-sabras-products-locally
- https://www.rivo.io/blog/liquid-death-country-club-loyalty-program · https://referralcodes.com/shop/olipop-referral
- https://www.surveymonkey.com/r/JKDYCLK (Entenmann's Social Spotters) · https://hunted.space/product/attayo · https://www.zeemaps.com/world-of-maps/?p=18 · https://uwaterloo.ca/news/whats-stock
- https://www.digitalcommerce360.com/2023/10/04/infographic-general-mills-incentivizes-customers-through-mobile-app-fetch/
- https://www.marketplace.org/2017/05/26/how-many-burgers-has-mcdonalds-actually-sold · https://www.mentalfloss.com/food/fast-food/14-facts-you-might-not-know-about-mcdonalds
- https://css-tricks.com/?p=288685 (Web Share API)
- https://olshanlaw.com/Advertising-Law-Blog/FTC-Position-Forward-Friend · https://www.ftc.gov/node/43504 (CAN-SPAM forward-to-a-friend)
- https://www.federalregister.gov/documents/2024/08/22/2024-18519/trade-regulation-rule-on-the-use-of-consumer-reviews-and-testimonials · https://www.bclplaw.com/en-US/events-insights-news/what-the-ftcs-final-rule-means-for-fake-indicators-of-social-media-influence-and-fake-review-websites.html
