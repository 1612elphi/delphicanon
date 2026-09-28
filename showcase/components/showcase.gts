import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonPage from '#src/components/canon-page.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSegmented from '#src/components/canon-segmented.gts';
import CanonTiles from '#src/components/canon-tiles.gts';
import CanonToast from '#src/components/canon-toast.gts';
import CanonValueLine from '#src/components/canon-value-line.gts';
import { tiles } from './tiles.gts';

const frameworks = ['ember', 'react', 'vue', 'svelte'] as const;
type Framework = (typeof frameworks)[number];

const frameworkNames = ['Ember', 'React', 'Vue', 'Svelte'];
const cli: Record<Exclude<Framework, 'ember'>, string> = {
  react: 'npx shadcn@latest add',
  vue: 'npx shadcn-vue@latest add',
  svelte: 'npx shadcn-svelte@latest add',
};

const base = (
  (import.meta.env.CANON_REGISTRY_URL as string | undefined) ||
  'http://localhost:4330'
).replace(/\/+$/, '');

const componentName = (name: string) =>
  name.replace(/(^|-)([a-z])/g, (_, _dash, letter: string) =>
    letter.toUpperCase(),
  );

function command(framework: Framework, name: string) {
  if (framework === 'ember')
    return name === 'canon-all'
      ? 'npm install delphicanon'
      : `import ${componentName(name)} from 'delphicanon/components/${name}';`;
  return `${cli[framework]} ${base}/r/${framework}/${name}.json`;
}

const summary = [
  { label: 'Components', value: String(tiles.length) },
  { label: 'Frameworks', value: String(frameworks.length) },
  { label: 'Registry', value: base },
];

export default class Showcase extends Component {
  @tracked index = 0;

  get framework() {
    return frameworks[this.index]!;
  }

  pick = (index: number) => (this.index = index);
  command = (name: string) => command(this.framework, name);

  <template>
    <CanonPage @maxWidth={{null}}>
      <CanonRows @framed={{true}} class="showcase-header">
        <CanonHeading @text="Canon" />
        <CanonRow @title="Framework" @form="stacked">
          <CanonSegmented
            @items={{frameworkNames}}
            @selected={{this.index}}
            @onChange={{this.pick}}
          />
        </CanonRow>
        <CanonTiles @items={{summary}} />
        <CanonValueLine
          @label="canon-all"
          @value={{this.command "canon-all"}}
          @layout="wrapping"
        />
      </CanonRows>
      <div class="showcase-grid-box">
        <div class="showcase-grid">
          {{#each tiles as |tile|}}
            <CanonRows
              @framed={{true}}
              class={{if tile.wide "showcase-tile--wide"}}
            >
              <CanonHeading @text={{componentName tile.name}} />
              <tile.Live />
              <CanonValueLine
                @label="Install"
                @value={{this.command tile.name}}
                @layout="wrapping"
              />
            </CanonRows>
          {{/each}}
        </div>
      </div>
    </CanonPage>
    <CanonToast />
  </template>
}
