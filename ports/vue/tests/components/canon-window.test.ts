import { expect, test } from 'vitest';
import CanonSidebar from '../../src/components/canon-sidebar.vue';
import CanonSidebarRow from '../../src/components/canon-sidebar-row.vue';
import CanonWindow from '../../src/components/canon-window.vue';
import { click, find, findAll, render } from '../helpers/render.ts';

test('draws the title bar and its controls', async () => {
	const calls: string[] = [];
	const close = () => calls.push('close');
	const zoom = () => calls.push('zoom');
	await render(
		`<div style="width: 900px; height: 500px">
      <CanonWindow title="Delphi" :on-close="close" :on-zoom="zoom">
        <template #toolbar><button type="button" class="tool">T</button></template>
        <template #menubar><span class="menu">M</span></template>
        <template #main><p class="detail">D</p></template>
      </CanonWindow>
    </div>`,
		{ CanonWindow, close, zoom },
	);
	expect(
		find('section.canon-window').getAttribute('aria-labelledby'),
	).toMatch(/-title$/);
	expect(find('.canon-window-title')).toHaveTextContent('Delphi');
	expect(findAll('.canon-window-toolbar .tool')).toHaveLength(1);
	expect(findAll('.canon-window-menubar .menu')).toHaveLength(1);
	expect(findAll('.canon-window-main .detail')).toHaveLength(1);
	expect(find('[aria-label="Minimise"]')).toBeDisabled();
	await click('[aria-label="Close"]');
	await click('[aria-label="Zoom"]');
	expect(calls).toEqual(['close', 'zoom']);
});

test('leaves the controls out without callbacks', async () => {
	await render(`<CanonWindow />`, { CanonWindow });
	expect(findAll('.canon-window-controls')).toHaveLength(0);
	expect(findAll('.canon-window-menubar')).toHaveLength(0);
	expect(find('.canon-window')).not.toHaveAttribute('aria-labelledby');
});

test('collapses its sidebar when narrow', async () => {
	await render(
		`<div style="display: flex; gap: 8px; height: 400px">
      <div style="width: 900px">
        <CanonWindow class="wide">
          <template #sidebar><CanonSidebar><CanonSidebarRow title="A" /></CanonSidebar></template>
        </CanonWindow>
      </div>
      <div style="width: 400px">
        <CanonWindow class="narrow">
          <template #sidebar><CanonSidebar><CanonSidebarRow title="A" /></CanonSidebar></template>
        </CanonWindow>
      </div>
      <div style="width: 400px">
        <CanonWindow class="kept">
          <template #sidebar><CanonSidebar :collapsed="false"><CanonSidebarRow title="A" /></CanonSidebar></template>
        </CanonWindow>
      </div>
    </div>`,
		{ CanonWindow, CanonSidebar, CanonSidebarRow },
	);
	const width = (selector: string) =>
		find(`${selector} .canon-sidebar`).offsetWidth;
	expect(
		width('.narrow'),
		'collapsed left out follows the window',
	).toBeLessThan(width('.wide') / 4);
	expect(width('.kept')).toBe(width('.wide'));
});
