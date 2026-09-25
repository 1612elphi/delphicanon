import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { modifier } from 'ember-modifier';
import CanonBar from './canon-bar.gts';
import CanonGrid from './canon-grid.gts';
import '../styles/tokens.css';
import './canon-tiles.css';

export interface CanonTile {
  label: string;
  value: string;
  /** Share of a level bar along the tile's bottom edge, 0 to 1; none draws no bar. */
  level?: number;
}

export interface CanonTilesSignature {
  Args: { items: CanonTile[] };
  Element: HTMLDivElement;
}

/** Least width of a tile; the grid never goes below two columns. */
export const tileWidth = 168;

/**
 * Read-only values as a hairline grid of tiles, label over value. As many
 * columns as fit; a short last row stretches its last tile.
 */
export default class CanonTiles extends Component<CanonTilesSignature> {
  @tracked columns = 2;

  measure = modifier((element: HTMLElement) => {
    let frame = 0;
    // a new column count changes the height; set it next frame, outside this observation
    const observer = new ResizeObserver(([entry]) => {
      const width = entry?.contentRect.width ?? 0;
      const columns = Math.max(2, Math.floor(width / tileWidth));
      cancelAnimationFrame(frame);
      if (columns !== this.columns)
        frame = requestAnimationFrame(() => (this.columns = columns));
    });
    observer.observe(element);
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
    };
  });

  <template>
    <div class="canon-tiles" {{this.measure}} ...attributes>
      <CanonGrid @columns={{this.columns}}>
        {{#each @items as |item|}}
          <div class="canon-tiles-tile">
            <span class="canon-tiles-label">{{item.label}}</span>
            <span class="canon-tiles-value">{{item.value}}</span>
            {{#if (isLevel item.level)}}
              <CanonBar class="canon-tiles-level" @share={{item.level}} />
            {{/if}}
          </div>
        {{/each}}
      </CanonGrid>
    </div>
  </template>
}

function isLevel(level: number | undefined): level is number {
  return level !== undefined;
}
