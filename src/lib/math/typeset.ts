import {
	inverses,
	isItalic,
	N,
	shown,
	structural,
	type Fence,
	type Node,
} from './node.ts';

export interface Rect {
	x: number;
	y: number;
	width: number;
	height: number;
}

export type Mark =
	| { m: 'glyphs'; text: string; italic: boolean }
	| { m: 'rule' }
	| { m: 'paren'; open: boolean }
	/** Half of a floor or ceiling bracket. */
	| { m: 'corner'; open: boolean; floor: boolean }
	| { m: 'radical' }
	| { m: 'hole' };

export type Ink = 'input' | 'result' | 'accent';

export interface Atom {
	mark: Mark;
	/** Glyphs: x is the pen position, y the baseline and height the font size. Shapes: their bounds. */
	frame: Rect;
	/** Stroke width of a shape. */
	weight: number;
	ink: Ink;
}

/** A place the editing caret can stand: an index in an edited row, and the caret's line. */
export interface Caret<Row = unknown> {
	row: Row;
	index: number;
	rect: Rect;
}

/** Glyph measurements at a font size: advance width and ink bounds about the baseline, both positive. */
export interface Metrics {
	measure(
		text: string,
		italic: boolean,
		size: number,
	): { width: number; ascent: number; descent: number };
	xHeight(size: number, italic: boolean): number;
}

/** Atoms placed around a baseline at y = 0, y growing downwards, and the caret stops among them when edited. */
export class Box {
	atoms: Atom[] = [];
	carets: Caret[] = [];
	width: number;
	ascent: number;
	descent: number;

	constructor(width = 0, ascent = 0, descent = 0, atoms: Atom[] = []) {
		this.width = width;
		this.ascent = ascent;
		this.descent = descent;
		this.atoms = atoms;
	}

	get height() {
		return this.ascent + this.descent;
	}

	append(other: Box, gap = 0) {
		this.embed(other, this.width + gap);
		this.width += gap + other.width;
		this.ascent = Math.max(this.ascent, other.ascent);
		this.descent = Math.max(this.descent, other.descent);
		return this;
	}

	/** Adds `other`'s atoms and carets moved by `x` and `y`; the size stays for the caller to set. */
	embed(other: Box, x: number, y = 0) {
		for (const atom of other.atoms)
			this.atoms.push({
				...atom,
				frame: moved(atom.frame, x, y),
			});
		for (const caret of other.carets)
			this.carets.push({
				...caret,
				rect: moved(caret.rect, x, y),
			});
	}

	/** Moved down by `y`; a negative `y` raises it. */
	lowered(y: number): Box {
		const box = new Box(
			this.width,
			this.ascent - y,
			this.descent + y,
		);
		box.embed(this, 0, y);
		return box;
	}
}

function moved(rect: Rect, x: number, y: number): Rect {
	return { ...rect, x: rect.x + x, y: rect.y + y };
}

const minus = '−';

/** Binding strength: an operand weaker than its place needs brackets. */
function precedence(node: Node, level: number): number {
	switch (node.k) {
		case 'relation':
		case 'list':
			return 0;
		case 'sum':
		case 'negate':
		case 'derivative':
		case 'integral':
			return 1;
		case 'product':
			return 2;
		case 'quotient':
			return level < 2 ? 4 : 2;
		case 'power':
			return 3;
		case 'call':
		case 'factorial':
			return 4;
		default:
			return 5;
	}
}

function startsWithDigit(node: Node): boolean {
	switch (node.k) {
		case 'number':
			return true;
		case 'power':
		case 'factorial':
			return startsWithDigit(node.a);
		case 'product':
			return node.items[0]
				? startsWithDigit(node.items[0])
				: false;
		default:
			return false;
	}
}

function isFunction(node: Node): boolean {
	if (node.k === 'call') return !structural.has(node.name);
	if (node.k === 'power') return isFunction(node.a);
	return false;
}

export function isBare(node: Node): boolean {
	return node.k === 'symbol' || node.k === 'number';
}

function italicSymbol(node: Node): boolean {
	return node.k === 'symbol' && isItalic(shown(node.v));
}

/**
 * Sets a tree at `size` in the maths serif. Levels follow TeX: 0 display,
 * 1 text (a fraction's parts, same size), 2 script, 3 script-script.
 */
