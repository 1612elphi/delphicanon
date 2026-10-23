import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonDropZone from '../src/components/canon-drop-zone.svelte';
import { chooseFiles, find, findAll, settled, waitUntil } from './helpers.ts';

// 1 x 1 transparent PNG
const png = Uint8Array.from(
	atob(
		'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
	),
	(c) => c.charCodeAt(0),
);

function transfer(files: File[]) {
	const data = new DataTransfer();
	files.forEach((file) => data.items.add(file));
	return data;
}

async function drag(
	selector: string,
	type: string,
	dataTransfer: DataTransfer,
) {
	find(selector).dispatchEvent(
		new DragEvent(type, {
			bubbles: true,
			cancelable: true,
			dataTransfer,
		}),
	);
	await settled();
}

test('decodes a dropped image and names it', async () => {
	const got: string[] = [];
	await render(CanonDropZone, {
		prompt: 'Drop',
		onImages: (images, names) =>
			got.push(
				`${names[0]} ${images[0]!.width}x${images[0]!.height}`,
			),
	});
	expect(find('.canon-drop-zone-prompt').textContent).toBe('Drop');
	expect(findAll('button').length).toBe(2);
	const dataTransfer = transfer([
		new File(['text'], 'notes.txt', { type: 'text/plain' }),
		new File([png], 'dot.png', { type: 'image/png' }),
	]);
	await drag('.canon-drop-zone-target', 'dragenter', dataTransfer);
	expect(find('.canon-drop-zone-target').classList).toContain(
		'canon-drop-zone-target--over',
	);
	await drag('.canon-drop-zone-target', 'drop', dataTransfer);
	expect(find('.canon-drop-zone-target').classList).not.toContain(
		'canon-drop-zone-target--over',
	);
	await waitUntil(() => got.length > 0);
	expect(got, 'text skipped, image decoded').toEqual(['dot 1x1']);
});

test('onFiles passes files through; no Paste when off', async () => {
	const got: string[][] = [];
	await render(CanonDropZone, {
		prompt: 'Drop',
		accept: '',
		multiple: true,
		paste: false,
		onFiles: (files) => got.push(files.map((f) => f.name)),
	});
	expect(findAll('button').length).toBe(1);
	expect(find('input[type=file]').hasAttribute('multiple')).toBe(true);
	await chooseFiles('input[type=file]', [
		new File(['a'], 'a.wav'),
		new File(['b'], 'b.txt'),
	]);
	expect(got).toEqual([['a.wav', 'b.txt']]);
});
