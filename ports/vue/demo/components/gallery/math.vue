<script lang="ts">
export const pane = 'main';
export const order = 30;
</script>

<script setup lang="ts">
import { computed, ref } from 'vue';
import CanonButton from '../../../src/components/canon-button.vue';
import CanonCanvas from '../../../src/components/canon-canvas.vue';
import CanonGrid from '../../../src/components/canon-grid.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonMathField, {
	CanonMathFieldHandle,
} from '../../../src/components/canon-math-field.vue';
import CanonMathKey from '../../../src/components/canon-math-key.vue';
import CanonMathKeypad from '../../../src/components/canon-math-keypad.vue';
import CanonMathView from '../../../src/components/canon-math-view.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import type { Key } from '@canon/lib/math/expression.ts';

const inserts: Key[] = [
	{ kind: 'fraction' },
	{ kind: 'power' },
	{ kind: 'root' },
	{ kind: 'symbol', symbol: '×' },
];
const morphs = ['(x+1)^2', 'x^2+2*x+1', '(x+1)*(x+1)'];
const views = [
	'sqrt(x^2+1)/(2*x)',
	'defint(sin(x)^2,0,pi,x)',
	'sum(k^2,k,1,n)',
];
const viewRow =
	'display: flex; flex-wrap: wrap; gap: 24px; align-items: center; justify-content: space-around; padding: 16px; background: var(--canon-card)';

const handle = new CanonMathFieldHandle();
const morph = ref(0);
const morphText = computed(() => morphs[morph.value % morphs.length]);
const next = () => (morph.value += 1);
</script>

<template>
	<CanonRows :framed="true">
		<CanonHeading text="Maths input" />
		<CanonMathField
			text="(x+1)^2/2"
			placeholder="x^2 - 4"
			:handle="handle"
		/>
		<CanonMathField variable="t" placeholder="sin(t)" />
		<CanonGrid :columns="4">
			<CanonMathKey
				v-for="(key, i) in inserts"
				:key="i"
				:math-key="key"
				:on-click="() => handle.edit([key])"
			/>
		</CanonGrid>
		<CanonHeading text="Maths view" />
		<div :style="viewRow">
			<CanonMathView
				v-for="text in views"
				:key="text"
				:text="text"
				:size="22"
			/>
			<CanonMathView
				text="b*c^(-1)+(1/2)*x^(-1/2)"
				:presents="true"
			/>
		</div>
	</CanonRows>
	<CanonCanvas :height="140">
		<CanonMathView
			:text="morphText"
			:size="34"
			:morphs="true"
			style="block-size: 100%"
		/>
	</CanonCanvas>
	<CanonRows :framed="true">
		<CanonButton text="Morph" :on-click="next" />
		<CanonHeading text="Maths keypad" />
		<CanonMathKeypad variable="t" />
	</CanonRows>
</template>