export class Typesetter {
	metrics: Metrics;
	size: number;
	ink: Ink;

	constructor(metrics: Metrics, size: number, ink: Ink = 'result') {
		this.metrics = metrics;
		this.size = size;
		this.ink = ink;
	}

	points(level: number): number {
		return this.size * [1, 1, 0.7, 0.55][Math.min(level, 3)]!;
	}

	script(level: number): number {
		return level < 2 ? 2 : 3;
	}

	text(
		string: string,
		{ italic = false, level = 0, scale = 1, ink = this.ink } = {},
	): Box {
		const points = this.points(level) * scale;
		if (string === '') return new Box();
		const m = this.metrics.measure(string, italic, points);
		return new Box(
			m.width,
			Math.max(
				this.metrics.xHeight(points, italic),
				m.ascent,
			),
			Math.max(0, m.descent),
			[
				{
					mark: {
						m: 'glyphs',
						text: string,
						italic,
					},
					frame: {
						x: 0,
						y: 0,
						width: m.width,
						height: points,
					},
					weight: 0,
					ink,
				},
			],
		);
	}

	private operand(node: Node, level: number, below: number): Box {
		const box = this.layout(node, level);
		return precedence(node, level) < below
			? this.parens(box, level)
			: box;
	}

	layout(node: Node, level = 0): Box {
		const s = this.points(level);
		const script = this.script(level);
		const operatorGap = level >= 2 ? s * 0.12 : s * 0.22;
		switch (node.k) {
			case 'number':
				return this.text(node.v, { level });
			case 'symbol': {
				const text = shown(node.v);
				return this.text(text, {
					italic: isItalic(text),
					level,
				});
			}
			case 'word':
				return this.text(node.v, { level });
			case 'hole':
				return this.hole(level);
			case 'negate':
				return this.text(minus, { level }).append(
					this.operand(node.a, level, 2),
					s * 0.04,
				);
			case 'sum': {
				const box = new Box();
				node.items.forEach((term, index) => {
					let body = term;
					let negative = false;
					if (term.k === 'negate') {
						negative = true;
						body = term.a;
					}
					const set = this.operand(
						body,
						level,
						negative ||
							(index > 0 &&
								body.k ===
									'negate')
							? 2
							: 1,
					);
					if (index === 0) {
						if (negative)
							box.append(
								this.text(
									minus,
									{
										level,
									},
								),
							);
						box.append(
							set,
							negative ? s * 0.04 : 0,
						);
					} else {
						box.append(
							this.text(
								negative
									? minus
									: '+',
								{ level },
							),
							operatorGap,
						);
						box.append(set, operatorGap);
					}
				});
				return box;
			}
			case 'product': {
				let box = new Box();
				const factors = node.items;
				factors.forEach((original, index) => {
					let factor = original;
					// parens: sin(x) x²
					if (
						index < factors.length - 1 &&
						factor.k === 'call' &&
						factor.items.length === 1 &&
						isBare(factor.items[0]!) &&
						!structural.has(factor.name)
					) {
						factor = N.call(factor.name, [
							N.group(
								factor
									.items[0]!,
							),
						]);
					}
					const set = this.operand(
						factor,
						level,
						index === 0 &&
							factor.k === 'negate'
							? 1
							: 2,
					);
					if (index === 0) {
						box = set;
						return;
					}
					if (startsWithDigit(original)) {
						box.append(
							this.text('·', {
								level,
							}),
							s * 0.14,
						);
						box.append(set, s * 0.14);
					} else {
						const previous =
							factors[index - 1]!;
						const spaced =
							isFunction(previous) ||
							isFunction(factor) ||
							(level < 2 &&
								(previous.k ===
									'quotient' ||
									factor.k ===
										'quotient'));
						box.append(
							set,
							spaced
								? s * 0.26
								: s * 0.04,
						);
					}
				});
				return box;
			}
			case 'quotient': {
				if (level >= 2) {
					const box = this.operand(
						node.a,
						level,
						2,
					);
					box.append(
						this.text('/', { level }),
						s * 0.03,
					);
					box.append(
						this.operand(node.b, level, 3),
						s * 0.03,
					);
					return box;
				}
				return this.fraction(
					this.layout(node.a, level + 1),
					this.layout(node.b, level + 1),
					level,
				);
			}
			case 'power': {
				const base = node.a;
				if (
					base.k === 'call' &&
					base.items.length === 1 &&
					!structural.has(base.name) &&
					!inverses.has(base.name)
				) {
					// sin²x
					const box = this.superscript(
						this.functionName(
							base.name,
							level,
						),
						node.b,
						level,
						false,
					);
					box.append(
						this.argument(
							base.items[0]!,
							level,
						),
						isBare(base.items[0]!)
							? s * 0.17
							: s * 0.03,
					);
					return box;
				}
				return this.superscript(
					this.operand(base, level, 5),
					node.b,
					level,
					italicSymbol(base),
				);
			}
			case 'call':
				return this.call(node.name, node.items, level);
			case 'factorial':
				return this.operand(node.a, level, 4).append(
					this.text('!', { level }),
					s * 0.02,
				);
			case 'relation': {
				const blank =
					node.a.k === 'word' && node.a.v === '';
				const box = blank
					? new Box()
					: this.layout(node.a, level);
				box.append(
					this.text(node.op, {
						level,
						ink:
							this.ink === 'result'
								? 'accent'
								: this.ink,
					}),
					blank ? 0 : s * 0.28,
				);
				box.append(
					this.layout(node.b, level),
					s * 0.28,
				);
				return box;
			}
			case 'sub':
				return this.layout(node.a, level).append(
					this.text(node.v, {
						level: script,
					}).lowered(s * 0.2),
					italicSymbol(node.a)
						? s * 0.05
						: s * 0.02,
				);
			case 'list':
				return this.listed(node.items, level, s * 0.7);
			case 'group':
				return this.parens(
					this.layout(node.a, level),
					level,
				);
			case 'derivative':
				return this.derivativeOperator(
					this.layout(
						N.symbol(node.v),
						level + 1,
					),
					level,
				).append(
					this.parens(
						this.layout(node.a, level),
						level,
					),
					s * 0.1,
				);
			case 'integral':
				return this.integralSign(
					undefined,
					undefined,
					level,
				)
					.append(
						this.operand(node.a, level, 2),
						s * 0.12,
					)
					.append(
						this.differential(
							this.layout(
								N.symbol(
									node.v,
								),
								level,
							),
							level,
						),
						s * 0.17,
					);
		}
	}

