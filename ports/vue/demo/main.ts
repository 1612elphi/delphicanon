import { createApp } from 'vue';
import '../../../demo-app/styles.css';
import App from './app.vue';

// ?theme=dark or ?theme=light forces the class the web app writes on <html>
const theme = new URLSearchParams(window.location.search).get('theme');
if (theme === 'dark' || theme === 'light') {
  document.documentElement.classList.add(theme);
}

createApp(App).mount('#app');
