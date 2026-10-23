import { useState } from 'react';
import CanonDropZone from '../../src/components/canon-drop-zone.tsx';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonIcon from '../../src/components/canon-icon.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import CanonStatus from '../../src/components/canon-status.tsx';
import file from 'lucide-static/icons/file.svg?raw';

export const pane = 'main';
export const order = 25;

const dropPrompt = 'Drop an image here';

export default function DropZones() {
	const [imported, setImported] = useState('None');

	const showImages = (images: ImageBitmap[], names: string[]) => {
		const [image] = images;
		if (image)
			setImported(
				`${names[0] ?? ''} ${image.width} x ${image.height}`.trim(),
			);
	};

	const showFiles = (files: File[]) =>
		setImported(files.map((f) => f.name).join(', '));

	return (
		<CanonRows framed>
			<CanonHeading text="Drop zones" />
			<CanonDropZone
				prompt={dropPrompt}
				onImages={showImages}
			/>
			<CanonStatus text={imported} tone="muted" row />
			<CanonDropZone
				prompt={dropPrompt}
				icon={<CanonIcon svg={file} />}
				accept=""
				multiple
				paste={false}
				onFiles={showFiles}
			/>
		</CanonRows>
	);
}
