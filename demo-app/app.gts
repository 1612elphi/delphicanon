import EmberApp from 'ember-strict-application-resolver';
import EmberRouter from '@ember/routing/router';
import PageTitleService from 'ember-page-title/services/page-title';
import CanonToastService from '#src/services/canon-toast.ts';

// ?theme=dark or ?theme=light forces the class the web app writes on <html>
const theme = new URLSearchParams(window.location.search).get('theme');
if (theme === 'dark' || theme === 'light') {
	document.documentElement.classList.add(theme);
}

class Router extends EmberRouter {
	location = 'history';
	rootURL = '/';
}

export class App extends EmberApp {
	modules = {
		'./router': Router,
		'./services/page-title': PageTitleService,
		'./services/canon-toast': CanonToastService,
		...import.meta.glob('./templates/**/*', { eager: true }),
	};
}

Router.map(function () {});
