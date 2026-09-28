import { useLayoutEffect, useRef } from 'react';

/**
 * A ref for an uncontrolled field whose text follows `value` when `value`
 * changes, as a Glimmer `value={{...}}` binding does: typing the consumer
 * does not echo back stays in the field. `keepWhileFocused` leaves a focused
 * field alone, so an echo cannot replace the text being typed.
 */
export function useShownValue<T extends HTMLInputElement | HTMLTextAreaElement>(
  value: string | undefined,
  keepWhileFocused = false,
) {
  const ref = useRef<T>(null);
  useLayoutEffect(() => {
    const field = ref.current;
    if (!field || (keepWhileFocused && document.activeElement === field))
      return;
    if (field.value !== (value ?? '')) field.value = value ?? '';
  }, [value, keepWhileFocused]);
  return ref;
}
