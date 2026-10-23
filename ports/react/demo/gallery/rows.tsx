import CanonBar from '../../src/components/canon-bar.tsx';
import CanonEmptyRow from '../../src/components/canon-empty-row.tsx';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonIcon from '../../src/components/canon-icon.tsx';
import CanonRow from '../../src/components/canon-row.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import bug from 'lucide-static/icons/bug.svg?raw';

export const pane = 'sidebar';
export const order = 10;

const detailCaption = 'Caption under the title';

export default function Rows() {
	return (
		<CanonRows framed>
			<CanonHeading text="Rows" />
			<CanonRow title="Plain">
				<CanonBar
					className="gallery-bar"
					share={0.65}
				/>
			</CanonRow>
			<CanonRow
				title="Detail and icon"
				icon={<CanonIcon svg={bug} />}
				detail={detailCaption}
			>
				<CanonBar className="gallery-bar" share={0.3} />
			</CanonRow>
			<CanonRow title="No control" />
			<CanonEmptyRow text="Nothing here" />
		</CanonRows>
	);
}
