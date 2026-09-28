<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { HTMLAttributes } from 'svelte/elements';
  import CanonButton from './canon-button.svelte';
  import CanonGrid from './canon-grid.svelte';
  import '@canon/styles/tokens.css';

  interface Props extends Omit<HTMLAttributes<HTMLDivElement>, 'children'> {
    /** Titles; with `icons`, what assistive technology reads. */
    items: string[];
    /** Cells that show a symbol instead of the title, one per item. */
    icons?: Snippet[];
    selected?: number;
    columns?: number;
    boxed?: boolean;
    disabled?: boolean;
    /** Indices of choices that cannot be taken now; they stay, greyed. */
    disabledIndices?: number[];
    onChange?: (index: number) => void;
  }

  let {
    items,
    icons,
    selected: given,
    columns,
    boxed,
    disabled,
    disabledIndices,
    onChange,
    class: className,
    ...rest
  }: Props = $props();

  // a pick holds until the selected prop changes
  let picked = $state<{ index: number; over: number | undefined }>();

  const selected = $derived(
    picked && picked.over === given ? picked.index : (given ?? 0),
  );

  const cells = $derived(
    items.map((title, index) => ({
      index,
      title,
      icon: icons?.[index],
      selected: index === selected,
      disabled:
        disabled === true || (disabledIndices?.includes(index) ?? false),
    })),
  );

  function pick(index: number) {
    if (index === selected) return;
    picked = { index, over: given };
    onChange?.(index);
  }
</script>

<!-- @component Single selection from a flush grid of cells. -->
<CanonGrid
  class={['canon-segmented', className]}
  role="radiogroup"
  {columns}
  {boxed}
  {...rest}
>
  {#each cells as cell (cell.index)}
    <CanonButton
      role="radio"
      aria-checked={cell.selected ? 'true' : 'false'}
      kind="segment"
      text={cell.icon ? '' : cell.title}
      icon={cell.icon}
      label={cell.title}
      selected={cell.selected}
      disabled={cell.disabled}
      onClick={() => pick(cell.index)}
    />
  {/each}
</CanonGrid>
