export interface Size {
	width: number;
	height: number;
}

export interface Rect extends Size {
	x: number;
	y: number;
}

/** Height of a line, the room a picture leaves on its top and leading sides for a pair, and the default gap to the picture. */
export const dimensionLine = { height: 32, room: 44, gap: 12 } as const;

/**
 * Frame for a picture of `size` fitted into `area`, leaving room for the
 * dimension lines on the top and leading sides, the group centred. Inline
 * offsets are from the leading edge, so they hold in either direction.
 */
export function sheet(size: Size, area: Rect): Rect {
	const { room } = dimensionLine;
	const space = { width: area.width - room, height: area.height - room };
	if (
		size.width <= 0 ||
		size.height <= 0 ||
		space.width <= 0 ||
		space.height <= 0
	)
		return { x: 0, y: 0, width: 0, height: 0 };
	const scale = Math.min(
		space.width / size.width,
		space.height / size.height,
	);
	// keep degenerate sizes visible
	const width = Math.max(1, size.width * scale);
	const height = Math.max(1, size.height * scale);
	return {
		x: area.x + (area.width - width - room) / 2 + room,
		y: area.y + (area.height - height - room) / 2 + room,
		width,
		height,
	};
}

/**
 * The across line over `span` and the down line beside its leading side,
 * before its quarter turn, each `gap` outside `edge`.
 */
export function dimensionLines(
	span: Rect,
	edge: Rect = span,
	gap: number = dimensionLine.gap,
): { across: Rect; down: Rect } {
	const { height } = dimensionLine;
	return {
		across: {
			x: span.x,
			y: edge.y - gap - height,
			width: span.width,
			height,
		},
		down: {
			x: edge.x - gap - height / 2 - span.height / 2,
			y: span.y + span.height / 2 - height / 2,
			width: span.height,
			height,
		},
	};
}
