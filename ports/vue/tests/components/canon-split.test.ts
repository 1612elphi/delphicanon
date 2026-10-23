import { expect, test } from 'vitest';
import { reactive } from 'vue';
import CanonCanvas from '../../src/components/canon-canvas.vue';
import CanonSplit from '../../src/components/canon-split.vue';
import { find, render, settled } from '../helpers/render.ts';

const layout = () =>
	getComputedStyle(find('.canon-split-body'))
		.getPropertyValue('--canon-split-layout')
		.trim();
const box = (selector: string) => find(selector).getBoundingClientRect();

test('wide: a 340 px sidebar beside the main pane, banner across both', async () => {
	await render(
		`<div style="width: 1000px; height: 600px">
      <CanonSplit>
        <template #banner><CanonCanvas :height="100" /></template>
        <template #sidebar><div class="side">Side</div></template>
        <template #main><div class="main">Main</div></template>
        <template #footer><div class="strip">Strip</div></template>
      </CanonSplit>
    </div>`,
		{ CanonSplit, CanonCanvas },
	);
	expect(layout()).toBe('wide');
	expect(find('.canon-split-sidebar').offsetWidth).toBe(340);
	expect(find('.canon-split-main').offsetLeft).toBe(341);
	expect(find('.canon-split-banner').offsetWidth).toBe(1000);
	expect(find('.canon-split-main .canon-split-footer')).toHaveTextContent(
		'Strip',
	);
});

test('narrow or portrait: one column, sidebar first', async () => {
	await render(
		`<div style="width: 500px; height: 800px">
      <CanonSplit>
        <template #sidebar><div class="side">Side</div></template>
        <template #main><div class="main">Main</div></template>
      </CanonSplit>
    </div>`,
		{ CanonSplit },
	);
	expect(layout()).toBe('stacked');
	expect(box('.main').top).toBeGreaterThan(box('.side').top);
	expect(box('.main').left).toBe(box('.side').left);
});

test('oneColumn stacks at every width', async () => {
	await render(
		`<div style="width: 1000px; height: 600px">
      <CanonSplit :one-column="true">
        <template #sidebar><div class="side">Side</div></template>
        <template #main><div class="main">Main</div></template>
      </CanonSplit>
    </div>`,
		{ CanonSplit },
	);
	expect(layout()).toBe('stacked');
	expect(box('.main').top).toBeGreaterThan(box('.side').top);
});

test('mainLeadsStacked and halves', async () => {
	await render(
		`<div class="stacked" style="width: 500px; height: 800px">
      <CanonSplit :main-leads-stacked="true">
        <template #sidebar><div class="side">Side</div></template>
        <template #main><div class="main">Main</div></template>
      </CanonSplit>
    </div>
    <div class="halves" style="width: 1001px; height: 600px">
      <CanonSplit :halves="true">
        <template #sidebar><CanonCanvas :aspect="1" /></template>
        <template #main><div>Main</div></template>
      </CanonSplit>
    </div>`,
		{ CanonSplit, CanonCanvas },
	);
	expect(box('.stacked .side').top).toBeGreaterThan(
		box('.stacked .main').top,
	);
	const picture = find('.halves .canon-split-sidebar .canon-canvas');
	expect(picture.offsetWidth).toBe(500);
	expect(picture.offsetHeight, 'the picture fills its pane').toBe(600);
});

test('a collapsing picture refits to a new aspect', async () => {
	const model = reactive({ aspect: 1 });
	await render(
		`<div style="width: 500px; height: 800px">
      <CanonSplit halves :collapses-to="100">
        <template #sidebar><CanonCanvas :aspect="model.aspect" /></template>
        <template #main><div>Main</div></template>
      </CanonSplit>
    </div>`,
		{ CanonSplit, CanonCanvas, model },
	);
	const split = find('.canon-split');
	const full = () => split.style.getPropertyValue('--canon-split-full');
	expect(split).toHaveAttribute('data-collapsing');
	expect(full()).toBe('480px');
	model.aspect = 2;
	await settled();
	expect(full(), 'half the width and the frame').toBe('254px');
});

test('footerHidden takes the footer away', async () => {
	await render(
		`<div style="width: 1000px; height: 600px">
      <CanonSplit :footer-hidden="true">
        <template #main><div>Main</div></template>
        <template #footer><div>Strip</div></template>
      </CanonSplit>
    </div>`,
		{ CanonSplit },
	);
	expect(document.querySelector('.canon-split-footer')).toBeNull();
});
