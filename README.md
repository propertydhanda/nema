# ⚡ Nema — Personal Memory Consciousness OS

> *νεῦμα — Greek for vital force, breath of life*

Nema is a neuroscience-inspired personal memory system that captures, stores, and retrieves your life the way your brain actually works — not as flat text, but as layered memory with emotional weight, associations, and context.

## Architecture

```
nema-agent (orchestrator)
├── neuma-capture   → voice/text/photo input
├── neuma-store     → hippocampus encoding pipeline  
└── neuma-recall    → emotionally intelligent retrieval
```

## Memory Layers (A–H)

| Layer | What It Holds |
|---|---|
| A — Episodic | Specific events: when/where/who/what |
| B — Semantic Self | Facts about you, identity statements |
| C — Emotional | Emotional experiences, feeling states |
| D — Procedural | Habits, skills, routines |
| E — Social | People, relationships, social graph |
| F — Values | Core principles, what matters most |
| G — Narrative | Life story arcs, turning points |
| H — Future Self | Goals, fears, who you're becoming |

## Stack

- **Backend:** Python + FastAPI + PostgreSQL 17 + pgvector (HNSW)
- **Embeddings:** all-MiniLM-L6-v2 (local, no API cost)
- **LLM:** Claude Haiku (layer classification + emotion extraction)
- **Mobile:** Flutter (iOS + Android + Web)
- **DB:** 16 tables covering full memory + identity + people graph

## Quick Start

```bash
# Backend
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --port 8600

# Flutter app
cd app
flutter pub get
flutter run -d chrome
```

## API

| Endpoint | Description |
|---|---|
| `POST /capture` | Store a memory (auto-classifies layer + emotion) |
| `POST /recall` | Semantic memory search with neuroscience scoring |
| `GET /memories` | List memories |
| `POST /identity/statement` | Add identity statement (I am / I seek / I believe) |
| `POST /identity/value` | Add a core value |
| `POST /people` | Add to people graph |
| `GET /stats` | Memory OS stats |
| `GET /docs` | Swagger UI |

## Neuroscience Foundation

Every architectural decision maps to brain science:

- **Hippocampus** → encoding pipeline (neuma-store)
- **Amygdala** → emotional significance tagging
- **Entorhinal cortex** → spatiotemporal indexing (event_at vs recorded_at)
- **Hebbian learning** → association graph
- **Memory consolidation** → hot/warm/cold tiers
- **Spaced repetition** → strength decay + next_review_at
- **Source monitoring** → false memory prevention (certainty labels)

---

Built by Vinit Mojes · Powered by Aura + Neuma
