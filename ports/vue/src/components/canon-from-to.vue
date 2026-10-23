<script setup lang="ts">
import CanonMenuCell from './canon-menu-cell.vue';
import { ArrowRight } from '../lib/control-icons.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-from-to.css';

defineProps<{
	items: string[];
	from?: number;
	to?: number;
	/** Accessible names of the two menus; default From and To. */
	fromLabel?: string;
	toLabel?: string;
	disabled?: boolean;
	onFromChange?: (index: number) => void;
	onToChange?: (index: number) => void;
}>();
</script>

<!-- Two menus of the same choices with an arrow between: a conversion from one to the other. -->
<template>
	<div class="canon-from-to" role="group">
		<CanonMenuCell
			:items="items"
			:selected="from"
			:label="fromLabel ? fromLabel : 'From'"
			:disabled="disabled"
			:on-change="onFromChange"
		/>
		<span class="canon-from-to-arrow" aria-hidden="true"
			><ArrowRight
		/></span>
		<CanonMenuCell
			:items="items"
			:selected="to"
			:label="toLabel ? toLabel : 'To'"
			:disabled="disabled"
			:on-change="onToChange"
		/>
	</div>
</template>
