import { describe, expect, test } from 'vitest';
import CanonSidebar from '../../src/components/canon-sidebar.tsx';
import CanonSidebarRow from '../../src/components/canon-sidebar-row.tsx';
import CanonWindow from '../../src/components/canon-window.tsx';
import { click, find, findAll, render } from '../helpers/render.tsx';

describe('canon-window', () => {
  test('draws the title bar and its controls', async () => {
    const calls: string[] = [];
    await render(
      <div style={{ width: 900, height: 500 }}>
        <CanonWindow
          title="Delphi"
          onClose={() => calls.push('close')}
          onZoom={() => calls.push('zoom')}
          toolbar={
            <button type="button" className="tool">
              T
            </button>
          }
          menubar={<span className="menu">M</span>}
          main={<p className="detail">D</p>}
        />
      </div>,
    );
    expect(
      find('section.canon-window').getAttribute('aria-labelledby'),
    ).toMatch(/-title$/);
    expect(find('.canon-window-title').textContent).toBe('Delphi');
    expect(findAll('.canon-window-toolbar .tool')).toHaveLength(1);
    expect(findAll('.canon-window-menubar .menu')).toHaveLength(1);
    expect(findAll('.canon-window-main .detail')).toHaveLength(1);
    expect(find<HTMLButtonElement>('[aria-label="Minimise"]').disabled).toBe(
      true,
    );
    await click('[aria-label="Close"]');
    await click('[aria-label="Zoom"]');
    expect(calls).toEqual(['close', 'zoom']);
  });

  test('leaves the controls out without callbacks', async () => {
    await render(<CanonWindow />);
    expect(findAll('.canon-window-controls')).toHaveLength(0);
    expect(findAll('.canon-window-menubar')).toHaveLength(0);
    expect(find('.canon-window').hasAttribute('aria-labelledby')).toBe(false);
  });

  test('collapses its sidebar when narrow', async () => {
    const sidebar = (collapsed?: boolean) => (
      <CanonSidebar collapsed={collapsed}>
        <CanonSidebarRow title="A" />
      </CanonSidebar>
    );
    await render(
      <div style={{ display: 'flex', gap: 8, height: 400 }}>
        <div style={{ width: 900 }}>
          <CanonWindow className="wide" sidebar={sidebar()} />
        </div>
        <div style={{ width: 400 }}>
          <CanonWindow className="narrow" sidebar={sidebar()} />
        </div>
        <div style={{ width: 400 }}>
          <CanonWindow className="kept" sidebar={sidebar(false)} />
        </div>
      </div>,
    );
    const width = (selector: string) =>
      find(`${selector} .canon-sidebar`).offsetWidth;
    expect(width('.narrow')).toBeLessThan(width('.wide') / 4);
    expect(width('.kept')).toBe(width('.wide'));
  });
});
