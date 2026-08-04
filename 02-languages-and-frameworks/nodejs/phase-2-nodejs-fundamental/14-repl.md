# REPL

## Scope of This Topic

REPL (Read-Eval-Print Loop) is Node's interactive shell — `node` with no file argument. Smallest topic in this phase, but worth understanding both as a debugging tool and because Node exposes the underlying `repl` module for building custom interactive tooling.

## Basic Usage

```bash
$ node
> const x = 5;
undefined
> x + 3
8
> .exit
```

Each expression is evaluated immediately and its result printed — genuinely useful for quickly testing a snippet, checking API behavior, or exploring an unfamiliar module without creating a throwaway file.

## Useful Built-in REPL Commands

```
.help       — list all REPL commands
.break      — exit a multi-line expression you got stuck in
.clear      — reset the current context (clear defined variables)
.save file  — save current session to a file
.load file  — load and execute a file's contents into the session
.editor     — enter multi-line edit mode (useful for pasting larger blocks)
.exit       — quit (Ctrl+D also works)
```

## `_` — The Last Result Variable

```js
> 5 + 3
8
> _ + 10
18
```

`_` always holds the result of the last evaluated expression — handy for chaining exploration without retyping.

## Programmatic REPL — Building Custom Tooling

Node exposes `repl.start()` to embed a REPL inside your own application, which is how tools like a debugging console attached to a running server, or a custom CLI's interactive mode, are built:

```js
const repl = require('repl');

const replServer = repl.start({ prompt: 'myapp> ' });
replServer.context.db = database; // inject app-specific objects into the REPL's scope

// Now inside the REPL: myapp> db.query('SELECT ...')
```

This pattern shows up in real tools — e.g. attaching a REPL to a running production-debugging session (with appropriate access controls) to inspect live application state without redeploying.

## REPL vs Running a Script — When Each Makes Sense

| | REPL | Script file |
|---|---|---|
| Best for | Quick one-off checks, exploring an API, debugging a snippet interactively | Anything meant to be run repeatedly, version-controlled, or shared |
| State | Lost on exit (unless `.save`d) | Persisted as actual source code |
| Async handling | Top-level `await` supported in modern Node REPL | Requires wrapping in an async function pre-ES2022, native top-level await in ESM |

## Mental Model Summary

- REPL is Node's interactive shell for quick exploration/debugging — not a replacement for actual scripts, but genuinely useful for fast iteration.
- `_` holds the last result; `.editor` mode handles multi-line pasting cleanly.
- `repl.start()` lets you embed a REPL inside your own tooling, injecting app-specific context for live inspection — a legitimate production debugging pattern when properly access-controlled.

## Fullstack Angle — What You'd Actually Use This For

- **Quickly checking how an unfamiliar library's API behaves** before committing code to a file — faster feedback loop than writing/running a throwaway script.
- **Debugging a live production issue** via an embedded REPL/debug console (properly secured) to inspect actual running state — faster than adding logging and redeploying.

## Architect Angle — What You'd Actually Decide

- **Debug console access control**: if embedding a REPL into a production service for live inspection, this is a genuine security surface — must be scoped to internal-only network access, authenticated, and audited, not exposed on a public port. Worth an explicit security review before enabling in any production environment.
- **Not a substitute for observability tooling**: an embedded REPL is a useful last-resort debugging aid, not a replacement for proper structured logging/metrics/tracing — worth setting that expectation with a team that might otherwise lean on it as a primary debugging method.

## Interview Q&A Rapid Fire

**Q: What does REPL stand for and what is it used for in Node?**
Read-Eval-Print Loop — Node's interactive shell (`node` with no arguments), used for quickly testing snippets, exploring APIs, and debugging without writing a full script file.

**Q: What does the `_` variable do in the Node REPL?**
Holds the result of the last evaluated expression, allowing quick chaining/continued exploration without retyping the previous result.

**Q: How would you build a custom interactive debugging console for a running application?**
Use `repl.start()` to embed a REPL instance within the application, injecting relevant objects (e.g. a database connection) into `replServer.context` so they're accessible by name inside the interactive session — with proper access controls if used in production.