import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { toastDetail, toastHold } from '../lib/toast.ts';

/**
 * Drives the one CanonToast outlet: a short "Copied" note with the copied
 * value, near the bottom of the column the last pointer went down in.
 * `copy` is CanonCopyFeedback.copy: every tapped value copy confirms with
 * the toast and nothing else.
 */
export default class CanonToastService extends Service {
	@tracked detail?: string;
	@tracked visible = false;
	/** Counts shows, so the outlet can tell a repeat from a first show. */
	@tracked shown = 0;
	lastPointer?: { x: number; y: number; target: Element | null };
	#timer?: number;

	constructor(...args: ConstructorParameters<typeof Service>) {
		super(...args);
		document.addEventListener('pointerdown', this.#note, {
			capture: true,
			passive: true,
		});
	}

	#note = (event: PointerEvent) => {
		this.lastPointer = {
			x: event.clientX,
			y: event.clientY,
			target:
				event.target instanceof Element
					? event.target
					: null,
		};
	};

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

	write(text: string): Promise<void> {
		return navigator.clipboard.writeText(text);
	}

	willDestroy() {
		super.willDestroy();
		window.clearTimeout(this.#timer);
		document.removeEventListener('pointerdown', this.#note, {
			capture: true,
		});
	}
}

declare module '@ember/service' {
	interface Registry {
		'canon-toast': CanonToastService;
	}
}
