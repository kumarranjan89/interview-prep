# Chapter 04 — Agents, Tool Use & the ReAct Pattern

How to give LLMs the ability to *act* — call APIs, run code, search the web, and reason step by step.  
**Time to complete:** 4–5 hours | **Exercises:** 6

---

## Navigation
← [Chapter 03: RAG](./03-rag.md) | → [Chapter 05: Agentic Frameworks](./05-agentic-frameworks.md)

---

## What is an Agent?

**Simple meaning:** An agent is an LLM that can *take actions* in a loop — it decides what to do, does it (calls a tool), observes the result, and repeats until the task is done.

A plain LLM only *talks*. An agent *acts*.

```
Plain LLM:
  You: "What's the weather in Tokyo?"
  LLM: "I don't have access to real-time weather." ❌

Agent:
  You: "What's the weather in Tokyo?"
  Agent: [calls weather API] → observes "18°C, rainy"
  Agent: "It's 18°C and rainy in Tokyo right now." ✅
```

**The core difference:**
> An LLM predicts text. An agent uses an LLM as a *reasoning engine* to decide which actions to take in the real world.

---

## The Agent Loop

The fundamental pattern of every agent:

```
┌──────────────────────────────────────────────┐
│                  AGENT LOOP                    │
│                                                │
│   1. THINK   → LLM reasons about what to do   │
│        ↓                                       │
│   2. ACT     → LLM calls a tool               │
│        ↓                                       │
│   3. OBSERVE → Tool returns a result          │
│        ↓                                       │
│   4. REPEAT  → Until task is complete         │
│        ↓                                       │
│   5. ANSWER  → LLM gives final response       │
└──────────────────────────────────────────────┘
```

**Key insight:** The LLM doesn't execute tools itself. It *decides* which tool to call and with what arguments. Your code executes the tool and feeds the result back.

---

## What is a Tool?

A **tool** (also called a "function") is anything the LLM can call to interact with the outside world:

- **Search:** Web search, database queries, RAG retrieval
- **Compute:** Calculator, code execution, data analysis
- **APIs:** Weather, stock prices, send email, create calendar event
- **Actions:** Write a file, update a record, make a purchase

**A tool is defined by:**
1. **Name** — e.g., `get_weather`
2. **Description** — what it does (the LLM uses this to decide when to call it)
3. **Parameters** — what inputs it needs (with types)

The **description is critical** — it's how the LLM knows when and how to use the tool.

---

## Function Calling (How Tools Actually Work)

Modern LLMs support **function calling** (also called "tool use"). You give the LLM a list of available tools, and it responds with a structured request to call one.

**The flow:**
```
1. You send: user message + list of tool definitions
        ↓
2. LLM responds: "Call get_weather with { city: 'Tokyo' }"
   (it returns structured JSON, not text)
        ↓
3. Your code: executes get_weather('Tokyo') → "18°C, rainy"
        ↓
4. You send: the tool result back to the LLM
        ↓
5. LLM responds: "It's 18°C and rainy in Tokyo."
```

**Important:** The LLM never runs your code. It only *requests* a call. You stay in control of execution — critical for safety.

---

## The ReAct Pattern (Reason + Act)

**ReAct = Reasoning + Acting**

This is the most important agent pattern. The LLM alternates between **reasoning** (thinking out loud) and **acting** (calling tools), using observations to inform the next step.

```
Thought:  I need to find the weather in Tokyo.
Action:   get_weather(city="Tokyo")
Observation: 18°C, rainy

Thought:  The user also asked if they need an umbrella. It's rainy, so yes.
Action:   (none needed)
Answer:   Yes, bring an umbrella — it's 18°C and rainy in Tokyo.
```

**Why ReAct works:**
- **Reasoning** helps the LLM break complex problems into steps
- **Acting** grounds those steps in real data
- **Observations** correct course when something unexpected happens

This interleaving of thought and action is far more reliable than asking the LLM to answer in one shot.

---

## Code Examples

### Basic Tool Calling — Python (OpenAI)
```python
# pip install openai
from openai import OpenAI
import json

client = OpenAI(api_key="YOUR_API_KEY")

# 1. Define the actual tool function
def get_weather(city: str) -> str:
    # In reality, call a weather API here
    fake_data = {"Tokyo": "18°C, rainy", "Paris": "22°C, sunny"}
    return fake_data.get(city, "Unknown city")

# 2. Describe the tool to the LLM
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get the current weather for a given city",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {
                        "type": "string",
                        "description": "The city name, e.g. Tokyo",
                    }
                },
                "required": ["city"],
            },
        },
    }
]

# 3. Run the agent loop
def run_agent(user_message: str) -> str:
    messages = [{"role": "user", "content": user_message}]

    while True:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            tools=tools,
        )
        msg = response.choices[0].message
        messages.append(msg)

        # If the LLM wants to call a tool
        if msg.tool_calls:
            for tool_call in msg.tool_calls:
                args = json.loads(tool_call.function.arguments)
                if tool_call.function.name == "get_weather":
                    result = get_weather(args["city"])

                # Feed the result back
                messages.append({
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": result,
                })
        else:
            # No more tools needed — final answer
            return msg.content

print(run_agent("What's the weather in Tokyo? Do I need an umbrella?"))
# → "It's 18°C and rainy in Tokyo, so yes, bring an umbrella."
```