	private call(name: string, args: Node[], level: number): Box {
		const s = this.points(level);
		const script = this.script(level);
		const first = args[0] ?? N.hole;
		const at = (i: number) => this.layout(args[i]!, level);
		const small = (i: number) => this.layout(args[i]!, script);
		switch (true) {
			case name === 'sqrt':
				return this.radical(
					this.layout(first, level),
					level,
				);
			case name === 'abs':
				return this.bars(
					this.layout(first, level),
					level,
				);
			case name === 'floor' || name === 'ceil':
				return this.fence(
					name,
					this.layout(first, level),
					level,
				);
			case name === 'nthroot' && args.length === 2:
				return this.indexedRadical(
					small(1),
					at(0),
					level,
				);
			case name === 'cbrt':
				return this.indexedRadical(
					this.text('3', { level: script }),
					this.layout(first, level),
					level,
				);
			case name === 'log' && args.length === 2:
				return this.logBase(small(1), level).append(
					this.parens(at(0), level),
					s * 0.03,
				);
			case name === 'factorial':
				return this.operand(first, level, 5).append(
					this.text('!', { level }),
					s * 0.02,
				);
			case (name === 'sum' || name === 'product') &&
				args.length === 4: {
				const below = small(1)
					.append(
						this.text('=', {
							level: script,
						}),
						s * 0.04,
					)
					.append(small(2), s * 0.04);
				return this.series(
					name === 'sum' ? 'Σ' : 'Π',
					below,
					small(3),
					level,
				).append(
					this.operand(first, level, 2),
					s * 0.1,
				);
			}
			case name === 'defint' && args.length === 4:
				return this.integralSign(
					small(1),
					small(2),
					level,
				)
					.append(
						this.operand(first, level, 2),
						s * 0.1,
					)
					.append(
						this.differential(at(3), level),
						s * 0.17,
					);
			case name === 'integrate' && args.length === 2:
				return this.integralSign(
					undefined,
					undefined,
					level,
				)
					.append(
						this.operand(first, level, 2),
						s * 0.12,
					)
					.append(
						this.differential(at(1), level),
						s * 0.17,
					);
			case name === 'diff' && args.length === 2:
				return this.derivativeOperator(
					this.layout(args[1]!, level + 1),
					level,
				).append(this.parens(at(0), level), s * 0.1);
			case name === 'limit' && args.length === 3:
				return this.limitOperator(
					small(1),
					small(2),
					level,
				).append(
					this.operand(first, level, 2),
					s * 0.17,
				);
			default: {
				const box = this.functionName(name, level);
				if (args.length === 1)
					box.append(
						this.argument(first, level),
						isBare(first)
							? s * 0.17
							: s * 0.03,
					);
				else
					box.append(
						this.parens(
							this.listed(
								args,
								level,
							),
							level,
						),
						s * 0.03,
					);
				return box;
			}
		}
	}

