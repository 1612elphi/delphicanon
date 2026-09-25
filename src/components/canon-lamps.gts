import type { TOC } from '@ember/component/template-only';
import { modifier } from 'ember-modifier';
import '../styles/tokens.css';
import './canon-lamps.css';
import {
  CircleDot as circleDot,
  Pause as pause,
  Play as play,
  Repeat as repeat,
} from 'lucide-static';
import CanonIcon from './canon-icon.gts';

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

const Play = <template><CanonIcon @svg={{play}} /></template>;
const Pause = <template><CanonIcon @svg={{pause}} /></template>;
const Loop = <template><CanonIcon @svg={{repeat}} /></template>;
const Record = <template><CanonIcon @svg={{circleDot}} /></template>;

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
