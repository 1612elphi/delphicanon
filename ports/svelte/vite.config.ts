import { fileURLToPath } from 'node:url';
import { svelte } from '@sveltejs/vite-plugin-svelte';
import { playwright } from '@vitest/browser-playwright';
import { defineConfig } from 'vitest/config';

const chrome =
  process.env['CHROME_PATH'] ??
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

export default defineConfig({
  plugins: [svelte()],
  resolve: {
    alias: { '@canon': fileURLToPath(new URL('../../src', import.meta.url)) },
  },
  publicDir: '../../public',
  server: { fs: { allow: ['../..'] } },
  test: {
    include: ['tests/**/*.test.ts'],
    browser: {
      enabled: true,
      headless: true,
      provider: playwright({ launchOptions: { executablePath: chrome } }),
      instances: [{ browser: 'chromium' }],
    },
  },
});
