import { useState } from 'react';
import type { CanonPlacement } from '@canon/lib/popover.ts';
import CanonButton from '../../src/components/canon-button.tsx';
import CanonCanvas from '../../src/components/canon-canvas.tsx';
import CanonContextMenu from '../../src/components/canon-context-menu.tsx';
import CanonGrid from '../../src/components/canon-grid.tsx';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonIcon from '../../src/components/canon-icon.tsx';
import CanonMenu, {
  type CanonMenuEntry,
  type CanonMenuItem,
} from '../../src/components/canon-menu.tsx';
import CanonMenuBar, {
  type CanonMenuBarMenu,
} from '../../src/components/canon-menu-bar.tsx';
import CanonPopover from '../../src/components/canon-popover.tsx';
import CanonRow from '../../src/components/canon-row.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import CanonSegmented from '../../src/components/canon-segmented.tsx';
import CanonSlider from '../../src/components/canon-slider.tsx';
import CanonTooltip from '../../src/components/canon-tooltip.tsx';
import GalleryArt from '../gallery-art.tsx';
import chevronDown from 'lucide-static/icons/chevron-down.svg?raw';
import copy from 'lucide-static/icons/copy.svg?raw';
import pencil from 'lucide-static/icons/pencil.svg?raw';
import share from 'lucide-static/icons/share.svg?raw';
import trash from 'lucide-static/icons/trash-2.svg?raw';

import '../../../../demo-app/components/gallery/menus.css';

export const pane = 'main';
export const order = 21;

const rule = { kind: 'separator' } as const;
const sides = ['Top', 'Right', 'Bottom', 'Left'];
const edges = ['Start', 'Centre', 'End'];
const sizes = ['Small', 'Medium', 'Large'];
const tips = [
  { text: 'Copy', svg: copy },
  { text: 'Share', svg: share },
  { text: 'Delete', svg: trash },
];

export default function Menus() {
  const [chosen, setChosen] = useState('—');
  const [grid, setGrid] = useState(true);
  const [snap, setSnap] = useState(false);
  const [rulers, setRulers] = useState(false);
  const [size, setSize] = useState('Medium');
  const [side, setSide] = useState(2);
  const [edge, setEdge] = useState(0);
  const [opacity, setOpacity] = useState(0.8);

  const placement =
    `${['top', 'right', 'bottom', 'left'][side]}${['-start', '', '-end'][edge]}` as CanonPlacement;

  const items: CanonMenuEntry[] = [
    { title: 'Duplicate', icon: <CanonIcon svg={copy} />, shortcut: '⌘D' },
    { title: 'Rename…', icon: <CanonIcon svg={pencil} /> },
    {
      title: 'Share',
      icon: <CanonIcon svg={share} />,
      items: [
        { title: 'Copy link' },
        { title: 'Email' },
        { title: 'Messages' },
      ],
    },
    rule,
    { title: 'Grid', kind: 'checkbox', checked: grid, shortcut: "⌘'" },
    { title: 'Snap', kind: 'checkbox', checked: snap },
    rule,
    ...sizes.map((title) => ({
      title,
      kind: 'radio' as const,
      checked: size === title,
    })),
    rule,
    { title: 'Rasterise', disabled: true },
    {
      title: 'Delete',
      icon: <CanonIcon svg={trash} />,
      destructive: true,
      shortcut: '⌫',
    },
  ];

  const menus: CanonMenuBarMenu[] = [
    {
      title: 'File',
      items: [
        { title: 'New', shortcut: '⌘N' },
        { title: 'Open…', shortcut: '⌘O' },
        {
          title: 'Open recent',
          items: [{ title: 'Poster.pdf' }, { title: 'Letter.pdf' }],
        },
        rule,
        { title: 'Close', shortcut: '⌘W' },
      ],
    },
    {
      title: 'Edit',
      items: [
        { title: 'Undo', shortcut: '⌘Z' },
        { title: 'Redo', shortcut: '⇧⌘Z', disabled: true },
        rule,
        { title: 'Cut', shortcut: '⌘X' },
        { title: 'Copy', shortcut: '⌘C' },
        { title: 'Paste', shortcut: '⌘V' },
      ],
    },
    {
      title: 'View',
      items: [
        { title: 'Grid', kind: 'checkbox', checked: grid },
        { title: 'Rulers', kind: 'checkbox', checked: rulers },
        rule,
        {
          title: 'Zoom',
          items: [
            { title: 'Zoom in', shortcut: '⌘+' },
            { title: 'Zoom out', shortcut: '⌘−' },
            { title: 'Fit', shortcut: '⌘0' },
          ],
        },
      ],
    },
    { title: 'Help', items: [{ title: 'About' }] },
  ];

  const choose = (item: CanonMenuItem) => {
    setChosen(item.title);
    if (item.title === 'Grid') setGrid(!grid);
    if (item.title === 'Snap') setSnap(!snap);
    if (item.title === 'Rulers') setRulers(!rulers);
    if (item.kind === 'radio') setSize(item.title);
  };

  return (
    <>
      <CanonRows framed>
        <CanonHeading text="Menus" />
        <CanonMenuBar aria-label="Gallery" menus={menus} onSelect={choose} />
        <CanonRow title="Dropdown" form="flush">
          <CanonMenu items={items} onSelect={choose}>
            {(menu) => (
              <CanonButton
                ref={menu.trigger}
                kind="cell"
                text="Actions"
                icon={<CanonIcon svg={chevronDown} />}
              />
            )}
          </CanonMenu>
        </CanonRow>
        <CanonRow title="Chosen" detail={chosen} />
      </CanonRows>
      <CanonContextMenu
        className="gallery-context-area"
        tabIndex={0}
        aria-label="Context area"
        items={items}
        onSelect={choose}
      >
        <CanonCanvas height={160}>
          <GalleryArt label="Right click" />
        </CanonCanvas>
      </CanonContextMenu>
      <CanonRows framed>
        <CanonHeading text="Popover" />
        <CanonRow title="Side" form="stacked">
          <CanonSegmented items={sides} selected={side} onChange={setSide} />
        </CanonRow>
        <CanonRow title="Edge" form="stacked">
          <CanonSegmented items={edges} selected={edge} onChange={setEdge} />
        </CanonRow>
        <CanonGrid>
          <CanonPopover
            className="gallery-popover"
            role="dialog"
            aria-label="Opacity"
            placement={placement}
            trigger={(popover) => (
              <CanonButton ref={popover.trigger} kind="cell" text="Popover" />
            )}
            content={(popover) => (
              <CanonRows>
                <CanonRow title="Opacity" form="stacked">
                  <CanonSlider
                    value={opacity}
                    label="Opacity"
                    onChange={setOpacity}
                  />
                </CanonRow>
                <CanonButton
                  kind="primary"
                  text="Done"
                  onClick={popover.close}
                />
              </CanonRows>
            )}
          />
          {tips.map(({ text, svg }) => (
            <CanonTooltip key={text} text={text} placement={placement}>
              {(tip) => (
                <CanonButton
                  ref={tip.trigger}
                  kind="cell"
                  label={text}
                  icon={<CanonIcon svg={svg} />}
                />
              )}
            </CanonTooltip>
          ))}
        </CanonGrid>
      </CanonRows>
    </>
  );
}
