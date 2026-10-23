import type { HTMLAttributes, MouseEvent, ReactNode, Ref } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-sidebar-row.css';

/** neutral: no state. off: disabled module. on and warning light the leading edge. */
export type CanonSidebarLight = 'neutral' | 'off' | 'on' | 'warning';

export interface CanonSidebarRowProps extends Omit<
	HTMLAttributes<HTMLElement>,
	'title' | 'onClick' | 'children'
> {
	title: string;
	/** Rendered in the 44 px icon cell; the consumer supplies it. */
	icon?: ReactNode;
	/** Default neutral. */
	light?: CanonSidebarLight;
	/** The current page: filled in primary, `aria-current="page"`. */
	selected?: boolean;
	/** Makes the row a link; without it the row is a button. */
	href?: string;
	onClick?: (
		event: MouseEvent<HTMLAnchorElement | HTMLButtonElement>,
	) => void;
	ref?: Ref<HTMLAnchorElement | HTMLButtonElement>;
}

/** One navigation row of a CanonSidebar: an icon cell and a title cell (SidebarRow). */
export default function CanonSidebarRow({
	title,
	icon,
	light = 'neutral',
	selected,
	href,
	onClick,
	className,
	ref,
	...rest
}: CanonSidebarRowProps) {
	const shared = {
		className: cx(
			'canon-sidebar-row',
			`canon-sidebar-row--${light}`,
			className,
		),
		'aria-current': selected ? ('page' as const) : undefined,
		onClick,
	};
	const content = (
		<>
			<span
				className="canon-sidebar-row-icon"
				aria-hidden="true"
			>
				{icon}
			</span>
			<span className="canon-sidebar-row-title">{title}</span>
		</>
	);
	return href ? (
		<a
			href={href}
			{...shared}
			ref={ref as Ref<HTMLAnchorElement>}
			{...rest}
		>
			{content}
		</a>
	) : (
		<button
			type="button"
			{...shared}
			ref={ref as Ref<HTMLButtonElement>}
			{...rest}
		>
			{content}
		</button>
	);
}
