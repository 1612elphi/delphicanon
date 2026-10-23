import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import CanonSidebarRow from '#src/components/canon-sidebar-row.gts';
import Dot from '../helpers/dot.gts';

module('Component | canon-sidebar-row', function (hooks) {
	setupRenderingTest(hooks);

	test('is a button that reports clicks', async function (assert) {
		let clicks = 0;
		const tap = () => clicks++;
		await render(
			<template>
				<CanonSidebarRow
					@title="Toolbox"
					@icon={{Dot}}
					@onClick={{tap}}
				/>
			</template>,
		);
		assert.dom('button.canon-sidebar-row').hasText('Toolbox');
		assert.dom('.canon-sidebar-row').doesNotHaveAttribute(
			'aria-current',
		);
		assert.dom('.canon-sidebar-row').hasClass(
			'canon-sidebar-row--neutral',
		);
		assert.dom('.canon-sidebar-row-icon svg').exists();
		await click('.canon-sidebar-row');
		assert.strictEqual(clicks, 1);
	});

	test('is a link with an href and marks the current page', async function (assert) {
		await render(
			<template>
				<CanonSidebarRow
					@title="General"
					@href="#general"
					@light="warning"
					@selected={{true}}
				/>
			</template>,
		);
		assert.dom('a.canon-sidebar-row').hasAttribute(
			'href',
			'#general',
		);
		assert.dom('.canon-sidebar-row').hasAttribute(
			'aria-current',
			'page',
		);
		assert.dom('.canon-sidebar-row').hasClass(
			'canon-sidebar-row--warning',
		);
	});

	test('lights the leading edge only when on or warning', async function (assert) {
		await render(
			<template>
				<CanonSidebarRow
					class="on"
					@title="A"
					@light="on"
				/>
				<CanonSidebarRow
					class="off"
					@title="B"
					@light="off"
				/>
			</template>,
		);
		const capsule = (selector: string) =>
			getComputedStyle(
				document.querySelector(selector)!,
				'::after',
			).content;
		assert.strictEqual(capsule('.on'), '""');
		assert.strictEqual(capsule('.off'), 'none');
	});
});
