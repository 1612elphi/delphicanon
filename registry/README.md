# delphicanon registry

shadcn-compatible registries for the React, Vue and Svelte ports in `../ports/`. Each Canon component is one item, `canon-<name>`; `canon-all` depends on every component.

## Add a component

With the registry served at `http://localhost:4330`:

| Port   | Command                                                                         |
| ------ | ------------------------------------------------------------------------------- |
| React  | `npx shadcn@latest add http://localhost:4330/r/react/canon-slider.json`         |
| Vue    | `npx shadcn-vue@latest add http://localhost:4330/r/vue/canon-slider.json`       |
| Svelte | `npx shadcn-svelte@latest add http://localhost:4330/r/svelte/canon-slider.json` |

The project needs a `components.json` from the CLI's `init`. The CLI installs the dependency items too: `canon-tokens` (`tokens.css`) and `canon-lib-<name>` (shared and port-local logic), and other Canon components the item imports.

Files go to `<components alias>/canon/`: components and their CSS in `canon/`, logic in `canon/lib/`. Import a component from there, for example `@/components/canon/canon-slider` (React), `@/components/canon/canon-slider.vue` (Vue), `$lib/components/canon/canon-slider.svelte` (Svelte).

## What the consumer provides

- The `@font-face` rules for the first family of `--canon-font` ("iA Writer Quattro") and, for `canon-timecode`, of `--canon-segment-font` ("FluoWrite"), both in `tokens.css`. Without them the text falls back to the system monospace fonts in the same lists.
- The framework (`react` and `react-dom`, `vue`, or `svelte`). Items list no npm dependencies.
- Next.js: the App Router. Components import their CSS, which the Pages Router rejects outside `_app`. React component files start with `'use client'`. Where `rsc` is false, shadcn 4.21 removes it from about half of the files (its directive pattern carries the `g` flag, so `test` alternates); Vite builds the rest without a warning.
- TypeScript: `lib` with ES2023 or later (`Array.prototype.findLast`), and `erasableSyntaxOnly` off (the shared maths and colour solid code has constructor parameter properties).

## Build and serve

```sh
bun install
bun run build     # regenerates public/r/<fw>/ from ../ports and ../src
bun run serve     # static server on port 4330
bun run test      # rebuilds, then checks every import of every item
bun run lint
```

`build.ts` follows the imports of every component in `ports/<fw>/src/components/`, rewrites them to the paths the files have in the consumer's project, writes the sources and a `registry.json` to `.build/<fw>/`, and runs the framework's own build command (`shadcn build`, `shadcn-vue build`, `shadcn-svelte registry build`), which inlines the file contents into `public/r/<fw>/<item>.json`. It deletes only `public/r/`.

The React and Vue items name their dependencies by absolute URL, since both CLIs resolve a bare name against their own registry. `CANON_REGISTRY_URL` sets the site root baked into those URLs and into `homepage` (default `http://localhost:4330`); rebuild after changing it. Svelte items use `local:<name>`, which `shadcn-svelte registry build` turns into `./<name>.json`, relative to the item.

A new port under `ports/` needs one entry in `clis` in `build.ts`.
