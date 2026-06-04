# Chapter 01 — LLM Fundamentals
> **What LLMs are, how they work, and why they behave the way they do.**
> Time to complete: 2–3 hours | Exercises: 6

---

## Navigation
← [README (Index)](./README.md) | → [Chapter 02: Embeddings & Vectors](./02-embeddings-and-vectors.md)

---

## What is an LLM?

LLM = Large Language Model

Simple meaning: A program that predicts the next most likely word (token), given everything before it.

Think of it like:

- "The sky is ___" → "blue" (very confident)
- "The best programming language is ___" → "JavaScript / Python / Rust" (less confident)
- "Write me a function to sort an array" → generates code token by token

**LLMs do NOT:**
- Look things up in a database
- Know facts with certainty
- Understand language the way humans do

**LLMs DO:**
- Predict statistically likely next tokens
- Learn patterns from billions of documents
- Generate surprisingly useful text because human knowledge is in those patterns

---

## The Core Building Blocks

### 1. Tokens — What LLMs Actually Read

An LLM never reads words. It reads **tokens**.

```
"Hello, how are you?"

Tokens: ["Hello", ",", " how", " are", " you", "?"]
        →  6 tokens
```

More examples:

```
"ChatGPT"     → 1 token   (common word)
"Anthropic"   → 3 tokens  [" Anthrop", "ic"]  (less common)
"Rahul"       → 2 tokens  [" Rah", "ul"]
"😊"           → 1–3 tokens (emoji = multiple)
```

**Why this matters for you as an engineer:**

```
1 token ≈ 4 characters ≈ 0.75 words

GPT-4 context window: 128,000 tokens ≈ 96,000 words ≈ a full novel
Claude 3.5: 200,000 tokens ≈ 150,000 words

Cost is calculated per token:
  Input tokens  → you pay to send
  Output tokens → you pay to receive
  
Example: GPT-4o
  Input:  $2.50 per million tokens
  Output: $10.00 per million tokens
```

**Gotcha:** Longer prompts = more tokens = higher cost + slower response.
Always measure token count before going to production.

---

### 2. Context Window — The LLM's Working Memory

```
┌─────────────────────────────────────────────────┐
│              CONTEXT WINDOW                     │
│                                                 │
│  System Prompt     │ Your instructions          │
│  ─────────────────────────────────────          │
│  Previous messages │ Conversation history       │
│  ─────────────────────────────────────          │
│  Current message   │ What user just said        │
│  ─────────────────────────────────────          │
│  [GENERATES HERE]  │ LLM response               │
└─────────────────────────────────────────────────┘
```

Simple meaning: Everything the LLM can "see" at once.

**Critical behavior:**
- LLM has NO memory between separate API calls
- Each API call = fresh start, you must resend history
- When context fills up → either truncate (forget old messages) or error

```
// Every API call looks like this — full history every time
const response = await openai.chat.completions.create({
  model: "gpt-4o",
  messages: [
    { role: "system",    content: "You are a helpful assistant." },
    { role: "user",      content: "My name is Rahul." },     // past message
    { role: "assistant", content: "Hi Rahul!" },              // past response
    { role: "user",      content: "What's my name?" },        // current
  ]
});
// Without sending "My name is Rahul" again, it would not know
```

---

### 3. Temperature — How "Creative" the LLM Is

```
Temperature 0.0  →  Deterministic, same answer every time
                     Use for: code, data extraction, classification

Temperature 0.7  →  Balanced, slight variation
                     Use for: general chat, summaries, Q&A

Temperature 1.0+ →  Creative, unpredictable, sometimes weird
                     Use for: creative writing, brainstorming
```

**Mental model:** Think of temperature like a confidence dial.

```
Low temp  = LLM picks the MOST likely next token every time
            → predictable, focused, can be repetitive

High temp = LLM randomly picks from a wider range of tokens
            → varied, creative, can go off-track
```

