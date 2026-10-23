import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import CanonCanvas from '#src/components/canon-canvas.gts';
import CanonGlyphFlow from '#src/components/canon-glyph-flow.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonTextInput from '#src/components/canon-text-input.gts';
import CanonTextOutput from '#src/components/canon-text-output.gts';
import type { GlyphKind } from '#src/lib/glyph-rows.ts';
import './display.css';

export const pane = 'main';
export const order = 30;

const start = 'Glyph flow';
const metrics = { height: 36, rowGap: 8, gap: 4 };
const measure = () => 28;
const kind = (c: string): GlyphKind =>
	c === '\n' ? 'newline' : /\s/.test(c) ? 'space' : 'glyph';
const isSpace = (c: string) => /\s/.test(c);

export default class Text extends Component {
	@tracked text = start;

	get glyphs() {
		return [...this.text];
	}

	get upper() {
		return this.text.toUpperCase();
	}

	change = (text: string) => {
		this.text = text;
	};

	<template>
		<CanonCanvas @height={{120}}>
			<CanonGlyphFlow
				@glyphs={{this.glyphs}}
				@metrics={{metrics}}
				@measure={{measure}}
				@kind={{kind}}
				@label={{this.text}}
				as |glyph|
			>
				{{#unless (isSpace glyph)}}
					<span
						class="gallery-glyph"
					>{{glyph}}</span>
				{{/unless}}
			</CanonGlyphFlow>
		</CanonCanvas>
		<CanonRows @framed={{true}}>
			<CanonHeading @text="Text input" />
			<CanonTextInput
				@value={{start}}
				@onChange={{this.change}}
			/>
		</CanonRows>
		<CanonTextOutput
			@text={{this.upper}}
			@heading="Text output"
			@fileName="gallery.txt"
		/>
	</template>
}
