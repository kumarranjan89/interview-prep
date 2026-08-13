# Angular Mastery Syllabus (Principal/Staff-Level)

Structured for someone who already ships Angular daily — this skips "what is a component" and goes straight at internals, architecture, and the kind of questions asked at senior/principal bar-raiser rounds.

---

## Module 1 — Framework Architecture & Bootstrap

1.1 How Angular bootstraps an app — `bootstrapApplication()` vs legacy `platformBrowserDynamic().bootstrapModule()`
1.2 Standalone components/directives/pipes (v14+) vs NgModules — migration strategy, when NgModules still make sense
1.3 `ApplicationRef`, `NgZone`, and the root injector — what actually gets created at startup
1.4 Ahead-of-Time (AOT) vs Just-in-Time (JIT) compilation — what the Angular compiler (`ngc`/Ivy) does differently
1.5 Ivy renderer internals — instruction sets, `ɵɵelementStart`/`ɵɵadvance`, view engine vs Ivy compilation output
1.6 Incremental DOM vs Virtual DOM — why Angular chose Ivy's approach, tradeoffs vs React's VDOM diffing

## Module 2 — Dependency Injection (deep)

2.1 Injector hierarchy — root injector, platform injector, module injector, element injector, per-component injectors
2.2 Resolution algorithm — how Angular walks up the injector tree; `NullInjector`
2.3 `providedIn: 'root'` vs `providedIn: 'platform'` vs module-level `providers` vs component-level `providers`
2.4 Multi-providers (`multi: true`) — use cases (HTTP_INTERCEPTORS, validators)
2.5 Injection tokens (`InjectionToken`) — why/when over classes; typing them properly
2.6 `@Optional()`, `@Self()`, `@SkipSelf()`, `@Host()` — resolution modifiers and what problems each solves
2.7 `inject()` function (v14+) vs constructor injection — functional injection contexts, use in guards/resolvers/interceptors
2.8 Tree-shakable providers and how DI affects bundle size
2.9 Hierarchical DI gotchas — service instance per lazy-loaded module, singleton leaks, common interview trap: "why did my service state reset?"

## Module 3 — Component & Template Internals

3.1 Component metadata compilation — how `@Component` decorator becomes a `ComponentDef`
3.2 View hierarchy — host views, embedded views, `TemplateRef`, `ViewContainerRef`
3.3 Content projection — `<ng-content>`, multi-slot projection with `select`, `ngProjectAs`
3.4 Structural directives internals — how `*ngIf`/`*ngFor` desugar to `<ng-template>`; writing a custom structural directive
3.5 `ViewChild`/`ViewChildren`/`ContentChild`/`ContentChildren` — static vs dynamic queries, timing (`AfterViewInit` vs `AfterContentInit`)
3.6 Dynamic component creation — `ViewContainerRef.createComponent()`, `ComponentFactoryResolver` (deprecated) vs modern API
3.7 `@HostBinding`/`@HostListener` and host bindings in decorator metadata (v15+ `host: {}` object)

## Module 4 — Change Detection (this is where senior/principal interviews live)

4.1 Zone.js — monkey-patching of async APIs (`setTimeout`, `addEventListener`, Promises), how it triggers `ApplicationRef.tick()`
4.2 Change detection tree walk — top-down, per-component `ChangeDetectorRef`
4.3 `ChangeDetectionStrategy.Default` vs `OnPush` — exact rules for when an OnPush component re-checks (input reference change, event originating inside it, manual trigger, async pipe)
4.4 Manual control — `ChangeDetectorRef.markForCheck()`, `.detach()`, `.detectChanges()`, `.reattach()`
4.5 `NgZone.runOutsideAngular()` / `NgZone.run()` — escaping and re-entering CD for perf-critical code (canvas, animations, high-frequency events)
4.6 Zoneless change detection (stabilizing v18–v20) — `provideExperimentalZonelessChangeDetection()`, how signals make this viable, what breaks without Zone.js (third-party libs relying on it)
4.7 Signals-based fine-grained reactivity vs tree-walk CD — why this is a paradigm shift, not just an optimization
4.8 Common CD interview scenarios: "component didn't update after array mutation" (OnPush + reference equality), "infinite change detection loop" (ExpressionChangedAfterItHasBeenCheckedError), diagnosing with Angular DevTools profiler