**As an engineer:** Start with `temperature: 0` for anything that needs consistent output (JSON extraction, classification). Increase only when you need variation.

---

### 4. The Transformer — How LLMs Are Built

You don't need to know the math. You need the mental model.

```
Input tokens
     ↓
┌────────────────────────┐
│   EMBEDDING LAYER      │  Words → numbers (vectors)
└────────────────────────┘
     ↓
┌────────────────────────┐
│   ATTENTION LAYER 1    │  Each token looks at ALL other tokens
├────────────────────────┤  and decides what's relevant
│   ATTENTION LAYER 2    │
├────────────────────────┤  "sat" looks at "cat" heavily
│   ATTENTION LAYER 3    │  "sat" looks at "the" lightly
│        ...             │
│   ATTENTION LAYER N    │
└────────────────────────┘
     ↓
┌────────────────────────┐
│   OUTPUT LAYER         │  Numbers → probability over all tokens
└────────────────────────┘
     ↓
Pick next token (based on temperature)
     ↓
Repeat until done
```

**The key insight — Attention:**

When processing "The cat sat on the mat", for the word "sat":
- It pays HIGH attention to "cat" (who sat?)
- It pays MEDIUM attention to "mat" (sat where?)
- It pays LOW attention to "The", "on", "the"

This is why LLMs understand context — not just the current word, but all words in relation to each other.

---

### 5. Parameters — The "Size" of an LLM

```
GPT-2       →  1.5 billion parameters    (2019, you can run locally)
GPT-3       →  175 billion parameters   (2020, API only)
GPT-4       →  ~1 trillion parameters   (estimated, not confirmed)
Llama 3 8B  →  8 billion parameters     (runs on a good laptop)
Llama 3 70B →  70 billion parameters    (needs a GPU server)
```

**Simple mental model:** Parameters = the "knobs" adjusted during training.
More knobs = can capture more complex patterns = smarter (generally).

**Why it matters for you:**
- Bigger models = smarter but slower + more expensive
- Smaller models = faster + cheaper but less capable
- For production: use the smallest model that does the job well

---

## How Training Works (Just Enough to Know)

```
Step 1: PRETRAINING
  Feed the model: most of the internet + books + code
  Task: "Predict the next token"
  Result: Model learns language, facts, code, reasoning
  Cost: $millions, done by OpenAI/Anthropic/Meta

Step 2: FINE-TUNING (RLHF)
  Feed the model: human-curated Q&A examples
  Task: "Answer questions helpfully and safely"
  Result: Model becomes a useful assistant, not just a predictor
  
Step 3: YOU USE IT VIA API
  You send prompts, get completions
  You pay per token
```

You will almost never do Step 1 or Step 2. You work at Step 3.
(Chapter 10 covers the rare cases when you do fine-tune.)

---

## Why Hallucinations Happen

This is one of the most important things to understand.

**Hallucination** = LLM confidently states something false.

**Why it happens:**

```
LLM is trained to predict the MOST LIKELY next token.
Not the MOST TRUE next token.

Example:
  Prompt: "The capital of Australia is ___"
  
  During training, the model saw:
  - "Sydney is the largest city in Australia" (many times)
  - "The capital of Australia is Canberra" (fewer times)
  
  If temperature > 0, model might output "Sydney"
  Sydney FEELS right (it's the most famous city)
  But Canberra IS right
```

**The deeper reason:**

```
The model doesn't "know" facts.
It knows statistical patterns of text.

If you ask about a niche topic with little training data:
  - Model has few patterns to draw from
  - It fills gaps with plausible-sounding text
  - That plausible text can be completely wrong
```

**How to fight hallucinations (preview of Chapter 03 — RAG):**

```
Instead of: "Tell me about our company policy"
            → LLM guesses / makes things up

Do this:    "Here is our policy: [paste document]
             Based on ONLY this document, what is the policy?"
            → LLM answers from the given text, not from training
```

This is the core idea behind RAG. More in Chapter 03.

