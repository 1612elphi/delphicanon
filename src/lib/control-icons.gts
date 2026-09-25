import type { TOC } from '@ember/component/template-only';

// lucide-static 1.48 paths (ISC); the controls draw these themselves
export const Minus: TOC<{ Args: object }> = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><path d="M5 12h14" /></svg>
</template>;

export const Plus: TOC<{ Args: object }> = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><path d="M5 12h14" /><path d="M12 5v14" /></svg>
</template>;

export const ChevronsUpDown: TOC<{ Args: object }> = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><path d="m7 15 5 5 5-5" /><path d="m7 9 5-5 5 5" /></svg>
</template>;

export const ArrowRight: TOC<{ Args: object }> = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><path d="M5 12h14" /><path d="m12 5 7 7-7 7" /></svg>
</template>;

export const Folder: TOC<{ Args: object }> = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><path
      d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z"
    /></svg>
</template>;

export const Clipboard: TOC<{ Args: object }> = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><rect width="8" height="4" x="8" y="2" rx="1" ry="1" /><path
      d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"
    /></svg>
</template>;

export const Picture: TOC<{ Args: object }> = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><rect width="18" height="18" x="3" y="3" rx="2" ry="2" /><circle
      cx="9"
      cy="9"
      r="2"
    /><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21" /></svg>
</template>;
