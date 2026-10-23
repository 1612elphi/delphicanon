<script lang="ts">
export const pane = 'sidebar';
export const order = 10;
</script>

<script setup lang="ts">
import CanonBar from '../../../src/components/canon-bar.vue';
import CanonEmptyRow from '../../../src/components/canon-empty-row.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonRow from '../../../src/components/canon-row.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import { icon } from '../icon.ts';
import bug from 'lucide-static/icons/bug.svg?raw';

const detailCaption = 'Caption under the title';
</script>

<template>
	<CanonRows :framed="true">
		<CanonHeading text="Rows" />
		<CanonRow title="Plain"
			><CanonBar class="gallery-bar" :share="0.65"
		/></CanonRow>
		<CanonRow
			title="Detail and icon"
			:icon="icon(bug)"
			:detail="detailCaption"
		>
			<CanonBar class="gallery-bar" :share="0.3" />
		</CanonRow>
		<CanonRow title="No control" />
		<CanonEmptyRow text="Nothing here" />
	</CanonRows>
</template>
