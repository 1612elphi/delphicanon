import { module, test } from 'qunit';
import { glyphRows, type GlyphKind } from '#src/lib/glyph-rows.ts';

const g: GlyphKind = 'glyph';
const s: GlyphKind = 'space';

module('Unit | lib/glyph-rows', function () {
	test('a word that does not fit wraps whole', function (assert) {
		const { frames, rows } = glyphRows(
			[20, 20, 10, 20, 20],
			[g, g, s, g, g],
			60,
			0,
			10,
			12,
		);
		assert.strictEqual(rows, 2);
		assert.deepEqual(frames[3], {
			x: 0,
			y: 12,
			width: 20,
			height: 10,
		});
	});

	test('a space that would lead a row takes no width', function (assert) {
		const { frames, rows } = glyphRows(
			[50, 10, 50],
			[g, s, g],
			60,
			0,
			10,
			12,
		);
		assert.strictEqual(rows, 2);
		assert.strictEqual(frames[2]!.x, 0);
	});

	test('a word wider than a row splits', function (assert) {
		assert.strictEqual(
			glyphRows([40, 40, 40], [g, g, g], 90, 5, 10, 12).rows,
			2,
		);
	});

	test('a newline starts a row; nothing is no rows', function (assert) {
		assert.strictEqual(
			glyphRows([10, 0, 10], [g, 'newline', g], 90, 0, 10, 12)
				.rows,
			2,
		);
		assert.strictEqual(glyphRows([], [], 90, 0, 10, 12).rows, 0);
	});

	test('glyphs in a row are spaced by the gap', function (assert) {
		const { frames } = glyphRows([10, 10], [g, g], 90, 4, 10, 12);
		assert.strictEqual(frames[1]!.x, 14);
	});
});
