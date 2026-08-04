# Cluster

## Scope of This Topic

`cluster` is Node's built-in way to scale a **single I/O-bound server** across all available CPU cores, by forking multiple copies of the process — the direct answer to "one Node process only uses one core" from `node-architecture.md`.

## The Core Model

```
                [ Master/Primary Process ]
                    |         |         |
              [ Worker 1 ] [ Worker 2 ] [ Worker 3 ]   ← one per CPU core, each a FULL Node process
                    |         |         |
                 (all listening on the same port, OS load-balances incoming connections)
```

```js
const cluster = require('cluster');
const os = require('os');
const http = require('http');

if (cluster.isPrimary) {
  const numCPUs = os.cpus().length;
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork(); // spawn one worker per core
  }

  cluster.on('exit', (worker, code, signal) => {
    console.log(`Worker ${worker.process.pid} died, restarting...`);
    cluster.fork(); // auto-restart a crashed worker — real resilience benefit
  });
} else {
  // Worker process — runs the actual server
  http.createServer((req, res) => {
    res.end(`Handled by worker ${process.pid}`);
  }).listen(3000);
}
```

## How Load Distribution Actually Works

The primary process doesn't manually route requests — it uses OS-level socket sharing (`SO_REUSEPORT` on Linux, or Node's own round-robin scheduling on other platforms) so the kernel/Node distributes incoming connections across workers automatically. Each worker is a **completely separate process** — separate memory, separate V8 instance, separate event loop — not threads.

## Cluster vs Worker Threads vs Child Process — The Full Picture

| | Scope | Solves |
|---|---|---|
| `worker_threads` | Threads within one process | CPU-heavy computation, in-process |
| `child_process` | One arbitrary external process | Running external programs, isolated tasks |
| `cluster` | Multiple copies of **your same server app** | Scaling an I/O-bound server across CPU cores |

**Cluster is specifically for scaling your own server**, not for general-purpose parallelism — it's built on top of `child_process` internally (each worker is a forked Node process), specialized for the "N copies of the same HTTP server" pattern.

## The Real Limitation: No Shared State Between Workers

Since each worker is a separate process with separate memory, **in-memory state doesn't automatically sync across workers**:

```js
// BROKEN in a clustered app — each worker has its own separate `requestCount`
let requestCount = 0;
http.createServer((req, res) => {
  requestCount++; // only increments THIS worker's copy
  res.end(`Count: ${requestCount}`); // inconsistent depending on which worker handled the request
}).listen(3000);
```

**This is the single most common real bug when introducing `cluster`** — any in-memory cache, session store, or counter that worked fine as a single process silently becomes inconsistent/wrong once clustered. Correct fix: externalize shared state to Redis (or another shared store) rather than relying on in-process memory.

## Zero-Downtime Restarts (Real Production Pattern)

Because workers are independent processes, you can restart them **one at a time** without ever having zero workers available:

```js
function reloadWorkers() {
  const workers = Object.values(cluster.workers);
  function restartNext(i) {
    if (i >= workers.length) return;
    const worker = workers[i];
    worker.once('exit', () => {
      cluster.fork().once('listening', () => restartNext(i + 1)); // wait for replacement before continuing
    });
    worker.disconnect(); // graceful — finishes in-flight requests first
  }
  restartNext(0);
}
```

This is the underlying mechanism tools like **PM2** automate — rolling restarts for zero-downtime deploys, without needing a separate load balancer in front to achieve it (though a real production setup typically has one anyway, for multi-machine scaling).

## Cluster vs Separate Container Replicas — A Real Architecture Question

In modern containerized deployments (Kubernetes, ECS), horizontal scaling is often achieved via **multiple container replicas** behind a load balancer, rather than `cluster` forking within a single container. Both solve the same underlying problem (multi-core utilization), but at different layers:

- **`cluster` within one container**: simpler, no orchestrator dependency, but the container's resource limits (CPU/memory) are shared across all workers inside it.
- **Multiple container replicas** (one process per container, no clustering): cleaner resource isolation per replica, works naturally with Kubernetes' own scaling/health-check/restart mechanisms, avoids duplicating logic the orchestrator already provides.

**Common modern practice**: run **one process per container** (no `cluster`) and let the orchestrator handle replication — avoids two overlapping scaling/restart mechanisms fighting each other. `cluster` is more relevant for non-containerized deployments (a single VM, PM2-managed) or cases needing multi-core utilization within a single fixed container.

## Mental Model Summary

- `cluster` forks multiple full copies of your Node process (one per CPU core, typically), sharing incoming connections via OS-level load distribution.
- Each worker has fully separate memory — no automatic shared state; use Redis/external store for anything that must be consistent across workers.
- Enables zero-downtime rolling restarts by cycling workers one at a time.
- In containerized deployments, the orchestrator's own replica scaling often replaces the need for in-app `cluster` usage — know which layer you're scaling at.

## Fullstack Angle — What You'd Actually Debug

- **In-memory cache/counter/rate-limiter behaving inconsistently in production but fine locally** → classic clustering bug — each worker has its own separate memory; move shared state to Redis.
- **Session data randomly "lost" for some requests** → sessions stored in-memory per-worker instead of a shared session store — a request handled by a different worker than the one that created the session sees no session data.
- **Deploys causing brief downtime despite "zero-downtime" intentions** → rolling restart logic not actually waiting for each replacement worker to be ready (`listening` event) before killing the next one.

## Architect Angle — What You'd Actually Decide

- **Cluster vs container-replica scaling**: for Kubernetes/ECS-based deployments, prefer one process per container + orchestrator-managed replicas over in-app `cluster` — avoids two competing scaling/restart systems and gives cleaner per-replica resource isolation. Reserve `cluster` for VM-based or PM2-managed deployments without a container orchestrator.
- **Shared state architecture**: any service being clustered/replicated needs an explicit decision on where session/cache/rate-limit state lives — Redis (or similar) is the standard answer, and this should be decided *before* scaling out, not discovered as a bug after.
- **Health check and readiness design**: whichever scaling mechanism is chosen, workers/replicas need proper readiness signaling (only receive traffic once truly ready) and graceful shutdown (finish in-flight requests before termination) — a recurring category of production incident when overlooked.

## Interview Q&A Rapid Fire

**Q: What problem does `cluster` solve?**
A single Node process only uses one CPU core for JS execution; `cluster` forks multiple copies of the same server process (typically one per core), letting a multi-core machine be fully utilized for an I/O-bound server, with the OS/Node distributing incoming connections across the worker processes.

**Q: Why doesn't a simple in-memory counter work correctly in a clustered app?**
Each cluster worker is a fully separate OS process with its own memory space — there's no automatic state sharing between workers. A counter incremented in one worker's memory is invisible to the others, producing inconsistent results depending on which worker handles each request.

**Q: How does `cluster` enable zero-downtime restarts?**
Because workers are independent processes, they can be restarted one at a time — disconnect and replace one worker, wait for its replacement to be ready, then move to the next — ensuring there's always at least one worker available to handle traffic throughout the restart.

**Q: In a Kubernetes deployment, would you still use `cluster` inside each container?**
Generally no — running one process per container and letting Kubernetes manage replica count avoids two overlapping scaling/restart mechanisms and gives cleaner resource isolation per replica; `cluster` is more suited to non-orchestrated deployments (a single VM, PM2) or when multi-core utilization within one fixed container is specifically required.