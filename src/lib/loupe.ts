export interface LoupeFrame {
  x: number;
  y: number;
  width: number;
  height: number;
}

/** Which side of the point a loupe sits on. */
export interface LoupeSides {
  left: boolean;
  above: boolean;
}

/**
 * Where a loupe of `side` goes near `centre` in a view of `size`: up and to
 * the left, `gap` away, turned to the other side where it would come within
 * 8 px of the edge or above `top`, then kept inside. `sides` keeps the side
 * it was on, so a dragged loupe does not jump.
 */
export function frame(
  centre: { x: number; y: number },
  side: number,
  gap: number,
  size: { width: number; height: number },
  top: number,
  sides?: LoupeSides,
): LoupeFrame {
  const left = sides?.left ?? centre.x - gap - side >= 8;
  const above = sides?.above ?? centre.y - gap - side >= top;
  const x = left ? centre.x - gap - side : centre.x + gap;
  const y = above ? centre.y - gap - side : centre.y + gap;
  return {
    x: Math.min(Math.max(x, 8), size.width - side - 8),
    y: Math.min(Math.max(y, top), size.height - side - 8),
    width: side,
    height: side,
  };
}