### Basic Tool Calling — TypeScript (OpenAI)
```typescript
// npm install openai
import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// 1. Actual tool implementation
function getWeather(city: string): string {
  const fakeData: Record<string, string> = {
    Tokyo: "18°C, rainy",
    Paris: "22°C, sunny",
  };
  return fakeData[city] ?? "Unknown city";
}

// 2. Tool definitions for the LLM
const tools: OpenAI.Chat.Completions.ChatCompletionTool[] = [
  {
    type: "function",
    function: {
      name: "get_weather",
      description: "Get the current weather for a given city",
      parameters: {
        type: "object",
        properties: {
          city: { type: "string", description: "The city name, e.g. Tokyo" },
        },
        required: ["city"],
      },
    },
  },
];

// 3. Agent loop
async function runAgent(userMessage: string): Promise<string> {
  const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
    { role: "user", content: userMessage },
  ];

  while (true) {
    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages,
      tools,
    });

    const msg = response.choices[0].message;
    messages.push(msg);

    if (msg.tool_calls) {
      for (const toolCall of msg.tool_calls) {
        const args = JSON.parse(toolCall.function.arguments);
        let result = "";
        if (toolCall.function.name === "get_weather") {
          result = getWeather(args.city);
        }
        messages.push({
          role: "tool",
          tool_call_id: toolCall.id,
          content: result,
        });
      }
    } else {
      return msg.content ?? "";
    }
  }
}

runAgent("What's the weather in Tokyo?").then(console.log);
```

### Multi-Tool Agent
```typescript
// Multiple tools — LLM picks the right one(s)
function calculate(expression: string): string {
  try {
    // In production, use a safe math parser, NOT eval
    return String(Function(`"use strict"; return (${expression})`)());
  } catch {
    return "Invalid expression";
  }
}

function searchKnowledgeBase(query: string): string {
  // This could be your RAG retrieval from Chapter 03!
  return "Refund policy: 30 days for unused items.";
}

const multiTools: OpenAI.Chat.Completions.ChatCompletionTool[] = [
  {
    type: "function",
    function: {
      name: "calculate",
      description: "Evaluate a math expression like '2 + 2 * 3'",
      parameters: {
        type: "object",
        properties: { expression: { type: "string" } },
        required: ["expression"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "search_knowledge_base",
      description: "Search company policy documents for relevant info",
      parameters: {
        type: "object",
        properties: { query: { type: "string" } },
        required: ["query"],
      },
    },
  },
];

// The agent loop dispatches to the correct tool by name:
function executeTool(name: string, args: any): string {
  switch (name) {
    case "calculate":
      return calculate(args.expression);
    case "search_knowledge_base":
      return searchKnowledgeBase(args.query);
    default:
      return "Unknown tool";
  }
}
```

### Manual ReAct Prompt (No Function Calling API)
```typescript
// Useful for understanding ReAct, or with models lacking function-calling
const reactPrompt = `You are an agent that solves tasks step by step.

Available tools:
- search(query): search the web
- calculate(expression): do math

Use this format:
Thought: <your reasoning>
Action: <tool_name>(<args>)
Observation: <result will be filled in>
... (repeat Thought/Action/Observation as needed)
Thought: I now know the answer
Answer: <final answer>

Question: {question}`;

// Your code parses the "Action:" line, runs the tool,
// appends "Observation: <result>", and sends it back to the LLM.
// Loop until the LLM outputs "Answer:".
```

---

## Single-Agent vs Multi-Agent

### Single Agent
One LLM with a set of tools handles the whole task. Simple, easier to debug. Good for most use cases.

### Multi-Agent
Multiple specialized agents collaborate, often coordinated by an "orchestrator" agent.
```
        ┌─────────────┐
        │ Orchestrator│
        └──────┬──────┘
       ┌───────┼────────┐
       ↓       ↓        ↓
  ┌────────┐ ┌──────┐ ┌────────┐
  │Research│ │Writer│ │Reviewer│
  │ Agent  │ │Agent │ │ Agent  │
  └────────┘ └──────┘ └────────┘
```
**When to use multi-agent:** Complex tasks with distinct sub-roles (research, writing, review). But it adds cost, latency, and complexity — start with a single agent.

