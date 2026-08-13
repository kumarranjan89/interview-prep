# Reactive Forms

## Mental Model
A Reactive Form is a **tree of `FormControl`/`FormGroup`/`FormArray` objects you build explicitly in TypeScript**, and the template just binds to that tree — it never owns the source of truth. Contrast with template-driven forms, where the template *is* the source of truth and Angular reverse-engineers a form model from directives. Reactive forms flip that: model-first, template second. This is why reactive forms are the default recommendation at scale — the form's shape, validation, and value are all inspectable, testable, and typeable without touching the DOM.

## Core API

```typescript
import { FormGroup, FormControl, FormArray, Validators } from '@angular/forms';

const profileForm = new FormGroup({
  name: new FormControl('', [Validators.required, Validators.minLength(2)]),
  emails: new FormArray([
    new FormControl('', [Validators.required, Validators.email]),
  ]),
});

profileForm.valueChanges.subscribe(v => console.log(v));   // Observable
profileForm.statusChanges.subscribe(s => console.log(s));  // 'VALID' | 'INVALID' | 'PENDING' | 'DISABLED'

profileForm.get('name')?.setValue('Ranjan');
profileForm.patchValue({ name: 'Ranjan' }); // partial update, doesn't require all keys
```

Template:
```html
<form [formGroup]="profileForm" (ngSubmit)="onSubmit()">
  <input formControlName="name" />
  <div formArrayName="emails">
    <input *ngFor="let c of emails.controls; let i = index" [formControlName]="i" />
  </div>
</form>
```

## Typed Reactive Forms (v14+)
Before v14, `FormGroup.value` was typed `any` — a common legacy-code smell.
```typescript
interface ProfileForm {
  name: FormControl<string>;
  age: FormControl<number | null>;
}
const form = new FormGroup<ProfileForm>({
  name: new FormControl('', { nonNullable: true }),
  age: new FormControl(null),
});
form.value.name; // typed as string, autocomplete works
```
`{ nonNullable: true }` matters — without it, `.reset()` sets the control back to `null` even if you typed it as `string`, which silently breaks type safety.

## Custom Validators

```typescript
// Sync
function forbiddenNameValidator(forbidden: RegExp): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const forbidden_ = forbidden.test(control.value);
    return forbidden_ ? { forbiddenName: { value: control.value } } : null;
  };
}

// Async — e.g. checking username availability against a server
function uniqueUsernameValidator(api: UserService): AsyncValidatorFn {
  return (control: AbstractControl) =>
    api.checkUsername(control.value).pipe(
      map(taken => (taken ? { usernameTaken: true } : null)),
      debounceTime(300) // debounce inside the validator itself, or use updateOn: 'blur'
    );
}
```
Cross-field validation (e.g., "password === confirmPassword") is attached at the `FormGroup` level, not on an individual control, since it needs access to sibling values.

## ControlValueAccessor — writing a custom form control
This is the interface that lets a **custom component** (date picker, star rating, rich text editor) participate in `formControlName`/`[(ngModel)]` binding like a native `<input>`.

```typescript
@Component({
  selector: 'app-star-rating',
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => StarRatingComponent),
    multi: true,
  }],
})
class StarRatingComponent implements ControlValueAccessor {
  value = 0;
  disabled = false;
  private onChange: (v: number) => void = () => {};
  private onTouched: () => void = () => {};

  writeValue(v: number): void { this.value = v; }              // model -> view
  registerOnChange(fn: (v: number) => void): void { this.onChange = fn; }
  registerOnTouched(fn: () => void): void { this.onTouched = fn; }
  setDisabledState(disabled: boolean): void { this.disabled = disabled; }

  selectStar(v: number) {
    this.value = v;
    this.onChange(v);  // view -> model
    this.onTouched();
  }
}
```
This is a **classic senior-level take-home/whiteboard exercise** — interviewers use it to check you actually understand the form control abstraction, not just `[(ngModel)]` surface usage.

## Dynamic forms
Building `FormGroup` structures at runtime from a JSON schema (common in admin panels/CMS-driven UIs):
```typescript
buildForm(schema: FieldSchema[]): FormGroup {
  const group: Record<string, FormControl> = {};
  for (const field of schema) {
    group[field.name] = new FormControl(
      field.default ?? '',
      field.required ? [Validators.required] : []
    );
  }
  return new FormGroup(group);
}
```
Key design question interviewers probe: how do you keep this **typed** when the shape is runtime-determined? (Usually: you don't fully — you accept `FormGroup<Record<string, FormControl<any>>>` at the dynamic boundary and narrow with runtime validation, or generate types from the schema at build time.)

## Architecture Mindset
- Reactive forms are the right default for **anything with complex validation, dynamic fields, or unit-testable logic** — because the form model exists independently of the DOM, you can unit test validation without `TestBed`/rendering at all.
- Template-driven forms remain fine for genuinely simple forms (a login form, a single search box) where the ceremony of building a `FormGroup` isn't worth it.
- At scale, wrap `ControlValueAccessor` components in a shared UI library — every custom input (date range, multi-select, currency) should be a `ControlValueAccessor` so form code never special-cases how a given field is filled in.

## Developer Mindset
- Treat the `FormGroup` as your state management for the form — don't duplicate form values into separate component fields "for convenience"; read from the form's `value`/`valueChanges` directly.
- `updateOn: 'blur'` or `'submit'` (per-control or form-wide) is underused — default `'change'` fires validation (and any async validator's HTTP call) on every keystroke, which is wasteful for anything hitting a server.
- Always unsubscribe from `valueChanges`/`statusChanges` subscriptions (`takeUntilDestroyed()`) — a classic memory-leak source in long-lived forms (wizards, multi-step flows kept alive across steps).

## Common interview questions
1. **Reactive vs template-driven forms — when would you pick each?**
   → Reactive: complex/dynamic/testable forms, type safety. Template-driven: simple forms, quick prototypes, when the team leans heavily on directives-in-template style.
2. **How do you implement cross-field validation (e.g., password confirmation)?**
   → A validator function attached to the parent `FormGroup`, reading both child control values, returning an error object placed on the group (not a single control).
3. **Walk me through implementing `ControlValueAccessor` for a custom component.**
   → Explain the four methods (`writeValue`, `registerOnChange`, `registerOnTouched`, `setDisabledState`) and the `NG_VALUE_ACCESSOR` provider token with `forwardRef`.
4. **How do typed reactive forms (`FormControl<T>`) change form code compared to pre-v14?**
   → Compile-time type safety on `.value`, autocomplete, and the `nonNullable` option controlling what `.reset()` produces — versus untyped `any` everywhere pre-v14.
5. **How would you debounce an async validator that hits an API on every keystroke?**
   → `debounceTime()` inside the validator's observable pipeline, or set `updateOn: 'blur'` on the control so validation (and the API call) only fires when the user leaves the field.

## Common Mistakes
- Forgetting `{ nonNullable: true }` on typed controls, then being surprised `.reset()` sets a "typed as string" control to `null` at runtime.
- Attaching cross-field validators to individual controls instead of the parent `FormGroup` — they need sibling access, which individual controls don't have.
- Not debouncing/switching `updateOn` for async validators — hammering an API on every keystroke.
- Leaking `valueChanges`/`statusChanges` subscriptions in long-lived forms (wizards) by never unsubscribing.
- Reimplementing `ControlValueAccessor` behavior manually with `@Input()`/`@Output()` instead of actually implementing the interface — breaks compatibility with `formControlName`, validators, and form state tracking (`dirty`/`touched`) for that field.