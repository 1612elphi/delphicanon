import { useCallback, useMemo, type HTMLAttributes, type Ref } from 'react';
import { MathMorph } from '@canon/lib/math/draw.ts';
import { capture } from '@canon/lib/motion.ts';
import { layoutRow, type Row } from '@canon/lib/math/expression.ts';
import { canvasMetrics } from '@canon/lib/math/measure.ts';
import { keyed } from '@canon/lib/math/morph.ts';
import { Typesetter, type Box, type Rect } from '@canon/lib/math/typeset.ts';
import { cx } from '../lib/class-names.ts';
import { useMathEditing, type MathEditing } from '../lib/math-editing.ts';
import { useRefs } from '../lib/refs.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-math-view.css';
import '@canon/components/canon-math-editor.css';

export interface CanonMathEditorProps extends HTMLAttributes<HTMLDivElement> {
	editing: MathEditing;
	/** Font size in px; default 30. */
	size?: number;
	ref?: Ref<HTMLDivElement>;
}

export const padding = 16;
export const blinkSeconds = 0.53;
/** Seconds of holding before the caret follows the pointer. */
export const dragDelay = 0.22;

/** Distance to a caret line; vertical distance counts double, so a tap picks its own line of a fraction. */
function distance(rect: Rect, x: number, y: number): number {
	const dy =
		y < rect.y
			? rect.y - y
			: Math.max(0, y - (rect.y + rect.height));
	const dx =
		x < rect.x
			? rect.x - x
			: Math.max(0, x - (rect.x + rect.width));
	return dx + dy * 2;
}

function still(): boolean {
	return matchMedia('(prefers-reduced-motion: reduce)').matches;
}

const morphs = new WeakMap<SVGGElement, MathMorph>();

