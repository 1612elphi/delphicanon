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
| Solid args | `setPoint(_:animated:)` is a change of `@point` with `@animated`; `setVision(_:animated:)` is `@vision` (rows), which eases on every change after the first render. `colour` is not an arg: `colourAt(space, point)` and `pointFor(space, colour)` convert. `yaw` and `pitch` are not args. There is no `onPick`: the Swift sends only `.valueChanged`, which is `@onChange(point, colour)`. `@closestName` stands in for `ColourNames.closest` in the value read out. | Args are data; the colour name set stays out of the addon. |
| Solid space change | A new `@space` with an unchanged `@point` converts the pick, as the Swift setter does, and reports it through `@onChange`. | The parent owns the point and would otherwise hold it in the old space's units. |
| Solid input | `touch-action: none` covers the whole solid, so a touch that starts off the solid does not scroll the page (CanonGrabPan let it). Arrow keys turn the solid (not in ortho with a slice, where drags pick); the pick is read from a polite live `<output>`. Axis letters behind the camera hide instead of keeping their last place. The WebGL context keeps its drawing buffer so tests read pixels. | Web input and assistive technology; the task asked for `touch-action: none`. |
| Unverified | The crease (`horizontal-viewport-segments`) and laptop (`device-posture: folded`) rules have no test and were not seen on a device. | No dual-screen browser available. |

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
| [ ] | B controls | CanonControls: CanonSwitch, CanonStatus, CanonTextCell, CanonStepper, CanonNumberField, CanonSlider | canon-switch, canon-status, canon-text-cell, canon-stepper, canon-number-field, canon-slider | Stepper repeats while held. |
| [ ] | B controls | CanonDecimalField, CanonTextArea, CanonMenuCell, CanonFromTo, CanonLoader, CanonFigure, CanonDualList, CanonFileCell, CanonDropZone | canon-decimal-field, canon-text-area, canon-menu-cell, canon-from-to, canon-loader, canon-figure, canon-dual-list, canon-file-cell, canon-drop-zone | Loader: compare the web app's `ui/nds-loader.gts`. |
| [ ] | B display | CanonClassics: CanonPreviewPanel, CanonCodeBlock | canon-preview-panel, canon-code-block | |
| [ ] | B display | CanonTiles, CanonImageCompare, CanonPageStrip, CanonReadout (CanonTimecode, CanonLamps, CanonTransport, CanonReadoutBand) | canon-tiles, canon-image-compare, canon-page-strip, canon-timecode, canon-lamps, canon-readout-band | PageStrip reorder: native drag and drop or pointer events, no new dependency. |
| [ ] | B display | CanonGlyphFlow (CanonGlyphRows, CanonTextInput, CanonTextOutput) | canon-glyph-flow, canon-text-input, canon-text-output, `lib/glyph-rows.ts` | Glyph painting through a block. |
| [ ] | B display | CanonMotion (CanonGrabPan, CanonSidewaysPan, motion constants) | modifiers `canon-grab-pan`, `canon-sideways-pan`, add to `lib/motion.ts` | |
| [ ] | B colour | CanonClassics: CanonColourWell; CanonColourCards (CanonColourCard, CanonValueLine, CanonColourStrip, CanonSwatch, CanonPaletteCard) | canon-colour-well, canon-colour-card, canon-value-line, canon-colour-strip, canon-swatch, canon-palette-card | Nearest colour name is an arg (a function), so the addon carries no name dataset. |
| [ ] | B colour | CanonColourControls | canon-colour-controls | Drives canon-colour-solid through args; build against its arg interface. |
| [x] | B solid | CanonColourSolid | canon-colour-solid, `lib/colour-solid/*` (space, geometry, view, solid, shader, vec) | Metal to WebGL2. Every solid, slice, ortho unroll, marks, vision matrix. Args: `space`, `point`, `animated`, `sliceAxis`, `isOrtho`, `showsWhole`, `cutsAway`, `marks`, `vision`, `onChange`, `closestName`. `lib/colour-solid/space.ts` exports `spaces`, `spaceNames`, `channels`, `colourAt`, `pointFor`, `convertPoint` for CanonColourControls. |
| [ ] | B math | CanonMath (typesetter, CanonMathView, CanonMathMorph) | canon-math-view, `lib/math/*` | Typeset to HTML/CSS. Morph with the Web Animations API. |
| [ ] | B math | CanonMathInput (CanonMathExpression, CanonMathEditor, CanonMathField, CanonMathInputViewController, CanonPaneSheetPresentation) | canon-math-field, canon-math-editor, `lib/math/expression.ts` | Keypad sheet as `<dialog>` docked to the field's pane on wide containers. Reads and writes nerdamer syntax. |
| [ ] | B math | CanonMathKeypad (families, keys, submenu, rail, tabs) | canon-math-keypad, canon-math-key, canon-math-rail, canon-math-tabs | Braun ET66 family colours as tokens. |
| [ ] | C | New from the parallel session: CanonValueLine layout option, big number field, CanonCanvas `.fitting`, CanonColourNotationInput, shared loupe, CanonDetentWheel | tbd | Waits for the merge notice. |
