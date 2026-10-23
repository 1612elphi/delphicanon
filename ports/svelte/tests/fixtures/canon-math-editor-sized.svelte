<script lang="ts">
	import CanonMathEditor from '../../src/components/canon-math-editor.svelte';
	import type { MathEditing } from '../../src/lib/math-editing.svelte.ts';

	let { editing }: { editing: MathEditing } = $props();
</script>

<div style="width: 300px; height: 112px; display: flex">
	<CanonMathEditor {editing} />
</div>
