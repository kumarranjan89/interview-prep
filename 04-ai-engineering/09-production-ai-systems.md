# Chapter 09 — Production AI Systems

Cost, latency, reliability, and guardrails — what it takes to ship AI safely at scale.  
**Time to complete:** 4–5 hours | **Exercises:** 6

---

## Navigation
← [Chapter 08: Evals & Observability](./08-evals-and-observability.md) | → [Chapter 10: Fine-Tuning](./10-fine-tuning.md)

---

## From Prototype to Production

A demo that works on your laptop is not a production system. Production AI must handle real traffic, real costs, real failures, and real adversarial users.

```
Prototype:                    Production:
- Works for you               - Works for thousands of users
- Cost doesn't matter         - Every token costs money
- Latency is fine             - Users abandon slow apps
- No bad actors               - Prompt injection, abuse
- Crashes are okay            - Must be reliable 24/7
```

**The three pillars of production AI:**
> **Cost** (can you afford it?) · **Latency** (is it fast enough?) · **Reliability** (does it work safely, every time?)

---

## Pillar 1: Cost Optimization

LLM costs scale with tokens and traffic. Uncontrolled, they explode. (Recall token economics from Chapter 01.)

### Strategy 1: Use the Right Model
```
Don't use gpt-4o for everything.
- Simple classification → gpt-4o-mini (10-30x cheaper)
- Complex reasoning     → gpt-4o
- Route by difficulty   → "model cascading"
```

### Strategy 2: Caching
Cache responses for repeated/similar queries.
- **Exact cache** — same input → return stored output
- **Semantic cache** — similar input (by embedding) → return stored output
- **Prompt caching** — providers cache repeated prompt prefixes (e.g., long system prompts) at reduced cost

### Strategy 3: Reduce Tokens
- Trim system prompts (Chapter 06)
- Manage conversation history (Chapter 07)
- Retrieve fewer/smaller chunks in RAG (Chapter 03)
- Limit `max_tokens` on output

### Strategy 4: Batching
Process multiple items in one call, or use provider batch APIs (often 50% cheaper for non-urgent jobs).

### Strategy 5: Model Cascading / Routing
Try a cheap model first; escalate to an expensive one only when needed.
```
Cheap model → confident? → return
            → uncertain? → escalate to strong model
```

---

## Pillar 2: Latency Optimization

Users abandon slow apps. LLMs are inherently slow (token-by-token generation), so latency management is critical.

### Strategy 1: Streaming
Stream tokens as they're generated instead of waiting for the full response. Dramatically improves *perceived* latency.
```
Without streaming: [5 second wait] → full answer
With streaming:    answer appears word-by-word immediately
```

### Strategy 2: Smaller/Faster Models
Smaller models generate faster. Use them where quality permits.

### Strategy 3: Parallel Calls
Run independent LLM calls concurrently instead of sequentially.

### Strategy 4: Caching
A cache hit is instant — the fastest possible response.

### Strategy 5: Reduce Output Length
Shorter outputs generate faster. Set `max_tokens` and instruct concise responses.

### Strategy 6: Prefetching / Speculative Execution
Start likely-needed calls before the user finishes (advanced).

---

## Pillar 3: Reliability & Guardrails

Production systems must handle failures, abuse, and bad output gracefully.

