export interface CompressFormat {
	label: string;
	type: string;
	extension: string;
	hasQuality: boolean;
}

export const formats: CompressFormat[] = [
	{
		label: 'JPEG',
		type: 'image/jpeg',
		extension: 'jpg',
		hasQuality: true,
	},
	{
		label: 'WebP',
		type: 'image/webp',
		extension: 'webp',
		hasQuality: true,
	},
	{
		label: 'PNG',
		type: 'image/png',
		extension: 'png',
		hasQuality: false,
	},
	{
		label: 'AVIF',
		type: 'image/avif',
		extension: 'avif',
		hasQuality: true,
	},
];

/** The formats this browser's canvas encodes; an unknown type comes back as PNG. */
export function availableFormats(): CompressFormat[] {
	const canvas = document.createElement('canvas');
	canvas.width = canvas.height = 1;
	return formats.filter((format) =>
		canvas.toDataURL(format.type).startsWith(`data:${format.type}`),
	);
}

export function exportName(name: string, format: CompressFormat): string {
	const dot = name.lastIndexOf('.');
	const stem = dot > 0 ? name.slice(0, dot) : name;
	return `${stem || 'image'}.${format.extension}`;
}

export interface EncodeRequest {
	job: number;
	/** Changes with the file; the decoded bitmap is kept while it stays. */
	source: number;
	file: Blob;
	type: string;
	/** 1 to 100. */
	quality: number;
}

export type EncodeReply =
	| { job: number; blob: Blob; width: number; height: number }
	| { job: number; error: string };

let decoded: { source: number; bitmap: ImageBitmap } | undefined;

function canvasOf(width: number, height: number) {
	if (typeof OffscreenCanvas !== 'undefined')
		return new OffscreenCanvas(width, height);
	const canvas = document.createElement('canvas');
	canvas.width = width;
	canvas.height = height;
	return canvas;
}

function blobOf(
	canvas: OffscreenCanvas | HTMLCanvasElement,
	type: string,
	quality: number,
): Promise<Blob | null> {
	if ('convertToBlob' in canvas)
		return canvas.convertToBlob({ type, quality });
	return new Promise((resolve) => canvas.toBlob(resolve, type, quality));
}

/** Decodes (once per source), draws and encodes; JPEG is flattened on white. Never throws. */
export async function encode(request: EncodeRequest): Promise<EncodeReply> {
	const { job, source, file, type, quality } = request;
	try {
		if (decoded?.source !== source) {
			decoded?.bitmap.close();
			// a failed decode must not leave the closed bitmap cached
			decoded = undefined;
			decoded = {
				source,
				bitmap: await createImageBitmap(file, {
					imageOrientation: 'from-image',
				}),
			};
		}
		const { bitmap } = decoded;
		const canvas = canvasOf(bitmap.width, bitmap.height);
		// both canvases give the same 2d context interface
		const context = (canvas as OffscreenCanvas).getContext('2d');
		if (!context) return { job, error: 'no 2d context' };
		if (type === 'image/jpeg') {
			context.fillStyle = '#fff';
			context.fillRect(0, 0, bitmap.width, bitmap.height);
		}
		context.drawImage(bitmap, 0, 0);
		const blob = await blobOf(
			canvas,
			type,
			Math.min(1, Math.max(0.01, quality / 100)),
		);
		if (blob?.type !== type)
			return { job, error: `${type} not encoded` };
		return {
			job,
			blob,
			width: bitmap.width,
			height: bitmap.height,
		};
	} catch (error) {
		return { job, error: String(error) };
	}
}

/**
 * Sends encodes to a worker where the browser has OffscreenCanvas, else
 * encodes on the main thread. Only the newest job's reply reaches `onReply`.
 */
export class Encoder {
	#worker?: Worker;
	#job = 0;
	#onReply: (reply: EncodeReply) => void;

	constructor(onReply: (reply: EncodeReply) => void) {
		this.#onReply = onReply;
		if (typeof OffscreenCanvas === 'undefined') return;
		this.#worker = new Worker(
			new URL('./encode-worker.ts', import.meta.url),
			{
				type: 'module',
			},
		);
		this.#worker.onmessage = ({
			data,
		}: MessageEvent<EncodeReply>) => this.#reply(data);
		this.#worker.onerror = (event) =>
			this.#reply({ job: this.#job, error: event.message });
	}

	send(request: Omit<EncodeRequest, 'job'>) {
		const job = ++this.#job;
		if (this.#worker) this.#worker.postMessage({ ...request, job });
		// ponytail: main-thread encodes overlap; stale replies are dropped by job
		else
			void encode({ ...request, job }).then((reply) =>
				this.#reply(reply),
			);
	}

	/** Drops the reply of any job in flight. */
	cancel() {
		this.#job += 1;
	}

	destroy() {
		this.cancel();
		this.#worker?.terminate();
	}

	#reply(reply: EncodeReply) {
		if (reply.job === this.#job) this.#onReply(reply);
	}
}
