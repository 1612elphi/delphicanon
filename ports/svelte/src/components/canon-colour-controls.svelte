<script lang="ts" module>
  import type { Rgb } from '@canon/lib/colour.ts';
  import {
    channels,
    colourAt,
    pointFor,
    solidSpaces,
    spaceNames,
    type SolidPoint,
    type SolidSpace,
  } from '@canon/lib/colour-space.ts';

  /**
   * What a CanonColourSolid shows and what its controls change: the Swift
   * controls held the solid itself, so here both read one state. Pass
   * `space`, `point`, `animated`, `sliceAxis`, `isOrtho` and `showsWhole` to
   * the solid and `pick` as its `onChange`. A new space reaches the solid with
   * the old point; the solid converts it and reports it through `pick`.
   */
  export class CanonColourSolidState {
    space = $state<SolidSpace>('hsl');
    point = $state<SolidPoint>([0, 0, 0, 0]);
    /** The last change of `point` eases, as after a tap on a slider track; drags and picks follow at once. */
    animated = $state(false);
    /** The slider row that is the solid's slice; row 3, CMYK's black, never slices. */
    activeRow = $state(0);
    /** Slices along the active row's channel; false cuts the solid away instead. */
    slices = $state(true);
    /** The View plane switch. */
    viewPlane = $state(false);
    /** True while CMYK's black changes. */
    showsWhole = $state(false);

    constructor({
      space = 'hsl',
      colour = [0.12, 0.4, 0.15],
      activeRow = 0,
    }: { space?: SolidSpace; colour?: Rgb; activeRow?: number } = {}) {
      this.space = space;
      this.point = pointFor(space, colour);
      this.activeRow = activeRow;
    }

    get colour(): Rgb {
      return colourAt(this.space, this.point);
    }

    get isOrtho(): boolean {
      return this.slices && this.viewPlane;
    }

    get sliceAxis(): number | undefined {
      if (!this.slices) return undefined;
      return channels(this.space)[Math.min(this.activeRow, 2)]?.axis;
    }

    setPoint(point: SolidPoint, animated: boolean) {
      this.animated = animated;
      this.point = point;
    }

    /** Eases to `colour`. */
    use = (colour: Rgb) => {
      this.setPoint(pointFor(this.space, colour), true);
    };

    selectSpace(space: SolidSpace) {
      this.space = space;
    }

    /** The solid's change callback. */
    pick = (point: SolidPoint) => this.setPoint(point, false);
  }

  const spaceTitles = solidSpaces.map((space) => spaceNames[space]);
  const fixed = (decimals: number) => (value: number) =>
    value.toFixed(decimals);
</script>

<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { Attachment } from 'svelte/attachments';
  import type { HTMLAttributes } from 'svelte/elements';
  import CanonColourNotationInput from './canon-colour-notation-input.svelte';
  import CanonRow from './canon-row.svelte';
  import CanonSegmented from './canon-segmented.svelte';
  import CanonSlider from './canon-slider.svelte';
  import CanonSwitch from './canon-switch.svelte';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-colour-controls.css';

  interface Props extends HTMLAttributes<HTMLDivElement> {
    state: CanonColourSolidState;
    /** Title of the notation row; default Any notation. */
    notationTitle?: string;
    /** Leaves out the notation row, for a tool with its own input. */
    hidesNotation?: boolean;
    /** Rows placed between the sliders and the View plane switch. */
    children?: Snippet;
  }

  let {
    state: model,
    notationTitle,
    hidesNotation,
    children: between,
    class: className,
    ...rest
  }: Props = $props();

  const spaceIndex = $derived(solidSpaces.indexOf(model.space));

  const rows = $derived.by(() => {
    const list = channels(model.space);
    const lit = model.slices ? Math.min(model.activeRow, 2) : -1;
    const longest = list.reduce(
      (a, c) => (c.name.length > a.length ? c.name : a),
      '',
    );
    return list.map((channel, index) => ({
      index,
      channel,
      value: model.point[channel.axis]! * channel.scale + channel.offset,
      lit: index === lit,
      longest,
    }));
  });

  function selectSpace(index: number) {
    model.selectSpace(solidSpaces[index]!);
  }

  function slide(index: number, value: number, dragging: boolean) {
    const channel = channels(model.space)[index];
    if (!channel) return;
    if (index < 3) model.activeRow = index;
    const next = [...model.point] as SolidPoint;
    next[channel.axis] = (value - channel.offset) / channel.scale;
    // taps ease, drags follow
    model.setPoint(next, !dragging);
  }

  // CanonSlider has no touch-down callback: a touch picks the row, black shows the whole solid
  function touch(index: number): Attachment<HTMLElement> {
    return (slider) => {
      const down = () => {
        if (index === 3) model.showsWhole = true;
        else model.activeRow = index;
        window.addEventListener('pointerup', up);
        window.addEventListener('pointercancel', up);
      };
      const up = () => {
        model.showsWhole = false;
        window.removeEventListener('pointerup', up);
        window.removeEventListener('pointercancel', up);
      };
      slider.addEventListener('pointerdown', down);
      return () => {
        slider.removeEventListener('pointerdown', down);
        up();
      };
    };
  }
</script>

<!--
  @component
  Rows that drive a CanonColourSolid: any notation beside an eyedropper,
  the space, one slider per channel and the View plane switch. The active
  slider row is the solid's slice. Place it inside a CanonRows.
-->
<div class={['canon-colour-controls', className]} {...rest}>
  {#if !hidesNotation}
    <CanonRow
      title={notationTitle ? notationTitle : 'Any notation'}
      form="stacked"
    >
      {#snippet children(titleId)}
        <CanonColourNotationInput
          colour={model.colour}
          onColour={model.use}
          labelledBy={titleId}
        />
      {/snippet}
    </CanonRow>
  {/if}
  <CanonRow title="Space" form="stacked">
    <CanonSegmented
      items={spaceTitles}
      selected={spaceIndex}
      columns={4}
      onChange={selectSpace}
    />
  </CanonRow>
  {#each rows as row (row.index)}
    <CanonRow
      class={[
        'canon-colour-controls-channel',
        row.lit && 'canon-colour-controls-lit',
      ]}
      title={row.channel.name}
      detail={row.channel.detail}
      form="flush"
      sizingTitle={row.longest}
    >
      {#snippet children(titleId)}
        <CanonSlider
          value={row.value}
          min={row.channel.min}
          max={row.channel.max}
          readout={fixed(row.channel.decimals)}
          labelledBy={titleId}
          onChange={(value, dragging) => slide(row.index, value, dragging)}
          {@attach touch(row.index)}
        />
      {/snippet}
    </CanonRow>
  {/each}
  {@render between?.()}
  <CanonRow title="View plane">
    {#snippet children(titleId)}
      <CanonSwitch
        on={model.viewPlane}
        onChange={(on) => (model.viewPlane = on)}
        aria-labelledby={titleId}
      />
    {/snippet}
  </CanonRow>
</div>
