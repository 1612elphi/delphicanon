import { describe, expect, test } from 'vitest';
import CanonButton from '../../src/components/canon-button.tsx';
import Dot from '../helpers/dot.tsx';
import { click, find, render, trigger, wait } from '../helpers/render.tsx';

describe('canon-button', () => {
	test('kinds set their heights and fill', async () => {
		await render(
			<>
				<CanonButton
					className="primary"
					text="Go"
					kind="primary"
				/>
				<CanonButton className="secondary" text="Go" />
				<CanonButton
					className="cell"
					text="Go"
					kind="cell"
				/>
				<CanonButton
					className="segment"
					text="Go"
					kind="segment"
					selected
				/>
			</>,
		);
		const height = (s: string) => find(s).offsetHeight;
		expect(height('.primary')).toBe(68);
		expect(height('.secondary')).toBe(60);
		expect(height('.cell')).toBe(44);
		expect(find('.primary').classList).toContain(
			'canon-button--filled',
		);
		expect(find('.segment').classList).toContain(
			'canon-button--filled',
		);
		expect(find('.cell').classList).not.toContain(
			'canon-button--filled',
		);
	});

	test('runs onClick unless disabled', async () => {
		let clicks = 0;
		const count = () => (clicks += 1);
		await render(
			<>
				<CanonButton
					className="on"
					text="Go"
					onClick={count}
				/>
				<CanonButton
					className="off"
					text="Go"
					onClick={count}
					disabled
				/>
			</>,
		);
		await click('.on');
		await click('.off');
		expect(clicks).toBe(1);
	});

	test('an icon-only button is named by its label', async () => {
		await render(
			<CanonButton
				kind="cell"
				icon={<Dot />}
				label="Zoom in"
			/>,
		);
		expect(find('button').getAttribute('aria-label')).toBe(
			'Zoom in',
		);
		expect(find('button').classList).toContain(
			'canon-button--symbol',
		);
		expect(
			document.querySelector('.canon-button-title'),
		).toBeNull();
	});

	test('oversized draws the icon behind the title', async () => {
		await render(
			<CanonButton
				text="Wipe"
				icon={<Dot />}
				iconStyle="oversized"
			/>,
		);
		expect(
			document.querySelector('.canon-button-watermark svg'),
		).not.toBeNull();
		expect(document.querySelector('.canon-button-icon')).toBeNull();
		expect(find('.canon-button-title').textContent).toBe('Wipe');
	});

	test('flashesCopied shows Copied after a click', async () => {
		await render(
			<CanonButton
				text="Copy"
				icon={<Dot />}
				flashesCopied
			/>,
		);
		await click('button');
		expect(find('.canon-button-title').textContent).toBe('Copied');
	});

	test('repeats while held; the release does not add a step', async () => {
		let steps = 0;
		const step = () => (steps += 1);
		await render(<CanonButton text="+" repeats onClick={step} />);
		await trigger('button', 'pointerdown', { button: 0 });
		await wait(600);
		await trigger('button', 'pointerup', { button: 0 });
		const held = steps;
		// the click that ends the hold
		await trigger('button', 'click');
		expect(held).toBeGreaterThanOrEqual(2);
		expect(steps).toBe(held);
		await click('button');
		expect(steps).toBe(held + 1);
	});
});
