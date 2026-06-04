# Chapter 12 — AI System Design (Staff-Level Interviews)

How to design end-to-end AI systems at scale — the capstone that ties everything together.  
**Time to complete:** 5–6 hours | **Exercises:** 6

---

## Navigation
← [Chapter 11: AI + Frontend](./11-frontend-ai.md) | → [README (Index)](./README.md)

---

## What Is AI System Design?

AI system design interviews ask you to architect a complete AI-powered product — not just call an API, but design the whole system: data flow, retrieval, models, evaluation, cost, latency, reliability, and scale.

```
Junior question:  "Call an LLM to summarize text."
Staff question:   "Design a system that answers questions over
                   10 million company documents for 100K users,
                   with citations, under 2s latency, and a budget."
```

**What interviewers evaluate:**
> Can you combine all the pieces (RAG, agents, memory, evals, guardrails, cost/latency) into a coherent, scalable, production-ready architecture — while reasoning about trade-offs?

---

## A Framework for AI System Design Interviews

Use this structured approach (like classic system design, adapted for AI):

```
1. CLARIFY      → requirements, scale, constraints
2. DEFINE       → success metrics & evaluation
3. HIGH-LEVEL   → core architecture & data flow
4. DEEP DIVE    → retrieval, models, prompts, memory
5. SCALE        → cost, latency, reliability at scale
6. EVALUATE     → how you measure & improve quality
7. TRADE-OFFS   → discuss alternatives & decisions
```

Spend real time on **step 1** — clarifying before designing signals seniority.

---

## Step 1: Clarify Requirements

Always ask before designing. Key questions:

**Functional:**
- What exactly should the system do? (Q&A, summarization, agent actions?)
- What are the inputs and outputs?
- Who are the users? How many?

**Scale:**
- How much data? (1K docs vs 10M docs changes everything)
- How many requests per second/day?
- How often does the data change?

**Constraints:**
- Latency target? (real-time chat vs batch)
- Budget? (cost per query matters)
- Accuracy requirements? (casual vs medical/legal)
- Privacy/compliance? (can data leave your servers?)

**Quality:**
- How do we define and measure "good"?
- What's the tolerance for hallucination/errors?

---

## Step 2: Define Success Metrics

State how you'll measure success (ties to Chapter 08):

- **Quality:** accuracy, faithfulness, relevance (evals, LLM-as-judge)
- **Latency:** p50, p95, p99 response times
- **Cost:** $ per query, total monthly budget
- **Reliability:** uptime, error rate
- **User satisfaction:** thumbs up/down, retention

---

## Step 3: High-Level Architecture

A reference architecture for a typical RAG-based AI product:

```
                        Users
                          │
                  ┌───────▼────────┐
                  │  Frontend (Ch11)│  streaming UI, citations
                  └───────┬────────┘
                          │
                  ┌───────▼────────┐
                  │  API Gateway   │  auth, rate limiting (Ch9)
                  └───────┬────────┘
                          │
                  ┌───────▼────────┐
                  │  Orchestrator  │  guardrails, routing (Ch9)
                  └───┬────────┬───┘
            ┌─────────┘        └──────────┐
     ┌──────▼──────┐               ┌──────▼──────┐
     │  Retrieval  │               │   Memory    │
     │  (Vector DB)│ (Ch3)         │ (Ch7)       │
     └──────┬──────┘               └─────────────┘
            │
     ┌──────▼──────┐
     │  LLM Layer  │  model routing, cascading (Ch9,10)
     └──────┬──────┘
            │
     ┌──────▼──────┐
     │ Guardrails  │  output validation, moderation
     └──────┬──────┘
            │
     ┌──────▼──────┐
     │Observability│  tracing, evals, cost (Ch8)
     └─────────────┘
```

Walk through the **data flow**: request → auth → guardrails → retrieve context + memory → build prompt → LLM → validate output → stream to user → log/eval.

---

## Step 4: Deep Dives

The interviewer will probe specific components. Be ready to go deep on each.

### Deep Dive: Retrieval (RAG)
- **Indexing:** chunking strategy, embedding model, vector DB choice (Ch 2, 3)
- **Retrieval:** top-k, hybrid search, re-ranking (Ch 3)
- **Freshness:** how often to re-index when data changes
- **Scale:** sharding, partitioning for millions of docs

