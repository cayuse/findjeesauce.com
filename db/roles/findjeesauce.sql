-- findjeesauce's own login and databases on the shared sauce-postgis cluster
-- (rep's accessory). Idempotent: run it again to re-key the password.
-- Expects psql variable :password (bin/db-role sends it on stdin, never argv).
-- The role can't create databases or roles and gets no grants on anyone
-- else's tables; it owns only its three databases.

SELECT format('CREATE ROLE findjeesauce LOGIN PASSWORD %L', :'password')
 WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'findjeesauce') \gexec

ALTER ROLE findjeesauce WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD :'password';

SELECT format('CREATE DATABASE %I OWNER findjeesauce', d)
  FROM unnest(ARRAY['findjeesauce_production', 'findjeesauce_production_cache', 'findjeesauce_production_queue']) AS d
 WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = d) \gexec

-- Only findjeesauce (and the cluster owner) may connect to its databases.
REVOKE CONNECT ON DATABASE findjeesauce_production, findjeesauce_production_cache, findjeesauce_production_queue FROM PUBLIC;
GRANT CONNECT ON DATABASE findjeesauce_production, findjeesauce_production_cache, findjeesauce_production_queue TO findjeesauce;
