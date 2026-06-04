# Chapter 05 — LangChain, LangGraph & Agentic Frameworks

How to stop building agent loops by hand and use battle-tested frameworks for production.  
**Time to complete:** 4–5 hours | **Exercises:** 6

---

## Navigation
← [Chapter 04: Agents & Tools](./04-agents-and-tools.md) | → [Chapter 06: Prompt Engineering](./06-prompt-engineering.md)

---

## Why Use a Framework?

In Chapter 04, you built agent loops by hand. That's great for learning, but production systems need more: memory, streaming, retries, tracing, state management, and integrations with dozens of tools and databases.

**Frameworks give you:**
- **Pre-built components** — LLM wrappers, memory, tools, retrievers
- **Composability** — chain steps together cleanly
- **Integrations** — 100s of vector DBs, APIs, model providers
- **Observability** — tracing and debugging out of the box
- **State management** — for complex multi-step agents

**The trade-off:**
> Frameworks save time but add abstraction. Sometimes a raw API call is simpler than fighting a framework. Use them when complexity justifies them.

---

## The Major Frameworks

| Framework | Best For | Style |
|-----------|----------|-------|
| **LangChain** | General-purpose chains, RAG, tools | Composable components |
| **LangGraph** | Stateful, cyclic, complex agents | Graph of nodes/edges |
| **LlamaIndex** | Data-heavy RAG, indexing | Data-first |
| **CrewAI** | Multi-agent collaboration | Role-based crews |
| **AutoGen** | Multi-agent conversations | Conversational agents |
| **Vercel AI SDK** | Frontend/TypeScript AI apps | Streaming-first, React |

We'll focus on **LangChain** and **LangGraph** (the most common in interviews), with notes on others.

---

## LangChain Core Concepts

### 1. Models
Wrappers around LLM providers (OpenAI, Anthropic, etc.) with a unified interface.
```python
from langchain_openai import ChatOpenAI
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
```

### 2. Prompts (Prompt Templates)
Reusable, parameterized prompts.
```python
from langchain_core.prompts import ChatPromptTemplate
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful {role}."),
    ("user", "{question}"),
])
```

### 3. Output Parsers
Convert raw LLM text into structured data (JSON, lists, objects).

### 4. Chains (LCEL — LangChain Expression Language)
Compose components with the pipe (`|`) operator.
```python
chain = prompt | llm | output_parser
result = chain.invoke({"role": "tutor", "question": "What is RAG?"})
```

### 5. Retrievers
Wrap vector stores for RAG (ties directly to Chapter 03).

### 6. Memory
Persist conversation history across calls.

### 7. Tools & Agents
Pre-built tool integrations and agent executors (the loop from Chapter 04, but managed).

---

## LCEL — The Pipe Pattern

LangChain Expression Language (LCEL) lets you compose components like Unix pipes. Data flows left to right.

```
Input → Prompt → LLM → Parser → Output
```

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_template("Explain {topic} in one sentence.")
llm = ChatOpenAI(model="gpt-4o-mini")
parser = StrOutputParser()

# Compose with pipes
chain = prompt | llm | parser

print(chain.invoke({"topic": "embeddings"}))
```

**Why LCEL is powerful:** chains get streaming, async, batching, and retries for free.

---

## Code Examples

### Simple Chain — Python
```python
# pip install langchain langchain-openai
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a concise technical writer."),
    ("user", "Summarize this in 2 sentences: {text}"),
])

chain = prompt | llm | StrOutputParser()

summary = chain.invoke({"text": "Large language models predict the next token..."})
print(summary)
```

### RAG Chain — Python (ties to Chapter 03)
```python
# pip install langchain langchain-openai langchain-chroma
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_chroma import Chroma
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough

# 1. Setup vector store with documents
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = Chroma.from_texts(
    texts=[
        "Our refund policy allows returns within 30 days.",
        "Free shipping on orders over $50.",
        "Support is available 24/7 via chat.",
    ],
    embedding=embeddings,
)
retriever = vectorstore.as_retriever(search_kwargs={"k": 2})

# 2. RAG prompt
prompt = ChatPromptTemplate.from_template("""
Answer using ONLY the context. If not in context, say "I don't know".

Context: {context}
Question: {question}
""")

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

def format_docs(docs):
    return "\n\n".join(d.page_content for d in docs)

# 3. Compose the RAG chain with LCEL
rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | llm
    | StrOutputParser()
)

print(rag_chain.invoke("How long do I have to return something?"))
# → "You have 30 days to return an item."
```

### Agent with Tools — Python
```python
# pip install langchain langchain-openai
from langchain_openai import ChatOpenAI
from langchain.agents import create_tool_calling_agent, AgentExecutor
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.tools import tool

