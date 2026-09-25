# Port: Canon components to Glimmer

Source: `~/GitRepos/delphitools-ios/delphitools/delphitools/Core/Canon/*.swift` at commit `4628b8d`.
Read it with `git -C ~/GitRepos/delphitools-ios show 4628b8d:<path>`; the working tree of that repo is off limits for edits (a parallel session refactors `Core/Canon`).
Reference for behaviour: `CANON.md` and `Features/Debug/CanonGalleryViewController.swift` in the same repo, same commit.
Reference for web conventions: `~/GitRepos/delphitools` (Ember 7.1, `.gts`, Vite) and its `DESIGN.md`.

## Decisions

| Topic | Decision |
|---|---|
| Package | `delphicanon`, an Ember v2 addon (current `@ember/addon-blueprint`), TypeScript, `.gts` strict mode, Glint. A demo app in the same repo holds the gallery. |
| Names | One Swift class, one component, same name: `CanonButton` in `src/components/canon-button.gts`. Helpers and pure logic in `src/lib/`. Modifiers in `src/modifiers/`. |
| Styling | Plain CSS, one co-located file per component, imported by the component. Tokens as `--canon-*` custom properties in `src/styles/tokens.css`, values from the iOS asset catalog (`delphi*.colorset`). Dark mode under both `prefers-color-scheme: dark` and `html.dark`, matching the web app. No crayon, no SCSS. |
| Units | 1 pt = 1 CSS px. Rows 52, flush controls 44, primary button 68, secondary 60. |
| API | UIKit properties become args; `.valueChanged` / closures become `@onChange` style callback args; internal state is `@tracked`. Section lists become named blocks (`<:sidebar>`, `<:main>`, `<:banner>`, `<:footer>`). |
| Layout | Size classes become container queries on the component, never viewport width or UA sniffing. The Duo crease becomes `@media (horizontal-viewport-segments: 2)` / `env(viewport-segment-*)`, the laptop pose `device-posture: folded` (Chromium only, progressive). |
| Platform swaps | Metal becomes WebGL2 with the same maths. `UIColorPickerViewController` becomes `<input type=color>`. The system menu becomes a native `<select>`. Photos and Files become `<input type=file>`, drag and drop, paste. Sheets become `<dialog>` or the popover API. Gesture recognisers become modifiers on pointer events with `touch-action`. |
| Dropped | Haptics. `CanonSelfCheck`. UIKit extensions on `UILabel`, `UIColor`, `UIResponder`. Mac-only components listed in CANON.md. |
| Copy | Clipboard through `navigator.clipboard.writeText`, confirmed by `CanonToast` (a service plus one outlet component, ARIA live region). |
| Privacy | No network calls in any component. No new runtime dependency without a line in this file saying why. |
| Tests | One QUnit rendering test per component. Unit tests for pure logic (maths parser and typesetter, glyph row layout, colour conversion). |
| Git | Local repo, no remote. Each parallel agent works in `~/GitRepos/delphicanon-wt/<group>` on branch `port/<group>`; the coordinator merges into `main`. |

## Phase A changes to the decisions