## Module 5 — Signals (deep — you already have base notes)

5.1 `signal()`, `computed()`, `effect()` — semantics, laziness, glitch-free guarantees
5.2 `input()`, `model()` (two-way binding signals), `output()` — the new component API surface replacing decorators
5.3 `linkedSignal()` (v19+) — derived-but-writable state
5.4 `toSignal()` / `toObservable()` interop — bridging RxJS and signals cleanly
5.5 Signal-based `computed` dependency tracking internals — how the reactive graph is built and torn down
5.6 Migration playbook: converting an `@Input()` + `BehaviorSubject` + `ngOnChanges` component to signals

## Module 6 — RxJS in Angular (where it's still essential)

6.1 `HttpClient` — Observable-based, cancellation-friendly, interceptors
6.2 Async pipe — subscription/unsubscription lifecycle tied to the view, why it's preferred over manual `.subscribe()`
6.3 Higher-order mapping operators in real Angular use: `switchMap` (typeahead/search-as-you-type — cancels stale requests), `mergeMap` (parallel independent requests), `concatMap` (ordered sequential requests), `exhaustMap` (ignore new triggers until current completes — login button)
6.4 Subjects: `Subject`, `BehaviorSubject`, `ReplaySubject`, `AsyncSubject` — state management use cases
6.5 `takeUntilDestroyed()` (v16+, uses `DestroyRef`) vs manual `Subscription` teardown vs `takeUntil(destroy$)` pattern
6.6 Combining streams: `combineLatest`, `forkJoin`, `withLatestFrom`, `merge` — when each is correct
6.7 Error handling: `catchError`, retry strategies (`retry`, `retryWhen`/`retry({count, delay})`)
6.8 Memory leak patterns specific to Angular — subscriptions outliving components, common root causes

## Module 7 — Routing (internals, not just config)

7.1 Router internals — `UrlTree`, `RouterStateSnapshot`, navigation lifecycle events (`NavigationStart` → `NavigationEnd`)
7.2 Guards — `CanActivate`, `CanActivateChild`, `CanDeactivate`, `CanMatch`, functional guards (v14.2+) vs class-based
7.3 Resolvers — pre-fetching data before activation, functional resolvers with `inject()`
7.4 Lazy loading — `loadChildren` with dynamic `import()`, `loadComponent` for standalone routes, preloading strategies (`PreloadAllModules`, custom `PreloadingStrategy`)
7.5 Route reuse strategy — `RouteReuseStrategy`, caching component instances across navigation (common in tab-heavy UIs)
7.6 Auxiliary/named outlets, nested routes, route params vs query params vs data
7.7 `withComponentInputBinding()` — binding route params directly to component `input()`s

## Module 8 — Forms

8.1 Template-driven vs Reactive forms — architectural tradeoffs, when to pick which at scale
8.2 `FormControl`, `FormGroup`, `FormArray` — internals, `valueChanges`/`statusChanges` observables
8.3 Custom validators (sync and async) — `AsyncValidatorFn`, debouncing async validation
8.4 Custom form controls — implementing `ControlValueAccessor` correctly (a classic senior-level exercise)
8.5 Signal-based forms (experimental, track for interview currency) — where the RFC/dev preview stands
8.6 Dynamic forms — building `FormGroup` structures from JSON schema at runtime

## Module 9 — Performance Engineering

