import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import { playwright } from '@vitest/browser-playwright';

const chrome =
	process.env.CHROME_PATH ??
	'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
// CANON_BROWSER=webkit or firefox runs Playwright's own build instead
const browser = (process.env.CANON_BROWSER ?? 'chromium') as
	'chromium' | 'webkit' | 'firefox';

export default defineConfig({
	plugins: [react()],
	resolve: {
		alias: {
			'@canon': fileURLToPath(
				new URL('../../src', import.meta.url),
			),
		},
	},
	publicDir: '../../public',
	server: { fs: { allow: ['../..'] } },
	test: {
		include: ['tests/**/*-test.{ts,tsx}'],
		browser: {
			enabled: true,
			headless: true,
			provider: playwright(
				browser === 'chromium'
					? {
							launchOptions: {
								executablePath:
									chrome,
							},
						}
					: {},
			),
			instances: [
				{
					browser,
					viewport: { width: 1440, height: 900 },
				},
			],
		},
	},
});
