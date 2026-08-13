# Signal Forms

**Status: stable as of Angular v22 (June 2026)**, introduced experimentally in v21. Lives in a separate entry point: `@angular/forms/signals` — not `@angular/forms`. It's a **third option** alongside Reactive and template-driven forms, not a replacement for either; Angular is explicit that Reactive Forms remain fully supported.

## Mental Model
A Signal Form is a **`FieldTree` grown from a single writable signal**. You already have signals for component state — Signal Forms just say "let your form model be one of those signals too, and let the field-level UI concerns (validity, dirtiness, touched state) hang off it as their own signals," instead of maintaining `FormGroup`/`FormControl` as a parallel object graph you keep in sync with your data model.

Think of it as: **your data model *is* the form** — there's no separate "form model" translation layer to keep synchronized. Every property in your model signal gets a corresponding node in the `FieldTree`, and every node is itself signal-shaped (call it as a function to get its state).

## Core API

```typescript
import { signal } from '@angular/core';
import { form, required, email, minLength } from '@angular/forms/signals';

// 1. The model — a plain writable signal, just an object literal
const loginModel = signal({ email: '', password: '' });

// 2. Wrap it with form() — second arg is a schema callback for validation
const loginForm = form(loginModel, (schema) => {
  required(schema.email, { message: 'Email is required' });
  email(schema.email, { message: 'Please enter a valid email address' });
  required(schema.password, { message: 'Password is required' });
  minLength(schema.password, 8, { message: 'At least 8 characters' });
});
```

Template:
```html
<input [formField]="loginForm.email" />
<app-errors [field]="loginForm.email"></app-errors>

<input type="password" [formField]="loginForm.password" />
```

- `form()` returns a **`FieldTree`** — think of it as a deeply nested signal mirroring your model's shape. Nested objects need no special API; nest them in the model and the field tree mirrors the shape automatically.
- Every node (including the root) exposes the same state signals: `value`, `dirty`, `touched`, `invalid`, etc. Call a node as a function to read its state — the API is identical at every depth of the tree.
- `[formField]` is the binding directive that connects a native/custom input to a `FieldTree` node, replacing `formControlName`.

## Custom validation with validate()

```typescript
import { form, validate } from '@angular/forms/signals';

const checkoutForm = form(this.formModel, (schema) => {
  required(schema.method, { message: 'Please select a payment method.' });

  validate(schema.amount, ({ value }) => {
    const amount = value();
    if (amount <= 0) return { kind: 'minAmount', message: 'Amount must be greater than zero.' };
    if (amount > 10000) return { kind: 'maxAmount', message: 'Amount cannot exceed $10,000.' };
    return null; // valid
  });
});
```
- `validate()`'s callback receives a context with a `value` signal for that field, plus a `valueOf` helper to read *other* fields — this is how cross-field validation works (no separate group-level validator concept like Reactive Forms' `FormGroup` validators).
- There's no `customError()` helper — you just return `{ kind, message }` or `null` directly.

## Conditional validation

```typescript
required(schema.promoCode, {
  message: 'Promo code is required for discounts',
  when: ({ valueOf }) => valueOf(schema.applyDiscount),
});
```
Rules can be gated on other fields' current values via `when` — declarative, no manual subscribe/toggle logic.

## Type-guarded variants — applyWhenValue()
For discriminated unions (e.g., a payment form whose fields differ by `method: 'card' | 'bank'`), `applyWhenValue()` narrows validation rules to a specific variant when the predicate is a type guard — the recommended way to validate variant/union-shaped models instead of ad hoc `if` branches inside `validate()`.

## Async validation
Async validators (e.g., checking username availability against a server) are supported the same way as built-in ones, for cases needing external data sources rather than pure in-memory checks.

## Signal Forms vs Reactive Forms
| | Signal Forms | Reactive Forms |
|---|---|---|
| Source of truth | Your own `signal()` (the model *is* the data) | Separate `FormGroup`/`FormControl` object tree |
| State access | Every node is signal-shaped (`field()` to read) | `.value`/`valueChanges` (Observable-based) |
| Validation | Schema callback in `form()`, declarative `required()`/`validate()`/`when` | Validator functions attached per-control/group |
| Cross-field validation | `valueOf` inside any field's `validate()` | Validator on the parent `FormGroup` |
| Custom controls | Bind via `[formField]` | Implement `ControlValueAccessor` |
| Maturity (Aug 2026) | Stable as of v22, newer ecosystem/tooling | Mature, most existing codebases use this today |

