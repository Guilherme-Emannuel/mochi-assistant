# 02 — Database

**Goal:** an isolated `mochi` database and a `mochi_app` role on the existing PostgreSQL 16 container,
without touching the other databases.

Placeholders used below: `<pg-container>` (the Postgres container name) and `<superuser>` (its admin user).

## 1. Create role and database (once)

Run this from the repository root on the server. The password is typed in without echo, so it
doesn't end up in shell history:

```bash
read -rsp "New password for mochi_app: " MOCHI_PW; echo
docker exec -i <pg-container> psql -U <superuser> -d postgres \
  -v mochi_password="'$MOCHI_PW'" < db/migrations/000_create_database.sql
```

Save the password in your password manager. It goes into n8n's credential store later.

## 2. Apply the schema

```bash
docker exec -i -e PGPASSWORD="$MOCHI_PW" <pg-container> \
  psql -h localhost -U mochi_app -d mochi < db/migrations/001_init_schema.sql
unset MOCHI_PW
```

## 3. Verify

```bash
docker exec -it <pg-container> psql -U <superuser> -d mochi -c '\dt' -c 'SELECT * FROM schema_migrations;'
```

You should see `tasks`, `reminders`, `pending_actions`, `audit_log` and `schema_migrations`.

## 4. Let n8n reach the database

n8n runs in its own container, so check whether it shares a Docker network with Postgres:

```bash
docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' <n8n-container>
docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' <pg-container>
```

- **They share a network:** in n8n, the Postgres credential host is `<pg-container>`, port `5432`.
- **They don't:** attach n8n to the Postgres network. It's additive and reversible, and existing connections keep working:
  ```bash
  docker network connect <pg-network> <n8n-container>
  # rollback: docker network disconnect <pg-network> <n8n-container>
  ```
  This is lost if the n8n container is recreated. To make it permanent, add the network to n8n's compose file.

n8n credential: **Postgres** → host as above · database `mochi` · user `mochi_app` · SSL off (internal Docker network).

## Backup

Add the `mochi` database to the server's backup routine:

```bash
docker exec <pg-container> pg_dump -U <superuser> -Fc mochi > /path/to/backup/mochi-$(date +%F).dump
```