# 1. Define tools with the @tool decorator
@tool
def get_weather(city: str) -> str:
    """Get the current weather for a city."""
    data = {"Tokyo": "18°C, rainy", "Paris": "22°C, sunny"}
    return data.get(city, "Unknown city")

@tool
def calculate(expression: str) -> str:
    """Evaluate a math expression like '2 + 2'."""
    return str(eval(expression))  # use a safe parser in production

tools = [get_weather, calculate]

# 2. Create the agent
llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)
prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a helpful assistant with tools."),
    ("human", "{input}"),
    ("placeholder", "{agent_scratchpad}"),  # where reasoning steps go
])

agent = create_tool_calling_agent(llm, tools, prompt)
executor = AgentExecutor(agent=agent, tools=tools, verbose=True, max_iterations=5)

# 3. Run it
result = executor.invoke({"input": "What's the weather in Tokyo? Also, what is 15 * 4?"})
print(result["output"])
```

### Conversation with Memory — Python
```python
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage

llm = ChatOpenAI(model="gpt-4o-mini")

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a friendly tutor."),
    MessagesPlaceholder(variable_name="history"),
    ("human", "{input}"),
])

chain = prompt | llm

history = []

def chat(message: str) -> str:
    response = chain.invoke({"history": history, "input": message})
    history.append(HumanMessage(content=message))
    history.append(AIMessage(content=response.content))
    return response.content

print(chat("My name is Rahul."))
print(chat("What's my name?"))  # → "Your name is Rahul."
```

### TypeScript — LangChain.js
```typescript
// npm install langchain @langchain/openai @langchain/core
import { ChatOpenAI } from "@langchain/openai";
import { ChatPromptTemplate } from "@langchain/core/prompts";
import { StringOutputParser } from "@langchain/core/output_parsers";

const llm = new ChatOpenAI({ model: "gpt-4o-mini", temperature: 0 });

const prompt = ChatPromptTemplate.fromMessages([
  ["system", "You are a concise assistant."],
  ["user", "Explain {topic} in one sentence."],
]);

const chain = prompt.pipe(llm).pipe(new StringOutputParser());

const result = await chain.invoke({ topic: "vector databases" });
console.log(result);
```

---

## LangGraph — Stateful, Cyclic Agents

LangChain chains are mostly linear (A → B → C). But real agents need **loops, branches, and state** — that's what **LangGraph** provides.

**LangGraph models your agent as a graph:**
- **Nodes** = steps (call LLM, call tool, decide)
- **Edges** = transitions between steps (can be conditional)
- **State** = shared data passed between nodes

```
        ┌─────────┐
        │  START  │
        └────┬────┘
             ↓
       ┌──────────┐
       │  agent   │◄─────────┐
       │ (LLM)    │          │
       └────┬─────┘          │
            ↓                │
      ┌───────────┐          │
      │ needs tool?│         │
      └─┬───────┬─┘          │
   yes  │       │  no        │
        ↓       ↓            │
   ┌────────┐  ┌─────┐       │
   │ tools  │  │ END │       │
   └───┬────┘  └─────┘       │
       └────────────────────┘
       (loop back with result)
```

### LangGraph Example — Python
```python
# pip install langgraph langchain-openai
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from langchain_openai import ChatOpenAI
from langchain_core.tools import tool
from langchain_core.messages import HumanMessage
from typing import TypedDict, Annotated
import operator

# 1. Define the tool
@tool
def get_weather(city: str) -> str:
    """Get weather for a city."""
    return {"Tokyo": "18°C, rainy"}.get(city, "Unknown")

tools = [get_weather]
llm = ChatOpenAI(model="gpt-4o-mini").bind_tools(tools)

# 2. Define shared state
class State(TypedDict):
    messages: Annotated[list, operator.add]

# 3. Define nodes
def call_model(state: State):
    response = llm.invoke(state["messages"])
    return {"messages": [response]}

# 4. Conditional edge: continue to tools or end?
def should_continue(state: State):
    last = state["messages"][-1]
    return "tools" if last.tool_calls else END

# 5. Build the graph
workflow = StateGraph(State)
workflow.add_node("agent", call_model)
workflow.add_node("tools", ToolNode(tools))
workflow.set_entry_point("agent")
workflow.add_conditional_edges("agent", should_continue)
workflow.add_edge("tools", "agent")  # loop back after tool

app = workflow.compile()

