import { defineComponent } from 'vue';
import { expect, test } from 'vitest';
import { vSidewaysPan } from '../../src/lib/sideways-pan.ts';
import { vGrabPan } from '../../src/lib/grab-pan.ts';
import { find, render, triggerEvent } from '../helpers/render.ts';

const Pad = defineComponent({
  directives: { sidewaysPan: vSidewaysPan, grabPan: vGrabPan },
  props: { sideways: Object, grab: Object },
  template: `<div v-if="sideways" class="pad" style="width: 200px; height: 100px" v-sideways-pan="sideways"></div>
    <div v-else class="pad" style="width: 200px; height: 100px" v-grab-pan="grab"></div>`,
});

const point = (x: number, y: number) => ({
  pointerId: 1,
  button: 0,
  clientX: x,
  clientY: y,
});

test('a sideways pan begins only on a clearly sideways drag', async () => {
  const moves: number[] = [];
  const onMove = (event: PointerEvent) => moves.push(event.clientX);
  await render(`<Pad :sideways="{ onMove }" />`, { Pad, onMove });
  expect(find('.pad').style.touchAction).toBe('pan-y');
  await triggerEvent('.pad', 'pointerdown', point(10, 10));
  await triggerEvent('.pad', 'pointermove', point(12, 20));
  await triggerEvent('.pad', 'pointermove', point(40, 20));
  await triggerEvent('.pad', 'pointerup', point(40, 20));
  expect(moves, 'a downward start never begins').toEqual([]);
  await triggerEvent('.pad', 'pointerdown', point(10, 10));
  await triggerEvent('.pad', 'pointermove', point(13, 10));
  await triggerEvent('.pad', 'pointermove', point(30, 12));
  await triggerEvent('.pad', 'pointermove', point(50, 12));
  expect(moves).toEqual([30, 50]);
});

test('a grab pan begins only where grabs says', async () => {
  const begun: number[] = [];
  const grabs = ({ x }: { x: number }) => x < 50;
  const onBegin = (event: PointerEvent) => begun.push(event.clientX);
  await render(`<Pad :grab="{ grabs, onBegin }" />`, { Pad, grabs, onBegin });
  const box = find('.pad').getBoundingClientRect();
  await triggerEvent('.pad', 'pointerdown', point(box.left + 150, box.top + 5));
  await triggerEvent('.pad', 'pointerup', point(box.left + 150, box.top + 5));
  await triggerEvent('.pad', 'pointerdown', point(box.left + 10, box.top + 5));
  expect(begun).toEqual([box.left + 10]);
});
