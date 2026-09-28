<script lang="ts">
/** Hands a text file to the system share sheet, or downloads it where there is none. */
export async function shareText(text: string, fileName: string) {
  const file = new File([text], fileName, { type: 'text/plain' });
  if (typeof navigator.share === 'function') {
    const data = navigator.canShare?.({ files: [file] })
      ? { files: [file] }
      : { text };
    try {
      await navigator.share(data);
    } catch {
      // dismissed
    }
    return;
  }
  const url = URL.createObjectURL(file);
  const link = document.createElement('a');
  link.href = url;
  link.download = fileName;
  link.click();
  URL.revokeObjectURL(url);
}
</script>

<script setup lang="ts">
import { computed, h, type FunctionalComponent } from 'vue';
import { toast } from '../lib/toast-store.ts';
import { copy as copyIcon, share as shareIcon } from '../lib/lucide.ts';
import CanonButton from './canon-button.vue';
import CanonEmptyRow from './canon-empty-row.vue';
import CanonGrid from './canon-grid.vue';
import CanonHeading from './canon-heading.vue';
import CanonIcon from './canon-icon.vue';
import CanonRows from './canon-rows.vue';
import '@canon/styles/tokens.css';
import '@canon/components/canon-text-output.css';

const props = defineProps<{
  text: string;
  heading: string;
  /** Name of the file Share hands over. */
  fileName: string;
  /** The output is still to come; the empty row stays away. */
  busy?: boolean;
  /** Shown when the output is blank; default None. */
  empty?: string;
}>();

defineSlots<{
  /** The output with its marks, shown in place of `text`. */
  default?: () => unknown;
  /** Rows between the text and the actions. */
  extra?: () => unknown;
}>();

const CopyIcon: FunctionalComponent = () => h(CanonIcon, { svg: copyIcon });
const ShareIcon: FunctionalComponent = () => h(CanonIcon, { svg: shareIcon });

const blank = computed(() => props.text.trim() === '');

function copy() {
  toast.write(props.text).catch(() => undefined);
}

const share = () => shareText(props.text, props.fileName);
</script>

<!--
  The output block of a text tool: a heading, the converted text, and Share
  beside Copy.
-->
<template>
  <CanonRows class="canon-text-output" :framed="true">
    <CanonHeading :text="heading" />
    <div v-if="!blank" class="canon-text-output-text">
      <slot>{{ text }}</slot>
    </div>
    <CanonEmptyRow v-if="blank && !busy" :text="empty || 'None'" />
    <slot name="extra" />
    <CanonGrid>
      <CanonButton
        text="Share"
        :icon="ShareIcon"
        :disabled="blank"
        :on-click="share"
      />
      <CanonButton
        text="Copy"
        :icon="CopyIcon"
        icon-style="oversized"
        kind="primary"
        :disabled="blank"
        :flashes-copied="true"
        :on-click="copy"
      />
    </CanonGrid>
  </CanonRows>
</template>
