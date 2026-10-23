// Screenshots the running demo (bun run start) in light and dark.
// node scripts/shot.mjs <out-dir> [url] [width] [height]
// Prints console errors; CHROME_PATH overrides the browser.
import puppeteer from 'puppeteer-core';

const [
	out = '.',
	url = 'http://localhost:4200/',
	width = '1400',
	height = '1000',
] = process.argv.slice(2);
const browser = await puppeteer.launch({
	executablePath:
		process.env.CHROME_PATH ??
		'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
	headless: 'new',
});
const page = await browser.newPage();
page.on('pageerror', (e) => console.log('pageerror', e.message));
page.on('console', (m) => {
	if (m.type() === 'error') console.log('console', m.text());
});
await page.setViewport({ width: Number(width), height: Number(height) });
for (const scheme of ['light', 'dark']) {
	await page.emulateMediaFeatures([
		{ name: 'prefers-color-scheme', value: scheme },
	]);
	await page.goto(url, { waitUntil: 'networkidle2' });
	await new Promise((resolve) => setTimeout(resolve, 500));
	const file = `${out}/gallery-${width}x${height}-${scheme}.png`;
	await page.screenshot({ path: file });
	console.log(file);
}
await browser.close();
