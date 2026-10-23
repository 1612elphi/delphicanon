export type GlyphKind = 'glyph' | 'space' | 'newline';

export interface Frame {
	x: number;
	y: number;
	width: number;
	height: number;
}

/**
 * Glyph widths wrapped into rows, words kept whole unless one is wider than
 * a row (CanonGlyphRows). Frames sit in a block whose first row starts at y 0.
 */
export function glyphRows(
	widths: number[],
	kinds: GlyphKind[],
	width: number,
	gap: number,
	height: number,
	pitch: number,
): { frames: Frame[]; rows: number } {
	const frames: Frame[] = widths.map(() => ({
		x: 0,
		y: 0,
		width: 0,
		height,
	}));
	let row = 0;
	let x = 0;
	let filled = false;
	const place = (k: number, left: number) => {
		frames[k] = {
			x: left,
			y: row * pitch,
			width: widths[k]!,
			height,
		};
		x = left + widths[k]!;
		filled = true;
	};
	const wrap = () => {
		row += 1;
		x = 0;
		filled = false;
	};
	let i = 0;
	while (i < widths.length) {
		const kind = kinds[i];
		if (kind === 'newline') {
			frames[i] = { x, y: row * pitch, width: 0, height };
			wrap();
			i += 1;
		} else if (kind === 'space') {
			// no leading row space
			if (filled) place(i, x + gap);
			else
				frames[i] = {
					x: 0,
					y: row * pitch,
					width: 0,
					height,
				};
			i += 1;
		} else {
			let end = i;
			let word = 0;
			while (end < widths.length && kinds[end] === 'glyph') {
				word += widths[end]! + (end > i ? gap : 0);
				end += 1;
			}
			if (filled && x + gap + word > width) wrap();
			for (let k = i; k < end; k++) {
				if (filled && x + gap + widths[k]! > width)
					wrap();
				place(k, filled ? x + gap : 0);
			}
			i = end;
		}
	}
	return { frames, rows: widths.length === 0 ? 0 : row + 1 };
}
