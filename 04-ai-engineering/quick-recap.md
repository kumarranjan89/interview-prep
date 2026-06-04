# Quick Recap — 15-Minute Cheat Sheet

The fastest way to revise the entire syllabus before an interview. One section per chapter — just the essentials.

---

## Navigation
[README (Index)](./README.md) | [All AI Concepts](./all-ai-concepts.md) | [Interview Questions](./interview-questions.md)

---

## Ch 01 — LLM Fundamentals
- **LLM = next-token predictor** built on Transformers (self-attention). Patterns, not facts.
- **Token** ≈ 4 chars; cost is per token (input + output).
- **Context window** = working memory; LLMs are **stateless** between calls.
- **Temperature:** 0 = deterministic (code/data), 0.7 = balanced, 1+ = creative.
- **Hallucination** = confident wrong answer (predicts likely, not true). Fix with RAG + temp 0.
- **Roles:** system (instructions) / user / assistant. System prompt is your most powerful lever.

## Ch 02 — Embeddings & Vectors
- **Embedding** = vector capturing meaning (OpenAI small = 1536 dims).
- **Cosine similarity** (-1 to 1) measures semantic closeness via angle.
- **Vector DB** (Pinecone/Chroma/Qdrant/pgvector) does fast **ANN** search.
- **Chunk** long docs (500-1000 chars + overlap) before embedding.
- Start with `text-embedding-3-small`.

## Ch 03 — RAG
- **RAG = retrieve docs → augment prompt → generate.** Open-book exam for LLMs.
- **Indexing (offline):** load → chunk → embed → store. **Query (online):** embed → search top-k → grounded prompt → generate.
- Prompt rule: **"answer ONLY from context, else say I don't know."**
- Advanced: **hybrid search**, **re-ranking**, query transformation, metadata filters.
- **Most failures are retrieval failures** — inspect chunks first.

## Ch 04 — Agents & Tools
- **Agent = LLM in a loop:** Think → Act → Observe → Repeat → Answer.
- **Function calling:** LLM *requests* a tool call (JSON); **your code executes it**.
- **ReAct = Reasoning + Acting** (Thought → Action → Observation).
- Always set a **max iteration limit**; handle tool errors as observations.
- **Human-in-the-loop** for irreversible actions. Start single-agent.

## Ch 05 — Agentic Frameworks
- **Frameworks** = pre-built blocks; use when complexity justifies abstraction.
- **LangChain** + **LCEL** pipe (`prompt | llm | parser`) → streaming/retries free.
- **LangGraph** = stateful graph (nodes/edges/state) for loops & branches.
- **Linear → LangChain; cyclic/stateful → LangGraph.**
- Others: LlamaIndex (RAG), CrewAI/AutoGen (multi-agent), Vercel AI SDK (frontend).

## Ch 06 — Prompt Engineering
- Great prompt = **role + task + context + constraints + format + examples.**
- **Zero-shot** (simple), **few-shot** (show pattern), **CoT** (reason step by step).
- **Structured output** via schema (Pydantic/Zod) = guaranteed typed JSON.
- Use **delimiters** to separate data from instructions (defends **prompt injection**).

## Ch 07 — Memory & State
- LLMs are **stateless** — memory is an app layer you build.
- **Short-term** = conversation in context (sliding window / summarization).
- **Long-term** = facts in vector store, retrieved via RAG; isolate per user.
- **Lost in the middle:** put key info at start/end.
- Store only **durable, important facts** (memory extraction).

## Ch 08 — Evals & Observability
- **Evals = regression tests for AI.** You can't improve what you can't measure.
- Types: reference-based, reference-free, human, **LLM-as-judge** (scalable; calibrate it).
- RAG metrics: context precision/recall, **faithfulness**, answer relevance.
- **Tracing** = visibility per step → root cause.
- **Offline** (before ship) + **online** (sampling, feedback, A/B). Grow the dataset with every bug.

