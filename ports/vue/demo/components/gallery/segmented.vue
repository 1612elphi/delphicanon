<script lang="ts">
export const pane = 'sidebar';
export const order = 20;
</script>

<script setup lang="ts">
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonRow from '../../../src/components/canon-row.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import CanonSegmented from '../../../src/components/canon-segmented.vue';
import { icon } from '../icon.ts';
import arrowDown from 'lucide-static/icons/arrow-down.svg?raw';
import arrowDownLeft from 'lucide-static/icons/arrow-down-left.svg?raw';
import arrowDownRight from 'lucide-static/icons/arrow-down-right.svg?raw';
import arrowLeft from 'lucide-static/icons/arrow-left.svg?raw';
import arrowRight from 'lucide-static/icons/arrow-right.svg?raw';
import arrowUp from 'lucide-static/icons/arrow-up.svg?raw';
import arrowUpLeft from 'lucide-static/icons/arrow-up-left.svg?raw';
import arrowUpRight from 'lucide-static/icons/arrow-up-right.svg?raw';
import circleDot from 'lucide-static/icons/circle-dot.svg?raw';

const modes = ['Region', 'Window', 'Screen', 'Timed'];
const five = ['One', 'Two', 'Three', 'Four', 'Five'];
const sizes = ['Tiny', 'Base', 'Small', 'Large'];
const labels = [
	'Top left',
	'Top',
	'Top right',
	'Left',
	'Centre',
	'Right',
	'Bottom left',
	'Bottom',
	'Bottom right',
];
const arrows = [
	arrowUpLeft,
	arrowUp,
	arrowUpRight,
	arrowLeft,
	circleDot,
	arrowRight,
	arrowDownLeft,
	arrowDown,
	arrowDownRight,
].map(icon);
</script>

<template>
	<CanonRows :framed="true">
		<CanonHeading text="Segmented" />
		<CanonRow title="Mode" form="stacked">
			<CanonSegmented :items="modes" />
		</CanonRow>
		<CanonRow title="Six in three" form="stacked">
			<CanonSegmented :items="five" :columns="3" />
		</CanonRow>
		<CanonRow title="Inline picker" form="flush">
			<CanonSegmented :items="modes" />
		</CanonRow>
		<CanonSegmented
			:items="sizes"
			:selected="1"
			:disabled-indices="[2, 3]"
		/>
		<CanonRow title="Symbols" form="stacked">
			<CanonSegmented
				:items="labels"
				:icons="arrows"
				:selected="7"
				:columns="3"
			/>
		</CanonRow>
	</CanonRows>
</template>