---

## The Three Roles in Every API Call

Every LLM API uses this structure:

```python
messages = [
  {
    "role": "system",       # Your instructions to the LLM
    "content": "You are a helpful assistant that answers only about Python."
  },
  {
    "role": "user",         # What the human said
    "content": "How do I reverse a list?"
  },
  {
    "role": "assistant",    # What the LLM said (for conversation history)
    "content": "You can use list.reverse() or list[::-1]"
  },
  {
    "role": "user",         # New human message
    "content": "Which is faster?"
  }
]
```

| Role | Who | Purpose |
|---|---|---|
| `system` | You (developer) | Sets LLM behavior, persona, constraints |
| `user` | End user | What they're asking |
| `assistant` | LLM | Previous responses (for memory) |

**System prompt = your most powerful tool.**
It defines everything: tone, format, what to refuse, what to focus on.

---

## Code Example

### Basic API Call — Python

```python
# pip install openai
from openai import OpenAI

client = OpenAI(api_key="YOUR_API_KEY")

response = client.chat.completions.create(
    model="gpt-4o-mini",          # cheaper model for learning
    temperature=0,                 # deterministic output
    max_tokens=500,               # limit response length
    messages=[
        {
            "role": "system",
            "content": "You are a helpful assistant. Answer concisely."
        },
        {
            "role": "user",
            "content": "What is a transformer in machine learning?"
        }
    ]
)

# Get the text response
answer = response.choices[0].message.content
print(answer)

# Check token usage (important for cost management!)
print(f"Input tokens:  {response.usage.prompt_tokens}")
print(f"Output tokens: {response.usage.completion_tokens}")
print(f"Total tokens:  {response.usage.total_tokens}")
```

### Basic API Call — JavaScript/TypeScript (your comfort zone)

```typescript
// npm install openai
import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function askLLM(question: string): Promise<string> {
  const response = await client.chat.completions.create({
    model: "gpt-4o-mini",
    temperature: 0,
    max_tokens: 500,
    messages: [
      {
        role: "system",
        content: "You are a helpful assistant. Answer concisely.",
      },
      {
        role: "user",
        content: question,
      },
    ],
  });

  // Log token usage — always track this
  console.log("Tokens used:", response.usage?.total_tokens);

  return response.choices[0].message.content ?? "";
}

// Usage
const answer = await askLLM("What is a transformer in machine learning?");
console.log(answer);
```

### Conversation with Memory

```typescript
import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

type Message = {
  role: "system" | "user" | "assistant";
  content: string;
};

// Store conversation history in memory
const history: Message[] = [
  {
    role: "system",
    content: "You are a helpful AI tutor teaching LLM concepts.",
  },
];

async function chat(userMessage: string): Promise<string> {
  // Add user message to history
  history.push({ role: "user", content: userMessage });

  const response = await client.chat.completions.create({
    model: "gpt-4o-mini",
    temperature: 0.7,
    messages: history,   // Always send full history
  });

  const assistantMessage = response.choices[0].message.content ?? "";

  // Add assistant response to history so next call has context
  history.push({ role: "assistant", content: assistantMessage });

  return assistantMessage;
}

// Try it
console.log(await chat("My name is Rahul and I'm learning AI."));
// → "Nice to meet you, Rahul! ..."

console.log(await chat("What is my name?"));
// → "Your name is Rahul." (works because history is included)
```

---

## Mental Models

### LLM = Extremely Well-Read Autocomplete

```
Your phone's autocomplete:
  "Happy birth___" → "day"  (simple pattern)

LLM autocomplete:
  "Explain quantum entanglement as if I'm 10___"
  → generates a full, accurate, age-appropriate explanation
  (complex pattern, but still just next-token prediction)
```

### Context Window = RAM, Not Hard Disk

