import { useRef, useState, type HTMLAttributes, type Ref } from 'react';
import CanonButton from './canon-button.tsx';
import { splitForMiddle } from '@canon/lib/files.ts';
import { cx } from '../lib/class-names.ts';
import '@canon/styles/tokens.css';
import '@canon/components/canon-file-cell.css';

export interface CanonFileCellProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'onChange' | 'children'
> {
	/** As the file input's accept attribute; empty takes any file. */
	accept?: string;
	labelledBy?: string;
	disabled?: boolean;
	onChange?: (file: File) => void;
	ref?: Ref<HTMLDivElement>;
}

/** File name beside a Choose cell. */
export default function CanonFileCell({
	accept,
	labelledBy,
	disabled,
	onChange,
	className,
	...rest
}: CanonFileCellProps) {
	// ponytail: no clear(); re-render the cell to empty it
	const [file, setFile] = useState<File>();
	const input = useRef<HTMLInputElement>(null);
	const parts = file ? splitForMiddle(file.name) : undefined;

	return (
		<div
			className={cx('canon-file-cell', className)}
			role="group"
			aria-labelledby={labelledBy}
			{...rest}
		>
			<span
				className={cx(
					'canon-file-cell-name',
					!parts && 'canon-file-cell-name--none',
				)}
			>
				{parts ? (
					<>
						<span className="canon-file-cell-head">
							{parts[0]}
						</span>
						<span className="canon-file-cell-tail">
							{parts[1]}
						</span>
					</>
				) : (
					'None'
				)}
			</span>
			<CanonButton
				kind="cell"
				text="Choose"
				disabled={disabled}
				onClick={() => input.current?.click()}
			/>
			<input
				type="file"
				className="canon-file-cell-input"
				accept={accept}
				hidden
				ref={input}
				onChange={(event) => {
					const picked = event.target.files?.[0];
					event.target.value = '';
					if (!picked) return;
					setFile(picked);
					onChange?.(picked);
				}}
			/>
		</div>
	);
}
