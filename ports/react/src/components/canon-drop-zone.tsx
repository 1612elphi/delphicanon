import {
	useRef,
	useState,
	type DragEvent,
	type HTMLAttributes,
	type ReactNode,
	type Ref,
} from 'react';
import CanonButton from './canon-button.tsx';
import CanonGrid from './canon-grid.tsx';
import { accepts, stem } from '@canon/lib/files.ts';
import { cx } from '../lib/class-names.ts';
import { Clipboard, Folder, Image } from '../lib/control-icons.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-drop-zone.css';

export interface CanonDropZoneProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'children'
> {
	/** Shown in the drop target under the icon. */
	prompt: string;
	/** Default a picture. */
	icon?: ReactNode;
	/** As the file input's accept attribute; default image/*. Empty takes any file. */
	accept?: string;
	multiple?: boolean;
	/** Shows Paste, which reads images from the clipboard; default true. */
	paste?: boolean;
	/** Decoded images, EXIF orientation applied, with their file names less the extension; no names after a paste. */
	onImages?: (images: ImageBitmap[], names: string[]) => void;
	/** The files themselves, when `onImages` is not set. */
	onFiles?: (files: File[]) => void;
	ref?: Ref<HTMLDivElement>;
}

/**
 * Import area: a drop target over a flush bar of sources. Pasting while
 * focus is inside it imports too.
 */
export default function CanonDropZone({
	prompt,
	icon,
	accept = 'image/*',
	multiple,
	paste,
	onImages,
	onFiles,
	className,
	...rest
}: CanonDropZoneProps) {
	const [over, setOver] = useState(false);
	const depth = useRef(0);
	const input = useRef<HTMLInputElement>(null);

	const deliver = async (all: File[], pasted: boolean) => {
		const matching = all.filter((file) => accepts(file, accept));
		const files = multiple ? matching : matching.slice(0, 1);
		if (files.length === 0) return;
		if (!onImages) {
			onFiles?.(files);
			return;
		}
		const decoded = await Promise.all(
			files.map((file) =>
				createImageBitmap(file, {
					imageOrientation: 'from-image',
				}).then(
					(image) => ({
						image,
						name: stem(file.name),
					}),
					() => undefined,
				),
			),
		);
		const images = decoded.filter((d) => d !== undefined);
		if (images.length === 0) return;
		onImages(
			images.map((d) => d.image),
			pasted ? [] : images.map((d) => d.name),
		);
	};

	const pasteImages = async () => {
		const blobs: File[] = [];
		try {
			for (const item of await navigator.clipboard.read()) {
				const type = item.types.find((t) =>
					t.startsWith('image/'),
				);
				if (type)
					blobs.push(
						new File(
							[
								await item.getType(
									type,
								),
							],
							'pasted',
							{ type },
						),
					);
			}
		} catch {
			return;
		}
		await deliver(blobs, true);
	};

	const carriesFiles = (event: DragEvent) =>
		event.dataTransfer?.types.includes('Files') ?? false;

	return (
		<div
			className={cx('canon-drop-zone', className)}
			{...rest}
			onPaste={(event) => {
				const files = [
					...(event.clipboardData?.files ?? []),
				];
				if (files.length === 0) return;
				event.preventDefault();
				void deliver(files, true);
			}}
		>
			<div
				className={cx(
					'canon-drop-zone-target',
					over && 'canon-drop-zone-target--over',
				)}
				onDragEnter={(event) => {
					if (!carriesFiles(event)) return;
					depth.current += 1;
					setOver(true);
				}}
				onDragOver={(event) => {
					if (!carriesFiles(event)) return;
					event.preventDefault();
					event.dataTransfer.dropEffect = 'copy';
				}}
				onDragLeave={() => {
					depth.current = Math.max(
						0,
						depth.current - 1,
					);
					if (depth.current === 0) setOver(false);
				}}
				onDrop={(event) => {
					event.preventDefault();
					depth.current = 0;
					setOver(false);
					void deliver(
						[
							...(event.dataTransfer
								?.files ?? []),
						],
						false,
					);
				}}
			>
				<span
					className="canon-drop-zone-icon"
					aria-hidden="true"
				>
					{icon ?? <Image />}
				</span>
				<span className="canon-drop-zone-prompt">
					{prompt}
				</span>
			</div>
			<CanonGrid>
				<CanonButton
					kind="cell"
					text="Files"
					icon={<Folder />}
					onClick={() => input.current?.click()}
				/>
				{paste !== false && (
					<CanonButton
						kind="cell"
						text="Paste"
						icon={<Clipboard />}
						onClick={() =>
							void pasteImages()
						}
					/>
				)}
			</CanonGrid>
			<input
				type="file"
				accept={accept}
				multiple={multiple}
				hidden
				ref={input}
				onChange={(event) => {
					const files = [
						...(event.target.files ?? []),
					];
					event.target.value = '';
					void deliver(files, false);
				}}
			/>
		</div>
	);
}
