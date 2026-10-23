import {
	useId,
	useMemo,
	useState,
	type HTMLAttributes,
	type KeyboardEvent,
	type ReactNode,
} from 'react';
import { rank, step, type CommandEntry } from '@canon/lib/command.ts';
import CanonEmptyRow from './canon-empty-row.tsx';
import CanonHeading from './canon-heading.tsx';
import CanonRows from './canon-rows.tsx';
import { cx } from '../lib/class-names.ts';
import { Search } from '../lib/control-icons.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-command.css';

export interface CanonCommandItem extends CommandEntry {
	/** Rendered before the title; the consumer supplies it. */
	icon?: ReactNode;
	/** Keys drawn as key caps at the end of the row, `['⌘', 'K']`. */
	shortcut?: string[];
	/** A second line: where it lives, or the query an answer answers. */
	detail?: string;
}

export interface CanonCommandProps extends Omit<
	HTMLAttributes<HTMLDivElement>,
	'onSelect' | 'children'
> {
	items: CanonCommandItem[];
	placeholder?: string;
	/** Accessible name of the field and the list; default Search. */
	label?: string;
	/** Shown when nothing matches; default No results. */
	empty?: string;
	/** Draws the 2 px tool frame; leave off inside a CanonDialog. */
	framed?: boolean;
	/** A click, or Enter on the active row. */
	onSelect?: (item: CanonCommandItem) => void;
	/** Every edit of the query, so the owner can add answer items for it. */
	onQuery?: (query: string) => void;
}

/**
 * The search and command palette (the macOS Omnibox): a combobox field over
 * a listbox of grouped rows. Focus stays in the field; the arrow keys move
 * the active row, wrapping, Enter selects it, Escape clears the query.
 */
export default function CanonCommand({
	items,
	placeholder,
	label = 'Search',
	empty,
	framed,
	onSelect,
	onQuery,
	className,
	...rest
}: CanonCommandProps) {
	const [query, setQueryState] = useState('');
	/** Row index the keys or the pointer moved to; -1 is the first enabled row. */
	const [chosen, setChosen] = useState(-1);
	const listId = `${useId()}-list`;

	const groups = useMemo(() => {
		let index = 0;
		return rank(items, query).map((group, number) => ({
			name: group.name,
			headingId: `${listId}-group-${number}`,
			rows: group.items.map((item) => ({
				item,
				index,
				id: `${listId}-${index++}`,
			})),
		}));
	}, [items, query, listId]);
	const rows = groups.flatMap((group) => group.rows);
	const activeIndex =
		rows[chosen] && !rows[chosen].item.disabled
			? chosen
			: rows.findIndex((row) => !row.item.disabled);
	const activeId = rows[activeIndex]?.id;

	const setQuery = (text: string) => {
		setQueryState(text);
		setChosen(-1);
		onQuery?.(text);
	};

	const pick = (item: CanonCommandItem) => {
		if (!item.disabled) onSelect?.(item);
	};

	const hover = (index: number) => {
		if (index !== chosen && !rows[index]?.item.disabled)
			setChosen(index);
	};

	const keydown = (event: KeyboardEvent<HTMLInputElement>) => {
		if (event.nativeEvent.isComposing) return;
		const delta =
			event.key === 'ArrowDown'
				? 1
				: event.key === 'ArrowUp'
					? -1
					: 0;
		if (delta) {
			event.preventDefault();
			const enabled = rows.filter(
				(row) => !row.item.disabled,
			);
			const at = enabled.findIndex(
				(row) => row.index === activeIndex,
			);
			const next = enabled[step(at, delta, enabled.length)];
			if (!next) return;
			setChosen(next.index);
			document.getElementById(next.id)?.scrollIntoView({
				block: 'nearest',
			});
		} else if (event.key === 'Enter') {
			const row = rows[activeIndex];
			if (!row) return;
			event.preventDefault();
			pick(row.item);
		} else if (event.key === 'Escape' && query) {
			// precedes dialog close request
			event.preventDefault();
			setQuery('');
		}
	};

	return (
		<CanonRows
			framed={framed}
			className={cx('canon-command', className)}
			{...rest}
		>
			<div className="canon-command-bar">
				<span
					className="canon-command-search"
					aria-hidden="true"
				>
					<Search />
				</span>
				<input
					className="canon-command-input"
					type="text"
					role="combobox"
					aria-label={label}
					aria-expanded="true"
					aria-controls={listId}
					aria-autocomplete="list"
					aria-activedescendant={activeId}
					autoComplete="off"
					spellCheck="false"
					placeholder={placeholder}
					value={query}
					onChange={(event) =>
						setQuery(event.target.value)
					}
					onKeyDown={keydown}
				/>
			</div>
			<div
				className="canon-command-list"
				role="listbox"
				id={listId}
				aria-label={label}
				hidden={rows.length === 0}
			>
				{groups.map((group) => (
					<div
						key={group.headingId}
						className="canon-command-group"
						role="group"
						aria-labelledby={
							group.name
								? group.headingId
								: undefined
						}
					>
						{group.name && (
							<CanonHeading
								text={
									group.name
								}
								id={
									group.headingId
								}
								role="presentation"
							/>
						)}
						{group.rows.map((row) => {
							const active =
								row.index ===
								activeIndex;
							return (
								<div
									key={
										row.id
									}
									className={cx(
										'canon-command-item',
										row
											.item
											.answer &&
											'canon-command-item--answer',
									)}
									role="option"
									id={
										row.id
									}
									aria-selected={
										active
											? 'true'
											: 'false'
									}
									aria-disabled={
										row
											.item
											.disabled
											? 'true'
											: undefined
									}
									data-active={
										active
											? ''
											: undefined
									}
									onClick={() =>
										pick(
											row.item,
										)
									}
									onPointerMove={() =>
										hover(
											row.index,
										)
									}
								>
									{row
										.item
										.icon !==
										undefined &&
										row
											.item
											.icon !==
											null && (
											<span
												className="canon-command-icon"
												aria-hidden="true"
											>
												{
													row
														.item
														.icon
												}
											</span>
										)}
									<span className="canon-command-text">
										<span className="canon-command-title">
											{
												row
													.item
													.title
											}
										</span>
										{row
											.item
											.detail && (
											<span className="canon-command-detail">
												{
													row
														.item
														.detail
												}
											</span>
										)}
									</span>
									{row
										.item
										.shortcut
										?.length ? (
										<span className="canon-command-keys">
											{row.item.shortcut.map(
												(
													key,
													i,
												) => (
													<span
														key={
															i
														}
														className="canon-command-key"
													>
														{
															key
														}
													</span>
												),
											)}
										</span>
									) : (
										active && (
											<span
												className="canon-command-enter"
												aria-hidden="true"
											>
												↵
											</span>
										)
									)}
								</div>
							);
						})}
					</div>
				))}
			</div>
			{rows.length === 0 && (
				<CanonEmptyRow
					text={empty || 'No results'}
					className="canon-command-empty"
					role="status"
				/>
			)}
		</CanonRows>
	);
}
