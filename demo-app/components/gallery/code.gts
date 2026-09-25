import CanonCodeBlock from '#src/components/canon-code-block.gts';
import CanonHeading from '#src/components/canon-heading.gts';
import CanonRows from '#src/components/canon-rows.gts';

export const pane = 'main';
export const order = 22;

const css = `.button {
    border-radius: 0;
    color: oklch(0.45 0.12 145);
}`;
const plain = 'no language: copy sits below';
const long = Array.from(
  { length: 400 },
  (_, i) => `line ${i + 1}: ${'lorem ipsum '.repeat(12)}`,
).join('\n');

<template>
  <CanonRows @framed={{true}}>
    <CanonHeading @text="Code" />
    <CanonCodeBlock @code={{css}} @language="css" />
    <CanonCodeBlock @code={{plain}} />
    <CanonCodeBlock
      @code={{long}}
      @language="capped at 160"
      @maxHeight={{160}}
    />
  </CanonRows>
</template>
