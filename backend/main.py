from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv
import anthropic, os, json
from datetime import datetime

load_dotenv()

app = FastAPI(title="MemoryLane OS — Neuma", version="0.1.0")
app.add_middleware(CORSMiddleware,
    allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

DB_URL = os.getenv("DATABASE_URL")
DEFAULT_USER = os.getenv("DEFAULT_USER_ID")
claude = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

# Local embedding model — no API quota needed
from sentence_transformers import SentenceTransformer
_embed_model = SentenceTransformer("all-MiniLM-L6-v2")  # 384 dims, fast, local
EMBED_DIMS = 384

def get_db():
    return psycopg2.connect(DB_URL, cursor_factory=psycopg2.extras.RealDictCursor)

def embed(text: str) -> list:
    return _embed_model.encode(text).tolist()

def llm(prompt: str, max_tokens: int = 100) -> str:
    msg = claude.messages.create(
        model="claude-haiku-4-5",
        max_tokens=max_tokens,
        messages=[{"role": "user", "content": prompt}]
    )
    return msg.content[0].text.strip()

def classify_layer(text: str) -> str:
    layer = llm(f"""Classify this memory into ONE layer:
episodic|semantic_self|emotional|procedural|social|values|narrative|future_self

Memory: "{text}"
Reply with ONLY the layer name.""", 10).lower()
    valid = ['episodic','semantic_self','emotional','procedural','social','values','narrative','future_self']
    return layer if layer in valid else 'episodic'

def extract_emotion(text: str) -> dict:
    raw = llm(f"""Return JSON only for this memory:
{{"valence":<-1 to 1>,"arousal":<0 to 1>,"significance":<0 to 1>,"emotion_tags":["word1","word2"],"certainty":"certain|likely|unsure"}}
Memory: "{text}" """, 150)
    try:
        return json.loads(raw)
    except:
        return {"valence": 0.0, "arousal": 0.5, "significance": 0.5, "emotion_tags": [], "certainty": "certain"}

# ── MODELS ────────────────────────────────────────────────────────────────────

class CaptureRequest(BaseModel):
    text: str
    source_type: str = "direct"        # direct | told | inferred | ai_generated
    input_modality: str = "text"       # text | voice_transcript | photo
    event_at: Optional[str] = None     # ISO datetime string
    location_label: Optional[str] = None
    people_names: Optional[List[str]] = [] 

class RecallRequest(BaseModel):
    query: str
    limit: int = 5
    layer_filter: Optional[str] = None

class IdentityRequest(BaseModel):
    statement_type: str   # i_am | i_avoid | i_seek | i_fear | i_believe | i_want | i_am_becoming
    content: str
    certainty: str = "certain"

class ValueRequest(BaseModel):
    value_name: str
    description: Optional[str] = None
    origin_story: Optional[str] = None
    priority_rank: Optional[int] = None

class PersonRequest(BaseModel):
    full_name: str
    preferred_name: Optional[str] = None
    category: str = "friend"
    notes: Optional[str] = None

# ── ROUTES ────────────────────────────────────────────────────────────────────

@app.get("/")
def root():
    return {"status": "Neuma is alive ⚡", "version": "0.1.0"}

@app.get("/health")
def health():
    try:
        db = get_db()
        cur = db.cursor()
        cur.execute("SELECT COUNT(*) as c FROM memories WHERE user_id = %s", (DEFAULT_USER,))
        count = cur.fetchone()["c"]
        db.close()
        return {"status": "ok", "memories": count}
    except Exception as e:
        raise HTTPException(500, str(e))

# ── CAPTURE ───────────────────────────────────────────────────────────────────

@app.post("/capture")
def capture(req: CaptureRequest):
    """Store a new memory — full encoding pipeline"""
    # 1. Classify layer
    layer = classify_layer(req.text)
    # 2. Extract emotion
    emotion = extract_emotion(req.text)
    # 3. Generate embedding
    vector = embed(req.text)

    db = get_db()
    cur = db.cursor()

    # 4. Insert memory
    cur.execute("""
        INSERT INTO memories (
            user_id, raw_text, layer, source_type, input_modality,
            event_at, location_label,
            valence, arousal, emotional_significance, emotion_tags, certainty,
            embedding, consolidation_state, memory_strength
        ) VALUES (
            %s, %s, %s, %s, %s,
            %s, %s,
            %s, %s, %s, %s, %s,
            %s, 'fresh', 1.0
        ) RETURNING id, layer, consolidation_state
    """, (
        DEFAULT_USER, req.text, layer, req.source_type, req.input_modality,
        req.event_at, req.location_label,
        emotion.get("valence"), emotion.get("arousal"),
        emotion.get("significance"), emotion.get("emotion_tags", []),
        emotion.get("certainty", "certain"),
        str(vector)
    ))
    memory = dict(cur.fetchone())

    # 5. Link people if provided
    for name in (req.people_names or []):
        cur.execute("SELECT id FROM people WHERE user_id=%s AND (full_name ILIKE %s OR preferred_name ILIKE %s)", 
                    (DEFAULT_USER, name, name))
        row = cur.fetchone()
        if row:
            cur.execute("INSERT INTO memory_people (memory_id, person_id) VALUES (%s, %s) ON CONFLICT DO NOTHING",
                        (memory["id"], row["id"]))

    db.commit()
    db.close()

    return {
        "status": "captured",
        "memory_id": memory["id"],
        "layer": layer,
        "emotion": emotion,
        "consolidation_state": "fresh"
    }

# ── RECALL ────────────────────────────────────────────────────────────────────

@app.post("/recall")
def recall(req: RecallRequest):
    """Retrieve memories using semantic similarity + scoring"""
    vector = embed(req.query)

    db = get_db()
    cur = db.cursor()

    layer_clause = "AND layer = %s" if req.layer_filter else ""
    params = [str(vector), DEFAULT_USER]
    if req.layer_filter:
        params.append(req.layer_filter)
    params.append(req.limit)

    cur.execute(f"""
        SELECT
            id, raw_text, layer, source_type, certainty,
            valence, arousal, emotional_significance,
            consolidation_state, memory_strength, retrieval_count,
            event_at, location_label, emotion_tags,
            1 - (embedding <=> %s::vector) AS similarity,
            (
                (1 - (embedding <=> %s::vector)) * 0.40 +
                COALESCE(emotional_significance, 0.5) * 0.25 +
                COALESCE(memory_strength, 1.0) * 0.20 +
                CASE consolidation_state
                    WHEN 'fresh' THEN 0.15
                    WHEN 'consolidating' THEN 0.10
                    WHEN 'consolidated' THEN 0.05
                    ELSE 0.02
                END
            ) AS score
        FROM memories
        WHERE user_id = %s AND is_deleted = FALSE
        {layer_clause}
        ORDER BY score DESC
        LIMIT %s
    """, [str(vector), str(vector)] + params[1:])

    results = [dict(r) for r in cur.fetchall()]

    # Log retrieval events
    for r in results:
        cur.execute("""
            INSERT INTO retrieval_events (memory_id, user_id, retrieval_cue, retrieval_type)
            VALUES (%s, %s, %s, 'voluntary')
        """, (r["id"], DEFAULT_USER, req.query))
        cur.execute("""
            UPDATE memories SET retrieval_count = retrieval_count + 1, last_retrieved_at = NOW()
            WHERE id = %s
        """, (r["id"],))

    db.commit()
    db.close()

    return {"query": req.query, "results": results, "count": len(results)}

# ── IDENTITY ──────────────────────────────────────────────────────────────────

@app.post("/identity/statement")
def add_statement(req: IdentityRequest):
    vector = embed(req.content)
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        INSERT INTO identity_statements (user_id, statement_type, content, certainty, embedding)
        VALUES (%s, %s, %s, %s, %s) RETURNING id
    """, (DEFAULT_USER, req.statement_type, req.content, req.certainty, str(vector)))
    row = cur.fetchone()
    db.commit(); db.close()
    return {"status": "stored", "id": row["id"], "type": req.statement_type}

@app.get("/identity")
def get_identity():
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT statement_type, content, certainty, created_at
        FROM identity_statements WHERE user_id=%s AND is_active=TRUE
        ORDER BY statement_type, created_at
    """, (DEFAULT_USER,))
    rows = [dict(r) for r in cur.fetchall()]
    db.close()
    return {"identity": rows}

