import { expect, test } from 'vitest';
import { render } from 'vitest-browser-svelte';
import CanonTextCell from '../src/components/canon-text-cell.svelte';
import { fillIn, find, triggerKeyEvent } from './helpers.ts';

test('reports every edit; Enter leaves the field', async () => {
	const edits: string[] = [];
	await render(CanonTextCell, {
		placeholder: 'Trigger',
		'aria-label': 'Trigger',
		onChange: (value) => edits.push(value),
	});
	expect(find('input').getAttribute('placeholder')).toBe('Trigger');
	expect(find('.canon-text-cell').offsetHeight).toBe(44);
	await fillIn('input', 'go');
	expect(edits).toEqual(['go']);
	await triggerKeyEvent('input', 'keydown', 'Enter');
	expect(document.activeElement).not.toBe(find('input'));
});
