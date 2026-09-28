import {
  useCallback,
  useLayoutEffect,
  useMemo,
  useState,
  type ButtonHTMLAttributes,
  type Ref,
} from 'react';
import { Expression, layoutRow, type Key } from '@canon/lib/math/expression.ts';
import { canvasMetrics } from '@canon/lib/math/measure.ts';
import { Typesetter } from '@canon/lib/math/typeset.ts';
import CanonMathInput from './canon-math-input.tsx';
import CanonMathView from './canon-math-view.tsx';
import { cx } from '../lib/class-names.ts';
import { Keyboard } from '../lib/control-icons.tsx';
import { press } from '../lib/press.ts';
import { useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-field.css';

export interface CanonMathFieldProps extends Omit<
  ButtonHTMLAttributes<HTMLButtonElement>,
  'onChange'
> {
  /** nerdamer syntax. */
  text?: string;
  /** The letter the keypad offers first, and the variable of derivatives, integrals and limits. */
  variable?: string;
  /** Shown faint while the text is empty, in the same syntax. */
  placeholder?: string;
  /** Font size in px; default 22. */
  size?: number;
  /** Every edit made in the keypad sheet. */
  onChange?: (text: string) => void;
  /** The sheet closed, with the text. */
  onCompletion?: (text: string) => void;
  /** Lets insert keys beside the field open it and type. */
  handle?: CanonMathFieldHandle;
  ref?: Ref<HTMLButtonElement>;
}

/** Opens a CanonMathField from outside it, as `field.edit(then:)` does. */
export class CanonMathFieldHandle {
  field?: { edit: (keys: Key[]) => void };

  /** Opens the keypad sheet, then types `keys`. */
  edit = (keys: Key[] = []) => this.field?.edit(keys);

  /** Points the handle at a field until the returned detach runs. */
  attach(field: { edit: (keys: Key[]) => void }): () => void {
    this.field = field;
    return () => {
      if (this.field === field) this.field = undefined;
    };
  }
}

/**
 * An expression typeset in a flush cell; a click opens the keypad sheet
 * (CanonMathField). `onChange` runs on every edit made there, `onCompletion`
 * when the sheet closes.
 */
export default function CanonMathField({
  text: given,
  variable = 'x',
  placeholder,
  size,
  onChange,
  onCompletion,
  handle,
  className,
  ref,
  ...rest
}: CanonMathFieldProps) {
  const [pendingKeys, setPendingKeys] = useState<Key[]>();
  const [edited, setEdited] = useState<{ text: string; over?: string }>();
  const [button, setButton] = useState<HTMLButtonElement | null>(null);
  const editing = pendingKeys !== undefined;

  /** The last edit, until the owner passes a different text. */
  const text = edited && edited.over === given ? edited.text : (given ?? '');

  const box = useMemo(
    () =>
      layoutRow(
        new Typesetter(canvasMetrics, size ?? 22, 'result'),
        new Expression(text || (placeholder ?? ''), variable).root,
        { variable },
      ),
    [text, placeholder, variable, size],
  );

  const edit = useCallback(
    (keys: Key[] = []) => setPendingKeys((pending) => pending ?? keys),
    [],
  );

  useLayoutEffect(() => handle?.attach({ edit }), [handle, edit]);

  const changed = (text: string) => {
    setEdited({ text, over: given });
    onChange?.(text);
  };

  const closed = (text: string) => {
    setEdited({ text, over: given });
    setPendingKeys(undefined);
    onCompletion?.(text);
    button?.focus({ preventScroll: true });
  };

  return (
    <>
      <button
        type="button"
        className={cx(
          'canon-math-field',
          editing && 'canon-math-field--editing',
          className,
        )}
        aria-label="Expression"
        aria-haspopup="dialog"
        onClick={() => edit()}
        ref={useRefs<HTMLButtonElement>(press, setButton, ref)}
        {...rest}
      >
        <CanonMathView box={box} faint={!text} label={text} />
        <span className="canon-math-field-glyph">
          <Keyboard />
        </span>
      </button>
      {editing && (
        <CanonMathInput
          text={text}
          variable={variable}
          keys={pendingKeys}
          source={button}
          onChange={changed}
          onClose={closed}
        />
      )}
    </>
  );
}
