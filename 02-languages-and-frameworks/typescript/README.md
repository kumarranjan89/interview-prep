# 🔷 TypeScript — Reading Guide

TypeScript for **architect / 15+ YOE** interviews and daily Angular work. **Foundation-first**, then advanced types, then real-world patterns in Angular/production codebases.

> **Architect framing:** at your level, TypeScript interviews probe *how you think in types* — structural typing, type algebra, modeling domain constraints — not syntax recall. You're expected to design type-safe APIs, diagnose complex type errors, and govern TypeScript config across teams.

---

## 📖 Read In This Order

| # | File | What it covers | Phase |
|---|------|----------------|-------|
| 1 | [type-system.md](./type-system.md) | The mental model: structural typing, type vs interface, widening/narrowing, the type hierarchy | 🧠 Foundation |
| 2 | [generics.md](./generics.md) | Generics in depth: constraints, defaults, variance, generic functions/classes, real patterns | 🧠 Core |
| 3 | [advanced-types.md](./advanced-types.md) | Type algebra: conditional types, mapped types, template literal types, `infer`, recursive types | 🧠 Advanced |
| 4 | [utility-types.md](./utility-types.md) | Built-in utilities (`Partial`, `Required`, `Pick`, `Omit`, `ReturnType`, `Parameters` etc.) + building custom ones | 🛠️ Applied |
| 5 | [narrowing-guards.md](./narrowing-guards.md) | Narrowing, type guards, discriminated unions, `satisfies`, assertion functions | 🛠️ Applied |
| 6 | [classes-decorators.md](./classes-decorators.md) | Classes, access modifiers, abstract, mixins, and decorators (Angular context) | 🛠️ Applied |
| 7 | [modules-declarations.md](./modules-declarations.md) | ES modules, ambient declarations, `.d.ts` files, declaration merging, module augmentation | 🛠️ Applied |
| 8 | [config-project-setup.md](./config-project-setup.md) | `tsconfig`, strict mode flags, project references, paths, performance, Angular workspace | ⚙️ Config |
| 9 | [angular-typescript.md](./angular-typescript.md) | TypeScript *inside* Angular: decorators, DI typing, strict templates, generics in services, component patterns | 🅰️ Angular |
| ★ | [interview-questions.md](./interview-questions.md) | **Architect-level TypeScript Q&A** across all topics | 🎯 Interview |

---

## 🗺️ The Learning Path (Why This Order)

```
FOUNDATION        1. type-system        structural typing, the mental model
        ↓
CORE              2. generics           write reusable, type-safe code
        ↓
ADVANCED          3. advanced-types     type algebra (conditional/mapped/infer)
                  4. utility-types      compose existing + build custom
        ↓
APPLIED           5. narrowing-guards   model domain states safely
                  6. classes-decorators OOP + Angular decorator context
                  7. modules-declarations ambient types, .d.ts, augmentation
        ↓
PRODUCTION        8. config-project-setup  tsconfig, strict, monorepo
                  9. angular-typescript    TS patterns in your actual stack
```

- **Type system first** — structural typing is the one concept most devs miss; understanding it makes everything else click.
- **Generics before advanced types** — generics are the vocabulary; conditional/mapped types use them constantly.
- **Utility types after advanced** — now you understand how they're built, not just how to use them.
- **Angular last** — everything before applies inside Angular; this section maps it to your actual codebase.

---

## ⏱️ If You're Short on Time

- **30-min refresher:** `type-system.md` + `generics.md`.
- **Interview tomorrow:** `generics.md` → `advanced-types.md` → `interview-questions.md`.
- **Angular debugging:** `narrowing-guards.md` + `angular-typescript.md`.
- **Strict mode / new project:** `config-project-setup.md`.

---

## 🎯 What "Good" Looks Like (Architect Bar)

By the end you should be able to:
- Explain **structural typing** and how TypeScript's type system works
- Write and read **complex generic** types with constraints and variance
- Understand and write **conditional types, mapped types, and `infer`**
- Model domain states as **discriminated unions** to eliminate invalid states
- Build custom utility types by composing type operators
- Explain and configure **all key strict mode flags** and why each matters
- Diagnose complex type errors without guessing
- Govern TypeScript config across a multi-team Angular workspace
- Speak to **decorator metadata**, DI typing, and strict template checking in Angular

---

## 🔗 Related Sections
- [Angular](../angular/) — component architecture, signals, zoneless
- [Performance](../performance/) — `framework-performance.md` (OnPush, signals)
- [Micro-Frontends](../mfe/README.md) — typed contracts between remotes
- [Build & Tooling](../tooling/) — bundlers, AOT, transpilation target

---

💡 **Tip:** The fastest way to level up TypeScript thinking is to read complex type definitions in well-typed libraries (Angular's core, RxJS) and reason through how they work — the skills in files 2–4 make that readable.
