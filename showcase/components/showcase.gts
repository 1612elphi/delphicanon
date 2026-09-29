import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import type { TOC } from '@ember/component/template-only';
import { fn } from '@ember/helper';
import { htmlSafe } from '@ember/template';
import type { ComponentLike } from '@glint/template';
import { modifier } from 'ember-modifier';
import CanonButton from '#src/components/canon-button.gts';
import CanonCommand, {
  type CanonCommandItem,
} from '#src/components/canon-command.gts';
import CanonDialog, {
  type CanonDialogClose,
} from '#src/components/canon-dialog.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonPage from '#src/components/canon-page.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import CanonSheet from '#src/components/canon-sheet.gts';
import CanonSidebar from '#src/components/canon-sidebar.gts';
import CanonSidebarRow from '#src/components/canon-sidebar-row.gts';
import CanonToast from '#src/components/canon-toast.gts';
import CanonValueLine from '#src/components/canon-value-line.gts';
import CanonWindow from '#src/components/canon-window.gts';
import Icon from '../../demo-app/components/icon.gts';
import { tiles, type Tile } from './tiles.gts';
import appWindow from 'lucide-static/icons/app-window.svg?raw';
import arrowLeft from 'lucide-static/icons/arrow-left.svg?raw';
import arrowRight from 'lucide-static/icons/arrow-right.svg?raw';
import layers from 'lucide-static/icons/layers.svg?raw';
import layoutGrid from 'lucide-static/icons/layout-grid.svg?raw';
import menu from 'lucide-static/icons/menu.svg?raw';
import monitor from 'lucide-static/icons/monitor.svg?raw';
import packageSvg from 'lucide-static/icons/package.svg?raw';
import palette from 'lucide-static/icons/palette.svg?raw';
import panelLeft from 'lucide-static/icons/panel-left.svg?raw';
import search from 'lucide-static/icons/search.svg?raw';
import sigma from 'lucide-static/icons/sigma.svg?raw';
import slidersHorizontal from 'lucide-static/icons/sliders-horizontal.svg?raw';
import type from 'lucide-static/icons/type.svg?raw';

// ∑CG: showcase top bar, the kit's name on the start side
//   spec: the name of the UI kit as the page title; up to 28 chars, plain, no period
//   sample: "Delphi's Canon UI kit"
const kitName = '∑CG';

// ∑CG: showcase installation page, the note on the tokens under its heading
//   spec: one sentence saying every component imports tokens.css, which holds the --canon-* custom properties, and the shadcn CLIs install it as canon-tokens; up to 120 chars, plain, sentence case
//   sample: "Every component imports tokens.css with the --canon-* properties; the shadcn CLIs install it as canon-tokens."
const tokensNote = '∑CG';

// ∑CG: showcase installation page, the note on the fonts under the tokens note
//   spec: one sentence saying the consumer supplies the @font-face rules for iA Writer Quattro and, for CanonTimecode, FluoWrite, and that without them text falls back to the system monospace fonts; up to 160 chars, plain, sentence case
//   sample: "Supply the @font-face rules for iA Writer Quattro and, for CanonTimecode, FluoWrite; without them the text falls back to system monospace."
const fontsNote = '∑CG';

const frameworks = ['ember', 'react', 'vue', 'svelte'] as const;
type Framework = (typeof frameworks)[number];
const frameworkNames = ['Ember', 'React', 'Vue', 'Svelte'];
const isFramework = (value: unknown): value is Framework =>
  frameworks.includes(value as Framework);

const cli: Record<Exclude<Framework, 'ember'>, string> = {
  react: 'npx shadcn@latest add',
  vue: 'npx shadcn-vue@latest add',
  svelte: 'npx shadcn-svelte@latest add',
};

// registry/build.ts installs under <components alias>/canon/; these are the CLIs' default aliases
const importPath: Record<Framework, (name: string) => string> = {
  ember: (name) => `delphicanon/components/${name}`,
  react: (name) => `@/components/canon/${name}`,
  vue: (name) => `@/components/canon/${name}.vue`,
  svelte: (name) => `$lib/components/canon/${name}.svelte`,
};

const base = (
  (import.meta.env.CANON_REGISTRY_URL as string | undefined) ||
  'http://localhost:4330'
).replace(/\/+$/, '');

