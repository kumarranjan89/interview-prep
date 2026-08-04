# Child Process

## Scope of This Topic

`child_process` lets Node spawn and communicate with **separate OS processes** — the mechanism for running external programs, offloading CPU-heavy work outside the single JS thread, or shelling out to system tools. This is a different (heavier) tool than `worker_threads` (next topic) — worth understanding the distinction clearly, since interviews often probe it directly.

## The Four Core Methods

```js
const { exec, execFile, spawn, fork } = require('child_process');
```

| Method | Use Case | Output Handling |
|---|---|---|
| `exec` | Run a shell command (supports pipes, `&&`, etc.) | Buffers entire output in memory, returned via callback |
| `execFile` | Run an executable directly, no shell | Same buffering as `exec`, but no shell injection risk |
| `spawn` | Run a command, stream output | Streams stdout/stderr — no buffering limit, better for large output |
| `fork` | Special case of `spawn` — spawns a **new Node.js process** | Streaming + built-in IPC channel for message passing |

## `exec` vs `execFile` — A Real Security Distinction

```js
// exec — runs through a shell, VULNERABLE to injection if userInput is untrusted
exec(`convert ${userInput} output.png`, callback);
// if userInput = "input.png; rm -rf /", the shell executes BOTH commands

// execFile — no shell involved, arguments passed directly, immune to shell injection
execFile('convert', [userInput, 'output.png'], callback);
```

**This is a genuinely common real vulnerability class** — any `exec()` call building a command string from user input is a shell injection risk. `execFile`/`spawn` with an arguments array (not a concatenated string) is the safe pattern.

## `spawn` — Streaming, For Larger Output

```js
const { spawn } = require('child_process');
const child = spawn('ffmpeg', ['-i', 'input.mp4', 'output.avi']);

child.stdout.on('data', (data) => console.log(`stdout: ${data}`));
child.stderr.on('data', (data) => console.error(`stderr: ${data}`));
child.on('close', (code) => console.log(`exited with code ${code}`));
```

`exec`/`execFile` buffer the **entire** output before the callback fires — fine for small output, but risks hitting the default buffer limit (`maxBuffer`, default 1MB) and crashing for large output (e.g. processing a large log file). `spawn` streams instead, with no such ceiling, at the cost of slightly more verbose event-based handling.

## `fork` — Node-to-Node with Built-in Messaging

```js
// parent.js
const { fork } = require('child_process');
const child = fork('worker-script.js');

child.send({ task: 'process', data: [1, 2, 3] });
child.on('message', (result) => console.log('Got result:', result));

// worker-script.js
process.on('message', (msg) => {
  const result = msg.data.map(x => x * 2);
  process.send(result);
});
```

`fork` is specifically for spawning **another Node.js process** running a separate script — each with its own V8 instance, memory space, and event loop, communicating only via message passing (`send`/`on('message')`), not shared memory. This is heavier than `worker_threads` (separate process vs separate thread) but gives full process isolation — a crash in the child doesn't touch the parent at all.

## Child Process vs Worker Threads — The Question Interviews Actually Ask

| | `child_process` (`fork`) | `worker_threads` |
|---|---|---|
| Isolation | Full OS process — separate memory entirely | Separate thread within the same process |
| Communication | Message passing only (serialized) | Message passing, **plus** `SharedArrayBuffer` for actual shared memory |
| Overhead | Higher — new process, new V8 instance | Lower — shares the parent process's V8 instance |
| Crash impact | Child crash fully isolated from parent | A worker crash can be contained but shares more underlying resources |
| Best for | Running external programs, full isolation needs, spawning non-Node executables | CPU-heavy JS computation that needs to stay within one Node process |

**Rule of thumb:** `worker_threads` for CPU-heavy pure-JS work (image processing, data crunching) within one service; `child_process` for running external tools/binaries, or when full process-level isolation is a genuine requirement (e.g. running untrusted code).

## Mental Model Summary

- Four methods: `exec`/`execFile` (buffered output, small commands), `spawn` (streamed output, larger workloads), `fork` (Node-to-Node with built-in messaging).
- Never build shell command strings from unsanitized user input — use `execFile`/`spawn` with an arguments array instead of `exec` with string concatenation.
- `child_process` gives full OS-level process isolation (heavier); `worker_threads` gives lighter thread-level isolation within the same process — choose based on whether you need full isolation or just CPU parallelism.

## Fullstack Angle — What You'd Actually Debug

- **Command injection finding in a security review** → `exec()` with string-concatenated user input — migrate to `execFile`/`spawn` with an arguments array.
- **Child process silently failing on large output** → hit the default `maxBuffer` limit on `exec`/`execFile` — switch to `spawn` and stream, or raise `maxBuffer` deliberately if output size is bounded and known.
- **Parent process not exiting cleanly after spawning children** → orphaned child processes not being killed/cleaned up on parent shutdown — needs explicit `child.kill()` in the shutdown path.

## Architect Angle — What You'd Actually Decide

- **Process isolation as a security boundary**: for any workload involving untrusted input processing (image/document conversion via external tools, running user-submitted code), `child_process` with full OS isolation (plus OS-level sandboxing, containers) is the architecturally correct choice over `worker_threads`, which shares the parent's memory space more closely.
- **Never allow raw shell string construction from user input anywhere in the codebase** — worth an explicit lint rule or code-review checklist item (`no exec() with template strings`), since this is a genuine, recurring vulnerability class across many codebases, not a hypothetical.
- **CPU-heavy work architecture decision**: choosing between `worker_threads` (in-process, lower overhead) vs a fully separate microservice/child process (higher overhead, stronger isolation, independently scalable) is a real trade-off to document — not just a performance question but an operational/deployment one (separate scaling, separate deploys, separate failure domains).

## Interview Q&A Rapid Fire

**Q: What's the security risk with `exec()` and how do you avoid it?**
`exec()` runs the command through a shell, so string-concatenating user input into the command creates a shell injection vulnerability (e.g. appending `; rm -rf /`). Avoid by using `execFile`/`spawn` with an arguments array, which passes arguments directly without shell interpretation.

**Q: Why would you choose `spawn` over `exec` for a long-running command?**
`exec` buffers the entire output in memory before returning it, and can hit a default buffer size limit (`maxBuffer`) on large output. `spawn` streams stdout/stderr incrementally with no such limit — better suited for large or continuous output.

**Q: What's the core difference between `child_process.fork()` and `worker_threads`?**
`fork()` spawns an entirely separate OS process with its own V8 instance and memory space, communicating only via serialized message passing — full isolation, higher overhead. `worker_threads` runs within the same process on a separate thread, sharing the process's resources more closely, with lower overhead and optional true shared memory via `SharedArrayBuffer`.

**Q: When would you choose `child_process` over `worker_threads` despite the higher overhead?**
When you need genuine OS-level process isolation — running external non-Node executables, or processing untrusted input where a crash or compromise should be fully contained from the parent process, not just thread-isolated within the same process.