9.1 Bundle analysis — `source-map-explorer`, differential loading, esbuild-based build system (Angular v17+ default)
9.2 Lazy loading strategy design — route-level, component-level (`@defer` blocks, v17+)
9.3 `@defer` blocks — deferred loading triggers (`on viewport`, `on interaction`, `on idle`, `on timer`), placeholder/loading/error states
9.4 `trackBy` in `*ngFor` / built-in tracking in `@for` (v17 control flow) — DOM diffing cost
9.5 New control flow syntax (`@if`, `@for`, `@switch`) — compiler-level perf gains over structural directives
9.6 Virtual scrolling (`cdk-virtual-scroll-viewport`) for large lists
9.7 Image optimization — `NgOptimizedImage` directive
9.8 SSR/hydration — Angular Universal, non-destructive hydration (v16+), `provideClientHydration()`, hydration mismatches debugging
9.9 Core Web Vitals in Angular apps — LCP/CLS/INP considerations specific to Angular's rendering model

## Module 10 — State Management Architecture

10.1 When signals + services are enough vs when you need NgRx/NGXS/Akita
10.2 NgRx internals — actions, reducers (pure functions), effects (side-effect isolation via RxJS), selectors (memoization with `createSelector`), the store as a single Observable source of truth
10.3 NgRx Signals (`@ngrx/signals`) — the newer signal-based store API replacing some classic NgRx boilerplate
10.4 Component Store pattern — scoped state without global store overhead
10.5 Facade pattern — decoupling components from store implementation details

## Module 11 — Testing

11.1 TestBed internals — `TestBed.configureTestingModule()`, compiling components for tests
11.2 Component testing — `ComponentFixture`, `DebugElement`, `fixture.detectChanges()` timing gotchas
11.3 Testing OnPush components and signals — forcing CD in tests
11.4 Mocking DI — `overrideProvider`, `useValue`/`useClass`/`useFactory` in test providers
11.5 Testing async code — `fakeAsync`/`tick()` vs `waitForAsync()`, marble testing for RxJS streams
11.6 E2E — Cypress/Playwright vs deprecated Protractor, component-level E2E

## Module 12 — Enterprise Architecture & Patterns

12.1 Monorepo strategies — Nx workspace architecture, module boundaries, dependency-graph-based build/test affected commands
12.2 Micro-frontend approaches — Module Federation with Angular, native federation, single-spa integration
12.3 Design system / component library architecture — building an internal library with `ng-packagr`, secondary entry points
12.4 Feature module boundaries and public API surface (`index.ts` barrels — and why they can hurt tree-shaking/build perf at scale)
12.5 Internationalization (i18n) — built-in `$localize`, runtime vs build-time translation tradeoffs
12.6 Accessibility (a11y) — Angular CDK a11y module, focus management, ARIA live regions in SPA navigation

## Module 13 — Security

13.1 Built-in XSS protection — Angular's automatic sanitization (`DomSanitizer`), when/why to bypass it (and the risk)
13.2 Content Security Policy considerations for Angular apps (Ivy-generated inline styles, `ngCspNonce`)
13.3 HTTP interceptor patterns for auth token injection/refresh, CSRF handling (`HttpClientXsrfModule`)

## Module 14 — Migration & Versioning Currency

14.1 `ng update` internals — schematics-based automated migrations
14.2 Major version history awareness (v14 standalone preview → v15 standalone stable → v16 signals + hydration → v17 control flow + esbuild default + defer → v18 zoneless dev preview → v19/v20 stabilizations) — know roughly what shipped when, common interview gut-check
14.3 Deprecated API awareness — `ComponentFactoryResolver`, `TestBed.get()`, ViewEngine references (all removed) — recognizing legacy code and knowing the modern replacement

---

## Module 15 — Version-Wise Feature Timeline (Latest → Earliest)

Purpose: when you land in a legacy app, you can eyeball the Angular version and immediately know what's available vs what you'll see done "the old way" — and why. (Current stable as of Aug 2026: **v22**, released June 3, 2026.)

