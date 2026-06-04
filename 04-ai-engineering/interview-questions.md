# Interview Questions — Master List

All interview questions from every chapter, in one place. Use this for final revision and mock interviews.

---

## Navigation
[README (Index)](./README.md) | [All AI Concepts](./all-ai-concepts.md) | [Quick Recap](./quick-recap.md)

---

## Chapter 01 — LLM Fundamentals

**Q1: What is an LLM and how does it work?**
A neural network trained to predict the next token, built on the Transformer architecture with self-attention. It learns statistical patterns (not facts) from massive text, and generates responses one token at a time based on probabilities influenced by temperature. It's pattern completion, not database lookup — which is why it generalizes and also hallucinates.

**Q2: What is a context window and why does it matter in production?**
The max text an LLM can process in one call (input + output). It's the model's working memory; nothing outside it exists to the model. Matters because cost scales with tokens, long conversations need overflow strategies (truncate/summarize), and attention degrades in very long contexts ("lost in the middle"). RAG addresses this by retrieving only relevant chunks.

**Q3: Why do LLMs hallucinate and how do you mitigate it?**
They're optimized to predict likely text, not true text, so they fill gaps with plausible-sounding content. Mitigations: RAG (ground answers in provided context), temperature 0 for factual tasks, and output validation (faithfulness checks). For high-stakes domains, treat output as a draft needing human verification.

**Q4: Difference between parameters and the context window?**
Parameters are the fixed learned weights (long-term knowledge/skills). The context window is runtime working memory for a single call. More parameters → smarter but needs retraining; larger context → remembers more in one conversation.

---

## Chapter 02 — Embeddings & Vectors

**Q1: What is an embedding and why is it useful?**
A numerical vector representing text's semantic meaning. Enables semantic search, similarity, recommendations, and clustering because similar concepts have similar vectors that we can compare mathematically.

**Q2: How do you measure similarity between embeddings?**
Cosine similarity — the cosine of the angle between vectors (-1 to 1). Preferred over Euclidean distance because it captures semantic direction regardless of magnitude.

**Q3: What is a vector database and why not use PostgreSQL?**
A DB specialized for storing and ANN-searching high-dimensional vectors using indexes like HNSW. Traditional DBs lack optimized similarity search at scale. For <10K vectors, pgvector is fine; at scale, use Pinecone/Weaviate/Qdrant.

**Q4: Explain RAG in simple terms.**
Retrieve relevant documents via vector search, add them to the prompt, and have the LLM answer from that context. Combines LLM reasoning with your up-to-date, private data — reducing hallucinations and stale knowledge.

**Q5: Trade-offs between embedding models?**
Dimensionality (nuance vs speed/storage), quality vs cost (OpenAI vs open-source), domain specificity, and speed. Start with `text-embedding-3-small`; switch to open-source if cost matters.

**Q6: How do you handle documents too long to embed?**
Chunk them (e.g., 500-1000 chars with overlap), embed each chunk, store all, and retrieve the most relevant. Chunking strategy depends on data type (code by function, prose by paragraph).

---

## Chapter 03 — RAG

**Q1: What is RAG and why better than fine-tuning for knowledge?**
RAG injects retrieved documents into the prompt so the model answers from context. Better for knowledge because updates are just document edits (no retraining), it provides citations, reduces hallucinations, and is cheaper. Fine-tuning is for behavior/style, RAG for facts.

**Q2: Walk me through a RAG pipeline.**
Indexing (offline): load → chunk → embed → store with metadata. Query (online): embed question → vector search top-K → build grounded prompt → LLM generates → optional citations.

**Q3: Why is chunking important and how to choose size?**
Respects token limits, improves retrieval precision, manages context cost. Too small loses context; too large adds noise. Start ~500-1000 chars with 10-15% overlap; tune by content type and evaluation.

**Q4: How do you reduce hallucinations in RAG?**
Instruct "answer ONLY from context, say I don't know"; temperature 0; improve retrieval (re-ranking, hybrid); faithfulness checks; require citations.

**Q5: What is hybrid search and when do you need it?**
Combines semantic + keyword (BM25) search. Needed when data has exact terms (codes, names, acronyms) that pure semantic search misses.

**Q6: How do you evaluate a RAG system?**
Retrieval: context precision/recall, hit rate, MRR. Generation: faithfulness, answer relevance, correctness. Tools: RAGAS, TruLens, LangSmith. Most failures are retrieval failures — inspect chunks first.

