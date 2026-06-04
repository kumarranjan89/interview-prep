# Chapter 11 — AI + Frontend: Your Superpower

Building AI-powered user interfaces — streaming, chat, and generative UI.  
**Time to complete:** 4–5 hours | **Exercises:** 6

---

## Navigation
← [Chapter 10: Fine-Tuning](./10-fine-tuning.md) | → [Chapter 12: AI System Design](./12-system-design.md)

---

## Why Frontend + AI Is a Superpower

Most engineers can call an LLM API. Far fewer can build a *great AI user experience*. As a frontend engineer, this is your edge.

```
Backend dev:   "It returns the right JSON" ✅
Frontend dev:  "It returns the right JSON AND feels instant,
                streams smoothly, handles errors gracefully,
                and is a joy to use" ✅✅✅
```

**The AI UX challenges that are uniquely frontend:**
> LLMs are *slow* and *non-deterministic*. Great AI UIs make slowness feel fast (streaming), uncertainty feel safe (loading/error states), and raw text feel structured (rich rendering).

---

## The Core Challenge: Latency

LLMs generate token-by-token — responses take seconds. Traditional request/response UX (spinner → wait → result) feels broken.

```
❌ Bad UX:                    ✅ Good UX:
[spinner.....5s.....]         Tokens stream in immediately,
   → full answer              answer builds word-by-word
User thinks: "is it frozen?"  User reads as it generates
```

**Streaming is the single most important AI frontend technique.**

---

## Streaming Fundamentals

Streaming sends the response incrementally as it's generated, using **Server-Sent Events (SSE)** or chunked responses.

```
Server (LLM) ──token──> ──token──> ──token──> Client
                                              (renders live)
```

**Two parts:**
1. **Backend** — streams tokens from the LLM to the client
2. **Frontend** — receives chunks and updates the UI in real time

---

## The Vercel AI SDK

The **Vercel AI SDK** is the most popular toolkit for building AI frontends in TypeScript/React. It handles streaming, state, and UI integration.

**Key features:**
- `streamText` / `generateText` — backend streaming helpers
- `useChat` / `useCompletion` — React hooks for chat UIs
- Provider-agnostic — OpenAI, Anthropic, Google, etc.
- Tool calling, structured output, and generative UI support
- Framework support — Next.js, React, Vue, Svelte

---

## Code Examples

### Streaming API Route — Next.js (App Router)
```typescript
// app/api/chat/route.ts
// npm install ai @ai-sdk/openai
import { openai } from "@ai-sdk/openai";
import { streamText } from "ai";

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: openai("gpt-4o-mini"),
    messages,
    system: "You are a helpful assistant.",
  });

  // Streams the response back to the client
  return result.toDataStreamResponse();
}
```

### Chat UI with useChat — React
```tsx
// app/page.tsx
"use client";
import { useChat } from "ai/react";

export default function Chat() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } =
    useChat({ api: "/api/chat" });

  return (
    <div className="flex flex-col h-screen max-w-2xl mx-auto p-4">
      {/* Message list */}
      <div className="flex-1 overflow-y-auto space-y-4">
        {messages.map((m) => (
          <div
            key={m.id}
            className={m.role === "user" ? "text-right" : "text-left"}
          >
            <span
              className={`inline-block px-4 py-2 rounded-lg ${
                m.role === "user"
                  ? "bg-blue-500 text-white"
                  : "bg-gray-200 text-gray-900"
              }`}
            >
              {m.content}
            </span>
          </div>
        ))}
        {isLoading && <div className="text-gray-400">Thinking...</div>}
      </div>

      {/* Input */}
      <form onSubmit={handleSubmit} className="flex gap-2 mt-4">
        <input
          value={input}
          onChange={handleInputChange}
          placeholder="Ask anything..."
          className="flex-1 border rounded-lg px-4 py-2"
        />
        <button
          type="submit"
          className="bg-blue-500 text-white px-6 py-2 rounded-lg"
        >
          Send
        </button>
      </form>
    </div>
  );
}
```

