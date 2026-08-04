# OS Module

## Scope of This Topic

`os` provides read access to operating-system-level information — CPU, memory, network interfaces, platform details. Mostly used for diagnostics, capacity-aware logic (e.g. sizing a worker pool to CPU count), and cross-platform-aware code.

## Core Methods

```js
const os = require('os');

os.platform();     // 'linux', 'darwin', 'win32'
os.arch();          // 'x64', 'arm64'
os.type();           // 'Linux', 'Darwin', 'Windows_NT'
os.release();        // kernel/OS version string

os.cpus();           // array of CPU core info (model, speed, times) — length = core count
os.totalmem();       // total system RAM in bytes
os.freemem();        // available RAM in bytes

os.hostname();        // machine hostname
os.homedir();          // current user's home directory
os.tmpdir();            // OS temp directory — correct cross-platform location for scratch files
os.networkInterfaces(); // network interface details (IP addresses, MAC, etc.)

os.uptime();             // system uptime in seconds
```

## The Practical Use That Actually Matters: Sizing Worker/Cluster Pools

```js
const os = require('os');
const cluster = require('cluster');

const numCPUs = os.cpus().length;
for (let i = 0; i < numCPUs; i++) {
  cluster.fork(); // one worker process per core — ties directly into cluster.md
}
```

This is the single most common real-world use of `os` — determining how many worker processes/threads to spawn to fully utilize available CPU cores, rather than hardcoding a number that may not match the deployment environment.

## `os.tmpdir()` — Correctness Detail

Using `os.tmpdir()` instead of a hardcoded `/tmp` matters because the OS temp directory location differs by platform (`/tmp` on Linux/macOS, `C:\Users\...\AppData\Local\Temp` on Windows) — hardcoding breaks Windows compatibility silently.

```js
const path = require('path');
const tempFile = path.join(os.tmpdir(), 'upload-' + Date.now() + '.tmp');
```

## Container Awareness Caveat — A Real Production Gotcha

Inside a Docker container (or any cgroup-limited environment), `os.cpus().length` and `os.totalmem()` report the **host machine's** resources, not the container's actual allocated limits — a container capped at 2 CPUs on a 32-core host still reports 32 from `os.cpus()`.

This has caused real production bugs: a service using `os.cpus().length` to size a worker pool inside a resource-constrained container over-provisions workers relative to actual available CPU, leading to excessive context-switching and worse performance than a correctly-sized pool. Correct approach in containerized environments: read the actual cgroup limits (or better, pass the intended concurrency as an explicit environment variable set by the deployment config, rather than trusting `os.cpus()`).

## Mental Model Summary

- `os` is a read-only diagnostics/environment-info module — CPU count, memory, platform, temp directory.
- The main practical use is sizing worker pools (`cluster`, `worker_threads`) to available CPU cores.
- In containers, `os.cpus()`/`os.totalmem()` reflect the **host**, not the container's cgroup-enforced limits — a genuine, easy-to-miss production sizing bug.

## Fullstack Angle — What You'd Actually Debug

- **Worker pool sized "correctly" locally but performing poorly in production containers** → `os.cpus().length` reporting host core count instead of the container's actual CPU allocation — check deployment's cgroup/CPU limits vs what the code assumes.
- **Temp file cross-platform path bugs** → hardcoded `/tmp` instead of `os.tmpdir()`.

## Architect Angle — What You'd Actually Decide

- **Explicit concurrency configuration over auto-detection in containerized deployments**: prefer an explicit `WORKER_COUNT` environment variable set by the deployment/orchestration layer (which knows the actual allocated CPU limit) over trusting `os.cpus()` inside the application — a more reliable and container-aware sizing strategy.
- **Resource-aware autoscaling design**: understanding that `os`-reported resources don't reflect cgroup limits is directly relevant when designing Kubernetes/container resource requests+limits alongside in-app concurrency settings — mismatches here are a recurring root cause of "why is this pod thrashing" incidents.

## Interview Q&A Rapid Fire

**Q: What's the most common practical use of the `os` module?**
Determining CPU core count (`os.cpus().length`) to size worker pools — for `cluster` forking or `worker_threads` spawning — so the app scales to match available hardware instead of a hardcoded number.

**Q: Why can `os.cpus().length` be misleading in a Docker container?**
It reports the host machine's total CPU count, not the container's actual cgroup-enforced CPU limit — a container restricted to 2 CPUs on a 32-core host still sees 32 from `os.cpus()`, leading to over-provisioned worker pools if used naively for sizing.

**Q: Why use `os.tmpdir()` instead of hardcoding `/tmp`?**
The correct temp directory location differs by OS (`/tmp` on Linux/macOS, a different path on Windows) — hardcoding breaks cross-platform compatibility silently rather than throwing an obvious error.