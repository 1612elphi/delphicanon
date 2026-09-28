<script lang="ts">
import { shallowReactive } from 'vue';
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
 * The constructor returns a shallow reactive object.
 */
export class CanonColourSolidState {
  space: SolidSpace;
  point: SolidPoint;
  /** The last change of `point` eases, as after a tap on a slider track; drags and picks follow at once. */
  animated = false;
  /** The slider row that is the solid's slice; row 3, CMYK's black, never slices. */
  activeRow: number;
  /** Slices along the active row's channel; false cuts the solid away instead. */
  slices = true;
  /** The View plane switch. */
  viewPlane = false;
  /** True while CMYK's black changes. */
  showsWhole = false;
  /** Eases to `colour`. */
  readonly use: (colour: Rgb) => void;
  /** The solid's change callback. */
  readonly pick: (point: SolidPoint) => void;

  constructor({
    space = 'hsl',
    colour = [0.12, 0.4, 0.15],
    activeRow = 0,
  }: { space?: SolidSpace; colour?: Rgb; activeRow?: number } = {}) {
    this.space = space;
    this.point = pointFor(space, colour);
    this.activeRow = activeRow;
    // use and pick are passed detached, so they write through the proxy
    const state = shallowReactive(this) as CanonColourSolidState;
    this.use = (colour) => state.setPoint(pointFor(state.space, colour), true);
    this.pick = (point) => state.setPoint(point, false);
    return state;
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

  selectSpace(space: SolidSpace) {
    this.space = space;
  }
}

const spaceTitles = solidSpaces.map((space) => spaceNames[space]);
const fixed = (decimals: number) => (value: number) => value.toFixed(decimals);
</script>

<script setup lang="ts">
/* eslint-disable vue/no-mutating-props -- the state is shared by design: the solid and the controls both write it */
import { computed } from 'vue';
import { elementDirective } from '../lib/directive.ts';
import CanonColourNotationInput from './canon-colour-notation-input.vue';
import CanonRow from './canon-row.vue';
import CanonSegmented from './canon-segmented.vue';
import CanonSlider from './canon-slider.vue';
import CanonSwitch from './canon-switch.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-colour-controls.css';

const props = defineProps<{
  state: CanonColourSolidState;
  /** Title of the notation row; default Any notation. */
  notationTitle?: string;
  /** Leaves out the notation row, for a tool with its own input. */
  hidesNotation?: boolean;
}>();

defineSlots<{
  /** Rows placed between the sliders and the View plane switch. */
  default?: () => unknown;
}>();

const spaceIndex = computed(() => solidSpaces.indexOf(props.state.space));

const rows = computed(() => {
  const { state } = props;
  const list = channels(state.space);
  const lit = state.slices ? Math.min(state.activeRow, 2) : -1;
  const longest = list.reduce(
    (a, c) => (c.name.length > a.length ? c.name : a),
    '',
  );
  return list.map((channel, index) => ({
    index,
    channel,
    value: state.point[channel.axis]! * channel.scale + channel.offset,
    lit: index === lit,
    longest,
  }));
});

function selectSpace(index: number) {
  props.state.selectSpace(solidSpaces[index]!);
}

function slide(index: number, value: number, dragging: boolean) {
  const { state } = props;
  const channel = channels(state.space)[index];
  if (!channel) return;
  if (index < 3) state.activeRow = index;
  const next = [...state.point] as SolidPoint;
  next[channel.axis] = (value - channel.offset) / channel.scale;
  // taps ease, drags follow
  state.setPoint(next, !dragging);
}

// CanonSlider has no touch-down callback: a touch picks the row, black shows the whole solid
const vTouch = elementDirective<number>((slider, index) => {
  const down = () => {
    if (index() === 3) props.state.showsWhole = true;
    else props.state.activeRow = index();
    window.addEventListener('pointerup', up);
    window.addEventListener('pointercancel', up);
  };
  const up = () => {
    props.state.showsWhole = false;
    window.removeEventListener('pointerup', up);
    window.removeEventListener('pointercancel', up);
  };
  slider.addEventListener('pointerdown', down);
  return () => {
    slider.removeEventListener('pointerdown', down);
    up();
  };
});

function toggleViewPlane(on: boolean) {
  props.state.viewPlane = on;
}
</script>

<!--
  Rows that drive a CanonColourSolid: any notation beside an eyedropper,
  the space, one slider per channel and the View plane switch. The active
  slider row is the solid's slice. Place it inside a CanonRows.
-->
<template>
  <div class="canon-colour-controls">
    <CanonRow
      v-if="!hidesNotation"
      v-slot="{ titleId }"
      :title="notationTitle ? notationTitle : 'Any notation'"
      form="stacked"
    >
      <CanonColourNotationInput
        :colour="state.colour"
        :on-colour="state.use"
        :labelled-by="titleId"
      />
    </CanonRow>
    <CanonRow title="Space" form="stacked">
      <CanonSegmented
        :items="spaceTitles"
        :selected="spaceIndex"
        :columns="4"
        :on-change="selectSpace"
      />
    </CanonRow>
    <CanonRow
      v-for="row in rows"
      :key="row.index"
      v-slot="{ titleId }"
      class="canon-colour-controls-channel"
      :class="{ 'canon-colour-controls-lit': row.lit }"
      :title="row.channel.name"
      :detail="row.channel.detail"
      form="flush"
      :sizing-title="row.longest"
    >
      <CanonSlider
        v-touch="row.index"
        :value="row.value"
        :min="row.channel.min"
        :max="row.channel.max"
        :readout="fixed(row.channel.decimals)"
        :labelled-by="titleId"
        :on-change="
          (value: number, dragging: boolean) =>
            slide(row.index, value, dragging)
        "
      />
    </CanonRow>
    <slot />
    <CanonRow v-slot="{ titleId }" title="View plane">
      <CanonSwitch
        :on="state.viewPlane"
        :on-change="toggleViewPlane"
        :aria-labelledby="titleId"
      />
    </CanonRow>
  </div>
</template>
