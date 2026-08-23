-- migrate:up transaction:false
PRAGMA journal_mode = WAL;

CREATE TABLE spending (
  id TEXT PRIMARY KEY,
  amount_in_cent INTEGER NOT NULL,
  name TEXT,
  manage_key TEXT NOT NULL
);

-- migrate:down
DROP TABLE spending;
