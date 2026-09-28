import { useState, type ReactNode } from 'react';
import { describe, expect, test } from 'vitest';
import CanonButton from '../../src/components/canon-button.tsx';
import CanonDialog from '../../src/components/canon-dialog.tsx';
import {
  click,
  find,
  findAll,
  focus,
  render,
  settle,
  trigger,
  wait,
  waitUntil,
} from '../helpers/render.tsx';

/** Holds `open` as a dialog's owner does; `#<name>` opens it, `#<name>-shut` sets it false. */
function Owner({
  name,
  closes,
  initial = false,
  children,
}: {
  name: string;
  closes: string[];
  initial?: boolean;
  children: (open: boolean, onClose: (value: string) => void) => ReactNode;
}) {
  const [open, setOpen] = useState(initial);
  return (
    <>
      <CanonButton id={name} text="Open" onClick={() => setOpen(true)} />
      <button type="button" id={`${name}-shut`} onClick={() => setOpen(false)}>
        Shut
      </button>
      {children(open, (value) => {
        setOpen(false);
        closes.push(value);
      })}
    </>
  );
}

// waiters miss the motion
const closed = (dialog: HTMLDialogElement) =>
  waitUntil(() => !dialog.open).then(() => settle());

const cancel = (dialog: HTMLDialogElement) =>
  settle(() => dialog.dispatchEvent(new Event('cancel', { cancelable: true })));

describe('canon-dialog', () => {
  test('opens modal, returns a value from the footer and focus to the invoker', async () => {
    const closes: string[] = [];
    await render(
      <Owner name="opener" closes={closes}>
        {(open, onClose) => (
          <CanonDialog
            open={open}
            title="Export"
            message="Text"
            onClose={onClose}
            footer={(close) => (
              <>
                <CanonButton text="Cancel" onClick={() => close('cancel')} />
                <CanonButton text="Save" onClick={() => close('save')} />
              </>
            )}
          >
            <p className="row">Body</p>
          </CanonDialog>
        )}
      </Owner>,
    );
    const dialog = find<HTMLDialogElement>('dialog');
    expect(dialog.open).toBe(false);
    expect(
      findAll('.canon-dialog-body'),
      'content renders while open',
    ).toHaveLength(0);

    await focus('#opener');
    await click('#opener');
    expect(dialog.open).toBe(true);
    expect(dialog.matches(':modal'), 'showModal').toBe(true);
    expect(dialog.getAttribute('aria-labelledby')).toBe(
      find('.canon-heading').id,
    );
    expect(dialog.getAttribute('aria-describedby')).toBe(
      find('.canon-dialog-message').id,
    );
    expect(find('.canon-dialog-title').textContent).toBe('Export');
    expect(
      findAll('.canon-dialog-footer.canon-grid .canon-button'),
    ).toHaveLength(2);

    await click('.canon-dialog-footer .canon-button:last-child');
    await closed(dialog);
    expect(closes).toEqual(['save']);
    expect(document.activeElement, 'focus returns').toBe(find('#opener'));
    expect(findAll('.canon-dialog-body')).toHaveLength(0);

    await click('#opener');
    await cancel(dialog);
    await closed(dialog);
    expect(closes, 'Escape closes with no value').toEqual(['save', '']);
  });

  test('the backdrop closes a dialog but not an alert; dismissable false holds both', async () => {
    const plainCloses: string[] = [];
    const alertCloses: string[] = [];
    const heldCloses: string[] = [];
    await render(
      <>
        <Owner name="plain" closes={plainCloses}>
          {(open, onClose) => (
            <CanonDialog open={open} onClose={onClose}>
              <p>Plain</p>
            </CanonDialog>
          )}
        </Owner>
        <Owner name="alert" closes={alertCloses}>
          {(open, onClose) => (
            <CanonDialog open={open} alert onClose={onClose}>
              <p>Alert</p>
            </CanonDialog>
          )}
        </Owner>
        <Owner name="held" closes={heldCloses}>
          {(open, onClose) => (
            <CanonDialog open={open} dismissable={false} onClose={onClose}>
              <p>Held</p>
            </CanonDialog>
          )}
        </Owner>
      </>,
    );
    const [plain, alerting, holding] = findAll<HTMLDialogElement>('dialog');
    const backdrop = async (dialog: HTMLDialogElement) => {
      await trigger(dialog, 'pointerdown');
      await trigger(dialog, 'click', { clientX: 1, clientY: 1 });
    };

    await click('#plain');
    await backdrop(plain!);
    await closed(plain!);
    expect(plainCloses, 'a plain dialog closes').toEqual(['']);

    await click('#alert');
    expect(alerting!.getAttribute('role')).toBe('alertdialog');
    await backdrop(alerting!);
    expect(alerting!.open, 'an alert stays').toBe(true);
    await cancel(alerting!);
    await closed(alerting!);
    expect(alertCloses, 'Escape closes an alert').toEqual(['']);

    await click('#held');
    await backdrop(holding!);
    await cancel(holding!);
    await wait(300);
    expect(holding!.open, 'not dismissable').toBe(true);
    await click('#held-shut');
    expect(holding!.open, 'the owner closes it').toBe(false);
  });

  test('the top layer covers fixed page elements at any z-index', async () => {
    await render(
      <>
        <div
          className="floating"
          style={{
            position: 'fixed',
            inset: 'auto 0 0',
            blockSize: 60,
            zIndex: 2147483647,
          }}
        >
          Footer
        </div>
        <Owner name="opener" closes={[]} initial>
          {(open, onClose) => (
            <CanonDialog open={open} onClose={onClose}>
              <p>Body</p>
            </CanonDialog>
          )}
        </Owner>
      </>,
    );
    const box = find('.floating').getBoundingClientRect();
    const hit = document.elementFromPoint(
      box.left + box.width / 2,
      box.top + box.height / 2,
    );
    expect(hit).toBe(find('dialog'));
  });
});
