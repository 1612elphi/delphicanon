<script setup lang="ts">
import { computed, ref, useTemplateRef, type Component } from 'vue';
import CanonButton from './canon-button.vue';
import CanonGrid from './canon-grid.vue';
import { Clipboard, Folder, Picture } from '../lib/control-icons.ts';
import { accepts, stem } from '@canon/lib/files.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-drop-zone.css';

const props = withDefaults(
	defineProps<{
		/** Shown in the drop target under the icon. */
		prompt: string;
		/** Default a picture. */
		icon?: Component;
		/** As the file input's accept attribute; default image/*. Empty takes any file. */
		accept?: string;
		multiple?: boolean;
		/** Shows Paste, which reads images from the clipboard; default true. */
		paste?: boolean;
		/** Decoded images, EXIF orientation applied, with their file names less the extension; no names after a paste. */
		onImages?: (images: ImageBitmap[], names: string[]) => void;
		/** The files themselves, when `onImages` is not set. */
		onFiles?: (files: File[]) => void;
	}>(),
	{ paste: undefined },
);

const over = ref(false);
let depth = 0;

const accept = computed(() => props.accept ?? 'image/*');
const showsPaste = computed(() => props.paste !== false);

const input = useTemplateRef<HTMLInputElement>('input');

function chooseFiles() {
	input.value?.click();
}

function picked(event: Event) {
	const element = event.target as HTMLInputElement;
	const files = [...(element.files ?? [])];
	element.value = '';
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
						[await item.getType(type)],
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

function pasted(event: ClipboardEvent) {
	const files = [...(event.clipboardData?.files ?? [])];
	if (files.length === 0) return;
	event.preventDefault();
	void deliver(files, true);
}

function enter(event: DragEvent) {
	if (!event.dataTransfer?.types.includes('Files')) return;
	depth += 1;
	over.value = true;
}

function hover(event: DragEvent) {
	if (!event.dataTransfer?.types.includes('Files')) return;
	event.preventDefault();
	event.dataTransfer.dropEffect = 'copy';
}

function leave() {
	depth = Math.max(0, depth - 1);
	if (depth === 0) over.value = false;
}

function drop(event: DragEvent) {
	event.preventDefault();
	depth = 0;
	over.value = false;
	void deliver([...(event.dataTransfer?.files ?? [])], false);
}

async function deliver(all: File[], fromPaste: boolean) {
	const matching = all.filter((file) => accepts(file, accept.value));
	const files = props.multiple ? matching : matching.slice(0, 1);
	if (files.length === 0) return;
	const { onImages } = props;
	if (!onImages) {
		props.onFiles?.(files);
		return;
	}
	const decoded = await Promise.all(
		files.map((file) =>
			createImageBitmap(file, {
				imageOrientation: 'from-image',
			}).then(
				(image) => ({ image, name: stem(file.name) }),
				() => undefined,
			),
		),
	);
	const images = decoded.filter((d) => d !== undefined);
	if (images.length === 0) return;
	onImages(
		images.map((d) => d.image),
		fromPaste ? [] : images.map((d) => d.name),
	);
}
</script>

<!--
  Import area: a drop target over a flush bar of sources. Pasting while
  focus is inside it imports too.
-->
<template>
	<div class="canon-drop-zone" @paste="pasted">
		<div
			class="canon-drop-zone-target"
			:class="{ 'canon-drop-zone-target--over': over }"
			@dragenter="enter"
			@dragover="hover"
			@dragleave="leave"
			@drop="drop"
		>
			<span class="canon-drop-zone-icon" aria-hidden="true">
				<component :is="icon ? icon : Picture" />
			</span>
			<span class="canon-drop-zone-prompt">{{ prompt }}</span>
		</div>
		<CanonGrid>
			<CanonButton
				kind="cell"
				text="Files"
				:icon="Folder"
				:on-click="chooseFiles"
			/>
			<CanonButton
				v-if="showsPaste"
				kind="cell"
				text="Paste"
				:icon="Clipboard"
				:on-click="pasteImages"
			/>
		</CanonGrid>
		<input
			ref="input"
			type="file"
			:accept="accept"
			:multiple="multiple"
			hidden
			@change="picked"
		/>
	</div>
</template>
