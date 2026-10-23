import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import CanonJumpGrid, { type CanonJumpSection } from './canon-jump-grid.gts';
import press from '../modifiers/canon-press.ts';
import { litIndex } from '../lib/jump.ts';
import { reducedMotion } from '../lib/motion.ts';
import '../styles/tokens.css';
import './canon-heading.css';
import './canon-jump-heading.css';

export interface CanonJumpHeadingSignature {
	Args: {
		text: string;
		/** Under the group's title in the jump grid: its item count. */
		detail?: string;
	};
	Element: HTMLHeadingElement;
}

function scroller(element: HTMLElement): HTMLElement {
	for (let at = element.parentElement; at; at = at.parentElement) {
		const style = getComputedStyle(at);
		// a display: contents pane has no box of its own
		if (
			style.display !== 'contents' &&
			/auto|scroll/.test(style.overflowY)
		)
			return at;
	}
	return document.documentElement;
}

/**
 * A CanonHeading with a chevron that opens a CanonJumpGrid of every jump
 * heading in the same scrolling box, lit at the group in view; a pick
 * scrolls that heading to the top and focuses it.
 */
export default class CanonJumpHeading extends Component<CanonJumpHeadingSignature> {
	@tracked sections?: CanonJumpSection[];
	@tracked current = 0;
	headings: HTMLElement[] = [];

	show = (event: MouseEvent) => {
		const heading = (
			event.currentTarget as HTMLElement
		).closest<HTMLElement>('.canon-jump-heading')!;
		const box = scroller(heading);
		const top =
			box === document.documentElement
				? 0
				: box.getBoundingClientRect().top;
		this.headings = [
			...box.querySelectorAll<HTMLElement>(
				'.canon-jump-heading',
			),
		];
		this.current = litIndex(
			this.headings.map((h) => h.getBoundingClientRect().top),
			top,
		);
		this.sections = this.headings.map((h) => ({
			title: h.dataset['canonJumpTitle'] ?? '',
			detail: h.dataset['canonJumpDetail'],
		}));
	};

	closed = () => {
		this.sections = undefined;
	};

	pick = (index: number) => {
		const target = this.headings[index];
		if (!target?.isConnected) return;
		target.scrollIntoView({
			block: 'start',
			behavior: reducedMotion() ? 'instant' : 'smooth',
		});
		target.querySelector('button')?.focus({ preventScroll: true });
	};

	<template>
		<h3
			class="canon-heading canon-jump-heading"
			data-canon-jump-title={{@text}}
			data-canon-jump-detail={{@detail}}
			...attributes
		>
			<button
				type="button"
				class="canon-jump-heading-button"
				aria-haspopup="dialog"
				aria-expanded={{if
					this.sections
					"true"
					"false"
				}}
				{{press}}
				{{on "click" this.show}}
			>{{@text}}<span
					class="canon-jump-heading-chevron"
					aria-hidden="true"
				>›</span></button>
		</h3>
		{{#if this.sections}}
			<CanonJumpGrid
				@open={{true}}
				@sections={{this.sections}}
				@current={{this.current}}
				@onPick={{this.pick}}
				@onClose={{this.closed}}
			/>
		{{/if}}
	</template>
}
