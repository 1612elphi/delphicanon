<script lang="ts" module>
  import {
    fromOklch,
    hex,
    oklabToLinear,
    parseHex,
    type Rgb,
  } from '@canon/lib/colour.ts';
  import { solidSpaces, spaceNames } from '@canon/lib/colour-space.ts';
  import { frame } from '@canon/lib/loupe.ts';
  import type { Attachment } from 'svelte/attachments';

  // stand-in for the app's 4,926 colour names
  const names: [string, Rgb][] = (
    [
      ['Black', '000000'],
      ['White', 'FFFFFF'],
      ['Grey', '808080'],
      ['Red', 'E53935'],
      ['Orange', 'FB8C00'],
      ['Yellow', 'FDD835'],
      ['Olive', '808000'],
      ['Green', '43A047'],
      ['Forest', '1E6626'],
      ['Teal', '00897B'],
      ['Cyan', '00ACC1'],
      ['Blue', '1E88E5'],
      ['Navy', '1A237E'],
      ['Purple', '8E24AA'],
      ['Pink', 'D81B60'],
      ['Brown', '6D4C41'],
      ['Cream', 'FAF5E6'],
    ] as const
  ).map(([name, code]) => [name, parseHex(code)!]);

  function nameOf(code: string): string {
    const [r, g, b] = parseHex(code)!;
    let best = names[0]!;
    let distance = Infinity;
    for (const entry of names) {
      const [x, y, z] = entry[1];
      const d = (r - x) ** 2 + (g - y) ** 2 + (b - z) ** 2;
      if (d < distance) [best, distance] = [entry, d];
    }
    return best[0];
  }

  const closestName = (colour: Rgb) => nameOf(hex(colour));

  function maxChroma(l: number, h: number): number {
    const radians = (h * Math.PI) / 180;
    let [low, high] = [0, 0.5];
    for (let i = 0; i < 24; i++) {
      const mid = (low + high) / 2;
      const inside = oklabToLinear(
        l,
        mid * Math.cos(radians),
        mid * Math.sin(radians),
      ).every((v) => v >= -1e-5 && v <= 1 + 1e-5);
      if (inside) low = mid;
      else high = mid;
    }
    return low;
  }

  function inGamut(l: number, c: number, h: number): Rgb {
    const hue = ((h % 360) + 360) % 360;
    return fromOklch(l, Math.min(c, maxChroma(l, hue)), hue);
  }

  const views = ['Slice', 'Ortho', 'Cut'];
  const harmonyKinds = ['Analogous', 'Split'];
  const normal = [
    [1, 0, 0],
    [0, 1, 0],
    [0, 0, 1],
  ];
  const deuteranopiaMatrix = [
    [0.625, 0.375, 0],
    [0.7, 0.3, 0],
    [0, 0.3, 0.7],
  ];

  const spaceName = (index: number) => spaceNames[solidSpaces[index]!];
  const tintDigits = (character: string) =>
    /\d/.test(character) ? 'var(--canon-primary)' : 'var(--canon-foreground)';

  // the colour's shades around the middle pixel, as the iOS gallery draws them
  function loupePixels(colour: Rgb): ImageData {
    const side = 15;
    const pixels = new ImageData(side, side);
    for (let y = 0; y < side; y++) {
      for (let x = 0; x < side; x++) {
        const toward = (x + y) % 2 === 0 ? 1 : 0;
        const by = (Math.abs(x - 7) + Math.abs(y - 7)) / 16;
        const at = (y * side + x) * 4;
        colour.forEach((channel, i) => {
          pixels.data[at + i] = Math.round(
            (channel + (toward - channel) * by) * 255,
          );
        });
        pixels.data[at + 3] = 255;
      }
    }
    return pixels;
  }

  const placeLoupe: Attachment<HTMLElement> = (loupe) => {
    const box = loupe.parentElement!;
    const observer = new ResizeObserver(() => {
      const { clientWidth: width, clientHeight: height } = box;
      const spot = frame(
        { x: width / 2, y: height / 2 + 60 },
        112,
        24,
        { width, height },
        8,
      );
      loupe.style.insetInlineStart = `${spot.x}px`;
      loupe.style.insetBlockStart = `${spot.y}px`;
    });
    observer.observe(box);
    return () => observer.disconnect();
  };

  // ?colourSpace=<picker index>&colourRow=<0-3>&colourView=<0-2>&colourCrease: the starting state, as the iOS launch arguments
  const query = new URLSearchParams(window.location.search);
  const number = (key: string) => Number(query.get(key) ?? 0) || 0;
  const startView = number('colourView');
  const crease = query.has('colourCrease');
