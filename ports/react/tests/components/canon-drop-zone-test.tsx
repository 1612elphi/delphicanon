import { describe, expect, test } from 'vitest';
import CanonDropZone from '../../src/components/canon-drop-zone.tsx';
import {
	find,
	findAll,
	render,
	settle,
	trigger,
	wait,
} from '../helpers/render.tsx';

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

function drag(selector: string, type: string, dataTransfer: DataTransfer) {
	return settle(() =>
		find(selector).dispatchEvent(
			new DragEvent(type, {
				bubbles: true,
				cancelable: true,
				dataTransfer,
			}),
		),
	);
}

// as @ember/test-helpers waitUntil: polls every 10 ms, gives up after 1 s
async function waitUntil(done: () => boolean) {
	for (let i = 0; i < 100 && !done(); i++) await wait(10);
}

describe('canon-drop-zone', () => {
	test('decodes a dropped image and names it', async () => {
		const got: string[] = [];
		const record = (images: ImageBitmap[], names: string[]) =>
			got.push(
				`${names[0]} ${images[0]!.width}x${images[0]!.height}`,
			);
		await render(<CanonDropZone prompt="Drop" onImages={record} />);
		expect(find('.canon-drop-zone-prompt').textContent).toBe(
			'Drop',
		);
		expect(findAll('button')).toHaveLength(2);
		const dataTransfer = transfer([
			new File(['text'], 'notes.txt', { type: 'text/plain' }),
			new File([png], 'dot.png', { type: 'image/png' }),
		]);
		await drag(
			'.canon-drop-zone-target',
			'dragenter',
			dataTransfer,
		);
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
		const record = (files: File[]) =>
			got.push(files.map((f) => f.name));
		await render(
			<CanonDropZone
				prompt="Drop"
				accept=""
				multiple
				paste={false}
				onFiles={record}
			/>,
		);
		expect(findAll('button')).toHaveLength(1);
		const input = find<HTMLInputElement>('input[type=file]');
		expect(input.hasAttribute('multiple')).toBe(true);
		input.files = transfer([
			new File(['a'], 'a.wav'),
			new File(['b'], 'b.txt'),
		]).files;
		await trigger(input, 'change');
		expect(got).toEqual([['a.wav', 'b.txt']]);
	});
});
