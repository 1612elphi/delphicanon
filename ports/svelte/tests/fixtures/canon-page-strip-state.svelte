<script lang="ts">
  import CanonPageStrip, {
    type CanonPage,
  } from '../../src/components/canon-page-strip.svelte';

  interface Props {
    onMove: (from: number, to: number) => void;
    onSelect: (index: number) => void;
  }

  let { onMove, onSelect }: Props = $props();

  let pages = $state<CanonPage[]>([
    { size: { width: 595, height: 842 }, name: 'A' },
    { size: { width: 842, height: 595 }, name: 'B' },
    { size: { width: 595, height: 842 }, name: 'C', depth: 2 },
  ]);
  let selected = $state(1);

  // the handlers write back, as the Ember test's State does
  function move(from: number, to: number) {
    onMove(from, to);
    const next = [...pages];
    next.splice(to, 0, ...next.splice(from, 1));
    pages = next;
  }

  function select(index: number) {
    onSelect(index);
    selected = index;
  }
</script>

<div style="width: 600px; height: 192px">
  <CanonPageStrip {pages} {selected} onSelect={select} reorders onMove={move} />
</div>
