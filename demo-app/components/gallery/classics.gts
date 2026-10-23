import Component from '@glimmer/component';
import { service } from '@ember/service';
import CanonButton from '#src/components/canon-button.gts';
import CanonGrid from '#src/components/canon-grid.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonRows from '#src/components/canon-rows.gts';
import type CanonToastService from '#src/services/canon-toast.ts';
import Icon from '../icon.gts';
import copy from 'lucide-static/icons/copy.svg?raw';
import eraser from 'lucide-static/icons/eraser.svg?raw';
import messageSquareCheck from 'lucide-static/icons/message-square-check.svg?raw';
import play from 'lucide-static/icons/play.svg?raw';
import repeat from 'lucide-static/icons/repeat.svg?raw';
import rotateCw from 'lucide-static/icons/rotate-cw.svg?raw';
import share from 'lucide-static/icons/share.svg?raw';
import shuffle from 'lucide-static/icons/shuffle.svg?raw';
import square from 'lucide-static/icons/square.svg?raw';
import trash from 'lucide-static/icons/trash-2.svg?raw';

export const pane = 'main';
export const order = 20;

export default class Classics extends Component {
	@service('canon-toast') declare toast: CanonToastService;

	showToast = () => this.toast.show('#3B82F6');

	<template>
		<CanonRows @framed={{true}}>
			<CanonHeading @text="Classics" />
			<CanonButton
				@text="Generate"
				@icon={{component Icon svg=rotateCw}}
				@kind="primary"
			/>
			<CanonGrid>
				<CanonButton
					@text="Copy"
					@icon={{component Icon svg=copy}}
				/>
				<CanonButton
					@text="Export"
					@icon={{component Icon svg=share}}
					@kind="primary"
				/>
			</CanonGrid>
			<CanonButton
				@text="Generate"
				@icon={{component Icon svg=rotateCw}}
				@iconStyle="oversized"
				@kind="primary"
			/>
			<CanonGrid>
				<CanonButton
					@text="Wipe"
					@icon={{component Icon svg=eraser}}
					@iconStyle="oversized"
				/>
				<CanonButton
					@text="Copy"
					@icon={{component Icon svg=copy}}
					@iconStyle="oversized"
				/>
				<CanonButton
					@text="Export"
					@icon={{component Icon svg=share}}
					@iconStyle="oversized"
					@kind="primary"
				/>
			</CanonGrid>
			<CanonGrid>
				<CanonButton
					@text="Loop"
					@icon={{component Icon svg=repeat}}
				/>
				<CanonButton
					@text="Play"
					@icon={{component Icon svg=play}}
					@kind="primary"
				/>
				<CanonButton
					@text="Stop"
					@icon={{component Icon svg=square}}
				/>
				<CanonButton
					@text="Shuffle"
					@icon={{component Icon svg=shuffle}}
				/>
				<CanonButton
					@text="Export"
					@icon={{component Icon svg=share}}
				/>
				<CanonButton
					@text="Delete"
					@icon={{component Icon svg=trash}}
				/>
			</CanonGrid>
			<CanonButton
				@text="Toast"
				@icon={{component Icon svg=messageSquareCheck}}
				@onClick={{this.showToast}}
			/>
			<CanonButton
				@text="Copy"
				@icon={{component Icon svg=copy}}
				@flashesCopied={{true}}
			/>
		</CanonRows>
	</template>
}
