import { defineConfig, mergeConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';
import viteConfig from './vite.config.ts';

// CANON_BROWSER=webkit or firefox runs Playwright's own build instead
const browser = (process.env.CANON_BROWSER ?? 'chromium') as
	'chromium' | 'webkit' | 'firefox';

export default mergeConfig(
	viteConfig,
	defineConfig({
		root: '.',
		// tests mount inline templates, which need the runtime compiler
		resolve: { alias: { vue: 'vue/dist/vue.esm-bundler.js' } },
		test: {
			include: ['tests/**/*.test.ts'],
			setupFiles: ['tests/setup.ts'],
			browser: {
				enabled: true,
				headless: true,
				provider: playwright(
					browser === 'chromium'
						? {
								launchOptions: {
									executablePath:
										process
											.env
											.CHROME_PATH ??
										'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
								},
							}
						: {},
				),
				instances: [{ browser }],
				viewport: { width: 1280, height: 800 },
			},
		},
	}),
);
