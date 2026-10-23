import CanonJumpHeading from '#src/components/canon-jump-heading.gts';
import CanonRow from '#src/components/canon-row.gts';
import CanonRows from '#src/components/canon-rows.gts';
import CanonSwitch from '#src/components/canon-switch.gts';

export const pane = 'sidebar';
export const order = 45;

<template>
	<CanonRows @framed={{true}}>
		<CanonJumpHeading @text="Rows" @detail="2" />
		<CanonRow @title="Plain" as |titleId|>
			<CanonSwitch @on={{true}} aria-labelledby={{titleId}} />
		</CanonRow>
		<CanonRow @title="No control" />
		<CanonJumpHeading @text="Components" @detail="2" />
		<CanonRow @title="Images" as |titleId|>
			<CanonSwitch @on={{true}} aria-labelledby={{titleId}} />
		</CanonRow>
		<CanonRow @title="Files" as |titleId|>
			<CanonSwitch aria-labelledby={{titleId}} />
		</CanonRow>
		<CanonJumpHeading @text="Big number" @detail="1" />
		<CanonRow @title="Sound" as |titleId|>
			<CanonSwitch aria-labelledby={{titleId}} />
		</CanonRow>
	</CanonRows>
</template>
