import { useEffect, useRef, useState, type HTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import { Clipboard, Trash } from '../lib/control-icons.tsx';
import { useLatest } from '../lib/refs.ts';
import CanonButton from './canon-button.tsx';
import CanonGrid from './canon-grid.tsx';
import CanonTextArea from './canon-text-area.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-text-input.css';

export interface CanonTextInputProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  'onChange'
> {
  /** Starting text; later changes to the prop are not followed. */
  value?: string;
  placeholder?: string;
  /** Height of the text area in px; default 128. */
  height?: number;
  /** Accessible name of the text area; default Input. */
  label?: string;
  /** Typing arrives once it pauses; Paste and Clear arrive at once. */
  onChange?: (text: string) => void;
}

/** Seconds typing must pause before `onChange`. */
export const typingDelay = 0.4;

/** The input block of a text tool: a text area with Paste and Clear under it. */
export default function CanonTextInput({
  value,
  placeholder,
  height,
  label,
  onChange,
  className,
  ...rest
}: CanonTextInputProps) {
  const [text, setText] = useState(value ?? '');
  const timer = useRef<number>(undefined);
  const mounted = useRef(true);
  const changes = useLatest(onChange);

  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
      window.clearTimeout(timer.current);
    };
  }, []);

  const typed = (next: string) => {
    setText(next);
    window.clearTimeout(timer.current);
    timer.current = window.setTimeout(
      () => changes.current?.(next),
      typingDelay * 1000,
    );
  };

  // text set from code reaches onChange at once
  const set = (next: string) => {
    window.clearTimeout(timer.current);
    setText(next);
    onChange?.(next);
  };

  const paste = async () => {
    try {
      const pasted = await navigator.clipboard.readText();
      if (mounted.current) set(pasted);
    } catch {
      return;
    }
  };

  return (
    <div className={cx('canon-text-input', className)} {...rest}>
      <CanonTextArea
        value={text}
        placeholder={placeholder || 'Type or paste'}
        height={height || 128}
        onChange={typed}
        aria-label={label || 'Input'}
      />
      <CanonGrid>
        <CanonButton
          text="Paste"
          icon={<Clipboard />}
          onClick={() => void paste()}
        />
        <CanonButton
          text="Clear"
          icon={<Trash />}
          disabled={!text}
          onClick={() => set('')}
        />
      </CanonGrid>
    </div>
  );
}
