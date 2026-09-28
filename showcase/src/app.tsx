import { useState } from 'react';
import CanonHeading from '@port/components/canon-heading.tsx';
import CanonPage from '@port/components/canon-page.tsx';
import CanonRow from '@port/components/canon-row.tsx';
import CanonRows from '@port/components/canon-rows.tsx';
import CanonSegmented from '@port/components/canon-segmented.tsx';
import CanonTiles from '@port/components/canon-tiles.tsx';
import CanonToast from '@port/components/canon-toast.tsx';
import CanonValueLine from '@port/components/canon-value-line.tsx';
import { tiles } from './tiles.tsx';

const frameworks = ['react', 'vue', 'svelte'] as const;
type Framework = (typeof frameworks)[number];

const frameworkNames = ['React', 'Vue', 'Svelte'];
const cli: Record<Framework, string> = {
  react: 'npx shadcn@latest add',
  vue: 'npx shadcn-vue@latest add',
  svelte: 'npx shadcn-svelte@latest add',
};

const base = (
  import.meta.env.CANON_REGISTRY_URL || 'http://localhost:4330'
).replace(/\/+$/, '');

const command = (framework: Framework, name: string) =>
  `${cli[framework]} ${base}/r/${framework}/${name}.json`;

const componentName = (name: string) =>
  name.replace(/(^|-)([a-z])/g, (_, _dash, letter: string) =>
    letter.toUpperCase(),
  );

export default function App() {
  const [index, setIndex] = useState(0);
  const framework = frameworks[index]!;

  return (
    <>
      <CanonPage maxWidth={null}>
        <CanonRows framed className="showcase-header">
          <CanonHeading text="Canon" />
          <CanonRow title="Framework" form="stacked">
            <CanonSegmented
              items={frameworkNames}
              selected={index}
              onChange={setIndex}
            />
          </CanonRow>
          <CanonTiles
            items={[
              { label: 'Components', value: String(tiles.length) },
              { label: 'Frameworks', value: String(frameworks.length) },
              { label: 'Registry', value: base },
            ]}
          />
          <CanonValueLine
            label="canon-all"
            value={command(framework, 'canon-all')}
            layout="wrapping"
          />
        </CanonRows>
        <div className="showcase-grid-box">
          <div className="showcase-grid">
            {tiles.map(({ name, wide, Live }) => (
              <CanonRows
                framed
                key={name}
                className={wide ? 'showcase-tile--wide' : undefined}
              >
                <CanonHeading text={componentName(name)} />
                <Live />
                <CanonValueLine
                  label="Install"
                  value={command(framework, name)}
                  layout="wrapping"
                />
              </CanonRows>
            ))}
          </div>
        </div>
      </CanonPage>
      <CanonToast />
    </>
  );
}
