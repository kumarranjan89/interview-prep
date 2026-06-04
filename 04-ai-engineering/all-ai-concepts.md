# All AI Concepts — Master Glossary

Every key concept across all 12 chapters, in one place. Use this as a quick reference and revision sheet.

---

## Navigation
[README (Index)](./README.md) | [Interview Questions](./interview-questions.md) | [Quick Recap](./quick-recap.md)

---

## Chapter 01 — LLM Fundamentals

| Concept | Definition |
|---------|-----------|
| **LLM** | A neural network trained to predict the next token; not a fact database. |
| **Token** | A chunk of text the LLM reads (~4 chars ≈ 0.75 words). |
| **Context window** | The LLM's working memory — all text it can "see" at once. |
| **Temperature** | Randomness dial: 0 = deterministic, 1+ = creative. |
| **Transformer** | The architecture behind LLMs; uses self-attention. |
| **Attention** | Mechanism letting each token weigh all other tokens. |
| **Parameters** | The learned weights of the model (GPT-4 ≈ 1T). |
| **Pretraining** | Learning language by predicting next token on massive data. |
| **Fine-tuning (RLHF)** | Aligning a base model into a helpful assistant. |
| **Hallucination** | A confident but false output; predicting likely, not true. |
| **System/user/assistant roles** | System = instructions; user = human; assistant = LLM. |

---

## Chapter 02 — Embeddings & Vectors

| Concept | Definition |
|---------|-----------|
| **Embedding** | A vector of numbers representing meaning of text. |
| **Vector** | A list of floats (e.g., 1536 dims for OpenAI small). |
| **Cosine similarity** | Measures semantic similarity (-1 to 1) via angle. |
| **Dimensionality** | Number of values in an embedding; more = more nuance. |
| **Vector database** | Specialized DB for storing + similarity-searching vectors. |
| **ANN** | Approximate Nearest Neighbor — fast similarity search. |
| **HNSW / IVF** | Indexing algorithms used by vector DBs. |
| **Chunking** | Splitting documents into smaller pieces before embedding. |

---

## Chapter 03 — RAG

| Concept | Definition |
|---------|-----------|
| **RAG** | Retrieval-Augmented Generation: retrieve docs, then generate. |
| **Indexing phase** | Offline: load → chunk → embed → store. |
| **Retrieval phase** | Online: embed query → search → augment → generate. |
| **top_k** | Number of chunks retrieved (start 3-5). |
| **Overlap** | Shared text between chunks to preserve context. |
| **Hybrid search** | Combines semantic (vector) + keyword (BM25) search. |
| **Re-ranking** | Two-stage: fast retrieve, then accurate cross-encoder sort. |
| **HyDE** | Generate hypothetical answer, embed it, search with it. |
| **Faithfulness** | Whether the answer is grounded in retrieved context. |

---

## Chapter 04 — Agents & Tools

