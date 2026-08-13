# Module 8 — Forms

Angular has **three form APIs** worth being fluent in for a senior/principal interview: Template-Driven (oldest, still common in legacy/simple forms), Reactive Forms (mature, used in most existing complex-form codebases), and Signal Forms (stable as of v22, June 2026, for signal-first apps). Custom control integration is covered inside the relevant file since the mechanism differs across systems.

## Files
- **[template-driven-forms.md](./template-driven-forms.md)** — `ngModel`, `NgForm`, how the template implicitly builds the control tree, where it breaks down at scale, and when it's still the *right* choice.
- **[reactive-forms.md](./reactive-forms.md)** — `FormGroup`/`FormControl`/`FormArray`, typed reactive forms (v14+), custom sync/async validators, `ControlValueAccessor`, dynamic forms from JSON schema.
- **[signal-forms.md](./signal-forms.md)** — `form()`, `FieldTree`, schema-based validation (`required`, `validate`, `when`, `applyWhenValue`), how it compares to Reactive Forms, migration considerations.

## Quick orientation
- `[(ngModel)]` + `name` attributes, no `FormGroup` anywhere in TS → Template-Driven Forms.
- `formControlName` + explicit `new FormGroup({...})` in TS → Reactive Forms.
- `[formField]` + `form()` wrapping a signal → Signal Forms (v21+ experimental, v22 stable).
- Custom input component implementing `ControlValueAccessor` → Reactive (and Template-Driven) integration pattern.
- Custom input component bound via `[formField]` directly → Signal Forms integration pattern (no separate interface to implement).

## The three side by side
See the full comparison table in **template-driven-forms.md** (bottom section) — it covers all three systems in one place: source of truth, type safety, cross-field validation, testability, and where each is the right call.

## Interview framing
If asked "which would you use," the honest senior-level answer is **it depends on the app's existing reactive substrate** — not "Signal Forms because it's newer." An RxJS-heavy app with mature Reactive Forms infrastructure has no urgent reason to migrate; a new, signals-first app should default to Signal Forms. Being able to articulate that tradeoff (rather than defaulting to "newest wins") is itself a signal of seniority.