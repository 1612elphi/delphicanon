<script lang="ts">
import { appearDelay, jumpColumns } from '@canon/lib/jump.ts';
import { reducedMotion, springEasing } from '@canon/lib/motion.ts';
import { elementDirective } from '../lib/directive.ts';

export interface CanonJumpSection {
	title: string;
	/** Under the title, as a count of the group's items. */
	detail?: string;
}

// iOS crossDissolve: no scale
const fade = (): Keyframe[] => [{ opacity: 0 }, { opacity: 1 }];

const tileSpring = springEasing(0.7);

const vAppear = elementDirective<[number, number, number]>((tile, value) => {
	if (!reducedMotion()) {
		const [index, count, current] = value();
		tile.animate(
			[
				{
					opacity: 0,
					transform: 'scale(0.8) rotate(-0.05rad)',
				},
				{ opacity: 1, transform: 'none' },
			],
			{
				duration: 450,
				delay: appearDelay(index, count, current),
				easing: tileSpring,
				fill: 'backwards',
			},
		);
	}
	return () => {};
});
</script>

<script setup lang="ts">
import { computed, ref } from 'vue';
import CanonDialog, { type CanonDialogClose } from './canon-dialog.vue';
import CanonGrid from './canon-grid.vue';
import { vPress } from '../lib/press.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-jump-grid.css';

const props = defineProps<{
	open: boolean;
	sections: CanonJumpSection[];
	/** The lit tile: the group in view. It takes focus when the grid opens. */
	current?: number;
	/** The dialog's accessible name; default Sections. */
	label?: string;
	/** A tile was picked; called after the grid has closed and focus has returned. */
	onPick?: (index: number) => void;
	/** Every close. The owner sets `open` false here. */
	onClose?: () => void;
}>();

const columns = ref(
	typeof window === 'undefined' ? 2 : jumpColumns(window.innerWidth),
);

const tiles = computed(() =>
	props.sections.map((section, index) => ({
		...section,
		index,
		value: String(index),
		lit: index === props.current,
	})),
);

const vMeasure = elementDirective<void>((holder) => {
	const observer = new ResizeObserver(([entry]) => {
		columns.value = jumpColumns(entry?.contentRect.width ?? 0);
	});
	observer.observe(holder.closest('dialog') ?? holder);
	return () => observer.disconnect();
});

function outside(close: CanonDialogClose, event: MouseEvent) {
	if (!(event.target as Element).closest('.canon-jump-grid-tile'))
		close();
}

function closed(value: string) {
	props.onClose?.();
	if (value !== '') props.onPick?.(Number(value));
}
</script>

<!--
  The Windows Phone jump list: every group of a long list as a tile over
  the page, the group in view lit. A pick closes it and reports the group;
  a click beside the tiles or Escape closes it.
-->
<template>
	<CanonDialog
		class="canon-jump-grid"
		:aria-label="label || 'Sections'"
		:open="open"
		:keyframes="fade"
		:on-close="closed"
	>
		<template #default="{ close }">
			<div
				v-measure
				class="canon-jump-grid-holder"
				@click="outside(close, $event)"
			>
				<CanonGrid :columns="columns" :boxed="true">
					<button
						v-for="tile in tiles"
						:key="tile.index"
						v-press
						v-appear="[
							tile.index,
							tiles.length,
							current ?? 0,
						]"
						type="button"
						class="canon-jump-grid-tile"
						:class="{
							'canon-jump-grid-tile--lit':
								tile.lit,
						}"
						:aria-current="
							tile.lit
								? 'true'
								: undefined
						"
						:autofocus="tile.lit"
						@click="close(tile.value)"
					>
						<span
							class="canon-jump-grid-title"
							>{{ tile.title }}</span
						>
						<span
							v-if="tile.detail"
							class="canon-jump-grid-detail"
							>{{ tile.detail }}</span
						>
					</button>
				</CanonGrid>
			</div>
		</template>
	</CanonDialog>
</template>
