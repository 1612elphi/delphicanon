# Port: delphicanon to React

The Ember addon in `../../src` is the reference; the Swift sources behind it where the Ember code is unclear. The root `PORT.md` decisions hold unless a row below changes them.

## Decisions

| Topic | Decision |
|---|---|
| Stack | React 19, TypeScript strict (`noUncheckedIndexedAccess`), function components and hooks, Vite with `@vitejs/plugin-react`. Runtime dependencies: `react`, `react-dom`. |
| Shared code | CSS and pure logic come from the root through the `@canon` alias (`@canon/styles/tokens.css`, `@canon/components/canon-<name>.css`, `@canon/lib/<file>.ts`). Nothing under the root `src/` is copied or edited. |
| Names | One Ember component, one file, same name: `canon-button.gts` becomes `src/components/canon-button.tsx`, default export `CanonButton`, props interface `CanonButtonProps` exported beside it. |
| Args | Ember args become props of the same name. `@onChange` and every other callback arg is a prop of the same name taking the same arguments (`onChange(value)`), never a DOM `ChangeEvent`. |
| Attributes | `...attributes` becomes the rest props spread on the root element; `className` joins the component's classes, `style` merges after the component's custom properties, and `ref` reaches the root element. Props interfaces extend the root element's `HTMLAttributes`, minus names the component takes for itself. |
| Blocks | A named block is a `ReactNode` prop of the block's name (`sidebar`, `main`, `banner`, `footer`); the default block is `children`. A block that yields values is a render-prop function: CanonRow's `children` may be `(titleId) => ReactNode`. |
| Icons | `icon` props are a `ReactNode` the consumer renders. `CanonIcon` turns an SVG string (lucide-static, or a `?raw` import) into its own `<svg>` element with no wrapper, so `> svg` rules in the shared CSS still match. The icons the components draw themselves (check, copy, minus, ...) are lucide-static 1.48 strings inlined in `src/lib/control-icons.tsx`, so lucide-static stays a devDependency for the demo. |
| Modifiers | `canon-press` is `press` in `lib/press.ts`, a ref callback. `canon-grab-pan` and `canon-sideways-pan` are `useGrabPan(handlers)` and `useSidewaysPan(handlers)` in `lib/pans.ts`, returning ref callbacks that call the latest handlers. The grid measuring modifier is inside `canon-grid.tsx`. Several ref callbacks combine with `useRefs` (`lib/refs.ts`); React 19 runs the cleanup a ref callback returns. |
| Yielded modifiers | A modifier a block yields (CanonPopover, CanonTooltip and CanonMenu `trigger`) is a ref callback in the render prop's argument: `trigger={(popover) => <CanonButton ref={popover.trigger} />}`, `children={(menu) => ...}`. It keeps its identity while the props it reads (`placement`) stay the same; a new placement detaches and attaches again, as the Ember modifier reruns. The panel is found by id with `panelFor`, as in Ember, because the trigger's ref runs before the panel's. |
| Latest values | Listeners set up once read props through `useLatest` (`lib/refs.ts`), a ref written in a layout effect, not during render. |
| Toast | The `canon-toast` service is `canonToast` in `lib/toast-store.ts` (`show`, `copy`, `write`, `lastPointer`), a module-level store; `CanonToast` reads it with `useSyncExternalStore`. Tests replace `canonToast.write` (`tests/helpers/clipboard.ts`). |
| Tests | Vitest 5 browser mode, provider `@vitest/browser-playwright`, launching the installed Chrome (`/Applications/Google Chrome.app`, `CHROME_PATH` overrides) headless at 1440 x 900. `tests/helpers/render.tsx` mounts with `createRoot` inside `act` and has `click`, `trigger`, `key`, `fillIn`, `wait` in the manner of `@ember/test-helpers`. The shared lib's unit tests stay at the root and are not repeated. |
| Demo | `demo/` is `demo-app/`: `demo/gallery/<group>.tsx` exports `pane`, `order` and a default component, found by `import.meta.glob` in `demo/groups.ts`, which `gallery.tsx` imports last: Vite hoists an eager glob above the other imports of its file, which put `canon-page.css` after `canon-dialog.css` and let `.canon-page > *` size the dialogs of the command group. The demo imports the root `demo-app/styles.css` and the gallery CSS files instead of copying them, and serves the root `public/` for the fonts. `bun run start --port 4311`. `demo/main.tsx` imports `styles.css` before any component, and `#root` is `display: contents`, so the cascade and the gallery's height match the Ember demo, where the stylesheet is a `<link>` ahead of the component styles and the app renders into `body`. |
| Copy gaps | The demo's copy gaps repeat the Ember demo's, one per string, in the same annotation form. |

