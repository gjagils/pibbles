-- Pibbles D1 schema. No personal data: a device is a random id, the name is
-- whatever the player chose to show on the ranking.

-- A week pack as uploaded (PUT /api/admin/week), for the preview page.
CREATE TABLE weeks (
  week_start  TEXT PRIMARY KEY,           -- yyyy-MM-dd, a Monday
  uploaded_at INTEGER NOT NULL            -- unix ms
);

-- One row per day: the four puzzles, with solutions, as JSON
-- {"blocks":{...},"logic":{...},"patterns":{...},"numbers":{...}}.
CREATE TABLE days (
  date        TEXT PRIMARY KEY,           -- yyyy-MM-dd
  week_start  TEXT NOT NULL REFERENCES weeks(week_start),
  puzzles     TEXT NOT NULL
);
CREATE INDEX days_week ON days(week_start);

-- Only the first result per device, date and kind counts (UNIQUE + INSERT OR IGNORE).
CREATE TABLE scores (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  date        TEXT NOT NULL,
  kind        TEXT NOT NULL,              -- blocks | logic | patterns | numbers
  device_id   TEXT NOT NULL,
  name        TEXT NOT NULL,
  ms          INTEGER NOT NULL,
  hints       INTEGER NOT NULL,
  score       INTEGER NOT NULL,           -- ms + 30000 * hints
  verified    INTEGER NOT NULL,           -- 1: checked against the stored pack
  created_at  INTEGER NOT NULL,
  UNIQUE (date, kind, device_id)
);
CREATE INDEX scores_board ON scores(date, kind, score, id);
