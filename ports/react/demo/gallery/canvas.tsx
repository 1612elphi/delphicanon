import { useState } from 'react';
import CanonCanvas from '../../src/components/canon-canvas.tsx';
import GalleryArt from '../gallery-art.tsx';

export const pane = 'main';
export const order = 10;

export default function Canvas() {
	const [lines, setLines] = useState(1);
	return (
		<>
			<CanonCanvas aspect={4}>
				<GalleryArt label="Column canvas" />
			</CanonCanvas>
			<CanonCanvas fitting animated>
				<button
					type="button"
					className="gallery-fit"
					onClick={() =>
						setLines((lines % 4) + 1)
					}
				>
					{Array.from(
						{ length: lines },
						(_, i) => (
							<span key={i}>
								Line {i + 1}
							</span>
						),
					)}
				</button>
			</CanonCanvas>
			<CanonCanvas aspect={4} boxing="unlessWide">
				<GalleryArt label="Boxed unless wide" />
			</CanonCanvas>
		</>
	);
}
