import type { ComponentType } from 'react';

interface GalleryGroup {
  default: ComponentType;
  pane: 'sidebar' | 'main';
  order: number;
}

export const groups = Object.entries(
  import.meta.glob<GalleryGroup>('./gallery/*.tsx', { eager: true }),
)
  .sort(([a, x], [b, y]) => x.order - y.order || a.localeCompare(b))
  .map(([name, group]) => ({ name, ...group }));
