# AI Engineering Knowledge Base
> **Your go-to place for AI/ML engineering concepts, interview prep, and practical examples.**

---

## How to Use This Repo

| Situation | What to open |
|---|---|
| Starting a new topic | Open the numbered chapter |
| Night before interview | `interview-questions.md` → your section |
| 30 min before interview | `quick-recap.md` |
| Need a code example fast | The chapter's `## Code Example` section |
| Forgot a concept | `all-ai-concepts.md` → Ctrl+F |

---

## Chapters

| # | File | Topic | Status |
|---|---|---|---|
| 01 | [01-llm-fundamentals.md](./01-llm-fundamentals.md) | LLM Fundamentals — tokens, embeddings, how LLMs work | ✅ |
| 02 | [02-embeddings-and-vectors.md](./02-embeddings-and-vectors.md) | Embeddings & Vector Databases | 🔜 |
| 03 | [03-rag.md](./03-rag.md) | RAG — Retrieval Augmented Generation | 🔜 |
| 04 | [04-agents-and-tools.md](./04-agents-and-tools.md) | Agents, Tool Use & ReAct Pattern | 🔜 |
| 05 | [05-agentic-frameworks.md](./05-agentic-frameworks.md) | LangChain, LangGraph & Agentic Frameworks | 🔜 |
| 06 | [06-prompt-engineering.md](./06-prompt-engineering.md) | Prompt Engineering & Structured Output | 🔜 |
| 07 | [07-memory-and-state.md](./07-memory-and-state.md) | Memory in LLMs and Agents | 🔜 |
| 08 | [08-evals-and-observability.md](./08-evals-and-observability.md) | Evals, Tracing & Observability | 🔜 |
| 09 | [09-production-ai-systems.md](./09-production-ai-systems.md) | Production AI — Cost, Latency, Guardrails | 🔜 |
| 10 | [10-fine-tuning.md](./10-fine-tuning.md) | Fine-Tuning — When & How | 🔜 |
| 11 | [11-frontend-ai.md](./11-frontend-ai.md) | AI + Frontend — Your Superpower | 🔜 |
| 12 | [12-system-design.md](./12-system-design.md) | AI System Design (Staff-level interviews) | 🔜 |

---

## Quick Reference Files

| File | Purpose |
|---|---|
| [interview-questions.md](./interview-questions.md) | All interview Q&A in one place, by chapter |
| [all-ai-concepts.md](./all-ai-concepts.md) | Every concept, one file — Ctrl+F your way through |
| [quick-recap.md](./quick-recap.md) | 30-minute pre-interview cheatsheet |
| [mental-models.md](./mental-models.md) | Analogies and mental models for every concept |
| [code-snippets/](./code-snippets/) | Runnable code examples by topic |

---

## Learning Path

```
Week 1–2    Chapter 01 → LLM Fundamentals
            Chapter 02 → Embeddings & Vectors

Week 3–4    Chapter 03 → RAG (build a working pipeline)

Week 5–6    Chapter 04 → Agents & Tool Use
            Chapter 05 → LangGraph

Week 7–8    Chapter 06 → Prompt Engineering
            Chapter 07 → Memory & State

Week 9–10   Chapter 08 → Evals & Observability
            Chapter 09 → Production Systems

Week 11–12  Chapter 10 → Fine-Tuning
            Chapter 11 → Frontend + AI (your moat)
            Chapter 12 → System Design prep
```

---

## Your Unique Advantage

> Most AI engineers **cannot build the UI layer.**
> You can.

Lean hard into this in interviews:

- Streaming token UIs (SSE + React)
- Real-time agent progress visualization
- AI-native component libraries
- Prompt playground tools

The combination of **deep frontend + AI engineering** is rare and commands a premium at product companies.

---

**Key insight:** You don't need to become a pure ML engineer. The gap in the market is engineers who understand AI systems AND can build production-grade user interfaces for them.

---

## Repository Structure

```
ai-engineering-kb/
├── README.md                    ← You are here (index)
├── 01-llm-fundamentals.md
├── 02-embeddings-and-vectors.md
├── 03-rag.md
├── 04-agents-and-tools.md
├── 05-agentic-frameworks.md
├── 06-prompt-engineering.md
├── 07-memory-and-state.md
├── 08-evals-and-observability.md
├── 09-production-ai-systems.md
├── 10-fine-tuning.md
├── 11-frontend-ai.md
├── 12-system-design.md
├── interview-questions.md       ← All Q&A in one file
├── all-ai-concepts.md           ← Master reference
├── quick-recap.md               ← Pre-interview cheatsheet
├── mental-models.md             ← Analogies & intuition
└── code-snippets/
    ├── 01-openai-basics.py
    ├── 02-embeddings.py
    ├── 03-rag-pipeline.py
    ├── 04-react-agent.py
    ├── 05-langgraph-flow.py
    └── 11-streaming-ui.tsx
```

---

## Progress Tracker

Mark chapters as you complete them. Update the table above.

- ✅ Complete — read + code example done + exercises done
- 🔄 In Progress
- 🔜 Not started

**Rule:** Don't mark ✅ until you've written your own interview answer for that chapter's key questions.

---

*Start with [Chapter 01 → LLM Fundamentals](./01-llm-fundamentals.md)*