import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const path = (relative: string) =>
  fileURLToPath(new URL(relative, import.meta.url));

export default defineConfig({
  base: './',
  // one tsconfig for ../src too; the root one extends @ember/app-tsconfig, absent without a root install
  tsconfig: './tsconfig.json',
  plugins: [react()],
  resolve: {
    alias: {
      '@canon': path('../src'),
      '@port': path('../ports/react/src'),
    },
    // the port's files resolve react from here; ports/react has no node_modules of its own in a fresh checkout
    dedupe: ['react', 'react-dom'],
  },
  server: { fs: { allow: ['..'] } },
});
