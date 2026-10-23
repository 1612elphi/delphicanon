<script lang="ts" module>
	export const pane = 'main';
	export const order = 30;
</script>

<script lang="ts">
	import CanonButton from '../../src/components/canon-button.svelte';
	import CanonCanvas from '../../src/components/canon-canvas.svelte';
	import CanonGrid from '../../src/components/canon-grid.svelte';
	import CanonHeading from '../../src/components/canon-heading.svelte';
	import CanonMathField, {
		CanonMathFieldHandle,
	} from '../../src/components/canon-math-field.svelte';
	import CanonMathKey from '../../src/components/canon-math-key.svelte';
	import CanonMathKeypad from '../../src/components/canon-math-keypad.svelte';
	import CanonMathView from '../../src/components/canon-math-view.svelte';
	import CanonRows from '../../src/components/canon-rows.svelte';
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
	let morph = $state(0);
</script>

<CanonRows framed>
	<CanonHeading text="Maths input" />
	<CanonMathField text="(x+1)^2/2" placeholder="x^2 - 4" {handle} />
	<CanonMathField variable="t" placeholder="sin(t)" />
	<CanonGrid columns={4}>
		{#each inserts as key, i (i)}
			<CanonMathKey
				{key}
				onClick={() => handle.edit([key])}
			/>
		{/each}
	</CanonGrid>
	<CanonHeading text="Maths view" />
	<div style={viewRow}>
		{#each views as text (text)}
			<CanonMathView {text} size={22} />
		{/each}
		<CanonMathView text="b*c^(-1)+(1/2)*x^(-1/2)" presents />
	</div>
</CanonRows>
<CanonCanvas height={140}>
	<CanonMathView
		text={morphs[morph % morphs.length]}
		size={34}
		morphs
		style="block-size: 100%"
	/>
</CanonCanvas>
<CanonRows framed>
	<CanonButton text="Morph" onClick={() => (morph += 1)} />
	<CanonHeading text="Maths keypad" />
	<CanonMathKeypad variable="t" />
</CanonRows>
