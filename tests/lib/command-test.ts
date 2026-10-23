import { module, test } from 'qunit';
import {
	answerScore,
	itemScore,
	keywordPenalty,
	matchScore,
	rank,
	step,
} from '#src/lib/command.ts';

module('Unit | lib/command', function () {
	test('matchScore tiers: prefix, word prefix, substring, subsequence', function (assert) {
		assert.strictEqual(matchScore('con', 'Contrast checker'), 90);
		assert.strictEqual(matchScore('CHE', 'Contrast checker'), 80);
		assert.strictEqual(matchScore('trast', 'Contrast checker'), 60);
		assert.strictEqual(matchScore('ccr', 'Contrast checker'), 40);
		assert.strictEqual(
			matchScore('xyz', 'Contrast checker'),
			undefined,
		);
		assert.strictEqual(matchScore('rc', 'Contrast checker'), 40);
		assert.strictEqual(
			matchScore('kc', 'Contrast checker'),
			undefined,
		);
	});

	test('keywords count one penalty lower; answers always match', function (assert) {
		const item = {
			id: 'a',
			title: 'Contrast checker',
			keywords: ['wcag'],
		};
		assert.strictEqual(itemScore('wc', item), 90 - keywordPenalty);
		assert.strictEqual(itemScore('co', item), 90);
		assert.strictEqual(itemScore('zz', item), undefined);
		assert.strictEqual(
			itemScore('zz', { id: 'b', title: '4', answer: true }),
			answerScore,
		);
	});

	test('rank keeps order for an empty query and groups by first appearance', function (assert) {
		const items = [
			{ id: '1', title: 'Beta', group: 'B' },
			{ id: '2', title: 'Alpha', group: 'A' },
			{ id: '3', title: 'Bravo', group: 'B' },
			{ id: '4', title: 'Answer', answer: true },
		];
		assert.deepEqual(
			rank(items, '  ').map((g) => [
				g.name,
				g.items.map((i) => i.id),
			]),
			[
				[undefined, ['4']],
				['B', ['1', '3']],
				['A', ['2']],
			],
		);
	});

	test('rank drops misses and sorts groups by their best score', function (assert) {
		const items = [
			{ id: '1', title: 'Tabs', group: 'B' },
			{ id: '2', title: 'Brave', group: 'A' },
			{ id: '3', title: 'Bravo', group: 'B' },
			{ id: '4', title: 'Grab bag', group: 'A' },
			{ id: '5', title: 'Cyan', group: 'C' },
		];
		assert.deepEqual(
			rank(items, 'bra').map((g) => [
				g.name,
				g.items.map((i) => i.id),
			]),
			[
				['A', ['2']],
				['B', ['3']],
			],
		);
		assert.deepEqual(
			rank(items, 'ba').map((g) => [
				g.name,
				g.items.map((i) => i.id),
			]),
			[
				['A', ['4', '2']],
				['B', ['3']],
			],
			'a word prefix beats a subsequence; ties keep the given order',
		);
	});

	test('step wraps at both ends', function (assert) {
		assert.strictEqual(step(0, 1, 3), 1);
		assert.strictEqual(step(2, 1, 3), 0);
		assert.strictEqual(step(0, -1, 3), 2);
		assert.strictEqual(step(-1, 1, 3), 0);
		assert.strictEqual(step(-1, -1, 3), 2);
		assert.strictEqual(step(0, 1, 0), -1);
	});
});
