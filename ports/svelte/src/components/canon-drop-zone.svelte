<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import CanonButton from './canon-button.svelte';
	import CanonGrid from './canon-grid.svelte';
	import { Clipboard, Folder, Picture } from '../lib/control-icons.ts';
	import { accepts, stem } from '@canon/lib/files.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-drop-zone.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children'
	> {
		/** Shown in the drop target under the icon. */
		prompt: string;
		/** Default a picture. */
		icon?: Snippet;
		/** As the file input's accept attribute; default image/*. Empty takes any file. */
		accept?: string;
		multiple?: boolean;
		/** Shows Paste, which reads images from the clipboard; default true. */
		paste?: boolean;
		/** Decoded images, EXIF orientation applied, with their file names less the extension; no names after a paste. */
		onImages?: (images: ImageBitmap[], names: string[]) => void;
		/** The files themselves, when `onImages` is not set. */
		onFiles?: (files: File[]) => void;
	}

	let {
		prompt,
		icon = Picture,
		accept = 'image/*',
		multiple,
		paste,
		onImages,
		onFiles,
		class: className,
		onpaste,
		...rest
	}: Props = $props();

	let over = $state(false);
	let depth = 0;
	let input = $state<HTMLInputElement>();

	function picked(event: Event & { currentTarget: HTMLInputElement }) {
		const files = [...(event.currentTarget.files ?? [])];
		event.currentTarget.value = '';
		void deliver(files, false);
	}

	async function pasteImages() {
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
	}

	function pasted(
		event: ClipboardEvent & { currentTarget: HTMLDivElement },
	) {
		onpaste?.(event);
		const files = [...(event.clipboardData?.files ?? [])];
		if (files.length === 0) return;
		event.preventDefault();
		void deliver(files, true);
	}

	function enter(event: DragEvent) {
		if (!event.dataTransfer?.types.includes('Files')) return;
		depth += 1;
		over = true;
	}

	function hover(event: DragEvent) {
		if (!event.dataTransfer?.types.includes('Files')) return;
		event.preventDefault();
		event.dataTransfer.dropEffect = 'copy';
	}

	function leave() {
		depth = Math.max(0, depth - 1);
		if (depth === 0) over = false;
	}

	function drop(event: DragEvent) {
		event.preventDefault();
		depth = 0;
		over = false;
		void deliver([...(event.dataTransfer?.files ?? [])], false);
	}

	async function deliver(all: File[], pasted: boolean) {
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
	}
</script>

<!--
  @component
  Import area: a drop target over a flush bar of sources. Pasting while
  focus is inside it imports too.
-->
<div class={['canon-drop-zone', className]} onpaste={pasted} {...rest}>
	<!-- svelte-ignore a11y_no_static_element_interactions -->
	<div
		class={[
			'canon-drop-zone-target',
			over && 'canon-drop-zone-target--over',
		]}
		ondragenter={enter}
		ondragover={hover}
		ondragleave={leave}
		ondrop={drop}
	>
		<span class="canon-drop-zone-icon" aria-hidden="true"
			>{@render icon()}</span
		>
		<span class="canon-drop-zone-prompt">{prompt}</span>
	</div>
	<CanonGrid>
		<CanonButton
			kind="cell"
			text="Files"
			icon={Folder}
			onClick={() => input?.click()}
		/>
		{#if paste !== false}
			<CanonButton
				kind="cell"
				text="Paste"
				icon={Clipboard}
				onClick={pasteImages}
			/>
		{/if}
	</CanonGrid>
	<input
		type="file"
		{accept}
		{multiple}
		hidden
		bind:this={input}
		onchange={picked}
	/>
</div>
