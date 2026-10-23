import CanonDialog, { type CanonDialogSignature } from './canon-dialog.gts';
import '../styles/tokens.css';
import './canon-sheet.css';

export type CanonSheetEdge = 'start' | 'end' | 'top' | 'bottom';

export interface CanonSheetSignature extends CanonDialogSignature {
	Args: Omit<CanonDialogSignature['Args'], 'alert'> & {
		/** The edge it slides in from; start and end follow the writing direction. Default bottom. */
		edge?: CanonSheetEdge;
	};
}

const offsets: Record<CanonSheetEdge, string> = {
	top: 'translateY(-100%)',
	bottom: 'translateY(100%)',
	start: 'translateX(-100%)',
	end: 'translateX(100%)',
};

/**
 * CanonDialog anchored to an edge of the window, sliding in from it: the
 * iOS sheet at the bottom, a side panel at start or end.
 */
export default class CanonSheet extends CanonDialog<
	CanonSheetSignature['Args']
> {
	get edge(): CanonSheetEdge {
		return this.args.edge ?? 'bottom';
	}

	get classNames(): string {
		return `canon-dialog canon-sheet canon-sheet--${this.edge}`;
	}

	keyframes(): Keyframe[] {
		let edge = this.edge;
		const rtl =
			this.element &&
			getComputedStyle(this.element).direction === 'rtl';
		if (rtl)
			edge =
				edge === 'start'
					? 'end'
					: edge === 'end'
						? 'start'
						: edge;
		return [{ transform: offsets[edge] }, { transform: 'none' }];
	}
}
