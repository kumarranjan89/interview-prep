# Worker Threads

## Scope of This Topic

`worker_threads` is Node's answer to genuine CPU-bound parallelism **within a single process** — real OS threads running actual JS code in parallel, distinct from libuv's I/O thread pool (which runs C++ code for `fs`/`crypto`/`dns`, not your JS). This directly addresses the "Node is bad at CPU-heavy work" limitation raised in `node-architecture.md`.

## Why This Exists — What It Solves

A CPU-heavy synchronous JS function (image processing, complex calculations, large JSON parsing) occupies the single JS thread completely — no other request can be handled until it finishes, regardless of how "async" the rest of your code is. `worker_threads` moves that computation to a genuinely separate thread with its own V8 instance and event loop, freeing the main thread to keep serving other requests.

```js
// main.js
const { Worker } = require('worker_threads');

const worker = new Worker('./heavy-task.js', {
  workerData: { numbers: [1, 2, 3, 4, 5] }
});

worker.on('message', (result) => console.log('Result:', result));
worker.on('error', (err) => console.error('Worker error:', err));
worker.on('exit', (code) => console.log(`Worker exited with code ${code}`));

// heavy-task.js
const { workerData, parentPort } = require('worker_threads');

function heavyComputation(numbers) {
  return numbers.reduce((sum, n) => sum + n ** 2, 0); // stands in for genuinely CPU-heavy work
}

parentPort.postMessage(heavyComputation(workerData.numbers));
```

## Communication — Message Passing by Default

Workers don't share memory with the main thread by default — data passed via `postMessage` is **structured-cloned** (deep-copied), not shared:

```js
worker.postMessage({ data: largeArray }); // largeArray is COPIED, not shared — cost scales with size
```

For genuinely large data, this copy cost matters — which is where `SharedArrayBuffer` comes in.

## `SharedArrayBuffer` — True Shared Memory (Advanced, Use Carefully)

```js
const sharedBuffer = new SharedArrayBuffer(1024);
const sharedArray = new Int32Array(sharedBuffer);

worker.postMessage({ sharedBuffer }); // the BUFFER ITSELF is shared, not copied — both threads see the same memory
```

This avoids copy overhead entirely, but reintroduces classic multi-threaded hazards — race conditions, torn reads/writes — that Node's single-threaded model normally protects you from. Correct usage requires `Atomics` (`Atomics.add`, `Atomics.wait`, etc.) for safe concurrent access. **Genuinely advanced territory** — most applications never need this; `postMessage` copying is fine unless profiling shows the copy cost is the actual bottleneck.

## Worker Pools — Don't Spawn Per-Request

Creating a new `Worker` has real startup overhead (new V8 isolate, new event loop) — spawning one per incoming request is a common anti-pattern that defeats the purpose.

```js
// Anti-pattern — new worker per request, startup overhead on every call
app.post('/process', (req, res) => {
  const worker = new Worker('./task.js', { workerData: req.body });
  worker.on('message', result => res.json(result));
});

// Better — maintain a pool, reuse workers, queue tasks when all are busy
// (libraries like piscina or workerpool handle this correctly)
const Piscina = require('piscina');
const pool = new Piscina({ filename: './task.js' });

app.post('/process', async (req, res) => {
  const result = await pool.run(req.body);
  res.json(result);
});
```

**Real production pattern:** use a worker pool library (`piscina`, `workerpool`) rather than hand-rolling pool management — task queuing, worker reuse, and back-pressure handling are easy to get subtly wrong when implemented manually.

## Worker Threads vs Child Process vs Cluster — Quick Disambiguation

| | Scope | Use Case |
|---|---|---|
| `worker_threads` | Thread within one process | CPU-heavy JS computation, in-process |
| `child_process` | Separate OS process | External programs, full isolation needs |
| `cluster` | Multiple full Node processes, same app | Scaling an I/O-bound server across CPU cores (next topic) |

## Mental Model Summary

- Worker threads provide real parallel JS execution for CPU-bound work, distinct from libuv's I/O thread pool (which never runs your JS).
- Data is copied (structured clone) by default via `postMessage` — `SharedArrayBuffer` avoids copying but reintroduces real concurrency hazards, requiring `Atomics`.
- Never spawn a worker per request — use a pool (ideally via a library like `piscina`) to amortize the real startup cost of creating a worker.

## Fullstack Angle — What You'd Actually Debug

- **API endpoint doing image/data processing blocks unrelated requests under load** → CPU-heavy synchronous work on the main thread — candidate for moving to `worker_threads`.
- **New worker-based endpoint is slower than expected under moderate load** → likely spawning a worker per request instead of using a pool — the worker startup cost can exceed the actual computation time for small tasks.
- **Data corruption / inconsistent results when using `SharedArrayBuffer`** → missing `Atomics` for safe concurrent access — a genuine race condition, not a fluke.

## Architect Angle — What You'd Actually Decide

- **CPU-bound workload boundary**: deciding whether CPU-heavy work belongs in `worker_threads` (in-process, lower overhead, tightly coupled to the main service) versus a fully separate service/language better suited to compute (e.g. a Python/Go service for heavy data processing) is a real architecture call — worker threads are the right answer for moderate, occasional CPU spikes, not for a service whose primary job is heavy computation.
- **Worker pool sizing and lifecycle**: pool size should generally track available CPU cores (tying back to `os.cpus().length`, with the container-awareness caveat from `os-module.md`) — worth documenting as an explicit capacity decision, not left to a library's default.
- **Standardize on a pool library** (`piscina`/`workerpool`) across services rather than hand-rolled worker management — the task-queuing and backpressure logic is easy to get wrong, and a shared, tested implementation reduces operational risk.

## Interview Q&A Rapid Fire

**Q: How is `worker_threads` different from libuv's I/O thread pool?**
The I/O thread pool (used for `fs`/`crypto`/`dns` operations) runs Node's internal C++ code to fake non-blocking behavior for OS-blocking operations — it never executes your JS. `worker_threads` runs actual JS code on a genuinely separate thread with its own V8 instance, intended specifically for offloading CPU-heavy JS computation.

**Q: Do worker threads share memory with the main thread by default?**
No — `postMessage` performs a structured clone (deep copy) of the data by default. True shared memory requires explicitly using `SharedArrayBuffer`, which then requires `Atomics` for safe concurrent access to avoid race conditions.

**Q: Why is spawning a new Worker per incoming request a bad pattern?**
Creating a worker has real startup overhead (new V8 isolate, new thread, new event loop) — for short-lived tasks, this overhead can exceed the actual computation time. A worker pool (reusing a fixed set of long-lived workers, queuing tasks) amortizes that cost properly.

**Q: When would you choose `worker_threads` over `child_process` for CPU-heavy work?**
When the work is pure JS computation that benefits from lower overhead and doesn't need full OS-process isolation — `worker_threads` shares the parent process's resources more efficiently. `child_process` is preferred when running external non-Node programs or when genuine full-process isolation (e.g. for untrusted code) is required.