function draw(scroller: HTMLElement, box: Box, editing: MathEditing) {
	const content = scroller.firstElementChild as HTMLElement;
	const group = content.querySelector('g')!;
	const caret = content.querySelector<HTMLElement>(
		'.canon-math-editor-caret',
	)!;
	const morph = morphs.get(group) ?? new MathMorph(group);
	morphs.set(group, morph);
	content.style.minInlineSize = `${Math.ceil(box.width + padding * 2 + 2)}px`;
	content.style.minBlockSize = `${Math.ceil(box.height + padding * 2)}px`;
	let height = -1;
	const origin = () => ({
		x: padding,
		y: (content.clientHeight - box.height) / 2 + box.ascent,
	});
	const place = (animated: boolean) => {
		height = content.clientHeight;
		const o = origin();
		morph.show(
			keyed(box.atoms, 'edit', (atom) => ({
				atom,
				frame: {
					...atom.frame,
					x: atom.frame.x + o.x,
					y: atom.frame.y + o.y,
				},
				alpha: 1,
			})),
			animated,
		);
		const { row, index } = editing.expression.caret;
		const stop = box.carets.find(
			(c) => c.row === row && c.index === index,
		);
		const r = stop?.rect ?? { x: 0, y: 0, width: 0, height: 0 };
		const rect =
			r.width > 0
				? { ...r, x: r.x + o.x, y: r.y + o.y }
				: {
						...r,
						x: r.x + o.x - 1,
						y: r.y + o.y,
						width: 2,
					};
		caret.style.insetInlineStart = `${rect.x}px`;
		caret.style.insetBlockStart = `${rect.y}px`;
		caret.style.inlineSize = `${rect.width}px`;
		caret.style.blockSize = `${rect.height}px`;
		caret.classList.toggle(
			'canon-math-editor-caret--slot',
			rect.width > 2,
		);
		caret.getAnimations().forEach((a) => a.cancel());
		if (!still())
			caret.animate([{ opacity: 1 }, { opacity: 0 }], {
				duration: blinkSeconds * 2000,
				easing: 'steps(2, jump-none)',
				iterations: Infinity,
			});
		const left = rect.x - 24;
		const right = rect.x + rect.width + 24;
		if (left < scroller.scrollLeft)
			scroller.scrollTo({
				left,
				behavior: animated ? 'smooth' : 'auto',
			});
		else if (right > scroller.scrollLeft + scroller.clientWidth)
			scroller.scrollTo({
				left: right - scroller.clientWidth,
				behavior: animated ? 'smooth' : 'auto',
			});
	};
	place(editing.animates && group.childElementCount > 0);
	editing.animates = false;

	const resize = new ResizeObserver(() => {
		if (content.clientHeight !== height) place(false);
	});
	resize.observe(content);

	let hold: number | undefined;
	let following = false;
	let dragX: number | undefined;
	const moveCaret = (event: PointerEvent) => {
		const bounds = content.getBoundingClientRect();
		const zoom = content.offsetWidth / (bounds.width || 1);
		const o = origin();
		const x = (event.clientX - bounds.left) * zoom - o.x;
		const y = (event.clientY - bounds.top) * zoom - o.y;
		let best: (typeof box.carets)[number] | undefined;
		for (const stop of box.carets)
			if (
				!best ||
				distance(stop.rect, x, y) <
					distance(best.rect, x, y)
			)
				best = stop;
		if (best) editing.moveCaret(best.row as Row, best.index);
	};
	const down = (event: PointerEvent) => {
		if (event.button !== 0) return;
		capture(scroller, event.pointerId);
		moveCaret(event);
		following = event.pointerType === 'mouse';
		dragX = event.clientX;
		window.clearTimeout(hold);
		hold = window.setTimeout(
			() => (following = true),
			dragDelay * 1000,
		);
	};
	const move = (event: PointerEvent) => {
		if (dragX === undefined) return;
		if (following) {
			moveCaret(event);
			return;
		}
		scroller.scrollLeft -= event.clientX - dragX;
		dragX = event.clientX;
		window.clearTimeout(hold);
	};
	const up = () => {
		window.clearTimeout(hold);
		following = false;
		dragX = undefined;
	};
	scroller.addEventListener('pointerdown', down);
	scroller.addEventListener('pointermove', move);
	scroller.addEventListener('pointerup', up);
	scroller.addEventListener('pointercancel', up);
	scroller.addEventListener('lostpointercapture', up);
	return () => {
		resize.disconnect();
		window.clearTimeout(hold);
		scroller.removeEventListener('pointerdown', down);
		scroller.removeEventListener('pointermove', move);
		scroller.removeEventListener('pointerup', up);
		scroller.removeEventListener('pointercancel', up);
		scroller.removeEventListener('lostpointercapture', up);
	};
}

/**
 * The expression being edited, typeset, with a blinking caret. A tap moves
 * the caret to the nearest place; held, the caret follows the pointer.
 */
export default function CanonMathEditor({
	editing,
	size,
	className,
	ref,
	...rest
}: CanonMathEditorProps) {
	const version = useMathEditing(editing);
	const box = useMemo(() => {
		void version;
		const e = editing.expression;
		return layoutRow(
			new Typesetter(canvasMetrics, size ?? 30, 'result'),
			e.root,
			{ caret: e.caret.row, variable: e.variable },
		);
	}, [editing, version, size]);

	const drawing = useCallback(
		(scroller: HTMLDivElement | null) =>
			scroller ? draw(scroller, box, editing) : undefined,
		[box, editing],
	);

	return (
		<div
			className={cx('canon-math-editor', className)}
			role="textbox"
			aria-label="Expression"
			aria-readonly="true"
			ref={useRefs(drawing, ref)}
			{...rest}
		>
			<div className="canon-math-editor-content">
				<svg aria-hidden="true">
					<g />
				</svg>
				<span className="canon-math-editor-caret" />
			</div>
			<span className="canon-math-editor-text">
				{editing.expression.text}
			</span>
		</div>
	);
}
