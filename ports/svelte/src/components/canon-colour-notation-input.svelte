<script lang="ts" module>
	/** Typed text is read after this pause, on Return, and when the field loses focus. */
	export const typingPauseMs = 400;

	interface EyeDropperResult {
		sRGBHex: string;
	}

	type EyeDropperWindow = Window & {
		EyeDropper?: new () => { open(): Promise<EyeDropperResult> };
	};
</script>

<script lang="ts">
	import { onDestroy } from 'svelte';
	import type { HTMLAttributes } from 'svelte/elements';
	import {
		hex,
		parseColour,
		parseHex,
		type Rgb,
	} from '@canon/lib/colour.ts';
	import { Pipette } from '../lib/control-icons.ts';
	import CanonButton from './canon-button.svelte';
	import CanonRule from './canon-rule.svelte';
	import CanonTextCell from './canon-text-cell.svelte';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-colour-notation-input.css';

	interface Props extends HTMLAttributes<HTMLDivElement> {
		/** Shown as hex while the field is not being typed in. */
		colour?: Rgb;
		/** A formatted value shown instead of `colour`'s hex. */
		text?: string;
		/** A picked colour, and a typed one read by the default `parse`. */
		onColour?: (colour: Rgb) => void;
		/**
		 * Reads typed text and uses it; false turns the text red. The default
		 * reads any notation `parseColour` knows and passes it to `onColour`.
		 */
		parse?: (text: string) => boolean;
		placeholder?: string;
		/** Id of the element that names the field, such as a row title. */
		labelledBy?: string;
		label?: string;
	}

	let {
		colour,
		text,
		onColour,
		parse: givenParse,
		placeholder,
		labelledBy,
		label,
		class: className,
		...rest
	}: Props = $props();

	// the typed text holds until what is shown changes
	let typed = $state<{ text: string; over: string }>();
	let fails = $state(false);
	let typing: number | undefined;
	let focused = false;
	const hasEyedropper =
		typeof window !== 'undefined' && 'EyeDropper' in window;

	const shown = $derived(text ?? (colour ? hex(colour) : ''));
	const value = $derived(
		typed && (focused || typed.over === shown) ? typed.text : shown,
	);
	const failing = $derived(fails && value === typed?.text);

	function parse(entry: string): boolean {
		if (givenParse) return givenParse(entry);
		const parsed = parseColour(entry);
		if (parsed) onColour?.(parsed);
		return parsed !== undefined;
	}

	function read() {
		window.clearTimeout(typing);
		const entry = typed?.text;
		if (entry === undefined) return;
		fails = !parse(entry) && entry.trim() !== '';
	}

	function type(entry: string) {
		typed = { text: entry, over: shown };
		fails = false;
		window.clearTimeout(typing);
		typing = window.setTimeout(read, typingPauseMs);
	}

	function leave() {
		focused = false;
		read();
		if (typed) typed = { ...typed, over: shown };
	}

	async function pick() {
		const { EyeDropper } = window as EyeDropperWindow;
		if (!EyeDropper) return;
		try {
			const { sRGBHex } = await new EyeDropper().open();
			const picked = parseHex(sRGBHex);
			if (picked) onColour?.(picked);
		} catch {
			// Escape closes the eyedropper with an AbortError
		}
	}

	onDestroy(() => clearTimeout(typing));
</script>

<!--
  @component
  A colour typed in any notation beside an eyedropper cell. The eyedropper
  is the browser's EyeDropper and is left out where the browser has none.
-->
<div class={['canon-colour-notation-input', className]} {...rest}>
	<CanonTextCell
		class={[
			'canon-colour-notation-input-field',
			failing && 'canon-colour-notation-input--fails',
		]}
		{value}
		placeholder={placeholder ? placeholder : 'oklch(0.64 0.15 264)'}
		onChange={type}
		spellcheck="false"
		autocomplete="off"
		autocapitalize="off"
		aria-labelledby={labelledBy}
		aria-label={label}
		aria-invalid={failing ? 'true' : undefined}
		onfocus={() => (focused = true)}
		onblur={leave}
	/>
	{#if hasEyedropper}
		<CanonRule vertical />
		<CanonButton
			kind="cell"
			icon={Pipette}
			label="Colour"
			onClick={pick}
		/>
	{/if}
</div>
