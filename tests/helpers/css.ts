import { htmlSafe } from '@ember/template';

/** An inline style for a test wrapper, so sizes and container queries can be set. */
export const css = (style: string) => htmlSafe(style);
