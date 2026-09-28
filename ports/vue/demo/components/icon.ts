import { h, type FunctionalComponent } from 'vue';
import CanonIcon from '../../src/components/canon-icon.vue';

const made = new Map<string, FunctionalComponent>();

/** A gallery icon from a lucide SVG imported with `?raw`; one component per SVG. */
export function icon(svg: string): FunctionalComponent {
  let component = made.get(svg);
  if (!component) {
    component = () => h(CanonIcon, { svg });
    made.set(svg, component);
  }
  return component;
}
