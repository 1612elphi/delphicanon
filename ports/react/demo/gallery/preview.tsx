import CanonPreviewPanel from '../../src/components/canon-preview-panel.tsx';

export const pane = 'main';
export const order = 5;

export default function Preview() {
	return (
		<CanonPreviewPanel caption="Preview" detail="1600 x 900">
			<div className="gallery-swatch" />
		</CanonPreviewPanel>
	);
}