### Deep Dive: Model Selection
- Which model for which task? (cost/quality, Ch 9)
- Model cascading/routing for cost (Ch 9)
- Fine-tuning vs RAG vs prompting (Ch 10)
- Fallback models for reliability

### Deep Dive: Prompting
- System prompt design, structured output (Ch 6)
- Prompt versioning and testing
- Injection defenses (Ch 6)

### Deep Dive: Memory
- Short-term (conversation) and long-term (user) memory (Ch 7)
- Per-user isolation, summarization strategy

### Deep Dive: Evaluation
- Offline eval set, online sampling, LLM-as-judge (Ch 8)
- A/B testing prompts/models
- Feedback loops

---

## Step 5: Scaling Concerns

### Cost at Scale
```
100K users × 10 queries/day × $0.01/query = $10K/day = $300K/month
→ Optimize: caching, cheaper models, cascading, token reduction (Ch 9)
```

### Latency at Scale
- Streaming (Ch 11) for perceived speed
- Caching for instant hits
- Parallel retrieval + generation
- Edge deployment, regional vector DBs

### Reliability at Scale
- Retries, timeouts, circuit breakers, fallback models (Ch 9)
- Graceful degradation (return cached/partial answer)
- Queue + batch for non-urgent work

### Throughput
- Horizontal scaling of app servers
- Provider rate limits (TPM/RPM) → request distribution, multiple keys/providers
- Async processing for heavy jobs

---

## Step 6 & 7: Evaluation Loop and Trade-Offs

### The Continuous Improvement Loop
```
Deploy → Trace & Log → Collect feedback → Build eval cases →
Improve (prompt/model/retrieval) → Re-eval → Deploy
```

### Always Discuss Trade-Offs
Staff-level answers weigh alternatives:
- **Bigger model vs cheaper + cascading** (quality vs cost)
- **RAG vs fine-tuning** (fresh knowledge vs baked behavior)
- **More retrieval vs less** (recall vs noise/cost)
- **Sync vs async** (latency vs throughput)
- **Build vs buy** (control vs speed)

> There is no single right answer — the interviewer wants your *reasoning*.

---

## Worked Example: "Design a Customer Support AI"

**Requirements (clarified):**
- Answer customer questions over 50K help articles + order data
- 50K users, ~5 queries each daily, < 3s latency
- Must cite sources; escalate to humans when unsure
- Can't expose customer PII to external APIs

**Architecture:**
```
1. Frontend: streaming chat with citations + "talk to human" button (Ch11)
2. Gateway: auth, rate limiting per user (Ch9)
3. Guardrails: PII redaction before LLM, moderation (Ch9)
4. Retrieval: hybrid search over help articles (Ch3),
              + structured lookup for order data (tool, Ch4)
5. Memory: per-user conversation + past tickets (Ch7)
6. LLM: gpt-4o-mini default, cascade to gpt-4o for complex (Ch9,10)
7. Output guardrails: faithfulness check; if low confidence → escalate
8. Observability: trace, eval faithfulness, track cost/CSAT (Ch8)
```

**Key trade-offs discussed:**
- RAG (not fine-tuning) for articles — they change frequently
- Cascading to control cost across 250K daily queries
- PII redaction or Azure OpenAI for compliance
- Human escalation as a safety net for low-confidence answers

---

## Common AI System Design Prompts

Practice designing these:
- **Document Q&A** over millions of docs (RAG at scale)
- **Customer support agent** with tools + escalation
- **Code assistant** (retrieval over a codebase + generation)
- **Personalized recommendation** explanations
- **Content moderation** pipeline
- **Multi-agent research assistant**
- **Semantic search** engine
- **AI email/meeting summarizer** at scale

---

## Mental Models

### AI System Design = Assembling the Toolkit
Chapters 1-11 gave you the tools (tokens, embeddings, RAG, agents, memory, evals, production, fine-tuning, frontend). System design is choosing and combining the right tools for the problem.

### Clarify First = Measure Twice, Cut Once
Jumping into architecture without clarifying requirements is the #1 mistake. Great designers spend the first few minutes understanding the real problem.

### Trade-Offs Over "Right Answers"
There's rarely one correct design. Seniority shows in how you reason about cost vs quality vs latency vs complexity — and justify your choices.

### Everything Is a Pipeline
An AI system is a data pipeline: input → guardrails → retrieve → augment → generate → validate → output → observe. Master the flow and you can design any AI product.

