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

## Phases

A. Scaffold and foundation, one agent, sequential. Blocks everything else.
B. Five groups in parallel worktrees: controls, display, colour, colour-solid, math.
C. After the parallel session merges its Canon additions: port the new and changed files.
D. Merge, lint, test, gallery check in a browser.

## Mapping

Tick when the component renders in the gallery, has its test, and passes lint.

| Tick | Group | Swift source | Glimmer | Notes |
|---|---|---|---|---|
| [ ] | A | CanonLayout: CanonRule, CanonRows, CanonRow, CanonHeading, CanonEmptyRow, CanonGrid, CanonPage, CanonPaddedSection, CanonBar | canon-rule, canon-rows, canon-row, canon-heading, canon-empty-row, canon-grid, canon-page, canon-bar | Row: plain, flush, stacked; control drops below label when narrow (container query). Grid sizes columns to the longest row. |
| [ ] | A | CanonControls: CanonButton, CanonSegmented | canon-button, canon-segmented | Kinds primary, secondary, cell, segment; `icon: oversized`; symbol-only when narrow. Icons via an `@icon` arg the consumer renders (lucide in the web app). |
| [ ] | A | CanonCanvas | canon-canvas | `.fixed`, `.aspect`, `maxHeight`, `boxing`, pattern background. |
| [ ] | A | CanonSplit | canon-split | Sidebar 340, one column under 640, `halves`, `bannerSticks`, `mainLeadsStacked`, `collapsesTo`, footer strip. Crease behaviour per Decisions. |
| [ ] | A | CanonToast, CanonCopyFeedback | canon-toast, service `canon-toast`, `canonCopy` | 1.4 s, fade, bottom of the column. |
| [ ] | B controls | CanonControls: CanonSwitch, CanonStatus, CanonTextCell, CanonStepper, CanonNumberField, CanonSlider | canon-switch, canon-status, canon-text-cell, canon-stepper, canon-number-field, canon-slider | Stepper repeats while held. |
| [ ] | B controls | CanonDecimalField, CanonTextArea, CanonMenuCell, CanonFromTo, CanonLoader, CanonFigure, CanonDualList, CanonFileCell, CanonDropZone | canon-decimal-field, canon-text-area, canon-menu-cell, canon-from-to, canon-loader, canon-figure, canon-dual-list, canon-file-cell, canon-drop-zone | Loader: compare the web app's `ui/nds-loader.gts`. |
| [ ] | B display | CanonClassics: CanonPreviewPanel, CanonCodeBlock | canon-preview-panel, canon-code-block | |
| [ ] | B display | CanonTiles, CanonImageCompare, CanonPageStrip, CanonReadout (CanonTimecode, CanonLamps, CanonTransport, CanonReadoutBand) | canon-tiles, canon-image-compare, canon-page-strip, canon-timecode, canon-lamps, canon-readout-band | PageStrip reorder: native drag and drop or pointer events, no new dependency. |
| [ ] | B display | CanonGlyphFlow (CanonGlyphRows, CanonTextInput, CanonTextOutput) | canon-glyph-flow, canon-text-input, canon-text-output, `lib/glyph-rows.ts` | Glyph painting through a block. |
| [ ] | B display | CanonMotion (CanonGrabPan, CanonSidewaysPan, motion constants) | modifiers `canon-grab-pan`, `canon-sideways-pan`, `lib/motion.ts` | |
| [ ] | B colour | CanonClassics: CanonColourWell; CanonColourCards (CanonColourCard, CanonValueLine, CanonColourStrip, CanonSwatch, CanonPaletteCard) | canon-colour-well, canon-colour-card, canon-value-line, canon-colour-strip, canon-swatch, canon-palette-card | Nearest colour name is an arg (a function), so the addon carries no name dataset. |
| [ ] | B colour | CanonColourControls | canon-colour-controls | Drives canon-colour-solid through args; build against its arg interface. |
| [ ] | B solid | CanonColourSolid | canon-colour-solid, `lib/colour-solid/*` | Metal to WebGL2. Every solid, slice, ortho unroll, marks, vision matrix. Largest single file. |
| [ ] | B math | CanonMath (typesetter, CanonMathView, CanonMathMorph) | canon-math-view, `lib/math/*` | Typeset to HTML/CSS. Morph with the Web Animations API. |
| [ ] | B math | CanonMathInput (CanonMathExpression, CanonMathEditor, CanonMathField, CanonMathInputViewController, CanonPaneSheetPresentation) | canon-math-field, canon-math-editor, `lib/math/expression.ts` | Keypad sheet as `<dialog>` docked to the field's pane on wide containers. Reads and writes nerdamer syntax. |
| [ ] | B math | CanonMathKeypad (families, keys, submenu, rail, tabs) | canon-math-keypad, canon-math-key, canon-math-rail, canon-math-tabs | Braun ET66 family colours as tokens. |
| [ ] | C | New from the parallel session: CanonValueLine layout option, big number field, CanonCanvas `.fitting`, CanonColourNotationInput, shared loupe, CanonDetentWheel | tbd | Waits for the merge notice. |
