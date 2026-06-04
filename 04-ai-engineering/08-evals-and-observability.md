# Chapter 08 — Evals, Tracing & Observability

How to measure whether your AI system actually works — and debug it when it doesn't.  
**Time to complete:** 4–5 hours | **Exercises:** 6

---

## Navigation
← [Chapter 07: Memory & State](./07-memory-and-state.md) | → [Chapter 09: Production AI Systems](./09-production-ai-systems.md)

---

## Why Evals Matter

In traditional software, you write tests: given input X, expect output Y. With LLMs, outputs are **non-deterministic** and **open-ended** — there's often no single "correct" answer. So how do you know if your system works?

**Evals (evaluations)** are how you measure LLM output quality systematically.

```
Without evals:
  "It seems to work?" → ship → users find it broken ❌

With evals:
  Run 100 test cases → measure quality → catch regressions → ship with confidence ✅
```

**The core problem evals solve:**
> You can't improve what you can't measure. And you can't safely change a prompt or model without evals to catch regressions.

---

## The Eval Mindset

Treat your AI system like any other engineering artifact: **measure, don't guess.**

- Changed a prompt? Run evals to confirm it didn't break anything.
- Switched models (gpt-4o → gpt-4o-mini)? Evals tell you if quality dropped.
- Added RAG? Evals tell you if retrieval actually helps.

**Evals are the regression tests of AI engineering.**

---

## Types of Evaluation

```
┌──────────────────────────────────────────────────┐
│ 1. REFERENCE-BASED   compare to a "golden" answer  │
│ 2. REFERENCE-FREE    judge quality without answer  │
│ 3. HUMAN EVAL        humans rate outputs            │
│ 4. LLM-AS-JUDGE      an LLM grades outputs          │
└──────────────────────────────────────────────────┘
```

### 1. Reference-Based (Ground Truth)
You have the expected answer and compare against it.
- **Exact match** — output equals expected (good for classification)
- **Similarity** — semantic similarity to expected (embeddings)
- **Metrics** — BLEU, ROUGE (for translation/summarization)

### 2. Reference-Free
No golden answer; judge intrinsic quality.
- Is it grounded in the provided context? (faithfulness)
- Is it relevant to the question?
- Is it coherent and well-formatted?

### 3. Human Evaluation
Humans rate outputs (thumbs up/down, 1-5 scale). The gold standard for quality, but slow and expensive. Use for calibration and high-stakes decisions.

### 4. LLM-as-Judge
Use a (usually stronger) LLM to grade outputs against criteria. Scalable and surprisingly effective. The workhorse of modern AI evals.

---

## LLM-as-Judge (The Key Technique)

You use an LLM to evaluate another LLM's output against criteria you define.

```
Input → Your LLM → Output
                      ↓
         Judge LLM evaluates:
         "Is this answer faithful to the context?
          Rate 1-5 and explain."
                      ↓
              Score + reasoning
```

**Example judge prompt:**
```
You are an evaluator. Rate the answer's faithfulness to the context.

Context: {context}
Question: {question}
Answer: {answer}

Score 1-5 where:
5 = fully grounded in context, no made-up info
1 = contradicts or ignores the context

Output JSON: { "score": number, "reasoning": string }
```

**Best practices for LLM-as-judge:**
- Use a strong model as the judge (e.g., gpt-4o)
- Give clear scoring rubrics with examples
- Ask for reasoning *before* the score (chain-of-thought)
- Use structured output for parseable scores
- Validate the judge against human ratings periodically

---

## Eval Metrics by Use Case

### Classification / Extraction
- **Accuracy** — % correct
- **Precision / Recall / F1** — for imbalanced classes
- **Exact match** — output matches expected exactly

### RAG (from Chapter 03)
- **Context Precision/Recall** — retrieval quality
- **Faithfulness** — answer grounded in context
- **Answer Relevance** — answer addresses the question

### Summarization
- **ROUGE** — overlap with reference summary
- **Faithfulness** — no hallucinated facts
- **Conciseness** — appropriate length

### Agents (from Chapter 04)
- **Task success rate** — did it complete the task?
- **Tool-call accuracy** — correct tools, correct args
- **Steps/efficiency** — how many iterations
- **Cost per task**

### General Generation
- **Relevance, coherence, helpfulness, safety** (usually via LLM-as-judge or human eval)

---

## Code Examples

