<script lang="ts" module>
  import type { CanonDialogProps } from './canon-dialog.svelte';

  export type CanonSheetEdge = 'start' | 'end' | 'top' | 'bottom';

  export interface CanonSheetProps extends Omit<
    CanonDialogProps,
    'alert' | 'keyframes'
  > {
    /** The edge it slides in from; start and end follow the writing direction. Default bottom. */
    edge?: CanonSheetEdge;
  }

  const offsets: Record<CanonSheetEdge, string> = {
    top: 'translateY(-100%)',
    bottom: 'translateY(100%)',
    start: 'translateX(-100%)',
    end: 'translateX(100%)',
  };
</script>

<script lang="ts">
  import CanonDialog from './canon-dialog.svelte';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-sheet.css';

  let {
    edge = 'bottom',
    class: className,
    ...rest
  }: CanonSheetProps = $props();

  function keyframes(dialog: HTMLDialogElement): Keyframe[] {
    let from = edge;
    if (getComputedStyle(dialog).direction === 'rtl')
      from = from === 'start' ? 'end' : from === 'end' ? 'start' : from;
    return [{ transform: offsets[from] }, { transform: 'none' }];
  }
</script>

<!--
  @component
  CanonDialog anchored to an edge of the window, sliding in from it: the
  iOS sheet at the bottom, a side panel at start or end.
-->
<CanonDialog
  class={['canon-sheet', `canon-sheet--${edge}`, className]}
  {keyframes}
  {...rest}
/>
