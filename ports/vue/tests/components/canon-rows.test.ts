import { expect, test } from 'vitest';
import CanonRows from '../../src/components/canon-rows.vue';
import { find, render } from '../helpers/render.ts';

test('stacks rows a hairline apart, framed on request', async () => {
  await render(
    `<CanonRows :framed="true">
      <div class="a">A</div>
      <div class="b">B</div>
    </CanonRows>`,
    { CanonRows },
  );
  const a = find('.a');
  const b = find('.b');
  expect(b.offsetTop - (a.offsetTop + a.offsetHeight)).toBe(1);
  expect(getComputedStyle(find('.canon-rows')).paddingTop).toBe('2px');
});
