import { spawnSync } from 'node:child_process';
import {
	copyFileSync,
	existsSync,
	mkdirSync,
	readdirSync,
	readFileSync,
	rmSync,
	writeFileSync,
} from 'node:fs';
import { dirname, join, posix, relative, resolve, sep } from 'node:path';

type Kind = 'component' | 'lib' | 'style';

interface Item {
	name: string;
	kind: Kind;
	files: Map<string, string>;
	dependencies: Set<string>;
}

interface FileEntry {
	path: string;
	type: string;
	target?: string;
}

interface Cli {
	dependency(name: string): string;
	file(target: string, kind: Kind): FileEntry;
	build(out: string): string[];
}

const here = import.meta.dir;
const root = resolve(here, '..');
const shared = join(root, 'src');
export const publicDir = join(here, 'public', 'r');
const stagingDir = join(here, '.build');
// The site root; the registry is under r/, and public/ outside r/ is not the generator's.
const siteUrl = (
	process.env.CANON_REGISTRY_URL ?? 'http://localhost:4330'
).replace(/\/$/, '');

const itemTypes: Record<Kind, string> = {
	component: 'registry:component',
	lib: 'registry:lib',
	style: 'registry:file',
};

const bin = (name: string) => join(here, 'node_modules', '.bin', name);

// Every file lands in <components alias>/canon/<target>; the three CLIs place files differently.
const clis: Record<string, (fw: string) => Cli> = {
	// shadcn resolves the @components/ target placeholder; a bare dependency name means shadcn/ui's own item.
	react: (fw) => ({
		dependency: (name) => `${siteUrl}/r/${fw}/${name}.json`,
		file: (target, kind) => ({
			path: `components/canon/${target}`,
			type: target.endsWith('.css')
				? 'registry:file'
				: kind === 'lib'
					? 'registry:lib'
					: 'registry:component',
			target: `@components/canon/${target}`,
		}),
		build: (out) => [
			bin('shadcn'),
			'build',
			'registry.json',
			'-o',
			out,
		],
	}),
	// shadcn-vue 2.8 has no target placeholders; it places a file by the part of its path after the components alias.
	vue: (fw) => ({
		dependency: (name) => `${siteUrl}/r/${fw}/${name}.json`,
		file: (target) => ({
			path: `components/canon/${target}`,
			type: 'registry:component',
		}),
		build: (out) => [
			bin('shadcn-vue'),
			'build',
			'registry.json',
			'-o',
			out,
		],
	}),
	// shadcn-svelte resolves a target against the directory of the file type and turns local:<name> into ./<name>.json.
	svelte: () => ({
		dependency: (name) => `local:${name}`,
		file: (target) => ({
			path: `components/canon/${target}`,
			type: 'registry:component',
			target: `canon/${target}`,
		}),
		build: (out) => [
			bin('shadcn-svelte'),
			'registry',
			'build',
			'registry.json',
			'-o',
			out,
		],
	}),
};

const stem = (name: string) => name.replace(/\..*$/, '');
const posixPath = (path: string) => path.split(sep).join('/');
export const importPattern =
	/(?<![\w$.'"])(from\s+|import\s*\(\s*|import\s+)(['"])([^'"\n]+)\2/g;

function locate(port: string, file: string) {
	const under = (dir: string) =>
		file.startsWith(dir + sep)
			? posixPath(relative(dir, file))
			: null;
	let path: string | null;
	if ((path = under(join(port, 'components'))))
		return {
			target: path,
			item: stem(path),
			kind: 'component' as Kind,
		};
	if ((path = under(join(port, 'lib'))))
		return {
			target: `lib/${path}`,
			item: `canon-lib-${stem(path)}`,
			kind: 'lib' as Kind,
		};
	if ((path = under(join(shared, 'lib'))))
		return {
			target: `lib/${path}`,
			item: `canon-lib-${stem(path.split('/')[0]!)}`,
			kind: 'lib' as Kind,
		};
	if ((path = under(join(shared, 'components'))) && path.endsWith('.css'))
		return {
			target: path,
			item: stem(path),
			kind: 'component' as Kind,
		};
	if (file === join(shared, 'styles', 'tokens.css'))
		return {
			target: 'tokens.css',
			item: 'canon-tokens',
			kind: 'style' as Kind,
		};
	throw new Error(`no registry location for ${relative(root, file)}`);
}

function consumerSpecifier(from: string, to: string) {
	let path = posix.relative(posix.dirname(from), to);
	if (!path.startsWith('.')) path = `./${path}`;
	return path
		.replace(/\.svelte\.ts$/, '.svelte.js')
		.replace(/\.tsx?$/, '');
}

function findCycle(items: Map<string, Item>) {
	const done = new Set<string>();
	const visit = (name: string, path: string[]): string[] | null => {
		if (path.includes(name)) return [...path, name];
		if (done.has(name)) return null;
		for (const dependency of items.get(name)!.dependencies) {
			const cycle = visit(dependency, [...path, name]);
			if (cycle) return cycle;
		}
		done.add(name);
		return null;
	};
	for (const name of items.keys()) {
		const cycle = visit(name, []);
		if (cycle) return cycle;
	}
	return null;
}

