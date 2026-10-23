import CanonButton from '../../src/components/canon-button.tsx';
import CanonGrid from '../../src/components/canon-grid.tsx';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonIcon from '../../src/components/canon-icon.tsx';
import CanonRow from '../../src/components/canon-row.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import moveHorizontal from 'lucide-static/icons/move-horizontal.svg?raw';
import zoomIn from 'lucide-static/icons/zoom-in.svg?raw';
import zoomOut from 'lucide-static/icons/zoom-out.svg?raw';

export const pane = 'sidebar';
export const order = 30;

export default function Grid() {
	return (
		<CanonRows framed>
			<CanonHeading text="Grid" />
			<CanonRow title="Actions" form="stacked">
				<CanonGrid>
					<CanonButton text="Cancel" />
					<CanonButton
						text="Apply"
						kind="primary"
					/>
				</CanonGrid>
			</CanonRow>
			<CanonRow title="Inline actions" form="flush">
				<CanonGrid>
					<CanonButton
						text="Cancel"
						kind="cell"
					/>
					<CanonButton text="Apply" kind="cell" />
					<CanonButton
						text="Disabled"
						kind="cell"
						disabled
					/>
				</CanonGrid>
			</CanonRow>
			<CanonRow
				title="Icon actions"
				detail="3.60 – 6.00"
				form="flush"
			>
				<CanonGrid>
					<CanonButton
						kind="cell"
						icon={
							<CanonIcon
								svg={zoomOut}
							/>
						}
						label="Zoom out"
					/>
					<CanonButton
						kind="cell"
						icon={
							<CanonIcon
								svg={zoomIn}
							/>
						}
						label="Zoom in"
					/>
					<CanonButton
						kind="cell"
						icon={
							<CanonIcon
								svg={
									moveHorizontal
								}
							/>
						}
						label="Fit width"
					/>
				</CanonGrid>
			</CanonRow>
		</CanonRows>
	);
}
