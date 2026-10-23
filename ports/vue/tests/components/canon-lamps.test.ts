import { reactive } from 'vue';
import { expect, test } from 'vitest';
import CanonLamps from '../../src/components/canon-lamps.vue';
import { find, findAll, render, settled } from '../helpers/render.ts';

const recording = ['record' as const, 'pause' as const];

test('every lamp present, lit ones lit, a flash blinks', async () => {
	const state = reactive({ loops: 0 });
	const lit = ['play', 'loop'] as const;
	await render(
		`<CanonLamps :lit="lit" :flashes="{ loop: state.loops }" />
    <CanonLamps class="rec" :lamps="recording" :lit="recording" />`,
		{ CanonLamps, state, lit, recording },
	);
	expect(findAll('.canon-lamps-lamp')).toHaveLength(5);
	expect(find('.canon-lamps-lamp--play')).toHaveClass(
		'canon-lamps-lamp--lit',
	);
	expect(find('.canon-lamps-lamp--pause')).not.toHaveClass(
		'canon-lamps-lamp--lit',
	);
	expect(document.querySelector('.canon-lamps-lamp--blink')).toBeNull();
	state.loops = 1;
	await settled();
	expect(find('.canon-lamps-lamp--loop')).toHaveClass(
		'canon-lamps-lamp--blink',
	);
	expect(find('.rec .canon-lamps-lamp--record')).toHaveClass(
		'canon-lamps-lamp--lit',
	);
});
