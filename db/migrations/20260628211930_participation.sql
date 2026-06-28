-- migrate:up transaction:false
PRAGMA journal_mode = WAL;

CREATE TABLE participation (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  amount_in_cent INTEGER NOT NULL,
  participant_name TEXT,
  CONSTRAINT fk_session FOREIGN KEY (session_id) REFERENCES session(id) ON DELETE CASCADE
);
CREATE INDEX participation_session_index On participation(session_id);

-- migrate:down
DROP INDEX participation_session_index;
DROP TABLE participation;

