# Template-Driven Forms

## Mental Model
Template-driven forms flip the direction Reactive Forms take: **the template is the source of truth**, and Angular builds the `FormControl`/`FormGroup` tree *for you* behind the scenes by reading directives (`ngModel`, `name`, `required`) off the DOM at runtime. You never instantiate `FormControl`/`FormGroup` yourself — the `NgForm` directive (auto-attached to every `<form>`) does it implicitly.

This is the inverse of the Signal Forms/Reactive Forms mental model of "model drives the form." Here, markup drives the form, and you reach into it via a template reference variable when you need the model.

## Core API

```html
<form #loginForm="ngForm" (ngSubmit)="onSubmit(loginForm)">
  <input
    name="email"
    [(ngModel)]="model.email"
    required
    email
    #emailField="ngModel"
  />
  <div *ngIf="emailField.invalid && emailField.touched">
    Email is required and must be valid.
  </div>

  <input name="password" [(ngModel)]="model.password" required minlength="8" />

  <button [disabled]="loginForm.invalid">Log in</button>
</form>
```

```typescript
class LoginComponent {
  model = { email: '', password: '' }; // plain object — not a FormControl anywhere

  onSubmit(form: NgForm) {
    if (form.valid) {
      console.log(form.value); // { email: '...', password: '...' }
    }
  }
}
```

Requires `FormsModule` imported (or, for standalone components, `imports: [FormsModule]` on the component itself).

## How it works under the hood
- `ngModel` is the directive that does double duty: it reads the initial value from the bound property, writes user input back to it (two-way binding via `[(ngModel)]` banana-in-a-box syntax, which desugars to `[ngModel]="model.email" (ngModelChange)="model.email = $event"`), *and* registers a `FormControl` instance with the parent `NgForm` automatically — keyed by the `name` attribute.
- `name` is not just an HTML attribute here — it's what Angular uses as the key when auto-building the underlying `FormGroup`. Forgetting `name` on a control inside `ngForm` is a common bug: the control silently isn't registered in the form model.
- Validation directives (`required`, `minlength`, `email`, `pattern`) are actually **directives that wrap the same `Validators.*` functions Reactive Forms uses** — the underlying validation engine is shared; only how validators get attached (template attributes vs explicit `Validators.required` in TS) differs.
- `#emailField="ngModel"` exports the directive instance to a template variable, giving you access to `.valid`, `.invalid`, `.touched`, `.dirty`, `.errors` — the same state properties `AbstractControl` exposes in Reactive Forms, just accessed from the template instead of the component class.

## Async validators
Attached the same way — as a directive with a provider registering an `NG_ASYNC_VALIDATORS` token — but far less common to write custom ones in template-driven forms specifically, since anything nontrivial tends to push a team toward Reactive Forms.

## Where it breaks down at scale
- **No type safety** on the form value — `model` is just a plain object; there's no compiler-enforced link between what's in the template and what shape you'll get back.
- **Cross-field validation is awkward** — there's no natural "parent group" to attach a validator function to in the template the way Reactive Forms lets you attach one to a `FormGroup` in TypeScript. It's usually done with a custom directive that reaches up to `NgForm`, which is more ceremony than the Reactive equivalent.
- **Hard to unit test** — the form model only fully exists once the template renders and directives run `ngOnInit`, so testing validation logic requires `TestBed`/DOM rendering, unlike Reactive Forms where you can construct and test a `FormGroup` with zero rendering.
- **Dynamic forms are painful** — adding/removing fields at runtime means conditionally rendering template markup (`*ngIf`/`*ngFor` over a fields array) rather than just pushing/removing from a `FormArray` in TypeScript.

