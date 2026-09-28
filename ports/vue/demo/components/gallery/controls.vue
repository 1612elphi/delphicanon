<script lang="ts">
export const pane = 'sidebar';
export const order = 40;
</script>

<script setup lang="ts">
import { computed, ref } from 'vue';
import CanonBigNumberField from '../../../src/components/canon-big-number-field.vue';
import CanonDecimalField from '../../../src/components/canon-decimal-field.vue';
import CanonDualList, {
  type CanonDualItem,
} from '../../../src/components/canon-dual-list.vue';
import CanonFigure from '../../../src/components/canon-figure.vue';
import CanonFileCell from '../../../src/components/canon-file-cell.vue';
import CanonFromTo from '../../../src/components/canon-from-to.vue';
import CanonGrid from '../../../src/components/canon-grid.vue';
import CanonHeading from '../../../src/components/canon-heading.vue';
import CanonLoader from '../../../src/components/canon-loader.vue';
import CanonMenuCell from '../../../src/components/canon-menu-cell.vue';
import CanonNumberField from '../../../src/components/canon-number-field.vue';
import CanonRow from '../../../src/components/canon-row.vue';
import CanonRows from '../../../src/components/canon-rows.vue';
import CanonSlider from '../../../src/components/canon-slider.vue';
import CanonStatus from '../../../src/components/canon-status.vue';
import CanonSwitch from '../../../src/components/canon-switch.vue';
import CanonTextArea from '../../../src/components/canon-text-area.vue';
import CanonTextCell from '../../../src/components/canon-text-cell.vue';
import '../../../../../demo-app/components/gallery/controls.css';

// ∑CG: gallery, a status shown as a padded row of its own
//   spec: example warning status text for the status-as-row variant; three to five words, sentence case, no period
//   sample: "Status as a row"
const statusRowText = '∑CG';

const switches = ['Images', 'Files', 'Sound'];
const longestSwitch = 'Images';
const whole = (value: number) => String(Math.round(value));
const rates = ['23.976', '24', '25'];

const number = ref(200);
const big = ref('16');
const seconds = ref(1.5);
const factor = ref(1);
const hidden = ref<CanonDualItem[]>([
  { id: 'b', name: 'Beta', caption: 'two' },
  { id: 'd', name: 'Delta', caption: 'four' },
]);
const shown = ref<CanonDualItem[]>([
  { id: 'a', name: 'Alpha', caption: 'one' },
  { id: 'c', name: 'Gamma', caption: 'three' },
]);

const figure = computed(() => String(number.value));

const setNumber = (value: number) => (number.value = value);
const setBig = (text: string) => (big.value = text);
const stepBig = (direction: -1 | 1) =>
  (big.value = String(Math.max(0, (parseInt(big.value) || 0) + direction)));
const setSeconds = (value: number) => (seconds.value = value);
const setFactor = (value: number) => (factor.value = value);

function moveRight(id: string) {
  const item = hidden.value.find((i) => i.id === id);
  if (!item) return;
  hidden.value = hidden.value.filter((i) => i !== item);
  shown.value = [...shown.value, item];
}

function moveLeft(id: string) {
  const item = shown.value.find((i) => i.id === id);
  if (!item) return;
  shown.value = shown.value.filter((i) => i !== item);
  hidden.value = [...hidden.value, item];
}

function reorder(id: string, delta: -1 | 1) {
  const index = shown.value.findIndex((i) => i.id === id);
  const other = index + delta;
  if (index < 0 || other < 0 || other >= shown.value.length) return;
  const next = [...shown.value];
  [next[index], next[other]] = [next[other]!, next[index]!];
  shown.value = next;
}
</script>

