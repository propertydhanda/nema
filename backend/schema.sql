-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- ── USERS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  display_name  TEXT NOT NULL,
  timezone      TEXT DEFAULT 'UTC',
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── LIFE EPOCHS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS life_epochs (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  description TEXT,
  started_at  DATE,
  ended_at    DATE,
  theme       TEXT,
  is_current  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── PEOPLE ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS people (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  full_name       TEXT NOT NULL,
  preferred_name  TEXT,
  category        TEXT CHECK (category IN ('family','friend','colleague','mentor','partner','acquaintance','other')),
  influence_score FLOAT DEFAULT 0.0,
  memory_count    INT DEFAULT 0,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── RELATIONSHIPS ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS relationships (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID REFERENCES users(id) ON DELETE CASCADE,
  person_id         UUID REFERENCES people(id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL,
  overall_valence   FLOAT,
  is_active         BOOLEAN DEFAULT TRUE,
  started_at        DATE,
  ended_at          DATE,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ── MEMORIES ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS memories (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID REFERENCES users(id) ON DELETE CASCADE,
  epoch_id              UUID REFERENCES life_epochs(id) ON DELETE SET NULL,

  -- Content
  raw_text              TEXT NOT NULL,
  summary               TEXT,

  -- Source monitoring (false memory prevention)
  input_modality        TEXT DEFAULT 'text' CHECK (input_modality IN ('text','voice_transcript','photo','audio','import')),
  source_type           TEXT DEFAULT 'direct' CHECK (source_type IN ('direct','told','inferred','ai_generated','reconstructed')),
  source_detail         TEXT,

  -- Layer (A–H)
  layer                 TEXT NOT NULL CHECK (layer IN ('episodic','semantic_self','emotional','procedural','social','values','narrative','future_self')),

  -- Temporal
  event_at              TIMESTAMPTZ,
  recorded_at           TIMESTAMPTZ DEFAULT NOW(),
  time_of_day           TEXT CHECK (time_of_day IN ('morning','afternoon','evening','night')),

  -- Emotion (amygdala-hippocampus)
  valence               FLOAT CHECK (valence BETWEEN -1 AND 1),
  arousal               FLOAT CHECK (arousal BETWEEN 0 AND 1),
  emotional_significance FLOAT CHECK (emotional_significance BETWEEN 0 AND 1),
  is_flashbulb          BOOLEAN DEFAULT FALSE,
  emotion_tags          TEXT[],

  -- Sensory context (encoding specificity)
  sensory_cues          JSONB,
  location_label        TEXT,
  location_lat          FLOAT,
  location_lng          FLOAT,

  -- Consolidation state
  consolidation_state   TEXT DEFAULT 'fresh' CHECK (consolidation_state IN ('fresh','consolidating','consolidated','remote')),

  -- Memory strength / SRS
  memory_strength       FLOAT DEFAULT 1.0,
  decay_rate            FLOAT DEFAULT 0.1,
  retrieval_count       INT DEFAULT 0,
  last_retrieved_at     TIMESTAMPTZ,
  next_review_at        TIMESTAMPTZ,

  -- Confidence
  certainty             TEXT DEFAULT 'certain' CHECK (certainty IN ('certain','likely','unsure')),

  -- Vector
  embedding             vector(1536),

  is_deleted            BOOLEAN DEFAULT FALSE,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_memories_user_layer    ON memories(user_id, layer);
CREATE INDEX IF NOT EXISTS idx_memories_event_at      ON memories(user_id, event_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_memories_consolidation ON memories(user_id, consolidation_state);

-- ── MEMORY ↔ PEOPLE ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS memory_people (
  memory_id     UUID REFERENCES memories(id) ON DELETE CASCADE,
  person_id     UUID REFERENCES people(id) ON DELETE CASCADE,
  role          TEXT DEFAULT 'present' CHECK (role IN ('subject','present','mentioned','cause','witness')),
  emotional_tone FLOAT,
  PRIMARY KEY (memory_id, person_id)
);

-- ── RETRIEVAL EVENTS (reconsolidation tracking) ────────────
CREATE TABLE IF NOT EXISTS retrieval_events (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  memory_id       UUID REFERENCES memories(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL,
  retrieved_at    TIMESTAMPTZ DEFAULT NOW(),
  retrieval_cue   TEXT,
  was_modified    BOOLEAN DEFAULT FALSE,
  retrieval_type  TEXT DEFAULT 'voluntary' CHECK (retrieval_type IN ('voluntary','involuntary','ai_surfaced'))
);

-- ── ENGRAMS (consolidated clusters) ───────────────────────
CREATE TABLE IF NOT EXISTS engrams (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             UUID REFERENCES users(id) ON DELETE CASCADE,
  label               TEXT NOT NULL,
  summary             TEXT,
  engram_type         TEXT DEFAULT 'episodic' CHECK (engram_type IN ('episodic','semantic','procedural','emotional')),
  tier                TEXT DEFAULT 'warm' CHECK (tier IN ('hot','warm','cold')),
  memory_count        INT DEFAULT 0,
  embedding           vector(1536),
  reactivation_count  INT DEFAULT 0,
  last_activated      TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS engram_memories (
  engram_id   UUID REFERENCES engrams(id) ON DELETE CASCADE,
  memory_id   UUID REFERENCES memories(id) ON DELETE CASCADE,
  PRIMARY KEY (engram_id, memory_id)
);

-- ── IDENTITY LAYER ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS identity_statements (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  statement_type  TEXT NOT NULL CHECK (statement_type IN ('i_am','i_avoid','i_seek','i_fear','i_believe','i_want','i_am_becoming')),
  content         TEXT NOT NULL,
  certainty       TEXT DEFAULT 'certain' CHECK (certainty IN ('certain','likely','unsure')),
  source          TEXT DEFAULT 'user' CHECK (source IN ('user','ai_inferred','interview')),
  is_active       BOOLEAN DEFAULT TRUE,
  embedding       vector(1536),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS core_values (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  value_name      TEXT NOT NULL,
  description     TEXT,
  origin_story    TEXT,
  priority_rank   INT,
  strength        FLOAT DEFAULT 1.0,
  embedding       vector(1536),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS personality_traits (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  trait_name      TEXT NOT NULL,
  trait_polarity  TEXT DEFAULT 'neutral' CHECK (trait_polarity IN ('strength','shadow','neutral')),
  description     TEXT,
  confidence_score FLOAT DEFAULT 0.5,
  evidence_count  INT DEFAULT 0,
  embedding       vector(1536),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS roles (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  role_name       TEXT NOT NULL,
  role_category   TEXT CHECK (role_category IN ('family','professional','social','identity','spiritual','creative','other')),
  description     TEXT,
  is_active       BOOLEAN DEFAULT TRUE,
  started_at      DATE,
  ended_at        DATE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS belief_systems (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  belief_domain   TEXT CHECK (belief_domain IN ('spiritual','philosophical','political','scientific','psychological','economic','relational','personal_myth','other')),
  belief_name     TEXT NOT NULL,
  belief_text     TEXT NOT NULL,
  certainty       TEXT DEFAULT 'certain' CHECK (certainty IN ('certain','likely','unsure','questioning')),
  is_active       BOOLEAN DEFAULT TRUE,
  embedding       vector(1536),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── IMPORT PIPELINE ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS import_jobs (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  source          TEXT CHECK (source IN ('photo','audio','whatsapp','notes','email','journal','custom')),
  status          TEXT DEFAULT 'pending' CHECK (status IN ('pending','processing','completed','failed','review_required')),
  file_path       TEXT,
  file_hash       TEXT,
  memories_created INT DEFAULT 0,
  raw_metadata    JSONB,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  completed_at    TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS import_candidates (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  import_job_id   UUID REFERENCES import_jobs(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL,
  proposed_text   TEXT NOT NULL,
  proposed_event_at TIMESTAMPTZ,
  proposed_location TEXT,
  proposed_layer  TEXT,
  review_status   TEXT DEFAULT 'pending' CHECK (review_status IN ('pending','approved','edited','rejected')),
  final_memory_id UUID REFERENCES memories(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── SEED: default user ─────────────────────────────────────
INSERT INTO users (id, display_name, timezone)
VALUES ('00000000-0000-0000-0000-000000000001', 'Vinit', 'America/Chicago')
ON CONFLICT DO NOTHING;

