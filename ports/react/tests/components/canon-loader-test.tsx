import { describe, expect, test } from 'vitest';
import CanonLoader from '../../src/components/canon-loader.tsx';
import { find, findAll, render } from '../helpers/render.tsx';

describe('canon-loader', () => {
  test('nine cells sized by cell and gap', async () => {
    await render(
      <>
        <CanonLoader className="big" />
        <CanonLoader className="small" mode="thinking" cell={4} gap={1} />
      </>,
    );
    expect(findAll('.big > *')).toHaveLength(9);
    expect(find('.big').getAttribute('role')).toBe('status');
    expect(find('.big').getAttribute('aria-label')).toBe('Loading');
    expect(find('.small').classList).toContain('canon-loader--thinking');
    expect(find('.big').offsetWidth).toBe(28);
    expect(find('.small').offsetWidth).toBe(14);
  });
});