```
RAM (context window):
  - Fast access
  - Limited size
  - Gone when you close the session
  - LLM can "see" and reason about everything in it

Hard disk (training data):
  - LLM "learned" from this during training
  - Cannot access it directly at inference time
  - Knowledge is baked into the weights (parameters)
```

### Temperature = Confidence Dial

```
0.0 ────────────────────────── 2.0
 |              |               |
Boring       Balanced        Chaotic
Consistent   Useful         Unpredictable
Best for:    Best for:      Best for:
code, data   chat, Q&A      creative writing
extraction   summaries      brainstorming
```

### Hallucination = Confident Confabulation

```
Like a person who:
  - Has read everything ever written
  - Has a perfect memory of patterns and styles
  - Has NEVER verified if anything was actually true
  - Answers every question with complete confidence

They'll give you a convincing answer.
It might be completely made up.
Always verify critical information from LLM output.
```

---

## Common Mistakes

### Mistake 1: Assuming LLMs "Know" Things

```
❌ Wrong assumption:
   "The LLM knows our company's Q3 revenue"
   → It doesn't. It knows patterns from its training data.

✅ Right approach:
   Provide the data in the prompt:
   "Our Q3 revenue was $2.4M. Based on this, what is the growth rate
    compared to Q2 revenue of $2.1M?"
```

### Mistake 2: Not Setting a System Prompt

```
❌ No system prompt:
   Just sending user messages with no instructions
   → LLM will try to be generally helpful, may go off-topic

✅ Always set system prompt:
   "You are a code reviewer. Review only the code provided.
    Output ONLY in JSON format: { issues: [], suggestions: [] }"
   → Predictable, structured, on-task output
```

### Mistake 3: Ignoring Token Costs in Loops

```
❌ Expensive loop:
   for each of 10,000 product descriptions:
     ask GPT-4 to classify it   ← $0.01 per call = $100 total
   
✅ Batch or use cheaper model:
   for each of 10,000 product descriptions:
     ask GPT-4o-mini to classify it   ← $0.0002 per call = $2 total
   
   Or: classify 20 at once in one prompt = 500 calls instead of 10,000
```

### Mistake 4: Temperature 1.0 for Code Generation

```
❌ Wrong:
   temperature: 1.0 for generating code
   → Different code every run, unpredictable behavior

✅ Right:
   temperature: 0 for code, data extraction, classification
   temperature: 0.7 for explanations, summaries
   temperature: 1.0 only for creative tasks
```

### Mistake 5: Sending Sensitive Data to External APIs

```
❌ Dangerous:
   Sending user PII, passwords, internal API keys in prompts
   → Goes to OpenAI/Anthropic servers, stored in logs

✅ Safe approach:
   Anonymize before sending: replace names, emails, IDs
   Or use: Azure OpenAI (your own deployment) / local models
   Always check your company's data policy first
```

---

## Interview Questions

### Q1: What is an LLM and how does it work?

**Answer:**
An LLM is a neural network trained to predict the next token in a sequence. It's built on the Transformer architecture, which uses self-attention to let every token in the input look at every other token and decide what's relevant. During training on massive text datasets, it learns statistical patterns — not facts, but the relationships between words, concepts, and ideas. When you prompt it, it generates a response one token at a time, each token chosen based on probabilities over its entire vocabulary, influenced by temperature. The key insight is that it's not a database lookup — it's statistical pattern completion, which is why it can generalize and also why it hallucinates.

---

### Q2: What is a context window and why does it matter in production?

**Answer:**
The context window is the maximum amount of text an LLM can process in a single call — both input and output combined. It's the model's working memory. Nothing outside the context window exists to the model. In production this matters for several reasons: first, cost scales with tokens, so large context windows are expensive; second, for long conversations you need a strategy to handle context overflow — either truncating old messages, summarizing history, or using external memory; third, research shows LLM attention degrades in very long contexts — important information in the middle of a 200K token context is often missed. The engineering pattern to handle this is RAG — retrieve only the relevant chunks rather than dumping everything into context.

---

