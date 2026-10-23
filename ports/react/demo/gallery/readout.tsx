import CanonCanvas from '../../src/components/canon-canvas.tsx';
import CanonReadoutBand, {
	readoutBandHeight,
} from '../../src/components/canon-readout-band.tsx';
import type { CanonLamp } from '../../src/components/canon-lamps.tsx';
import GalleryArt from '../gallery-art.tsx';
import '../../../../demo-app/components/gallery/display.css';

export const pane = 'main';
export const order = 12;

const over = { playhead: 83.4, playing: true, looping: true };
const below = { playhead: 1, paused: true };
const recording = { playhead: 4.2, playing: true, recording: true };
const recordLamps: CanonLamp[] = ['record', 'pause'];
const smpte = () => '01:02:03:04';
const belowHeight = readoutBandHeight(56);

export default function Readout() {
	return (
		<>
			<CanonCanvas height={120}>
				<CanonReadoutBand transport={over}>
					<GalleryArt label="Readout over" />
				</CanonReadoutBand>
			</CanonCanvas>
			<CanonCanvas height={belowHeight}>
				<CanonReadoutBand
					transport={below}
					readout="below"
					format={smpte}
				>
					<GalleryArt label="Readout below" />
				</CanonReadoutBand>
			</CanonCanvas>
			<CanonCanvas height={120}>
				<CanonReadoutBand
					transport={recording}
					lamps={recordLamps}
				>
					<GalleryArt label="Record lamp" />
				</CanonReadoutBand>
			</CanonCanvas>
		</>
	);
}
