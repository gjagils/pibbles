-- Results and name changes per address per minute (index.js tooMany). Rows older than
-- a few minutes are deleted as new ones come in, so the table stays small.
CREATE TABLE rate_limits (
  key     TEXT NOT NULL,                  -- the sender's IP address
  minute  INTEGER NOT NULL,               -- unix ms / 60000
  count   INTEGER NOT NULL,
  PRIMARY KEY (key, minute)
);