### Q3: Why do LLMs hallucinate and how do you mitigate it?

**Answer:**
LLMs hallucinate because they're optimized to predict statistically likely text, not factually true text. When asked about something outside their training data — or even within it if the training signal was weak — they generate plausible-sounding text rather than saying "I don't know." The three main mitigation strategies are: first, RAG — provide the ground truth in the prompt so the model answers from provided context, not from training; second, temperature zero for factual tasks, which makes the model pick the highest-probability token rather than sampling randomly; third, output validation — have another LLM or rule-based system check if the answer is grounded in the provided context. For high-stakes domains like medical or legal, always treat LLM output as a draft that needs human verification.

---

### Q4: What is the difference between model parameters and the context window?

**Answer:**
Parameters are the weights of the neural network — the billions of numbers learned during training that encode all the model's knowledge and capabilities. They're fixed after training. The context window is the runtime working memory — the text that the model can actively attend to during a single inference call. A useful analogy: parameters are like a person's long-term memory and skills built over a lifetime of learning; the context window is like their short-term working memory during a single conversation. Making a model smarter (more parameters) requires retraining. Making it remember more in a conversation just requires a larger context window.

---

## Practice Exercises

Use this to set up your environment:

```bash
# Python setup
pip install openai python-dotenv

# Create .env file
echo "OPENAI_API_KEY=your_key_here" > .env
```

**Exercise 1: Hello LLM**
Make your first API call. Ask it to explain tokens in one sentence.
Expected: A response you can read and understand.

**Exercise 2: Token counting**
Send three different prompts. Log the token count for each.
Which used the most tokens? Why?

**Exercise 3: Temperature experiment**
Ask "What is the best programming language?" with:
- temperature: 0 (run 3 times, compare)
- temperature: 1.0 (run 3 times, compare)
What do you notice about consistency?

**Exercise 4: Build a conversation loop**
Build a simple terminal chatbot that remembers previous messages.
Try: tell it your name in message 1, ask for your name in message 5.

**Exercise 5: Trigger a hallucination**
Ask the LLM a very specific, obscure question about a local event or niche topic.
Observe what it says. Is it confident? Is it accurate?

**Exercise 6: Token cost calculator**
Write a function that takes a prompt string and estimates its cost.
Use: 1 token ≈ 4 characters, gpt-4o-mini input = $0.15 per million tokens.

```typescript
function estimateCost(prompt: string, model: "gpt-4o" | "gpt-4o-mini"): number {
  // Your implementation here
}
```

---

## Summary Table

| Concept | Simple Meaning | Key Number |
|---|---|---|
| Token | Chunk of text the LLM reads | 1 token ≈ 4 chars |
| Context window | LLM's working memory | GPT-4: 128K tokens |
| Temperature | Randomness of output | 0 = consistent, 1 = creative |
| Parameters | Model's learned knowledge | GPT-4: ~1 trillion |
| Hallucination | Confident wrong answer | Fix with RAG |
| System prompt | Developer instructions | First message, most powerful |

---

## Key Takeaways

- LLMs predict the next token — they don't "know" facts, they know patterns
- Context window = working memory; no memory between API calls without history
- Temperature 0 for consistent output, higher for creative tasks
- Hallucinations are fundamental to how LLMs work — always design around them
- Tokens = money; always measure and optimize token usage in production
- The system prompt is your most powerful lever — never skip it
- Parameters are fixed after training; context window is runtime-only

---

## What's Next?

After completing this chapter:

- Move to [Chapter 02 → Embeddings & Vectors](./02-embeddings-and-vectors.md)
- Embeddings are how LLMs represent meaning as numbers
- They are the foundation of RAG — the most important AI engineering pattern

**Don't move on until:**
- [ ] You've made at least one real API call
- [ ] You understand why hallucinations happen
- [ ] You can explain context windows in plain English
- [ ] You've completed at least 4 of the 6 exercises

---

*Time spent: ___ hours | Date completed: ___*