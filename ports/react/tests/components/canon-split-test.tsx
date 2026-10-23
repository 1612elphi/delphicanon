import { describe, expect, test } from 'vitest';
import CanonCanvas from '../../src/components/canon-canvas.tsx';
import CanonSplit from '../../src/components/canon-split.tsx';
import { find, render, settle } from '../helpers/render.tsx';

const layout = () =>
	getComputedStyle(find('.canon-split-body'))
		.getPropertyValue('--canon-split-layout')
		.trim();
const box = (selector: string) => find(selector).getBoundingClientRect();

describe('canon-split', () => {
	test('wide: a 340 px sidebar beside the main pane, banner across both', async () => {
		await render(
			<div style={{ width: 1000, height: 600 }}>
				<CanonSplit
					banner={<CanonCanvas height={100} />}
					sidebar={
						<div className="side">Side</div>
					}
					main={<div className="main">Main</div>}
					footer={
						<div className="strip">
							Strip
						</div>
					}
				/>
			</div>,
		);
		expect(layout()).toBe('wide');
		expect(find('.canon-split-sidebar').offsetWidth).toBe(340);
		expect(find('.canon-split-main').offsetLeft).toBe(341);
		expect(find('.canon-split-banner').offsetWidth).toBe(1000);
		expect(
			find('.canon-split-main .canon-split-footer')
				.textContent,
		).toBe('Strip');
	});

	test('narrow or portrait: one column, sidebar first', async () => {
		await render(
			<div style={{ width: 500, height: 800 }}>
				<CanonSplit
					sidebar={
						<div className="side">Side</div>
					}
					main={<div className="main">Main</div>}
				/>
			</div>,
		);
		expect(layout()).toBe('stacked');
		expect(box('.main').top).toBeGreaterThan(box('.side').top);
		expect(box('.main').left).toBe(box('.side').left);
	});

	test('oneColumn stacks at every width', async () => {
		await render(
			<div style={{ width: 1000, height: 600 }}>
				<CanonSplit
					oneColumn
					sidebar={
						<div className="side">Side</div>
					}
					main={<div className="main">Main</div>}
				/>
			</div>,
		);
		expect(layout()).toBe('stacked');
		expect(box('.main').top).toBeGreaterThan(box('.side').top);
	});

	test('mainLeadsStacked and halves', async () => {
		await render(
			<>
				<div
					className="stacked"
					style={{ width: 500, height: 800 }}
				>
					<CanonSplit
						mainLeadsStacked
						sidebar={
							<div className="side">
								Side
							</div>
						}
						main={
							<div className="main">
								Main
							</div>
						}
					/>
				</div>
				<div
					className="halves"
					style={{ width: 1001, height: 600 }}
				>
					<CanonSplit
						halves
						sidebar={
							<CanonCanvas
								aspect={1}
							/>
						}
						main={<div>Main</div>}
					/>
				</div>
			</>,
		);
		expect(box('.stacked .side').top).toBeGreaterThan(
			box('.stacked .main').top,
		);
		const picture = find(
			'.halves .canon-split-sidebar .canon-canvas',
		);
		expect(picture.offsetWidth).toBe(500);
		expect(picture.offsetHeight).toBe(600);
	});

	test('a collapsing picture refits to a new aspect', async () => {
		const at = (aspect: number) => (
			<div style={{ width: 500, height: 800 }}>
				<CanonSplit
					halves
					collapsesTo={100}
					sidebar={
						<CanonCanvas aspect={aspect} />
					}
					main={<div>Main</div>}
				/>
			</div>
		);
		const { rerender } = await render(at(1));
		const split = find('.canon-split');
		const full = () =>
			split.style.getPropertyValue('--canon-split-full');
		expect(split.hasAttribute('data-collapsing')).toBe(true);
		expect(full()).toBe('480px');
		await rerender(at(2));
		await settle();
		expect(full(), 'half the width and the frame').toBe('254px');
	});

	test('footerHidden takes the footer away', async () => {
		await render(
			<div style={{ width: 1000, height: 600 }}>
				<CanonSplit
					footerHidden
					main={<div>Main</div>}
					footer={<div>Strip</div>}
				/>
			</div>,
		);
		expect(
			document.querySelector('.canon-split-footer'),
		).toBeNull();
	});
});
