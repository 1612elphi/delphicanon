<script lang="ts" module>
	import type {
		CanonMenuEntry as Entry,
		CanonMenuItem as Item,
	} from './canon-menu-list.svelte';

	export type CanonMenuEntry = Entry;
	export type CanonMenuItem = Item;
</script>

<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { Attachment } from 'svelte/attachments';
	import type { HTMLAttributes } from 'svelte/elements';
	import CanonMenuList, { showMenu } from './canon-menu-list.svelte';
	import {
		attach,
		panelFor,
		type CanonPlacement,
	} from '@canon/lib/popover.ts';
	import '@canon/styles/tokens.css';
	import '@canon/components/canon-popover.css';
	import '@canon/components/canon-menu.css';

	interface Props extends Omit<
		HTMLAttributes<HTMLDivElement>,
		'children' | 'onselect'
	> {
		items: CanonMenuEntry[];
		/** Default bottom-start. */
		placement?: CanonPlacement;
		onSelect?: (item: CanonMenuItem) => void;
		/** Put `{@attach trigger}` on the button that opens the menu. */
		children?: Snippet<
			[{ trigger: Attachment<HTMLButtonElement> }]
		>;
	}

	let { items, placement, onSelect, children, ...rest }: Props = $props();

	const uid = $props.id();
	const id = `${uid}-menu`;

	const trigger: Attachment<HTMLButtonElement> = (button) => {
		const panel = panelFor(button, id);
		const detach = attach(panel, button, {
			placement: placement ?? 'bottom-start',
			invokes: true,
			haspopup: 'menu',
		});
		const keydown = (event: KeyboardEvent) => {
			if (
				event.key !== 'ArrowDown' &&
				event.key !== 'ArrowUp'
			)
				return;
			event.preventDefault();
			showMenu(
				panel,
				event.key === 'ArrowDown' ? 'first' : 'last',
			);
		};
		button.addEventListener('keydown', keydown);
		return () => {
			button.removeEventListener('keydown', keydown);
			detach();
		};
	};

	const select = (item: CanonMenuItem) => onSelect?.(item);
</script>

<!--
  @component
  A dropdown menu opened by the consumer's button: a click, Enter or Space
  opens it at the first item, the down and up arrows at the first and last.
  Choosing an item closes it and reports the item.
-->
{@render children?.({ trigger })}
<CanonMenuList {id} {items} onSelect={select} {...rest} />
