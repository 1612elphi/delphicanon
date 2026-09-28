import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import CanonButton from '#src/components/canon-button.gts';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonPage from '#src/components/canon-page.gts';
import CanonSidebar from '#src/components/canon-sidebar.gts';
import CanonSidebarRow from '#src/components/canon-sidebar-row.gts';
import CanonWindow from '#src/components/canon-window.gts';
import GalleryArt from '../gallery-art.gts';
import Icon from '../icon.gts';
import aperture from 'lucide-static/icons/aperture.svg?raw';
import camera from 'lucide-static/icons/camera.svg?raw';
import clipboard from 'lucide-static/icons/clipboard.svg?raw';
import keyboard from 'lucide-static/icons/keyboard.svg?raw';
import panelLeft from 'lucide-static/icons/panel-left.svg?raw';
import settings from 'lucide-static/icons/settings.svg?raw';
import wrench from 'lucide-static/icons/wrench.svg?raw';
import './shell.css';

export const pane = 'main';
export const order = 45;

const eq = (a: string, b: string) => a === b;

export default class ShellGallery extends Component {
  @tracked selected = 'Toolbox';
  // undefined follows the window's width
  @tracked collapsed?: true;
  @tracked closed = false;
  @tracked minimised = false;
  @tracked zoomed = false;

  pick = (title: string, event: MouseEvent) => {
    event.preventDefault();
    this.selected = title;
  };
  toggle = () => (this.collapsed = this.collapsed ? undefined : true);
  close = () => (this.closed = true);
  reopen = () => (this.closed = false);
  minimise = () => (this.minimised = !this.minimised);
  zoom = () => (this.zoomed = !this.zoomed);

  <template>
    <div class="gallery-shell">
      {{#if this.closed}}
        <CanonButton @text="Reopen" @onClick={{this.reopen}} />
      {{else}}
        <CanonWindow
          class="gallery-shell-window gallery-shell-wide
            {{if this.minimised 'gallery-shell--minimised'}}
            {{if this.zoomed 'gallery-shell--zoomed'}}"
          @title="Delphi"
          @framed={{true}}
          @onClose={{this.close}}
          @onMinimise={{this.minimise}}
          @onZoom={{this.zoom}}
        >
          <:toolbar>
            <CanonButton
              @kind="cell"
              @icon={{component Icon svg=panelLeft}}
              @label="Sidebar"
              @selected={{this.collapsed}}
              aria-pressed={{if this.collapsed "true" "false"}}
              @onClick={{this.toggle}}
            />
          </:toolbar>
          <:sidebar>
            <CanonSidebar @collapsed={{this.collapsed}} aria-label="Main">
              <:hero><div class="gallery-shell-hero"><GalleryArt
                    @label="Hero"
                  /></div></:hero>
              <:default>
                <CanonSidebarRow
                  @title="Toolbox"
                  @icon={{component Icon svg=wrench}}
                  @selected={{eq this.selected "Toolbox"}}
                  @onClick={{fn this.pick "Toolbox"}}
                />
                <CanonHeading @text="Modules" />
                <CanonSidebarRow
                  @title="Clipboard"
                  @icon={{component Icon svg=clipboard}}
                  @light="on"
                  @selected={{eq this.selected "Clipboard"}}
                  @onClick={{fn this.pick "Clipboard"}}
                />
                <CanonSidebarRow
                  @title="Capture"
                  @icon={{component Icon svg=camera}}
                  @light="warning"
                  @selected={{eq this.selected "Capture"}}
                  @onClick={{fn this.pick "Capture"}}
                />
                <CanonSidebarRow
                  @title="Hotkeys"
                  @icon={{component Icon svg=keyboard}}
                  @light="off"
                  @selected={{eq this.selected "Hotkeys"}}
                  @onClick={{fn this.pick "Hotkeys"}}
                />
                <CanonSidebarRow
                  @title="Loupe"
                  @icon={{component Icon svg=aperture}}
                  @light="on"
                  @selected={{eq this.selected "Loupe"}}
                  @onClick={{fn this.pick "Loupe"}}
                />
                <CanonSidebarRow
                  @title="General"
                  @icon={{component Icon svg=settings}}
                  @href="#general"
                  @selected={{eq this.selected "General"}}
                  @onClick={{fn this.pick "General"}}
                />
              </:default>
            </CanonSidebar>
          </:sidebar>
          <:main>
            <CanonPage>
              <CanonCanvas @aspect={{3}}><GalleryArt
                  @label={{this.selected}}
                /></CanonCanvas>
            </CanonPage>
          </:main>
        </CanonWindow>
      {{/if}}
      <CanonWindow
        class="gallery-shell-window gallery-shell-narrow"
        @title="Narrow"
        @framed={{true}}
      >
        <:menubar>
          <CanonButton @kind="cell" @text="File" />
          <CanonButton @kind="cell" @text="Edit" />
          <CanonButton @kind="cell" @text="View" />
        </:menubar>
        <:sidebar>
          <CanonSidebar aria-label="Narrow">
            <CanonSidebarRow
              @title="Toolbox"
              @icon={{component Icon svg=wrench}}
              @selected={{true}}
            />
            <CanonSidebarRow
              @title="Clipboard"
              @icon={{component Icon svg=clipboard}}
              @light="on"
            />
            <CanonSidebarRow
              @title="Capture"
              @icon={{component Icon svg=camera}}
              @light="warning"
            />
            <CanonSidebarRow
              @title="Hotkeys"
              @icon={{component Icon svg=keyboard}}
              @light="off"
            />
          </CanonSidebar>
        </:sidebar>
        <:main>
          <CanonPage>
            <CanonCanvas @aspect={{2}}><GalleryArt
                @label="Rail"
              /></CanonCanvas>
          </CanonPage>
        </:main>
      </CanonWindow>
    </div>
  </template>
}
