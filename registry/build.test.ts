import { beforeAll, expect, test } from 'bun:test';
import { readdirSync, readFileSync } from 'node:fs';
import { basename, join, posix } from 'node:path';
import { build, importPattern, publicDir } from './build.ts';

interface Built {
  name: string;
  registryDependencies?: string[];
  files?: { path?: string; target?: string; content: string }[];
}

const location = (file: { path?: string; target?: string }) =>
  (file.target ?? file.path)!.replace(/^(.*\/)?canon\//, '');

beforeAll(build, 120_000);

test.each(['react', 'svelte', 'vue'])(
  '%s imports stay inside each item and its dependencies',
  (fw) => {
    const dir = join(publicDir, fw);
    const packages = Object.keys(
      JSON.parse(
        readFileSync(
          join(import.meta.dir, '..', 'ports', fw, 'package.json'),
          'utf8',
        ),
      ).dependencies,
    );
    const items = new Map<string, Built>(
      readdirSync(dir)
        .filter((name) => !['registry.json', 'index.json'].includes(name))
        .map((name) => [
          basename(name, '.json'),
          JSON.parse(readFileSync(join(dir, name), 'utf8')) as Built,
        ]),
    );
    const failures: string[] = [];
    for (const item of items.values()) {
      const dependencies = (item.registryDependencies ?? []).map((d) =>
        basename(d, '.json').replace(/^local:/, ''),
      );
      const allowed = new Set<string>();
      for (const name of [item.name, ...dependencies]) {
        const other = items.get(name);
        if (!other) failures.push(`${item.name}: unknown dependency ${name}`);
        other?.files?.forEach((file) => allowed.add(location(file)));
      }
      for (const file of item.files ?? []) {
        const from = location(file);
        for (const [, , , spec] of file.content.matchAll(importPattern)) {
          if (!spec!.startsWith('.')) {
            if (!packages.some((p) => spec === p || spec!.startsWith(`${p}/`)))
              failures.push(`${item.name}: ${from} imports ${spec}`);
            continue;
          }
          const path = posix.join(posix.dirname(from), spec!);
          const candidates = [
            path,
            `${path}.ts`,
            `${path}.tsx`,
            path.replace(/\.svelte\.js$/, '.svelte.ts'),
          ];
          if (/\.tsx?$/.test(spec!) || !candidates.some((c) => allowed.has(c)))
            failures.push(`${item.name}: ${from} imports ${spec}`);
        }
      }
    }
    const all = items.get('canon-all')?.registryDependencies?.length;
    expect(all).toBe(
      readdirSync(join(import.meta.dir, '..', 'ports', fw, 'src', 'components'))
        .length,
    );
    expect(failures).toEqual([]);
  },
);
