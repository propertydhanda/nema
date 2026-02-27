-- ============================================================
-- Migration 001 — Neuroscience Alignment Fixes
-- Based on: Dr. review of schema vs actual brain architecture
-- ============================================================

-- A) memory_fragments — distributed feature storage
-- Brains store sensory, affect, semantic features separately + bind at recall
CREATE TABLE IF NOT EXISTS memory_fragments (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  memory_id       UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
  feature_type    TEXT NOT NULL CHECK (feature_type IN (
                    'sensory',    -- sight, smell, sound, taste, touch
                    'emotion',    -- felt state at the time
                    'semantic',   -- meaning, interpretation
                    'social',     -- who, relationship context
                    'body',       -- somatic marker, physical sensation
                    'spatial',    -- place, environment
                    'temporal'    -- time-related detail
                  )),
  content         TEXT NOT NULL,          -- the actual fragment detail
  confidence      TEXT DEFAULT 'certain'
                    CHECK (confidence IN ('certain','likely','unsure')),
  source_type     TEXT DEFAULT 'direct'
                    CHECK (source_type IN ('direct','reconstructed','inferred','ai_suggested')),
  embedding       vector(384),            -- fragment-level embedding
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fragments_memory   ON memory_fragments(memory_id);
CREATE INDEX IF NOT EXISTS idx_fragments_type     ON memory_fragments(memory_id, feature_type);
CREATE INDEX IF NOT EXISTS idx_fragments_embed    ON memory_fragments USING hnsw (embedding vector_cosine_ops);


-- B) memory_revisions — versioning for reconsolidation
-- Every time a memory is edited after recall, we track what changed
CREATE TABLE IF NOT EXISTS memory_revisions (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  memory_id             UUID NOT NULL REFERENCES memories(id) ON DELETE CASCADE,
  retrieval_event_id    UUID REFERENCES retrieval_events(id) ON DELETE SET NULL,
  revised_at            TIMESTAMPTZ DEFAULT NOW(),
  changed_fields        JSONB NOT NULL,   -- diff: {"raw_text": {"from": "...", "to": "..."}}
  reason                TEXT CHECK (reason IN (
                          'user_edit',        -- user manually corrected
                          'interview',        -- updated during identity interview
                          'ai_suggestion',    -- AI proposed, user accepted
                          'reconsolidation',  -- spontaneous update after recall
                          'media_match'       -- photo/audio matched and updated detail
                        )),
  revised_by            TEXT DEFAULT 'user' CHECK (revised_by IN ('user','ai','system')),
  certainty_before      TEXT,             -- what certainty was before edit
  certainty_after       TEXT              -- what certainty is after edit
);

CREATE INDEX IF NOT EXISTS idx_revisions_memory    ON memory_revisions(memory_id);
CREATE INDEX IF NOT EXISTS idx_revisions_retrieval ON memory_revisions(retrieval_event_id);


-- C) relationship_id on memory_people
-- "This memory happened in the context of my relationship with X"
ALTER TABLE memory_people
  ADD COLUMN IF NOT EXISTS relationship_id UUID REFERENCES relationships(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_memory_people_rel ON memory_people(relationship_id);


-- D) Fuzzy time precision on memories
-- Autobiographical memory is often approximate — don't invent false exactness
ALTER TABLE memories
  ADD COLUMN IF NOT EXISTS event_time_precision TEXT DEFAULT 'unknown'
    CHECK (event_time_precision IN ('exact','approximate','unknown')),
  ADD COLUMN IF NOT EXISTS event_time_range_start TIMESTAMPTZ,  -- "sometime between..."
  ADD COLUMN IF NOT EXISTS event_time_range_end   TIMESTAMPTZ;  -- "...and this date"

-- Backfill: if event_at was set, mark as approximate (we don't know if user was precise)
UPDATE memories
  SET event_time_precision = 'approximate'
  WHERE event_at IS NOT NULL AND event_time_precision = 'unknown';


-- E) mood_at_recall on retrieval_events
-- Reconsolidation depends on emotional state at time of retrieval
ALTER TABLE retrieval_events
  ADD COLUMN IF NOT EXISTS mood_at_recall       FLOAT   -- valence at retrieval time (-1 to 1)
    CHECK (mood_at_recall BETWEEN -1 AND 1),
  ADD COLUMN IF NOT EXISTS arousal_at_recall    FLOAT   -- activation at retrieval (0 to 1)
    CHECK (arousal_at_recall BETWEEN 0 AND 1),
  ADD COLUMN IF NOT EXISTS notes                TEXT;   -- optional free text about recall context


-- F) cues table — explicit cue-based retrieval support
-- Enables "that smell from childhood" or "every time I hear that song" queries
CREATE TABLE IF NOT EXISTS cues (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  cue_type    TEXT NOT NULL CHECK (cue_type IN (
                'smell','sound','visual','taste','touch',  -- sensory
                'place','person','phrase','song',          -- contextual
                'date','season','weather',                 -- temporal
                'body_state','emotion_state'               -- internal
              )),
  cue_value   TEXT NOT NULL,              -- "pine trees", "rain on windows", "Bohemian Rhapsody"
  strength    FLOAT DEFAULT 0.5,          -- how reliably does this cue trigger recall? 0–1
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS memory_cues (
  memory_id   UUID REFERENCES memories(id) ON DELETE CASCADE,
  cue_id      UUID REFERENCES cues(id) ON DELETE CASCADE,
  trigger_strength FLOAT DEFAULT 0.5,    -- how strongly does THIS cue trigger THIS memory?
  PRIMARY KEY (memory_id, cue_id)
);

CREATE INDEX IF NOT EXISTS idx_cues_user      ON cues(user_id, cue_type);
CREATE INDEX IF NOT EXISTS idx_memory_cues_m  ON memory_cues(memory_id);
CREATE INDEX IF NOT EXISTS idx_memory_cues_c  ON memory_cues(cue_id);
