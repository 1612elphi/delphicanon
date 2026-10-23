import { reactive } from 'vue';
import { expect, test } from 'vitest';
import CanonTextArea from '../../src/components/canon-text-area.vue';
import { fillIn, find, render, settled } from '../helpers/render.ts';

test('reports typing; a new value does not replace text being typed', async () => {
	const model = reactive({ text: 'one' });
	const edits: string[] = [];
	const record = (value: string) => edits.push(value);
	await render(
		`<CanonTextArea
      :value="model.text"
      :height="120"
      placeholder="Notes"
      aria-label="Notes"
      :on-change="record"
    />`,
		{ CanonTextArea, model, record },
	);
	const area = find<HTMLTextAreaElement>('textarea');
	expect(area.value).toBe('one');
	expect(area.offsetHeight).toBe(120);
	await fillIn('textarea', 'typed');
	expect(edits).toEqual(['typed']);
	model.text = 'echo';
	await settled();
	expect(area.value, 'focused: kept').toBe('typed');
	area.blur();
	model.text = 'later';
	await settled();
	expect(area.value).toBe('later');
});