---

## Common Mistakes

### Mistake 1: Designing Before Clarifying
❌ Jumping to architecture without understanding scale/constraints
✅ Ask clarifying questions first — it signals seniority

### Mistake 2: Ignoring Evaluation
❌ No plan to measure quality or catch regressions
✅ Always include offline + online evals (Ch 8)

### Mistake 3: Fine-Tuning for Knowledge
❌ Proposing fine-tuning to add changing facts
✅ Use RAG for knowledge; fine-tuning for behavior (Ch 10)

### Mistake 4: Forgetting Cost
❌ A design that's technically great but costs $1M/month
✅ Estimate cost at scale; optimize with caching/cascading

### Mistake 5: No Guardrails or Safety
❌ Ignoring injection, PII, hallucination, escalation
✅ Include input/output guardrails and human-in-the-loop (Ch 9)

### Mistake 6: Not Discussing Trade-Offs
❌ Presenting one design as "the answer"
✅ Compare alternatives and justify decisions

### Mistake 7: Ignoring the User Experience
❌ Backend-only thinking, no streaming/latency story
✅ Address frontend UX and perceived latency (Ch 11)

---

## Interview Questions

### Q1: How would you design a Q&A system over 10 million documents?
**Answer:** Start by clarifying scale, latency, freshness, and accuracy needs. The core is RAG at scale: an offline indexing pipeline (load → chunk → embed → store) using a scalable vector DB with sharding/partitioning for 10M docs. At query time: embed the query, use hybrid search (semantic + keyword) to retrieve candidates, re-rank to the top few, build a grounded prompt, and generate with citations. For scale, add caching (exact + semantic), model cascading for cost, and streaming for perceived latency. Include an evaluation loop (faithfulness, retrieval precision/recall) and observability. Discuss trade-offs: chunk size, top-k vs noise, re-indexing frequency for freshness, and cost per query at volume.

### Q2: How do you decide between RAG, fine-tuning, and prompting in a design?
**Answer:** Match the approach to the need. Prompting (and few-shot) is the default for behavior achievable through instructions — cheapest and most flexible. RAG is for knowledge, especially changing or large knowledge bases, because you update documents without retraining and get citations. Fine-tuning is for consistent style/format, narrow high-volume tasks, or cost/latency reduction by baking behavior into a smaller model — and it's a last resort after the others. In a system design, I'd typically use RAG for the knowledge layer and prompting for behavior, and only add fine-tuning if evals show prompting can't meet style/consistency or cost targets. They combine well: fine-tune for "how to respond," RAG for "what to respond with."

### Q3: How would you control cost in a system serving millions of queries?
**Answer:** Several layers: (1) Caching — exact and semantic caching to avoid regenerating repeated/similar answers, plus prompt caching for static prefixes. (2) Model routing/cascading — use a cheap model (gpt-4o-mini) by default and escalate to a strong model only for hard queries. (3) Token reduction — trim system prompts, manage conversation history, retrieve fewer/smaller chunks, cap max_tokens. (4) Batching — for non-urgent jobs via batch APIs. (5) Right-sizing per task and fine-tuning a small model for high-volume narrow tasks. (6) Monitoring — track cost per query with budgets and alerts. I'd estimate cost at scale upfront (queries × cost/query) and design optimizations to hit the budget.

### Q4: How do you ensure quality and catch regressions in a production AI system?
**Answer:** Build an evaluation loop. Offline: maintain a versioned eval dataset covering happy paths, edge cases, and past bugs, and run it (with reference-based metrics and LLM-as-judge) on every prompt/model change to catch regressions. Online: sample live traffic for automated evaluation, collect explicit user feedback (thumbs up/down) and implicit signals (rephrasing, abandonment), and A/B test changes. Add tracing/observability to debug issues to root cause (was it retrieval, prompt, or model?). Every production bug becomes a new eval case. This continuous loop — deploy, trace, collect feedback, build cases, improve, re-eval — keeps quality from silently degrading.

