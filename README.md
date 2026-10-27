# findjeesauce.com

"Find JeeSauce near you": the public store finder. A small Rails 8 app that
copies the store list from rep (the field tool, `cayuse/sauce`) and serves it
to the public. Rep itself stays off the open internet: only this app's server
reads rep's store feed, with a token.

| | Staging | Live |
|---|---|---|
| URL | https://test.findjeesauce.com (noindex) | https://findjeesauce.com (+ www → bare) |
| Box | bigballs, behind its nginx, port 9396 | the GCP box, kamal-proxy |
| Reads rep at | https://sauce.cavaforge.net | https://rep.jeesauce.com |

## How it works

- `StoreFeed.sync!` (every 30 min, Solid Queue) fetches rep's
  `GET /api/v1/stores` with `REP_API_TOKEN` and replaces the `stores` table in
  one transaction, only when the whole fetch succeeded. Errors keep the last
  good copy; a feed that would drop over half the stores is refused. Every
  attempt is a `SyncRun`. Contract: rep `docs/api/rep-api.yaml`; tokens and
  rotation: rep `docs/API_CLIENTS_AND_TOKENS.md`.
- `/` search: a ZIP or city is geocoded in the browser (Google Maps, our own
  key) and sent as lat/lng; nearest stores first. Without a key, or with JS
  off, the server matches ZIPs and cities directly. "Use my location" uses the
  browser's location.
- `/stores/:id-name` a page per store (indexable, in `/sitemap.xml`).
- `/stores.json` the public copy for jeesauce.com to embed (CORS open; it is
  the same public list).

## Develop

```
cp .env.example .env
docker compose up app                       # port: docker compose port app 3000
docker compose exec app bin/rails stores:sync FILE=path/to/saved-feed.json
docker compose run --rm app bundle exec rspec
```

## Deploy (from gameforge)

```
kamal deploy -d staging
kamal deploy -d production
kamal sync -d staging        # pull the store list now
kamal status -d staging      # last syncs + token expiry
```

First time on a box: `bin/db-role staging|production` (our role and three
databases on the shared sauce-postgis cluster), then deploy. Secrets live in
`/home/sauce/secrets/findjeesauce/`:

- `master.key`
- `db.env`
- `google-maps.env`
- `rep-api.staging.env`
- `rep-api.production.env`

Never in git.
