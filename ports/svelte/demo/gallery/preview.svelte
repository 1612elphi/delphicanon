<script lang="ts" module>
  export const pane = 'main';
  export const order = 5;
</script>

<script lang="ts">
  import CanonPreviewPanel from '../../src/components/canon-preview-panel.svelte';
  import '../../../../demo-app/components/gallery/display.css';
</script>

<CanonPreviewPanel caption="Preview" detail="1600 x 900">
  <div class="gallery-swatch"></div>
</CanonPreviewPanel>