### Simple Eval Harness — Python
```python
from openai import OpenAI
client = OpenAI(api_key="YOUR_API_KEY")

# 1. Define a golden dataset
test_cases = [
    {"input": "I love this!", "expected": "positive"},
    {"input": "Awful, broke immediately.", "expected": "negative"},
    {"input": "It's fine I guess.", "expected": "neutral"},
]

# 2. The system under test
def classify(text: str) -> str:
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        temperature=0,
        messages=[
            {"role": "system", "content":
                "Classify sentiment as exactly one word: "
                "positive, negative, or neutral."},
            {"role": "user", "content": text},
        ],
    )
    return response.choices[0].message.content.strip().lower()

# 3. Run the eval
def run_eval():
    correct = 0
    for case in test_cases:
        result = classify(case["input"])
        passed = result == case["expected"]
        correct += passed
        print(f"{'✅' if passed else '❌'} '{case['input']}' "
              f"→ {result} (expected {case['expected']})")
    accuracy = correct / len(test_cases)
    print(f"\nAccuracy: {accuracy:.0%} ({correct}/{len(test_cases)})")

run_eval()
```

### LLM-as-Judge — Python
```python
from pydantic import BaseModel

class Judgment(BaseModel):
    reasoning: str
    score: int  # 1-5

def judge_faithfulness(context: str, question: str, answer: str) -> Judgment:
    response = client.beta.chat.completions.parse(
        model="gpt-4o",  # strong model as judge
        messages=[
            {"role": "system", "content":
                "You are a strict evaluator. Rate how faithful the answer "
                "is to the provided context on a scale of 1-5. "
                "5 = fully grounded, 1 = contradicts/ignores context. "
                "Give reasoning before the score."},
            {"role": "user", "content":
                f"Context: {context}\n\nQuestion: {question}\n\nAnswer: {answer}"},
        ],
        response_format=Judgment,
    )
    return response.choices[0].message.parsed

# Usage
result = judge_faithfulness(
    context="The refund window is 30 days.",
    question="How long do I have to return?",
    answer="You have 30 days to return an item.",
)
print(f"Score: {result.score}/5 — {result.reasoning}")
```

### Semantic Similarity Eval — Python
```python
import numpy as np

def get_embedding(text: str) -> list[float]:
    return client.embeddings.create(
        model="text-embedding-3-small", input=text
    ).data[0].embedding

def cosine(a, b):
    a, b = np.array(a), np.array(b)
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

def similarity_eval(output: str, expected: str, threshold: float = 0.85) -> bool:
    sim = cosine(get_embedding(output), get_embedding(expected))
    print(f"Similarity: {sim:.3f}")
    return sim >= threshold

# Use when outputs can be phrased differently but mean the same
similarity_eval(
    output="You can return items within a month.",
    expected="Returns are accepted for 30 days.",
)
```

### Eval Suite with pytest — Python
```python
# pip install pytest
import pytest

CASES = [
    ("I love it", "positive"),
    ("Terrible", "negative"),
]

@pytest.mark.parametrize("text,expected", CASES)
def test_classification(text, expected):
    assert classify(text) == expected

# Run: pytest test_evals.py
# Treats LLM behavior like regression tests
```

---

## Tracing & Observability

Evals tell you *if* something is wrong. **Tracing** tells you *why*. In production, an LLM app is a pipeline of steps — you need visibility into each one.

```
User Query
   ↓  [trace: input, tokens]
Embed Query
   ↓  [trace: embedding time]
Vector Search
   ↓  [trace: retrieved chunks, scores]
Build Prompt
   ↓  [trace: final prompt, token count]
LLM Call
   ↓  [trace: model, latency, tokens, cost]
Response
   ↓  [trace: output, eval score]
```

### What to Trace
- **Inputs/outputs** at each step
- **Latency** per step and total
- **Token usage and cost** per call
- **Retrieved documents** (for RAG debugging)
- **Tool calls and results** (for agents)
- **Errors and retries**
- **Eval scores** (online evaluation)

### Why It Matters
When a user reports "the bot gave a wrong answer," tracing lets you see:
- Was retrieval wrong? (bad chunks)
- Was the prompt wrong? (bad formatting)
- Was the model wrong? (hallucination despite good context)

Without tracing, you're debugging blind.

---

## Observability Tools

| Tool | Strength |
|------|----------|
| **LangSmith** | Tracing + evals, tight LangChain integration |
| **LangFuse** | Open-source tracing, evals, prompt management |
| **Phoenix (Arize)** | Open-source LLM observability + evals |
| **Helicone** | Proxy-based logging, cost tracking |
| **Weights & Biases** | Experiment tracking, evals |
| **RAGAS** | RAG-specific evaluation metrics |
| **DeepEval** | Pytest-style LLM evals |
| **TruLens** | Evaluation + feedback functions |

