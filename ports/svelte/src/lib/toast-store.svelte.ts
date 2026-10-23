import { toastDetail, toastHold } from '@canon/lib/toast.ts';

/**
 * Drives the one CanonToast outlet: a short "Copied" note with the copied
 * value, near the bottom of the column the last pointer went down in.
 * `copy` is CanonCopyFeedback.copy: every tapped value copy confirms with
 * the toast and nothing else.
 */
class CanonToastStore {
	detail = $state<string>();
	visible = $state(false);
	/** Counts shows, so the outlet can tell a repeat from a first show. */
	shown = $state(0);
	lastPointer?: { x: number; y: number; target: Element | null };
	#timer?: number;

	constructor() {
		if (typeof document === 'undefined') return;
		document.addEventListener(
			'pointerdown',
			(event) => {
				this.lastPointer = {
					x: event.clientX,
					y: event.clientY,
					target:
						event.target instanceof Element
							? event.target
							: null,
				};
			},
			{ capture: true, passive: true },
		);
	}

	/** Shows the toast; the detail appears when it is one short line. */
	show(detail?: string) {
		this.detail = toastDetail(detail);
		this.visible = true;
		this.shown += 1;
		window.clearTimeout(this.#timer);
		this.#timer = window.setTimeout(() => {
			this.visible = false;
		}, toastHold * 1000);
	}

	/** Copies `text` and confirms with the toast. Nothing shows if the write fails. */
	async copy(text: string) {
		try {
			await this.write(text);
		} catch {
			return;
		}
		this.show(text);
	}

	/** Replaceable, so tests fake the clipboard. */
	write(text: string): Promise<void> {
		return navigator.clipboard.writeText(text);
	}
}

export type { CanonToastStore };
export const canonToast = new CanonToastStore();