	/** A function's name as a calculator prints it: `ln` for nerdamer's natural `log`, `log` for `log10`, sin⁻¹ for `asin`. */
	functionName(name: string, level: number): Box {
		if (name === 'log') return this.text('ln', { level });
		if (name === 'log10') return this.text('log', { level });
		if (inverses.has(name)) {
			const box = this.text(name.slice(1), { level });
			return box.append(
				this.raised(
					this.text(`${minus}1`, {
						level: this.script(level),
					}),
					box.ascent,
					level,
				),
				this.points(level) * 0.03,
			);
		}
		return this.text(name, { level });
	}

	/** Absolute value bars, or floor or ceiling brackets, around `content`. */
	fence(kind: Fence, content: Box, level: number): Box {
		if (kind === 'abs') return this.bars(content, level);
		const s = this.points(level);
		const top = -Math.max(content.ascent, s * 0.72) - s * 0.08;
		const bottom = Math.max(content.descent, s * 0.2) + s * 0.08;
		const width = s * 0.26;
		const side = (open: boolean) =>
			new Box(width, -top, bottom, [
				{
					mark: {
						m: 'corner',
						open,
						floor: kind === 'floor',
					},
					frame: {
						x: 0,
						y: top,
						width,
						height: bottom - top,
					},
					weight: Math.max(1, s * 0.05),
					ink: this.ink,
				},
			]);
		return side(true)
			.append(content, s * 0.05)
			.append(side(false), s * 0.05);
	}

	/** A radical with its index over the sign's short stroke. */
	indexedRadical(index: Box, content: Box, level: number): Box {
		const root = this.radical(content, level);
		const hook = this.points(level) * 0.15;
		const shift = Math.max(0, index.width - hook);
		const lift = root.ascent * 0.42;
		const box = new Box(
			shift + root.width,
			Math.max(root.ascent, lift + index.ascent),
			root.descent,
		);
		box.embed(index, shift + hook - index.width, -lift);
		box.embed(root, shift);
		return box;
	}

	/** `log` with its base lowered after it. */
	logBase(base: Box, level: number): Box {
		return this.text('log', { level }).append(
			base.lowered(this.points(level) * 0.25),
			this.points(level) * 0.02,
		);
	}

	/** Σ or Π on the axis with its limits centred above and below. */
	series(glyph: string, below: Box, above: Box, level: number): Box {
		const s = this.points(level);
		const sign = this.text(glyph, { level, scale: 1.4 });
		const centred = sign.lowered(
			(sign.ascent - sign.descent) / 2 - s * 0.26,
		);
		const width = Math.max(centred.width, below.width, above.width);
		const gap = s * 0.1;
		const aboveBaseline = -centred.ascent - gap - above.descent;
		const belowBaseline = centred.descent + gap + below.ascent;
		const box = new Box(
			width + s * 0.06,
			-aboveBaseline + above.ascent,
			belowBaseline + below.descent,
		);
		box.embed(centred, (width - centred.width) / 2);
		box.embed(above, (width - above.width) / 2, aboveBaseline);
		box.embed(below, (width - below.width) / 2, belowBaseline);
		return box;
	}

