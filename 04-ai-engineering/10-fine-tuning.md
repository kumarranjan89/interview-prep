# Chapter 10 — Fine-Tuning: When & How

When to actually train a model, when NOT to, and how fine-tuning really works.  
**Time to complete:** 3–4 hours | **Exercises:** 5

---

## Navigation
← [Chapter 09: Production AI Systems](./09-production-ai-systems.md) | → [Chapter 11: AI + Frontend](./11-frontend-ai.md)

---

## What is Fine-Tuning?

**Simple meaning:** Fine-tuning takes a pre-trained model and trains it further on your own examples, so it learns a specific *behavior*, *style*, or *format*.

Recall from Chapter 01 — training has stages:
```
Pretraining → Fine-tuning (RLHF) → YOU USE IT (API)
```
Fine-tuning lets you add a small, custom training step on top of an existing model — without the millions of dollars of pretraining.

```
Base model (general) + Your examples → Fine-tuned model (specialized)
```

**Key insight:**
> Fine-tuning teaches the model HOW to behave, not WHAT facts to know. For facts/knowledge, use RAG (Chapter 03).

---

## The Most Important Lesson: Usually, Don't

This is the #1 thing interviewers want to hear. **Fine-tuning is rarely the first answer.**

```
Decision order (try in this sequence):
  1. Prompt engineering   → cheapest, fastest (Chapter 06)
  2. Few-shot examples    → show the pattern in the prompt
  3. RAG                  → for knowledge/facts (Chapter 03)
  4. Fine-tuning          → only if the above aren't enough
```

**Why fine-tuning is a last resort:**
- Expensive (data prep + training + hosting)
- Slow to iterate (retrain for every change)
- Needs lots of quality data (100s-1000s of examples)
- Can become outdated (knowledge is frozen at training time)
- Hard to debug

---

## When TO Fine-Tune

Fine-tuning makes sense for:

### 1. Consistent Style / Tone / Format
You need outputs in a very specific voice or structure that's hard to achieve with prompting alone.
```
e.g., always respond in your company's exact brand voice,
or always output a specific complex JSON structure reliably
```

### 2. Specialized Tasks
A narrow, repetitive task where you have lots of examples.
```
e.g., classifying support tickets into 50 internal categories
```

### 3. Cost/Latency Reduction
A fine-tuned *small* model can match a large model on a narrow task — cheaper and faster. You "bake in" the behavior so you don't need long prompts.
```
Long few-shot prompt on gpt-4o
  → fine-tuned gpt-4o-mini with no examples needed
  → cheaper + faster, same quality on that task
```

### 4. Teaching a Skill the Model Lacks
Domain-specific behaviors, structured reasoning patterns, or formats not well-represented in training.

---

## When NOT to Fine-Tune

```
❌ To add facts/knowledge        → use RAG instead
❌ For frequently changing info  → use RAG (retrain is too slow)
❌ When you have little data      → use few-shot prompting
❌ When prompting already works   → don't add complexity
❌ For a one-off task             → not worth the effort
```

**Critical distinction:**
```
Q: "Should I fine-tune so the model knows our 2025 product catalog?"
A: No — use RAG. Catalogs change; fine-tuning bakes in stale data.

Q: "Should I fine-tune so the model always replies in our support tone?"
A: Maybe — if prompting can't achieve the consistency you need.
```

---

## Types of Fine-Tuning

### 1. Full Fine-Tuning
Update *all* model weights. Most powerful, but expensive and requires significant compute. Rare outside large orgs.

### 2. PEFT (Parameter-Efficient Fine-Tuning)
Update only a small subset of parameters. Much cheaper, nearly as effective. The practical choice.

### 3. LoRA (Low-Rank Adaptation)
The most popular PEFT method. Adds small "adapter" matrices to the model instead of changing original weights.
```
Original weights (frozen) + small LoRA adapters (trained) = specialized model
```
- Tiny files (MBs vs GBs)
- Fast and cheap to train
- Can swap adapters for different tasks

### 4. QLoRA
LoRA + quantization (compressing weights to lower precision). Lets you fine-tune large models on a single consumer GPU.

### 5. Instruction Tuning / RLHF
Training on instruction-response pairs (instruction tuning) or with human preference feedback (RLHF). This is how base models become helpful assistants — usually done by model providers, not you.

---

## How Fine-Tuning Works (The Process)

```
1. COLLECT DATA      → gather input-output examples
        ↓
2. FORMAT DATA       → into the required structure (e.g., JSONL)
        ↓
3. SPLIT             → training set + validation set
        ↓
4. TRAIN             → upload data, run fine-tuning job
        ↓
5. EVALUATE          → test on held-out data (Chapter 08!)
        ↓
6. DEPLOY            → use the fine-tuned model via API
        ↓
7. ITERATE           → add data, retrain if needed
```

