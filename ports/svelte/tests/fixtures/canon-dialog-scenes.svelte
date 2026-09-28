<script lang="ts">
  import CanonButton from '../../src/components/canon-button.svelte';
  import CanonDialog from '../../src/components/canon-dialog.svelte';
  import type { DialogState } from './dialog-state.svelte.ts';

  let {
    scene,
    state: plain,
    alert,
    held,
  }: {
    scene: 'footer' | 'backdrop' | 'top';
    state: DialogState;
    alert?: DialogState;
    held?: DialogState;
  } = $props();
</script>

{#if scene === 'footer'}
  <CanonButton id="opener" text="Open" onClick={() => (plain.open = true)} />
  <CanonDialog
    open={plain.open}
    title="Export"
    message="Text"
    onClose={plain.close}
  >
    <p class="row">Body</p>
    {#snippet footer(close)}
      <CanonButton text="Cancel" onClick={() => close('cancel')} />
      <CanonButton text="Save" onClick={() => close('save')} />
    {/snippet}
  </CanonDialog>
{:else if scene === 'backdrop' && alert && held}
  <CanonDialog open={plain.open} onClose={plain.close}>
    <p>Plain</p>
  </CanonDialog>
  <CanonDialog open={alert.open} alert onClose={alert.close}>
    <p>Alert</p>
  </CanonDialog>
  <CanonDialog open={held.open} dismissable={false} onClose={held.close}>
    <p>Held</p>
  </CanonDialog>
{:else}
  <div
    class="floating"
    style="position: fixed; inset: auto 0 0; block-size: 60px; z-index: 2147483647"
  >
    Footer
  </div>
  <CanonDialog open={plain.open} onClose={plain.close}>
    <p>Body</p>
  </CanonDialog>
{/if}