# 6. Run it
result = app.invoke({"messages": [HumanMessage(content="Weather in Tokyo?")]})
print(result["messages"][-1].content)
```

**Why LangGraph over plain LangChain agents:**
- Explicit control over the loop and branching
- Persistent state (can pause/resume, add human-in-the-loop)
- Better for complex, multi-step, cyclic workflows
- Easier to debug and visualize

---

## Other Frameworks (Brief)

### LlamaIndex
Data-first framework optimized for RAG and indexing. Great when your app is heavily data/retrieval-centric. Strong document loaders and index structures.

### CrewAI
Role-based multi-agent framework. You define agents with roles (researcher, writer) and they collaborate as a "crew." Good for structured multi-agent tasks.

### AutoGen (Microsoft)
Multi-agent conversational framework. Agents talk to each other to solve problems. Strong for complex collaborative reasoning.

### Vercel AI SDK
TypeScript-first, streaming-focused. Best for building AI features into web apps (React/Next.js). Ties directly to Chapter 11 (Frontend AI).

---

## When NOT to Use a Framework

Frameworks add abstraction and dependencies. Sometimes raw API calls are better:

- **Simple, single-step tasks** — a direct API call is clearer
- **Maximum control needed** — frameworks hide details you may need
- **Minimal dependencies** — avoid bloat for tiny projects
- **Debugging is hard** — framework abstractions can obscure what's happening

**Rule of thumb:** Prototype with raw API calls to understand the flow, then adopt a framework when complexity (memory, tools, RAG, state) justifies it.

---

## Mental Models

### LangChain = Lego Blocks
Each component (model, prompt, retriever, parser) is a block. LCEL is how you snap them together. You build complex apps from simple, reusable pieces.

### LCEL Pipe = Assembly Line
Data enters one end and flows through each station (prompt → LLM → parser), getting transformed at each step, until the finished product comes out the other end.

### LangGraph = Flowchart with Memory
A regular chain is a straight line. LangGraph is a flowchart — it can branch, loop back, and remember state along the way. Use it when your agent needs to make decisions and repeat steps.

### Framework = Power Tools
You *can* build a house with hand tools (raw API), but power tools (frameworks) are faster for big projects. For hanging one picture (simple task), grabbing the power drill is overkill.

---

## Common Mistakes

### Mistake 1: Using a Framework for Everything
❌ Wrapping a single API call in 5 layers of LangChain abstraction
✅ Use raw calls for simple tasks; frameworks for complex ones

### Mistake 2: Not Understanding What's Under the Hood
❌ Treating the framework as magic, can't debug when it breaks
✅ Learn the raw API first (Chapters 1-4) so you understand what the framework does

### Mistake 3: Ignoring Version Churn
❌ LangChain APIs change frequently; copying old tutorials breaks
✅ Always check the current docs and pin dependency versions

### Mistake 4: Using Chains for Cyclic Workflows
❌ Forcing loops/branches into a linear chain
✅ Use LangGraph for stateful, cyclic, branching agents

### Mistake 5: No Iteration/Recursion Limit
❌ LangGraph agent loops forever
✅ Set `recursion_limit` / `max_iterations` (same lesson as Chapter 04)

### Mistake 6: Skipping Observability
❌ No tracing, can't see why the agent did something
✅ Use LangSmith or similar (Chapter 08) to trace every step

---

## Interview Questions

### Q1: Why use a framework like LangChain instead of raw API calls?
**Answer:** Frameworks provide pre-built, composable components (models, prompts, retrievers, memory, tools), integrations with hundreds of providers and vector databases, and built-in features like streaming, retries, batching, and observability. They speed up development of complex applications like RAG systems and agents. The trade-off is added abstraction and dependency churn. For simple, single-step tasks, raw API calls are often clearer; frameworks pay off when you need memory, tool orchestration, RAG, or stateful workflows.

### Q2: What is LCEL and why is it useful?
**Answer:** LCEL (LangChain Expression Language) is a declarative way to compose components using the pipe operator, like `prompt | llm | parser`. Data flows left to right through each component. It's useful because any chain built with LCEL automatically gets streaming, async execution, batching, and retry support for free, and the composition is readable and reusable. It's essentially a functional pipeline pattern applied to LLM workflows.

### Q3: What is the difference between LangChain and LangGraph?
**Answer:** LangChain chains are primarily linear pipelines (A → B → C) — great for straightforward flows like RAG. LangGraph models an application as a graph of nodes and edges with shared state, supporting loops, conditional branching, and persistence. You use LangGraph when your agent needs to make decisions, repeat steps (cyclic behavior), maintain and update state across steps, or support human-in-the-loop with pause/resume. In short: LangChain for linear flows, LangGraph for stateful, cyclic, branching agents.

### Q4: How does LangGraph model an agent?
**Answer:** LangGraph represents an agent as a state graph. Nodes are steps (e.g., call the LLM, execute a tool, make a decision). Edges define transitions and can be conditional (e.g., "if the LLM requested a tool, go to the tools node; otherwise end"). A shared state object is passed between nodes and updated at each step. This makes loops explicit — for example, after running a tool, the graph loops back to the agent node with the result, repeating until the LLM produces a final answer with no tool calls.

### Q5: When would you NOT use a framework?
**Answer:** Avoid frameworks for simple, single-step tasks where a raw API call is clearer and has fewer dependencies; when you need maximum control over the exact requests and behavior; for very small projects where framework bloat isn't justified; or when debugging is critical and the framework's abstractions would obscure what's happening. A good practice is to prototype with raw API calls to understand the flow, then adopt a framework once complexity (memory, tools, RAG, state) justifies it.

### Q6: Name some agentic frameworks and their strengths.
**Answer:** LangChain — general-purpose composable chains, RAG, and tools. LangGraph — stateful, cyclic, complex agents with explicit control. LlamaIndex — data-first, optimized for RAG and indexing. CrewAI — role-based multi-agent collaboration. AutoGen — multi-agent conversational problem solving. Vercel AI SDK — TypeScript/streaming-first for building AI features into web frontends. The choice depends on the task: data-heavy RAG favors LlamaIndex, multi-agent favors CrewAI/AutoGen, complex stateful single agents favor LangGraph, and frontend apps favor the Vercel AI SDK.

---

## Practice Exercises

Setup:
```bash
# Python
pip install langchain langchain-openai langchain-chroma langgraph python-dotenv