**Data is everything.** Quality and quantity of examples determine success far more than hyperparameters.

---

## Data Preparation

### Format (OpenAI Chat Fine-Tuning — JSONL)
Each line is a complete conversation example:
```jsonl
{"messages": [{"role": "system", "content": "You are a support bot."}, {"role": "user", "content": "How do I reset my password?"}, {"role": "assistant", "content": "Go to Settings > Security > Reset Password."}]}
{"messages": [{"role": "system", "content": "You are a support bot."}, {"role": "user", "content": "I was charged twice."}, {"role": "assistant", "content": "I'm sorry! I've flagged this for a refund review..."}]}
```

### Data Guidelines
- **Quantity:** Start with 50-100 high-quality examples; more for complex tasks
- **Quality > quantity:** A few hundred great examples beat thousands of noisy ones
- **Consistency:** Examples should reflect exactly the behavior you want
- **Diversity:** Cover the range of inputs you'll see in production
- **Match production:** Format examples like real usage (same system prompt)

---

## Code Examples

### Fine-Tuning Job — Python (OpenAI)
```python
from openai import OpenAI
client = OpenAI(api_key="YOUR_API_KEY")

# 1. Upload your training data file (JSONL)
training_file = client.files.create(
    file=open("training_data.jsonl", "rb"),
    purpose="fine-tune",
)

# 2. Create the fine-tuning job
job = client.fine_tuning.jobs.create(
    training_file=training_file.id,
    model="gpt-4o-mini-2024-07-18",  # base model to fine-tune
    # Optional: validation file, hyperparameters
)
print(f"Job started: {job.id}")

# 3. Check status (training takes minutes to hours)
status = client.fine_tuning.jobs.retrieve(job.id)
print(f"Status: {status.status}")

# 4. Once complete, use the fine-tuned model
# (job.fine_tuned_model gives the model name)
response = client.chat.completions.create(
    model="ft:gpt-4o-mini-2024-07-18:your-org::abc123",  # your fine-tuned model
    messages=[
        {"role": "system", "content": "You are a support bot."},
        {"role": "user", "content": "How do I reset my password?"},
    ],
)
print(response.choices[0].message.content)
```

### Preparing & Validating Data — Python
```python
import json

def validate_training_data(filepath: str):
    errors = []
    with open(filepath) as f:
        for i, line in enumerate(f, 1):
            try:
                example = json.loads(line)
                messages = example.get("messages", [])
                if not messages:
                    errors.append(f"Line {i}: no messages")
                # Must end with an assistant message
                if messages[-1]["role"] != "assistant":
                    errors.append(f"Line {i}: must end with assistant")
                # Validate roles
                for m in messages:
                    if m["role"] not in ("system", "user", "assistant"):
                        errors.append(f"Line {i}: bad role {m['role']}")
            except json.JSONDecodeError:
                errors.append(f"Line {i}: invalid JSON")

    if errors:
        print("❌ Validation errors:")
        for e in errors:
            print(f"  {e}")
    else:
        print("✅ Data is valid")

validate_training_data("training_data.jsonl")
```

### LoRA Fine-Tuning (Open Source) — Python Sketch
```python
# pip install transformers peft datasets trl
# Conceptual example fine-tuning an open model with LoRA
from peft import LoraConfig
from trl import SFTTrainer
from transformers import AutoModelForCausalLM, AutoTokenizer

model_name = "meta-llama/Llama-3.2-1B"
model = AutoModelForCausalLM.from_pretrained(model_name)
tokenizer = AutoTokenizer.from_pretrained(model_name)

# LoRA config — only train small adapters
lora_config = LoraConfig(
    r=8,                    # rank (size of adapter)
    lora_alpha=16,
    target_modules=["q_proj", "v_proj"],  # which layers to adapt
    lora_dropout=0.05,
)

trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=your_dataset,   # formatted examples
    peft_config=lora_config,
)

trainer.train()
trainer.save_model("./my-lora-adapter")  # tiny adapter file
```

---

## Evaluating a Fine-Tuned Model

Fine-tuning without evaluation is flying blind. Use everything from Chapter 08:

- **Hold out a test set** the model never saw during training
- **Compare against the base model** — did fine-tuning actually help?
- **Compare against prompting/RAG** — was fine-tuning even necessary?
- **Watch for overfitting** — great on training data, poor on new data
- **Measure cost/latency** — did a fine-tuned small model meet your goals?

