import { expect, test } from 'vitest';
import CanonCanvas from '../../src/components/canon-canvas.vue';
import CanonPage from '../../src/components/canon-page.vue';
import { find, render } from '../helpers/render.ts';

test('caps and centres sections; a canvas spans the width', async () => {
  await render(
    `<div style="width: 1000px; height: 400px">
      <CanonPage>
        <div class="section">Section</div>
        <CanonCanvas :height="50" />
      </CanonPage>
    </div>`,
    { CanonPage, CanonCanvas },
  );
  const section = find('.section');
  expect(section.offsetWidth).toBe(720);
  expect(
    section.getBoundingClientRect().left -
      find('.canon-page').getBoundingClientRect().left,
  ).toBe(140);
  expect(find('.canon-canvas').offsetWidth).toBe(1000);
});

test('null maxWidth leaves only the padding', async () => {
  await render(
    `<div style="width: 1000px">
      <CanonPage :max-width="null"><div class="section">S</div></CanonPage>
    </div>`,
    { CanonPage },
  );
  expect(find('.section').offsetWidth).toBe(968);
});
