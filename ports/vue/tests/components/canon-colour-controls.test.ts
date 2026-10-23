import { expect, test } from 'vitest';
import CanonColourControls, {
	CanonColourSolidState,
} from '../../src/components/canon-colour-controls.vue';
import CanonColourSolid from '../../src/components/canon-colour-solid.vue';
import CanonRows from '../../src/components/canon-rows.vue';
import { hex } from '@canon/lib/colour.ts';
import {
	click,
	fillIn,
	find,
	findAll,
	render,
	triggerEvent,
	waitUntil,
} from '../helpers/render.ts';

test('one slider per channel, the active one the slice', async () => {
	const state = new CanonColourSolidState({
		colour: [1, 0, 0],
		activeRow: 2,
	});
	await render(
		`<div style="width: 400px">
      <div style="height: 200px">
        <CanonColourSolid
          :space="state.space"
          :point="state.point"
          :animated="state.animated"
          :slice-axis="state.sliceAxis"
          :is-ortho="state.isOrtho"
          :shows-whole="state.showsWhole"
          :on-change="state.pick"
        />
      </div>
      <CanonRows><CanonColourControls :state="state" /></CanonRows>
    </div>`,
		{ CanonColourSolid, CanonColourControls, CanonRows, state },
	);
	expect(findAll('.canon-slider')).toHaveLength(3);
	expect(
		find(
			'.canon-colour-controls-lit .canon-row-title',
		).textContent?.trim(),
	).toBe('Lightness');
	expect(state.sliceAxis, 'hsl lightness is axis 1').toBe(1);
	expect(find('.canon-colour-notation-input-field')).toHaveValue(
		'#FF0000',
	);

	const track = find('.canon-slider-track').getBoundingClientRect();
	const at = {
		button: 0,
		pointerId: 1,
		clientX: track.left + track.width / 3,
		clientY: track.top + track.height / 2,
	};
	await triggerEvent('.canon-slider', 'pointerdown', at);
	await triggerEvent('.canon-slider', 'pointerup', at);
	expect(hex(state.colour)).toBe('#00FF00');
	expect(state.activeRow).toBe(0);
	expect(state.animated, 'a tap eases').toBe(true);
	// the solid paints on the next animation frame
	await waitUntil(
		() =>
			document.querySelector('.canon-colour-solid output')
				?.textContent === '#00FF00',
	);

	await click('[role=radio]:nth-child(8)');
	expect(state.space).toBe('cmyk');
	await waitUntil(() => hex(state.colour) === '#00FF00');
	expect(findAll('.canon-slider')).toHaveLength(4);
	expect(
		state.point.map((v) => Math.round(v * 100)),
		'the solid converts the pick, the colour survives',
	).toEqual([100, 0, 100, 0]);

	await triggerEvent('input[role=switch]', 'click');
	expect(state.isOrtho).toBe(true);
});

test('reads any notation after a pause', async () => {
	const state = new CanonColourSolidState();
	await render(
		`<CanonRows><CanonColourControls :state="state" /></CanonRows>`,
		{ CanonColourControls, CanonRows, state },
	);
	await fillIn('.canon-colour-notation-input-field', 'rgb(59, 130, 246)');
	await waitUntil(() => hex(state.colour) === '#3B82F6', {
		timeout: 2000,
	});
	expect(hex(state.colour)).toBe('#3B82F6');
	await fillIn('.canon-colour-notation-input-field', 'nope');
	await waitUntil(
		() =>
			document
				.querySelector(
					'.canon-colour-notation-input-field',
				)
				?.getAttribute('aria-invalid') === 'true',
		{ timeout: 2000 },
	);
	expect(find('.canon-colour-notation-input-field')).toHaveAttribute(
		'aria-invalid',
		'true',
	);
});
