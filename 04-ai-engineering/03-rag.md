# Chapter 03 — RAG (Retrieval-Augmented Generation)

How to make LLMs answer from YOUR data, reduce hallucinations, and stay up to date.  
**Time to complete:** 4–5 hours | **Exercises:** 6

---

## Navigation
← [Chapter 02: Embeddings & Vectors](./02-embeddings-vectors.md) | → [Chapter 04: Agents & Tools](./04-agents-and-tools.md)

---

## What is RAG?

**RAG = Retrieval-Augmented Generation**

**Simple meaning:** Instead of asking the LLM to answer from its training (which it might hallucinate), you first *retrieve* relevant documents from your own data, then give those documents to the LLM and ask it to answer based on them.

Think of it like an **open-book exam**:
- **Without RAG (closed book):** "What's our refund policy?" → LLM guesses from training → may be wrong
- **With RAG (open book):** "Here's our policy document [paste]. What's the refund policy?" → LLM reads and answers correctly

**The core problem RAG solves:**
- LLMs have a knowledge cutoff (they don't know recent events)
- LLMs don't know your private/company data
- LLMs hallucinate when uncertain

**The core insight:**
> Don't make the LLM *remember* facts. Make it *read* facts you provide, then reason over them.

---

## Why RAG Matters (The Business Case)

| Problem | Without RAG | With RAG |
|---------|-------------|----------|
| Private data | LLM doesn't know it | Retrieve and inject it |
| Fresh data | Stuck at training cutoff | Update documents anytime |
| Hallucinations | Confident wrong answers | Grounded in real docs |
| Citations | No source | Can cite exact documents |
| Cost | Fine-tuning is expensive | Just update a database |

**Key advantage over fine-tuning:** Updating knowledge is as easy as adding a document to a database — no model retraining required.

---

## The RAG Pipeline

There are two phases: **Indexing** (done once, offline) and **Retrieval + Generation** (done per query, online).

### Phase 1: Indexing (Offline / Preprocessing)
```
Raw Documents (PDFs, web pages, docs)
        ↓
   1. LOAD          → Read documents into text
        ↓
   2. CHUNK         → Split into smaller pieces
        ↓
   3. EMBED         → Convert each chunk to a vector
        ↓
   4. STORE         → Save vectors + text in vector DB
```

### Phase 2: Retrieval + Generation (Online / Per Query)
```
User Question
        ↓
   1. EMBED QUERY   → Convert question to a vector
        ↓
   2. SEARCH        → Find top K similar chunks in vector DB
        ↓
   3. AUGMENT       → Build prompt: context + question
        ↓
   4. GENERATE      → LLM answers using the context
        ↓
   Answer (with optional citations)
```

---

## Step 1: Loading Documents

Documents come from many sources: PDFs, websites, Markdown, databases, Notion, Confluence, etc.

**Common loaders:**
- **PDF:** `pdf-parse` (Node), `PyPDF2` / `pdfplumber` (Python)
- **Web:** `cheerio` (Node), `BeautifulSoup` (Python)
- **Markdown/Text:** Direct file reads
- **Frameworks:** LangChain has 100+ document loaders

**Goal:** Convert everything into plain text + metadata (source, page, date).

---

## Step 2: Chunking (The Most Underrated Step)

**Why chunk?**
- Embedding models have token limits (e.g., 8192 tokens)
- Smaller chunks = more precise retrieval
- LLM context windows are limited and expensive

**The chunking trade-off:**
```
Too small (50 chars)   → loses context, fragments meaning
Too large (5000 chars) → retrieves irrelevant info, wastes tokens
Just right (500-1000)  → captures complete thoughts
```

### Chunking Strategies

**1. Fixed-size chunking** (simplest)
```
Split every 500 characters, with 50-char overlap
```

**2. Sentence-based chunking**
```
Split on sentence boundaries (. ! ?)
```

**3. Paragraph-based chunking**
```
Split on double newlines (\n\n)
```

**4. Recursive chunking** (most common in production)
```
Try to split by paragraph, then sentence, then word
Keeps semantically related content together
```

**5. Semantic chunking** (advanced)
```
Use embeddings to detect topic shifts and split there
```

### Why Overlap Matters
```
Without overlap:
  Chunk 1: "...the refund policy allows returns"
  Chunk 2: "within 30 days of purchase..."
  → A query about "30 day returns" might miss the connection

With overlap (50 chars):
  Chunk 1: "...the refund policy allows returns within 30 days"
  Chunk 2: "returns within 30 days of purchase..."
  → Context preserved across boundaries
```

---

## Step 3 & 4: Embed and Store

This is covered in Chapter 02. Each chunk becomes a vector, stored in a vector database alongside its original text and metadata.

```
{
  id: "doc1_chunk3",
  vector: [0.1, 0.5, ...],   // 1536 numbers
  text: "The refund policy allows...",
  metadata: { source: "policy.pdf", page: 2, date: "2024-01-15" }
}
```

---

## Step 5: Retrieval

When a user asks a question:
1. Embed the question into a vector
2. Search the vector DB for the top K most similar chunks (K is usually 3-10)
3. Return those chunks

**Key parameter — `top_k`:**
```
top_k = 3   → fewer, more focused chunks (less context, cheaper)
top_k = 10  → more chunks (more context, may include noise)
```

**Gotcha:** Retrieving too many chunks can hurt — irrelevant context distracts the LLM and increases cost. Start with `top_k = 3-5`.

---

## Step 6: Augmentation & Generation

Build a prompt that includes the retrieved context and instructs the LLM to answer from it.

**The critical prompt pattern:**
```
You are a helpful assistant. Answer the question using ONLY the context below.
If the answer is not in the context, say "I don't have that information."

Context:
{retrieved_chunks}

Question: {user_question}

Answer:
```

**Why "ONLY the context" and "say I don't know" matters:**
- Prevents the LLM from falling back to (possibly wrong) training knowledge
- Reduces hallucinations dramatically
- Makes the system honest about gaps

---

## Code Examples

### Complete RAG Pipeline — Python (with Chroma)
```python
# pip install openai chromadb python-dotenv
from openai import OpenAI
import chromadb
from chromadb.utils import embedding_functions

client = OpenAI(api_key="YOUR_API_KEY")

# --- INDEXING PHASE ---

# 1. Setup vector DB with OpenAI embeddings
chroma_client = chromadb.Client()
openai_ef = embedding_functions.OpenAIEmbeddingFunction(
    api_key="YOUR_API_KEY",
    model_name="text-embedding-3-small"
)
collection = chroma_client.create_collection(
    name="knowledge_base",
    embedding_function=openai_ef
)

# 2. Chunking function
def chunk_text(text: str, chunk_size: int = 500, overlap: int = 50) -> list[str]:
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunks.append(text[start:end])
        start += chunk_size - overlap
    return chunks

# 3. Load and index documents
documents = {
    "policy.txt": "Our refund policy allows returns within 30 days of purchase. "
                  "Items must be unused and in original packaging. "
                  "Refunds are processed within 5-7 business days.",
    "shipping.txt": "We offer free shipping on orders over $50. "
                    "Standard delivery takes 3-5 business days. "
                    "Express shipping is available for $15.",
}

doc_id = 0
for source, text in documents.items():
    for chunk in chunk_text(text):
        collection.add(
            documents=[chunk],
            ids=[f"chunk_{doc_id}"],
            metadatas=[{"source": source}]
        )
        doc_id += 1

# --- RETRIEVAL + GENERATION PHASE ---

def rag_query(question: str, top_k: int = 3) -> str:
    # 1. Retrieve relevant chunks
    results = collection.query(query_texts=[question], n_results=top_k)
    retrieved_chunks = results["documents"][0]
    context = "\n\n".join(retrieved_chunks)

    # 2. Build augmented prompt
    prompt = f"""Answer the question using ONLY the context below.
If the answer is not in the context, say "I don't have that information."

Context:
{context}

Question: {question}

Answer:"""

    # 3. Generate
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        temperature=0,
        messages=[{"role": "user", "content": prompt}]
    )
    return response.choices[0].message.content

# Test
print(rag_query("How long do I have to return an item?"))
# → "You have 30 days to return an item..."

print(rag_query("What is the CEO's name?"))
# → "I don't have that information."
```

### Complete RAG Pipeline — TypeScript (in-memory)
```typescript
// npm install openai
import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

interface Chunk {
  id: string;
  text: string;
  source: string;
  embedding?: number[];
}

// --- Helpers ---

function chunkText(text: string, chunkSize = 500, overlap = 50): string[] {
  const chunks: string[] = [];
  let start = 0;
  while (start < text.length) {
    chunks.push(text.slice(start, start + chunkSize));
    start += chunkSize - overlap;
  }
  return chunks;
}

async function embed(text: string): Promise<number[]> {
  const res = await client.embeddings.create({
    model: "text-embedding-3-small",
    input: text,
  });
  return res.data[0].embedding;
}

function cosineSimilarity(a: number[], b: number[]): number {
  const dot = a.reduce((s, v, i) => s + v * b[i], 0);
  const magA = Math.sqrt(a.reduce((s, v) => s + v * v, 0));
  const magB = Math.sqrt(b.reduce((s, v) => s + v * v, 0));
  return dot / (magA * magB);
}

// --- INDEXING ---

const vectorStore: Chunk[] = [];

async function indexDocument(source: string, text: string) {
  const chunks = chunkText(text);
  for (let i = 0; i < chunks.length; i++) {
    const embedding = await embed(chunks[i]);
    vectorStore.push({
      id: `${source}_${i}`,
      text: chunks[i],
      source,
      embedding,
    });
  }
}

// --- RETRIEVAL + GENERATION ---

async function ragQuery(question: string, topK = 3): Promise<string> {
  // 1. Embed query
  const queryEmbedding = await embed(question);

  // 2. Retrieve top K
  const ranked = vectorStore
    .map((chunk) => ({
      chunk,
      score: cosineSimilarity(queryEmbedding, chunk.embedding!),
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, topK);

  const context = ranked.map((r) => r.chunk.text).join("\n\n");

  // 3. Augment + generate
  const prompt = `Answer the question using ONLY the context below.
If the answer is not in the context, say "I don't have that information."

Context:
${context}

Question: ${question}

Answer:`;

  const response = await client.chat.completions.create({
    model: "gpt-4o-mini",
    temperature: 0,
    messages: [{ role: "user", content: prompt }],
  });

  return response.choices[0].message.content ?? "";
}

// --- Usage ---
async function main() {
  await indexDocument(
    "policy",
    "Our refund policy allows returns within 30 days of purchase. " +
    "Items must be unused. Refunds process in 5-7 business days."
  );

  console.log(await ragQuery("How long for a refund?"));
}

main();
```

### RAG with Citations
```typescript
async function ragWithCitations(question: string, topK = 3) {
  const queryEmbedding = await embed(question);

  const ranked = vectorStore
    .map((chunk) => ({
      chunk,
      score: cosineSimilarity(queryEmbedding, chunk.embedding!),
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, topK);

  // Number each source for citation
  const context = ranked
    .map((r, i) => `[${i + 1}] (Source: ${r.chunk.source})\n${r.chunk.text}`)
    .join("\n\n");

  const prompt = `Answer using ONLY the context. Cite sources using [number].

Context:
${context}

Question: ${question}

Answer (with citations):`;

  const response = await client.chat.completions.create({
    model: "gpt-4o-mini",
    temperature: 0,
    messages: [{ role: "user", content: prompt }],
  });

  return {
    answer: response.choices[0].message.content,
    sources: ranked.map((r, i) => ({ id: i + 1, source: r.chunk.source, score: r.score })),
  };
}
```

---

## Advanced RAG Techniques

As you move to production, basic RAG often isn't enough. Here are the key upgrades.

### 1. Hybrid Search (Keyword + Semantic)
Pure vector search misses exact matches (product codes, names, acronyms). Combine:
- **Semantic search** (embeddings) → captures meaning
- **Keyword search** (BM25) → captures exact terms

```
Final score = (0.7 × semantic_score) + (0.3 × keyword_score)
```

### 2. Re-ranking
Retrieve a large set (e.g., top 20), then use a more powerful **cross-encoder** model to re-rank and keep only the best 3-5.
```
Vector search (fast, top 20) → Re-ranker (accurate, top 3) → LLM
```
Popular re-rankers: Cohere Rerank, `bge-reranker`.

### 3. Query Transformation
User queries are often vague. Improve them before searching:
- **Query expansion:** Add synonyms/related terms
- **HyDE (Hypothetical Document Embeddings):** Generate a hypothetical answer, embed *that*, and search with it
- **Multi-query:** Generate 3 variations of the question, search with all, merge results

### 4. Contextual / Metadata Filtering
Combine vector search with structured filters:
```typescript
await index.query({
  vector: queryEmbedding,
  filter: { department: "legal", date: { $gte: "2024-01-01" } },
  topK: 5,
});
```

### 5. Parent-Document Retrieval
Embed small chunks for precise matching, but return the larger parent document for richer context.

---

## Evaluating RAG Quality

You can't improve what you don't measure. RAG has two parts to evaluate:

### Retrieval Metrics
- **Context Precision:** Are the retrieved chunks relevant?
- **Context Recall:** Did we retrieve all the relevant chunks?
- **Hit Rate:** Was at least one correct chunk in the top K?
- **MRR (Mean Reciprocal Rank):** How high was the first correct chunk ranked?

### Generation Metrics
- **Faithfulness:** Is the answer grounded in the retrieved context (no hallucination)?
- **Answer Relevance:** Does the answer actually address the question?
- **Correctness:** Is the answer factually right?

**Popular tools:** RAGAS, TruLens, LangSmith, DeepEval. (More in Chapter 08.)

---

## Mental Models

### RAG = Open-Book Exam
The LLM is a smart student. Without RAG, it answers from memory (may be wrong). With RAG, you hand it the textbook and say "answer from this page." It does much better.

### Retrieval = Librarian, Generation = Writer
- The **retriever** is a librarian who fetches the right books.
- The **generator** (LLM) is a writer who reads those books and writes a clear answer.
- If the librarian fetches the wrong books, even the best writer fails. **Retrieval quality is everything.**

### Garbage In, Garbage Out
RAG output quality is capped by retrieval quality. Most RAG failures are *retrieval* failures, not generation failures. When debugging, always inspect the retrieved chunks first.

### Chunking = Cutting a Pizza
Too few large slices = hard to share precisely. Too many tiny slices = the toppings (context) get separated. You want slices big enough to hold a complete bite of meaning.

---

## Common Mistakes

### Mistake 1: Poor Chunking
❌ **Wrong:** Splitting mid-sentence or using huge 5000-char chunks
```
Chunk: "...the price is $99. The warranty cov"  ← cut off mid-word
```
✅ **Right:** Use recursive chunking with overlap, respect sentence boundaries

### Mistake 2: Not Telling the LLM to Stay Grounded
❌ **Wrong:**
```
"Here is some context: {context}. Question: {q}"
```
The LLM may still use training knowledge and hallucinate.

✅ **Right:**
```
"Answer using ONLY the context. If not in context, say 'I don't know'."
```

### Mistake 3: Retrieving Too Many or Too Few Chunks
❌ **Wrong:** `top_k = 50` → context overload, expensive, noisy
❌ **Wrong:** `top_k = 1` → might miss key info
✅ **Right:** Start with `top_k = 3-5`, tune based on evaluation

### Mistake 4: Ignoring Retrieval Quality
❌ **Wrong:** Blaming the LLM for bad answers when retrieval fetched wrong chunks
✅ **Right:** Always log and inspect retrieved chunks. Fix retrieval first.

### Mistake 5: Forgetting Metadata
❌ **Wrong:** Storing only text and vectors
✅ **Right:** Store source, date, author, page — essential for filtering and citations

### Mistake 6: Stale Index
❌ **Wrong:** Documents change but the vector DB is never updated
✅ **Right:** Build a re-indexing pipeline that updates vectors when source data changes

### Mistake 7: One-Size-Fits-All Chunk Size
❌ **Wrong:** Same chunk size for code, legal docs, and chat logs
✅ **Right:** Tune chunk size per content type (code by function, prose by paragraph)

---

## Interview Questions

### Q1: What is RAG and why is it better than fine-tuning for knowledge?
**Answer:** RAG (Retrieval-Augmented Generation) retrieves relevant documents from a knowledge base and injects them into the LLM's prompt so it answers from provided context rather than training memory. It's better than fine-tuning for knowledge tasks because: updating knowledge is as simple as adding/editing a document (no retraining); it provides citations and traceability; it dramatically reduces hallucinations by grounding answers; and it's far cheaper. Fine-tuning is better for teaching *behavior/style/format*, while RAG is better for injecting *facts/knowledge*.

### Q2: Walk me through a RAG pipeline.
**Answer:** There are two phases. **Indexing (offline):** load documents, chunk them into smaller pieces, embed each chunk into a vector, and store vectors + text + metadata in a vector database. **Query (online):** embed the user's question, search the vector DB for the top-K most similar chunks, build a prompt combining those chunks as context with the question, and instruct the LLM to answer using only that context. Optionally, add citations from the retrieved chunks' metadata.

### Q3: Why is chunking important and how do you choose chunk size?
**Answer:** Chunking matters because embedding models have token limits, smaller chunks give more precise retrieval, and context windows are limited and costly. The trade-off: too small loses context and fragments meaning; too large retrieves irrelevant info and wastes tokens. A common starting point is 500-1000 characters with ~10-15% overlap. Overlap preserves context across boundaries. The ideal size depends on content type — code is best chunked by function, prose by paragraph. You tune chunk size empirically using retrieval evaluation metrics.

### Q4: How do you reduce hallucinations in a RAG system?
**Answer:** Several techniques: (1) Prompt instruction — explicitly tell the LLM to answer ONLY from the provided context and to say "I don't know" if the answer isn't there. (2) Temperature 0 for factual grounding. (3) High-quality retrieval — most hallucinations come from retrieving wrong/insufficient chunks, so improving retrieval (re-ranking, hybrid search) helps. (4) Faithfulness checks — use another model to verify the answer is grounded in the context. (5) Citations — require the model to cite sources, which forces grounding.

### Q5: What is hybrid search and when do you need it?
**Answer:** Hybrid search combines semantic (vector/embedding) search with keyword (lexical/BM25) search. Pure semantic search captures meaning but can miss exact matches like product codes, names, acronyms, or rare technical terms. Keyword search nails exact matches but misses synonyms and paraphrasing. Combining them (typically a weighted score) gives the best of both. You need it when your data contains identifiers, jargon, or exact terms that users search for literally.

### Q6: How do you evaluate a RAG system?
**Answer:** Evaluate both components separately. **Retrieval:** context precision (are retrieved chunks relevant?), context recall (did we get all relevant chunks?), hit rate, and MRR. **Generation:** faithfulness (is the answer grounded in context, no hallucination?), answer relevance (does it address the question?), and correctness (is it factually right?). Tools like RAGAS, TruLens, and LangSmith automate these. The key debugging insight: most RAG failures are retrieval failures, so always inspect retrieved chunks first.

### Q7: What is re-ranking and why use it?
**Answer:** Re-ranking is a two-stage retrieval approach. First, use fast vector search to retrieve a large candidate set (e.g., top 20). Then use a more accurate but slower cross-encoder model to re-score and re-order those candidates, keeping only the best 3-5 for the LLM. Vector search (bi-encoder) is fast but less precise because query and document are embedded independently. A cross-encoder looks at the query and document together, giving much more accurate relevance scores. This improves answer quality without searching the entire database with the expensive model.

---

## Practice Exercises

Setup:
```bash
# Python
pip install openai chromadb python-dotenv pypdf

# Node.js
npm install openai
```

### Exercise 1: Basic RAG
Build a RAG system over 5 text documents about a topic you know well. Ask 5 questions — 3 answerable from the docs, 2 not. Verify it says "I don't know" for the unanswerable ones.

### Exercise 2: Chunking Comparison
Take one long document. Index it three ways: 200-char chunks, 500-char chunks, 1000-char chunks (all with overlap). Run the same 5 queries against each. Which chunk size retrieves the best context?

### Exercise 3: Add Citations
Extend your RAG system to include source citations. The answer should reference which document each fact came from.

### Exercise 4: Debug Bad Retrieval
Intentionally create a query that returns wrong chunks. Log the retrieved chunks and their similarity scores. Diagnose why retrieval failed (bad chunking? wrong embedding? ambiguous query?).

### Exercise 5: PDF RAG
Load a real PDF (a manual, paper, or report). Build a RAG system over it. Test with questions that require finding specific facts buried in the document.

### Exercise 6: Compare top_k Values
Run the same query with `top_k = 1, 3, 5, 10`. Compare answer quality, token usage, and cost. Find the sweet spot for your data.

---

## Summary Table

| Concept | Simple Meaning | Key Detail |
|---------|---------------|------------|
| RAG | Retrieve docs, then generate | Open-book exam for LLMs |
| Indexing | Offline prep of documents | Load → Chunk → Embed → Store |
| Chunking | Splitting documents | 500-1000 chars + overlap |
| top_k | Number of chunks retrieved | Start with 3-5 |
| Hybrid search | Semantic + keyword | Catches exact terms |
| Re-ranking | Two-stage retrieval | Fast retrieve, accurate re-sort |
| Faithfulness | Answer grounded in context | Key anti-hallucination metric |

---

## Key Takeaways

- **RAG grounds LLMs in your data** — answers from retrieved context, not training memory
- **Two phases:** indexing (offline) and retrieval+generation (online)
- **Chunking quality is critical** — too small loses context, too large adds noise
- **Always instruct the LLM to stay grounded** — "use ONLY the context, say I don't know"
- **Retrieval quality caps everything** — most RAG failures are retrieval failures
- **Advanced techniques** (hybrid search, re-ranking, query transformation) matter in production
- **Evaluate both retrieval and generation** — use RAGAS, TruLens, or LangSmith
- **RAG beats fine-tuning for knowledge** — update a document, not the whole model

---

## What's Next?

After completing this chapter:

**Move to Chapter 04 → Agents, Tool Use & ReAct Pattern**
- Give LLMs the ability to take actions (call APIs, run code, search)
- Learn the ReAct pattern (Reason + Act)
- Build agents that can use RAG as one of many tools

**Don't move on until:**
- You've built a working RAG pipeline end-to-end
- You understand the indexing vs query phases
- You can explain why chunking and retrieval quality matter
- You've debugged a bad retrieval case
- You've completed at least 4 of the 6 exercises

---

**Time spent:** ___ hours | **Date completed:** ___