**Q7: What is re-ranking and why use it?**
Two-stage: fast vector search for top ~20, then an accurate cross-encoder re-scores to top 3-5. Cross-encoders judge query+doc together for better relevance, improving quality affordably.

---

## Chapter 04 — Agents & Tools

**Q1: Difference between an LLM and an agent?**
An LLM only generates text. An agent uses the LLM as a reasoning engine in a loop that takes actions via tools — deciding, calling, observing, repeating until done.

**Q2: Explain the ReAct pattern.**
Reasoning + Acting: the LLM alternates Thought → Action → Observation, using each result to inform the next step. More reliable than one-shot for multi-step tasks.

**Q3: How does function calling work? Does the LLM run code?**
No. The LLM returns a structured JSON request (tool name + args). Your code validates and executes it, then feeds the result back. This separation ensures safety.

**Q4: How do you prevent runaway cost/infinite loops?**
Max iteration limit, token/cost budget, cheaper models, clear stopping conditions, tool timeouts, and monitoring.

**Q5: What makes a good tool definition?**
Clear specific name, precise description (the LLM chooses based on it), well-typed parameters with descriptions/examples, and defined required fields.

**Q6: When use multiple agents vs one?**
Multi-agent for distinct specialized sub-roles (research/write/review). It adds cost, latency, and coordination complexity — start single-agent, escalate only when needed.

**Q7: How do you handle dangerous/irreversible actions?**
Human-in-the-loop approval, least-privilege tool permissions, argument validation, sandboxing, dry-run modes, and audit logging.

---

## Chapter 05 — Agentic Frameworks

**Q1: Why use a framework vs raw API calls?**
Pre-built composable components, integrations, and built-in streaming/retries/observability speed up complex apps. Trade-off: abstraction and version churn. Raw calls are clearer for simple tasks.

**Q2: What is LCEL and why useful?**
LangChain Expression Language — pipe-based composition (`prompt | llm | parser`). Chains get streaming, async, batching, and retries for free; readable and reusable.

**Q3: Difference between LangChain and LangGraph?**
LangChain chains are mostly linear; LangGraph models a stateful graph with loops, branches, and persistence. Linear flow → LangChain; cyclic/stateful agents → LangGraph.

**Q4: How does LangGraph model an agent?**
As a state graph: nodes are steps (call LLM, run tool), edges are transitions (conditional), and a shared state passes between them. Loops are explicit (tool → back to agent).

**Q5: When would you NOT use a framework?**
Simple single-step tasks, need for maximum control, minimal dependencies, or when abstraction hinders debugging. Prototype raw, adopt a framework when complexity justifies it.

**Q6: Name some frameworks and strengths.**
LangChain (general/composable), LangGraph (stateful agents), LlamaIndex (data/RAG), CrewAI (role-based multi-agent), AutoGen (conversational multi-agent), Vercel AI SDK (frontend/streaming).

---

## Chapter 06 — Prompt Engineering

**Q1: What is prompt engineering and why does it matter?**
Designing LLM inputs for reliable, useful outputs. It's the cheapest, fastest lever to improve quality without retraining. Good prompts specify role, task, context, constraints, and format.

**Q2: Explain zero-shot, few-shot, and chain-of-thought.**
Zero-shot: no examples (simple tasks). Few-shot: examples demonstrating pattern/format (consistency). CoT: reason step by step (math/logic/complex). Combine for the most power.

**Q3: How do you get reliable structured output?**
In order of reliability: prompt instruction → JSON mode → schema-based structured outputs (Pydantic/Zod, guaranteed + typed) → function calling. Use schemas in production.

**Q4: Why does chain-of-thought improve accuracy?**
Intermediate reasoning tokens give the model "working space" to break problems into steps before committing — like scratch paper. Trade-off: more tokens/cost.

**Q5: What is prompt injection and how to defend?**
Malicious input overriding intended behavior. Defenses: delimiters (mark data as data), input validation, output checks, keep secrets out of prompts, moderation — defense-in-depth.

**Q6: What makes a good system prompt?**
Clear role/persona, task, explicit rules/constraints, tone, output format, delimiters, and what NOT to do — without conflicting instructions. It governs the whole conversation.

---

## Chapter 07 — Memory & State

**Q1: LLMs are stateless — how do chatbots "remember"?**
The app stores conversation history and resends it each call. The model isn't remembering — the application manages state and feeds it back, using windows/summarization to fit the context.

**Q2: Short-term vs long-term memory?**
Short-term: current session history in context window (bounded). Long-term: durable facts in external store, retrieved via RAG across sessions.