### Raw Streaming (No SDK) — Fetch + ReadableStream
```typescript
async function streamChat(message: string, onToken: (t: string) => void) {
  const response = await fetch("/api/chat", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ message }),
  });

  const reader = response.body!.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    const chunk = decoder.decode(value);
    onToken(chunk);  // update UI with each chunk
  }
}

// Usage in a component
let text = "";
await streamChat("Hello!", (token) => {
  text += token;
  setMessage(text);  // re-render with growing text
});
```

### Backend Raw Streaming — Express
```typescript
import express from "express";
import OpenAI from "openai";

const app = express();
const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

app.post("/api/chat", express.json(), async (req, res) => {
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");

  const stream = await client.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [{ role: "user", content: req.body.message }],
    stream: true,
  });

  for await (const chunk of stream) {
    const content = chunk.choices[0]?.delta?.content ?? "";
    if (content) res.write(content);
  }
  res.end();
});
```

### Structured Output Streaming — Generative UI
```tsx
// Stream structured objects to render rich UI as it generates
"use client";
import { experimental_useObject as useObject } from "ai/react";
import { z } from "zod";

const recipeSchema = z.object({
  name: z.string(),
  ingredients: z.array(z.string()),
  steps: z.array(z.string()),
});

export default function RecipeGenerator() {
  const { object, submit, isLoading } = useObject({
    api: "/api/recipe",
    schema: recipeSchema,
  });

  return (
    <div>
      <button onClick={() => submit("Make a pasta recipe")}>Generate</button>

      {/* Renders progressively as fields stream in */}
      {object?.name && <h2>{object.name}</h2>}
      {object?.ingredients && (
        <ul>{object.ingredients.map((i, idx) => <li key={idx}>{i}</li>)}</ul>
      )}
      {object?.steps && (
        <ol>{object.steps.map((s, idx) => <li key={idx}>{s}</li>)}</ol>
      )}
    </div>
  );
}
```

---

## AI UX Patterns

### 1. Streaming Text
Show tokens as they arrive. The baseline for any AI chat. (Examples above.)

### 2. Loading & Thinking States
While waiting for the first token, show meaningful feedback.
```
"Thinking..." → "Searching documents..." → streaming answer
```
For agents, show *what* it's doing (tool calls), not just a spinner.

### 3. Optimistic UI
Show the user's message immediately before the server responds.

### 4. Stop / Regenerate
Let users cancel a streaming response or regenerate a different one.
```tsx
const { stop, reload } = useChat();
// <button onClick={stop}>Stop</button>
// <button onClick={reload}>Regenerate</button>
```

### 5. Markdown & Code Rendering
LLMs output Markdown. Render it richly (headings, lists, code blocks with syntax highlighting).
```tsx
// npm install react-markdown react-syntax-highlighter
import ReactMarkdown from "react-markdown";
<ReactMarkdown>{message.content}</ReactMarkdown>
```

### 6. Citations & Sources
For RAG apps (Chapter 03), show which documents the answer came from. Builds trust.

### 7. Generative UI
Stream structured data and render actual UI components (cards, charts, forms) instead of plain text — the cutting edge of AI UX.

### 8. Error & Retry States
Network errors, rate limits, content filtering — handle gracefully with clear messages and retry buttons.

---

## Generative UI (The Frontier)

Instead of the LLM returning text, it returns *structured data* or *chooses UI components* to render. The frontend turns that into rich, interactive interfaces.

```
User: "Show me the weather in Tokyo"

Plain text response:
  "It's 18°C and rainy in Tokyo."

Generative UI response:
  <WeatherCard city="Tokyo" temp={18} condition="rainy" icon="🌧️" />
```

**How it works:** combine tool calling (Chapter 04) + structured output (Chapter 06) + streaming. The LLM decides which component and props; your frontend renders it.

---

## Security on the Frontend

Critical: **never expose your API key in the browser.**

```
❌ DANGEROUS:
   const client = new OpenAI({ apiKey: "sk-..." });  // in browser code!
   → key is visible in the bundle, anyone can steal it

✅ SAFE:
   Browser → your backend API route → LLM provider
   The key lives ONLY on the server.
```

**Other frontend security concerns:**
- **Rate limiting** at your API route (prevent abuse, Chapter 09)
- **Input validation** before forwarding to the LLM
- **Prompt injection** — sanitize user input (Chapter 06)
- **Auth** — protect your AI endpoints
- **Cost controls** — a public AI endpoint can drain your budget

