import { mount } from 'svelte';
import '../../../demo-app/styles.css';
import App from './app.svelte';

// ?theme=dark or ?theme=light forces the class the web app writes on <html>
const theme = new URLSearchParams(window.location.search).get('theme');
if (theme === 'dark' || theme === 'light') {
	document.documentElement.classList.add(theme);
}

mount(App, { target: document.body });
