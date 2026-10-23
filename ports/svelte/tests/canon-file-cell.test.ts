import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonFileCell from '../src/components/canon-file-cell.svelte';
import { chooseFiles, find } from './helpers.ts';

test('shows None, then the chosen file name', async () => {
	const picked: string[] = [];
	await render(CanonFileCell, {
		accept: 'image/*',
		onChange: (file) => picked.push(file.name),
	});
	expect(find('.canon-file-cell-name').textContent?.trim()).toBe('None');
	expect(find('input[type=file]').getAttribute('accept')).toBe('image/*');
	expect(find('button').textContent?.trim()).toBe('Choose');
	const file = new File(['x'], 'a-rather-long-name.png', {
		type: 'image/png',
	});
	await chooseFiles('input[type=file]', [file]);
	expect(picked).toEqual(['a-rather-long-name.png']);
	expect(find('.canon-file-cell-tail').textContent).toBe('name.png');
});