## Ch 09 — Production AI Systems
- Three pillars: **cost, latency, reliability.**
- **Cost:** right model, **caching** (exact/semantic/prompt), token reduction, **cascading**, batching.
- **Latency:** **streaming** (#1), smaller models, parallelism, caching.
- **Guardrails:** input (PII, injection, moderation, rate limit) + output (schema, faithfulness, moderation).
- **Reliability:** retries+backoff, timeouts, circuit breakers, fallbacks, graceful degradation.

## Ch 10 — Fine-Tuning
- **Fine-tuning teaches behavior/style, NOT facts** (use RAG for facts).
- Order: **prompting → few-shot → RAG → fine-tuning** (last resort).
- Use for: consistent style/format, narrow high-volume tasks, cost/latency reduction.
- **LoRA/QLoRA** = cheap adapter-based fine-tuning. Data: quality > quantity (JSONL).
- Always evaluate on held-out data; combine fine-tuning + RAG when needed.

## Ch 11 — Frontend AI
- Frontend = **last mile of AI**; great UX turns capability into value.
- **Streaming = #1 technique** (SSE/chunked); makes slow LLMs feel instant.
- **Vercel AI SDK:** `streamText`, `useChat`, `useObject`.
- **Never expose API keys in browser** — proxy via backend; rate-limit endpoints.
- Render Markdown richly, show **citations**, handle loading/error/stop states.
- **Generative UI** = LLM picks components, not just text.

## Ch 12 — AI System Design
- **7 steps:** Clarify → Define metrics → High-level → Deep dive → Scale → Evaluate → Trade-offs.
- **Clarify first** (scale, latency, budget, privacy) — signals seniority.
- **Pipeline thinking:** input → guardrails → retrieve + memory → generate → validate → observe.
- Estimate **cost at scale**; design caching/cascading to hit budget.
- **Discuss trade-offs** — there's no single right answer; reasoning is what counts.

---

## The 10 Most Important Takeaways

1. **LLMs predict tokens, not truth** — design around hallucinations.
2. **RAG for knowledge, fine-tuning for behavior** — never confuse the two.
3. **Retrieval quality caps RAG quality** — most failures are retrieval failures.
4. **The system prompt is your most powerful lever** — never skip it.
5. **Structured output (schemas) makes LLMs production-reliable.**
6. **Agents = LLM + tools + loop; the LLM decides, your code executes.**
7. **Evals are non-negotiable** — they're regression tests for AI.
8. **Streaming is the biggest perceived-latency win.**
9. **Never expose API keys client-side** — always proxy through a backend.
10. **In system design, clarify first and reason about trade-offs.**

---

## Key Numbers to Remember

| Thing | Number |
|-------|--------|
| 1 token | ≈ 4 characters ≈ 0.75 words |
| GPT-4 context | 128K tokens |
| Claude 3.5 context | 200K tokens |
| OpenAI small embedding | 1536 dims |
| Typical chunk size | 500-1000 chars |
| Typical top_k | 3-5 |
| Temperature for code | 0 |

---

## The Decision Cheat Sheet

```
Need facts/knowledge?          → RAG
Need behavior/style/format?    → Fine-tuning
Simple task?                   → Prompting
Need to show a pattern?        → Few-shot
Need reasoning?                → Chain-of-thought
Need actions/tools?            → Agent
Cyclic/stateful agent?         → LangGraph
Reduce cost?                   → Cascading + caching
Reduce perceived latency?      → Streaming
Measure quality?               → Evals + LLM-as-judge
```

---

## Final Interview Tips

- **Explain in plain English first**, then add technical depth.
- **Always mention trade-offs** — it signals senior thinking.
- **Reach for RAG before fine-tuning** — a common interview trap.
- **Mention evals and observability** — most candidates forget them.
- **Clarify before designing** in system design rounds.
- **Know your numbers** (tokens, context, costs).

**You've got this. Good luck!**

---

[← Interview Questions](./interview-questions.md) | [README (Index) →](./README.md)
