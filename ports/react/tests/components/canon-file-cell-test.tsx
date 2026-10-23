import { describe, expect, test } from 'vitest';
import CanonFileCell from '../../src/components/canon-file-cell.tsx';
import { find, render, trigger } from '../helpers/render.tsx';

describe('canon-file-cell', () => {
	test('shows None, then the chosen file name', async () => {
		const picked: string[] = [];
		const record = (file: File) => picked.push(file.name);
		await render(
			<CanonFileCell accept="image/*" onChange={record} />,
		);
		expect(find('.canon-file-cell-name').textContent).toBe('None');
		expect(find('input[type=file]').getAttribute('accept')).toBe(
			'image/*',
		);
		expect(find('button').textContent).toBe('Choose');
		const file = new File(['x'], 'a-rather-long-name.png', {
			type: 'image/png',
		});
		const input = find<HTMLInputElement>('input[type=file]');
		const files = new DataTransfer();
		files.items.add(file);
		input.files = files.files;
		await trigger(input, 'change');
		expect(picked).toEqual(['a-rather-long-name.png']);
		expect(find('.canon-file-cell-tail').textContent).toBe(
			'name.png',
		);
	});
});
