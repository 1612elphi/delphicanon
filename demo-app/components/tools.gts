import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import type Owner from '@ember/owner';
import type { ComponentLike } from '@glint/template';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonSidebar from '#src/components/canon-sidebar.gts';
import CanonSidebarRow from '#src/components/canon-sidebar-row.gts';
import CanonWindow from '#src/components/canon-window.gts';
import Icon from './icon.gts';
import './tools.css';

interface ToolModule {
  default: ComponentLike;
  tool: { title: string; group: string; icon: string };
}

interface Entry {
  id: string;
  title: string;
  group: string;
  Tool: ComponentLike;
  Glyph: ComponentLike;
}

// each tools/<id>/<id>.gts exports `tool` beside its component
const entries: Entry[] = Object.entries(
  import.meta.glob<ToolModule>('./tools/*/*.gts', { eager: true }),
)
  .filter(([path, module]) => {
    const [, id, file] = /\.\/tools\/([^/]+)\/([^/]+)\.gts$/.exec(path) ?? [];
    return id === file && 'tool' in module;
  })
  .map(([path, module]) => ({
    id: /\.\/tools\/([^/]+)\//.exec(path)![1]!,
    title: module.tool.title,
    group: module.tool.group,
    Tool: module.default,
    Glyph: <template><Icon @svg={{module.tool.icon}} /></template>,
  }))
  .sort(
    (a, b) => a.group.localeCompare(b.group) || a.title.localeCompare(b.title),
  );

const groups = [...new Set(entries.map((entry) => entry.group))].map(
  (group) => ({
    group,
    tools: entries.filter((entry) => entry.group === group),
  }),
);

const current = (fallback: string | undefined) =>
  entries.find((entry) => `#${entry.id}` === window.location.hash) ??
  entries.find((entry) => entry.id === fallback) ??
  entries[0]!;

const eq = (a: unknown, b: unknown) => a === b;

interface ToolsSignature {
  Args: { start?: string };
}

/** The web delphitools shell: every tool under demo-app/components/tools/, one at a time. */
export default class Tools extends Component<ToolsSignature> {
  @tracked entry = current(this.args.start);

  constructor(owner: Owner, args: ToolsSignature['Args']) {
    super(owner, args);
    const follow = () => (this.entry = current(this.args.start));
    window.addEventListener('hashchange', follow);
    registerDestructor(this, () =>
      window.removeEventListener('hashchange', follow),
    );
  }

  <template>
    <CanonWindow class="tools" @title="Tools">
      <:sidebar>
        <CanonSidebar @compact={{true}} aria-label="Tools">
          {{#each groups as |g|}}
            <CanonHeading @text={{g.group}} />
            {{#each g.tools as |t|}}
              <CanonSidebarRow
                @title={{t.title}}
                @icon={{t.Glyph}}
                @href="#{{t.id}}"
                @selected={{eq t this.entry}}
              />
            {{/each}}
          {{/each}}
        </CanonSidebar>
      </:sidebar>
      <:main>
        {{#let this.entry.Tool as |Tool|}}
          <div class="tools-pane"><Tool /></div>
        {{/let}}
      </:main>
    </CanonWindow>
  </template>
}