### Q5: How would you design a customer support agent with safety guarantees?
**Answer:** Clarify requirements (data sources, PII, escalation policy). Architecture: streaming frontend with citations and a human-handoff button; gateway with auth and rate limiting; input guardrails (PII redaction, moderation, injection defense); a retrieval layer (hybrid search over help articles) plus tools for structured order lookups; per-user memory; an LLM layer with cascading; output guardrails that run a faithfulness check and escalate to a human when confidence is low or the topic is sensitive; and full observability (tracing, faithfulness evals, CSAT, cost). Safety guarantees come from grounding answers in retrieved context, PII handling for compliance (redaction or Azure/self-hosted), human-in-the-loop escalation as a fallback, and continuous evaluation. I'd use RAG (not fine-tuning) since articles change frequently.

### Q6: What trade-offs do you consider in AI system design?
**Answer:** The central tensions are cost vs quality vs latency. A bigger model improves quality but costs more and is slower — often resolved with cascading. RAG vs fine-tuning trades fresh, updatable knowledge against baked-in behavior. More retrieval improves recall but adds noise and cost. Synchronous serving minimizes latency while async/batch maximizes throughput and lowers cost. Build vs buy trades control against speed of delivery. Privacy constraints may force self-hosted/Azure over the cheapest API. Complexity itself is a trade-off — more components mean more capability but more failure modes. Staff-level answers explicitly weigh these and justify choices against the clarified requirements rather than presenting one "correct" design.

---

## Practice Exercises

These are design exercises — write out architectures, data flows, and trade-offs (no code required).

### Exercise 1: Document Q&A at Scale
Design a Q&A system over 5M PDFs for 100K users, < 2s latency. Specify chunking, vector DB, retrieval, caching, and cost estimate.

### Exercise 2: Support Agent
Design a customer support agent with tool use, memory, citations, and human escalation. Address PII and safety.

### Exercise 3: Code Assistant
Design an AI code assistant that retrieves over a large codebase and generates suggestions. Address indexing code and freshness.

### Exercise 4: Cost Optimization Challenge
Take a design costing $500K/month. Apply caching, cascading, and token reduction. Estimate the new cost and quality trade-offs.

### Exercise 5: Evaluation Strategy
Design the full eval strategy for one of the above systems: offline dataset, online sampling, metrics, and feedback loop.

### Exercise 6: Full Mock Interview
Pick a prompt (e.g., "design a meeting summarizer for 1M users"). Do a full 45-minute design using the 7-step framework. Record your trade-off reasoning.

---

## Summary Table

| Step | Focus | Chapters |
|------|-------|----------|
| Clarify | Requirements, scale, constraints | — |
| Metrics | Define & measure success | Ch 8 |
| High-level | Architecture & data flow | All |
| Deep dive | Retrieval, models, prompts, memory | Ch 2,3,6,7,10 |
| Scale | Cost, latency, reliability | Ch 9 |
| Evaluate | Quality loop, A/B testing | Ch 8 |
| Trade-offs | Justify decisions | All |

---

## Key Takeaways

- **Clarify before designing** — understand scale, constraints, and success first
- **Combine the toolkit** — RAG, agents, memory, evals, guardrails, frontend
- **Think in pipelines** — input → guardrails → retrieve → generate → validate → observe
- **Always include evaluation** — offline + online, with a continuous improvement loop
- **Estimate and optimize cost** — caching, cascading, token reduction at scale
- **Design for reliability and safety** — retries, fallbacks, guardrails, human escalation
- **RAG for knowledge, fine-tuning for behavior** — and combine when needed
- **Discuss trade-offs** — there's no single right answer; reasoning is what counts

---

## What's Next?

**Congratulations — you've completed the syllabus!** 🎉

You now understand the full AI engineering stack:
1. **Fundamentals** (Ch 1) → how LLMs work
2. **Embeddings & RAG** (Ch 2-3) → meaning and retrieval
3. **Agents & frameworks** (Ch 4-5) → action and orchestration
4. **Prompting & memory** (Ch 6-7) → reliability and state
5. **Evals & production** (Ch 8-9) → measurement and scale
6. **Fine-tuning & frontend** (Ch 10-11) → specialization and UX
7. **System design** (Ch 12) → putting it all together

**Final preparation tips:**
- Build at least one end-to-end project combining 3+ chapters
- Practice explaining each concept in plain English
- Do mock system design interviews using the 7-step framework
- Review the interview questions across all chapters
- Stay current — the field moves fast; follow model/tool releases

**You're ready. Go build, and good luck with your interviews!**

---

**Time spent:** ___ hours | **Date completed:** ___
