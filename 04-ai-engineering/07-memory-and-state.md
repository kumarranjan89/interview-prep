# Chapter 07 — Memory in LLMs and Agents

How to give LLMs and agents persistent memory across turns, sessions, and tasks.  
**Time to complete:** 3–4 hours | **Exercises:** 6

---

## Navigation
← [Chapter 06: Prompt Engineering](./06-prompt-engineering.md) | → [Chapter 08: Evals & Observability](./08-evals-and-observability.md)

---

## The Memory Problem

Recall from Chapter 01: **LLMs have no memory between API calls.** Each call is stateless. The only thing the model "remembers" is what you put in the context window *right now*.

```
Call 1: "My name is Rahul"        → LLM: "Hi Rahul!"
Call 2: "What's my name?"         → LLM: "I don't know" ❌
        (unless you resend Call 1)
```

**Memory** is the engineering layer you build *around* the LLM to make it appear to remember — across turns, sessions, and even tasks.

> The LLM is stateless. Memory is something *you* manage and feed back into the context.

---

## Types of Memory

```
┌────────────────────────────────────────────────┐
│                    MEMORY                        │
│                                                  │
│  SHORT-TERM (Working Memory)                     │
│  └─ Conversation history in current session     │
│  └─ Lives in the context window                 │
│                                                  │
│  LONG-TERM (Persistent Memory)                   │
│  └─ Facts, preferences, past interactions       │
│  └─ Stored in a database / vector store         │
│  └─ Retrieved when relevant                     │
└──────────────────────────────────────────────────┘
```

### Short-Term Memory
The conversation history within a single session. You store messages and resend them with each call (as in Chapter 01). Limited by the context window.

### Long-Term Memory
Information that persists across sessions — user preferences, important facts, summaries of past conversations. Stored externally (database, vector store) and retrieved when relevant (often via RAG from Chapter 03).

---

## The Human Memory Analogy

