import { describe, expect, test } from 'vitest';
import CanonBar from '../../src/components/canon-bar.tsx';
import CanonRow from '../../src/components/canon-row.tsx';
import { find, render } from '../helpers/render.tsx';

describe('canon-row', () => {
  test('labels its control and passes the title id', async () => {
    await render(
      <CanonRow title="Mode" detail="Caption" form="flush">
        {(titleId) => (
          <button type="button" aria-labelledby={titleId}>
            Go
          </button>
        )}
      </CanonRow>,
    );
    expect(find('.canon-row').classList).toContain('canon-row--flush');
    expect(find('.canon-row-title').textContent).toBe('Mode');
    expect(find('.canon-row-detail').textContent).toBe('Caption');
    const id = find('.canon-row-title').id;
    expect(find('button').getAttribute('aria-labelledby')).toBe(id);
  });

  test('puts the control below the label when both do not fit', async () => {
    await render(
      <>
        <div style={{ width: 600 }} className="wide">
          <CanonRow title="Label" form="flush">
            <div style={{ width: 300, height: 44 }} />
          </CanonRow>
        </div>
        <div style={{ width: 300 }} className="narrow">
          <CanonRow title="Label" form="flush">
            <div style={{ width: 300, height: 44 }} />
          </CanonRow>
        </div>
      </>,
    );
    const offset = (scope: string) =>
      find(`${scope} .canon-row-control`).offsetTop -
      find(`${scope} .canon-row-label`).offsetTop;
    expect(offset('.wide')).toBe(0);
    expect(offset('.narrow')).toBeGreaterThan(0);
  });

  test('a bar shrinks beside the title before the row stacks', async () => {
    await render(
      <div style={{ width: 260 }}>
        <CanonRow title="Detail and icon">
          <CanonBar
            style={{ inlineSize: '100%', maxInlineSize: 160 }}
            share={0.5}
          />
        </CanonRow>
      </div>,
    );
    const label = find('.canon-row-label');
    const bar = find('.canon-bar');
    expect(bar.getBoundingClientRect().top).toBeLessThan(
      label.getBoundingClientRect().bottom,
    );
    expect(bar.offsetWidth).toBeLessThan(160);
  });

  test('a sizing title stacks a row whose own title fits', async () => {
    await render(
      <div style={{ width: 300 }}>
        <CanonRow title="A" sizingTitle="A much longer title than this row has">
          <div style={{ width: 120, height: 30 }} />
        </CanonRow>
      </div>,
    );
    expect(find('.canon-row-control').offsetTop).toBeGreaterThan(
      find('.canon-row-label').offsetTop,
    );
  });
});
