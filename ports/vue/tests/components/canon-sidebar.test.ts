import { expect, test } from 'vitest';
import CanonHeading from '../../src/components/canon-heading.vue';
import CanonSidebar from '../../src/components/canon-sidebar.vue';
import CanonSidebarRow from '../../src/components/canon-sidebar-row.vue';
import { find, findAll, render } from '../helpers/render.ts';

test('holds a hero, headings and rows', async () => {
  await render(
    `<div style="height: 400px">
      <CanonSidebar aria-label="Main">
        <template #hero><img alt="" /></template>
        <template #default>
          <CanonHeading text="Modules" />
          <CanonSidebarRow title="Toolbox" />
          <CanonSidebarRow title="General" />
        </template>
      </CanonSidebar>
    </div>`,
    { CanonHeading, CanonSidebar, CanonSidebarRow },
  );
  expect(find('nav.canon-sidebar')).toHaveAttribute('aria-label', 'Main');
  expect(findAll('.canon-sidebar-hero img')).toHaveLength(1);
  expect(find('.canon-sidebar-rows .canon-heading')).toBeVisible();
  expect(findAll('.canon-sidebar-row')).toHaveLength(2);
});

test('collapses to the icon rail', async () => {
  await render(
    `<div style="display: flex; height: 400px">
      <CanonSidebar class="wide">
        <CanonHeading text="Modules" />
        <CanonSidebarRow title="Toolbox" />
      </CanonSidebar>
      <CanonSidebar class="rail" :collapsed="true">
        <CanonHeading text="Modules" />
        <CanonSidebarRow title="Toolbox" />
      </CanonSidebar>
    </div>`,
    { CanonHeading, CanonSidebar, CanonSidebarRow },
  );
  const wide = find('.wide');
  const rail = find('.rail');
  const cell = find('.rail .canon-sidebar-row-icon');
  expect(wide).not.toHaveClass('canon-sidebar--expanded');
  expect(rail.offsetWidth).toBeLessThan(wide.offsetWidth / 4);
  expect(rail.offsetWidth, 'the rail keeps the cell').toBeGreaterThan(
    cell.offsetWidth,
  );
  expect(find('.rail .canon-heading')).not.toBeVisible();
  expect(
    find('.rail .canon-sidebar-row'),
    'the title stays as the accessible name',
  ).toHaveTextContent('Toolbox');
});
