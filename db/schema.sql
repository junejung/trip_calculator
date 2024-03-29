-- This DROP statement drops a table if it exists and does nothing otherwise
--
-- SQLite will raise an error if we try to CREATE a table that 
-- already exists, or DROP a table that doesn't

DROP TABLE IF EXISTS addresses;

CREATE TABLE addresses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  label VARCHAR(32),
  content VARCHAR NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);

-- This guarantees that the label column is unique
CREATE UNIQUE INDEX label_index ON addresses(label);
