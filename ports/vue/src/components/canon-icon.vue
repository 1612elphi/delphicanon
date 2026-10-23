<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
	/** An SVG string, as lucide-static exports them. */
	svg: string;
}>();

// lucide's fixed 24 px size would override the CSS box the call site gives the svg
const parts = computed(() => {
	const root = new DOMParser().parseFromString(
		props.svg,
		'image/svg+xml',
	).documentElement;
	const attrs: Record<string, string> = {};
	for (const { name, value } of root.attributes) {
		if ((name === 'width' || name === 'height') && value === '24')
			continue;
		attrs[name] = value;
	}
	return { attrs, inner: root.innerHTML };
});
</script>

<template>
	<!-- eslint-disable-next-line vue/no-v-html -->
	<svg v-bind="parts.attrs" v-html="parts.inner" />
</template>