---

## Agent Design Principles

### 1. Clear Tool Descriptions
The LLM chooses tools based on descriptions. Vague descriptions = wrong tool choices.
```
❌ "Gets data"
✅ "Fetches the current stock price for a given ticker symbol (e.g., AAPL)"
```

### 2. Limit the Number of Tools
Too many tools confuse the LLM. Keep it focused (typically < 10-15 tools). Group related ones.

### 3. Set a Max Iteration Limit
Agents can loop forever. Always cap iterations to prevent runaway cost.
```typescript
const MAX_ITERATIONS = 10;
for (let i = 0; i < MAX_ITERATIONS; i++) { /* loop */ }
```

### 4. Handle Tool Errors Gracefully
Tools fail (API down, bad input). Return the error to the LLM so it can recover.
```
Observation: ERROR — city not found. Try a different spelling.
```

### 5. Human-in-the-Loop for Dangerous Actions
For irreversible actions (send email, delete data, make a purchase), require human approval before executing.

---

## Mental Models

### Agent = LLM Brain + Tool Hands
The LLM is the brain that decides *what* to do. The tools are the hands that *do* it. Without hands, the brain can only think and talk. Without a brain, the hands don't know what to do.

### ReAct = Show Your Work
Like a math student who writes out each step instead of guessing the final answer. Reasoning between actions catches mistakes early and makes the process debuggable.

### Tools = APIs the LLM Can Read
A tool definition is like API documentation written for an LLM. The better the "docs" (description, parameter names), the better the LLM uses it.

### The LLM is the Router, Not the Engine
The LLM decides which tool to call and with what arguments. Your code is the engine that runs them. This separation keeps you in control and makes the system safe.

---

## Common Mistakes

### Mistake 1: Vague Tool Descriptions
❌ LLM can't tell when to use `process()` vs `handle()`
✅ Use clear, specific, action-oriented descriptions

### Mistake 2: No Iteration Limit
❌ Agent loops forever, burning tokens and money
✅ Always set `MAX_ITERATIONS` and break when reached

### Mistake 3: Letting the LLM Execute Code Directly
❌ Trusting the LLM to "run" anything itself
✅ The LLM only *requests* calls; your code executes them with validation

### Mistake 4: Using `eval()` for Tool Inputs
❌ `eval(llm_output)` → massive security hole
✅ Validate and sanitize all LLM-generated arguments; use safe parsers

### Mistake 5: Too Many Tools
❌ 50 tools → the LLM picks wrong ones, gets confused
✅ Keep tools focused; split into multiple specialized agents if needed

### Mistake 6: Not Handling Tool Failures
❌ Tool throws, agent crashes
✅ Catch errors, return them as observations so the LLM can adapt

### Mistake 7: No Human Approval for Risky Actions
❌ Agent auto-sends emails / deletes records
✅ Require human-in-the-loop confirmation for irreversible actions

---

## Interview Questions

### Q1: What is the difference between an LLM and an agent?
**Answer:** A plain LLM only generates text — it predicts the next token and responds. An agent uses an LLM as a reasoning engine inside a loop that can take actions in the real world via tools. The agent decides what to do, calls a tool, observes the result, and repeats until the task is complete. The key addition is the action loop and tool use, which lets the system fetch real-time data, perform computations, and affect external systems — things a plain LLM cannot do.

### Q2: Explain the ReAct pattern.
**Answer:** ReAct stands for Reasoning + Acting. It's an agent pattern where the LLM alternates between reasoning steps (thinking out loud about what to do next) and acting steps (calling tools), using the observations from each action to inform the next reasoning step. The format is typically Thought → Action → Observation, repeated until the LLM reaches an answer. It works because reasoning breaks complex tasks into manageable steps, actions ground those steps in real data, and observations let the agent self-correct. It's far more reliable than one-shot answering for multi-step tasks.

### Q3: How does function calling work? Does the LLM run the code?
**Answer:** No, the LLM never runs code. In function calling, you provide the LLM with tool definitions (name, description, parameters). When the LLM decides a tool is needed, it returns a structured JSON request specifying the tool name and arguments — it does not execute anything. Your application code receives this request, validates it, executes the actual function, and sends the result back to the LLM. The LLM then continues reasoning with that result. This separation is critical for safety: you stay in full control of what actually executes.

### Q4: How do you prevent an agent from running forever or costing too much?
**Answer:** Several safeguards: (1) Set a maximum iteration limit on the agent loop and break when reached. (2) Set a token/cost budget per task and abort if exceeded. (3) Use a cheaper model (like gpt-4o-mini) where possible. (4) Add clear stopping conditions in the prompt so the LLM knows when the task is done. (5) Implement timeouts on individual tool calls. (6) Monitor and log iterations to detect runaway behavior. Without these, an agent stuck in a reasoning loop can rack up significant cost.