| Concept | Definition |
|---------|-----------|
| **Agent** | LLM that takes actions in a loop (think → act → observe). |
| **Tool / function** | A callable the LLM can invoke (search, calc, API). |
| **Function calling** | LLM returns structured request to call a tool (doesn't run it). |
| **ReAct** | Reasoning + Acting: interleave Thought → Action → Observation. |
| **Agent loop** | Think → Act → Observe → Repeat → Answer. |
| **Iteration limit** | Cap on loop count to prevent runaway cost. |
| **Multi-agent** | Multiple specialized agents coordinated by an orchestrator. |
| **Human-in-the-loop** | Approval required for risky/irreversible actions. |

---

## Chapter 05 — Agentic Frameworks

| Concept | Definition |
|---------|-----------|
| **Framework** | Pre-built AI building blocks (saves time, adds abstraction). |
| **LangChain** | Composable component library (models, prompts, tools). |
| **LCEL** | LangChain Expression Language; pipe composition (`a \| b \| c`). |
| **Retriever** | LangChain component wrapping a vector store for RAG. |
| **LangGraph** | Stateful graph of nodes/edges for cyclic, branching agents. |
| **Node / Edge** | Step / transition (edges can be conditional). |
| **State** | Shared data passed between graph nodes. |
| **LlamaIndex / CrewAI / AutoGen / Vercel AI SDK** | Other frameworks for data RAG, multi-agent, frontend. |

---

## Chapter 06 — Prompt Engineering

| Concept | Definition |
|---------|-----------|
| **Prompt engineering** | Designing inputs for reliable, useful LLM output. |
| **Zero-shot** | Ask with no examples. |
| **Few-shot** | Provide examples to demonstrate the pattern. |
| **Chain-of-thought (CoT)** | Ask the model to reason step by step. |
| **Self-consistency** | Run CoT multiple times, take majority answer. |
| **Role/persona prompting** | Assign an expert role to shape output. |
| **Structured output** | Schema-enforced JSON (Pydantic/Zod) for parseable data. |
| **JSON mode** | Forces valid JSON output. |
| **Delimiters** | Separate data from instructions (prevents injection). |
| **Prompt injection** | Malicious input that hijacks LLM behavior. |

---

## Chapter 07 — Memory & State

| Concept | Definition |
|---------|-----------|
| **Stateless LLM** | No memory between API calls; app manages state. |
| **Short-term memory** | Conversation history in the context window. |
| **Long-term memory** | Persistent facts in external store, retrieved via RAG. |
| **Sliding window** | Keep only the last N messages. |
| **Summarization** | Compress old history into a running summary. |
| **Token budgeting** | Allocate context tokens deliberately. |
| **Lost in the middle** | LLMs miss info in the middle of long contexts. |
| **Memory extraction** | Saving only durable, important facts. |

---

## Chapter 08 — Evals & Observability

| Concept | Definition |
|---------|-----------|
| **Eval** | Systematic measurement of output quality (AI regression tests). |
| **Reference-based** | Compare output to a golden answer. |
| **Reference-free** | Judge intrinsic quality (faithfulness, relevance). |
| **LLM-as-judge** | Use a strong LLM to grade outputs against a rubric. |
| **Human eval** | Humans rate outputs (gold standard, slow). |
| **Tracing** | Visibility into each pipeline step (find root cause). |
| **Offline eval** | Test against a fixed dataset before shipping. |
| **Online eval** | Evaluate live traffic (sampling, feedback, A/B). |
| **Eval dataset** | Test cases that grow with every bug found. |

---

## Chapter 09 — Production AI Systems

| Concept | Definition |
|---------|-----------|
| **Cost-latency-quality triangle** | The central production trade-off. |
| **Caching** | Reuse responses (exact, semantic, prompt caching). |
| **Streaming** | Send tokens as generated; improves perceived latency. |
| **Model cascading** | Try cheap model first, escalate to strong if needed. |
| **Guardrails** | Input/output safety checks (validation, moderation, PII). |
| **Retries with backoff** | Handle transient errors gracefully. |
| **Circuit breaker** | Stop calling a failing service. |
| **Rate limiting** | Cap usage per user/global to prevent abuse. |
| **Graceful degradation** | Return useful default instead of crashing. |

---

## Chapter 10 — Fine-Tuning

| Concept | Definition |
|---------|-----------|
| **Fine-tuning** | Training a base model on your examples (behavior, not facts). |
| **When to use** | Style/format/narrow task; last resort after prompting/RAG. |
| **When NOT to** | Adding/changing knowledge → use RAG. |
| **Full fine-tuning** | Update all weights (expensive, rare). |
| **PEFT** | Parameter-efficient fine-tuning (update a subset). |
| **LoRA** | Low-Rank Adaptation; small trainable adapters. |
| **QLoRA** | LoRA + quantization; fine-tune big models on 1 GPU. |
| **JSONL** | Training data format (one conversation per line). |

---

## Chapter 11 — Frontend AI

| Concept | Definition |
|---------|-----------|
| **Streaming UI** | Render tokens as they arrive; #1 AI UX technique. |
| **SSE** | Server-Sent Events; the transport for streaming. |
| **Vercel AI SDK** | TypeScript toolkit (`useChat`, `streamText`, `useObject`). |
| **Generative UI** | LLM returns structured data; frontend renders components. |
| **Optimistic UI** | Show user action instantly before server responds. |
| **Loading/thinking states** | Meaningful feedback while waiting. |
| **API key security** | Never expose keys in browser; proxy via backend. |
| **Citations** | Show RAG sources in UI to build trust. |

---

## Chapter 12 — AI System Design

| Concept | Definition |
|---------|-----------|
| **AI system design** | Architecting a complete AI product end-to-end. |
| **7-step framework** | Clarify → Define → High-level → Deep dive → Scale → Evaluate → Trade-offs. |
| **Clarify first** | Ask requirements/scale/constraints before designing. |
| **Success metrics** | Quality, latency (p50/p95/p99), cost, reliability. |
| **Pipeline thinking** | Input → guardrails → retrieve → generate → validate → observe. |
| **Continuous improvement loop** | Deploy → trace → feedback → eval → improve. |
| **Trade-offs** | Cost vs quality vs latency vs complexity. |

---

## The Big Decision Tables

### RAG vs Fine-Tuning vs Prompting
| Need | Use |
|------|-----|
| Add/change facts & knowledge | **RAG** |
| Simple behavior via instructions | **Prompting** |
| Show a pattern | **Few-shot** |
| Consistent style/format | **Fine-tuning** |
| Narrow high-volume task | **Fine-tuning (small model)** |
| Knowledge + behavior | **RAG + Fine-tuning** |

### Temperature Settings
| Value | Use For |
|-------|---------|
| 0.0 | Code, data extraction, classification |
| 0.7 | Chat, summaries, Q&A |
| 1.0+ | Creative writing, brainstorming |

### Model Choice
| Task | Model |
|------|-------|
| Simple/classification | gpt-4o-mini (cheap, fast) |
| Complex reasoning | gpt-4o |
| Mixed traffic | Cascade mini → 4o |

---

## How Everything Connects

```
Ch1 Fundamentals (tokens, context, temperature)
        ↓
Ch2 Embeddings → Ch3 RAG (retrieval over your data)
        ↓
Ch4 Agents → Ch5 Frameworks (action & orchestration)
        ↓
Ch6 Prompting + Ch7 Memory (reliability & state)
        ↓
Ch8 Evals + Ch9 Production (measure & scale)
        ↓
Ch10 Fine-tuning + Ch11 Frontend (specialize & deliver)
        ↓
Ch12 System Design (combine everything)
```

---

[← README (Index)](./README.md) | [Interview Questions →](./interview-questions.md)
