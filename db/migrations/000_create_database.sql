-- Run ONCE as a Postgres superuser. Creates an isolated role + database for Mochi.
-- Usage (password is passed as a psql variable, never hard-coded):
--   psql -U <superuser> -d postgres -v mochi_password="'<strong-password>'" -f 000_create_database.sql
--
-- Safe for an existing server: it does not touch other databases or roles.

\set ON_ERROR_STOP on

CREATE ROLE mochi_app LOGIN PASSWORD :mochi_password
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;

CREATE DATABASE mochi OWNER mochi_app ENCODING 'UTF8' TEMPLATE template0;

-- Nobody else can connect to the mochi database
REVOKE CONNECT ON DATABASE mochi FROM PUBLIC;
GRANT CONNECT ON DATABASE mochi TO mochi_app;