**v22 (Jun 2026) — "consolidation" release, current stable**
- **Signal Forms** — stable (moved out of experimental). Field-based API (`form()`, `Field`) replaces most `FormGroup`/`FormControl` boilerplate for new code
- **Resource APIs stable** — `resource()`, `rxResource()`, `httpResource()` all production-ready for async/data-fetching state as signals
- **Angular Aria** — stable: headless, accessible-by-default UI primitives you style yourself
- **OnPush is now the default change detection strategy** for new components (old always-check behavior renamed `ChangeDetectionStrategy.Eager`, opt-in only) — huge legacy-vs-new dividing line
- Router now inherits route params from **all** parent routes by default (previously only immediate parent, opt-in)
- **Vitest is the default test runner** (Karma fully phased out of new-project scaffolding)
- New apps ship **without Zone.js by default**
- **WebMCP** — apps/forms can expose themselves as tools AI agents running in-browser can call directly
- Selectorless components expanded; **@boundary** (error-boundary primitive) in developer preview
- TypeScript 5.9 support; Webpack-based builders deprecated (esbuild/Vite fully primary, TSGo support incoming)
- Major security hardening — stricter sanitization on SVG `href`/`xlink:href`, meta selectors, placeholder values; HTTP transfer cache no longer leaks cookie-bearing/`withCredentials` responses
- **Legacy tell**: any component without an explicit `changeDetection` strategy that still behaves like check-everything is pre-v22, or was scaffolded before the default flipped

**v21 (Nov 2025)**
- **Signal Forms** — introduced as experimental (stabilized in v22)
- **Zoneless is now default for new projects** (zone.js became opt-out, not opt-in)
- **Vitest replaces Karma** as the default test runner for new projects; Jest/Web Test Runner support deprecated
- `HttpClient` usable without explicitly importing `HttpClientModule`/`provideHttpClient()` boilerplate in more cases
- Angular MCP Server expanded — seven stable/experimental tools for AI agents to scaffold idiomatic Angular code
- Angular Aria — introduced in developer preview
- Route data available as signals (router signal-based data resolution)

**v20 (May 2025)**
- `effect()`, `linkedSignal()`, `toSignal()` — **stabilized** (out of developer preview)
- Incremental hydration — developer preview
- Route-level render mode config for hybrid SSR/SSG — developer preview
- **Zoneless promoted to developer preview** (from experimental)
- New template syntax: template string literals, exponentiation operator (`**`), `in` keyword, `void` operator in expressions
- Type checking added for host binding/listener expressions
- HammerJS support deprecated

**v19 (Nov 2024)**
- `linkedSignal()` — writable signal derived from another signal's state
- Incremental hydration (developer preview) — hydrate parts of the page on demand
- Route-level render mode config for hybrid SSR/SSG (developer preview)
- Standalone is now the CLI default for new projects (NgModules no longer scaffolded)

**v18 (May 2024)**
- Zoneless change detection — developer preview (`provideExperimentalZonelessChangeDetection()`)
- `@defer` blocks — stable
- Material 3 support
- Native async/await usable in more places due to build tooling updates

**v17 (Nov 2023)**
- New control flow syntax — `@if`, `@for`, `@switch` (built into template compiler, replaces `*ngIf`/`*ngFor`/`ngSwitch` for new code)
- `@defer` blocks — introduced (developer preview)
- esbuild + Vite-based dev server — new default build pipeline (much faster builds/HMR)
- Standalone APIs now the recommended default in docs/schematics
- View Transitions API integration for route animations
- **Legacy tell**: if you see `*ngIf`/`*ngFor` everywhere and no `@if`/`@for`, codebase predates or hasn't migrated past v17

**v16 (May 2023)**
- **Signals introduced** — `signal()`, `computed()`, `effect()` (developer preview)
- Non-destructive full-app hydration for SSR (previously destroy-and-rebuild)
- `inject()`-based required inputs preview groundwork
- Angular DevTools support for signals debugging
- Jest and Web Test Runner support (moving off Karma) begins
- **Legacy tell**: any state management done purely via RxJS `BehaviorSubject` + `async` pipe with no signals in sight predates v16, or the team hasn't adopted signals yet

**v15 (Nov 2022)**
- Standalone components/directives/pipes — **stable** (were developer preview in v14)
- `MEDIUM`-level directive composition API (`hostDirectives`)
- Image directive (`NgOptimizedImage`) — stable
- Router standalone APIs stabilized (`provideRouter()`)
- Functional route guards introduced

