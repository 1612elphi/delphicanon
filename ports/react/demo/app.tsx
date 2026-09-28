import { lazy, Suspense } from 'react';
import CanonToast from '../src/components/canon-toast.tsx';
import Gallery from './gallery.tsx';

const ColourPage = lazy(() => import('./colour-page.tsx'));

// ?page=colour: the colour page, as CanonColourGalleryViewController
const colour =
  new URLSearchParams(window.location.search).get('page') === 'colour';

export default function App() {
  return (
    <>
      {colour ? (
        <Suspense>
          <ColourPage />
        </Suspense>
      ) : (
        <Gallery />
      )}
      <CanonToast />
    </>
  );
}