**Most provide:** request logging, latency/cost dashboards, trace visualization, dataset management, and eval pipelines.

---

## Building an Eval Dataset

Good evals need good test data.

### Sources
- **Real production data** — best signal (anonymize PII!)
- **Hand-crafted edge cases** — tricky inputs you want to handle
- **Synthetic data** — LLM-generated test cases for coverage
- **User feedback** — thumbs down examples become test cases

### Structure
```json
[
  {
    "input": "How long for a refund?",
    "expected": "30 days",
    "context": "Refunds within 30 days...",
    "metadata": { "category": "policy", "difficulty": "easy" }
  }
]
```

### Tips
- Start small (20-50 cases) and grow over time
- Include edge cases and failure modes, not just happy paths
- Version your eval dataset alongside your code
- Add a case every time you find a bug (regression test)

---

## Online vs Offline Evaluation

### Offline (Pre-Deployment)
Run evals against a fixed dataset before shipping. Catches regressions. Fast feedback loop during development.

### Online (Production)
Evaluate real traffic in production:
- **Sampling** — evaluate a % of live requests with LLM-as-judge
- **User feedback** — thumbs up/down, explicit ratings
- **Implicit signals** — did the user rephrase? abandon? retry?
- **A/B testing** — compare two prompts/models on live traffic

Both are needed: offline for confidence before shipping, online for catching real-world issues.

---

## Mental Models

### Evals = Unit Tests for AI
Just as you wouldn't ship code without tests, you shouldn't ship prompts without evals. They catch regressions when you change prompts, models, or logic.

### LLM-as-Judge = Automated Grader
Like having a TA grade essays against a rubric. Not perfect, but scalable and consistent — and calibrated against human graders periodically.

### Tracing = Flight Recorder
When something goes wrong, the trace is the black box that shows exactly what happened at each step, so you can find the root cause instead of guessing.

### Eval Dataset = Growing Immune System
Every bug you find becomes a test case. Over time your eval set "remembers" past failures and prevents them from recurring.

---

## Common Mistakes

### Mistake 1: No Evals at All
❌ "It looks good" → ship → silent regressions
✅ Build an eval set early, run it on every change

### Mistake 2: Only Testing Happy Paths
❌ Evals only cover easy, expected inputs
✅ Include edge cases, adversarial inputs, and known failure modes

### Mistake 3: Trusting LLM-as-Judge Blindly
❌ Assuming the judge is always right
✅ Calibrate the judge against human ratings; use clear rubrics

### Mistake 4: No Tracing in Production
❌ Can't debug user-reported issues
✅ Trace inputs, outputs, retrievals, tokens, cost at each step

### Mistake 5: Ignoring Cost and Latency in Evals
❌ Only measuring quality, not cost/speed
✅ Track quality AND cost AND latency — they're all production concerns

### Mistake 6: Static Eval Dataset
❌ Eval set never grows; misses new failure modes
✅ Add every production bug as a new test case

### Mistake 7: Exact Match for Open-Ended Output
❌ Requiring exact string match on generative answers
✅ Use semantic similarity or LLM-as-judge for open-ended outputs

---

## Interview Questions

### Q1: How do you evaluate an LLM application when there's no single correct answer?
**Answer:** Since outputs are non-deterministic and open-ended, you use a mix of evaluation methods. For tasks with ground truth (classification, extraction), use reference-based metrics like accuracy or semantic similarity. For open-ended outputs, use reference-free methods: LLM-as-judge to score qualities like faithfulness, relevance, and coherence against a rubric; human evaluation for high-stakes calibration; and implicit signals from production (user feedback, rephrasing). The key is building a representative eval dataset and measuring systematically rather than eyeballing outputs.

### Q2: What is LLM-as-judge and what are its limitations?
**Answer:** LLM-as-judge uses a (usually stronger) LLM to evaluate another model's output against defined criteria, like rating faithfulness 1-5. It's scalable, consistent, and effective for open-ended tasks where exact match fails. Best practices: use a strong judge model, provide clear rubrics with examples, ask for reasoning before the score, and use structured output. Limitations: judges can be biased (e.g., preferring longer or more verbose answers, position bias, self-preference for their own outputs), and they can make mistakes. So you should calibrate the judge against human ratings periodically and not trust it blindly.

### Q3: Why are evals important when changing a prompt or model?
**Answer:** Because LLM behavior is sensitive and non-deterministic, a small prompt tweak or a model swap (e.g., gpt-4o to gpt-4o-mini for cost savings) can silently degrade quality or break edge cases. Evals act as regression tests: you run the new prompt/model against your eval dataset and compare scores before and after. This lets you make changes with confidence, quantify trade-offs (e.g., "mini is 90% as accurate at 1/10th the cost"), and catch regressions before they reach users. Without evals, you're guessing.

