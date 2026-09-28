import { h, type FunctionalComponent } from 'vue';

/** A stand-in icon. */
const Dot: FunctionalComponent = () =>
  h('svg', { viewBox: '0 0 24 24' }, [h('circle', { cx: 12, cy: 12, r: 6 })]);

export default Dot;
