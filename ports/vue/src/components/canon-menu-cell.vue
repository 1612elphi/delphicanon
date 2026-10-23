<script setup lang="ts">
import { computed, ref } from 'vue';
import { ChevronsUpDown } from '../lib/control-icons.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-menu-cell.css';

const props = defineProps<{
	items: string[];
	/** Undefined shows the placeholder: a value set elsewhere that matches no choice. */
	selected?: number;
	/** Default an em dash. */
	placeholder?: string;
	labelledBy?: string;
	label?: string;
	disabled?: boolean;
	onChange?: (index: number) => void;
}>();

const picked = ref<{ index: number; over: number | undefined }>();

const selected = computed(() =>
	picked.value && picked.value.over === props.selected
		? picked.value.index
		: props.selected,
);
const title = computed(() =>
	selected.value === undefined ? undefined : props.items[selected.value],
);
const placeholder = computed(() => props.placeholder ?? '—');
const options = computed(() =>
	props.items.map((choice, index) => ({
		title: choice,
		value: String(index),
		selected: index === selected.value,
	})),
);

function pick(event: Event) {
	const index = Number((event.target as HTMLSelectElement).value);
	if (index === selected.value) return;
	picked.value = { index, over: props.selected };
	props.onChange?.(index);
}
</script>

<!--
  A flush cell that shows one choice and opens the system menu of all of
  them: a native select laid invisibly over the cell.
-->
<template>
	<div
		class="canon-menu-cell"
		:class="{ 'canon-menu-cell--disabled': disabled }"
	>
		<span class="canon-menu-cell-title">{{
			title ? title : placeholder
		}}</span>
		<span class="canon-menu-cell-icon" aria-hidden="true"
			><ChevronsUpDown
		/></span>
		<select
			class="canon-menu-cell-select"
			:aria-labelledby="labelledBy"
			:aria-label="label"
			:disabled="disabled"
			@change="pick"
		>
			<option v-if="!title" value="" disabled selected hidden>
				{{ placeholder }}
			</option>
			<option
				v-for="choice in options"
				:key="choice.value"
				:value="choice.value"
				:selected="choice.selected"
			>
				{{ choice.title }}
			</option>
		</select>
	</div>
</template>