# Node.js
npm install langchain @langchain/openai @langchain/core
```

### Exercise 1: First Chain
Build a simple LCEL chain: prompt → LLM → parser. Make it translate any input text to French.

### Exercise 2: RAG Chain
Rebuild your Chapter 03 RAG system using LangChain's retriever and LCEL. Compare the code length to your hand-built version.

### Exercise 3: Tool-Calling Agent
Build a LangChain agent with two tools (calculator + a mock search). Verify it picks the right tool for different questions.

### Exercise 4: Conversation Memory
Build a chatbot with memory using `MessagesPlaceholder`. Tell it your name, then ask it back several turns later.

### Exercise 5: LangGraph Agent
Build the LangGraph weather agent from this chapter. Add a second tool and a conditional edge. Visualize the graph.

### Exercise 6: Framework vs Raw
Take a task you built with raw API calls in Chapter 04 and rebuild it with LangChain. Write down which approach you preferred and why.

---

## Summary Table

| Concept | Simple Meaning | Key Detail |
|---------|---------------|------------|
| Framework | Pre-built AI building blocks | Saves time, adds abstraction |
| LangChain | Composable component library | Models, prompts, retrievers, tools |
| LCEL | Pipe-based composition | `prompt \| llm \| parser` |
| Retriever | RAG component wrapper | Ties to Chapter 03 |
| LangGraph | Stateful graph of agent steps | Loops, branches, state |
| Node / Edge | Step / transition | Edges can be conditional |
| State | Shared data between nodes | Enables memory & resume |

---

## Key Takeaways

- **Frameworks speed up complex AI apps** — but understand raw APIs first
- **LangChain = composable Lego blocks** — models, prompts, retrievers, tools, memory
- **LCEL pipes components together** — gets streaming, async, retries for free
- **LangGraph adds loops, branches, and state** — for complex cyclic agents
- **Linear flow → LangChain; cyclic/stateful → LangGraph**
- **Many frameworks exist** — pick based on the task (RAG, multi-agent, frontend)
- **Don't over-abstract** — raw calls are sometimes simpler and clearer
- **Always cap iterations and add observability** — same lessons as earlier chapters

---

## What's Next?

After completing this chapter:

**Move to Chapter 06 → Prompt Engineering & Structured Output**
- Master the techniques that make LLMs reliable
- Learn few-shot, chain-of-thought, and structured output (JSON schemas)
- Get consistent, parseable results from any model

**Don't move on until:**
- You've built a chain with LCEL
- You've built a RAG chain and a tool-calling agent with a framework
- You can explain the difference between LangChain and LangGraph
- You've built a LangGraph agent with a conditional edge
- You've completed at least 4 of the 6 exercises

---

**Time spent:** ___ hours | **Date completed:** ___
