-- =============================================================================
-- Schéma SalleEnFrance — initialisation
-- =============================================================================

CREATE TABLE IF NOT EXISTS users (
  id          SERIAL PRIMARY KEY,
  email       TEXT UNIQUE NOT NULL,
  password    TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sites (
  id     SERIAL PRIMARY KEY,
  name   TEXT NOT NULL,
  city   TEXT NOT NULL,
  region TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS rooms (
  id        SERIAL PRIMARY KEY,
  site_id   INT REFERENCES sites(id) ON DELETE CASCADE,
  name      TEXT NOT NULL,
  capacity  INT NOT NULL
);

CREATE TABLE IF NOT EXISTS bookings (
  id         SERIAL PRIMARY KEY,
  room_id    INT REFERENCES rooms(id) ON DELETE CASCADE,
  user_id    INT REFERENCES users(id) ON DELETE CASCADE,
  starts_at  TIMESTAMPTZ NOT NULL,
  ends_at    TIMESTAMPTZ NOT NULL,
  CHECK (ends_at > starts_at)
);

INSERT INTO users (email, password) VALUES
  ('demo@salleenfrance.fr', 'changeme'),
  ('admin@salleenfrance.fr', 'changeme')
ON CONFLICT DO NOTHING;

INSERT INTO sites (name, city, region) VALUES
  ('SalleEnFrance Paris République',  'Paris',     'Île-de-France'),
  ('SalleEnFrance Lyon Part-Dieu',    'Lyon',      'Auvergne-Rhône-Alpes'),
  ('SalleEnFrance Marseille Vieux-Port', 'Marseille', 'Provence-Alpes-Côte-d''Azur'),
  ('SalleEnFrance Bordeaux Chartrons','Bordeaux',  'Nouvelle-Aquitaine'),
  ('SalleEnFrance Lille Euralille',   'Lille',     'Hauts-de-France')
ON CONFLICT DO NOTHING;

INSERT INTO rooms (site_id, name, capacity) VALUES
  (1, 'Versailles',  12),
  (1, 'Concorde',    8),
  (2, 'Fourvière',   10),
  (2, 'Croix-Rousse', 6),
  (3, 'Calanques',   14),
  (4, 'Garonne',     8),
  (5, 'Beffroi',     12)
ON CONFLICT DO NOTHING;
