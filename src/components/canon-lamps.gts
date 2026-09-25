import type { TOC } from '@ember/component/template-only';
import { modifier } from 'ember-modifier';
import '../styles/tokens.css';
import './canon-lamps.css';

export type CanonLamp = 'play' | 'pause' | 'loop' | 'record';

export interface CanonLampsSignature {
  Args: {
    /** Which lamps; every one is always present. Default play, pause, loop. */
    lamps?: readonly CanonLamp[];
    lit?: readonly CanonLamp[];
    /** A count per lamp; each change turns that lamp off for a split second. */
    flashes?: Partial<Record<CanonLamp, number>>;
  };
  Element: HTMLSpanElement;
}

export const transportLamps: CanonLamp[] = ['play', 'pause', 'loop'];

/** Milliseconds a lamp stays unlit when it blinks. */
export const lampBlinkMs = 120;

const blink = modifier(
  (element: HTMLElement, [count]: [number | undefined]) => {
    const last = element.dataset['flashes'];
    element.dataset['flashes'] = String(count ?? 0);
    if (last === undefined || last === String(count ?? 0)) return;
    element.classList.add('canon-lamps-lamp--blink');
    const timer = window.setTimeout(
      () => element.classList.remove('canon-lamps-lamp--blink'),
      lampBlinkMs,
    );
    return () => window.clearTimeout(timer);
  },
);

const Play = <template>
  <svg viewBox="0 0 24 24"><path
      d="M6 3.5v17a1 1 0 0 0 1.5.86l14-8.5a1 1 0 0 0 0-1.72l-14-8.5A1 1 0 0 0 6 3.5Z"
    /></svg>
</template>;
const Pause = <template>
  <svg viewBox="0 0 24 24"><rect
      x="5"
      y="3"
      width="5"
      height="18"
      rx="1"
    /><rect x="14" y="3" width="5" height="18" rx="1" /></svg>
</template>;
const Loop = <template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2.75"
    stroke-linecap="round"
    stroke-linejoin="round"
  ><path d="m17 2 4 4-4 4" /><path d="M3 11v-1a4 4 0 0 1 4-4h14" /><path
      d="m7 22-4-4 4-4"
    /><path d="M21 13v1a4 4 0 0 1-4 4H3" /></svg>
</template>;
const Record = <template>
  <svg viewBox="0 0 24 24"><circle
      cx="12"
      cy="12"
      r="9.5"
      fill="none"
      stroke="currentColor"
      stroke-width="2.25"
    /><circle cx="12" cy="12" r="5" /></svg>
</template>;

const icons = { play: Play, pause: Pause, loop: Loop, record: Record };

function has(list: readonly CanonLamp[] | undefined, lamp: CanonLamp) {
  return list?.includes(lamp) ?? false;
}

function icon(lamp: CanonLamp) {
  return icons[lamp];
}

function count(
  flashes: CanonLampsSignature['Args']['flashes'],
  lamp: CanonLamp,
) {
  return flashes?.[lamp];
}

/** Transport lamps: every icon is always present, lit while its state holds. Record lights red. */
const CanonLamps: TOC<CanonLampsSignature> = <template>
  <span class="canon-lamps" aria-hidden="true" ...attributes>
    {{#each (if @lamps @lamps transportLamps) as |lamp|}}
      <span
        class="canon-lamps-lamp canon-lamps-lamp--{{lamp}}
          {{if (has @lit lamp) 'canon-lamps-lamp--lit'}}"
        {{blink (count @flashes lamp)}}
      >{{#let (icon lamp) as |Icon|}}<Icon />{{/let}}</span>
    {{/each}}
  </span>
</template>;

export default CanonLamps;