## Deviations from the Ember behaviour

| Component | Deviation | Why |
|---|---|---|
| canon-colour-solid | The ref callback creates the `<canvas>` and prepends it to the root; React does not render it. The DOM is the same. | Under StrictMode the setup runs twice, and `Renderer.destroy()` loses the WebGL context, which leaves the same canvas unusable for the second setup. |
| canon-colour-solid | `canon-colour-solid--whole` comes from the `showsWhole` prop at render, one frame before Ember sets it at paint. | React rewrites `className` on every change and would drop a class set by hand. |
| canon-colour-solid | A space change reports the converted point through `onChange` in a microtask after the commit. | A callback during render would update the parent while it renders. |
| canon-math-key | The Ember `@key` arg is the `mathKey` prop. | React reserves `key` and strips it from props. |
| canon-math-field, canon-math-input | `CanonMathFieldHandle` has `attach(field)`, returning a detach function; the field attaches `{ edit }` in a layout effect. | The React field has no instance to assign, and assigning to a prop object fails the React hooks lint. |
| canon-math-view | The props extend `HTMLAttributes<Element>`: the root is a `<div>` when it morphs and an `<svg>` when static, as in Ember. | One props type for both roots. |
| canon-glyph-flow | The previous scene is state, recomputed during render when an input changes identity (`glyphs`, `metrics`, `measure`, `kind`, `focus`, `animated`, `equals`, `size`). A consumer keeps those props referentially stable (the demo memoises `glyphs`); a new array each render starts a new scene. | Ember kept the scene in a `@cached` getter with a side effect, which React render cannot have. |
| canon-page-strip | The long press listens through React's `onPointerDown`/`Up`/`Cancel`/`Leave` on the page button. The props omit the DOM `onSelect` and `onDrop` handlers; text-input omits `onChange`. | The Ember args use those names with other signatures. |
| canon-text-cell, canon-big-number-field, canon-text-area | The field is uncontrolled; `useShownValue` (`lib/shown-value.ts`) writes the `value` prop into it only when the prop changes. canon-text-area keeps typed text while focused, as the Ember `show` modifier did. | A controlled React input would undo typing the consumer does not send back, which the Ember one-way `value` binding does not. |
| canon-menu-cell | The `<select>` takes `value`, not `selected` on each `<option>`. | React's form of the same state. |
| canon-slider | Pointer moves apply inside `flushSync`; `dragging` is a ref. | Pointer moves arrive faster than React renders; without it a move compares against a stale value and is dropped. |
| canon-decimal-field | `apply` returns the value it sets, so an arrow step right after typing steps from the committed value. | React state is not updated until the next render. |
| canon-switch, canon-slider, canon-drop-zone | The component's own `onChange`, `onKeyDown` and `onPaste` come after the rest props and replace a consumer's handler of the same name. | Same as Ember, where the component's `{{on}}` follows `...attributes`. |
| canon-colour-controls | `CanonColourSolidState` is an interface created by `useCanonColourSolidState(initial)` in the component that owns it; writes go through `set(partial)`, `setPoint`, `use`, `selectSpace` and `pick`, which keep their identity across renders. `initial` takes `slices` and `viewPlane`. | Ember's class with `@tracked` fields has no React counterpart; the state has to live in a component. |
| canon-colour-well | The hex field is uncontrolled and commits on the native `change` event (Return or leaving the field). | React's `onChange` fires on every keystroke. |
| canon-colour-notation-input | Focus is state, so focusing and leaving the field render once more. Nothing visible changes. | React reads it during render. |
| canon-detent-wheel | The motion lives in a ref; React state holds only position, selection and row height. The `follow` modifier is an effect on `count` and `selected`. | Frames, drags and the wheel read and write the motion synchronously, as the Ember fields do. |
| canon-popover | The `<:trigger>` and `<:content>` blocks are the `trigger` and `content` props; `trigger` is a function of `{ trigger, close }`, `content` a node or a function of `{ close }`. The props omit the HTML `content` attribute. `close` finds the panel by id. | Named blocks that yield values are render props. |
| canon-tooltip, canon-menu | The default block is `children`, a function of `{ trigger }`. | Same. |
| canon-menu | `icon` in `CanonMenuEntry` is a `ReactNode`. A submenu panel anchors to the item before it, where Ember looks the item up by `data-index`; it is the same element. | The submenu's ref callback stays one module function, so a render of the parent does not reattach it. |
| canon-menu-bar | The ref callbacks that anchor each menu to its cell are memoised on the number of menus. | A new callback each render would detach and attach every menu, resetting `aria-expanded` while one is open. |
| canon-sidebar-row | `onClick` gets React's `MouseEvent`, not the DOM one; `preventDefault` works the same. The props omit the HTML `title` attribute. | React hands its own event to handlers. |
| canon-window | The `<:toolbar>`, `<:menubar>`, `<:sidebar>` and `<:main>` blocks are node props of the same names. The props omit the HTML `title` attribute. | Named blocks become props. |
| canon-dialog | `header`, `children` and `footer` are a node or a function of `close`. `showModal` and `close` run in a layout effect on `open`; the listeners are a ref callback that reads the props through `useLatest`. The block functions run inside a `react-hooks/refs` lint exception: `close` reads refs, but only when a block's handler calls it. | React has no modifier with a positional argument; the lint cannot tell a callback from a read during render. |
| canon-sheet | CanonSheet and CanonDialog both render `CanonDialogBase` (exported from `canon-dialog.tsx`), which takes `kindClasses` and `keyframes(dialog)`; Ember's CanonSheet subclasses CanonDialog and overrides `classNames` and `keyframes`. | Function components do not subclass. |
| canon-jump-grid | Renders `CanonDialogBase` with `kindClasses` `canon-dialog` and a fade for `keyframes`, where Ember subclasses CanonDialog. The props omit CanonDialog's `title`, `message`, `alert`, `dismissable` and blocks. Each tile is a local `Tile` component, so its `press` and appear ref callbacks keep their identity; the appear callback sets the `autofocus` attribute on the lit tile. | React's `autoFocus` calls `focus()` at commit, before `showModal`, and writes no attribute, so `showModal` would focus the first tile. |
| canon-jump-heading | The lit index is state beside the sections; the headings found on open are a ref. Every open lights the group then in view; the Ember component lights the first open's group again on later opens. | Ember's `current` is an untracked field, and Glimmer caches the first value it read. |
| canon-command | The field is controlled (`value` from state, `onChange`), since the component owns the query. | React's form of the one-way binding plus the `input` listener. |