### Input Guardrails (Before the LLM)
- **Validation** — check input format, length, type
- **PII detection** — redact sensitive data before sending (Chapter 01 mistake #5)
- **Prompt injection defense** — delimiters, instruction filtering (Chapter 06)
- **Rate limiting** — prevent abuse and runaway cost
- **Content moderation** — block harmful input (e.g., OpenAI Moderation API)

### Output Guardrails (After the LLM)
- **Format validation** — ensure structured output matches schema (Chapter 06)
- **Faithfulness check** — verify grounding (LLM-as-judge, Chapter 08)
- **Content moderation** — block harmful/unsafe output
- **PII filtering** — don't leak sensitive data
- **Fallbacks** — default response if output fails validation

### Reliability Patterns
- **Retries with backoff** — handle transient API errors
- **Timeouts** — don't hang forever
- **Circuit breakers** — stop calling a failing service
- **Fallback models** — switch providers if one is down
- **Graceful degradation** — return a useful default instead of crashing

---

## Code Examples

### Streaming — TypeScript
```typescript
import OpenAI from "openai";
const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function streamResponse(prompt: string) {
  const stream = await client.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [{ role: "user", content: prompt }],
    stream: true,  // enable streaming
  });

  for await (const chunk of stream) {
    const content = chunk.choices[0]?.delta?.content ?? "";
    process.stdout.write(content);  // print tokens as they arrive
  }
}

streamResponse("Explain streaming in one paragraph.");
```

### Retries with Exponential Backoff — Python
```python
import time
from openai import OpenAI, APIError, RateLimitError

client = OpenAI(api_key="YOUR_API_KEY")

def call_with_retry(prompt: str, max_retries: int = 3) -> str:
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                timeout=30,  # don't hang forever
            )
            return response.choices[0].message.content
        except (RateLimitError, APIError) as e:
            if attempt == max_retries - 1:
                raise
            wait = 2 ** attempt  # 1s, 2s, 4s
            print(f"Retry {attempt+1} after {wait}s ({e})")
            time.sleep(wait)
    return ""
```

### Semantic Caching — Python
```python
import numpy as np
from openai import OpenAI

client = OpenAI(api_key="YOUR_API_KEY")
cache = []  # list of (embedding, response)

def embed(text: str):
    return client.embeddings.create(
        model="text-embedding-3-small", input=text
    ).data[0].embedding

def cosine(a, b):
    a, b = np.array(a), np.array(b)
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

def cached_query(prompt: str, threshold: float = 0.95) -> str:
    q_emb = embed(prompt)

    # Check cache for a semantically similar query
    for cached_emb, cached_response in cache:
        if cosine(q_emb, cached_emb) >= threshold:
            print("[CACHE HIT]")
            return cached_response

    # Cache miss → call LLM
    print("[CACHE MISS]")
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
    ).choices[0].message.content

    cache.append((q_emb, response))
    return response
```

### Input/Output Guardrails — Python
```python
import re

def input_guardrail(user_input: str) -> tuple[bool, str]:
    # Length check
    if len(user_input) > 5000:
        return False, "Input too long."

    # Simple PII redaction (emails)
    redacted = re.sub(r'\S+@\S+', '[EMAIL]', user_input)

    # Moderation
    mod = client.moderations.create(input=redacted)
    if mod.results[0].flagged:
        return False, "Input flagged by moderation."

    return True, redacted

def output_guardrail(output: str) -> str:
    # Moderate output
    mod = client.moderations.create(input=output)
    if mod.results[0].flagged:
        return "I'm sorry, I can't help with that."
    return output

def safe_chat(user_input: str) -> str:
    ok, processed = input_guardrail(user_input)
    if not ok:
        return processed  # error message

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": processed}],
    ).choices[0].message.content

    return output_guardrail(response)
```

### Model Cascading — Python
```python
from pydantic import BaseModel

class Answer(BaseModel):
    answer: str
    confident: bool

def cascade_query(question: str) -> str:
    # Try cheap model first
    cheap = client.beta.chat.completions.parse(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content":
                "Answer the question. Set confident=false if unsure."},
            {"role": "user", "content": question},
        ],
        response_format=Answer,
    ).choices[0].message.parsed

    if cheap.confident:
        return cheap.answer  # cheap path

    # Escalate to strong model
    print("[ESCALATING to gpt-4o]")
    return client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": question}],
    ).choices[0].message.content
```

---

## Rate Limiting & Quotas

Protect your system and budget from abuse and runaway usage.

- **Per-user limits** — N requests per minute/day per user
- **Global limits** — total spend cap per day
- **Token quotas** — cap tokens per user/session
- **Provider rate limits** — respect API RPM/TPM limits (handle 429s with backoff)

```
User exceeds limit → return 429 / friendly message
                  → don't call the LLM
```

---

## Security Best Practices

(Building on Chapters 01 and 06.)

- **Never hardcode API keys** — use environment variables / secret managers
- **Don't send PII** to external APIs without anonymization (or use Azure OpenAI / self-hosted)
- **Defend against prompt injection** — delimiters, input validation, output checks
- **Least privilege for agent tools** — limit what tools can do (Chapter 04)
- **Human-in-the-loop** for irreversible actions
- **Audit logging** — log who did what for compliance
- **Check data policies** — know where your data goes and how it's stored

---

## Deployment Architecture

A typical production LLM app:

```
        Users
          ↓
   ┌─────────────┐
   │ API Gateway │  rate limiting, auth
   └──────┬──────┘
          ↓
   ┌─────────────┐
   │ App Server  │  input guardrails, orchestration
   └──────┬──────┘
     ↓         ↓
┌────────┐ ┌──────────┐
│ Cache  │ │ Vector DB│  (RAG, memory)
└────────┘ └──────────┘
     ↓
┌─────────────┐
│ LLM Provider│  (with retries, fallback)
└──────┬──────┘
       ↓
   Output guardrails → Response
       ↓
   Observability (tracing, evals, cost) — Chapter 08
```

---

## Mental Models

### The Cost-Latency-Quality Triangle
You usually can't maximize all three. A bigger model is higher quality but slower and pricier. Pick the right balance per use case — and route different requests to different points on the triangle.

### Guardrails = Seatbelts and Airbags
You hope you never need them, but in production with real users, something *will* go wrong. Guardrails contain the damage when it does.

### Streaming = Restaurant Service
Without streaming, you wait for the entire meal before eating. With streaming, courses arrive as they're ready — the wait *feels* much shorter even if total time is similar.

### Caching = Memoization for LLMs
Repeated/similar questions don't need fresh (expensive, slow) generation. Remember past answers and serve them instantly — like memoizing an expensive function.

---

## Common Mistakes

### Mistake 1: Using the Biggest Model Everywhere
❌ gpt-4o for trivial classification → 10-30x overspend
✅ Route by task complexity; use mini models where they suffice

### Mistake 2: No Streaming
❌ Users stare at a spinner for 5+ seconds
✅ Stream tokens for instant perceived responsiveness

### Mistake 3: No Guardrails
❌ Trusting all input/output → injection, harmful content, bad data
✅ Validate and moderate both input and output

### Mistake 4: No Retries/Timeouts
❌ One transient API error crashes the request
✅ Retries with backoff + timeouts + fallbacks

### Mistake 5: No Cost Monitoring
❌ Surprise $10,000 bill at month-end
✅ Track cost per request; set budget alerts and caps

### Mistake 6: No Caching
❌ Paying to regenerate the same answers repeatedly
✅ Add exact and/or semantic caching

### Mistake 7: Ignoring Rate Limits
❌ Hitting provider 429s in production; or one user drains your budget
✅ Implement per-user and global rate limiting

---

## Interview Questions

### Q1: How do you optimize the cost of an LLM application in production?
**Answer:** Several strategies: (1) Right-size the model — use cheaper models like gpt-4o-mini for simple tasks and reserve expensive models for complex reasoning. (2) Caching — exact and semantic caching avoid regenerating answers to repeated/similar queries; prompt caching reduces cost for repeated prefixes. (3) Reduce tokens — trim system prompts, manage conversation history, retrieve fewer RAG chunks, cap max_tokens. (4) Model cascading — try a cheap model first and escalate only when it's uncertain. (5) Batching — use batch APIs for non-urgent work. (6) Monitor cost per request with alerts and budget caps. The overarching principle is to match model capability to task difficulty.

### Q2: How do you reduce latency in an LLM application?
**Answer:** The biggest win is streaming — sending tokens as they're generated dramatically improves perceived latency even if total time is unchanged. Beyond that: use smaller/faster models where quality permits; run independent calls in parallel rather than sequentially; cache responses so hits are instant; reduce output length (shorter responses generate faster) via max_tokens and concise prompting; and use prompt caching for long static prefixes. For complex pipelines, minimize the number of sequential LLM calls on the critical path.

### Q3: What are guardrails and what types exist?
**Answer:** Guardrails are safety checks that protect an LLM system from bad input and bad output. Input guardrails (before the LLM) include input validation, PII detection/redaction, prompt-injection defenses, content moderation, and rate limiting. Output guardrails (after the LLM) include schema/format validation, faithfulness checks (e.g., LLM-as-judge to verify grounding), content moderation, PII filtering, and fallback responses when output fails validation. Together they prevent harmful, malformed, or ungrounded responses and defend against abuse — essential because production systems face real, sometimes adversarial, users.

### Q4: How do you handle failures and ensure reliability?
**Answer:** Use standard resilience patterns adapted to LLMs: retries with exponential backoff for transient errors and rate limits (429s); timeouts so requests don't hang; circuit breakers to stop hammering a failing provider; fallback models or providers when the primary is down; and graceful degradation — returning a useful default or cached response instead of crashing. Combine with monitoring and alerting so you detect issues quickly. The goal is that a single transient failure never breaks the user experience.

### Q5: What is model cascading and when would you use it?
**Answer:** Model cascading (or routing) is a cost-optimization pattern where you try a cheaper, faster model first and only escalate to a more expensive, capable model when needed — for example, when the cheap model signals low confidence or the task is detected as complex. You'd use it when your traffic has a mix of easy and hard requests: most queries are handled cheaply, and only the hard minority incur the higher cost. It captures most of the cost savings of a small model while preserving the quality of a large model on difficult cases. The trade-off is added complexity and the latency of a possible second call.

### Q6: How do you secure an LLM application?
**Answer:** Key practices: never hardcode API keys — use environment variables or a secret manager; avoid sending PII to external APIs without anonymization, or use a private deployment like Azure OpenAI or self-hosted models; defend against prompt injection with delimiters, input validation, and output checks; apply least privilege to agent tools and require human-in-the-loop for irreversible actions; add content moderation on input and output; implement rate limiting; maintain audit logs for compliance; and understand your data policy — where data goes and how it's retained. Security is defense-in-depth across input, processing, and output.

---

## Practice Exercises

Setup:
```bash
# Python
pip install openai numpy python-dotenv

# Node.js
npm install openai
```

### Exercise 1: Streaming
Build a streaming chatbot in the terminal. Compare the perceived speed to a non-streaming version.

### Exercise 2: Retry Logic
Implement retries with exponential backoff. Simulate failures (e.g., raise an error randomly) and verify it recovers.

### Exercise 3: Semantic Cache
Build a semantic cache. Ask 5 differently-phrased versions of the same question and verify cache hits after the first.

### Exercise 4: Guardrails
Add input and output guardrails (length check, moderation, PII redaction) to a chatbot. Test with problematic inputs.

### Exercise 5: Model Cascading
Build a cascade that uses gpt-4o-mini first and escalates to gpt-4o when unsure. Measure cost savings across mixed-difficulty questions.

### Exercise 6: Cost Dashboard
Add per-request cost tracking. Log tokens and cost for every call. Build a simple summary of total spend and average cost per request.

---

## Summary Table

| Concept | Simple Meaning | Key Detail |
|---------|---------------|------------|
| Cost optimization | Spend less per request | Right model, caching, fewer tokens |
| Caching | Reuse past responses | Exact + semantic + prompt caching |
| Streaming | Tokens as generated | Improves perceived latency |
| Model cascading | Cheap first, escalate | Cost savings on easy queries |
| Guardrails | Input/output safety checks | Validation, moderation, PII |
| Reliability | Handle failures gracefully | Retries, timeouts, fallbacks |
| Rate limiting | Cap usage | Prevent abuse & runaway cost |

---

## Key Takeaways

- **Production AI rests on three pillars** — cost, latency, and reliability
- **Match model to task** — don't use gpt-4o for everything; cascade when useful
- **Cache aggressively** — exact, semantic, and prompt caching cut cost and latency
- **Stream responses** — the cheapest, biggest perceived-latency win
- **Guardrails are mandatory** — validate and moderate both input and output
- **Build for failure** — retries, timeouts, fallbacks, graceful degradation
- **Monitor cost and rate-limit** — avoid surprise bills and abuse
- **Security is defense-in-depth** — keys, PII, injection, least privilege, logging

---

## What's Next?

After completing this chapter:

**Move to Chapter 10 → Fine-Tuning: When & How**
- When fine-tuning is worth it (and when RAG/prompting is better)
- How fine-tuning works and how to prepare data
- The rare cases where you actually train a model

**Don't move on until:**
- You've implemented streaming, retries, and caching
- You've added input/output guardrails
- You can explain the cost-latency-quality triangle
- You understand model cascading and rate limiting
- You've completed at least 4 of the 6 exercises

---

**Time spent:** ___ hours | **Date completed:** ___
