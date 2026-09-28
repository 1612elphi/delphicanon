# Port: delphicanon to Svelte

Svelte 5 port of the Ember addon in the repository root. The Ember sources (`src/`, `tests/`, `demo-app/`) are the reference; the root `PORT.md` holds the decisions behind them, which apply here unless a row below says otherwise.

## Decisions

| Topic | Decision | Why |
|---|---|---|
| Stack | Svelte 5 with runes (`$props`, `$state`, `$derived`, `$effect`), `<script lang="ts">`, plain Vite with `@sveltejs/vite-plugin-svelte`, svelte-check. Runtime dependency: `svelte` only. |
| Shared code | Components import `@canon/styles/tokens.css`, `@canon/components/canon-<name>.css` and `@canon/lib/<file>.ts` from the root `src/`; nothing is copied. `@canon` is a Vite alias and a tsconfig path. |
| Args | Ember args are props with the same names. Callbacks are function props with the Ember names (`onChange`, `onClick`, `onSelect`), the Svelte 5 convention. Internal state is `$state`, getters are `$derived`. |
| Blocks | The default block is `children`; named blocks are snippet props (`sidebar`, `main`, `banner`, `footer`, ...). A block that yields values is a snippet with parameters (`children: Snippet<[titleId: string]>`). `has-block` is a check of the snippet prop. |
| Attributes | `...attributes` is a rest prop spread last on the root element, so the consumer's attributes win as in Glimmer. `class` is merged (Glimmer merges it): the root's `class` is a clsx array ending in the consumer's class. An event the root handles itself calls the consumer's handler of the same name too, as stacked `{{on}}` modifiers would. |
| Icons | `icon` props are `Snippet`s the consumer renders. `iconSnippet(svg)` in `src/lib/control-icons.ts` turns an SVG string into one (`createRawSnippet`). The lucide icons the components draw themselves are inlined in `control-icons.ts` as strings. |
| Why inline | The Ember addon depends on `lucide-static` at runtime; this port may depend on `svelte` only. The demo still imports `lucide-static/icons/<name>.svg?raw` (dev dependency). |
| Modifiers | Ember modifiers are attachments (`{@attach}`), never actions: `press` (`src/lib/press.ts`), `grabPan(handlers)` (`grab-pan.ts`), `sidewaysPan(handlers)` (`sideways-pan.ts`). Local modifiers (grid layout, split collapse, canvas fit) are attachment factories in the component; a factory's arguments re-run it, as a changed modifier argument does in Ember. |
| Toast | The `canon-toast` service is `canonToast`, a class instance with `$state` fields in `src/lib/toast-store.svelte.ts` (`show`, `copy`, `write`). Nothing to register. Tests replace `canonToast.write`. |
| Ember-bound libs | `src/lib/control-icons.gts` is `src/lib/control-icons.ts` (snippets). `src/lib/math/editing.ts` is `src/lib/math-editing.svelte.ts` (`version` is `$state`). |
| Ids | `guidFor(this)` is `$props.id()`. |
| Docs | The class doc comment becomes a `<!-- @component -->` comment. Exported types and constants go in `<script module>`. |
| Tests | Vitest 5 browser mode, `@vitest/browser-playwright`, headless system Chrome (`/Applications/Google Chrome.app`, `CHROME_PATH` overrides). `vitest-browser-svelte` renders; a test that needs children or several components renders a fixture from `tests/fixtures/`. `tests/helpers.ts` reimplements the `@ember/test-helpers` calls the Ember tests use (`click` fires mousedown, focus, mouseup, click as Ember's does; `settled` is a Svelte tick and one task). QUnit assertions become `expect`. |
| Demo | `index.html` at the package root, `demo/main.ts` mounts `demo/app.svelte`. Gallery groups are `demo/gallery/<group>.svelte` exporting `pane` and `order` from `<script module>`, found with `import.meta.glob`. The demo imports the root `demo-app/styles.css` and gallery CSS instead of copying them; `public/` is the root's. Same query parameters as the Ember demo. |
| Style order | A component that sets its own `style` attribute puts it before the rest spread, so a consumer's `style` replaces it as in Glimmer. Components that set single properties with `style:` directives (code block, timecode, image compare) merge them with a consumer's `style` instead. | A `style:` directive always wins over a `style` attribute in Svelte. |
| Untracked setup | An attachment that builds something once (the colour solid's renderer, the math input sheet, the detent wheel's starting state) runs its body in `untrack`, and initial props read once in a constructor are read through `untrack`. | An attachment re-runs when any state it reads changes; the Ember modifier or constructor ran once. |
| Detent wheel | The follow attachment writes state in the effect itself; Ember deferred the writes with `queueMicrotask`. | Glimmer forbids writing tracked state during render; Svelte allows it in an effect. |
| Page strip | The long press reads the page from the cell's `data-page-index` when the press starts; cells are keyed by index. | An index argument would tear the gesture down on every selection. |
| Glyph flow | `children: Snippet<[glyph: G, index: number \| null]>` with `generics="G"`; `<:empty>` is the `empty` snippet. | Blocks with parameters are snippets. |
| Colour controls | `CanonColourSolidState` is a class with `$state` fields exported from `canon-colour-controls.svelte`'s module script, same fields, getters and `pick`. Inside the component the `state` prop is bound as `model`. | A local named `state` beside the `$state` rune is a compile error (`store_rune_conflict`). |
| Math | `CanonMathFieldHandle` is a class exported from the field's module script; the field registers `edit` on it in an effect. `CanonMathView` props extend `HTMLAttributes<Element>`, as its root is an `<svg>` or a `<div>`. | Same object passed to field and keypad as in Ember. |
| Empty arrays | CanonLamps and CanonReadoutBand treat an empty `lamps` array as absent, as Glimmer's `if` does. | Same output as Ember. |
| a11y ignores | `canon-colour-solid` (group with `tabindex`) and `canon-drop-zone` (static element with drop handlers) carry a `svelte-ignore` for the a11y warning. | Adding a role would change the DOM against Ember. |
| Checks | 57 test files, 98 tests (the 97 Ember tests plus one for a consumer's `pointerdown` on the slider). The gallery and the colour page were compared with the Ember demo pixel for pixel at 1400 x 1000 and 1400 x 5200, light and dark. | |

## Tracker

Tick when the component renders in the gallery, has its test, and passes lint.

| Tick | Component | Notes |
|---|---|---|
| [x] | canon-bar | |
| [x] | canon-big-number-field | |
| [x] | canon-button | |
| [x] | canon-canvas | |
| [x] | canon-code-block | |
| [x] | canon-colour-card | |
| [x] | canon-colour-controls | |
| [x] | canon-colour-notation-input | |
| [x] | canon-colour-solid | |
| [x] | canon-colour-strip | |
| [x] | canon-colour-well | |
| [x] | canon-decimal-field | |
| [x] | canon-detent-wheel-row | Tested by the detent wheel test. |
| [x] | canon-detent-wheel | |
| [x] | canon-drop-zone | |
| [x] | canon-dual-list | |
| [x] | canon-empty-row | |
| [x] | canon-figure | |
| [x] | canon-file-cell | |
| [x] | canon-from-to | |
| [x] | canon-glyph-flow | |
| [x] | canon-grid | |
| [x] | canon-heading | |
| [x] | canon-icon | No test, as in Ember. |
| [x] | canon-image-compare | |
| [x] | canon-lamps | |
| [x] | canon-loader | |
| [x] | canon-loupe | |
| [x] | canon-math-editor | |
| [x] | canon-math-field | |
| [x] | canon-math-input | Tested by the field test. |
| [x] | canon-math-key | |
| [x] | canon-math-keypad | |
| [x] | canon-math-rail | |
| [x] | canon-math-tabs | Tested by the keypad test. |
| [x] | canon-math-view | |
| [x] | canon-menu-cell | |
| [x] | canon-number-field | |
| [x] | canon-page-strip | |
| [x] | canon-page | |
| [x] | canon-palette-card | |
| [x] | canon-preview-panel | |
| [x] | canon-readout-band | |
| [x] | canon-row | |
| [x] | canon-rows | |
| [x] | canon-rule | |
| [x] | canon-segmented | |
| [x] | canon-slider | |
| [x] | canon-split | |
| [x] | canon-status | |
| [x] | canon-stepper | |
| [x] | canon-swatch | |
| [x] | canon-switch | |
| [x] | canon-text-area | |
| [x] | canon-text-cell | |
| [x] | canon-text-input | |
| [x] | canon-text-output | |
| [x] | canon-tiles | |
| [x] | canon-timecode | |
| [x] | canon-toast | |
| [x] | canon-value-line | |