## Tracker

Tick when the component renders in the demo, has its test, and passes lint.

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
| [x] | canon-colour-solid | Canvas created in the ref callback, see Deviations. |
| [x] | canon-colour-strip | |
| [x] | canon-colour-well | |
| [x] | canon-command | |
| [x] | canon-compression-scale | Each bar's label placement is a ref callback on the share and the label text. |
| [x] | canon-context-menu | |
| [x] | canon-decimal-field | |
| [x] | canon-detent-wheel-row | No Ember test; covered by the canon-detent-wheel test. |
| [x] | canon-detent-wheel | |
| [x] | canon-dialog | |
| [x] | canon-dimension-line | |
| [x] | canon-drop-zone | |
| [x] | canon-dual-list | |
| [x] | canon-empty-row | |
| [x] | canon-figure | |
| [x] | canon-file-cell | |
| [x] | canon-from-to | |
| [x] | canon-glyph-flow | |
| [x] | canon-grid | |
| [x] | canon-heading | |
| [x] | canon-icon | No Ember test; covered through the components that draw icons. |
| [x] | canon-image-compare | |
| [x] | canon-jump-grid | Renders `CanonDialogBase`, see Deviations. |
| [x] | canon-jump-heading | |
| [x] | canon-lamps | |
| [x] | canon-loader | |
| [x] | canon-loupe | |
| [x] | canon-math-editor | |
| [x] | canon-math-field | |
| [x] | canon-math-input | Covered by the canon-math-field test, as in Ember. |
| [x] | canon-math-key | `@key` is `mathKey`. |
| [x] | canon-math-keypad | |
| [x] | canon-math-rail | |
| [x] | canon-math-tabs | Covered by the canon-math-keypad test, as in Ember. |
| [x] | canon-math-view | |
| [x] | canon-menu | `CanonMenuList` and `showMenu` are exported beside it. |
| [x] | canon-menu-bar | |
| [x] | canon-menu-cell | |
| [x] | canon-number-field | |
| [x] | canon-page-strip | |
| [x] | canon-page | |
| [x] | canon-palette-card | |
| [x] | canon-popover | |
| [x] | canon-preview-panel | |
| [x] | canon-readout-band | |
| [x] | canon-row | |
| [x] | canon-rows | |
| [x] | canon-rule | |
| [x] | canon-segmented | |
| [x] | canon-sheet | Renders `CanonDialogBase`, see Deviations. |
| [x] | canon-sidebar | |
| [x] | canon-sidebar-row | |
| [x] | canon-slider | |
| [x] | canon-split | Refits a collapsing picture on a new `data-canon-aspect` or `data-canon-height`, as Ember. |
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