const componentName = (name: string) =>
  name.replace(/(^|-)([a-z])/g, (_, _dash, letter: string) =>
    letter.toUpperCase(),
  );

function install(framework: Framework, name: string) {
  if (framework === 'ember') return 'npm install delphicanon';
  return `${cli[framework]} ${base}/r/${framework}/${name}.json`;
}

const importLine = (framework: Framework, name: string) =>
  `import ${componentName(name)} from '${importPath[framework](name)}';`;

const iconFor = (svg: string): ComponentLike => <template>
  <Icon @svg={{svg}} />
</template>;

const groups: { title: string; svg: string; names: string[] }[] = [
  {
    title: 'Layout',
    svg: layoutGrid,
    names: [
      'canon-bar',
      'canon-canvas',
      'canon-empty-row',
      'canon-grid',
      'canon-heading',
      'canon-page',
      'canon-row',
      'canon-rows',
      'canon-rule',
      'canon-split',
    ],
  },
  {
    title: 'Controls',
    svg: slidersHorizontal,
    names: [
      'canon-big-number-field',
      'canon-button',
      'canon-decimal-field',
      'canon-drop-zone',
      'canon-dual-list',
      'canon-figure',
      'canon-file-cell',
      'canon-from-to',
      'canon-loader',
      'canon-menu-cell',
      'canon-number-field',
      'canon-segmented',
      'canon-slider',
      'canon-status',
      'canon-stepper',
      'canon-switch',
      'canon-text-area',
      'canon-text-cell',
    ],
  },
  {
    title: 'Text',
    svg: type,
    names: [
      'canon-code-block',
      'canon-glyph-flow',
      'canon-text-input',
      'canon-text-output',
    ],
  },
  {
    title: 'Colour',
    svg: palette,
    names: [
      'canon-colour-card',
      'canon-colour-controls',
      'canon-colour-notation-input',
      'canon-colour-solid',
      'canon-colour-strip',
      'canon-colour-well',
      'canon-detent-wheel',
      'canon-detent-wheel-row',
      'canon-loupe',
      'canon-palette-card',
      'canon-swatch',
      'canon-value-line',
    ],
  },
  {
    title: 'Maths',
    svg: sigma,
    names: [
      'canon-math-editor',
      'canon-math-field',
      'canon-math-input',
      'canon-math-key',
      'canon-math-keypad',
      'canon-math-rail',
      'canon-math-tabs',
      'canon-math-view',
    ],
  },
  {
    title: 'Display',
    svg: monitor,
    names: [
      'canon-icon',
      'canon-image-compare',
      'canon-lamps',
      'canon-page-strip',
      'canon-preview-panel',
      'canon-readout-band',
      'canon-tiles',
      'canon-timecode',
      'canon-toast',
    ],
  },
  {
    title: 'Overlays',
    svg: layers,
    names: ['canon-command', 'canon-dialog', 'canon-sheet'],
  },
  {
    title: 'Menus',
    svg: menu,
    names: [
      'canon-context-menu',
      'canon-menu',
      'canon-menu-bar',
      'canon-popover',
      'canon-tooltip',
    ],
  },
  {
    title: 'Shell',
    svg: appWindow,
    names: ['canon-sidebar', 'canon-sidebar-row', 'canon-window'],
  },
];

interface Entry {
  id: string;
  /** Sidebar row title. */
  title: string;
  /** Page heading, pager and palette title. */
  heading: string;
  group: string;
  href: string;
  icon: ComponentLike;
  tile?: Tile;
}

const tileByName = new Map(tiles.map((tile) => [tile.name, tile]));

const sections: { title: string; entries: Entry[] }[] = [
  {
    title: 'Getting started',
    entries: [
      {
        id: 'installation',
        title: 'Installation',
        heading: 'Installation',
        group: 'Getting started',
        href: '#installation',
        icon: iconFor(packageSvg),
      },
    ],
  },
  ...groups.map(({ title, svg, names }) => {
    const icon = iconFor(svg);
    return {
      title,
      entries: names.map((name) => {
        const tile = tileByName.get(name);
        if (!tile) throw new Error(`no tile for ${name}`);
        return {
          id: name,
          title: componentName(name).replace(/^Canon/, ''),
          heading: componentName(name),
          group: title,
          href: `#${name}`,
          icon,
          tile,
        };
      }),
    };
  }),
];

