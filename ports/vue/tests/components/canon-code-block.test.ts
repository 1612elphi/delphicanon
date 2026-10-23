import { expect, test } from 'vitest';
import CanonCodeBlock from '../../src/components/canon-code-block.vue';
import { fakeClipboard } from '../helpers/fake-clipboard.ts';
import { click, find, render } from '../helpers/render.ts';

const long = Array.from(
	{ length: 40 },
	(_, i) => `line ${i} ${'lorem ipsum '.repeat(12)}`,
).join('\n');

test('lines do not wrap, maxHeight caps, copy writes the code', async () => {
	const written = fakeClipboard();
	await render(
		`<div style="width: 300px">
      <CanonCodeBlock :code="long" language="css" :max-height="160" />
    </div>`,
		{ CanonCodeBlock, long },
	);
	const code = find('.canon-code-block-code');
	expect(code.scrollWidth > code.clientWidth, 'scrolls sideways').toBe(
		true,
	);
	expect(code.offsetHeight).toBe(160);
	expect(find('.canon-code-block-language').textContent.trim()).toBe(
		'css',
	);
	await click('.canon-code-block-copy');
	expect(written).toEqual([long]);
	expect(
		document.querySelector('.canon-code-block-copy--copied'),
	).not.toBeNull();
});

test('without a language the copy button sits below', async () => {
	await render(`<CanonCodeBlock code="x" />`, { CanonCodeBlock });
	const bar = find('.canon-code-block-bar');
	const code = find('.canon-code-block-code');
	expect(
		bar.getBoundingClientRect().top >=
			code.getBoundingClientRect().bottom,
	).toBe(true);
});
