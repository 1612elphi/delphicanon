import { h, type FunctionalComponent } from 'vue';
import CanonIcon from '../components/canon-icon.vue';
import {
  arrowRight,
  chevronsUpDown,
  clipboard,
  folder,
  image,
  minus,
  pipette,
  plus,
} from './lucide.ts';

const icon =
  (svg: string): FunctionalComponent =>
  () =>
    h(CanonIcon, { svg });

export const Minus = icon(minus);
export const Plus = icon(plus);
export const ChevronsUpDown = icon(chevronsUpDown);
export const ArrowRight = icon(arrowRight);
export const Folder = icon(folder);
export const Clipboard = icon(clipboard);
export const Picture = icon(image);
export const Pipette = icon(pipette);
