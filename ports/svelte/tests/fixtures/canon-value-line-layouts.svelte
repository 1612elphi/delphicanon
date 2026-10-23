<script lang="ts">
	import CanonValueLine from '../../src/components/canon-value-line.svelte';

	const digitsGreen = (character: string) =>
		/\d/.test(character) ? 'rgb(0, 128, 0)' : 'rgb(0, 0, 0)';
</script>

<div style="width: 240px">
	<CanonValueLine
		class="above"
		label="Above"
		value="#1e6626"
		layout="above"
	/>
	<CanonValueLine
		class="wrapping"
		label="x ="
		value="#1e6626#1e6626#1e6626#1e6626"
		layout="wrapping"
	/>
	<CanonValueLine
		class="numbered"
		label="01"
		value="#1e6626"
		layout="numbered"
		lit
		tint={digitsGreen}
	/>
</div>
