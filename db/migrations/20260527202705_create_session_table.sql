-- migrate:up transaction:false
PRAGMA journal_mode = WAL;

CREATE TABLE session (
  id TEXT PRIMARY KEY,
  amount_in_cent INTEGER NOT NULL
);

-- migrate:down
DROP TABLE session;

