import { module, test } from 'qunit';
import { afterPress, attach, placementStyle } from '#src/lib/popover.ts';

module('Unit | lib/popover', function () {
  test('placements become position areas with a gap towards the anchor', function (assert) {
    assert.deepEqual(placementStyle('bottom-start'), {
      area: 'block-end span-inline-end',
      fallbacks: 'flip-block, flip-inline, flip-block flip-inline',
      gap: 'margin-block-start',
    });
    assert.strictEqual(
      placementStyle('top-end').area,
      'block-start span-inline-start',
    );
    assert.strictEqual(placementStyle('top').area, 'block-start');
    assert.deepEqual(placementStyle('right-start'), {
      area: 'inline-end span-block-end',
      fallbacks: 'flip-inline, flip-block, flip-inline flip-block',
      gap: 'margin-inline-start',
    });
    assert.strictEqual(placementStyle('left').gap, 'margin-inline-end');
  });

  test('a popover opened during a press waits for its release', async function (assert) {
    const opened: string[] = [];
    afterPress(false, () => opened.push('free'));
    assert.deepEqual(opened, ['free'], 'no press: now');
    afterPress(true, () => opened.push('held'));
    await new Promise((resolve) => setTimeout(resolve));
    assert.deepEqual(opened, ['free'], 'held: not yet');
    window.dispatchEvent(new PointerEvent('pointerup'));
    assert.deepEqual(opened, ['free'], 'after the release, not during it');
    await new Promise((resolve) => setTimeout(resolve));
    assert.deepEqual(opened, ['free', 'held']);
    window.dispatchEvent(new PointerEvent('pointerup'));
    await new Promise((resolve) => setTimeout(resolve));
    assert.deepEqual(opened, ['free', 'held'], 'once');
  });

  test('an anchor keeps its name when its style attribute is rewritten', async function (assert) {
    const anchor = document.createElement('button');
    const panel = document.createElement('div');
    panel.popover = 'auto';
    document.body.append(anchor, panel);
    const detach = attach(panel, anchor, { placement: 'bottom-start' });
    const name = panel.style.getPropertyValue('position-anchor');
    anchor.setAttribute('style', 'left: 4px');
    await Promise.resolve();
    assert.strictEqual(anchor.style.getPropertyValue('anchor-name'), name);
    assert.strictEqual(anchor.style.left, '4px');
    detach();
    anchor.setAttribute('style', 'left: 8px');
    await Promise.resolve();
    assert.strictEqual(anchor.style.getPropertyValue('anchor-name'), '');
    anchor.remove();
    panel.remove();
  });
});
