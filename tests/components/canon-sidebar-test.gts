import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonSidebar from '#src/components/canon-sidebar.gts';
import CanonSidebarRow from '#src/components/canon-sidebar-row.gts';
import { css } from '../helpers/css.ts';

module('Component | canon-sidebar', function (hooks) {
	setupRenderingTest(hooks);

	test('holds a hero, headings and rows', async function (assert) {
		await render(
			<template>
				<div style={{css "height: 400px"}}>
					<CanonSidebar aria-label="Main">
						<:hero><img alt="" /></:hero>
						<:default>
							<CanonHeading
								@text="Modules"
							/>
							<CanonSidebarRow
								@title="Toolbox"
							/>
							<CanonSidebarRow
								@title="General"
							/>
						</:default>
					</CanonSidebar>
				</div>
			</template>,
		);
		assert.dom('nav.canon-sidebar').hasAttribute(
			'aria-label',
			'Main',
		);
		assert.dom('.canon-sidebar-hero img').exists();
		assert.dom('.canon-sidebar-rows .canon-heading').isVisible();
		assert.dom('.canon-sidebar-row').exists({ count: 2 });
	});

	test('collapses to the icon rail', async function (assert) {
		await render(
			<template>
				<div
					style={{css
						"display: flex; height: 400px"
					}}
				>
					<CanonSidebar class="wide">
						<CanonHeading @text="Modules" />
						<CanonSidebarRow
							@title="Toolbox"
						/>
					</CanonSidebar>
					<CanonSidebar
						class="rail"
						@collapsed={{true}}
					>
						<CanonHeading @text="Modules" />
						<CanonSidebarRow
							@title="Toolbox"
						/>
					</CanonSidebar>
				</div>
			</template>,
		);
		const wide = document.querySelector<HTMLElement>('.wide')!;
		const rail = document.querySelector<HTMLElement>('.rail')!;
		const cell = rail.querySelector<HTMLElement>(
			'.canon-sidebar-row-icon',
		)!;
		assert.true(rail.offsetWidth < wide.offsetWidth / 4);
		assert.true(
			rail.offsetWidth > cell.offsetWidth,
			'the rail keeps the cell',
		);
		assert.dom('.rail .canon-heading').isNotVisible();
		assert.dom('.rail .canon-sidebar-row').hasText(
			'Toolbox',
			'the title stays as the accessible name',
		);
	});

	test('compact rows are shorter and keep a square icon cell', async function (assert) {
		await render(
			<template>
				<div
					style={{css
						"display: flex; height: 400px"
					}}
				>
					<CanonSidebar class="regular">
						<CanonSidebarRow
							@title="Toolbox"
						/>
					</CanonSidebar>
					<CanonSidebar
						class="compact"
						@compact={{true}}
					>
						<CanonSidebarRow
							@title="Toolbox"
						/>
					</CanonSidebar>
				</div>
			</template>,
		);
		const row = (side: string) =>
			document.querySelector<HTMLElement>(
				`.${side} .canon-sidebar-row`,
			)!;
		const cell = document.querySelector<HTMLElement>(
			'.compact .canon-sidebar-row-icon',
		)!;
		assert.true(
			row('compact').offsetHeight <
				row('regular').offsetHeight,
		);
		assert.strictEqual(
			cell.offsetWidth,
			row('compact').offsetHeight,
		);
	});
});
