<script lang="ts">
	let { label }: { label: string } = $props();
</script>

<!-- @component Stand-in canvas content: a gradient with a centred label. -->
<div class="gallery-art"><span>{label}</span></div>