const pages = sections.flatMap((section) => section.entries);
if (new Set(pages.map((page) => page.id)).size !== tiles.length + 1)
  throw new Error('every tile needs exactly one sidebar entry');
const pageById = new Map(pages.map((page) => [page.id, page]));

const commandItems: CanonCommandItem[] = pages.map((page) => ({
  id: page.id,
  title: page.heading,
  group: page.group,
  keywords: [page.title],
  icon: page.icon,
}));

const storageKey = 'delphicanon-showcase-framework';

function readPage() {
  const id = decodeURIComponent(window.location.hash.slice(1));
  return pageById.has(id) ? id : 'installation';
}

function readFramework(): Framework {
  const query = new URLSearchParams(window.location.search).get('fw');
  if (isFramework(query)) return query;
  try {
    const stored = window.localStorage.getItem(storageKey);
    if (isFramework(stored)) return stored;
  } catch {
    // storage blocked: the default stands
  }
  return 'ember';
}

const paletteStyle = htmlSafe('--canon-dialog-width: 640px');
const menuIcon = iconFor(panelLeft);
const searchIcon = iconFor(search);
const previousIcon = iconFor(arrowLeft);
const nextIcon = iconFor(arrowRight);
const eq = (a: unknown, b: unknown) => a === b;

const scrollTop = modifier((element: HTMLElement, [page]: [string]) => {
  if (page) element.scrollTop = 0;
});

