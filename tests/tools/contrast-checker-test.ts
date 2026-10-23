import { module, test } from 'qunit';
import {
	contrastFigure,
	contrastRatio,
	fromHsl,
	hsl,
	parseHex,
} from '#src/lib/colour.ts';
import {
	adjust,
	share,
	suggest,
	targets,
} from '../../demo-app/components/tools/contrast-checker/contrast.ts';

const colour = (code: string) => parseHex(code)!;
const white = colour('FFFFFF');
const black = colour('000000');

module('Unit | tools/contrast-checker', function () {
	test('the figure never rounds up past a threshold', function (assert) {
		assert.strictEqual(contrastFigure(4.499), '4.49');
		assert.strictEqual(contrastFigure(4.5), '4.5');
		assert.strictEqual(contrastFigure(7.001), '7');
		assert.strictEqual(
			contrastFigure(contrastRatio(white, black)),
			'21',
		);
	});

	test('the scale is logarithmic from 1 to 21', function (assert) {
		assert.strictEqual(share(1), 0);
		assert.strictEqual(share(0.5), 0);
		assert.strictEqual(share(21), 1);
		assert.ok(Math.abs(share(Math.sqrt(21)) - 0.5) < 1e-9);
	});

	test('adjust moves grey to the nearest passing lightness, darker on white', function (assert) {
		const grey = colour('777777');
		const fixed = adjust(grey, white, 4.5);
		assert.ok(contrastRatio(fixed, white) >= 4.5);
		assert.ok(hsl(fixed)[2] < hsl(grey)[2]);
		// nearest, not the extreme: one step lighter fails
		const [h, s, l] = hsl(fixed);
		assert.ok(contrastRatio(fromHsl(h, s, l + 1), white) < 4.5);
	});

	test('adjust moves lighter on a dark ground', function (assert) {
		const dark = colour('1A1A2E');
		const ink = colour('444444');
		const fixed = adjust(ink, dark, 7);
		assert.ok(contrastRatio(fixed, dark) >= 7);
		assert.ok(hsl(fixed)[2] > hsl(ink)[2]);
	});

	test('suggestions are empty once the level passes, and when none reaches it', function (assert) {
		const [fgAa, fgAaa, bgAa] = targets;
		assert.strictEqual(suggest(fgAa!, black, white), undefined);
		const grey = colour('808080');
		const candidate = suggest(fgAa!, grey, grey);
		assert.ok(candidate && contrastRatio(candidate, grey) >= 4.5);
		const moved = suggest(bgAa!, grey, grey);
		assert.ok(moved && contrastRatio(grey, moved) >= 4.5);
		// white reaches 3.95:1 on mid grey and black 5.32:1, so no lightness reaches 7:1
		assert.strictEqual(suggest(fgAaa!, grey, grey), undefined);
	});
});
