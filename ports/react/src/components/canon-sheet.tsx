import { CanonDialogBase, type CanonDialogProps } from './canon-dialog.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-sheet.css';

export type CanonSheetEdge = 'start' | 'end' | 'top' | 'bottom';

export interface CanonSheetProps extends Omit<CanonDialogProps, 'alert'> {
	/** The edge it slides in from; start and end follow the writing direction. Default bottom. */
	edge?: CanonSheetEdge;
}

const offsets: Record<CanonSheetEdge, string> = {
	top: 'translateY(-100%)',
	bottom: 'translateY(100%)',
	start: 'translateX(-100%)',
	end: 'translateX(100%)',
};

function slide(edge: CanonSheetEdge, dialog: HTMLDialogElement): Keyframe[] {
	if (getComputedStyle(dialog).direction === 'rtl')
		edge =
			edge === 'start'
				? 'end'
				: edge === 'end'
					? 'start'
					: edge;
	return [{ transform: offsets[edge] }, { transform: 'none' }];
}

/**
 * CanonDialog anchored to an edge of the window, sliding in from it: the
 * iOS sheet at the bottom, a side panel at start or end.
 */
export default function CanonSheet({
	edge = 'bottom',
	...rest
}: CanonSheetProps) {
	return (
		<CanonDialogBase
			{...rest}
			kindClasses={`canon-dialog canon-sheet canon-sheet--${edge}`}
			keyframes={(dialog) => slide(edge, dialog)}
		/>
	);
}
