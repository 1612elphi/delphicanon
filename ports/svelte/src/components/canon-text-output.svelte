<script lang="ts" module>
	/** Hands a text file to the system share sheet, or downloads it where there is none. */
	export async function shareText(text: string, fileName: string) {
		const file = new File([text], fileName, { type: 'text/plain' });
		if (typeof navigator.share === 'function') {
			const data = navigator.canShare?.({ files: [file] })
				? { files: [file] }
				: { text };
			try {
				await navigator.share(data);
			} catch {
				// dismissed
			}
			return;
		}
		const url = URL.createObjectURL(file);
		const link = document.createElement('a');
		link.href = url;
		link.download = fileName;
		link.click();
		URL.revokeObjectURL(url);
	}
</script>

<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import { canonToast } from '../lib/toast-store.svelte.ts';
	import {
		copy as copyIcon,
		iconSnippet,
		share,
	} from '../lib/control-icons.ts';
	import CanonButton from './canon-button.svelte';
	import CanonEmptyRow from './canon-empty-row.svelte';
	import CanonGrid from './canon-grid.svelte';
	import CanonHeading from './canon-heading.svelte';
	import CanonRows from './canon-rows.svelte';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-text-output.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		text: string;
		heading: string;
		/** Name of the file Share hands over. */
		fileName: string;
		/** The output is still to come; the empty row stays away. */
		busy?: boolean;
		/** Shown when the output is blank; default None. */
		empty?: string;
		/** The output with its marks, shown in place of `text`. */
		children?: Snippet;
		/** Rows between the text and the actions. */
		extra?: Snippet;
	}

	let {
		text,
		heading,
		fileName,
		busy,
		empty,
		children,
		extra,
		class: className,
		...rest
	}: Props = $props();

	const Copy = iconSnippet(copyIcon);
	const Share = iconSnippet(share);

	const blank = $derived(text.trim() === '');

	const copy = () => {
		canonToast.write(text).catch(() => undefined);
	};
</script>

<!-- @component The output block of a text tool: a heading, the converted text, and Share beside Copy. -->
<CanonRows class={['canon-text-output', className]} framed {...rest}>
	<CanonHeading text={heading} />
	{#if !blank}
		<div class="canon-text-output-text">
			{#if children}{@render children()}{:else}{text}{/if}
		</div>
	{:else if !busy}
		<CanonEmptyRow text={empty || 'None'} />
	{/if}
	{@render extra?.()}
	<CanonGrid>
		<CanonButton
			text="Share"
			icon={Share}
			disabled={blank}
			onClick={() => shareText(text, fileName)}
		/>
		<CanonButton
			text="Copy"
			icon={Copy}
			iconStyle="oversized"
			kind="primary"
			disabled={blank}
			flashesCopied
			onClick={copy}
		/>
	</CanonGrid>
</CanonRows>