const Nav: TOC<{
  Args: {
    current: string;
    /** Focuses the current row when a dialog opens, instead of its scroller. */
    autofocus?: boolean;
    onPick?: (event: MouseEvent) => void;
  };
}> = <template>
  {{#each sections as |section|}}
    <CanonHeading @text={{section.title}} />
    {{#each section.entries as |entry|}}
      <CanonSidebarRow
        @title={{entry.title}}
        @icon={{entry.icon}}
        @href={{entry.href}}
        @selected={{eq entry.id @current}}
        @onClick={{@onPick}}
        {{! showModal focuses the first focusable element, else the scroller }}
        {{! template-lint-disable no-autofocus-attribute }}
        autofocus={{if @autofocus (eq entry.id @current)}}
      />
    {{/each}}
  {{/each}}
</template>;

export default class Showcase extends Component {
  @tracked page = readPage();
  @tracked framework = readFramework();
  @tracked palette = false;
  @tracked sheet = false;

  get entry() {
    return pageById.get(this.page)!;
  }

  get previous() {
    return pages[pages.indexOf(this.entry) - 1];
  }

  get next() {
    return pages[pages.indexOf(this.entry) + 1];
  }

  get frameworkIndex() {
    return frameworks.indexOf(this.framework);
  }

  get canonAll() {
    return frameworks.map((framework, index) => ({
      label: frameworkNames[index]!,
      value: install(framework, 'canon-all'),
      lit: framework === this.framework,
    }));
  }

  install = (name: string) => install(this.framework, name);
  importLine = (name: string) => importLine(this.framework, name);

  pickFramework = (index: number) => {
    const framework = frameworks[index]!;
    this.framework = framework;
    try {
      window.localStorage.setItem(storageKey, framework);
    } catch {
      // storage blocked: the URL still carries it
    }
    const url = new URL(window.location.href);
    url.searchParams.set('fw', framework);
    window.history.replaceState(window.history.state, '', url);
  };

  listen = modifier(() => {
    const hashchange = () => (this.page = readPage());
    // consumer owns the shortcut
    const keydown = (event: KeyboardEvent) => {
      if (event.key.toLowerCase() !== 'k') return;
      if (!(event.metaKey || event.ctrlKey) || event.altKey) return;
      event.preventDefault();
      this.palette = true;
    };
    window.addEventListener('hashchange', hashchange);
    document.addEventListener('keydown', keydown);
    return () => {
      window.removeEventListener('hashchange', hashchange);
      document.removeEventListener('keydown', keydown);
    };
  });

  openPalette = () => (this.palette = true);
  closePalette = () => (this.palette = false);
  go = (close: CanonDialogClose, item: CanonCommandItem) => {
    window.location.hash = item.id;
    close(item.id);
  };

  openSheet = () => (this.sheet = true);
  closeSheet = () => (this.sheet = false);
  pickInSheet = (close: CanonDialogClose) => close();

  <template>
    <div class="showcase" {{this.listen}}>
      <CanonWindow @title={{kitName}}>
        <:toolbar>
          <CanonButton
            class="showcase-menu"
            @kind="cell"
            @icon={{menuIcon}}
            @label="Components"
            @onClick={{this.openSheet}}
          />
          <CanonButton
            @kind="cell"
            @text="Search"
            @icon={{searchIcon}}
            @onClick={{this.openPalette}}
          />
          <CanonSegmented
            class="showcase-frameworks"
            aria-label="Framework"
            @items={{frameworkNames}}
            @selected={{this.frameworkIndex}}
            @onChange={{this.pickFramework}}
          />
        </:toolbar>
        <:sidebar>
          <CanonSidebar
            class="showcase-nav"
            @collapsed={{false}}
            aria-label="Components"
          >
            <Nav @current={{this.page}} />
          </CanonSidebar>
        </:sidebar>
        <:main>
          <CanonPage {{scrollTop this.page}}>
            {{#let this.entry.tile as |tile|}}
              {{#if tile}}
                <CanonRows @framed={{true}}>
                  <CanonHeading @text={{this.entry.heading}} />
                  <tile.Live />
                </CanonRows>
                <CanonRows @framed={{true}}>
                  <CanonHeading @text="Installation" />
                  <CanonValueLine
                    @label="Command"
                    @value={{this.install tile.name}}
                    @layout="wrapping"
                  />
                  <CanonValueLine
                    @label="Import"
                    @value={{this.importLine tile.name}}
                    @layout="wrapping"
                  />
                </CanonRows>
              {{else}}
                <CanonRows @framed={{true}}>
                  <CanonHeading @text="Installation" />
                  {{#each this.canonAll as |line|}}
                    <CanonValueLine
                      @label={{line.label}}
                      @value={{line.value}}
                      @lit={{line.lit}}
                      @layout="wrapping"
                    />
                  {{/each}}
                </CanonRows>
                <CanonRows @framed={{true}}>
                  <CanonHeading @text="Tokens and fonts" />
                  <p class="showcase-note">{{tokensNote}}</p>
                  <p class="showcase-note">{{fontsNote}}</p>
                  <CanonValueLine
                    @label="--canon-font"
                    @value='"iA Writer Quattro"'
                    @layout="wrapping"
                  />
                  <CanonValueLine
                    @label="--canon-segment-font"
                    @value='"FluoWrite"'
                    @layout="wrapping"
                  />
                </CanonRows>
              {{/if}}
            {{/let}}
            <nav class="showcase-pager" aria-label="Pages">
              {{#if this.previous}}
                <CanonSidebarRow
                  class="showcase-previous"
                  rel="prev"
                  @title={{this.previous.heading}}
                  @icon={{previousIcon}}
                  @href={{this.previous.href}}
                />
              {{/if}}
              {{#if this.next}}
                <CanonSidebarRow
                  class="showcase-next"
                  rel="next"
                  @title={{this.next.heading}}
                  @icon={{nextIcon}}
                  @href={{this.next.href}}
                />
              {{/if}}
            </nav>
          </CanonPage>
        </:main>
      </CanonWindow>
    </div>

    <CanonDialog
      @open={{this.palette}}
      @onClose={{this.closePalette}}
      aria-label="Command palette"
      style={{paletteStyle}}
    >
      <:default as |close|>
        <CanonCommand
          @items={{commandItems}}
          @placeholder="Search components"
          @onSelect={{fn this.go close}}
        />
      </:default>
    </CanonDialog>

    <CanonSheet
      @open={{this.sheet}}
      @edge="start"
      @title="Components"
      @onClose={{this.closeSheet}}
    >
      <:default as |close|>
        <div class="showcase-sidebar-rows">
          <Nav
            @current={{this.page}}
            @autofocus={{true}}
            @onPick={{fn this.pickInSheet close}}
          />
        </div>
      </:default>
    </CanonSheet>

    <CanonToast />
  </template>
}
