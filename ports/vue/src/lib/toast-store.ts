import { reactive } from 'vue';
import { toastDetail, toastHold } from '@canon/lib/toast.ts';

let timer: number | undefined;

/**
 * Drives the one CanonToast outlet: a short "Copied" note with the copied
 * value, near the bottom of the column the last pointer went down in.
 * `copy` is CanonCopyFeedback.copy: every tapped value copy confirms with
 * the toast and nothing else. Tests replace `write`.
 */
export const toast = reactive({
	detail: undefined as string | undefined,
	visible: false,
	/** Counts shows, so the outlet can tell a repeat from a first show. */
	shown: 0,
	lastPointer: undefined as
		{ x: number; y: number; target: Element | null } | undefined,

	/** Shows the toast; the detail appears when it is one short line. */
	show(detail?: string) {
		toast.detail = toastDetail(detail);
		toast.visible = true;
		toast.shown += 1;
		window.clearTimeout(timer);
		timer = window.setTimeout(() => {
			toast.visible = false;
		}, toastHold * 1000);
	},

	/** Copies `text` and confirms with the toast. Nothing shows if the write fails. */
	async copy(text: string) {
		try {
			await toast.write(text);
		} catch {
			return;
		}
		toast.show(text);
	},

	write(text: string): Promise<void> {
		return navigator.clipboard.writeText(text);
	},
});

if (typeof document !== 'undefined') {
	document.addEventListener(
		'pointerdown',
		(event) => {
			toast.lastPointer = {
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
