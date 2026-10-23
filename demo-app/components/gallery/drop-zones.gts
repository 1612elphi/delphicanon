import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import CanonDropZone from '#src/components/canon-drop-zone.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonStatus from '#src/components/canon-status.gts';
import Icon from '../icon.gts';
import file from 'lucide-static/icons/file.svg?raw';

export const pane = 'main';
export const order = 25;

const dropPrompt = 'Drop an image here';

export default class DropZones extends Component {
	@tracked imported = 'None';

	showImages = (images: ImageBitmap[], names: string[]) => {
		const [image] = images;
		if (image)
			this.imported =
				`${names[0] ?? ''} ${image.width} x ${image.height}`.trim();
	};

	showFiles = (files: File[]) => {
		this.imported = files.map((f) => f.name).join(', ');
	};

	<template>
		<CanonRows @framed={{true}}>
			<CanonHeading @text="Drop zones" />
			<CanonDropZone
				@prompt={{dropPrompt}}
				@onImages={{this.showImages}}
			/>
			<CanonStatus
				@text={{this.imported}}
				@tone="muted"
				@row={{true}}
			/>
			<CanonDropZone
				@prompt={{dropPrompt}}
				@icon={{component Icon svg=file}}
				@accept=""
				@multiple={{true}}
				@paste={{false}}
				@onFiles={{this.showFiles}}
			/>
		</CanonRows>
	</template>
}