**Q3: How do you handle a conversation exceeding the context window?**
Sliding window, summarization, token trimming, or retrieval. Production pattern is hybrid: running summary + recent verbatim + retrieved memories.

**Q4: How does long-term memory work and relate to RAG?**
RAG applied to memories: extract durable facts, embed, store; before responding, retrieve relevant memories and inject them. The "documents" are facts about the user.

**Q5: What is the "lost in the middle" problem?**
LLMs attend best to the start/end of context and miss the middle. Mitigate by placing key info at start/end and retrieving only relevant content.

**Q6: Design memory for a multi-user assistant.**
Short-term: per-session summary + recent window. Long-term: vector store namespaced by user ID, with memory extraction. Add token budgeting, lost-in-the-middle handling, and privacy controls; consider mem0/Zep/LangGraph checkpointing.

---

## Chapter 08 — Evals & Observability

**Q1: How do you evaluate when there's no single correct answer?**
Mix methods: reference-based (accuracy/similarity) for ground truth; LLM-as-judge for open-ended qualities; human eval for calibration; implicit production signals. Build a representative dataset and measure systematically.

**Q2: What is LLM-as-judge and its limitations?**
A strong LLM grades output against a rubric — scalable and effective. Limitations: bias (verbosity, position, self-preference) and mistakes. Calibrate against humans; use clear rubrics and reasoning-before-score.

**Q3: Why are evals important when changing a prompt or model?**
LLM behavior is sensitive; small changes can silently regress. Evals are regression tests — compare scores before/after to change with confidence and quantify trade-offs.

**Q4: Offline vs online evaluation?**
Offline: fixed dataset before shipping (catch regressions). Online: live traffic via sampling, feedback, implicit signals, A/B testing. Production needs both.

**Q5: What would you trace in a RAG app and why?**
Query, embedding, retrieved chunks + scores, assembled prompt + tokens, LLM model/latency/tokens/cost, final response + eval score. Reveals root cause (retrieval vs prompt vs model).

**Q6: How do you build a good eval dataset?**
Start small (20-50), grow over time. Source from production (anonymized), edge cases, synthetic, and feedback. Include failure modes; add each bug as a regression test; version with code.

---

## Chapter 09 — Production AI Systems

**Q1: How do you optimize cost in production?**
Right-size models, caching (exact/semantic/prompt), token reduction, model cascading, batching, and monitoring with budgets. Match model capability to task difficulty.

**Q2: How do you reduce latency?**
Streaming (biggest perceived win), smaller/faster models, parallel calls, caching, shorter outputs, prompt caching. Minimize sequential calls on the critical path.

**Q3: What are guardrails and what types exist?**
Safety checks. Input: validation, PII redaction, injection defense, moderation, rate limiting. Output: schema validation, faithfulness checks, moderation, PII filtering, fallbacks.

**Q4: How do you handle failures and ensure reliability?**
Retries with backoff, timeouts, circuit breakers, fallback models/providers, graceful degradation, plus monitoring/alerting. A transient failure should never break UX.

**Q5: What is model cascading and when to use it?**
Try a cheap model first, escalate to a strong one when uncertain/complex. Use with mixed-difficulty traffic to capture cost savings while preserving quality on hard cases.

**Q6: How do you secure an LLM application?**
No hardcoded keys, anonymize PII (or use Azure/self-hosted), injection defenses, least-privilege tools, human-in-the-loop, moderation, rate limiting, audit logs, and data-policy awareness — defense-in-depth.

---

## Chapter 10 — Fine-Tuning

**Q1: When fine-tune vs RAG vs prompting?**
Prompting first (cheapest), few-shot to show patterns, RAG for knowledge (especially changing), fine-tuning for consistent style/format, narrow high-volume tasks, or cost/latency. RAG = knowledge, fine-tuning = behavior; combine when needed.

**Q2: Why is fine-tuning usually wrong for knowledge?**
It bakes facts in at training time → stale, expensive to update, and prone to hallucination. RAG stores facts retrievably, updatable anytime with citations.

**Q3: What is LoRA and why popular?**
Low-Rank Adaptation: freezes original weights, trains small adapter matrices. Cheap, fast, tiny files, swappable, near full-fine-tuning quality. QLoRA adds quantization for big models on one GPU.

**Q4: How do you prepare fine-tuning data?**
Collect input-output examples reflecting desired behavior, format as JSONL (full conversations ending in assistant), prioritize quality over quantity, ensure consistency/diversity, match production format, hold out a test set, and validate programmatically.

