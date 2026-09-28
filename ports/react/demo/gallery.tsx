import CanonButton from '../src/components/canon-button.tsx';
import CanonCanvas from '../src/components/canon-canvas.tsx';
import CanonGrid from '../src/components/canon-grid.tsx';
import CanonIcon from '../src/components/canon-icon.tsx';
import CanonSplit from '../src/components/canon-split.tsx';
import GalleryArt from './gallery-art.tsx';
import play from 'lucide-static/icons/play.svg?raw';
import repeat from 'lucide-static/icons/repeat.svg?raw';
import square from 'lucide-static/icons/square.svg?raw';
// last: Vite hoists an eager glob above the imports, and the groups' CSS must follow CanonSplit's
import { groups } from './groups.ts';

const sidebar = groups.filter((g) => g.pane === 'sidebar');
const main = groups.filter((g) => g.pane === 'main');

// ?halves: equal panes without a crease, as -galleryHalves on iOS
const halves = new URLSearchParams(window.location.search).has('halves');

/** The port of CanonGalleryViewController: one split, groups from ./gallery/. */
export default function Gallery() {
  return (
    <CanonSplit
      className="gallery"
      halves={halves}
      banner={
        <CanonCanvas height={120}>
          <GalleryArt label="All columns" />
        </CanonCanvas>
      }
      sidebar={sidebar.map(({ name, default: Group }) => (
        <Group key={name} />
      ))}
      main={main.map(({ name, default: Group }) => (
        <Group key={name} />
      ))}
      footer={
        <CanonGrid>
          <CanonButton text="Loop" icon={<CanonIcon svg={repeat} />} />
          <CanonButton
            text="Play"
            icon={<CanonIcon svg={play} />}
            kind="primary"
          />
          <CanonButton text="Stop" icon={<CanonIcon svg={square} />} />
        </CanonGrid>
      }
    />
  );
}