@app.post("/identity/value")
def add_value(req: ValueRequest):
    vector = embed(req.value_name + " " + (req.description or ""))
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        INSERT INTO core_values (user_id, value_name, description, origin_story, priority_rank, embedding)
        VALUES (%s, %s, %s, %s, %s, %s) RETURNING id
    """, (DEFAULT_USER, req.value_name, req.description, req.origin_story, req.priority_rank, str(vector)))
    row = cur.fetchone()
    db.commit(); db.close()
    return {"status": "stored", "id": row["id"]}

# ── PEOPLE ────────────────────────────────────────────────────────────────────

@app.post("/people")
def add_person(req: PersonRequest):
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        INSERT INTO people (user_id, full_name, preferred_name, category, notes)
        VALUES (%s, %s, %s, %s, %s) RETURNING id
    """, (DEFAULT_USER, req.full_name, req.preferred_name, req.category, req.notes))
    row = cur.fetchone()
    db.commit(); db.close()
    return {"status": "stored", "id": row["id"]}

@app.get("/people")
def list_people():
    db = get_db()
    cur = db.cursor()
    cur.execute("SELECT id, full_name, preferred_name, category, memory_count FROM people WHERE user_id=%s ORDER BY memory_count DESC", (DEFAULT_USER,))
    rows = [dict(r) for r in cur.fetchall()]
    db.close()
    return {"people": rows}

