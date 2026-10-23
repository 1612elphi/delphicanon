<script lang="ts" module>
	export const pane = 'sidebar';
	export const order = 45;
</script>

<script lang="ts">
	import CanonJumpHeading from '../../src/components/canon-jump-heading.svelte';
	import CanonRow from '../../src/components/canon-row.svelte';
	import CanonRows from '../../src/components/canon-rows.svelte';
	import CanonSwitch from '../../src/components/canon-switch.svelte';
</script>

<CanonRows framed>
	<CanonJumpHeading text="Rows" detail="2" />
	<CanonRow title="Plain">
		{#snippet children(titleId)}
			<CanonSwitch on aria-labelledby={titleId} />
		{/snippet}
	</CanonRow>
	<CanonRow title="No control" />
	<CanonJumpHeading text="Components" detail="2" />
	<CanonRow title="Images">
		{#snippet children(titleId)}
			<CanonSwitch on aria-labelledby={titleId} />
		{/snippet}
	</CanonRow>
	<CanonRow title="Files">
		{#snippet children(titleId)}
			<CanonSwitch aria-labelledby={titleId} />
		{/snippet}
	</CanonRow>
	<CanonJumpHeading text="Big number" detail="1" />
	<CanonRow title="Sound">
		{#snippet children(titleId)}
			<CanonSwitch aria-labelledby={titleId} />
		{/snippet}
	</CanonRow>
</CanonRows>
