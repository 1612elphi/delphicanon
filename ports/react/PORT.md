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
| Latest values | Listeners set up once read props through `useLatest` (`lib/refs.ts`), a ref written in a layout effect, not during render. |
| Toast | The `canon-toast` service is `canonToast` in `lib/toast-store.ts` (`show`, `copy`, `write`, `lastPointer`), a module-level store; `CanonToast` reads it with `useSyncExternalStore`. Tests replace `canonToast.write` (`tests/helpers/clipboard.ts`). |
| Tests | Vitest 5 browser mode, provider `@vitest/browser-playwright`, launching the installed Chrome (`/Applications/Google Chrome.app`, `CHROME_PATH` overrides) headless at 1440 x 900. `tests/helpers/render.tsx` mounts with `createRoot` inside `act` and has `click`, `trigger`, `key`, `fillIn`, `wait` in the manner of `@ember/test-helpers`. The shared lib's unit tests stay at the root and are not repeated. |
| Demo | `demo/` is `demo-app/`: `demo/gallery/<group>.tsx` exports `pane`, `order` and a default component, found by `import.meta.glob`. The demo imports the root `demo-app/styles.css` and the gallery CSS files instead of copying them, and serves the root `public/` for the fonts. `bun run start --port 4311`. |
| Copy gaps | The demo's copy gaps repeat the Ember demo's, one per string, in the same annotation form. |

## Deviations from the Ember behaviour

| Component | Deviation | Why |
|---|---|---|

## Tracker

Tick when the component renders in the demo, has its test, and passes lint.

| Tick | Component | Notes |
|---|---|---|
| [ ] | canon-bar | |
| [ ] | canon-big-number-field | |
| [x] | canon-button | |
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
