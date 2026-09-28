<script lang="ts">
  import type { HTMLAttributes } from 'svelte/elements';
  import '@canon/styles/tokens.css';
  import '@canon/components/canon-heading.css';

  interface Props extends HTMLAttributes<HTMLHeadingElement> {
    text: string;
  }

  let { text, class: className, ...rest }: Props = $props();
</script>

<h3 class={['canon-heading', className]} {...rest}>{text}</h3>
