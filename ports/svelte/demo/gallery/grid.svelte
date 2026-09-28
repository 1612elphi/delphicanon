<script lang="ts" module>
  export const pane = 'sidebar';
  export const order = 30;
</script>

<script lang="ts">
  import CanonButton from '../../src/components/canon-button.svelte';
  import CanonGrid from '../../src/components/canon-grid.svelte';
  import CanonHeading from '../../src/components/canon-heading.svelte';
  import CanonRow from '../../src/components/canon-row.svelte';
  import CanonRows from '../../src/components/canon-rows.svelte';
  import { icon } from '../icon.ts';
  import moveHorizontal from 'lucide-static/icons/move-horizontal.svg?raw';
  import zoomIn from 'lucide-static/icons/zoom-in.svg?raw';
  import zoomOut from 'lucide-static/icons/zoom-out.svg?raw';
</script>

<CanonRows framed>
  <CanonHeading text="Grid" />
  <CanonRow title="Actions" form="stacked">
    <CanonGrid>
      <CanonButton text="Cancel" />
      <CanonButton text="Apply" kind="primary" />
    </CanonGrid>
  </CanonRow>
  <CanonRow title="Inline actions" form="flush">
    <CanonGrid>
      <CanonButton text="Cancel" kind="cell" />
      <CanonButton text="Apply" kind="cell" />
      <CanonButton text="Disabled" kind="cell" disabled />
    </CanonGrid>
  </CanonRow>
  <CanonRow title="Icon actions" detail="3.60 – 6.00" form="flush">
    <CanonGrid>
      <CanonButton kind="cell" icon={icon(zoomOut)} label="Zoom out" />
      <CanonButton kind="cell" icon={icon(zoomIn)} label="Zoom in" />
      <CanonButton kind="cell" icon={icon(moveHorizontal)} label="Fit width" />
    </CanonGrid>
  </CanonRow>
</CanonRows>
