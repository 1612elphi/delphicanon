import CanonButton from '#src/components/canon-button.gts';
import CanonGrid from '#src/components/canon-grid.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import Icon from '../icon.gts';
import moveHorizontal from 'lucide-static/icons/move-horizontal.svg?raw';
import zoomIn from 'lucide-static/icons/zoom-in.svg?raw';
import zoomOut from 'lucide-static/icons/zoom-out.svg?raw';

export const pane = 'sidebar';
export const order = 30;

<template>
	<CanonRows @framed={{true}}>
		<CanonHeading @text="Grid" />
		<CanonRow @title="Actions" @form="stacked">
			<CanonGrid>
				<CanonButton @text="Cancel" />
				<CanonButton @text="Apply" @kind="primary" />
			</CanonGrid>
		</CanonRow>
		<CanonRow @title="Inline actions" @form="flush">
			<CanonGrid>
				<CanonButton @text="Cancel" @kind="cell" />
				<CanonButton @text="Apply" @kind="cell" />
				<CanonButton
					@text="Disabled"
					@kind="cell"
					@disabled={{true}}
				/>
			</CanonGrid>
		</CanonRow>
		<CanonRow
			@title="Icon actions"
			@detail="3.60 – 6.00"
			@form="flush"
		>
			<CanonGrid>
				<CanonButton
					@kind="cell"
					@icon={{component Icon svg=zoomOut}}
					@label="Zoom out"
				/>
				<CanonButton
					@kind="cell"
					@icon={{component Icon svg=zoomIn}}
					@label="Zoom in"
				/>
				<CanonButton
					@kind="cell"
					@icon={{component
						Icon
						svg=moveHorizontal
					}}
					@label="Fit width"
				/>
			</CanonGrid>
		</CanonRow>
	</CanonRows>
</template>
