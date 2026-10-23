import { useId, type HTMLAttributes, type ReactNode } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-window.css';

export interface CanonWindowProps extends Omit<
	HTMLAttributes<HTMLElement>,
	'title' | 'children'
> {
	title?: string;
	/** Any of the three shows all three controls; one without a callback is disabled. */
	onClose?: () => void;
	onMinimise?: () => void;
	onZoom?: () => void;
	/** Draws the 2 px tool frame around the window. */
	framed?: boolean;
	/** Trailing controls in the title bar. */
	toolbar?: ReactNode;
	/** A strip under the title bar. */
	menubar?: ReactNode;
	/** A CanonSidebar; it collapses to its rail when the body is narrower than 640 px. */
	sidebar?: ReactNode;
	/** The detail: a CanonPage or CanonSplit fills it. */
	main?: ReactNode;
}

const given = (node: ReactNode) => node !== undefined && node !== null;

/**
 * Desktop-style window chrome (MainWindow): a title bar, an optional menu
 * bar, then the sidebar beside the detail. Fills its container.
 */
export default function CanonWindow({
	title,
	onClose,
	onMinimise,
	onZoom,
	framed,
	toolbar,
	menubar,
	sidebar,
	main,
	className,
	...rest
}: CanonWindowProps) {
	const titleId = `${useId()}-title`;
	const controls =
		onClose !== undefined ||
		onMinimise !== undefined ||
		onZoom !== undefined;
	return (
		<section
			className={cx(
				'canon-window',
				framed && 'canon-window--framed',
				className,
			)}
			aria-labelledby={title ? titleId : undefined}
			{...rest}
		>
			<header className="canon-window-bar">
				{controls && (
					<div className="canon-window-controls">
						<button
							type="button"
							className="canon-window-control canon-window-control--close"
							aria-label="Close"
							disabled={!onClose}
							onClick={() =>
								onClose?.()
							}
						></button>
						<button
							type="button"
							className="canon-window-control canon-window-control--minimise"
							aria-label="Minimise"
							disabled={!onMinimise}
							onClick={() =>
								onMinimise?.()
							}
						></button>
						<button
							type="button"
							className="canon-window-control canon-window-control--zoom"
							aria-label="Zoom"
							disabled={!onZoom}
							onClick={() =>
								onZoom?.()
							}
						></button>
					</div>
				)}
				<div
					className="canon-window-title"
					id={titleId}
				>
					{title}
				</div>
				{given(toolbar) && (
					<div className="canon-window-toolbar">
						{toolbar}
					</div>
				)}
			</header>
			{given(menubar) && (
				<div className="canon-window-menubar">
					{menubar}
				</div>
			)}
			<div className="canon-window-body">
				{sidebar}
				<div className="canon-window-main">{main}</div>
			</div>
		</section>
	);
}
