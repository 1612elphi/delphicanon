import { useState } from 'react';
import CanonButton from '../../src/components/canon-button.tsx';
import CanonCanvas from '../../src/components/canon-canvas.tsx';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonIcon from '../../src/components/canon-icon.tsx';
import CanonMenuBar, {
  type CanonMenuBarMenu,
} from '../../src/components/canon-menu-bar.tsx';
import CanonPage from '../../src/components/canon-page.tsx';
import CanonSidebar from '../../src/components/canon-sidebar.tsx';
import CanonSidebarRow, {
  type CanonSidebarLight,
} from '../../src/components/canon-sidebar-row.tsx';
import CanonWindow from '../../src/components/canon-window.tsx';
import { cx } from '../../src/lib/class-names.ts';
import GalleryArt from '../gallery-art.tsx';
import aperture from 'lucide-static/icons/aperture.svg?raw';
import camera from 'lucide-static/icons/camera.svg?raw';
import clipboard from 'lucide-static/icons/clipboard.svg?raw';
import keyboard from 'lucide-static/icons/keyboard.svg?raw';
import panelLeft from 'lucide-static/icons/panel-left.svg?raw';
import settings from 'lucide-static/icons/settings.svg?raw';
import wrench from 'lucide-static/icons/wrench.svg?raw';

import '../../../../demo-app/components/gallery/shell.css';

export const pane = 'main';
export const order = 45;

const menus: CanonMenuBarMenu[] = [
  {
    title: 'File',
    items: [
      { title: 'New', shortcut: '⌘N' },
      { title: 'Close', shortcut: '⌘W' },
    ],
  },
  {
    title: 'Edit',
    items: [
      { title: 'Undo', shortcut: '⌘Z' },
      { title: 'Copy', shortcut: '⌘C' },
    ],
  },
  {
    title: 'View',
    items: [{ title: 'Sidebar', kind: 'checkbox', checked: true }],
  },
];

const modules = [
  { title: 'Clipboard', svg: clipboard, light: 'on' },
  { title: 'Capture', svg: camera, light: 'warning' },
  { title: 'Hotkeys', svg: keyboard, light: 'off' },
] as const;

export default function Shell() {
  const [selected, setSelected] = useState('Toolbox');
  // undefined follows the window's width
  const [collapsed, setCollapsed] = useState<true>();
  const [closed, setClosed] = useState(false);
  const [minimised, setMinimised] = useState(false);
  const [zoomed, setZoomed] = useState(false);

  const row = (
    title: string,
    svg: string,
    extra: { light?: CanonSidebarLight; href?: string } = {},
  ) => (
    <CanonSidebarRow
      key={title}
      title={title}
      icon={<CanonIcon svg={svg} />}
      {...extra}
      selected={selected === title}
      onClick={(event) => {
        event.preventDefault();
        setSelected(title);
      }}
    />
  );

  return (
    <div className="gallery-shell">
      {closed ? (
        <CanonButton text="Reopen" onClick={() => setClosed(false)} />
      ) : (
        <CanonWindow
          className={cx(
            'gallery-shell-window gallery-shell-wide',
            minimised && 'gallery-shell--minimised',
            zoomed && 'gallery-shell--zoomed',
          )}
          title="Delphi"
          framed
          onClose={() => setClosed(true)}
          onMinimise={() => setMinimised(!minimised)}
          onZoom={() => setZoomed(!zoomed)}
          toolbar={
            <CanonButton
              kind="cell"
              icon={<CanonIcon svg={panelLeft} />}
              label="Sidebar"
              selected={collapsed}
              aria-pressed={collapsed ? 'true' : 'false'}
              onClick={() => setCollapsed(collapsed ? undefined : true)}
            />
          }
          sidebar={
            <CanonSidebar
              collapsed={collapsed}
              aria-label="Main"
              hero={
                <div className="gallery-shell-hero">
                  <GalleryArt label="Hero" />
                </div>
              }
            >
              {row('Toolbox', wrench)}
              <CanonHeading text="Modules" />
              {modules.map(({ title, svg, light }) =>
                row(title, svg, { light }),
              )}
              {row('Loupe', aperture, { light: 'on' })}
              {row('General', settings, { href: '#general' })}
            </CanonSidebar>
          }
          main={
            <CanonPage>
              <CanonCanvas aspect={3}>
                <GalleryArt label={selected} />
              </CanonCanvas>
            </CanonPage>
          }
        />
      )}
      <CanonWindow
        className="gallery-shell-window gallery-shell-narrow"
        title="Narrow"
        framed
        menubar={<CanonMenuBar menus={menus} aria-label="Narrow" />}
        sidebar={
          <CanonSidebar aria-label="Narrow">
            <CanonSidebarRow
              title="Toolbox"
              icon={<CanonIcon svg={wrench} />}
              selected
            />
            {modules.map(({ title, svg, light }) => (
              <CanonSidebarRow
                key={title}
                title={title}
                icon={<CanonIcon svg={svg} />}
                light={light}
              />
            ))}
          </CanonSidebar>
        }
        main={
          <CanonPage>
            <CanonCanvas aspect={2}>
              <GalleryArt label="Rail" />
            </CanonCanvas>
          </CanonPage>
        }
      />
    </div>
  );
}