	/** ∫ on the axis, with its bounds at the top and bottom of its right side when given. */
	integralSign(
		lower: Box | undefined,
		upper: Box | undefined,
		level: number,
	): Box {
		const s = this.points(level);
		const sign = this.text('∫', { level, scale: 1.55 });
		const box = sign.lowered(
			(sign.ascent - sign.descent) / 2 - s * 0.26,
		);
		if (!lower && !upper) return box;
		const signWidth = box.width;
		const up = upper ?? new Box();
		const low = lower ?? new Box();
		const upperBaseline = -box.ascent + up.ascent;
		const lowerBaseline = box.descent - low.descent;
		box.embed(up, signWidth + s * 0.02, upperBaseline);
		box.embed(low, signWidth - s * 0.14, lowerBaseline);
		box.width =
			Math.max(
				signWidth + s * 0.02 + up.width,
				signWidth - s * 0.14 + low.width,
			) +
			s * 0.04;
		box.ascent = Math.max(box.ascent, -upperBaseline + up.ascent);
		box.descent = Math.max(
			box.descent,
			lowerBaseline + low.descent,
		);
		return box;
	}

	/** The `dx` closing an integral. */
	differential(variable: Box, level: number): Box {
		return this.text('d', { level }).append(
			variable,
			this.points(level) * 0.03,
		);
	}

	/** d over d and the variable, as a fraction. */
	derivativeOperator(variable: Box, level: number): Box {
		const bottom = this.text('d', { level: level + 1 }).append(
			variable,
			this.points(level) * 0.03,
		);
		return this.fraction(
			this.text('d', { level: level + 1 }),
			bottom,
			level,
		);
	}

	/** `lim` with the variable's approach set small under it. */
	limitOperator(variable: Box, approach: Box, level: number): Box {
		const s = this.points(level);
		const lim = this.text('lim', { level });
		const below = variable
			.append(
				this.text('→', { level: this.script(level) }),
				s * 0.03,
			)
			.append(approach, s * 0.03);
		const width = Math.max(lim.width, below.width);
		const belowBaseline = lim.descent + s * 0.14 + below.ascent;
		const box = new Box(
			width,
			lim.ascent,
			belowBaseline + below.descent,
		);
		box.embed(lim, (width - lim.width) / 2);
		box.embed(below, (width - below.width) / 2, belowBaseline);
		return box;
	}

	/** Two lines centred on the axis with no bar: a binomial coefficient's inside. */
	stacked(top: Box, bottom: Box, level: number): Box {
		const s = this.points(level);
		const width = Math.max(top.width, bottom.width);
		const above = top.lowered(-s * 0.26 - s * 0.1 - top.descent);
		const below = bottom.lowered(
			-s * 0.26 + s * 0.1 + bottom.ascent,
		);
		const box = new Box(width, above.ascent, below.descent);
		box.embed(above, (width - top.width) / 2);
		box.embed(below, (width - bottom.width) / 2);
		return box;
	}

	/** ₙPᵣ, as a calculator prints it. */
	permutation(n: Box, r: Box, level: number): Box {
		const s = this.points(level);
		return n
			.lowered(s * 0.2)
			.append(this.text('P', { level }), s * 0.02)
			.append(r.lowered(s * 0.2), s * 0.02);
	}

	/** A dashed box for an operand still to be typed. */
	hole(level: number, ink: Ink = this.ink): Box {
		const s = this.points(level);
		const side = s * 0.52;
		const height = s * 0.64;
		return new Box(side + s * 0.12, height, 0, [
			{
				mark: { m: 'hole' },
				frame: {
					x: s * 0.06,
					y: -height,
					width: side,
					height,
				},
				weight: Math.max(1, s * 0.04),
				ink,
			},
		]);
	}

	/** Absolute value bars around `content`. */
	bars(content: Box, level: number): Box {
		const s = this.points(level);
		const weight = Math.max(1, s * 0.05);
		const top = -content.ascent - s * 0.08;
		const bar = () =>
			new Box(weight, -top, content.descent + s * 0.08, [
				{
					mark: { m: 'rule' },
					frame: {
						x: 0,
						y: top,
						width: weight,
						height:
							content.height +
							s * 0.16,
					},
					weight: 0,
					ink: this.ink,
				},
			]);
		const box = new Box(s * 0.06)
			.append(bar())
			.append(content, s * 0.1)
			.append(bar(), s * 0.1);
		box.width += s * 0.06;
		return box;
	}

