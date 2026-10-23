import {
	useCallback,
	useId,
	type HTMLAttributes,
	type ReactNode,
	type Ref,
	type RefCallback,
} from 'react';
import {
	attach,
	hide,
	panelFor,
	type CanonPlacement,
} from '@canon/lib/popover.ts';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-popover.css';

export interface CanonPopoverTriggerApi {
	/** A ref for the button that opens the panel. */
	trigger: RefCallback<HTMLButtonElement>;
	close: () => void;
}

export interface CanonPopoverProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'content' | 'children'
> {
	/** Default bottom-start. The panel flips to the other side when it does not fit. */
	placement?: CanonPlacement;
	/** Put `trigger` as the ref of the button that opens the panel. */
	trigger: (popover: CanonPopoverTriggerApi) => ReactNode;
	content?: ReactNode | ((popover: { close: () => void }) => ReactNode);
	ref?: Ref<HTMLDivElement>;
}

/**
 * A panel anchored to the consumer's button. The button toggles it; a
 * click outside or Escape closes it, and focus inside goes back to the
 * button. Give the panel a role and a label (`role="dialog"
 * aria-label="…"`) and `autoFocus` on what should take focus.
 */
export default function CanonPopover({
	placement = 'bottom-start',
	trigger,
	content,
	className,
	ref,
	...rest
}: CanonPopoverProps) {
	const id = `${useId()}-popover`;
	const anchor = useCallback(
		(button: HTMLButtonElement) =>
			attach(panelFor(button, id), button, {
				placement,
				invokes: true,
			}),
		[id, placement],
	);
	const close = useCallback(() => {
		const panel = document.getElementById(id);
		if (panel) hide(panel);
	}, [id]);

	return (
		<>
			{trigger({ trigger: anchor, close })}
			<div
				id={id}
				className={cx('canon-popover', className)}
				popover="auto"
				ref={ref}
				{...rest}
			>
				{typeof content === 'function'
					? content({ close })
					: content}
			</div>
		</>
	);
}