**v14 (Jun 2022)**
- Standalone components — introduced as **developer preview**
- Typed reactive forms (`FormControl<T>` instead of `any`) — big one for legacy form code cleanup
- `inject()` function introduced
- Optional injectors in Router
- **Legacy tell**: untyped `FormGroup`/`FormControl` (`.value` typed as `any`) means pre-v14 forms code

**v13 (Nov 2021)**
- Full Ivy-only tooling — View Engine (legacy renderer) fully removed
- Angular Package Format simplified, no more `ngcc` compatibility compiler step needed
- Component test harnesses stabilized (CDK)

**v12 (May 2021)**
- Nullish coalescing (`??`) in templates
- Style/webpack 5 support
- Deprecated: `esm5`/`fesm5` bundle formats (IE11-oriented legacy bundling)

**v9–v11 (2020)**
- Ivy renderer became the **default** (v9, Feb 2020) — this is the single biggest legacy dividing line: pre-v9 apps ran on View Engine, with real differences in compilation output, debugging, and library compatibility
- Router — `paramMap`/`queryParamMap` Observable APIs matured
- Strict mode project generation option (v11)

**v6–v8 (2018–2019)**
- `providedIn: 'root'` tree-shakable providers introduced (v6) — before this, everything went in `NgModule.providers` arrays
- Angular Elements (custom elements/web components) introduced (v6)
- `ng update`/`ng add` schematics introduced (v6)
- Differential loading (modern/legacy bundles) (v8)
- Ivy — opt-in preview (v8)
- **Legacy tell**: services registered in `providers: []` arrays inside NgModules instead of `providedIn: 'root'` is a pre-v6 (or un-migrated) pattern

**v2–v5 (2016–2017)**
- Original NgModule-based architecture, View Engine compiler, RxJS-only reactivity, `*ngIf`/`*ngFor` as the only structural directive syntax, class-based everything (no `inject()`), constructor DI only
- This is "classic Angular" — if you see this shape with none of the above, you're maintaining a genuinely old codebase and most of Modules 1–6 above will need translating back to this era's idioms (e.g., no signals at all, DI is 100% constructor-based)

### Quick legacy-app diagnostic checklist
| You see... | Codebase is roughly... |
|---|---|
| `form()`/`Field` from `@angular/forms/signals` | v21+ (v22 for stable) |
| No explicit `changeDetection` yet components behave OnPush-like | v22+ (OnPush became the default) |
| Karma + `karma.conf.js` present | pre-v21 (Vitest is now default) |
| `@if`/`@for` in templates | v17+ |
| `signal()`/`computed()` in components | v16+ |
| `standalone: true` or no NgModules at all | v15+ (stable), v14 (preview) |
| Typed `FormGroup<T>` | v14+ |
| `providedIn: 'root'` everywhere, no Ivy issues | v9+ |
| `providers: []` arrays in every NgModule, no tree-shaking | pre-v6 or never modernized |
| Heavy `zone.js` patches referenced directly, no signals, no `inject()` | pre-v16, likely v9–v13 |

**Note on support windows (as of Aug 2026):** v22 is current stable (support through Dec 2026, LTS through May 2028). v21 is in LTS through May 2027. v20 LTS runs through Nov 2026. v19 and below are end-of-life — if you're maintaining one of those, expect no security patches, which is itself worth flagging in an interview when discussing legacy-app tradeoffs.

---

## Suggested pacing
Given the sequential DSA → system design → React plan already in motion, treat this as the **Angular-specific block** ahead of interviews: modules 1–6 are "must be instant recall," 7–11 are "must explain with tradeoffs," 12–14 are "must sound current" — principal-level rounds probe there specifically because it signals you haven't stalled on an old version.

## Suggested repo structure
```
interview-prep/angular/
  01-architecture-bootstrap.md
  02-dependency-injection.md
  03-component-template-internals.md
  04-change-detection.md
  05-signals.md          <- already created
  06-rxjs.md
  07-routing.md
  08-forms.md
  09-performance.md
  10-state-management.md
  11-testing.md
  12-enterprise-patterns.md
  13-security.md
  14-migration-versioning.md
  15-version-feature-timeline.md
```