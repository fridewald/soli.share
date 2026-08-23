-- migrate:up transaction:false
PRAGMA journal_mode = WAL;

CREATE TABLE participation (
  id TEXT PRIMARY KEY,
  spending_id TEXT NOT NULL,
  amount_in_cent INTEGER NOT NULL,
  participant_name TEXT,
  CONSTRAINT fk_spending FOREIGN KEY (spending_id) REFERENCES spending(id) ON DELETE CASCADE
);
CREATE INDEX participation_spending_index On participation(spending_id);

-- migrate:down
DROP INDEX participation_spending_index;
DROP TABLE participation;
