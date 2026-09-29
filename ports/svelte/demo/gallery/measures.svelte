<script lang="ts" module>
  export const pane = 'main';
  export const order = 16;
</script>

<script lang="ts">
  import type { Attachment } from 'svelte/attachments';
  import CanonCanvas from '../../src/components/canon-canvas.svelte';
  import CanonCompressionScale from '../../src/components/canon-compression-scale.svelte';
  import CanonDimensionLine from '../../src/components/canon-dimension-line.svelte';
  import CanonHeading from '../../src/components/canon-heading.svelte';
  import CanonRow from '../../src/components/canon-row.svelte';
  import CanonRows from '../../src/components/canon-rows.svelte';
  import CanonSegmented from '../../src/components/canon-segmented.svelte';
  import CanonSwitch from '../../src/components/canon-switch.svelte';
  import {
    dimensionLines,
    sheet,
    type Rect,
  } from '@canon/lib/dimension-line.ts';
  import '../../../../demo-app/components/gallery/measures.css';

  const picture = { width: 1600, height: 1200 };

  const scales = [
    { title: 'Saved', before: 2_400_000, after: 1_700_000, working: false },
    { title: 'Grew', before: 2_400_000, after: 3_100_000, working: false },
    { title: 'Even', before: 2_400_000, after: 2_400_000, working: false },
    { title: 'Working', before: 2_400_000, after: 0, working: true },
    { title: 'Empty', before: 0, after: 0, working: false },
  ];
  const titles = scales.map((scale) => scale.title);

  const box = ({ x, y, width, height }: Rect) =>
    `inset-inline-start: ${x}px; inset-block-start: ${y}px; inline-size: ${width}px; block-size: ${height}px`;

  let area = $state<Rect>({ x: 0, y: 0, width: 0, height: 0 });
  let scale = $state(0);
  let blank = $state(false);
  const frame = $derived(sheet(picture, area));
  const lines = $derived(dimensionLines(frame));
  const shown = $derived(scales[scale]!);

  const measure: Attachment<HTMLElement> = (element) => {
    const observer = new ResizeObserver(() => {
      area = {
        x: element.offsetLeft,
        y: element.offsetTop,
        width: element.clientWidth,
        height: element.clientHeight,
      };
    });
    observer.observe(element);
    return () => observer.disconnect();
  };
</script>

<CanonCanvas height={220} background="var(--canon-muted)">
  <div class="gallery-dimensions">
    <span class="gallery-dimensions-area" {@attach measure}></span>
    {#if area.width}
      <span class="gallery-dimensions-sheet" style={box(frame)}></span>
      <CanonDimensionLine
        pixels={picture.width}
        {blank}
        style={box(lines.across)}
      />
      <CanonDimensionLine
        pixels={picture.height}
        {blank}
        down
        style={box(lines.down)}
      />
    {/if}
  </div>
</CanonCanvas>
<CanonCanvas height={176}>
  <CanonCompressionScale
    before={shown.before}
    after={shown.after}
    format="JPEG"
    working={shown.working}
  />
</CanonCanvas>
<CanonRows framed>
  <CanonHeading text="Measures" />
  <CanonSegmented
    items={titles}
    selected={scale}
    onChange={(index) => (scale = index)}
  />
  <CanonRow title="Blank">
    {#snippet children(titleId)}
      <CanonSwitch
        on={blank}
        onChange={(on) => (blank = on)}
        aria-labelledby={titleId}
      />
    {/snippet}
  </CanonRow>
</CanonRows>
