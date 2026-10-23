import { expect, test } from 'vitest';
import CanonButton from '../../src/components/canon-button.vue';
import Dot from '../helpers/dot.ts';
import { click, find, render, triggerEvent, wait } from '../helpers/render.ts';

test('kinds set their heights and fill', async () => {
	await render(
		`<CanonButton class="primary" text="Go" kind="primary" />
    <CanonButton class="secondary" text="Go" />
    <CanonButton class="cell" text="Go" kind="cell" />
    <CanonButton class="segment" text="Go" kind="segment" :selected="true" />`,
		{ CanonButton },
	);
	const height = (s: string) => find(s).offsetHeight;
	expect(height('.primary')).toBe(68);
	expect(height('.secondary')).toBe(60);
	expect(height('.cell')).toBe(44);
	expect(find('.primary')).toHaveClass('canon-button--filled');
	expect(find('.segment')).toHaveClass('canon-button--filled');
	expect(find('.cell')).not.toHaveClass('canon-button--filled');
});

test('runs onClick unless disabled', async () => {
	let clicks = 0;
	const count = () => (clicks += 1);
	await render(
		`<CanonButton class="on" text="Go" :on-click="count" />
    <CanonButton class="off" text="Go" :on-click="count" :disabled="true" />`,
		{ CanonButton, count },
	);
	await click('.on');
	await click('.off').catch(() => undefined);
	expect(clicks).toBe(1);
});

test('an icon-only button is named by its label', async () => {
	await render(
		`<CanonButton kind="cell" :icon="Dot" label="Zoom in" />`,
		{
			CanonButton,
			Dot,
		},
	);
	expect(find('button')).toHaveAttribute('aria-label', 'Zoom in');
	expect(find('button')).toHaveClass('canon-button--symbol');
	expect(document.querySelector('.canon-button-title')).toBeNull();
});

test('oversized draws the icon behind the title', async () => {
	await render(
		`<CanonButton text="Wipe" :icon="Dot" icon-style="oversized" />`,
		{ CanonButton, Dot },
	);
	expect(
		document.querySelector('.canon-button-watermark svg'),
	).not.toBeNull();
	expect(document.querySelector('.canon-button-icon')).toBeNull();
	expect(find('.canon-button-title')).toHaveTextContent('Wipe');
});

test('flashesCopied shows Copied after a click', async () => {
	await render(
		`<CanonButton text="Copy" :icon="Dot" :flashes-copied="true" />`,
		{ CanonButton, Dot },
	);
	await click('button');
	expect(find('.canon-button-title')).toHaveTextContent('Copied');
});

test('repeats while held; the release does not add a step', async () => {
	let steps = 0;
	const step = () => (steps += 1);
	await render(
		`<CanonButton text="+" :repeats="true" :on-click="step" />`,
		{
			CanonButton,
			step,
		},
	);
	await triggerEvent('button', 'pointerdown', { button: 0 });
	await wait(600);
	await triggerEvent('button', 'pointerup', { button: 0 });
	const held = steps;
	await click('button');
	expect(held, `${held} steps while held`).toBeGreaterThanOrEqual(2);
	expect(steps).toBe(held);
	await click('button');
	expect(steps, 'a later tap steps once').toBe(held + 1);
});