### Q4: What is the difference between offline and online evaluation?
**Answer:** Offline evaluation runs against a fixed dataset before deployment — it catches regressions and gives a fast feedback loop during development. Online evaluation assesses real production traffic: sampling live requests for LLM-as-judge scoring, collecting user feedback (thumbs up/down), tracking implicit signals (rephrasing, abandonment), and A/B testing prompts or models. Offline gives confidence before shipping; online catches real-world issues and distribution shifts that offline data misses. Production systems need both.

### Q5: What would you trace in a RAG application and why?
**Answer:** I'd trace each pipeline step: the user query and its tokens; the query embedding and timing; the retrieved chunks with their similarity scores and sources; the final assembled prompt and its token count; the LLM call's model, latency, tokens, and cost; and the final response with any eval score. This matters because when an answer is wrong, the trace reveals the root cause — whether retrieval fetched the wrong chunks, the prompt was malformed, or the model hallucinated despite good context. Most RAG failures are retrieval failures, so seeing the retrieved chunks is especially valuable for debugging.

### Q6: How do you build a good eval dataset?
**Answer:** Start small (20-50 cases) and grow it. Source cases from real production data (anonymized), hand-crafted edge cases, synthetic LLM-generated examples for coverage, and user feedback (thumbs-down examples). Each case should include the input, expected output (when available), any needed context, and metadata like category and difficulty. Crucially, include edge cases and known failure modes, not just happy paths, and add a new test case every time you find a bug so it becomes a regression test. Version the dataset alongside your code so evals evolve with the system.

---

## Practice Exercises

Setup:
```bash
# Python
pip install openai pydantic numpy pytest python-dotenv
```

### Exercise 1: Build an Eval Harness
Create a golden dataset of 10 classification cases. Write a harness that runs your classifier and reports accuracy. Identify which cases fail.

### Exercise 2: LLM-as-Judge
Build an LLM-as-judge that scores answer faithfulness 1-5. Test it on 5 answers (some grounded, some hallucinated). Does it score correctly?

### Exercise 3: Compare Two Models
Run the same eval dataset against gpt-4o and gpt-4o-mini. Compare accuracy, cost, and latency. Which would you ship and why?

### Exercise 4: Semantic Similarity Eval
Build an eval that uses embedding similarity instead of exact match. Test it on paraphrased answers that mean the same thing.

### Exercise 5: Add Tracing
Add logging/tracing to a RAG pipeline (from Chapter 03). Log retrieved chunks, prompt, tokens, and latency for each query. Use it to debug a deliberately bad query.

### Exercise 6: Regression Test Suite
Build a pytest-based eval suite. Add a case, watch it pass. Then break your prompt and verify the test catches the regression.

---

## Summary Table

| Concept | Simple Meaning | Key Detail |
|---------|---------------|------------|
| Eval | Measuring output quality | Regression tests for AI |
| Reference-based | Compare to golden answer | Accuracy, similarity |
| Reference-free | Judge intrinsic quality | Faithfulness, relevance |
| LLM-as-judge | LLM grades output | Scalable, needs calibration |
| Tracing | Visibility into each step | Find root cause |
| Offline eval | Test before shipping | Catch regressions |
| Online eval | Evaluate live traffic | Sampling, feedback, A/B |

---

## Key Takeaways

- **You can't improve what you can't measure** — evals are essential, not optional
- **Evals are regression tests for AI** — run them on every prompt/model change
- **Use multiple eval types** — reference-based, reference-free, human, LLM-as-judge
- **LLM-as-judge is scalable** — but calibrate it against humans and watch for bias
- **Tracing tells you WHY** — log inputs, outputs, retrievals, tokens, and cost per step
- **Track quality AND cost AND latency** — all are production concerns
- **Grow your eval dataset over time** — every bug becomes a regression test
- **Use both offline and online evaluation** — confidence before shipping, monitoring after

---

## What's Next?

After completing this chapter:

**Move to Chapter 09 → Production AI Systems**
- Cost optimization, latency reduction, and caching
- Guardrails, rate limiting, and reliability
- Deploying AI systems that scale safely

**Don't move on until:**
- You've built an eval harness and an LLM-as-judge
- You've compared two models on cost/quality/latency
- You've added tracing to a pipeline
- You understand offline vs online evaluation
- You've completed at least 4 of the 6 exercises

---

**Time spent:** ___ hours | **Date completed:** ___
