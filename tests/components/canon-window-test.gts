import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import CanonSidebar from '#src/components/canon-sidebar.gts';
import CanonSidebarRow from '#src/components/canon-sidebar-row.gts';
import CanonWindow from '#src/components/canon-window.gts';
import { css } from '../helpers/css.ts';

module('Component | canon-window', function (hooks) {
  setupRenderingTest(hooks);

  test('draws the title bar and its controls', async function (assert) {
    const calls: string[] = [];
    const close = () => calls.push('close');
    const zoom = () => calls.push('zoom');
    await render(
      <template>
        <div style={{css "width: 900px; height: 500px"}}>
          <CanonWindow @title="Delphi" @onClose={{close}} @onZoom={{zoom}}>
            <:toolbar><button type="button" class="tool">T</button></:toolbar>
            <:menubar><span class="menu">M</span></:menubar>
            <:main><p class="detail">D</p></:main>
          </CanonWindow>
        </div>
      </template>,
    );
    assert.dom('section.canon-window').hasAria('labelledby', /-title$/);
    assert.dom('.canon-window-title').hasText('Delphi');
    assert.dom('.canon-window-toolbar .tool').exists();
    assert.dom('.canon-window-menubar .menu').exists();
    assert.dom('.canon-window-main .detail').exists();
    assert.dom('[aria-label="Minimise"]').isDisabled();
    await click('[aria-label="Close"]');
    await click('[aria-label="Zoom"]');
    assert.deepEqual(calls, ['close', 'zoom']);
  });

  test('leaves the controls out without callbacks', async function (assert) {
    await render(<template><CanonWindow /></template>);
    assert.dom('.canon-window-controls').doesNotExist();
    assert.dom('.canon-window-menubar').doesNotExist();
    assert.dom('.canon-window').doesNotHaveAria('labelledby');
  });

  test('collapses its sidebar when narrow', async function (assert) {
    await render(
      <template>
        <div style={{css "display: flex; gap: 8px; height: 400px"}}>
          <div style={{css "width: 900px"}}>
            <CanonWindow class="wide">
              <:sidebar><CanonSidebar><CanonSidebarRow
                    @title="A"
                  /></CanonSidebar></:sidebar>
            </CanonWindow>
          </div>
          <div style={{css "width: 400px"}}>
            <CanonWindow class="narrow">
              <:sidebar><CanonSidebar><CanonSidebarRow
                    @title="A"
                  /></CanonSidebar></:sidebar>
            </CanonWindow>
          </div>
          <div style={{css "width: 400px"}}>
            <CanonWindow class="kept">
              <:sidebar><CanonSidebar @collapsed={{false}}><CanonSidebarRow
                    @title="A"
                  /></CanonSidebar></:sidebar>
            </CanonWindow>
          </div>
        </div>
      </template>,
    );
    const width = (selector: string) =>
      document.querySelector<HTMLElement>(`${selector} .canon-sidebar`)!
        .offsetWidth;
    assert.true(width('.narrow') < width('.wide') / 4);
    assert.strictEqual(width('.kept'), width('.wide'));
  });
});
