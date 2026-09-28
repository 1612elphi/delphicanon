<script lang="ts" module>
  export const pane = 'main';
  export const order = 30;
</script>

<script lang="ts">
  import CanonCanvas from '../../src/components/canon-canvas.svelte';
  import CanonGlyphFlow from '../../src/components/canon-glyph-flow.svelte';
  import CanonHeading from '../../src/components/canon-heading.svelte';
  import CanonRows from '../../src/components/canon-rows.svelte';
  import CanonTextInput from '../../src/components/canon-text-input.svelte';
  import CanonTextOutput from '../../src/components/canon-text-output.svelte';
  import type { GlyphKind } from '@canon/lib/glyph-rows.ts';
  import '../../../../demo-app/components/gallery/display.css';

  const start = 'Glyph flow';
  const metrics = { height: 36, rowGap: 8, gap: 4 };
  const measure = () => 28;
  const kind = (c: string): GlyphKind =>
    c === '\n' ? 'newline' : /\s/.test(c) ? 'space' : 'glyph';
  const isSpace = (c: string) => /\s/.test(c);

  let text = $state(start);
  const glyphs = $derived([...text]);
  const upper = $derived(text.toUpperCase());

  const change = (next: string) => {
    text = next;
  };
</script>

<CanonCanvas height={120}>
  <CanonGlyphFlow {glyphs} {metrics} {measure} {kind} label={text}>
    {#snippet children(glyph)}
      {#if !isSpace(glyph)}
        <span class="gallery-glyph">{glyph}</span>
      {/if}
    {/snippet}
  </CanonGlyphFlow>
</CanonCanvas>
<CanonRows framed>
  <CanonHeading text="Text input" />
  <CanonTextInput value={start} onChange={change} />
</CanonRows>
<CanonTextOutput text={upper} heading="Text output" fileName="gallery.txt" />
