// before the components' CSS, as the Ember demo's <link> in index.html
import '../../../demo-app/styles.css';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './app.tsx';

// ?theme=dark or ?theme=light forces the class the web app writes on <html>
const theme = new URLSearchParams(window.location.search).get('theme');
if (theme === 'dark' || theme === 'light') {
	document.documentElement.classList.add(theme);
}

createRoot(document.getElementById('root')!).render(
	<StrictMode>
		<App />
	</StrictMode>,
);