	/** A function's argument: bare when it is one letter or number (`sin x`), bracketed otherwise. */
	private argument(node: Node, level: number): Box {
		if (node.k === 'group' || isBare(node))
			return this.layout(node, level);
		return this.parens(this.layout(node, level), level);
	}

	private listed(items: Node[], level: number, gap?: number): Box {
		const box = new Box();
		items.forEach((item, index) => {
			if (index > 0)
				box.append(
					this.text(',', { level }),
					this.points(level) * 0.02,
				);
			box.append(
				this.layout(item, level),
				index > 0
					? (gap ?? this.points(level) * 0.2)
					: 0,
			);
		});
		return box;
	}

	private superscript(
		base: Box,
		exponent: Node,
		level: number,
		italic: boolean,
	): Box {
		return base.append(
			this.raised(
				this.layout(exponent, this.script(level)),
				base.ascent,
				level,
			),
			this.points(level) * (italic ? 0.07 : 0.03),
		);
	}

	/** An exponent lifted to sit over a base whose ascent is `ascent`. */
	raised(exponent: Box, ascent: number, level: number): Box {
		const lift = Math.max(
			this.points(level) * 0.38,
			ascent - exponent.height * 0.45,
		);
		return exponent.lowered(-lift);
	}

	fraction(top: Box, bottom: Box, level: number): Box {
		const s = this.points(level);
		const weight = Math.max(1, s * 0.05);
		const gap = s * 0.16;
		const axis = s * 0.26;
		const margin = s * 0.08;
		const bar = Math.max(top.width, bottom.width) + s * 0.16;
		const box = new Box(bar + margin * 2);
		const above = top.lowered(
			-axis - weight / 2 - gap - top.descent,
		);
		const below = bottom.lowered(
			-axis + weight / 2 + gap + bottom.ascent,
		);
		box.embed(above, margin + (bar - top.width) / 2);
		box.embed(below, margin + (bar - bottom.width) / 2);
		box.atoms.push({
			mark: { m: 'rule' },
			frame: {
				x: margin,
				y: -axis - weight / 2,
				width: bar,
				height: weight,
			},
			weight: 0,
			ink: this.ink,
		});
		box.ascent = above.ascent;
		box.descent = below.descent;
		return box;
	}

	radical(content: Box, level: number): Box {
		const s = this.points(level);
		const weight = Math.max(1, s * 0.05);
		const top = content.ascent + s * 0.1 + weight;
		const sign = {
			x: s * 0.04,
			y: -top + weight / 2,
			width: s * 0.5,
			height: top + content.descent + s * 0.04 - weight / 2,
		};
		const signRight = sign.x + sign.width;
		const start = signRight + s * 0.06;
		const end = start + content.width + s * 0.06;
		const box = new Box(
			end + s * 0.04,
			top + s * 0.02,
			Math.max(content.descent, sign.y + sign.height),
			[
				{
					mark: { m: 'radical' },
					frame: sign,
					weight,
					ink: this.ink,
				},
				{
					mark: { m: 'rule' },
					frame: {
						x: signRight - weight / 2,
						y: -top,
						width:
							end -
							signRight +
							weight / 2,
						height: weight,
					},
					weight: 0,
					ink: this.ink,
				},
			],
		);
		box.embed(content, start);
		return box;
	}

	/** Font brackets around content of about one line, drawn brackets around taller content. */
	parens(content: Box, level: number): Box {
		const s = this.points(level);
		if (content.height <= s * 1.05) {
			return this.text('(', { level })
				.append(content, s * 0.03)
				.append(this.text(')', { level }), s * 0.03);
		}
		const weight = Math.max(1, s * 0.07);
		const width = s * 0.26 + content.height * 0.03;
		const top = -content.ascent - s * 0.08;
		const height = content.height + s * 0.16;
		const bracket = (open: boolean) =>
			new Box(width, -top, height + top, [
				{
					mark: { m: 'paren', open },
					frame: { x: 0, y: top, width, height },
					weight,
					ink: this.ink,
				},
			]);
		return bracket(true)
			.append(content, s * 0.04)
			.append(bracket(false), s * 0.04);
	}
}