## Architecture Mindset
- Signal Forms make the most sense in apps that are **already signal-first** end to end — if your services expose signals and your components are built on `computed()`/`effect()`, having forms live in that same reactive substrate avoids the RxJS↔signal boundary friction Reactive Forms otherwise introduces (`valueChanges` is an Observable, so you'd `toSignal()` it anyway to fit a signal-based architecture).
- For an app that's still RxJS/Reactive-Forms-heavy, don't force a migration just to chase the new API — Angular explicitly kept Reactive Forms as a first-class, fully-supported option. Evaluate per new feature, not as a wholesale rewrite.
- Custom validators via `validate()` + `valueOf` collapse what used to be two separate concepts in Reactive Forms (control-level validators and group-level cross-field validators) into one consistent mechanism — worth calling out as a design simplification when discussing this in an architecture review.

## Developer Mindset
- Stop thinking "form model vs data model" as two things you keep in sync — with Signal Forms there's one signal, and the `FieldTree` is a reactive *view* over it, similar to how `computed()` is a view over a signal.
- Read field state by calling the node like a signal (`loginForm.email().valid`) rather than reaching for imperative getters — this is the same mental shift Signals ask of you everywhere else in the app.
- Since this stabilized only in v22 (June 2026), expect thinner community tooling/StackOverflow coverage than Reactive Forms for a while — lean on the official docs and be ready to read source/blog posts from the Angular team directly when you hit an edge case.

## Common interview questions
1. **What problem do Signal Forms solve that Reactive Forms didn't?**
   → They eliminate the separate form-model-vs-data-model synchronization step; the model signal *is* the form, and validation/UI state (dirty, touched, invalid) are signal-shaped just like everything else in a signals-based component.
2. **How does cross-field validation work in Signal Forms vs Reactive Forms?**
   → Reactive Forms: a validator attached to the parent `FormGroup` reading sibling control values. Signal Forms: any field's `validate()` callback can read other fields via the `valueOf` helper in its context — no separate group-level validator concept needed.
3. **Are Signal Forms replacing Reactive Forms?**
   → No — Angular explicitly frames it as a third option alongside Reactive and template-driven forms, aimed particularly at apps already built signal-first. Reactive Forms remain fully supported.
4. **How do you handle a discriminated-union-shaped form model (e.g., payment method changes which fields are relevant)?**
   → `applyWhenValue()` with a type-guard predicate, narrowing validation rules to the matched variant — the recommended pattern over manual `if` branches inside a single `validate()`.
5. **What's the equivalent of `ControlValueAccessor` in Signal Forms for a custom input component?**
   → Bind the custom component to a `FieldTree` node via `[formField]`, same directive-driven connection point as native inputs — no separate interface to implement (the mechanism is unified, unlike Reactive Forms' `NG_VALUE_ACCESSOR` provider dance).

## Common Mistakes
- Importing from `@angular/forms` instead of `@angular/forms/signals` — Signal Forms is a distinct entry point; mixing the two APIs on the same field is not how it's designed to work.
- Trying to attach a cross-field validator "on the group" the Reactive Forms way — there is no separate group-validator concept; use `validate()` + `valueOf` on the relevant field(s) instead.
- Forgetting `structural nodes` (objects/arrays) in the model must stay plain objects/arrays — classes, `Map`, and `Set` aren't supported as structural nodes in the model signal.
- Assuming this is a drop-in replacement and rewriting a stable, working Reactive Forms codebase wholesale — evaluate per new form, since tooling/team familiarity with Reactive Forms is still deeper as of Aug 2026.
- Treating `when` conditions and `validate()` custom logic as equivalent — `when` is for gating a whole rule declaratively; reach for `validate()` when the pass/fail logic itself is genuinely custom, not just conditional.