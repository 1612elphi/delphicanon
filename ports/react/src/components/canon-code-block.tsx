import { useEffect, useRef, useState, type HTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import { Check, Copy } from '../lib/control-icons.tsx';
import { press } from '../lib/press.ts';
import { canonToast } from '../lib/toast-store.ts';
import { flashSeconds } from './canon-button.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-code-block.css';

export interface CanonCodeBlockProps extends HTMLAttributes<HTMLDivElement> {
  code: string;
  /** Shown uppercased in a heading bar above the code; without it the copy button sits below. */
  language?: string;
  /** Taller code scrolls inside the block. */
  maxHeight?: number;
}

/** Monospaced, selectable code with a copy button. Lines do not wrap; the block scrolls sideways. */
export default function CanonCodeBlock({
  code,
  language,
  maxHeight,
  className,
  ...rest
}: CanonCodeBlockProps) {
  const [copied, setCopied] = useState(false);
  const timer = useRef<number>(undefined);
  const mounted = useRef(true);

  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
      window.clearTimeout(timer.current);
    };
  }, []);

  const copy = async () => {
    try {
      await canonToast.write(code);
    } catch {
      return;
    }
    if (!mounted.current) return;
    setCopied(true);
    window.clearTimeout(timer.current);
    timer.current = window.setTimeout(
      () => setCopied(false),
      flashSeconds * 1000,
    );
  };

  return (
    <div
      className={cx(
        'canon-code-block',
        language && 'canon-code-block--titled',
        className,
      )}
      {...rest}
    >
      <div className="canon-code-block-bar">
        {language && (
          <span className="canon-code-block-language">{language}</span>
        )}
        <button
          type="button"
          className={cx(
            'canon-code-block-copy',
            copied && 'canon-code-block-copy--copied',
          )}
          aria-label="Copy code"
          ref={press}
          onClick={() => void copy()}
        >
          {copied ? <Check /> : <Copy />}
        </button>
      </div>
      <pre
        className="canon-code-block-code"
        tabIndex={0}
        style={
          maxHeight === undefined
            ? undefined
            : { maxBlockSize: `${maxHeight}px` }
        }
      >
        {code}
      </pre>
    </div>
  );
}
