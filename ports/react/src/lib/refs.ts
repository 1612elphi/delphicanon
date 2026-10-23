import {
	useLayoutEffect,
	useMemo,
	useRef,
	type Ref,
	type RefCallback,
	type RefObject,
} from 'react';

type Cleanup = void | (() => void);

/** One ref callback that sets every ref and runs every cleanup. */
export function useRefs<T>(
	...refs: (Ref<T> | ((element: T) => Cleanup) | undefined)[]
): RefCallback<T> {
	return useMemo(
		() => (element: T) => {
			const cleanups = refs.map((ref) => {
				if (typeof ref === 'function')
					return ref(element);
				if (ref) ref.current = element;
			});
			return () =>
				cleanups.forEach((cleanup, i) => {
					if (typeof cleanup === 'function')
						return cleanup();
					const ref = refs[i];
					if (typeof ref === 'function')
						ref(null as T);
					else if (ref) ref.current = null;
				});
		},
		// eslint-disable-next-line react-hooks/exhaustive-deps, react-hooks/use-memo
		refs,
	);
}

/** A ref that holds the value of the last commit, for listeners set up once. */
export function useLatest<T>(value: T): RefObject<T> {
	const latest = useRef(value);
	useLayoutEffect(() => {
		latest.current = value;
	});
	return latest;
}
