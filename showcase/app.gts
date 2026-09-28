import EmberApp from 'ember-strict-application-resolver';
import EmberRouter from '@ember/routing/router';
import CanonToastService from '#src/services/canon-toast.ts';
import Showcase from './components/showcase.gts';
import './showcase.css';

// ?theme=dark or ?theme=light forces the class the web app writes on <html>
const theme = new URLSearchParams(window.location.search).get('theme');
if (theme === 'dark' || theme === 'light') {
  document.documentElement.classList.add(theme);
}

class Router extends EmberRouter {
  // the page is served from any directory beside the registry
  location = 'none';
}

export class App extends EmberApp {
  modules = {
    './router': Router,
    './services/canon-toast': CanonToastService,
    './templates/application': Showcase,
  };
}

Router.map(function () {});
