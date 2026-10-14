-- Mochi schema v1. Run as mochi_app, connected to the mochi database:
--   psql -U mochi_app -d mochi -f 001_init_schema.sql

\set ON_ERROR_STOP on
BEGIN;

-- Track applied migrations
CREATE TABLE IF NOT EXISTS schema_migrations (
  version     text PRIMARY KEY,
  applied_at  timestamptz NOT NULL DEFAULT now()
);

-- Generic updated_at trigger
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

-- ---------------------------------------------------------------------------
-- tasks: things I have to do or deliver
-- ---------------------------------------------------------------------------
CREATE TABLE tasks (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title         text        NOT NULL CHECK (length(trim(title)) > 0),
  notes         text,
  project       text,                                   -- free label, e.g. "UFMS", "Prefeitura"
  status        text        NOT NULL DEFAULT 'todo'
                CHECK (status IN ('todo', 'doing', 'done', 'cancelled')),
  priority      smallint    NOT NULL DEFAULT 2
                CHECK (priority BETWEEN 1 AND 4),       -- 1 = urgent ... 4 = someday
  due_at        timestamptz,
  source        text        NOT NULL DEFAULT 'desktop'
                CHECK (source IN ('desktop', 'whatsapp', 'web', 'system')),
  calendar_event_id text,                               -- link to a Google Calendar event, if any
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  completed_at  timestamptz,
  CONSTRAINT completed_at_matches_status
    CHECK ((status = 'done') = (completed_at IS NOT NULL))
);

CREATE INDEX tasks_open_due_idx ON tasks (due_at) WHERE status IN ('todo', 'doing');
CREATE INDEX tasks_project_idx  ON tasks (project);

CREATE TRIGGER tasks_set_updated_at
  BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- reminders: persistent, delivered by the mochi-reminders workflow
-- ---------------------------------------------------------------------------
CREATE TABLE reminders (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id     uuid REFERENCES tasks(id) ON DELETE CASCADE,
  message     text        NOT NULL,
  fire_at     timestamptz NOT NULL,
  channel     text        NOT NULL DEFAULT 'whatsapp'
              CHECK (channel IN ('whatsapp', 'desktop')),
  status      text        NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'sent', 'failed', 'cancelled')),
  attempts    smallint    NOT NULL DEFAULT 0,
  last_error  text,
  sent_at     timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX reminders_due_idx ON reminders (fire_at) WHERE status = 'pending';

CREATE TRIGGER reminders_set_updated_at
  BEFORE UPDATE ON reminders FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- pending_actions: human-in-the-loop approval queue (ADR-0005)
-- ---------------------------------------------------------------------------
CREATE TABLE pending_actions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tool          text        NOT NULL,                  -- e.g. 'create_event'
  payload       jsonb       NOT NULL,                  -- exact arguments that will be executed
  summary       text        NOT NULL,                  -- what I read before approving
  status        text        NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'approved', 'rejected', 'expired', 'executed', 'failed')),
  requested_via text        NOT NULL CHECK (requested_via IN ('desktop', 'whatsapp', 'web', 'system')),
  result        jsonb,
  created_at    timestamptz NOT NULL DEFAULT now(),
  expires_at    timestamptz NOT NULL DEFAULT now() + interval '15 minutes',
  decided_at    timestamptz,
  executed_at   timestamptz
);

CREATE INDEX pending_actions_open_idx ON pending_actions (created_at) WHERE status = 'pending';

-- ---------------------------------------------------------------------------
-- audit_log: append-only history of everything Mochi did
-- ---------------------------------------------------------------------------
CREATE TABLE audit_log (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  at         timestamptz NOT NULL DEFAULT now(),
  actor      text        NOT NULL CHECK (actor IN ('mochi', 'user', 'system')),
  action     text        NOT NULL,                     -- e.g. 'tool_call', 'approve', 'reminder_sent'
  target     text,                                     -- e.g. 'tasks:<uuid>'
  details    jsonb       NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX audit_log_at_idx ON audit_log (at DESC);

-- Append-only: block UPDATE and DELETE
CREATE OR REPLACE FUNCTION audit_log_readonly() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'audit_log is append-only';
END $$;

CREATE TRIGGER audit_log_no_update
  BEFORE UPDATE OR DELETE ON audit_log FOR EACH ROW EXECUTE FUNCTION audit_log_readonly();

-- ---------------------------------------------------------------------------
-- Helper functions used by n8n workflows
-- ---------------------------------------------------------------------------

-- Atomically claim due reminders (safe if two executions overlap)
CREATE OR REPLACE FUNCTION claim_due_reminders(max_rows int DEFAULT 20)
RETURNS SETOF reminders
LANGUAGE sql AS $$
  UPDATE reminders r
     SET attempts = r.attempts + 1
   WHERE r.id IN (
           SELECT id FROM reminders
            WHERE status = 'pending' AND fire_at <= now() AND attempts < 5
            ORDER BY fire_at
            LIMIT max_rows
            FOR UPDATE SKIP LOCKED)
  RETURNING r.*;
$$;

-- Expire stale approvals
CREATE OR REPLACE FUNCTION expire_pending_actions()
RETURNS integer
LANGUAGE sql AS $$
  WITH upd AS (
    UPDATE pending_actions
       SET status = 'expired', decided_at = now()
     WHERE status = 'pending' AND expires_at < now()
    RETURNING 1)
  SELECT count(*)::int FROM upd;
$$;

-- Today's agenda of tasks for the morning briefing
CREATE OR REPLACE VIEW tasks_briefing AS
SELECT id, title, project, priority, due_at,
       CASE WHEN due_at < now() THEN 'overdue'
            WHEN due_at < date_trunc('day', now() AT TIME ZONE 'America/Campo_Grande')
                          AT TIME ZONE 'America/Campo_Grande' + interval '1 day' THEN 'today'
            ELSE 'upcoming' END AS bucket
  FROM tasks
 WHERE status IN ('todo', 'doing')
   AND (due_at IS NULL OR due_at < now() + interval '7 days')
 ORDER BY (due_at IS NULL), due_at, priority;

INSERT INTO schema_migrations (version) VALUES ('001_init_schema');

COMMIT;
