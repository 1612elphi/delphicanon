import type { HTMLAttributes } from 'react';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-preview-panel.css';

export interface CanonPreviewPanelProps extends HTMLAttributes<HTMLElement> {
	caption: string;
	/** Trailing note in the caption row, such as the size. */
	detail?: string;
}

/** Framed preview: caption row, hairline, then the content flush beneath. */
export default function CanonPreviewPanel({
	caption,
	detail,
	className,
	children,
	...rest
}: CanonPreviewPanelProps) {
	return (
		<figure
			className={cx('canon-preview-panel', className)}
			{...rest}
		>
			<figcaption className="canon-preview-panel-header">
				<span className="canon-preview-panel-caption">
					{caption}
				</span>
				{detail && (
					<span className="canon-preview-panel-detail">
						{detail}
					</span>
				)}
			</figcaption>
			<div className="canon-preview-panel-content">
				{children}
			</div>
		</figure>
	);
}
