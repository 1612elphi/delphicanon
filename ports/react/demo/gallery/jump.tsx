import CanonJumpHeading from '../../src/components/canon-jump-heading.tsx';
import CanonRow from '../../src/components/canon-row.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import CanonSwitch from '../../src/components/canon-switch.tsx';

export const pane = 'sidebar';
export const order = 45;

export default function Jump() {
	return (
		<CanonRows framed>
			<CanonJumpHeading text="Rows" detail="2" />
			<CanonRow title="Plain">
				{(titleId) => (
					<CanonSwitch
						on
						aria-labelledby={titleId}
					/>
				)}
			</CanonRow>
			<CanonRow title="No control" />
			<CanonJumpHeading text="Components" detail="2" />
			<CanonRow title="Images">
				{(titleId) => (
					<CanonSwitch
						on
						aria-labelledby={titleId}
					/>
				)}
			</CanonRow>
			<CanonRow title="Files">
				{(titleId) => (
					<CanonSwitch
						aria-labelledby={titleId}
					/>
				)}
			</CanonRow>
			<CanonJumpHeading text="Big number" detail="1" />
			<CanonRow title="Sound">
				{(titleId) => (
					<CanonSwitch
						aria-labelledby={titleId}
					/>
				)}
			</CanonRow>
		</CanonRows>
	);
}
