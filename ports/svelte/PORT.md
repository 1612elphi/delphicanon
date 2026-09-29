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
| Yielded modifiers | A modifier the Ember block yields (CanonPopover, CanonTooltip and CanonMenu `trigger`) is an attachment in the snippet's parameter object: `{#snippet children(menu)}<CanonButton {@attach menu.trigger} />{/snippet}`, `{#snippet trigger(popover)}`, `{#snippet content(popover)}`. An attachment on a component reaches the root element through the rest spread, as `...attributes` carries a modifier. Hash yields are one object parameter; positional yields (`close` in CanonDialog's blocks) are positional parameters. | Svelte passes values into a block only as snippet parameters, and an attachment is the element-level counterpart of a modifier. |
| Stable attachments | CanonMenuBar's `anchor(index)` and CanonMenuList's `submenu(index)` return the same function per index. | A new function re-attaches through the spread, which clears `popoverTargetElement` and `aria-expanded` on an open menu. |
| Menu list | `CanonMenuList` and `showMenu` are `canon-menu-list.svelte` (default export and module export); `canon-menu.svelte` re-exports `CanonMenuEntry` and `CanonMenuItem`. The list imports `canon-popover.css` only; CanonMenu, CanonContextMenu and CanonMenuBar import `canon-menu.css`. A submenu is the list importing itself. | A `.svelte` file has one component. The registry makes an item of every file, and `canon-menu.css` belongs to the `canon-menu` item, so the list importing it would make the cycle canon-menu, canon-menu-list, canon-menu. |
| Sheet | CanonSheet renders CanonDialog with its classes and a `keyframes(dialog)` prop, the slide from its edge. `keyframes` is a public CanonDialog prop, default the centred scale. | Ember's CanonSheet subclasses CanonDialog and overrides `classNames` and `keyframes()`; a Svelte component cannot be subclassed. |
| Jump grid | CanonJumpGrid renders CanonDialog with a fade as `keyframes`, as CanonSheet does. The window width is read only when `window` exists; the grid's ResizeObserver sets the columns once it mounts. The lit tile's `autofocus` carries a `svelte-ignore a11y_autofocus`, and the holder's click a `svelte-ignore` for the static-element warnings, as the Ember template disables the same lint rules. | Ember's CanonJumpGrid subclasses CanonDialog; `window` is undefined in a server render. |
| Jump heading | Every open lights the group then in view. The Ember component lights the first open's group again on later opens. | Ember's `current` is an untracked field, and Glimmer caches the first value it read; here it is `$state`. |
| Dialog content | The implicit children of CanonDialog and CanonSheet are the default block; `header`, `children` and `footer` get `close` as their parameter. | Blocks with parameters are snippets. |
| Server render | `tests/ssr.server.test.ts` renders each of the 11 menus, shell and command components, the 2 jump components and the 2 kit parts (CanonCompressionScale, CanonDimensionLine) with `svelte/server` `render()` in a Node Vitest project (`server` in `vite.config.ts`), so a `window` or `document` read during setup fails the run. | SvelteKit renders components on the server. |
| Window test | The window test's fixture gives its three boxes `flex: none`. | The Vitest browser viewport is narrower than the Ember test container, and the boxes shrank below the 640 px rail break. |
| Checks | 73 test files, 139 tests: in the browser project the 97 Ember tests of the first port, one for a consumer's `pointerdown` on the slider, the 20 Ember tests of the menus, shell and command groups, the compact sidebar test, the 2 Ember tests of the jump group, the 2 kit part tests and the split refit test; in the server project 15 server renders. The measures group (kit parts) matches the Ember demo pixel for pixel in all five scale states, light and dark. The jump group matches the Ember demo pixel for pixel, closed and open, light and dark. The gallery was compared with the Ember demo pixel for pixel at 1400 x 1000 and 1400 x 8000, light and dark, and the new widgets were driven in both demos with the same puppeteer steps. | |

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
| [x] | canon-command | |
| [x] | canon-compression-scale | The label placement is an attachment factory on the share and the label text. |
| [x] | canon-context-menu | |
| [x] | canon-decimal-field | |
| [x] | canon-detent-wheel | |
| [x] | canon-detent-wheel-row | Tested by the detent wheel test. |
| [x] | canon-dialog | |
| [x] | canon-dimension-line | |
| [x] | canon-drop-zone | |
| [x] | canon-dual-list | |
| [x] | canon-empty-row | |
| [x] | canon-figure | |
| [x] | canon-file-cell | |
| [x] | canon-from-to | |
| [x] | canon-glyph-flow | |
| [x] | canon-grid | Skips `[popover]` children when it places cells, as in Ember. |
| [x] | canon-heading | |
| [x] | canon-icon | No test, as in Ember. |
| [x] | canon-image-compare | |
| [x] | canon-jump-grid | |
| [x] | canon-jump-heading | |
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
| [x] | canon-menu | |
| [x] | canon-menu-bar | |
| [x] | canon-menu-cell | |
| [x] | canon-menu-list | Tested by the menu, context menu and menu bar tests. |
| [x] | canon-number-field | |
| [x] | canon-page | |
| [x] | canon-page-strip | |
| [x] | canon-palette-card | |
| [x] | canon-popover | |
| [x] | canon-preview-panel | |
| [x] | canon-readout-band | |
| [x] | canon-row | |
| [x] | canon-rows | |
| [x] | canon-rule | |
| [x] | canon-segmented | |
| [x] | canon-sheet | |
| [x] | canon-sidebar | |
| [x] | canon-sidebar-row | |
| [x] | canon-slider | |
| [x] | canon-split | Refits a collapsing picture on a new `data-canon-aspect` or `data-canon-height`, as Ember. The test waits two frames before the change, as the ResizeObserver's first notification otherwise lands after it and refits on its own. |
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
| [x] | canon-tooltip | |
| [x] | canon-value-line | |
| [x] | canon-window | |