</script>

<script lang="ts">
  import CanonButton from '../src/components/canon-button.svelte';
  import CanonCanvas from '../src/components/canon-canvas.svelte';
  import CanonColourCard from '../src/components/canon-colour-card.svelte';
  import CanonColourControls, {
    CanonColourSolidState,
  } from '../src/components/canon-colour-controls.svelte';
  import CanonColourNotationInput from '../src/components/canon-colour-notation-input.svelte';
  import CanonColourSolid from '../src/components/canon-colour-solid.svelte';
  import CanonColourStrip from '../src/components/canon-colour-strip.svelte';
  import CanonDetentWheel from '../src/components/canon-detent-wheel.svelte';
  import CanonDetentWheelRow from '../src/components/canon-detent-wheel-row.svelte';
  import CanonHeading from '../src/components/canon-heading.svelte';
  import CanonLoupe from '../src/components/canon-loupe.svelte';
  import CanonPaletteCard from '../src/components/canon-palette-card.svelte';
  import CanonRow from '../src/components/canon-row.svelte';
  import CanonRows from '../src/components/canon-rows.svelte';
  import CanonSegmented from '../src/components/canon-segmented.svelte';
  import CanonSplit from '../src/components/canon-split.svelte';
  import CanonSwitch from '../src/components/canon-switch.svelte';
  import CanonValueLine from '../src/components/canon-value-line.svelte';
  import { luminance, oklch } from '@canon/lib/colour.ts';
  import { icon } from './icon.ts';
  import copy from 'lucide-static/icons/copy.svg?raw';
  import save from 'lucide-static/icons/download.svg?raw';
  import share from 'lucide-static/icons/share.svg?raw';

  const model = new CanonColourSolidState({
    space: query.has('colourSpace')
      ? solidSpaces[number('colourSpace')]
      : 'hsl',
    activeRow: number('colourRow'),
  });
  model.slices = startView !== 2;
  model.viewPlane = startView === 1;

  let view = $state(startView);
  let split = $state(false);
  let stripPalette = $state(false);
  let deuteranopia = $state(false);

  const colour = $derived(model.colour);
  const harmony = $derived.by((): Rgb[] => {
    const [l, c, h] = oklch(colour);
    return (split ? [0, 150, 210] : [0, 30, -30]).map((turn) =>
      inGamut(l, c, h + turn),
    );
  });
  const shades = $derived.by((): Rgb[] => {
    const [, c, h] = oklch(colour);
    return Array.from({ length: 9 }, (_, i) => inGamut(0.95 - i * 0.085, c, h));
  });
  const decimal = $derived(
    `rgb(${colour.map((v) => v.toFixed(4)).join(', ')})`,
  );

  function showView(index: number) {
    view = index;
    model.slices = index !== 2;
    model.viewPlane = index === 1;
  }

  const copyPalette = () =>
    void navigator.clipboard?.writeText(harmony.map(hex).join('\n'));
</script>

<!-- @component The port of CanonColourGalleryViewController: the solid, colour cards and palette cards, driven by one colour. -->
<CanonSplit
  class="gallery"
  halves
  collapsesTo={240}
  pictureMeetsCrease={crease}