---

## Performance Tips

- **Stream everything** — never block on full responses
- **Debounce inputs** — for autocomplete/suggestion features
- **Optimistic updates** — render user actions instantly
- **Virtualize long chats** — render only visible messages (e.g., react-window)
- **Cancel stale requests** — abort previous streams when a new one starts
- **Edge runtime** — deploy API routes close to users for lower latency

---

## Mental Models

### Streaming = Typing Effect, But Real
The word-by-word appearance isn't a gimmick — it's the actual generation. It makes a 5-second wait feel like a conversation instead of a freeze.

### Frontend = The Last Mile of AI
The model can be brilliant, but if the UX is clunky, users won't care. The frontend is where AI capability becomes AI *value*.

### Generative UI = LLM as a UI Compiler
Instead of generating text, the LLM generates a description of UI, and your frontend "compiles" it into real components. The LLM becomes a dynamic interface designer.

### API Key = House Key
You'd never tape your house key to the front door. Never put your API key in browser code — keep it on the server, behind your own door.

---

## Common Mistakes

### Mistake 1: Exposing API Keys in the Browser
❌ Calling the LLM provider directly from client code
✅ Always proxy through your own backend; key stays server-side

### Mistake 2: No Streaming
❌ Blocking spinner for 5+ seconds → feels broken
✅ Stream tokens for instant, responsive feel

### Mistake 3: No Loading/Error States
❌ Blank screen or crash on slow/failed requests
✅ Show thinking states, handle errors with retry

### Mistake 4: Rendering Raw Markdown as Text
❌ Showing `**bold**` and ` ```code``` ` literally
✅ Render Markdown richly with syntax highlighting

### Mistake 5: No Way to Stop/Regenerate
❌ User stuck watching an unwanted long response
✅ Provide stop and regenerate controls

### Mistake 6: No Rate Limiting on AI Endpoints
❌ Public endpoint → abuse → huge bill
✅ Rate limit and authenticate AI routes (Chapter 09)

### Mistake 7: Not Cancelling Stale Streams
❌ Old responses overwrite new ones; memory leaks
✅ Abort previous streams when a new request starts

---

## Interview Questions

### Q1: Why is streaming important in AI frontends and how does it work?
**Answer:** LLMs generate token-by-token and full responses take seconds, so a traditional spinner-then-result UX feels broken or frozen. Streaming sends the response incrementally as it's generated, letting the UI render text word-by-word immediately. This dramatically improves *perceived* latency — users start reading right away even though total generation time is unchanged. Technically, it uses Server-Sent Events or chunked HTTP responses: the backend streams tokens from the LLM (using `stream: true`) to the client, which reads the stream (e.g., via ReadableStream or a hook like `useChat`) and updates state on each chunk.

### Q2: How do you keep API keys secure in an AI web app?
**Answer:** Never put the API key in client-side code — it would be visible in the browser bundle and easily stolen. Instead, route all LLM calls through your own backend: the browser calls your API endpoint, and your server (where the key lives in an environment variable or secret manager) calls the LLM provider. This also lets you add rate limiting, authentication, input validation, and cost controls at your endpoint. A public AI endpoint without these protections can be abused to drain your budget, so guarding the server route is as important as hiding the key.

### Q3: What is generative UI?
**Answer:** Generative UI is a pattern where the LLM produces structured data or selects UI components to render, rather than just plain text, and the frontend turns that into rich, interactive interfaces — like a weather card, a chart, or a form instead of a sentence. It combines tool calling, structured output, and streaming: the model decides which component and what props based on the user's request, and the frontend renders the actual React (or other) components. It's the frontier of AI UX because it makes AI responses interactive and visual rather than text-only.

### Q4: How do you handle errors and loading states in an AI UI?
**Answer:** For loading, show meaningful feedback before the first token arrives — a "thinking" indicator, and for agents, surface what they're doing (e.g., "searching documents", tool calls) rather than a generic spinner. Use optimistic UI to render the user's message instantly. For errors — network failures, rate limits (429), content moderation blocks, timeouts — catch them and show clear, friendly messages with a retry/regenerate option rather than crashing or leaving a blank screen. Also provide stop controls for long streams and cancel stale requests when a new one starts. Good state handling is what makes a non-deterministic, slow system feel reliable.

