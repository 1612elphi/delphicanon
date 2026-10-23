import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

const canon = fileURLToPath(new URL('../../src', import.meta.url));
const publicDir = fileURLToPath(new URL('../../public', import.meta.url));

export default defineConfig({
	root: 'demo',
	publicDir,
	plugins: [vue()],
	resolve: { alias: { '@canon': canon } },
	server: { fs: { allow: ['../..'] } },
	build: { outDir: '../dist', emptyOutDir: true },
});