### Q5: What makes a good tool definition?
**Answer:** A good tool definition has: a clear, specific name (`get_stock_price` not `getData`); a precise description that explains exactly what it does and when to use it, since the LLM relies on this to choose tools; well-named, well-typed parameters with descriptions and examples; and a defined required vs optional set. The description is the most important part — it's effectively documentation the LLM reads to decide whether and how to call the tool. Ambiguous descriptions lead to the LLM picking the wrong tool or supplying bad arguments.

### Q6: When would you use multiple agents instead of one?
**Answer:** Use multiple agents when a task has distinct specialized sub-roles that benefit from separation — for example, a research agent, a writing agent, and a reviewer agent coordinated by an orchestrator. Multi-agent setups can improve quality through specialization and separation of concerns. However, they add cost, latency, and complexity, and introduce coordination challenges. The best practice is to start with a single agent with good tools, and only move to multi-agent when a single agent demonstrably struggles with the task's complexity or distinct responsibilities.

### Q7: How do you handle dangerous or irreversible actions in an agent?
**Answer:** Use human-in-the-loop approval. For actions that are irreversible or high-risk (sending emails, making payments, deleting data, modifying production systems), the agent should pause and request explicit human confirmation before executing. Additional safeguards include: restricting tool permissions (least privilege), validating all arguments, sandboxing code execution, dry-run modes that preview the action, and audit logging. Never let an agent autonomously perform irreversible actions without guardrails.

---

## Practice Exercises

Setup:
```bash
# Python
pip install openai python-dotenv

# Node.js
npm install openai
```

### Exercise 1: Single Tool Agent
Build an agent with one tool — a calculator. Ask it "What is 23 * 47 + 19?" Verify it calls the tool instead of guessing.

### Exercise 2: Weather + Reasoning
Build a weather agent. Ask "What's the weather in Paris, and should I wear a jacket?" Verify it calls the weather tool, then reasons about the jacket.

### Exercise 3: Multi-Tool Agent
Build an agent with three tools: calculator, web search (mock), and a knowledge base search. Ask questions that require different tools and verify it picks the right one each time.

### Exercise 4: Add Iteration Limits
Take your multi-tool agent and add a `MAX_ITERATIONS` cap. Create a query that would loop and verify the agent stops gracefully.

### Exercise 5: Manual ReAct
Implement the ReAct pattern manually (without function-calling API). Parse `Thought/Action/Observation` from the LLM's text output and feed observations back. Compare it to the function-calling approach.

### Exercise 6: RAG-Powered Agent
Combine Chapter 03 and 04: build an agent whose `search_docs` tool performs RAG retrieval. Ask questions that require looking up documents, then reasoning over them.

---

## Summary Table

| Concept | Simple Meaning | Key Detail |
|---------|---------------|------------|
| Agent | LLM that takes actions in a loop | Think → Act → Observe → Repeat |
| Tool | Function the LLM can call | Name + description + parameters |
| Function calling | LLM requests a tool call | LLM never runs code itself |
| ReAct | Reason + Act interleaved | Thought → Action → Observation |
| Iteration limit | Cap on loop count | Prevents runaway cost |
| Multi-agent | Specialized agents collaborate | Use only when needed |
| Human-in-the-loop | Approval for risky actions | Safety for irreversible ops |

---

## Key Takeaways

- **Agents = LLM + tools + a loop** — they reason, act, observe, and repeat
- **The LLM decides; your code executes** — function calling keeps you in control
- **ReAct interleaves reasoning and acting** — far more reliable than one-shot answers
- **Tool descriptions are critical** — the LLM picks tools based on them
- **Always cap iterations** — agents can loop forever and burn money
- **Handle tool errors as observations** — let the agent self-correct
- **Human-in-the-loop for dangerous actions** — never auto-run irreversible ops
- **Start with a single agent** — only go multi-agent when truly needed

---

## What's Next?

After completing this chapter:

**Move to Chapter 05 → LangChain, LangGraph & Agentic Frameworks**
- Use frameworks instead of building agent loops by hand
- Learn LangChain (chains, tools, memory) and LangGraph (stateful graphs)
- Build more robust, production-ready agents

**Don't move on until:**
- You've built a working tool-calling agent
- You understand the agent loop (Think → Act → Observe)
- You can explain ReAct in plain English
- You've added iteration limits and error handling
- You've completed at least 4 of the 6 exercises

---

**Time spent:** ___ hours | **Date completed:** ___
