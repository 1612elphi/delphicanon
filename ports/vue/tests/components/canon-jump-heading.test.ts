import { expect, test } from 'vitest';
import CanonJumpHeading from '../../src/components/canon-jump-heading.vue';
import {
	click,
	find,
	findAll,
	render,
	settled,
	waitUntil,
} from '../helpers/render.ts';

const groups = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon'];

test('opens a grid of its scrolling box’s groups lit at the one in view; a pick scrolls there and focuses it', async () => {
	await render(
		`<div class="list" style="block-size: 200px; overflow-y: auto">
      <template v-for="group in groups" :key="group">
        <CanonJumpHeading :text="group" detail="3" />
        <div style="block-size: 300px"></div>
      </template>
    </div>`,
		{ CanonJumpHeading, groups },
	);
	const list = find('.list');
	const headings = findAll('.canon-jump-heading');
	expect(headings[0]!.tagName, 'a heading').toBe('H3');
	const buttons = findAll('.canon-jump-heading-button');
	expect(buttons).toHaveLength(5);
	expect(buttons[0]).toHaveAttribute('aria-haspopup', 'dialog');

	list.scrollTop = headings[2]!.offsetTop - list.offsetTop;
	// the helper focuses first, which would scroll an off-screen heading in
	await click(headings[2]!.querySelector('button')!);
	expect(findAll('.canon-jump-grid-tile')).toHaveLength(5);
	expect(
		find('.canon-jump-grid-tile--lit').innerText.replace(
			/\s+/g,
			' ',
		),
	).toBe('Gamma 3');

	await click('.canon-jump-grid-tile:nth-child(4)');
	const target = headings[3]!;
	await waitUntil(
		() =>
			!document.querySelector('dialog') &&
			Math.abs(
				target.getBoundingClientRect().top -
					list.getBoundingClientRect().top,
			) < 2,
		{ timeout: 3000 },
	);
	await settled();
	expect(target.querySelector('button')).toHaveFocus();
	expect(buttons[0]!.textContent).toBe('Alpha›');
});