function collect(fw: string) {
	const port = join(root, 'ports', fw, 'src');
	const packages = Object.keys(
		JSON.parse(
			readFileSync(
				join(root, 'ports', fw, 'package.json'),
				'utf8',
			),
		).dependencies ?? {},
	);
	const components = readdirSync(join(port, 'components')).sort();
	const items = new Map<string, Item>();
	const sources = new Map<string, string>();
	const queue = components.map((name) => join(port, 'components', name));
	const seen = new Set<string>();

	while (queue.length) {
		const file = queue.shift()!;
		if (seen.has(file)) continue;
		seen.add(file);
		const self = locate(port, file);
		const clash = sources.get(self.target);
		if (clash)
			throw new Error(
				`${relative(root, file)} and ${relative(root, clash)} both install as canon/${self.target}`,
			);
		sources.set(self.target, file);
		let item = items.get(self.item);
		if (!item) {
			item = {
				name: self.item,
				kind: self.kind,
				files: new Map(),
				dependencies: new Set(),
			};
			items.set(self.item, item);
		}
		let content = readFileSync(file, 'utf8');
		if (!file.endsWith('.css'))
			content = content.replace(
				importPattern,
				(match, lead, quote, spec) => {
					if (
						!spec.startsWith('.') &&
						!spec.startsWith('@canon/')
					) {
						if (
							!packages.some(
								(p) =>
									spec ===
										p ||
									spec.startsWith(
										`${p}/`,
									),
							)
						)
							throw new Error(
								`${relative(root, file)} imports ${spec}`,
							);
						return match;
					}
					const imported = spec.startsWith(
						'@canon/',
					)
						? join(
								shared,
								spec.slice(
									'@canon/'
										.length,
								),
							)
						: resolve(dirname(file), spec);
					if (!existsSync(imported))
						throw new Error(
							`${relative(root, file)}: ${spec} does not exist`,
						);
					queue.push(imported);
					const other = locate(port, imported);
					if (other.item !== self.item)
						item.dependencies.add(
							other.item,
						);
					return (
						lead +
						quote +
						consumerSpecifier(
							self.target,
							other.target,
						) +
						quote
					);
				},
			);
		// The Next.js App Router treats a module without this directive as a server component.
		if (self.kind === 'component' && file.endsWith('.tsx'))
			content = `'use client'\n\n${content}`;
		item.files.set(self.target, content);
	}

	const cycle = findCycle(items);
	if (cycle) throw new Error(`${fw}: item cycle ${cycle.join(' -> ')}`);
	return { items, components: components.map(stem) };
}

export function build() {
	rmSync(stagingDir, { recursive: true, force: true });
	rmSync(publicDir, { recursive: true, force: true });
	const frameworks = readdirSync(join(root, 'ports')).filter((fw) =>
		existsSync(join(root, 'ports', fw, 'src', 'components')),
	);
	for (const fw of frameworks) {
		const makeCli = clis[fw];
		if (!makeCli) throw new Error(`no shadcn CLI for ports/${fw}`);
		const cli = makeCli(fw);
		const { items, components } = collect(fw);
		const staging = join(stagingDir, fw);
		const entries = [...items.values()]
			.sort((a, b) => a.name.localeCompare(b.name))
			.map((item) => ({
				name: item.name,
				type: itemTypes[item.kind],
				registryDependencies: [...item.dependencies]
					.sort()
					.map(cli.dependency),
				files: [...item.files.keys()]
					.sort()
					.map((target) => {
						const entry = cli.file(
							target,
							item.kind,
						);
						const path = join(
							staging,
							entry.path,
						);
						mkdirSync(dirname(path), {
							recursive: true,
						});
						writeFileSync(
							path,
							item.files.get(target)!,
						);
						return entry;
					}),
			}));
		entries.push({
			name: 'canon-all',
			type: 'registry:block',
			registryDependencies: components.map(cli.dependency),
			files: [],
		});
		const registry = {
			$schema: 'https://ui.shadcn.com/schema/registry.json',
			name: 'delphicanon',
			homepage: `${siteUrl}/`,
			items: entries,
		};
		writeFileSync(
			join(staging, 'registry.json'),
			`${JSON.stringify(registry, null, 2)}\n`,
		);
		// shadcn-svelte reads the package.json in its working directory to detect npm dependencies.
		writeFileSync(
			join(staging, 'package.json'),
			'{ "private": true }\n',
		);
		const out = join(publicDir, fw);
		const [command, ...args] = cli.build(out);
		const run = spawnSync(command!, args, {
			cwd: staging,
			stdio: 'inherit',
		});
		if (run.status !== 0)
			throw new Error(`${fw}: ${command} failed`);
		// shadcn-svelte writes index.json, not registry.json.
		if (!existsSync(join(out, 'registry.json')))
			copyFileSync(
				join(staging, 'registry.json'),
				join(out, 'registry.json'),
			);
		console.log(
			`${fw}: ${entries.length} items in ${relative(here, out)}`,
		);
	}
}

if (import.meta.main) build();
