import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type ButtonHTMLAttributes,
  type ReactNode,
  type Ref,
} from 'react';
import { cx } from '../lib/class-names.ts';
import { Check } from '../lib/control-icons.tsx';
import { press } from '../lib/press.ts';
import { useLatest, useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-button.css';

export type CanonButtonKind = 'primary' | 'secondary' | 'cell' | 'segment';

export interface CanonButtonProps extends Omit<
  ButtonHTMLAttributes<HTMLButtonElement>,
  'onClick'
> {
  /** The title. Empty shows the icon alone. */
  text?: string;
  /** Rendered as the symbol; the consumer supplies it (lucide in the web app). */
  icon?: ReactNode;
  /**
   * inline: small, beside the title. oversized: large and faint behind the
   * title, turned, cut off by the trailing and bottom edges. Keep it rare.
   */
  iconStyle?: 'inline' | 'oversized';
  /**
   * primary: the tool's main verb, fills its container. secondary: fills
   * its container. cell: content width, the enclosing grid or flush row
   * draws the lines. segment: a cell that shows `selected`.
   */
  kind?: CanonButtonKind;
  selected?: boolean;
  disabled?: boolean;
  /** Accessible name when the title is empty or dropped. */
  label?: string;
  onClick?: () => void;
  /** Holding the button runs onClick again and again; a tap runs it once. */
  repeats?: boolean;
  /** Shows Copied with a check for 1.5 s after each click. */
  flashesCopied?: boolean;
  ref?: Ref<HTMLButtonElement>;
}

/** Seconds before a held button repeats, between repeats, and between repeats after ten. */
export const repeatTiming = { delay: 0.4, interval: 0.09, fast: 0.04 } as const;
export const flashSeconds = 1.5;

export default function CanonButton({
  text: title,
  icon: symbol,
  iconStyle,
  kind = 'secondary',
  selected,
  disabled,
  label: accessibleName,
  onClick,
  repeats,
  flashesCopied,
  className,
  ref,
  ...rest
}: CanonButtonProps) {
  const [flashing, setFlashing] = useState(false);
  const flashTimer = useRef<number>(undefined);
  const holdTimer = useRef<number>(undefined);
  const held = useRef(false);
  const didRepeat = useRef(false);
  const latest = useLatest({ onClick, disabled, repeats });

  const text = flashing ? 'Copied' : (title ?? '');
  const icon = flashing ? <Check /> : symbol;
  const hasIcon = icon !== undefined && icon !== null;
  const oversized = iconStyle === 'oversized' && hasIcon;
  const filled =
    kind === 'primary' ||
    (selected === true && (kind === 'segment' || kind === 'secondary'));
  // a grid drops the title of a filling button with a symbol when it does not fit
  const fits =
    (kind === 'primary' || kind === 'secondary') &&
    text !== '' &&
    hasIcon &&
    !oversized;
  const label = hasIcon ? (accessibleName ?? (text || undefined)) : undefined;

  useEffect(
    () => () => {
      window.clearTimeout(flashTimer.current);
      window.clearTimeout(holdTimer.current);
    },
    [],
  );

  const click = () => {
    if (didRepeat.current) {
      didRepeat.current = false;
      return;
    }
    onClick?.();
    if (flashesCopied) {
      setFlashing(true);
      window.clearTimeout(flashTimer.current);
      flashTimer.current = window.setTimeout(
        () => setFlashing(false),
        flashSeconds * 1000,
      );
    }
  };

  const repeat = useCallback((button: HTMLButtonElement) => {
    const schedule = (seconds: number, count: number) => {
      window.clearTimeout(holdTimer.current);
      holdTimer.current = window.setTimeout(() => {
        if (!held.current || latest.current.disabled) return;
        didRepeat.current = true;
        latest.current.onClick?.();
        schedule(
          count < 10 ? repeatTiming.interval : repeatTiming.fast,
          count + 1,
        );
      }, seconds * 1000);
    };
    const hold = (event: PointerEvent) => {
      if (!latest.current.repeats || event.button !== 0) return;
      held.current = true;
      didRepeat.current = false;
      schedule(repeatTiming.delay, 0);
    };
    const letGo = () => {
      held.current = false;
      window.clearTimeout(holdTimer.current);
    };
    const ends = ['pointerup', 'pointerleave', 'pointercancel'] as const;
    button.addEventListener('pointerdown', hold);
    ends.forEach((type) => button.addEventListener(type, letGo));
    return () => {
      letGo();
      button.removeEventListener('pointerdown', hold);
      ends.forEach((type) => button.removeEventListener(type, letGo));
    };
  }, [latest]);

  return (
    <button
      type="button"
      className={cx(
        'canon-button',
        `canon-button--${kind}`,
        filled && 'canon-button--filled',
        hasIcon && 'canon-button--has-icon',
        oversized && 'canon-button--oversized',
        !text && 'canon-button--symbol',
        className,
      )}
      data-canon-fit={fits ? '' : undefined}
      disabled={disabled}
      aria-label={label}
      onClick={click}
      ref={useRefs(press, repeat, ref)}
      {...rest}
    >
      {hasIcon && (
        <span
          className={oversized ? 'canon-button-watermark' : 'canon-button-icon'}
          aria-hidden="true"
        >
          {icon}
        </span>
      )}
      {text && <span className="canon-button-title">{text}</span>}
    </button>
  );
}