**Q5: How do you know if fine-tuning was successful?**
Evaluate on held-out data; compare vs base model and vs prompting/RAG; check for overfitting; measure cost/latency. Success = meaningful, generalizable improvement justifying the complexity.

**Q6: Can you combine fine-tuning and RAG?**
Yes — often best. Fine-tune for behavior/style/format, use RAG for current facts. Separates "how to respond" from "what to respond with."

---

## Chapter 11 — Frontend AI

**Q1: Why is streaming important and how does it work?**
LLMs are slow (token-by-token); spinner UX feels broken. Streaming renders text as generated, improving perceived latency. Uses SSE/chunked responses: backend streams (`stream: true`), frontend reads chunks and updates state.

**Q2: How do you keep API keys secure in a web app?**
Never in client code. Proxy LLM calls through your backend where the key lives server-side; add rate limiting, auth, validation, and cost controls at the endpoint.

**Q3: What is generative UI?**
LLM produces structured data or selects UI components (e.g., a weather card) instead of text; the frontend renders real components. Combines tool calling + structured output + streaming.

**Q4: How do you handle errors and loading states?**
Meaningful "thinking" feedback (show agent actions), optimistic UI, clear error messages with retry, stop controls for long streams, and cancel stale requests. Makes a slow, non-deterministic system feel reliable.

**Q5: What is the Vercel AI SDK?**
A TS toolkit: backend helpers (`streamText`, `generateText`) and React hooks (`useChat`, `useCompletion`, `useObject`) managing streaming state, history, and controls. Supports tools, structured output, generative UI.

**Q6: How and why display RAG citations?**
Render the retrieved sources (links/footnotes/cards) alongside the answer using metadata returned by the backend. Builds trust, enables verification, and provides transparency — vital in high-stakes domains.

---

## Chapter 12 — AI System Design

**Q1: Design a Q&A system over 10M documents.**
Clarify scale/latency/freshness/accuracy. RAG at scale: offline indexing with a sharded vector DB; query-time hybrid search + re-ranking + grounded generation with citations. Add caching, cascading, streaming, evals, observability. Discuss chunk size, top-k, re-indexing, cost/query trade-offs.

**Q2: How decide RAG vs fine-tuning vs prompting in a design?**
Prompting default; RAG for knowledge (changing/large); fine-tuning for style/format, narrow high-volume, or cost/latency. Typically RAG for knowledge + prompting for behavior; fine-tune only if evals demand. Combine when needed.

**Q3: Control cost across millions of queries?**
Caching, model routing/cascading, token reduction, batching, right-sizing, and monitoring with budgets/alerts. Estimate cost upfront (queries × cost/query) and design to hit budget.

**Q4: Ensure quality and catch regressions?**
Evaluation loop: versioned offline eval set run on every change; online sampling, user feedback, implicit signals, A/B tests; tracing for root cause; every bug becomes a new case. Continuous deploy → trace → feedback → improve → re-eval.

**Q5: Design a customer support agent with safety guarantees.**
Streaming UI + citations + human handoff; gateway auth/rate limiting; input guardrails (PII, moderation, injection); hybrid retrieval + order-lookup tools; per-user memory; cascading LLM; output faithfulness check with escalation on low confidence; full observability. RAG (not fine-tuning) for changing articles; PII handling for compliance.

**Q6: What trade-offs do you consider?**
Cost vs quality vs latency; RAG vs fine-tuning; more retrieval (recall) vs noise/cost; sync vs async; build vs buy; privacy constraints; complexity vs capability. Weigh explicitly against clarified requirements.

---

## Rapid-Fire Round (Quick Answers)

- **What's a token?** ~4 chars; the unit LLMs read.
- **Temperature 0 for?** Deterministic tasks: code, extraction, classification.
- **RAG fixes what?** Hallucinations + stale/private knowledge.
- **Cosine similarity range?** -1 to 1.
- **ReAct =?** Reason + Act loop.
- **LangChain vs LangGraph?** Linear vs stateful/cyclic.
- **Few-shot =?** Examples in the prompt.
- **Stateless LLM means?** No memory between calls; app resends history.
- **LLM-as-judge =?** An LLM grading outputs.
- **Streaming improves?** Perceived latency.
- **LoRA =?** Cheap fine-tuning via small adapters.
- **Never put in browser?** API keys.
- **Fine-tune for facts?** No — use RAG.
- **First step in system design?** Clarify requirements.

---

[← All AI Concepts](./all-ai-concepts.md) | [Quick Recap →](./quick-recap.md)
