import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import CanonHeading from '#src/components/canon-heading.gts';

module('Component | canon-heading', function (hooks) {
	setupRenderingTest(hooks);

	test('is a heading with its text', async function (assert) {
		await render(
			<template><CanonHeading @text="Rows" /></template>,
		);
		assert.dom('h3.canon-heading').hasText('Rows');
	});
});