## Signal Forms vs Reactive Forms vs Template-Driven — full picture
| | Template-Driven | Reactive | Signal Forms |
|---|---|---|---|
| Source of truth | Template (`ngModel` directives) | `FormGroup`/`FormControl` tree in TS | A `signal()` model, wrapped by `form()` |
| Setup | `[(ngModel)]` + `name` attrs | Explicit `new FormGroup({...})` | `form(modelSignal, schema)` |
| Type safety | None (plain object) | Full, if using `FormControl<T>` (v14+) | Full — types flow from the model signal |
| Best for | Trivial forms (login, search box) | Complex, dynamic, or heavily-tested forms | Signal-first apps wanting one reactive substrate |
| Cross-field validation | Awkward (custom directive) | Validator on parent `FormGroup` | `validate()` + `valueOf` on any field |
| Testability | Requires rendering/`TestBed` | Fully unit-testable without rendering | Fully unit-testable — it's just a signal |
| Maturity (Aug 2026) | Mature, legacy-common | Mature, most codebases | Stable since v22 (Jun 2026), newest |

## Architecture Mindset
- Template-driven forms are not "the beginner API to graduate from" — they're the right architectural choice for **genuinely simple, low-validation-complexity forms** where the overhead of building an explicit `FormGroup` buys you nothing. A search box or a single-field newsletter signup doesn't need Reactive Forms' ceremony.
- The real architectural risk is a team defaulting to template-driven forms **out of habit** as complexity grows, then bolting on custom validator directives and template logic to simulate what Reactive Forms gives you natively — that's the point to flag a migration, not "always avoid template-driven forms."
- In a legacy-app audit, heavy template-driven form usage across genuinely complex forms (multi-step wizards, forms with nontrivial cross-field rules) is itself a signal of technical debt worth raising.

## Developer Mindset
- Remember `name` is load-bearing, not decorative — a missing `name` attribute on an `ngModel`-bound input is registered nowhere in the form, and the bug ("why isn't my form value including this field") is easy to lose time to.
- Don't reach for a custom directive to hack in cross-field validation the template-driven way once you notice you need it — that's the signal to migrate that specific form to Reactive Forms rather than force-fit the simpler API.
- When reading legacy code, `#var="ngModel"` / `#var="ngForm"` template reference variables are how state (`valid`/`touched`/`dirty`) gets exposed — if you're hunting for where validation errors are being read, start there.

## Common interview questions
1. **Template-driven vs Reactive Forms — when would you choose each?**
   → Template-driven for simple, low-validation forms where ceremony isn't worth it; Reactive for anything complex, dynamic, or requiring solid unit test coverage without rendering.
2. **How does `[(ngModel)]` actually register a control with the form?**
   → It desugars into `[ngModel]`/`(ngModelChange)` two-way binding, and the `NgModel` directive itself registers a `FormControl` with the parent `NgForm`, keyed by the element's `name` attribute.
3. **Why is cross-field validation harder in template-driven forms?**
   → There's no explicit parent `FormGroup` object in your code to attach a validator function to — you'd need a custom directive that reaches up into `NgForm`, versus just attaching a validator to a `FormGroup` you already constructed in Reactive Forms.
4. **How would you unit test validation logic in a template-driven form vs a Reactive form?**
   → Template-driven requires `TestBed` + rendering, since the form model doesn't exist independent of the DOM. Reactive Forms lets you construct and test a `FormGroup` directly with zero rendering.
5. **What's the underlying relationship between template-driven validation attributes (`required`, `email`) and Reactive Forms' `Validators`?**
   → They're directives wrapping the same underlying `Validators.*` functions — the validation engine is shared; only the attachment mechanism (template attribute vs explicit TS call) differs.

## Common Mistakes
- Forgetting the `name` attribute on an `ngModel`-bound control inside a `<form>` — it silently fails to register with the form model.
- Forgetting to import `FormsModule` (or add it to a standalone component's `imports`) — `ngModel`/`ngForm` directives simply don't exist without it, producing a confusing template compilation error.
- Trying to unit test validation logic without rendering the template — it won't work the way it does for Reactive Forms, since the control tree only exists once directives run.
- Reaching for increasingly elaborate custom directives to simulate cross-field validation or dynamic fields instead of migrating that specific form to Reactive Forms once complexity crosses a threshold.
- Mixing `[(ngModel)]` two-way binding with a Reactive Forms `FormControl` on the same element — these are two different form systems and combining them on one control is a broken/unsupported pattern, not a hybrid feature.