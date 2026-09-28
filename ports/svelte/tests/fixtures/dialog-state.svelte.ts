import type { CanonSheetEdge } from '../../src/components/canon-sheet.svelte';

export class DialogState {
  open = $state(false);
  edge = $state<CanonSheetEdge>('end');
  closes: string[] = [];
  close = (value: string) => {
    this.open = false;
    this.closes.push(value);
  };
}
