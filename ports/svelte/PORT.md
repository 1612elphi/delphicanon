# Port: delphicanon to Svelte

Svelte 5 port of the Ember addon in the repository root. The Ember sources (`src/`, `tests/`, `demo-app/`) are the reference; the root `PORT.md` holds the decisions behind them, which apply here unless a row below says otherwise.

## Decisions

| Topic | Decision |
|---|---|
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

## Tracker

Tick when the component renders in the gallery, has its test, and passes lint.

| Tick | Component | Notes |
|---|---|---|
| [ ] | canon-bar | |
| [ ] | canon-big-number-field | |
| [ ] | canon-button | |
| [ ] | canon-canvas | |
| [ ] | canon-code-block | |
| [ ] | canon-colour-card | |
| [ ] | canon-colour-controls | |
| [ ] | canon-colour-notation-input | |
| [ ] | canon-colour-solid | |
| [ ] | canon-colour-strip | |
| [ ] | canon-colour-well | |
| [ ] | canon-decimal-field | |
| [ ] | canon-detent-wheel-row | |
| [ ] | canon-detent-wheel | |
| [ ] | canon-drop-zone | |
| [ ] | canon-dual-list | |
| [ ] | canon-empty-row | |
| [ ] | canon-figure | |
| [ ] | canon-file-cell | |
| [ ] | canon-from-to | |
| [ ] | canon-glyph-flow | |
| [ ] | canon-grid | |
| [ ] | canon-heading | |
| [ ] | canon-icon | |
| [ ] | canon-image-compare | |
| [ ] | canon-lamps | |
| [ ] | canon-loader | |
| [ ] | canon-loupe | |
| [ ] | canon-math-editor | |
| [ ] | canon-math-field | |
| [ ] | canon-math-input | |
| [ ] | canon-math-key | |
| [ ] | canon-math-keypad | |
| [ ] | canon-math-rail | |
| [ ] | canon-math-tabs | |
| [ ] | canon-math-view | |
| [ ] | canon-menu-cell | |
| [ ] | canon-number-field | |
| [ ] | canon-page-strip | |
| [ ] | canon-page | |
| [ ] | canon-palette-card | |
| [ ] | canon-preview-panel | |
| [ ] | canon-readout-band | |
| [ ] | canon-row | |
| [ ] | canon-rows | |
| [ ] | canon-rule | |
| [ ] | canon-segmented | |
| [ ] | canon-slider | |
| [ ] | canon-split | |
| [ ] | canon-status | |
| [ ] | canon-stepper | |
| [ ] | canon-swatch | |
| [ ] | canon-switch | |
| [ ] | canon-text-area | |
| [ ] | canon-text-cell | |
| [ ] | canon-text-input | |
| [ ] | canon-text-output | |
| [ ] | canon-tiles | |
| [ ] | canon-timecode | |
| [ ] | canon-toast | |
| [ ] | canon-value-line | |
