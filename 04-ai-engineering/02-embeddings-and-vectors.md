# Chapter 02 — Embeddings & Vector Databases

How LLMs understand meaning, and how to store/retrieve that meaning efficiently.  
**Time to complete:** 3–4 hours | **Exercises:** 5

---

## Navigation
← [Chapter 01: LLM Fundamentals](./01-llm-fundamentals.md) | → [Chapter 03: RAG](./03-rag.md)

---

## What is an Embedding?

**Simple meaning:** An embedding is a list of numbers (a vector) that represents the "meaning" of a piece of text (or image, audio, etc.) in a way that computers can understand and compare.

Think of it like:
- Words with similar meanings have similar number lists.
- Words with very different meanings have very different number lists.

**Example:**
```
"King"   → [0.1, 0.3, 0.5, ..., 0.9]
"Queen"  → [0.1, 0.3, 0.4, ..., 0.8]  (very similar to King)
"Apple"  → [0.8, 0.2, 0.1, ..., 0.0]  (very different)
```

**Key properties:**
- **High-dimensional:** Typically 100s or 1000s of numbers (e.g., OpenAI's `text-embedding-3-small` uses 1536 dimensions).
- **Dense:** All numbers are usually non-zero.
- **Contextual:** The embedding for "bank" will be different in "river bank" vs. "money bank".

**Why this matters for you as an engineer:**
Embeddings are the bridge between human language and machine understanding. They enable:
- **Semantic search:** Find documents based on meaning, not just keywords.
- **Recommendations:** Suggest similar items.
- **Classification:** Group similar texts together.
- **Anomaly detection:** Find unusual text patterns.

---

## How Embeddings Are Created

LLMs (specifically, their internal layers) are used to create embeddings. When an LLM processes text, it converts words into these numerical representations. An embedding model is a specialized LLM designed to output these vectors.

**The process:**
1. **Text input:** "The quick brown fox"
2. **Tokenization:** Converts text into tokens (numbers).
3. **Embedding model:** Processes tokens through its layers.
4. **Output:** A single vector (list of numbers) representing the entire text's meaning.

The "meaning" is learned during pre-training, where the model tries to predict missing words or the next word. This forces the model to create rich internal representations of words and sentences.

---

## Measuring Similarity: Cosine Similarity

How do we compare two embeddings (vectors) to see how similar their meanings are? We use a metric called **cosine similarity**.

- Cosine similarity ranges from -1 to 1.
- **1:** Exactly the same meaning (vectors point in the same direction).
- **0:** No semantic relationship (vectors are orthogonal).
- **-1:** Exactly opposite meaning (vectors point in opposite directions – rare with text embeddings).

**Visual intuition:** Imagine two arrows (vectors) in a multi-dimensional space. Cosine similarity measures the cosine of the angle between them. A smaller angle means higher similarity.

**Why not Euclidean distance?**
While Euclidean distance measures the "straight-line" distance between two points, cosine similarity focuses on the *orientation* of the vectors. For high-dimensional data like embeddings, cosine similarity often better captures semantic similarity, as it's less sensitive to the magnitude of the vectors.

---

## Vector Databases

**Simple meaning:** A specialized database designed to store, index, and query high-dimensional vectors (embeddings) efficiently.

**Why do we need them?**
If you have millions or billions of embeddings, a traditional database (like PostgreSQL or MongoDB) isn't optimized for finding the "nearest neighbors" (most similar vectors) quickly. Vector databases use special indexing algorithms (like Annoy, Faiss, HNSW) to perform Approximate Nearest Neighbor (ANN) search.

**Key features of a Vector Database:**
- **Stores vectors:** Along with optional metadata.
- **Indexes vectors:** For fast similarity search.
- **Queries by similarity:** "Find the 10 most similar documents to this query."
- **Scales to millions:** Efficiently handles large datasets.
- **Supports filtering:** Combine similarity search with metadata filters (e.g., "similar documents from 2023").

**Popular Vector Databases:**
- **Pinecone:** Managed, cloud-native, easy to start.
- **Weaviate:** Open-source, GraphQL API, hybrid search.
- **Chroma:** Open-source, simple Python API, great for prototyping.
- **Qdrant:** Open-source, high performance, filter support.
- **pgvector:** PostgreSQL extension, use if you already use Postgres.

---

## The RAG Pattern (Preview)

**RAG = Retrieval-Augmented Generation**

This is the most important pattern in AI engineering. It combines:
1. **Retrieval:** Use vector search to find relevant documents.
2. **Augmentation:** Add those documents to your prompt.
3. **Generation:** Ask the LLM to answer using only those documents.

**Why this matters:**
- **Reduces hallucinations:** LLM answers from provided context, not from training.
- **Keeps knowledge fresh:** Update documents without retraining the model.
- **Domain-specific:** Add your company's private data to any LLM.

**Simple flow:**
```
User Question: "What's our refund policy?"
         ↓
Embed the question → [0.2, 0.5, 0.1, ...]
         ↓
Vector DB search → Top 5 similar documents
         ↓
Add to prompt: "Based on these documents [paste], answer: What's our refund policy?"
         ↓
LLM generates answer from documents
```

Full details in Chapter 03.

---

## Popular Embedding Models

**OpenAI Models:**
- `text-embedding-3-small`: 1536 dimensions, fast, cheap (~$0.02/1M tokens)
- `text-embedding-3-large`: 3072 dimensions, higher quality (~$0.13/1M tokens)
- `text-embedding-ada-002`: Older, 1536 dimensions, being phased out

**Open Source Models:**
- `all-MiniLM-L6-v2`: 384 dimensions, very fast, runs locally
- `sentence-transformers/all-mpnet-base-v2`: 768 dimensions, good quality
- `BAAI/bge-large-en-v1.5`: 1024 dimensions, state-of-the-art open source

**Choosing a model:**
- **Start with:** OpenAI `text-embedding-3-small` (easy, good quality)
- **For cost-sensitive:** `all-MiniLM-L6-v2` (free, runs locally)
- **For best quality:** `text-embedding-3-large` or `bge-large-en-v1.5`

---

## Code Examples

### Basic Embedding — Python
```python
# pip install openai python-dotenv
from openai import OpenAI
import numpy as np

client = OpenAI(api_key="YOUR_API_KEY")

def get_embedding(text: str) -> list[float]:
    response = client.embeddings.create(
        model="text-embedding-3-small",
        input=text
    )
    return response.data[0].embedding

# Get embeddings
embedding1 = get_embedding("The cat sat on the mat")
embedding2 = get_embedding("A feline rested on a rug")

print(f"Dimensions: {len(embedding1)}")  # 1536

# Calculate cosine similarity
def cosine_similarity(a: list[float], b: list[float]) -> float:
    a_np = np.array(a)
    b_np = np.array(b)
    return np.dot(a_np, b_np) / (np.linalg.norm(a_np) * np.linalg.norm(b_np))

similarity = cosine_similarity(embedding1, embedding2)
print(f"Similarity: {similarity:.4f}")  # Should be high (similar meaning)
```

### Basic Embedding — TypeScript
```typescript
// npm install openai
import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function getEmbedding(text: string): Promise<number[]> {
  const response = await client.embeddings.create({
    model: "text-embedding-3-small",
    input: text,
  });
  return response.data[0].embedding;
}

function cosineSimilarity(a: number[], b: number[]): number {
  const dotProduct = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magnitudeA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magnitudeB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
  return dotProduct / (magnitudeA * magnitudeB);
}

// Usage
async function main() {
  const emb1 = await getEmbedding("The cat sat on the mat");
  const emb2 = await getEmbedding("A feline rested on a rug");

  console.log(`Dimensions: ${emb1.length}`);  // 1536
  console.log(`Similarity: ${cosineSimilarity(emb1, emb2).toFixed(4)}`);
}

main();
```

### Vector Database with Chroma (Python)
```python
# pip install chromadb
import chromadb
from chromadb.utils import embedding_functions

# Initialize Chroma (local, in-memory for demo)
client = chromadb.Client()

# Use OpenAI embeddings
openai_ef = embedding_functions.OpenAIEmbeddingFunction(
    api_key="YOUR_API_KEY",
    model_name="text-embedding-3-small"
)

# Create a collection
collection = client.create_collection(
    name="documents",
    embedding_function=openai_ef
)

# Add documents
documents = [
    "Our refund policy allows returns within 30 days of purchase.",
    "We offer free shipping on orders over $50.",
    "Customer support is available 24/7 via chat and email.",
    "All products come with a 1-year warranty.",
]

collection.add(
    documents=documents,
    ids=["doc1", "doc2", "doc3", "doc4"],
    metadatas=[
        {"category": "policy", "date": "2024-01-01"},
        {"category": "shipping", "date": "2024-01-01"},
        {"category": "support", "date": "2024-01-01"},
        {"category": "warranty", "date": "2024-01-01"},
    ]
)

# Query
results = collection.query(
    query_texts=["Can I return this item?"],
    n_results=2
)

print("Most similar documents:")
for doc, dist in zip(results["documents"][0], results["distances"][0]):
    print(f"  {doc} (distance: {dist:.4f})")
```

### Vector Database with Pinecone (TypeScript)
```typescript
// npm install @pinecone-database/pinecone
import { Pinecone } from '@pinecone-database/pinecone';
import OpenAI from 'openai';

const pinecone = new Pinecone({ apiKey: process.env.PINECONE_API_KEY! });
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY! });

async function getEmbedding(text: string): Promise<number[]> {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: text,
  });
  return response.data[0].embedding;
}

async function main() {
  // Initialize index
  const index = pinecone.index('documents');

  // Upsert documents
  const documents = [
    { id: 'doc1', text: 'Our refund policy allows returns within 30 days.' },
    { id: 'doc2', text: 'We offer free shipping on orders over $50.' },
    { id: 'doc3', text: 'Customer support is available 24/7.' },
  ];

  for (const doc of documents) {
    const embedding = await getEmbedding(doc.text);
    await index.upsert([{
      id: doc.id,
      values: embedding,
      metadata: { text: doc.text },
    }]);
  }

  // Query
  const queryEmbedding = await getEmbedding('Can I return this?');
  const results = await index.query({
    vector: queryEmbedding,
    topK: 2,
    includeMetadata: true,
  });

  console.log('Most similar documents:');
  for (const match of results.matches || []) {
    console.log(`  ${match.metadata?.text} (score: ${match.score?.toFixed(4)})`);
  }
}

main();
```

### Simple Semantic Search
```typescript
import OpenAI from "openai";

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

interface Document {
  id: string;
  text: string;
  embedding?: number[];
}

async function embedDocuments(docs: Document[]): Promise<Document[]> {
  for (const doc of docs) {
    const response = await client.embeddings.create({
      model: "text-embedding-3-small",
      input: doc.text,
    });
    doc.embedding = response.data[0].embedding;
  }
  return docs;
}

function cosineSimilarity(a: number[], b: number[]): number {
  const dotProduct = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magnitudeA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magnitudeB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
  return dotProduct / (magnitudeA * magnitudeB);
}

async function semanticSearch(
  documents: Document[],
  query: string,
  topK: number = 3
): Promise<{ doc: Document; score: number }[]> {
  // Embed the query
  const queryResponse = await client.embeddings.create({
    model: "text-embedding-3-small",
    input: query,
  });
  const queryEmbedding = queryResponse.data[0].embedding;

  // Calculate similarities
  const results = documents
    .map((doc) => ({
      doc,
      score: cosineSimilarity(queryEmbedding, doc.embedding!),
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, topK);

  return results;
}

// Usage
async function main() {
  const documents = await embedDocuments([
    { id: "1", text: "TypeScript is a typed superset of JavaScript." },
    { id: "2", text: "Python is known for its simplicity and readability." },
    { id: "3", text: "Rust is a systems programming language focused on safety." },
    { id: "4", text: "JavaScript is the language of the web." },
  ]);

  const results = await semanticSearch(documents, "web development language");
  console.log("Results for 'web development language':");
  for (const { doc, score } of results) {
    console.log(`  ${doc.text} (score: ${score.toFixed(4)})`);
  }
}

main();
```

---

## Mental Models

### Embedding = Geographic Coordinates
Think of embeddings like latitude/longitude on a map:
- "Paris" and "London" are close (similar: European capitals)
- "Paris" and "Antarctica" are far apart (different: city vs continent)
- But in 1536 dimensions, not 2

### Vector Database = Specialized Search Engine
Traditional search: Match keywords exactly
- Query: "cat" → finds documents containing "cat"
- Query: "feline" → finds documents containing "feline"
- These are separate results, even though they mean the same thing

Vector search: Match meaning
- Query: "cat" → finds documents about cats, felines, kittens, pets
- All grouped by semantic similarity, not keyword matching

### Cosine Similarity = Angle, Not Distance
Two vectors can be far apart in space (large Euclidean distance) but point in the same direction (high cosine similarity). For semantic meaning, direction matters more than magnitude.

### High-Dimensional Space = Rich Representation
In 2D, you can only represent two independent concepts (e.g., x=size, y=color). In 1536D, you can represent 1536 independent aspects of meaning (tone, topic, sentiment, formality, domain, etc.).

---

## Common Mistakes

### Mistake 1: Using Keyword Search for Semantic Problems
❌ **Wrong approach:**
   ```typescript
   // User searches: "how do i get my money back"
   // Keyword search finds nothing because "refund" isn't in the query
   ```

✅ **Right approach:**
   ```typescript
   // Vector search understands "get my money back" ≈ "refund"
   // Returns the refund policy document
   ```

### Mistake 2: Embedding Every Single Word
❌ **Inefficient:**
   ```typescript
   for (const word of text.split(' ')) {
     await embed(word);  // One API call per word = slow + expensive
   }
   ```

✅ **Right approach:**
   ```typescript
   await embed(text);  // One API call for the whole document
   ```

### Mistake 3: Not Normalizing Vectors
❌ **Problem:**
   Some embedding models produce vectors with different magnitudes. This can skew similarity calculations.

✅ **Right approach:**
   ```typescript
   function normalize(v: number[]): number[] {
     const magnitude = Math.sqrt(v.reduce((sum, val) => sum + val * val, 0));
     return v.map(val => val / magnitude);
   }
   
   const normalized = normalize(embedding);
   ```

### Mistake 4: Ignoring Metadata in Vector DB
❌ **Problem:**
   Storing only vectors, no metadata. Can't filter by date, category, author.

✅ **Right approach:**
   ```typescript
   await index.upsert([{
     id: 'doc1',
     values: embedding,
     metadata: {
       text: 'Full document text...',
       category: 'policy',
       date: '2024-01-15',
       author: 'legal-team',
     },
   }]);
   
   // Then you can filter:
   await index.query({
     vector: queryEmbedding,
     filter: { category: 'policy', date: { $gte: '2024-01-01' } },
     topK: 10,
   });
   ```

### Mistake 5: Using the Wrong Embedding Model
❌ **Problem:**
   Using a model trained on English for Chinese text, or using a general model for code.

✅ **Right approach:**
   - General text: `text-embedding-3-small`
   - Code: `text-embedding-3-small` (works well) or specialized code models
   - Multilingual: Use multilingual models like `multilingual-e5-large`
   - Domain-specific: Consider fine-tuned embeddings for medical, legal, etc.

### Mistake 6: Re-embedding on Every Query
❌ **Expensive:**
   ```typescript
   // Every user query re-embeds the entire database
   const docs = await getAllDocuments();
   for (const doc of docs) {
     doc.embedding = await embed(doc.text);  // Slow!
   }
   ```

✅ **Right approach:**
   ```typescript
   // Embed documents once, store in vector DB
   // Only embed the query at runtime
   const queryEmbedding = await embed(userQuery);
   const results = await vectorDB.query(queryEmbedding);
   ```

---

## Interview Questions

### Q1: What is an embedding and why is it useful?
**Answer:** An embedding is a numerical representation (vector) of text that captures its semantic meaning. It's useful because it converts unstructured text into a format computers can process mathematically. This enables semantic search (finding documents by meaning, not keywords), similarity comparison, recommendations, and clustering. The key insight is that similar concepts have similar embeddings in vector space, allowing us to use mathematical operations like cosine similarity to measure semantic relatedness.

### Q2: How do you measure similarity between two embeddings?
**Answer:** The most common metric is cosine similarity, which measures the cosine of the angle between two vectors. It ranges from -1 (opposite) to 1 (identical), with 0 being unrelated. Cosine similarity is preferred over Euclidean distance for embeddings because it focuses on orientation (semantic direction) rather than magnitude. For high-dimensional text embeddings, magnitude can vary based on text length, but the direction captures the meaning. The formula is: cosine_similarity = (A · B) / (||A|| × ||B||), where · is dot product and ||A|| is the L2 norm.

### Q3: What is a vector database and why not use PostgreSQL?
**Answer:** A vector database is specialized for storing and querying high-dimensional vectors with approximate nearest neighbor (ANN) search. Traditional databases like PostgreSQL can store vectors (with extensions like pgvector), but they lack optimized indexing for similarity search at scale. Vector databases use algorithms like HNSW, IVF, or Annoy to build indexes that can find similar vectors in sub-millisecond time, even with millions of documents. For small datasets (<10K), PostgreSQL with pgvector is fine. For production at scale, use a dedicated vector database like Pinecone, Weaviate, or Qdrant.

### Q4: Explain the RAG pattern in simple terms.
**Answer:** RAG stands for Retrieval-Augmented Generation. It's a pattern where you first retrieve relevant documents from a knowledge base using vector search, then provide those documents to an LLM as context, and ask the LLM to answer using only that context. This combines the LLM's reasoning capabilities with your own up-to-date, domain-specific data. It solves two problems: hallucinations (the LLM answers from provided facts, not training) and stale knowledge (you update documents without retraining). The flow is: user query → embed → vector search → retrieve top K docs → add to prompt → LLM generates answer.

### Q5: What are the trade-offs between different embedding models?
**Answer:** The main trade-offs are: **Dimensionality** – higher dimensions (3072) capture more nuance but are slower and use more storage; lower dimensions (384) are faster but less precise. **Quality vs cost** – OpenAI's models are high quality but cost money; open-source models like MiniLM are free but slightly lower quality. **Domain specificity** – general models work well for most text, but specialized models (for code, medical, legal) perform better in their domains. **Speed** – smaller models embed faster, which matters for real-time applications. The practical advice: start with OpenAI's `text-embedding-3-small` for ease and quality, switch to open-source if cost becomes an issue.

### Q6: How do you handle documents that are too long to embed?
**Answer:** Most embedding models have a token limit (e.g., 8192 tokens for OpenAI). For longer documents, you chunk them into smaller pieces (e.g., 500-1000 characters with overlap). Each chunk is embedded separately, and all chunks are stored in the vector database. When querying, you retrieve the most relevant chunks. Overlap (e.g., 100 characters) ensures that concepts split across chunk boundaries aren't lost. The chunking strategy depends on your data – for code, chunk by function; for prose, chunk by paragraph or sentence; for PDFs, chunk by page.

---

## Practice Exercises

Use this to set up your environment:

```bash
# Python setup
pip install openai python-dotenv chromadb numpy

# Node.js setup
npm install openai @pinecone-database/pinecone
```

### Exercise 1: Your First Embedding
Create embeddings for these three texts:
- "The cat sat on the mat"
- "A feline rested on a rug"
- "I love programming in Python"

Calculate cosine similarity between all pairs. Which are most similar? Why?

### Exercise 2: Build a Simple Search Engine
Create a list of 10 documents (movie descriptions, product reviews, etc.). Embed all of them. Then write a search function that takes a query, embeds it, and returns the top 3 most similar documents with their similarity scores.

### Exercise 3: Chunking Strategy
Take a long text (e.g., a Wikipedia article or documentation page). Implement different chunking strategies:
- Fixed-size chunks (500 chars)
- Sentence-based chunks
- Paragraph-based chunks

Compare which strategy gives the best search results for relevant queries.

### Exercise 4: Vector Database Exploration
Set up either Chroma (Python) or Pinecone (TypeScript). Create a collection/index with at least 20 documents and metadata. Try:
- Basic similarity search
- Metadata filtering (e.g., only search documents from a specific category)
- Hybrid search (similarity + filters)

### Exercise 5: Mini RAG System
Build a simple RAG system:
1. Create a knowledge base of 5-10 documents on a specific topic
2. Embed and store them in a vector database
3. Write a function that:
   - Takes a user question
   - Retrieves the top 2 most relevant documents
   - Sends them to an LLM with the prompt: "Answer this question using ONLY the provided context: [documents]. Question: [question]"
4. Test with questions that can and cannot be answered from your knowledge base

---

## Summary Table

| Concept | Simple Meaning | Key Number |
|---------|---------------|-------------|
| Embedding | Numbers representing meaning | 1536 dimensions (OpenAI small) |
| Cosine similarity | Measures semantic similarity | -1 to 1 scale |
| Vector database | Specialized for similarity search | Scales to millions of vectors |
| RAG | Retrieve + Generate | Reduces hallucinations |
| Chunking | Split long documents | 500-1000 chars with overlap |
| ANN | Approximate Nearest Neighbor | Fast, not exact |

---

## Key Takeaways

- **Embeddings convert meaning to numbers** – similar concepts have similar vectors in high-dimensional space
- **Cosine similarity measures semantic relatedness** – focus on direction, not magnitude
- **Vector databases enable semantic search at scale** – use specialized DBs, not traditional SQL
- **RAG combines retrieval with generation** – provides context to LLMs to reduce hallucinations
- **Chunk long documents before embedding** – respect token limits, use overlap for continuity
- **Metadata is crucial** – store context with vectors for filtering and debugging
- **Start with OpenAI, optimize later** – `text-embedding-3-small` is a good default
- **Embed once, query many times** – don't re-embed your database on every request

---

## What's Next?

After completing this chapter:

**Move to Chapter 03 → RAG**
- Build production-ready retrieval systems
- Learn advanced RAG patterns (hybrid search, re-ranking, multi-hop)
- Implement evaluation metrics for RAG quality

**Don't move on until:**
- You've created embeddings and calculated similarity
- You've used a vector database (Chroma or Pinecone)
- You understand why chunking is necessary
- You've built a simple RAG system
- You've completed at least 3 of the 5 exercises

---

**Time spent:** ___ hours | **Date completed:** ___