<template>
  <CanonRows :framed="true">
    <CanonHeading text="Components" />
    <CanonRow v-slot="{ titleId }" title="Switch">
      <CanonSwitch :on="true" :aria-labelledby="titleId" />
    </CanonRow>
    <CanonRow v-slot="{ titleId }" title="Number" form="flush">
      <CanonNumberField
        :value="number"
        :max="5000"
        :step="50"
        unit="items"
        :labelled-by="titleId"
        :on-change="setNumber"
      />
    </CanonRow>
    <CanonRow title="Figure" detail="Follows Number">
      <CanonFigure :text="figure" unit="px" :size="28" />
    </CanonRow>
    <CanonRow v-slot="{ titleId }" title="Slider" form="flush">
      <CanonSlider :value="0.65" :labelled-by="titleId" />
    </CanonRow>
    <CanonRow v-slot="{ titleId }" title="Stepped slider" form="flush">
      <CanonSlider
        :value="80"
        :min="1"
        :max="100"
        :step="1"
        :readout="whole"
        :labelled-by="titleId"
      />
    </CanonRow>
    <CanonRow v-slot="{ titleId }" title="Text" form="flush">
      <CanonTextCell placeholder="Trigger" :aria-labelledby="titleId" />
    </CanonRow>
    <CanonRow v-slot="{ titleId }" title="File" form="flush">
      <CanonFileCell :labelled-by="titleId" />
    </CanonRow>
    <CanonRow v-slot="{ titleId }" title="Image" form="flush">
      <CanonFileCell accept="image/*" :labelled-by="titleId" />
    </CanonRow>
    <CanonGrid>
      <CanonRow
        v-for="(title, index) in switches"
        :key="title"
        v-slot="{ titleId }"
        :title="title"
        :sizing-title="longestSwitch"
      >
        <CanonSwitch :on="index % 2 === 0" :aria-labelledby="titleId" />
      </CanonRow>
    </CanonGrid>
    <CanonHeading text="Big number" />
    <CanonBigNumberField
      :value="big"
      placeholder="0"
      unit="PX"
      label="Big number"
      :on-step="stepBig"
      :on-input="setBig"
    />
    <CanonRow v-slot="{ titleId }" title="Decimal" form="flush">
      <CanonDecimalField
        :value="seconds"
        :labelled-by="titleId"
        :on-change="setSeconds"
      />
    </CanonRow>
    <CanonRow v-slot="{ titleId }" title="Signed, six places" form="flush">
      <CanonDecimalField
        :value="factor"
        unit="×"
        :step="0.001"
        :decimals="6"
        :signed="true"
        :labelled-by="titleId"
        :on-change="setFactor"
      />
    </CanonRow>
    <CanonTextArea
      placeholder="Text area"
      :height="120"
      aria-label="Text area"
    />
    <CanonRow v-slot="{ titleId }" title="Menu" form="flush">
      <CanonMenuCell :items="rates" :selected="0" :labelled-by="titleId" />
    </CanonRow>
    <CanonFromTo :items="rates" :from="0" :to="2" />
    <CanonRow title="Status">
      <div class="gallery-inline">
        <CanonStatus text="Granted" tone="ok" />
        <CanonStatus text="Not granted" tone="warn" />
        <CanonStatus text="Stopped" tone="muted" />
      </div>
    </CanonRow>
    <CanonStatus :text="statusRowText" tone="warn" :row="true" />
    <CanonRow title="Loader">
      <div class="gallery-inline gallery-loaders">
        <CanonLoader />
        <CanonLoader mode="comet" :reverse="true" />
        <CanonLoader mode="dot" />
        <CanonLoader mode="twin" />
        <CanonLoader mode="thinking" />
        <CanonLoader :cell="4" :gap="1" />
      </div>
    </CanonRow>
    <CanonRow title="Dual list" form="stacked">
      <CanonDualList
        :left="hidden"
        :right="shown"
        left-title="Hidden"
        right-title="Shown"
        :list-height="140"
        :on-move-right="moveRight"
        :on-move-left="moveLeft"
        :on-reorder="reorder"
      />
    </CanonRow>
  </CanonRows>
</template>
