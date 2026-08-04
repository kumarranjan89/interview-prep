# Process

## Scope of This Topic

`process` is a global object giving your running Node program information about, and control over, itself — environment variables, arguments, exit behavior, and crucially, hooks into error/signal handling that matter a lot in production.

## Core Properties

```js
process.argv;         // ['node', '/path/to/script.js', 'arg1', 'arg2'] — first 2 always node path + script path
process.env;            // environment variables object — process.env.NODE_ENV, process.env.PORT, etc.
process.platform;        // 'linux', 'darwin', 'win32'
process.version;          // Node version string
process.pid;                // this process's OS process ID
process.cwd();                // current working directory (see path-module.md for the __dirname distinction)
process.memoryUsage();         // { rss, heapTotal, heapUsed, external, arrayBuffers } — real diagnostic data
```

## Exiting the Process

```js
process.exit(0);  // 0 = success, non-zero = error/failure signal to shell/orchestrator
process.exit(1);
```

**Gotcha:** `process.exit()` terminates **immediately**, potentially before pending async operations (unflushed writes, in-flight I/O) complete — generally discouraged in application code. Prefer letting the event loop drain naturally by closing all open handles (server, DB connections), and only force-exit as a last resort with a timeout fallback.

## Error and Signal Handling — The Part That Matters in Production

```js
process.on('uncaughtException', (err) => {
  console.error('Uncaught exception:', err);
  // Node's own docs recommend NOT resuming normal operation here —
  // the process is in an undefined state; log, cleanup, then exit
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled rejection:', reason);
  // A rejected Promise with no .catch anywhere — as of modern Node, this can crash the process by default
});

process.on('SIGTERM', () => {
  // Sent by orchestrators (Docker, Kubernetes) to request graceful shutdown
  server.close(() => process.exit(0)); // stop accepting new connections, finish in-flight ones, then exit
});
```

**`uncaughtException` is a last-resort safety net, not a substitute for proper error handling** — code that relies on it to "catch everything" is a real anti-pattern; the process is genuinely in an unknown state at that point (a half-completed operation, corrupted in-memory state) and continuing to serve requests risks silent data corruption. Log and exit, let an orchestrator restart the process cleanly.

## Graceful Shutdown Pattern — A Real Production Concern

```js
function gracefulShutdown() {
  console.log('Shutting down gracefully...');
  server.close(() => {           // stop accepting new connections
    db.disconnect().then(() => {  // close DB pool
      process.exit(0);
    });
  });
  setTimeout(() => process.exit(1), 10000); // force-exit fallback if cleanup hangs
}

process.on('SIGTERM', gracefulShutdown); // Kubernetes/Docker send this before killing a container
process.on('SIGINT', gracefulShutdown);   // Ctrl+C locally
```

Without this, a container orchestrator killing a pod mid-request drops in-flight connections abruptly — a real source of intermittent 5xx errors during deployments/scaling events if graceful shutdown isn't implemented.

## Environment Variables — Configuration Pattern

```js
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

if (NODE_ENV === 'production') {
  // production-only behavior
}
```

`process.env` values are always **strings** — `process.env.MAX_RETRIES` is `"3"`, not `3`; forgetting to `parseInt`/coerce is a common, quietly-wrong bug (`"3" + 1` → `"31"`, not `4`).

## Mental Model Summary

- `process` is the interface to the currently running Node instance — env vars, args, memory stats, exit control.
- `process.exit()` is abrupt — prefer graceful shutdown via closing handles, reserving forced exit as a timeout fallback.
- `uncaughtException`/`unhandledRejection` are last-resort safety nets for logging and clean exit, not a substitute for proper `try/catch`/`.catch()` error handling.
- `SIGTERM` handling is essential in containerized/orchestrated deployments — without it, deploys and scale-downs drop in-flight requests.

## Fullstack Angle — What You'd Actually Debug

- **Intermittent 5xx errors specifically during deploys or autoscaling events** → missing `SIGTERM` graceful shutdown handling — the orchestrator is killing the process mid-request.
- **Config value behaving like a string when a number was expected** (`if (process.env.MAX_RETRIES > 2)` silently always true/false in a confusing way) → forgot to `parseInt`/`Number()` an env var — all `process.env` values are strings.
- **Process crashing with no clear stack trace pointing to app code** → check for `unhandledRejection` — a fire-and-forget async call somewhere without a `.catch`.

## Architect Angle — What You'd Actually Decide

- **Graceful shutdown as a non-negotiable production requirement**: any service deployed behind an orchestrator (Kubernetes, ECS) needs `SIGTERM` handling as part of the base service template — worth codifying in a shared boilerplate/starter template rather than leaving to individual service authors to remember.
- **`uncaughtException`/`unhandledRejection` policy**: standardize on log-and-exit (let the orchestrator restart) rather than attempting to "recover" and continue — a documented team policy, since the temptation to swallow-and-continue is real and genuinely dangerous for data integrity.
- **Configuration strategy**: env-var-based config (12-factor app style) is the standard for containerized deployments — but requires explicit type coercion/validation at startup (a schema-validated config module) rather than scattered `process.env.X || default` calls throughout the codebase, to catch misconfigurations early rather than at runtime.

## Interview Q&A Rapid Fire

**Q: Why is calling `process.exit()` directly generally discouraged?**
It terminates immediately, potentially cutting off pending async work (unflushed logs, in-flight DB writes, open connections) — preferred approach is closing all handles/servers gracefully and letting the process exit naturally, using a forced exit only as a timeout-guarded fallback.

**Q: What should you do inside an `uncaughtException` handler?**
Log the error for diagnostics and then exit the process — not attempt to resume normal operation, since the process is in an undefined state after an uncaught error and continuing risks silent data corruption or further crashes.

**Q: Why does a Node service need to handle `SIGTERM` explicitly?**
Container orchestrators (Docker, Kubernetes) send `SIGTERM` to request graceful shutdown before force-killing a process; without a handler that stops accepting new connections and finishes in-flight requests, deploys/scale-downs abruptly drop active connections, causing intermittent errors.

**Q: Why is `process.env.PORT` a common source of subtle bugs?**
All `process.env` values are strings — comparing or arithmetic-ing against them without explicit coercion (`parseInt`, `Number()`) produces string concatenation or always-true/false comparisons instead of the intended numeric behavior.