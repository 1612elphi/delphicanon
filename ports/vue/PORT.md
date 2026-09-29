# Port: Canon components to Vue

The Ember addon in `../../src` is the reference; its `PORT.md` holds the decisions behind the components. This file lists what changes in Vue.

## Decisions

| Topic | Decision |
|---|---|
| Stack | Vue 3.5 single-file components, `<script setup lang="ts">`, `defineProps` with a type literal. Vite with `@vitejs/plugin-vue`; `vue-tsc` checks types. |
| Files | `src/components/canon-<name>.vue`, one per Ember component, same name. Port-local helpers in `src/lib/`. Each component imports `@canon/styles/tokens.css` and `@canon/components/canon-<name>.css`; shared logic comes from `@canon/lib/<file>.ts`. The alias `@canon` is `../../src`. |
| Callbacks | Ember's `@onChange` style args stay function props with the same names (`onChange`, `onClick`, `onSelect`, ...), declared in `defineProps`. Vue maps a listener to a declared `on*` prop, so a consumer writes either `:on-change="fn"` or `@change="fn"`. There is no `defineEmits`: several callbacks return a value (`grabs`, `menu`, `parse`) and the three ports keep one prop list. |
| Args | Ember args are props with the same names. Vue casts an absent boolean prop to `false`; where `undefined` means something else the prop sets `default: undefined` through `withDefaults`. |
| Blocks | Named blocks are named slots (`#sidebar`, `#main`, `#banner`, `#footer`, ...); the default block is the default slot; a block that yields values is a scoped slot with the yielded values as named slot props (CanonRow: `v-slot="{ titleId }"`). `has-block` is `$slots.<name>`. |
| Attributes | `...attributes` is Vue's attribute fallthrough to the root element. A component with more than one root (CanonToast) sets `inheritAttrs: false` and binds `$attrs` where Ember put `...attributes`. |
| Icons | An `icon` prop takes a Vue component the consumer renders. CanonIcon draws an SVG string as an `<svg>` element with the string's attributes and children, no wrapper, so the shared `> svg` rules apply. The lucide icons the components draw themselves are inlined in `src/lib/lucide.ts` (lucide-static 1.48.0, ISC), so `vue` is the only runtime dependency. `src/lib/control-icons.ts` is the port of `control-icons.gts` as functional components. |
| Modifiers | `canon-press`, `canon-grab-pan` and `canon-sideways-pan` are directives: `v-press` (`lib/press.ts`), `v-grab-pan="handlers"` (`lib/grab-pan.ts`), `v-sideways-pan="handlers"` (`lib/sideways-pan.ts`), built on `lib/directive.ts`, which reads the latest binding value on every event. A modifier private to one component becomes `onMounted` / `watch` on a template ref in that component. |
| Yielded modifiers | A block that yields a modifier (CanonPopover, CanonTooltip and CanonMenu `trigger`) yields a function template ref as a slot prop, bound with `:ref="trigger"` on an element or a single-root component (`lib/trigger.ts` takes the component's `$el`). Vue calls a function ref during the patch, before the panel beside the trigger mounts, so the ref only stores the element; the component attaches in a post-flush watch on that element, its own panel ref and `placement`, and the watch cleanup detaches. These components have two roots, so they set `inheritAttrs: false` and bind `$attrs` on the panel, where Ember put `...attributes`. |
| Menu list | There is no `canon-menu-list.vue`: CanonMenu without a default slot is the bare panel that Ember exports as CanonMenuList, with the list's `onEdge` and `sub` props beside CanonMenu's; `showMenu` is exported from its plain script block. A separate list file would import `canon-menu.css`, which the registry files under the item `canon-menu`, and `canon-menu` would import the list back: `registry/build.ts` rejects that cycle. Submenus render CanonMenu recursively. The parent anchors its submenus, and CanonMenuBar its menus, in `onMounted` and a post-flush watch on the submenu ids or the menu count, in place of a modifier on each list. |
| Toast | The `canon-toast` service is `toast` in `lib/toast-store.ts`, a module-level `reactive` object with `show`, `copy` and a replaceable `write`. CanonToast is the outlet; render it once. |
| Math editing | `lib/math-editing.ts` is `MathEditing` with its version in a `shallowRef`; the instance is `markRaw`. |
| Demo | `demo/` is the gallery (Vite root). Groups are `demo/components/gallery/<group>.vue` with `pane` and `order` exported from a plain `<script>` block, found by `import.meta.glob`. The demo's own stylesheets are imported from `../../demo-app/`; fonts come from the root `public/`. Same query parameters as the Ember demo. |
| Whitespace | Vue's template compiler condenses whitespace between elements, so text content has no space between sibling elements where Glimmer kept one. Every place this touches is a flex or grid container, so the rendered page is the same; three tests compare normalised `innerText` instead of text content. |
| Reserved names | `key` is reserved in Vue, so CanonMathKey's `@key` is `mathKey`. A module-level name in a plain `<script>` block is visible to the template and hides a prop of the same name; internal functions that would share a prop's name are renamed (`nudge`, `parseText`). |
| Tests | Vitest 5 browser mode, `@vitest/browser-playwright`, launching the installed Chrome (`CHROME_PATH` overrides), viewport 1280 x 800. `tests/helpers/render.ts` mounts an inline template with the runtime compiler (tests alias `vue` to the full build) and has the `@ember/test-helpers` equivalents (`click` sends mousedown, focus, mouseup, click, as Ember's does). Assertions use the jest-dom matchers Vitest's browser mode adds to `expect`. |

## Mapping

Tick when the component renders in the gallery, has its test, and passes lint.

| Tick | Ember component | Vue | Notes |
|---|---|---|---|
| [x] | canon-bar | `canon-bar.vue` | |
| [x] | canon-big-number-field | `canon-big-number-field.vue` | |
| [x] | canon-button | `canon-button.vue` | |
| [x] | canon-canvas | `canon-canvas.vue` | |
| [x] | canon-code-block | `canon-code-block.vue` | |
| [x] | canon-colour-card | `canon-colour-card.vue` | |
| [x] | canon-colour-controls | `canon-colour-controls.vue` | `CanonColourSolidState` is a class exported from the plain script block; its constructor returns `shallowReactive(this)`, the depth of `@tracked`. The controls write the shared state (`vue/no-mutating-props` off for this file, as in Ember). The slider's touch modifier is a local `v-touch` directive. |
| [x] | canon-colour-notation-input | `canon-colour-notation-input.vue` | The local parse function is `parseText`, since `parse` is a prop. |
| [x] | canon-colour-solid | `canon-colour-solid.vue` | No gallery group; the colour page uses it. `cutsAway` and `animated` default to `undefined` (`cutsAway` undefined means true). The first sync of the renderer runs in setup, before mount; the mount paint draws the synced state. |
| [x] | canon-colour-strip | `canon-colour-strip.vue` | |
| [x] | canon-colour-well | `canon-colour-well.vue` | |
| [x] | canon-command | `canon-command.vue` | `CanonCommandItem` exported. |
| [x] | canon-compression-scale | `canon-compression-scale.vue` | The two bars are a `v-for` in the one file, with a local `v-place` directive for the label, so the registry sees no second component file. |
| [x] | canon-context-menu | `canon-context-menu.vue` | The setup is `onMounted` on the anchor span; the panel is the span's next element. |
| [x] | canon-decimal-field | `canon-decimal-field.vue` | `typingPauseMs` is exported from a plain script block. The internal step function is `nudge`, since `step` is a prop. |
| [x] | canon-detent-wheel | `canon-detent-wheel.vue` | Rows are the default slot with props `{ index, focus }`. `follow` runs in a watcher without Ember's `queueMicrotask`, which only kept tracked writes out of render. |
| [x] | canon-detent-wheel-row | `canon-detent-wheel-row.vue` | No test of its own, as in Ember; the detent-wheel test covers it. |
| [x] | canon-dialog | `canon-dialog.vue` | `dismissable` defaults to undefined, so an absent prop dismisses (tested). The blocks are slots with `{ close }`. The present modifier is `onMounted` and a post-flush watch on `open`; the listeners are template listeners on the `<dialog>`. Extra prop `keyframes(dialog)` for CanonSheet, which Ember overrides in a subclass; the internal function is `frames`, since `keyframes` is a prop. |
| [x] | canon-dimension-line | `canon-dimension-line.vue` | |
| [x] | canon-drop-zone | `canon-drop-zone.vue` | `paste` defaults to undefined, so an absent prop shows Paste (tested). |
| [x] | canon-dual-list | `canon-dual-list.vue` | `CanonDualItem` is exported from a plain script block; ids from `useId()`. |
| [x] | canon-empty-row | `canon-empty-row.vue` | |
| [x] | canon-figure | `canon-figure.vue` | `animated` defaults to undefined. The roll is a post-flush watch on the template ref, the text and `animated`. |
| [x] | canon-file-cell | `canon-file-cell.vue` | |
| [x] | canon-from-to | `canon-from-to.vue` | |
| [x] | canon-glyph-flow | `canon-glyph-flow.vue` | Generic over the glyph type (`generic="G"`). `animated` defaults to undefined, so absent means animated (tested). Glide and fade are local directives; ghosts are keyed per scene so each fades from its own start. The scene is a `computed` that writes the animation memory, as Ember's `@cached` getter does. |
| [x] | canon-grid | `canon-grid.vue` | `place()` skips `[popover]` children, as in Ember. |
| [x] | canon-heading | `canon-heading.vue` | |
| [x] | canon-icon | `canon-icon.vue` | No test of its own, as in Ember; every icon test covers it. |
| [x] | canon-image-compare | `canon-image-compare.vue` | `v-sideways-pan`. |
| [x] | canon-jump-grid | `canon-jump-grid.vue` | Wraps CanonDialog with a fade as `keyframes`, as CanonSheet does, where Ember subclasses it; class and `aria-label` fall through to the `<dialog>`. `CanonJumpSection` exported. The appear and measure modifiers are local directives on `elementDirective`; the appear runs once per tile, when it mounts, where the Ember modifier runs again when its index, count or current change. |
| [x] | canon-jump-heading | `canon-jump-heading.vue` | Two roots, so `inheritAttrs: false` and `$attrs` on the `<h3>`. The lit index is a `shallowRef`, so every open lights the group then in view; the Ember component lights the first open's group again on later opens, since its `current` is an untracked field that Glimmer caches. |
| [x] | canon-lamps | `canon-lamps.vue` | The blink is reactive state set by a watch on the flash counts: Vue's class patch would drop a class added by hand. Same 120 ms timing. |
| [x] | canon-loader | `canon-loader.vue` | `CanonLoaderMode` exported. |
| [x] | canon-loupe | `canon-loupe.vue` | |
| [x] | canon-math-editor | `canon-math-editor.vue` | |
| [x] | canon-math-field | `canon-math-field.vue` | `CanonMathFieldHandle` is exported from the plain script block; `handle.field` holds `{ edit }` instead of the component. |
| [x] | canon-math-input | `canon-math-input.vue` | Covered by the canon-math-field test, as in Ember. |
| [x] | canon-math-key | `canon-math-key.vue` | `@key` is the prop `mathKey`: Vue never passes `key` to a component. |
| [x] | canon-math-keypad | `canon-math-keypad.vue` | |
| [x] | canon-math-rail | `canon-math-rail.vue` | |
| [x] | canon-math-tabs | `canon-math-tabs.vue` | Covered by the canon-math-keypad test, as in Ember. |
| [x] | canon-math-view | `canon-math-view.vue` | `inheritAttrs: false`; a consumer's `style` replaces the morph's `min-block-size`, as after Ember's `...attributes`. |
| [x] | canon-menu | `canon-menu.vue` | Also CanonMenuList, see Menu list. `CanonMenuEntry` and `CanonMenuItem` exported with `Component` icons. |
| [x] | canon-menu-bar | `canon-menu-bar.vue` | `CanonMenuBarMenu` exported. Cell listeners fall through CanonButton to its `<button>`. |
| [x] | canon-menu-cell | `canon-menu-cell.vue` | |
| [x] | canon-number-field | `canon-number-field.vue` | |
| [x] | canon-page | `canon-page.vue` | |
| [x] | canon-page-strip | `canon-page-strip.vue` | The long press listens with `@pointerdown` and the rest on the button, in place of the modifier. |
| [x] | canon-palette-card | `canon-palette-card.vue` | |
| [x] | canon-popover | `canon-popover.vue` | `#trigger="{ trigger, close }"`, `#content="{ close }"`. |
| [x] | canon-preview-panel | `canon-preview-panel.vue` | |
| [x] | canon-readout-band | `canon-readout-band.vue` | The default slot takes `v-slot="{ playhead }"`. |
| [x] | canon-row | `canon-row.vue` | |
| [x] | canon-rows | `canon-rows.vue` | |
| [x] | canon-rule | `canon-rule.vue` | |
| [x] | canon-segmented | `canon-segmented.vue` | |
| [x] | canon-sheet | `canon-sheet.vue` | Wraps CanonDialog instead of extending it: passes the edge classes through class fallthrough, the slide as `keyframes`, and forwards the three slots. `dismissable` defaults to undefined (tested through Escape). |
| [x] | canon-sidebar | `canon-sidebar.vue` | `collapsed` defaults to undefined, so an absent prop follows the window's width (tested). |
| [x] | canon-sidebar-row | `canon-sidebar-row.vue` | `CanonSidebarLight` exported. |
| [x] | canon-slider | `canon-slider.vue` | The drag modifier is `onMounted` listeners on template refs. |
| [x] | canon-split | `canon-split.vue` | Refits a collapsing picture on a new `data-canon-aspect` or `data-canon-height`, as Ember. |
| [x] | canon-status | `canon-status.vue` | `CanonStatusTone` exported. |
| [x] | canon-stepper | `canon-stepper.vue` | |
| [x] | canon-swatch | `canon-swatch.vue` | |
| [x] | canon-switch | `canon-switch.vue` | `on` defaults to undefined. |
| [x] | canon-text-area | `canon-text-area.vue` | The echo guard is a post-flush watch on the ref and `value`. |
| [x] | canon-text-cell | `canon-text-cell.vue` | |
| [x] | canon-text-input | `canon-text-input.vue` | `setText` is exposed through `defineExpose`. |
| [x] | canon-text-output | `canon-text-output.vue` | The slot fallback is the text, as `has-block` did. |
| [x] | canon-tiles | `canon-tiles.vue` | |
| [x] | canon-timecode | `canon-timecode.vue` | `seconds` and `text` default to undefined, so null and undefined stay different. |
| [x] | canon-toast | `canon-toast.vue` | |
| [x] | canon-tooltip | `canon-tooltip.vue` | `v-slot="{ trigger }"`; `tooltipGraceMs` exported from the plain script block. |
| [x] | canon-value-line | `canon-value-line.vue` | The fade is a post-flush watch on the shown value. |
| [x] | canon-window | `canon-window.vue` | |
