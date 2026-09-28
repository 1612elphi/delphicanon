<script lang="ts" module>
  export const pane = 'sidebar';
  export const order = 10;
</script>

<script lang="ts">
  import CanonBar from '../../src/components/canon-bar.svelte';
  import CanonEmptyRow from '../../src/components/canon-empty-row.svelte';
  import CanonHeading from '../../src/components/canon-heading.svelte';
  import CanonRow from '../../src/components/canon-row.svelte';
  import CanonRows from '../../src/components/canon-rows.svelte';
  import { icon } from '../icon.ts';
  import bug from 'lucide-static/icons/bug.svg?raw';

  // ∑CG: gallery, caption under the "Detail and icon" row title
  //   spec: shows what a row's detail line looks like; plain, lowercase after the first word, about 25 characters
  //   sample: "Caption under the title"
  const detailCaption = '∑CG';
</script>

<CanonRows framed>
  <CanonHeading text="Rows" />
  <CanonRow title="Plain"
    ><CanonBar class="gallery-bar" share={0.65} /></CanonRow
  >
  <CanonRow title="Detail and icon" icon={icon(bug)} detail={detailCaption}
    ><CanonBar class="gallery-bar" share={0.3} /></CanonRow
  >
  <CanonRow title="No control" />
  <CanonEmptyRow text="Nothing here" />
</CanonRows>
