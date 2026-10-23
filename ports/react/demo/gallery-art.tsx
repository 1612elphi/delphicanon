/** Stand-in canvas content: a gradient with a centred label. */
export default function GalleryArt({ label }: { label: string }) {
	return (
		<div className="gallery-art">
			<span>{label}</span>
		</div>
	);
}