# ── MEMORIES ──────────────────────────────────────────────────────────────────

@app.get("/memories")
def list_memories(limit: int = 20, layer: Optional[str] = None):
    db = get_db()
    cur = db.cursor()
    if layer:
        cur.execute("SELECT id, raw_text, layer, valence, emotional_significance, consolidation_state, event_at, created_at FROM memories WHERE user_id=%s AND layer=%s AND is_deleted=FALSE ORDER BY created_at DESC LIMIT %s", (DEFAULT_USER, layer, limit))
    else:
        cur.execute("SELECT id, raw_text, layer, valence, emotional_significance, consolidation_state, event_at, created_at FROM memories WHERE user_id=%s AND is_deleted=FALSE ORDER BY created_at DESC LIMIT %s", (DEFAULT_USER, limit))
    rows = [dict(r) for r in cur.fetchall()]
    db.close()
    return {"memories": rows, "count": len(rows)}

@app.get("/stats")
def stats():
    db = get_db()
    cur = db.cursor()
    cur.execute("""
        SELECT
            COUNT(*) as total_memories,
            COUNT(DISTINCT layer) as layers_used,
            AVG(emotional_significance) as avg_significance,
            AVG(memory_strength) as avg_strength,
            SUM(retrieval_count) as total_retrievals
        FROM memories WHERE user_id=%s AND is_deleted=FALSE
    """, (DEFAULT_USER,))
    m = dict(cur.fetchone())
    cur.execute("SELECT COUNT(*) as people_count FROM people WHERE user_id=%s", (DEFAULT_USER,))
    m["people_count"] = cur.fetchone()["people_count"]
    cur.execute("SELECT COUNT(*) as identity_count FROM identity_statements WHERE user_id=%s AND is_active=TRUE", (DEFAULT_USER,))
    m["identity_count"] = cur.fetchone()["identity_count"]
    cur.execute("SELECT COUNT(*) as values_count FROM core_values WHERE user_id=%s", (DEFAULT_USER,))
    m["values_count"] = cur.fetchone()["values_count"]
    db.close()
    return m