```
Base gpt-4o-mini:        72% accuracy on task
Fine-tuned gpt-4o-mini:  91% accuracy on task  ✅ worth it
```

---

## Fine-Tuning vs RAG vs Prompting (The Decision Table)

| Need | Best Approach |
|------|---------------|
| Add up-to-date facts/knowledge | **RAG** |
| Frequently changing data | **RAG** |
| Simple task, works with instructions | **Prompting** |
| Need a few examples to show pattern | **Few-shot prompting** |
| Consistent style/tone/format | **Fine-tuning** |
| Narrow repetitive task, lots of data | **Fine-tuning** |
| Reduce cost/latency on a specific task | **Fine-tuning (small model)** |
| Knowledge + behavior | **RAG + Fine-tuning (combined)** |

**They're not mutually exclusive** — you can fine-tune a model for behavior AND use RAG for knowledge together.

---

## Mental Models

### Fine-Tuning = Specialized Training for an Employee
A new hire (base model) is generally capable. Fine-tuning is on-the-job training that teaches them *your* company's specific procedures and style. RAG is giving them a reference manual to look things up.

### RAG vs Fine-Tuning = Open Book vs Studying
RAG is an open-book exam — facts are provided at query time. Fine-tuning is studying beforehand to internalize *skills and style*. You study skills; you look up facts.

### LoRA = Sticky Notes on a Textbook
Instead of rewriting the whole textbook (full fine-tuning), you add sticky notes (small adapters) that adjust how it's used. Cheap, removable, swappable.

### Fine-Tuning = Baking, Prompting = Seasoning
Prompting seasons each dish at serving time (flexible, per-request). Fine-tuning bakes the flavor into the recipe (permanent, consistent). You bake in stable behaviors; you season variable ones.

---

## Common Mistakes

### Mistake 1: Fine-Tuning to Add Knowledge
❌ Fine-tuning to teach facts that change → stale, expensive
✅ Use RAG for knowledge; fine-tune only for behavior/style

### Mistake 2: Fine-Tuning Before Trying Prompting/RAG
❌ Jumping to fine-tuning first
✅ Exhaust prompting → few-shot → RAG before fine-tuning

### Mistake 3: Too Little or Low-Quality Data
❌ 10 inconsistent examples → poor results
✅ 50-100+ high-quality, consistent examples

### Mistake 4: No Held-Out Evaluation
❌ Can't tell if fine-tuning helped or overfit
✅ Always evaluate on a test set the model never saw

### Mistake 5: Inconsistent Training Data
❌ Examples that contradict each other → confused model
✅ Ensure examples consistently reflect the desired behavior

### Mistake 6: Not Comparing to Alternatives
❌ Fine-tuning without checking if RAG/prompting was enough
✅ Benchmark fine-tuning against simpler approaches first

### Mistake 7: Forgetting Data Changes
❌ Fine-tuning on data that goes out of date
✅ Only bake in stable behaviors; keep volatile info in RAG

---

## Interview Questions

### Q1: When should you fine-tune vs use RAG vs prompt engineering?
**Answer:** Follow an escalation order. Start with prompt engineering — it's cheapest and fastest. Add few-shot examples if you need to demonstrate a pattern. Use RAG when you need to inject knowledge or facts, especially changing ones, since you can update documents without retraining. Reserve fine-tuning for when you need consistent style/tone/format that prompting can't achieve, for narrow repetitive tasks with lots of training data, or to reduce cost/latency by baking behavior into a smaller model. The key distinction: RAG is for knowledge/facts, fine-tuning is for behavior/style. They can also be combined.

### Q2: Why is fine-tuning usually NOT the right answer for adding knowledge?
**Answer:** Fine-tuning teaches behavior and patterns, not reliable factual recall, and it bakes information in at training time. If you fine-tune to add facts, that knowledge becomes frozen and goes stale as data changes, requiring expensive retraining to update. It's also prone to hallucination since the model blends learned patterns rather than reciting exact facts. RAG is far better for knowledge: you store facts in a retrievable store, update them anytime by editing documents, and the model answers from the provided context with citations. So for facts — especially changing ones — use RAG; reserve fine-tuning for stable behaviors.

### Q3: What is LoRA and why is it popular?
**Answer:** LoRA (Low-Rank Adaptation) is a parameter-efficient fine-tuning method. Instead of updating all the model's weights (expensive, large), it freezes the original weights and trains small low-rank "adapter" matrices that adjust the model's behavior. It's popular because it's dramatically cheaper and faster to train, produces tiny adapter files (megabytes vs gigabytes), lets you swap different adapters for different tasks on the same base model, and achieves quality close to full fine-tuning. QLoRA extends it with quantization so you can even fine-tune large models on a single consumer GPU.

