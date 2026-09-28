<script lang="ts">
  import CanonGlyphFlow from '../../src/components/canon-glyph-flow.svelte';
  import type { GlyphKind } from '@canon/lib/glyph-rows.ts';

  let { glyphs, label }: { glyphs: string[]; label?: string } = $props();

  const metrics = { height: 36, rowGap: 8, gap: 4 };
  const measure = () => 28;
  const kind = (c: string): GlyphKind =>
    c === '\n' ? 'newline' : c === ' ' ? 'space' : 'glyph';
</script>

<div style="width: 300px; height: 120px">
  <CanonGlyphFlow {glyphs} {metrics} {measure} {kind} {label}>
    {#snippet children(glyph, index)}
      <span class="g" data-index={index}>{glyph}</span>
    {/snippet}
    {#snippet empty()}
      <span class="nothing">Empty</span>
    {/snippet}
  </CanonGlyphFlow>
</div>
