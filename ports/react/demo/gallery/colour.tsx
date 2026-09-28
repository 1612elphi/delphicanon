import { useState } from 'react';
import type { Rgb } from '@canon/lib/colour.ts';
import CanonColourWell from '../../src/components/canon-colour-well.tsx';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';

export const pane = 'main';
export const order = 40;

export default function ColourGallery() {
  const [foreground, setForeground] = useState<Rgb>([0.118, 0.4, 0.149]);
  const [orange, setOrange] = useState<Rgb>([1, 0.584, 0]);
  return (
    <CanonRows framed>
      <CanonHeading text="Wells" />
      <CanonColourWell
        label="Foreground"
        colour={foreground}
        format="oklch"
        onChange={setForeground}
      />
      <CanonColourWell colour={orange} onChange={setOrange} />
    </CanonRows>
  );
}