| Topic | Change | Why |
|---|---|---|
| Row stacking | CanonRow uses a wrapping flex line, not a container query. The label grows 999 times faster than the control, so a side-by-side control keeps its width and a wrapped one fills its line. `sizingTitle` is a hidden copy of the longest title inside the label. | The break point is the label's width plus the control's width, which a container query cannot know. |
| Text sizes | `--canon-text-*` tokens are the iOS text styles scaled down (body 15, subheadline 13, footnote 12, caption 11). Geometry stays 1 pt = 1 px. | iA Writer Quattro is about a third wider than SF Condensed; at the iOS sizes segment titles truncated at the 340 px sidebar. |
| Press motion | `lib/motion.ts` and the `canon-press` modifier exist from phase A with the press tilt, spring and constants. The display group adds the pan modifiers to the same file. | Every button presses; CanonButton needed it. |
| Grid measuring | CanonGrid places spans and drops titles to symbols with a small modifier (MutationObserver, ResizeObserver, canvas `measureText`). | Balanced rows and "any title does not fit" depend on the cell count and text widths. |
| Copy | `canonCopy` is the service method `copy(text)`; it shows the toast only after `navigator.clipboard.writeText` resolves. Tests replace `service.write`. | A toast after a failed write would say Copied when nothing was copied. |
| Pattern | The consumer sets `--canon-pattern` (from `canonPatternTile(svg)`) on an ancestor, standing in for the `CanonPatternSymbol` trait. Canvases draw it as a mask in the foreground colour at 4 %. | A mask follows the theme; a baked image would not. |
| Not ported | `CanonActionBar` alias (use CanonGrid), `CanonPaddedSection` (a CSS rule in `canon-page.css`), `setCanonSectionHidden` (render conditionally), status bar bleed under a page (web pages start below the app's own header), menu-as-primary-action press handling (goes with CanonMenuCell). | No web counterpart, or it belongs to a later group. |
| Demo only | `lucide-static` (gallery icons) and `puppeteer-core` (`bun run shot`) are devDependencies, not runtime ones. | The gallery needs symbols; the addon takes icons as components. Screenshots check the gallery headlessly. |
| Readout text | CanonTimecode takes `seconds` or `text` (the `show(text:)` path) as args; FluoWrite is `--canon-segment-font`, the consumer supplies the `@font-face` (the demo loads the iOS .otf from `public/fonts`). | Args replace the imperative `show`; the addon ships no fonts. |
| Lamp blink | CanonLamps takes `flashes`, a count per lamp; a change blinks that lamp for 0.12 s. CanonReadoutBand passes `transport.loops`. | `flash(_:)` is imperative; a counter keeps it arg-driven. |
| Page strip | Pages are args; `onMove` reports a move and the consumer reorders `pages`. Pictures are URLs, placed and turned in CSS. The long-press menu is a popover opened by `contextmenu` or a 500 ms touch press; `menu` returns `{ title, action, destructive }` items. Reorder by keyboard: Alt and the arrow keys. | No UICollectionView or UIMenu; a native `<select>` cannot hold per-page actions. |
| Canvas top inset | `canvasTopInset` (CanonCanvasContent) is not ported for CanonPageStrip or CanonGlyphFlow. | Follows the phase A status bar decision. |
| Glyph flow | Glyphs are absolutely placed elements painted by the default block (`glyph`, index or null for a fading glyph); the slide, grow and fade run on the Web Animations API with the iOS curves. Removed glyphs render once more as fading ghosts. `<:empty>` stands for `paintEmpty`. | No CGContext drawing. |
| Copy in code block and text output | CanonCodeBlock and CanonTextOutput write through `canon-toast`'s `write` and confirm in place (check icon, Copied flash), without the toast, as on iOS. Share uses `navigator.share` (a file where `canShare` allows, else text) and downloads the file where there is no share sheet. | iOS confirms these two in place, not with CanonToast. |
| Middle truncation | Tile values and page names truncate at the end. | CSS has no middle truncation. |
| Solid args | `setPoint(_:animated:)` is a change of `@point` with `@animated`; `setVision(_:animated:)` is `@vision` (rows), which eases on every change after the first render. `colour` is not an arg: `colourAt(space, point)` and `pointFor(space, colour)` convert. `yaw` and `pitch` are not args. There is no `onPick`: the Swift sends only `.valueChanged`, which is `@onChange(point, colour)`. `@closestName` stands in for `ColourNames.closest` in the value read out. | Args are data; the colour name set stays out of the addon. |
| Solid space change | A new `@space` with an unchanged `@point` converts the pick, as the Swift setter does, and reports it through `@onChange`. | The parent owns the point and would otherwise hold it in the old space's units. |
| Solid input | `touch-action: none` covers the whole solid, so a touch that starts off the solid does not scroll the page (CanonGrabPan let it). Arrow keys turn the solid (not in ortho with a slice, where drags pick); the pick is read from a polite live `<output>`. Axis letters behind the camera hide instead of keeping their last place. The WebGL context keeps its drawing buffer so tests read pixels. | Web input and assistive technology; the task asked for `touch-action: none`. |
| Unverified | The crease (`horizontal-viewport-segments`) and laptop (`device-posture: folded`) rules have no test and were not seen on a device. | No dual-screen browser available. |
| Colour state | CanonColourControls takes one `@state`, a `CanonColourSolidState` (exported from `canon-colour-controls.gts`) holding `space`, `point`, `animated`, `activeRow`, `slices`, `viewPlane`, `showsWhole`, with getters `colour`, `sliceAxis`, `isOrtho` and a `pick(point)` callback. The consumer passes `space`, `point`, `animated`, `sliceAxis`, `isOrtho` and `showsWhole` to canon-colour-solid and `pick` as its `@onChange`. A new space changes only `state.space`; the solid converts the point and reports it through `pick`. `cutsAway`, `marks` and `vision` stay with the consumer, as the Swift controls never set them. | The Swift controls held the solid and set its properties, and `solid.space` converted the point; a Glimmer component cannot set another's args. |
| Colour spaces | One Space table, `lib/colour-space.ts` (`SolidSpace`, `solidSpaces`, `spaceNames`, `channels`, `isCartesian`, `colourAt`, `pointFor`, `convertPoint`, reaches), on the conversions in `lib/colour.ts`. The solid keeps only its shader numbers and radii (`lib/colour-solid/solid.ts`). One `Rgb`, the tuple from `lib/colour.ts`, for the solid too. | The colour and solid groups each wrote a copy in parallel. |
| Colour formats | The app's primary and secondary colour format settings are args (`format`, `primaryFormat`, `secondaryFormat`), default hex and rgb. Nearest name is `nameOf(hex)`. | The addon has no settings store and no name dataset. |
| Colour not ported | `CanonColourStrip.placed(under:)` (the consumer stacks picture and strip in one CanonCanvas); CanonCopyFeedback (the `canon-toast` service's `copy` covers it). | Safe area and page fade have no web counterpart. |
| Controls: menu | CanonMenuCell is a styled cell with a native `<select>` laid invisibly over it; it has no press tilt. CanonFromTo reports `@onFromChange` and `@onToChange`. | The native picker takes the pointer, so a release would not arrive. |
| Controls: files | CanonFileCell and CanonDropZone take `@accept` and hand over `File` objects, no Photos and no temporary copies. `onImages` gets `ImageBitmap`s (EXIF orientation applied) and the file stems as a second argument, empty after a paste; Paste reads `navigator.clipboard.read()`, and a paste event inside the zone imports too. CanonFileCell has no `clear()`: re-render it. | Web file access; `imageNames` as state has no use once the names travel with the images. |
| Controls: loader | CanonLoader is the web nds-loader's CSS keyframes, not a timer; its colour is the CSS `color`. | Same table of steps, no JavaScript. |
| Controls: fields | CanonDecimalField's `show(value, range)` is `@value`, `@min`, `@max`, default 0 to no bound (no lower bound when signed). The stepper has no `insets` argument. Number and decimal fields step with the arrow keys too. Composite controls take `@labelledBy` or `@label` for their field. | Args instead of a method; keyboard access. |
| Controls: slider | CanonSlider's `@onChange` gets `(value, dragging)`, standing in for `isDragging`; it has no touch-down event, so CanonColourControls listens for `pointerdown` on it to pick the row and show the whole solid. | Args and callbacks instead of UIControl events. |
| Controls: figure | CanonFigure rolls changed characters, compared from the end, with the Web Animations API; no minimum scale factor and no Dynamic Type scaling. | No numeric text transition on the web. |
| Controls: switch grid | `CanonGrid.switches` is not a component: a CanonGrid of CanonRows with `@sizingTitle` and a CanonSwitch each, as in the controls gallery. | CanonGrid and CanonRow cover it. |
| Controls: unverified | CanonSwitch uses the 51 x 31 UISwitch geometry; the iOS 26 switch is wider and was not compared. | No simulator in this pass. |
| Colour page | The demo's `?page=colour` is CanonColourGalleryViewController: the solid over its strip in the split's banner (collapsing to 240 in one column), the controls with View, Strip palette and Deuteranopia in the sidebar, cards and palettes in the main pane. `?colourSpace`, `?colourRow`, `?colourView` stand for the iOS launch arguments. The solid gallery group is gone; the wells stay on the main page. | iOS puts the solid in a halves sidebar and the controls in the main pane; here the controls sit in the sidebar and the solid spans the top. The four-matrix vision picker of the solid group is the one Deuteranopia switch, as on iOS. |

## Phases

A. Scaffold and foundation, one agent, sequential. Blocks everything else.
B. Five groups in parallel worktrees: controls, display, colour, colour-solid, math.
C. After the parallel session merges its Canon additions: port the new and changed files.
D. Merge, lint, test, gallery check in a browser.

## Mapping

Tick when the component renders in the gallery, has its test, and passes lint.

| Tick | Group | Swift source | Glimmer | Notes |
|---|---|---|---|---|
| [x] | A | CanonLayout: CanonRule, CanonRows, CanonRow, CanonHeading, CanonEmptyRow, CanonGrid, CanonPage, CanonPaddedSection, CanonBar | canon-rule, canon-rows, canon-row, canon-heading, canon-empty-row, canon-grid, canon-page, canon-bar, `lib/grid.ts` | Row: plain, flush, stacked; control drops below label when narrow (container query). Grid sizes columns to the longest row. |
| [x] | A | CanonControls: CanonButton, CanonSegmented | canon-button, canon-segmented, modifier `canon-press`, `lib/motion.ts` (press only) | Kinds primary, secondary, cell, segment; `icon: oversized`; symbol-only when narrow. Icons via an `@icon` arg the consumer renders (lucide in the web app). |
| [x] | A | CanonCanvas | canon-canvas, `lib/pattern.ts` | `.fixed`, `.aspect`, `maxHeight`, `boxing`, pattern background. |
| [x] | A | CanonSplit | canon-split | Sidebar 340, one column under 640, `halves`, `bannerSticks`, `mainLeadsStacked`, `collapsesTo`, footer strip. Crease behaviour per Decisions. |
| [x] | A | CanonToast, CanonCopyFeedback | canon-toast, service `canon-toast` (`show`, `copy`), `lib/toast.ts` | 1.4 s, fade, bottom of the column. |
| [x] | B controls | CanonControls: CanonSwitch, CanonStatus, CanonTextCell, CanonStepper, CanonNumberField, CanonSlider | canon-switch, canon-status, canon-text-cell, canon-stepper, canon-number-field, canon-slider | Stepper repeats while held. |
| [x] | B controls | CanonDecimalField, CanonTextArea, CanonMenuCell, CanonFromTo, CanonLoader, CanonFigure, CanonDualList, CanonFileCell, CanonDropZone | canon-decimal-field, canon-text-area, canon-menu-cell, canon-from-to, canon-loader, canon-figure, canon-dual-list, canon-file-cell, canon-drop-zone | Loader: compare the web app's `ui/nds-loader.gts`. |
| [x] | B display | CanonClassics: CanonPreviewPanel, CanonCodeBlock | canon-preview-panel, canon-code-block | |
| [x] | B display | CanonTiles, CanonImageCompare, CanonPageStrip, CanonReadout (CanonTimecode, CanonLamps, CanonTransport, CanonReadoutBand) | canon-tiles, canon-image-compare, canon-page-strip, canon-timecode, canon-lamps, canon-readout-band, `lib/timecode.ts` | PageStrip reorder: native drag and drop, Alt and the arrow keys. |
| [x] | B display | CanonGlyphFlow (CanonGlyphRows, CanonTextInput, CanonTextOutput) | canon-glyph-flow, canon-text-input, canon-text-output, `lib/glyph-rows.ts` | Glyph painting through a block. |
| [x] | B display | CanonMotion (CanonGrabPan, CanonSidewaysPan, motion constants) | modifiers `canon-grab-pan`, `canon-sideways-pan`, add to `lib/motion.ts` | |
| [x] | B colour | CanonClassics: CanonColourWell; CanonColourCards (CanonColourCard, CanonValueLine, CanonColourStrip, CanonSwatch, CanonPaletteCard) | canon-colour-well, canon-colour-card, canon-value-line, canon-colour-strip, canon-swatch, canon-palette-card, `lib/colour.ts` | Nearest colour name is an arg (a function), so the addon carries no name dataset. |
| [x] | B colour | CanonColourControls | canon-colour-controls, `lib/colour-space.ts` | Drives canon-colour-solid through a shared state; canon-slider, canon-switch and canon-text-cell rows. |
| [x] | B solid | CanonColourSolid | canon-colour-solid, `lib/colour-solid/*` (geometry, view, solid, shader, vec) | Metal to WebGL2. Every solid, slice, ortho unroll, marks, vision matrix. Args: `space`, `point`, `animated`, `sliceAxis`, `isOrtho`, `showsWhole`, `cutsAway`, `marks`, `vision`, `onChange`, `closestName`. Space table from `lib/colour-space.ts`. |
| [ ] | B math | CanonMath (typesetter, CanonMathView, CanonMathMorph) | canon-math-view, `lib/math/*` | Typeset to HTML/CSS. Morph with the Web Animations API. |
| [ ] | B math | CanonMathInput (CanonMathExpression, CanonMathEditor, CanonMathField, CanonMathInputViewController, CanonPaneSheetPresentation) | canon-math-field, canon-math-editor, `lib/math/expression.ts` | Keypad sheet as `<dialog>` docked to the field's pane on wide containers. Reads and writes nerdamer syntax. |
| [ ] | B math | CanonMathKeypad (families, keys, submenu, rail, tabs) | canon-math-keypad, canon-math-key, canon-math-rail, canon-math-tabs | Braun ET66 family colours as tokens. |
| [ ] | C | CanonColourNotationInput.swift (new) | canon-colour-notation-input | Notation cell with eyedropper, injectable `parse`; CanonColourControls' notation row uses it. |
| [ ] | C | CanonDetentWheel.swift (new): CanonDetentWheel, CanonDetentWheelRow | canon-detent-wheel, canon-detent-wheel-row | Detent drum, friction, spring catch, selection tick per row. |
| [ ] | C | CanonLoupe.swift (new) | canon-loupe, `lib/loupe.ts` for `frame(near:side:gap:in:top:sides:)` | Unsmoothed pixels (`image-rendering: pixelated`), framed in the sampled colour. |
| [ ] | C | CanonColourCards.swift: CanonValueLine `layout` (`beside(labelWidth)`, `above`, `wrapping`, `numbered(wraps)`), `show(_:_:fadeDelay:)` with nil as a dash, `isLit`, `tint`, `isEnabled` | canon-value-line | Changes to the colour group's port. |
| [ ] | C | CanonDecimalField.swift: CanonBigNumberField (new) | canon-big-number-field | After the controls group merges. |
| [ ] | C | CanonCanvas.swift: `Size.fitting`, `canvasFittingHeight`, `refit(animated:)`, `band(fitting:)` | canon-canvas | Height from content for the width. |
