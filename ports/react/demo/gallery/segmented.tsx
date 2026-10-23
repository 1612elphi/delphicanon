import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonIcon from '../../src/components/canon-icon.tsx';
import CanonRow from '../../src/components/canon-row.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import CanonSegmented from '../../src/components/canon-segmented.tsx';
import arrowDown from 'lucide-static/icons/arrow-down.svg?raw';
import arrowDownLeft from 'lucide-static/icons/arrow-down-left.svg?raw';
import arrowDownRight from 'lucide-static/icons/arrow-down-right.svg?raw';
import arrowLeft from 'lucide-static/icons/arrow-left.svg?raw';
import arrowRight from 'lucide-static/icons/arrow-right.svg?raw';
import arrowUp from 'lucide-static/icons/arrow-up.svg?raw';
import arrowUpLeft from 'lucide-static/icons/arrow-up-left.svg?raw';
import arrowUpRight from 'lucide-static/icons/arrow-up-right.svg?raw';
import circleDot from 'lucide-static/icons/circle-dot.svg?raw';

export const pane = 'sidebar';
export const order = 20;

const modes = ['Region', 'Window', 'Screen', 'Timed'];
const five = ['One', 'Two', 'Three', 'Four', 'Five'];
const sizes = ['Tiny', 'Base', 'Small', 'Large'];
const labels = [
	'Top left',
	'Top',
	'Top right',
	'Left',
	'Centre',
	'Right',
	'Bottom left',
	'Bottom',
	'Bottom right',
];
const arrows = [
	arrowUpLeft,
	arrowUp,
	arrowUpRight,
	arrowLeft,
	circleDot,
	arrowRight,
	arrowDownLeft,
	arrowDown,
	arrowDownRight,
].map((svg) => <CanonIcon key={svg} svg={svg} />);

export default function Segmented() {
	return (
		<CanonRows framed>
			<CanonHeading text="Segmented" />
			<CanonRow title="Mode" form="stacked">
				<CanonSegmented items={modes} />
			</CanonRow>
			<CanonRow title="Six in three" form="stacked">
				<CanonSegmented items={five} columns={3} />
			</CanonRow>
			<CanonRow title="Inline picker" form="flush">
				<CanonSegmented items={modes} />
			</CanonRow>
			<CanonSegmented
				items={sizes}
				selected={1}
				disabledIndices={[2, 3]}
			/>
			<CanonRow title="Symbols" form="stacked">
				<CanonSegmented
					items={labels}
					icons={arrows}
					selected={7}
					columns={3}
				/>
			</CanonRow>
		</CanonRows>
	);
}