### Q4: How do you prepare data for fine-tuning?
**Answer:** Collect input-output examples that exactly reflect the behavior you want, then format them into the required structure — for OpenAI, JSONL where each line is a full conversation with system/user/assistant messages ending in an assistant response. Guidelines: prioritize quality over quantity (a few hundred excellent examples beat thousands of noisy ones); ensure consistency so examples don't contradict each other; include diversity to cover the range of production inputs; match the production format (same system prompt); and split off a validation/test set for evaluation. Validate the data programmatically before training to catch formatting errors.

### Q5: How do you know if fine-tuning was successful?
**Answer:** Evaluate on a held-out test set the model never saw during training, using the eval techniques from observability work — accuracy, LLM-as-judge, task success, etc. Compare three things: the fine-tuned model vs the base model (did it actually improve?), vs simpler approaches like prompting/RAG (was fine-tuning necessary?), and check for overfitting (strong on training data but weak on new inputs signals memorization). Also measure cost and latency, since a common goal is matching a large model's quality with a cheaper fine-tuned small model. Success means a meaningful, generalizable improvement that justifies the added complexity.

### Q6: Can you combine fine-tuning and RAG?
**Answer:** Yes, and it's often the best approach for complex applications. You fine-tune the model to internalize behavior, style, tone, or output format — for example, your company's brand voice or a specific structured response format — and you use RAG to supply current, factual knowledge at query time. This separates concerns cleanly: fine-tuning handles the stable "how to respond," RAG handles the changing "what to respond with." For instance, a customer-support assistant could be fine-tuned to match your support tone and JSON output schema, while RAG retrieves the latest policy and product details.

---

## Practice Exercises

Setup:
```bash
# Python
pip install openai python-dotenv

# For open-source LoRA (optional, needs GPU)
pip install transformers peft datasets trl
```

### Exercise 1: Decision Practice
For 5 scenarios (e.g., "always reply in legal tone", "answer about today's stock price", "classify tickets"), decide: prompting, RAG, or fine-tuning? Justify each.

### Exercise 2: Build a Dataset
Create a 20-example JSONL dataset for a specific behavior (e.g., a bot that always replies in haiku). Validate it with a script.

### Exercise 3: Run a Fine-Tuning Job
Fine-tune gpt-4o-mini on your dataset from Exercise 2. Compare its output to the base model with the same prompt.

### Exercise 4: Evaluate
Build a held-out test set. Measure your fine-tuned model vs the base model. Did fine-tuning help? Is there overfitting?

### Exercise 5: Compare Approaches
Take one task and solve it three ways: prompting, few-shot, and fine-tuning. Compare quality, cost, and effort. Which would you choose in production?

---

## Summary Table

| Concept | Simple Meaning | Key Detail |
|---------|---------------|------------|
| Fine-tuning | Train a model on your examples | Teaches behavior, not facts |
| When to use | Style/format/narrow task | Last resort after prompting/RAG |
| When NOT to | Adding/changing knowledge | Use RAG instead |
| Full fine-tuning | Update all weights | Expensive, rare |
| LoRA | Small trainable adapters | Cheap, swappable, popular |
| QLoRA | LoRA + quantization | Fine-tune big models on 1 GPU |
| Data | Input-output examples | Quality > quantity |

---

## Key Takeaways

- **Fine-tuning teaches behavior/style, not facts** — use RAG for knowledge
- **Usually, don't fine-tune** — try prompting → few-shot → RAG first
- **Fine-tune for consistent style/format, narrow tasks, or cost/latency reduction**
- **Data quality is everything** — consistent, high-quality examples matter most
- **LoRA/QLoRA make fine-tuning cheap** — small adapters instead of full retraining
- **Always evaluate on held-out data** — compare to base model and simpler approaches
- **Never fine-tune changing knowledge** — it goes stale; use RAG
- **Combine fine-tuning + RAG** — behavior from one, facts from the other

---

## What's Next?

After completing this chapter:

**Move to Chapter 11 → AI + Frontend: Your Superpower**
- Build AI-powered user interfaces (your comfort zone)
- Streaming UIs, chat interfaces, and generative UI
- Vercel AI SDK, React, and real-time AI experiences

**Don't move on until:**
- You can decide between prompting, RAG, and fine-tuning for any scenario
- You've prepared and validated a fine-tuning dataset
- You understand LoRA and why it's popular
- You know how to evaluate a fine-tuned model
- You've completed at least 3 of the 5 exercises

---

**Time spent:** ___ hours | **Date completed:** ___