>
  {#snippet sidebar()}
    <CanonCanvas aspect={1} maxHeight={640} background="var(--canon-muted)">
      <div class="gallery-solid">
        <CanonColourSolid
          class="gallery-solid-picture"
          space={model.space}
          point={model.point}
          animated={model.animated}
          sliceAxis={model.sliceAxis}
          isOrtho={model.isOrtho}
          showsWhole={model.showsWhole}
          marks={harmony.slice(1)}
          vision={deuteranopia ? deuteranopiaMatrix : normal}
          onChange={model.pick}
          {closestName}
        />
        <CanonColourStrip
          {colour}
          palette={stripPalette ? harmony : undefined}
          {nameOf}
        />
      </div>
    </CanonCanvas>
  {/snippet}
  {#snippet main()}
    <CanonRows framed>
      <CanonHeading text="Solid" />
      <CanonColourControls state={model}>
        <CanonRow title="View" form="flush">
          <CanonSegmented items={views} selected={view} onChange={showView} />
        </CanonRow>
      </CanonColourControls>
      <CanonRow title="Strip palette">
        {#snippet children(titleId)}
          <CanonSwitch
            on={stripPalette}
            onChange={(on) => (stripPalette = on)}
            aria-labelledby={titleId}
          />
        {/snippet}
      </CanonRow>
      <CanonRow title="Deuteranopia">
        {#snippet children(titleId)}
          <CanonSwitch
            on={deuteranopia}
            onChange={(on) => (deuteranopia = on)}
            aria-labelledby={titleId}
          />
        {/snippet}
      </CanonRow>
    </CanonRows>
    <CanonColourCard {colour} {nameOf} />
    <CanonColourCard {colour} layout="row" {nameOf} />
    <CanonRows framed>
      <CanonHeading text="Value lines" />
      <CanonValueLine label="Decimal RGB" value={decimal} labelWidth={92} />
      <CanonValueLine
        label="Luminance"
        value={luminance(colour).toFixed(3)}
        labelWidth={92}
      />
      <CanonValueLine label="Above" value={hex(colour)} layout="above" />
      <CanonValueLine
        label="x ="
        value={hex(colour).repeat(4)}
        layout="wrapping"
      />
      <CanonValueLine label="Nil" value={null} layout="wrapping" />
      <CanonValueLine label="01" value={hex(colour)} layout="numbered" lit />
      <CanonValueLine
        label="02"
        value={hex(colour).repeat(5)}
        layout="numbered"
        wraps
        tint={tintDigits}
      />
    </CanonRows>
    <CanonRows framed>
      <CanonHeading text="Notation input" />
      <CanonRow title="Any notation" form="stacked">
        {#snippet children(titleId)}
          <CanonColourNotationInput
            {colour}
            onColour={model.use}
            labelledBy={titleId}
          />
        {/snippet}
      </CanonRow>
      <CanonHeading text="Loupe" />
      <CanonCanvas height={200} background="var(--canon-muted)">
        <CanonLoupe
          class="gallery-loupe"
          pixels={loupePixels(colour)}
          {colour}
          {@attach placeLoupe}
        />
      </CanonCanvas>
      <CanonHeading text="Detent wheel" />
      <CanonCanvas height={200}>
        <CanonDetentWheel
          count={solidSpaces.length}
          selected={solidSpaces.indexOf(model.space)}
          onSelect={(index) => model.selectSpace(solidSpaces[index]!)}
          text={spaceName}
          label="Space"
        >
          {#snippet children(index, focus)}
            <CanonDetentWheelRow {focus}>{spaceName(index)}</CanonDetentWheelRow
            >
          {/snippet}
        </CanonDetentWheel>
      </CanonCanvas>
    </CanonRows>
    <CanonPaletteCard title="Harmony" colours={harmony} {nameOf}>
      {#snippet picker()}
        <CanonSegmented
          items={harmonyKinds}
          selected={split ? 1 : 0}
          onChange={(index) => (split = index === 1)}
        />
      {/snippet}
      {#snippet actions()}
        <CanonButton
          text="Copy"
          icon={icon(copy)}
          kind="cell"
          flashesCopied
          onClick={copyPalette}
        />
        <CanonButton text="Export" icon={icon(share)} kind="cell" />
        <CanonButton text="Save" icon={icon(save)} kind="cell" />
      {/snippet}
    </CanonPaletteCard>
    <CanonPaletteCard title="Shades" colours={shades} height={120} {nameOf} />
  {/snippet}
</CanonSplit>