| Human Memory | LLM Equivalent |
|--------------|----------------|
| Working memory (what you're thinking now) | Context window |
| Short-term memory (this conversation) | Message history |
| Long-term memory (lifetime of facts) | External store + retrieval |
| Recalling a relevant memory | Vector search / RAG |
| Forgetting unimportant details | Summarization / truncation |

---

## Short-Term Memory Strategies

As conversations grow, they eventually exceed the context window. You need a strategy to manage history.

### 1. Full History (Simplest)
Send the entire conversation every time.
```
✅ Simple, complete context
❌ Grows unbounded → hits context limit, expensive
```
Good for short conversations.

### 2. Sliding Window (Buffer)
Keep only the last N messages.
```
✅ Bounded size, cheap
❌ Forgets older context entirely
```

### 3. Summarization
When history gets long, summarize older messages into a compact summary, keep recent messages verbatim.
```
[Summary of messages 1-20] + [verbatim messages 21-25]
```
```
✅ Retains gist of long conversations, bounded size
❌ Loses detail, costs an extra LLM call to summarize
```

### 4. Token-Based Trimming
Trim history to fit within a token budget, dropping oldest messages first.

### 5. Hybrid (Summary + Recent + Retrieved)
The production pattern: a running summary + recent messages verbatim + relevant facts retrieved from long-term memory.

---

## Long-Term Memory Architecture

Long-term memory uses the RAG pattern from Chapter 03 applied to *memories*.

```
Store phase (after each interaction):
  Extract important facts → embed → store in vector DB
  e.g., "User prefers Python", "User's project is an e-commerce app"

Retrieve phase (before each response):
  Embed current message → search memory store →
  inject relevant memories into the prompt
```

**Example:**
```
Session 1: User says "I'm allergic to peanuts."
  → Store memory: { fact: "User is allergic to peanuts" }

Session 5 (days later): "Suggest a snack."
  → Retrieve memory: "User is allergic to peanuts"
  → LLM: "How about apple slices? (avoiding peanuts)"
```

---

## Code Examples

### Short-Term Memory — Sliding Window (TypeScript)
```typescript
import OpenAI from "openai";
const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

type Msg = { role: "system" | "user" | "assistant"; content: string };

const MAX_MESSAGES = 10;  // keep last 10 (plus system)
const system: Msg = { role: "system", content: "You are a helpful assistant." };
let history: Msg[] = [];

async function chat(userMessage: string): Promise<string> {
  history.push({ role: "user", content: userMessage });

  // Sliding window: keep only the last N messages
  if (history.length > MAX_MESSAGES) {
    history = history.slice(history.length - MAX_MESSAGES);
  }

  const response = await client.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [system, ...history],
  });

  const reply = response.choices[0].message.content ?? "";
  history.push({ role: "assistant", content: reply });
  return reply;
}
```

### Short-Term Memory — Summarization (Python)
```python
from openai import OpenAI
client = OpenAI(api_key="YOUR_API_KEY")

history = []          # recent messages
summary = ""          # running summary of older messages
MAX_RECENT = 6

def summarize(messages: list) -> str:
    text = "\n".join(f"{m['role']}: {m['content']}" for m in messages)
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{
            "role": "user",
            "content": f"Summarize this conversation concisely:\n{text}"
        }],
    )
    return response.choices[0].message.content

def chat(user_message: str) -> str:
    global history, summary
    history.append({"role": "user", "content": user_message})

    # When recent history grows, summarize the oldest part
    if len(history) > MAX_RECENT:
        old = history[:-MAX_RECENT]
        history = history[-MAX_RECENT:]
        new_summary = summarize(old)
        summary = f"{summary}\n{new_summary}".strip()

    system_content = "You are a helpful assistant."
    if summary:
        system_content += f"\n\nConversation summary so far:\n{summary}"

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "system", "content": system_content}, *history],
    )
    reply = response.choices[0].message.content
    history.append({"role": "assistant", "content": reply})
    return reply
```

### Long-Term Memory with Vector Store (Python)
```python
# pip install openai chromadb
from openai import OpenAI
import chromadb
from chromadb.utils import embedding_functions

client = OpenAI(api_key="YOUR_API_KEY")

# Memory store (persistent across sessions)
chroma = chromadb.PersistentClient(path="./memory_db")
ef = embedding_functions.OpenAIEmbeddingFunction(
    api_key="YOUR_API_KEY", model_name="text-embedding-3-small"
)
memory = chroma.get_or_create_collection(name="user_memory", embedding_function=ef)

def store_memory(fact: str, memory_id: str):
    memory.add(documents=[fact], ids=[memory_id])

def retrieve_memories(query: str, k: int = 3) -> list[str]:
    if memory.count() == 0:
        return []
    results = memory.query(query_texts=[query], n_results=min(k, memory.count()))
    return results["documents"][0]

def chat_with_memory(user_message: str) -> str:
    # 1. Retrieve relevant long-term memories
    memories = retrieve_memories(user_message)
    memory_context = "\n".join(f"- {m}" for m in memories)

    # 2. Build prompt with memories
    system = "You are a helpful assistant."
    if memory_context:
        system += f"\n\nWhat you remember about the user:\n{memory_context}"

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": user_message},
        ],
    )
    return response.choices[0].message.content

# Usage
store_memory("User is allergic to peanuts", "mem1")
store_memory("User prefers vegetarian food", "mem2")

print(chat_with_memory("Suggest a snack for me."))
# → considers allergy and preference
```

### Extracting Memories Automatically (Python)
```python
from pydantic import BaseModel

class Memory(BaseModel):
    facts: list[str]  # important facts worth remembering

def extract_memories(conversation: str) -> list[str]:
    response = client.beta.chat.completions.parse(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content":
                "Extract important, durable facts about the user worth "
                "remembering long-term (preferences, constraints, key info). "
                "Ignore small talk."},
            {"role": "user", "content": conversation},
        ],
        response_format=Memory,
    )
    return response.choices[0].message.parsed.facts

# After a session, extract and store memories
facts = extract_memories("I'm a vegetarian and I love spicy food. "
                         "I work as a backend engineer.")
for i, fact in enumerate(facts):
    store_memory(fact, f"auto_mem_{i}")
```

---

## Memory in Agent Frameworks

Frameworks (Chapter 05) provide memory abstractions:

- **LangChain:** `ConversationBufferMemory`, `ConversationSummaryMemory`, `VectorStoreRetrieverMemory`
- **LangGraph:** Built-in state persistence + checkpointing (pause/resume conversations)
- **Specialized:** `mem0`, `Zep` — dedicated long-term memory layers for AI apps

These handle the storage/retrieval plumbing so you focus on logic. But understanding the underlying strategies (above) is essential for debugging and tuning.

---

## Context Window Management

Memory and context management are deeply linked. Key strategies:

### Prioritization
Not all context is equal. Order matters:
```
1. System prompt (always)
2. Relevant long-term memories (retrieved)
3. Running summary of old conversation
4. Recent messages (verbatim)
5. Current message
```

### The "Lost in the Middle" Problem
Research shows LLMs attend best to information at the *start* and *end* of the context, and can miss info in the *middle* of a long context. Put the most important info at the beginning or end.

### Token Budgeting
Allocate your token budget deliberately:
```
Context window: 128K tokens
  - System + memories:  2K
  - Conversation:       8K
  - Retrieved docs:     4K (RAG)
  - Response space:     2K
  → Stay well under the limit, leave room for the response
```

---

## Mental Models

### LLM = Person With Amnesia
The LLM forgets everything the moment a call ends. Memory is like writing notes for them to read at the start of each conversation, so they can pretend to remember.

### Context Window = Desk Space
Short-term memory is what's currently on your desk. You can only fit so much. When it's full, you either file things away (summarize/store) or throw them out (truncate).

### Long-Term Memory = Filing Cabinet
Facts get filed away in a cabinet (vector store). When relevant, you pull the right folder (retrieve) and put it on your desk (context) to use it.

### Summarization = Meeting Minutes
You don't remember every word of a long meeting — you keep the minutes (summary). Same with long conversations: compress old turns into a summary.

---

## Common Mistakes

### Mistake 1: Sending Unbounded History
❌ Resending the full conversation forever → hits context limit, costs explode
✅ Use sliding window, summarization, or token budgeting

### Mistake 2: Storing Everything as Long-Term Memory
❌ Saving every message → noisy retrieval, irrelevant memories surface
✅ Extract only durable, important facts worth remembering

### Mistake 3: Never Retrieving Memories
❌ Storing memories but not searching them before responding
✅ Always retrieve relevant memories and inject them into context

### Mistake 4: Ignoring "Lost in the Middle"
❌ Burying critical info in the middle of a huge context
✅ Place key info at the start or end of the prompt

### Mistake 5: Summarizing Too Aggressively
❌ Compressing so much that important detail is lost
✅ Keep recent messages verbatim; summarize only older history

### Mistake 6: No Memory Isolation Between Users
❌ One shared memory store mixing different users' data
✅ Namespace/partition memory by user ID — also a privacy requirement

---

## Interview Questions

### Q1: LLMs are stateless — so how do chatbots "remember" conversations?
**Answer:** LLMs are indeed stateless; each API call is independent and the model only "sees" what's in the current context window. Chatbots simulate memory by storing the conversation history in the application and resending the relevant messages with every call. The model isn't remembering — the application is managing state and feeding it back. As conversations grow, the app uses strategies like sliding windows, summarization, or token trimming to keep the history within the context window.

### Q2: What is the difference between short-term and long-term memory in AI systems?
**Answer:** Short-term (working) memory is the conversation history within the current session, held in the context window and resent with each call — it's bounded by the context limit. Long-term memory persists across sessions: durable facts, preferences, and summaries stored externally in a database or vector store, retrieved when relevant (typically via RAG). Short-term is about maintaining coherence in the current conversation; long-term is about remembering a user across days, weeks, or different sessions.

### Q3: How do you handle a conversation that exceeds the context window?
**Answer:** Several strategies: (1) Sliding window — keep only the most recent N messages, dropping older ones. (2) Summarization — compress older messages into a running summary while keeping recent messages verbatim. (3) Token-based trimming — drop oldest messages until you fit a token budget. (4) Hybrid/retrieval — store the full history externally and retrieve only relevant past messages via vector search. The production pattern is hybrid: a running summary plus recent verbatim messages plus relevant retrieved memories. The right choice balances cost, completeness, and latency.

### Q4: How does long-term memory work and how is it related to RAG?
**Answer:** Long-term memory applies the RAG pattern to user-specific information. After interactions, you extract important, durable facts, embed them, and store them in a vector store. Before generating a response, you embed the current message, search the memory store for relevant memories, and inject them into the prompt as context. It's essentially RAG where the "documents" are memories about the user. This lets an assistant recall a user's preferences or constraints across sessions without retraining.

### Q5: What is the "lost in the middle" problem?
**Answer:** Research shows that LLMs attend most strongly to information at the beginning and end of their context window, and often overlook or under-weight information placed in the middle of a long context. This means simply stuffing more into the context doesn't guarantee the model uses it. The mitigation is to place the most important information (instructions, key facts, retrieved documents) at the start or end of the prompt, keep contexts focused, and use retrieval to include only what's relevant rather than dumping everything in.

### Q6: How would you design memory for a personal assistant used by many users?
**Answer:** I'd separate short-term and long-term memory. Short-term: per-session conversation history managed with summarization + a recent-message window. Long-term: a vector store namespaced/partitioned by user ID for isolation and privacy, where I extract durable facts after sessions and retrieve relevant ones before responding. I'd add a memory extraction step (using structured output) to store only meaningful facts, implement token budgeting to manage context, place key info at the start/end to avoid lost-in-the-middle, and ensure compliance (let users view/delete their memories). I'd likely use a dedicated memory layer like mem0 or Zep, or LangGraph checkpointing, in production.

---

## Practice Exercises

Setup:
```bash
# Python
pip install openai chromadb pydantic python-dotenv

# Node.js
npm install openai
```

### Exercise 1: Sliding Window Chatbot
Build a chatbot that keeps only the last 6 messages. Have a 10-message conversation and observe what it forgets.

### Exercise 2: Summarization Memory
Extend Exercise 1 to summarize older messages instead of dropping them. Verify it still recalls early facts after many turns.

### Exercise 3: Long-Term Memory Store
Build a vector-store memory. In session 1, tell it 3 facts about yourself. In a new session, ask questions that require recalling those facts.

### Exercise 4: Automatic Memory Extraction
Use structured output to automatically extract durable facts from a conversation, then store them. Verify it ignores small talk.

### Exercise 5: Token Budgeting
Implement a token counter. Build a chatbot that trims history to stay under a fixed token budget. Log token usage per turn.

### Exercise 6: Multi-User Memory
Extend your long-term memory to support multiple users with isolated memory (namespaced by user ID). Verify user A's memories never leak into user B's responses.

---

## Summary Table

| Concept | Simple Meaning | Key Detail |
|---------|---------------|------------|
| Stateless LLM | No memory between calls | App must manage state |
| Short-term memory | Current conversation | Lives in context window |
| Long-term memory | Persists across sessions | Vector store + retrieval |
| Sliding window | Keep last N messages | Bounded, forgets old |
| Summarization | Compress old history | Retains gist, costs a call |
| Lost in the middle | LLMs miss mid-context info | Put key info at start/end |
| Memory extraction | Save only durable facts | Use structured output |

---

## Key Takeaways

- **LLMs are stateless** — memory is an engineering layer you build around them
- **Short-term memory = conversation history** in the context window
- **Long-term memory = external store + retrieval** (RAG applied to memories)
- **Manage growing conversations** with sliding windows, summarization, or token budgeting
- **Store only durable, important facts** as long-term memory — not everything
- **Always retrieve relevant memories** before responding
- **Beware "lost in the middle"** — place key info at the start or end
- **Isolate memory per user** — for correctness and privacy

---

## What's Next?

After completing this chapter:

**Move to Chapter 08 → Evals, Tracing & Observability**
- Learn how to measure whether your AI system actually works
- Build evaluation datasets and metrics
- Trace and debug LLM applications in production

**Don't move on until:**
- You've built short-term memory (sliding window + summarization)
- You've built long-term memory with a vector store
- You can explain stateless LLMs vs application-managed memory
- You understand the "lost in the middle" problem
- You've completed at least 4 of the 6 exercises

---

**Time spent:** ___ hours | **Date completed:** ___
