import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vite';
import { extensions, ember } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';

export default defineConfig({
  root: fileURLToPath(new URL('.', import.meta.url)),
  base: './',
  envPrefix: ['VITE_', 'CANON_'],
  // the fonts come in through showcase.css, so the build carries them beside its assets
  publicDir: false,
  plugins: [ember(), babel({ babelHelpers: 'inline', extensions })],
  // @embroider/vite adds the root package's tests/index.html unless the input is set
  build: { rolldownOptions: { input: { main: 'index.html' } } },
  server: { fs: { allow: ['..'] } },
});
