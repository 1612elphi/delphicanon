/**
 * True when a file matches an `accept` list as an `<input type=file>` reads
 * it: MIME types, `type/*` wildcards and `.extensions`. An empty list takes
 * any file.
 */
export function accepts(
  file: { name: string; type: string },
  accept = '',
): boolean {
  const patterns = accept
    .split(',')
    .map((pattern) => pattern.trim().toLowerCase())
    .filter(Boolean);
  if (patterns.length === 0) return true;
  const name = file.name.toLowerCase();
  const type = file.type.toLowerCase();
  return patterns.some((pattern) => {
    if (pattern.startsWith('.')) return name.endsWith(pattern);
    if (pattern.endsWith('/*')) return type.startsWith(pattern.slice(0, -1));
    return type === pattern;
  });
}

/** A file name without its extension. */
export function stem(name: string): string {
  const dot = name.lastIndexOf('.');
  return dot > 0 ? name.slice(0, dot) : name;
}

/**
 * A name split so the middle can be cut: the head shrinks with an ellipsis
 * and the tail, the last `keep` characters, stays whole.
 */
export function splitForMiddle(name: string, keep = 8): [string, string] {
  const chars = [...name];
  if (chars.length <= keep) return ['', name];
  return [chars.slice(0, -keep).join(''), chars.slice(-keep).join('')];
}