### Q5: What is the Vercel AI SDK and what does it provide?
**Answer:** The Vercel AI SDK is a TypeScript toolkit for building AI applications, especially frontends. On the backend it provides helpers like `streamText` and `generateText` that handle streaming and provider abstraction (OpenAI, Anthropic, Google, etc.). On the frontend it provides React hooks like `useChat`, `useCompletion`, and `useObject` that manage streaming state, message history, loading flags, and stop/regenerate controls out of the box. It also supports tool calling, structured/object streaming, and generative UI. It removes most of the boilerplate of wiring streaming LLM responses into a React UI.

### Q6: How do you display RAG citations in the UI and why?
**Answer:** For a RAG application, alongside the generated answer you display the source documents that the retrieval step returned and that the answer is grounded in — typically as clickable references, footnotes, or source cards with titles/links. The backend returns the retrieved chunks' metadata (source, title, score) along with the answer, and the frontend renders them. This matters because it builds user trust, lets users verify the answer against the source, and provides transparency about where information came from — which is especially important in high-stakes domains where users need to confirm accuracy.

---

## Practice Exercises

Setup:
```bash
# Next.js + Vercel AI SDK
npx create-next-app@latest my-ai-app
cd my-ai-app
npm install ai @ai-sdk/openai zod react-markdown
```

### Exercise 1: Streaming Chat
Build a basic streaming chat UI with the Vercel AI SDK (`useChat` + a streaming API route). Verify tokens appear progressively.

### Exercise 2: Markdown Rendering
Add Markdown rendering with syntax highlighting to your chat. Ask for a code example and verify it renders properly.

### Exercise 3: Stop & Regenerate
Add stop and regenerate buttons. Test stopping a long response mid-stream and regenerating a new answer.

### Exercise 4: Loading & Error States
Add a "thinking" indicator and graceful error handling (simulate a failed request). Add a retry button.

### Exercise 5: Generative UI
Build a feature where the LLM returns structured data (e.g., a weather or recipe object) and you render it as a styled component using `useObject`.

### Exercise 6: Secure RAG Chat
Build a RAG chat (combining Chapter 03) where the backend retrieves documents and the UI shows the answer WITH source citations. Ensure the API key never reaches the browser.

---

## Summary Table

| Concept | Simple Meaning | Key Detail |
|---------|---------------|------------|
| Streaming | Render tokens as generated | Most important AI UX technique |
| Vercel AI SDK | Toolkit for AI frontends | `useChat`, `streamText` |
| Generative UI | LLM picks UI components | Tool calling + structured output |
| Loading states | Feedback while waiting | Show what's happening |
| API key security | Keep keys server-side | Never in browser code |
| Markdown rendering | Render rich text | Code blocks, lists, headings |
| Citations | Show RAG sources | Builds trust |

---

## Key Takeaways

- **Frontend is the last mile of AI** — great UX turns capability into value
- **Streaming is the #1 technique** — makes slow LLMs feel instant
- **Never expose API keys in the browser** — always proxy through your backend
- **Use the Vercel AI SDK** — `useChat`/`streamText` handle the hard parts
- **Handle loading, error, and stop states** — make non-determinism feel safe
- **Render Markdown richly** — and show citations for RAG apps
- **Generative UI is the frontier** — LLMs that render components, not just text
- **Secure and rate-limit AI endpoints** — protect against abuse and cost

---

## What's Next?

After completing this chapter:

**Move to Chapter 12 → AI System Design (Staff-level interviews)**
- Design end-to-end AI systems at scale
- Combine everything: RAG, agents, memory, evals, production concerns
- Handle the open-ended system design interview

**Don't move on until:**
- You've built a streaming chat UI
- You've added Markdown rendering, stop/regenerate, and error states
- You can explain why API keys must stay server-side
- You've built a generative UI feature
- You've completed at least 4 of the 6 exercises

---

**Time spent:** ___ hours | **Date completed:** ___
