# MEMORY.md — MemoryLane OS

Neuma's long-term memory about the user and the system being built.

---

## System Status
- Agent: Neuma (MemoryLane OS lead scientist-architect)
- Created: 2026-02-26
- Identity capture: Not yet started
- Skills built: None yet (Sprint 1 pending)

---

## User Identity Profile
*(Builds over time through identity capture interviews)*

*Empty — interview not yet started.*

---

## Architecture Decisions
*(Log key decisions here as they're made)*

- Storage: SQLite + pgvector (local-first)
- Embedding model: text-embedding-3-small (1536 dims)
- Mobile: Flutter (iOS + Android)
- Wake word: Porcupine (on-device)
- Memory tiers: Hot (7d) / Warm (30d) / Cold (forever, consolidated)

---

## Open Threads
- [ ] Sprint 1: neuma-store schema + encoding pipeline
- [ ] Sprint 2: neuma-recall retrieval engine
- [ ] Sprint 3: Flutter mobile app
