<script lang="ts" module>
  export const pane = 'sidebar';
  export const order = 40;
</script>

<script lang="ts">
  import CanonBigNumberField from '../../src/components/canon-big-number-field.svelte';
  import CanonDecimalField from '../../src/components/canon-decimal-field.svelte';
  import CanonDualList, {
    type CanonDualItem,
  } from '../../src/components/canon-dual-list.svelte';
  import CanonFigure from '../../src/components/canon-figure.svelte';
  import CanonFileCell from '../../src/components/canon-file-cell.svelte';
  import CanonFromTo from '../../src/components/canon-from-to.svelte';
  import CanonGrid from '../../src/components/canon-grid.svelte';
  import CanonHeading from '../../src/components/canon-heading.svelte';
  import CanonLoader from '../../src/components/canon-loader.svelte';
  import CanonMenuCell from '../../src/components/canon-menu-cell.svelte';
  import CanonNumberField from '../../src/components/canon-number-field.svelte';
  import CanonRow from '../../src/components/canon-row.svelte';
  import CanonRows from '../../src/components/canon-rows.svelte';
  import CanonSlider from '../../src/components/canon-slider.svelte';
  import CanonStatus from '../../src/components/canon-status.svelte';
  import CanonSwitch from '../../src/components/canon-switch.svelte';
  import CanonTextArea from '../../src/components/canon-text-area.svelte';
  import CanonTextCell from '../../src/components/canon-text-cell.svelte';
  import '../../../../demo-app/components/gallery/controls.css';

  // ∑CG: gallery, a status shown as a padded row of its own
  //   spec: example warning status text for the status-as-row variant; three to five words, sentence case, no period
  //   sample: "Status as a row"
  const statusRowText = '∑CG';

  const switches = ['Images', 'Files', 'Sound'];
  const longestSwitch = 'Images';
  const whole = (value: number) => String(Math.round(value));
  const rates = ['23.976', '24', '25'];

  let number = $state(200);
  let big = $state('16');
  let seconds = $state(1.5);
  let factor = $state(1);
  let hidden = $state<CanonDualItem[]>([
    { id: 'b', name: 'Beta', caption: 'two' },
    { id: 'd', name: 'Delta', caption: 'four' },
  ]);
  let shown = $state<CanonDualItem[]>([
    { id: 'a', name: 'Alpha', caption: 'one' },
    { id: 'c', name: 'Gamma', caption: 'three' },
  ]);

  const stepBig = (direction: -1 | 1) =>
    (big = String(Math.max(0, (parseInt(big) || 0) + direction)));

  function moveRight(id: string) {
    const item = hidden.find((i) => i.id === id);
    if (!item) return;
    hidden = hidden.filter((i) => i !== item);
    shown = [...shown, item];
  }

  function moveLeft(id: string) {
    const item = shown.find((i) => i.id === id);
    if (!item) return;
    shown = shown.filter((i) => i !== item);
    hidden = [...hidden, item];
  }

  function reorder(id: string, delta: -1 | 1) {
    const index = shown.findIndex((i) => i.id === id);
    const other = index + delta;
    if (index < 0 || other < 0 || other >= shown.length) return;
    const next = [...shown];
    [next[index], next[other]] = [next[other]!, next[index]!];
    shown = next;
  }
</script>

<CanonRows framed>
  <CanonHeading text="Components" />
  <CanonRow title="Switch">
    {#snippet children(titleId)}
      <CanonSwitch on aria-labelledby={titleId} />
    {/snippet}
  </CanonRow>
  <CanonRow title="Number" form="flush">
    {#snippet children(titleId)}
      <CanonNumberField
        value={number}
        max={5000}
        step={50}
        unit="items"
        labelledBy={titleId}
        onChange={(value) => (number = value)}
      />
    {/snippet}
  </CanonRow>
  <CanonRow title="Figure" detail="Follows Number">
    <CanonFigure text={String(number)} unit="px" size={28} />
  </CanonRow>
  <CanonRow title="Slider" form="flush">
    {#snippet children(titleId)}
      <CanonSlider value={0.65} labelledBy={titleId} />
    {/snippet}
  </CanonRow>
  <CanonRow title="Stepped slider" form="flush">
    {#snippet children(titleId)}
      <CanonSlider
        value={80}
        min={1}
        max={100}
        step={1}
        readout={whole}
        labelledBy={titleId}
      />
    {/snippet}
  </CanonRow>
  <CanonRow title="Text" form="flush">
    {#snippet children(titleId)}
      <CanonTextCell placeholder="Trigger" aria-labelledby={titleId} />
    {/snippet}
  </CanonRow>
  <CanonRow title="File" form="flush">
    {#snippet children(titleId)}
      <CanonFileCell labelledBy={titleId} />
    {/snippet}
  </CanonRow>
  <CanonRow title="Image" form="flush">
    {#snippet children(titleId)}
      <CanonFileCell accept="image/*" labelledBy={titleId} />
    {/snippet}
  </CanonRow>
  <CanonGrid>
    {#each switches as title, index (title)}
      <CanonRow {title} sizingTitle={longestSwitch}>
        {#snippet children(id)}
          <CanonSwitch on={index % 2 === 0} aria-labelledby={id} />
        {/snippet}
      </CanonRow>
    {/each}
  </CanonGrid>
  <CanonHeading text="Big number" />
  <CanonBigNumberField
    value={big}
    placeholder="0"
    unit="PX"
    label="Big number"
    onStep={stepBig}
    onInput={(text) => (big = text)}
  />
  <CanonRow title="Decimal" form="flush">
    {#snippet children(titleId)}
      <CanonDecimalField
        value={seconds}
        labelledBy={titleId}
        onChange={(value) => (seconds = value)}
      />
    {/snippet}
  </CanonRow>
  <CanonRow title="Signed, six places" form="flush">
    {#snippet children(titleId)}
      <CanonDecimalField
        value={factor}
        unit="×"
        step={0.001}
        decimals={6}
        signed
        labelledBy={titleId}
        onChange={(value) => (factor = value)}
      />
    {/snippet}
  </CanonRow>
  <CanonTextArea placeholder="Text area" height={120} aria-label="Text area" />
  <CanonRow title="Menu" form="flush">
    {#snippet children(titleId)}
      <CanonMenuCell items={rates} selected={0} labelledBy={titleId} />
    {/snippet}
  </CanonRow>
  <CanonFromTo items={rates} from={0} to={2} />
  <CanonRow title="Status">
    <div class="gallery-inline">
      <CanonStatus text="Granted" tone="ok" />
      <CanonStatus text="Not granted" tone="warn" />
      <CanonStatus text="Stopped" tone="muted" />
    </div>
  </CanonRow>
  <CanonStatus text={statusRowText} tone="warn" row />
  <CanonRow title="Loader">
    <div class="gallery-inline gallery-loaders">
      <CanonLoader />
      <CanonLoader mode="comet" reverse />
      <CanonLoader mode="dot" />
      <CanonLoader mode="twin" />
      <CanonLoader mode="thinking" />
      <CanonLoader cell={4} gap={1} />
    </div>
  </CanonRow>
  <CanonRow title="Dual list" form="stacked">
    <CanonDualList
      left={hidden}
      right={shown}
      leftTitle="Hidden"
      rightTitle="Shown"
      listHeight={140}
      onMoveRight={moveRight}
      onMoveLeft={moveLeft}
      onReorder={reorder}
    />
  </CanonRow>
</CanonRows>
