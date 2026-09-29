import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type DialogHTMLAttributes,
  type Ref,
} from 'react';
import { capture } from '@canon/lib/motion.ts';
import { Expression, type Key } from '@canon/lib/math/expression.ts';
import { keyForKeyboard, keypadHeight } from '@canon/lib/math/keypad.ts';
import { springEasing } from '@canon/lib/motion.ts';
import CanonMathEditor from './canon-math-editor.tsx';
import CanonMathKeypad from './canon-math-keypad.tsx';
import CanonMathRail, { railHeights } from './canon-math-rail.tsx';
import CanonRows from './canon-rows.tsx';
import { cx } from '../lib/class-names.ts';
import { MathEditing } from '../lib/math-editing.ts';
import { useLatest, useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-input.css';

export interface CanonMathInputProps extends Omit<
  DialogHTMLAttributes<HTMLDialogElement>,
  'onChange' | 'onClose'
> {
  /** nerdamer syntax. */
  text?: string;
  variable?: string;
  /** Typed once the sheet opens. */
  keys?: Key[];
  /** The element whose pane the sheet docks to on a regular width. */
  source?: HTMLElement | null;
  /** Every edit, with the text. */
  onChange?: (text: string) => void;
  /** The sheet closed, with the text. */
  onClose?: (text: string) => void;
  ref?: Ref<HTMLDialogElement>;
}

/** Editor height, and the height in a short window. */
export const editorHeights = { regular: 112, short: 84 };
/** Windows shorter than this get the short keys and editor. */
export const shortWindow = 800;
/** Widest the docked sheet gets. */
export const maxWidth = 560;
/** Gap between the display and the keypad. */
export const gap = 12;
/** Container width from which the sheet docks to the pane: CanonSplit's two-column width. */
export const regularWidth = 640;
/** Drag, in px, or speed, in px per second, that closes the sheet. */
export const closing = { distance: 100, speed: 900 };

/** Height of the content, without the bottom safe area. */
export function contentHeight(short: boolean): number {
  const display =
    (short ? editorHeights.short : editorHeights.regular) +
    1 +
    (short ? railHeights.short : railHeights.regular);
  return 16 * 2 + 2 * 4 + display + gap + keypadHeight(short);
}

function still(): boolean {
  return matchMedia('(prefers-reduced-motion: reduce)').matches;
}

interface Opened {
  editing: MathEditing;
  short: boolean;
  docked: boolean;
}

/**
 * The expression over its caret rail and the keypad, as a sheet
 * (CanonMathInputViewController with CanonPaneSheetPresentation). On a
 * compact container a bottom sheet with a small and a large height; on a
 * regular one docked to the bottom of the source's pane. Done, Enter,
 * Escape, a drag down or a click outside closes it.
 */
export default function CanonMathInput({
  text,
  variable,
  keys,
  source,
  onChange,
  onClose,
  className,
  style,
  ref,
  ...rest
}: CanonMathInputProps) {
  const latest = useLatest(onChange);
  const [{ editing, short, docked }] = useState<Opened>(() => {
    const expression = new Expression(text ?? '', variable ?? 'x');
    for (const key of keys ?? []) expression.apply(key);
    const container =
      source?.closest('.canon-split') ?? document.documentElement;
    return {
      editing: new MathEditing(expression, (text) => latest.current?.(text)),
      short: window.innerHeight < shortWindow,
      docked: container.clientWidth >= regularWidth,
    };
  });
  const [large, setLarge] = useState(false);
  const [pane, setPane] = useState<{ left: number; width: number }>();
  const finished = useRef(false);
  const dialogRef = useRef<HTMLDialogElement>(null);

  // the owner updates its own state, so after this commit
  useEffect(() => {
    if (keys?.length) latest.current?.(editing.expression.text);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /** The source's pane, the nearest CanonPage, or the whole window. */
  const measurePane = () => {
    const page = source?.closest('.canon-page');
    const rect = page?.getBoundingClientRect();
    const box =
      rect && rect.width > 0
        ? rect
        : { left: 0, width: document.documentElement.clientWidth };
    const width = Math.min(maxWidth, box.width);
    setPane({ left: box.left + (box.width - width) / 2, width });
  };

  const finish = () => {
    if (finished.current) return;
    finished.current = true;
    const dialog = dialogRef.current;
    const done = () => {
      dialog?.close();
      onClose?.(editing.expression.text);
    };
    if (!dialog || still()) return done();
    dialog
      .animate([{ transform: 'none' }, { transform: 'translateY(100%)' }], {
        duration: 250,
        easing: 'cubic-bezier(0.4, 0, 1, 1)',
        fill: 'forwards',
      })
      .finished.then(done, done);
  };
  const live = useLatest({ large, measurePane, finish });

  const present = useCallback(
    (dialog: HTMLDialogElement | null) => {
      dialogRef.current = dialog;
      if (!dialog) return;
      const finish = () => live.current.finish();
      const measurePane = () => live.current.measurePane();
      if (docked) measurePane();
      if (!dialog.open) dialog.showModal();
      dialog.focus({ preventScroll: true });
      if (!still())
        dialog.animate(
          [{ transform: 'translateY(100%)' }, { transform: 'none' }],
          { duration: 350, easing: 'cubic-bezier(0.2, 0.8, 0.2, 1)' },
        );

      const cancel = (event: Event) => {
        event.preventDefault();
        finish();
      };
      const outside = (event: MouseEvent) => {
        if (event.target !== dialog) return;
        const r = dialog.getBoundingClientRect();
        const inside =
          event.clientX >= r.left &&
          event.clientX <= r.right &&
          event.clientY >= r.top &&
          event.clientY <= r.bottom;
        if (!inside) finish();
      };
      const keydown = (event: KeyboardEvent) => {
        if (event.ctrlKey || event.metaKey || event.altKey) return;
        if (event.key === 'Enter') {
          event.preventDefault();
          finish();
          return;
        }
        const key = keyForKeyboard(event.key);
        if (!key) return;
        event.preventDefault();
        editing.apply(key);
      };

      // mostly-vertical drags only
      let start: { x: number; y: number } | undefined;
      let dragging = false;
      let travel = 0;
      let last = { y: 0, t: 0 };
      let speed = 0;
      const down = (event: PointerEvent) => {
        if (event.button !== 0 || !event.isPrimary) return;
        start = { x: event.clientX, y: event.clientY };
        dragging = false;
        travel = 0;
        speed = 0;
        last = { y: event.clientY, t: event.timeStamp };
      };
      const move = (event: PointerEvent) => {
        if (!start) return;
        const dx = event.clientX - start.x;
        const dy = event.clientY - start.y;
        if (!dragging) {
          if (Math.abs(dy) <= 10 || Math.abs(dy) <= Math.abs(dx)) return;
          dragging = true;
          capture(dialog, event.pointerId);
        }
        const dt = event.timeStamp - last.t;
        if (dt > 0) speed = ((event.clientY - last.y) / dt) * 1000;
        last = { y: event.clientY, t: event.timeStamp };
        travel = dy;
        // resists upwards unless it can grow
        const grows = !docked && !live.current.large;
        const shown = dy > 0 ? dy : grows ? Math.max(dy, -200) : dy / 6;
        dialog.style.translate = `0 ${shown}px`;
      };
      const up = () => {
        if (!start) return;
        start = undefined;
        if (!dragging) return;
        dragging = false;
        const down = travel > closing.distance || speed > closing.speed;
        const rise = travel < -60 || speed < -closing.speed;
        if (docked || !live.current.large) {
          if (down) return finish();
          if (rise && !docked) setLarge(true);
        } else if (down) {
          if (travel > 400) return finish();
          setLarge(false);
        }
        const from = dialog.style.translate;
        dialog.style.translate = '';
        if (!still())
          dialog.animate([{ translate: from }, { translate: '0 0' }], {
            duration: 350,
            easing: springEasing(0.8),
          });
      };

      dialog.addEventListener('cancel', cancel);
      dialog.addEventListener('click', outside);
      dialog.addEventListener('keydown', keydown);
      dialog.addEventListener('pointerdown', down);
      dialog.addEventListener('pointermove', move);
      dialog.addEventListener('pointerup', up);
      dialog.addEventListener('pointercancel', up);
      window.addEventListener('resize', measurePane);
      return () => {
        dialog.removeEventListener('cancel', cancel);
        dialog.removeEventListener('click', outside);
        dialog.removeEventListener('keydown', keydown);
        dialog.removeEventListener('pointerdown', down);
        dialog.removeEventListener('pointermove', move);
        dialog.removeEventListener('pointerup', up);
        dialog.removeEventListener('pointercancel', up);
        window.removeEventListener('resize', measurePane);
        if (dialog.open) dialog.close();
      };
    },
    [docked, editing, live],
  );

  const step = useCallback((key: Key) => editing.apply(key), [editing]);
  const type = useCallback((key: Key) => void editing.apply(key), [editing]);

  return (
    <dialog
      className={cx(
        'canon-math-input',
        docked ? 'canon-math-input--docked' : 'canon-math-input--sheet',
        large && 'canon-math-input--large',
        className,
      )}
      aria-label="Expression"
      tabIndex={-1}
      style={
        {
          '--canon-math-sheet-height': `${contentHeight(short)}px`,
          '--canon-math-editor-height': `${short ? editorHeights.short : editorHeights.regular}px`,
          ...(pane && {
            '--canon-math-sheet-left': `${pane.left}px`,
            '--canon-math-sheet-width': `${pane.width}px`,
          }),
          ...style,
        } as CSSProperties
      }
      ref={useRefs(present, ref)}
      {...rest}
    >
      <span className="canon-math-input-grabber" />
      <div className="canon-math-input-stack">
        <CanonRows framed className="canon-math-input-display">
          <CanonMathEditor editing={editing} size={short ? 26 : 30} />
          <CanonMathRail onStep={step} short={short} />
        </CanonRows>
        <CanonRows framed>
          <CanonMathKeypad
            variable={variable}
            short={short}
            onKey={type}
            onDone={finish}
          />
        </CanonRows>
      </div>
    </dialog>
  );
}
