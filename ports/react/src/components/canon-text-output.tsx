import type { HTMLAttributes, ReactNode } from 'react';
import { cx } from '../lib/class-names.ts';
import { Copy, Share } from '../lib/control-icons.tsx';
import { canonToast } from '../lib/toast-store.ts';
import CanonButton from './canon-button.tsx';
import CanonEmptyRow from './canon-empty-row.tsx';
import CanonGrid from './canon-grid.tsx';
import CanonHeading from './canon-heading.tsx';
import CanonRows from './canon-rows.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-text-output.css';

export interface CanonTextOutputProps extends HTMLAttributes<HTMLDivElement> {
  text: string;
  heading: string;
  /** Name of the file Share hands over. */
  fileName: string;
  /** The output is still to come; the empty row stays away. */
  busy?: boolean;
  /** Shown when the output is blank; default None. */
  empty?: string;
  /** The output with its marks, shown in place of `text`. */
  children?: ReactNode;
  /** Rows between the text and the actions. */
  extra?: ReactNode;
}

/** Hands a text file to the system share sheet, or downloads it where there is none. */
export async function shareText(text: string, fileName: string) {
  const file = new File([text], fileName, { type: 'text/plain' });
  if (typeof navigator.share === 'function') {
    const data = navigator.canShare?.({ files: [file] })
      ? { files: [file] }
      : { text };
    try {
      await navigator.share(data);
    } catch {
      // dismissed
    }
    return;
  }
  const url = URL.createObjectURL(file);
  const link = document.createElement('a');
  link.href = url;
  link.download = fileName;
  link.click();
  URL.revokeObjectURL(url);
}

/** The output block of a text tool: a heading, the converted text, and Share beside Copy. */
export default function CanonTextOutput({
  text,
  heading,
  fileName,
  busy,
  empty,
  children,
  extra,
  className,
  ...rest
}: CanonTextOutputProps) {
  const blank = text.trim() === '';
  return (
    <CanonRows className={cx('canon-text-output', className)} framed {...rest}>
      <CanonHeading text={heading} />
      {!blank && (
        <div className="canon-text-output-text">
          {children !== undefined ? children : text}
        </div>
      )}
      {blank && !busy && <CanonEmptyRow text={empty || 'None'} />}
      {extra}
      <CanonGrid>
        <CanonButton
          text="Share"
          icon={<Share />}
          disabled={blank}
          onClick={() => void shareText(text, fileName)}
        />
        <CanonButton
          text="Copy"
          icon={<Copy />}
          iconStyle="oversized"
          kind="primary"
          disabled={blank}
          flashesCopied
          onClick={() => void canonToast.write(text).catch(() => undefined)}
        />
      </CanonGrid>
    </CanonRows>
  );
}
