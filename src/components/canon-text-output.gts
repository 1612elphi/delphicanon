import Component from '@glimmer/component';
import { service } from '@ember/service';
import CanonButton from './canon-button.gts';
import CanonEmptyRow from './canon-empty-row.gts';
import CanonGrid from './canon-grid.gts';
import CanonHeading from './canon-heading.gts';
import CanonRows from './canon-rows.gts';
import type CanonToastService from '../services/canon-toast.ts';
import '../styles/tokens.css';
import './canon-text-output.css';
import { Copy as copy, Share as share } from 'lucide-static';
import CanonIcon from './canon-icon.gts';

export interface CanonTextOutputSignature {
  Args: {
    text: string;
    heading: string;
    /** Name of the file Share hands over. */
    fileName: string;
    /** The output is still to come; the empty row stays away. */
    busy?: boolean;
    /** Shown when the output is blank; default None. */
    empty?: string;
  };
  Blocks: {
    /** The output with its marks, shown in place of `text`. */
    default: [];
    /** Rows between the text and the actions. */
    extra: [];
  };
  Element: HTMLDivElement;
}

const CopyIcon = <template><CanonIcon @svg={{copy}} /></template>;

const ShareIcon = <template><CanonIcon @svg={{share}} /></template>;

/** Hands a text file to the system share sheet, or downloads it where there is none. */
export async function shareText(text: string, fileName: string) {
  const file = new File([text], fileName, { type: 'text/plain' });
  if (typeof navigator.share === 'function') {
    const data = navigator.canShare?.({ files: [file] })
      ? { files: [file] }
      : { text };
    try {
      await navigator.share(data);
    } catch {
      // dismissed
    }
    return;
  }
  const url = URL.createObjectURL(file);
  const link = document.createElement('a');
  link.href = url;
  link.download = fileName;
  link.click();
  URL.revokeObjectURL(url);
}

/** The output block of a text tool: a heading, the converted text, and Share beside Copy. */
export default class CanonTextOutput extends Component<CanonTextOutputSignature> {
  @service('canon-toast') declare toast: CanonToastService;

  get blank() {
    return this.args.text.trim() === '';
  }

  copy = () => {
    this.toast.write(this.args.text).catch(() => undefined);
  };

  share = () => shareText(this.args.text, this.args.fileName);

  <template>
    <CanonRows class="canon-text-output" @framed={{true}} ...attributes>
      <CanonHeading @text={{@heading}} />
      {{#unless this.blank}}
        <div class="canon-text-output-text">
          {{~#if (has-block)}}{{yield}}{{else}}{{@text}}{{/if~}}
        </div>
      {{/unless}}
      {{#if this.blank}}
        {{#unless @busy}}
          <CanonEmptyRow @text={{if @empty @empty "None"}} />
        {{/unless}}
      {{/if}}
      {{yield to="extra"}}
      <CanonGrid>
        <CanonButton
          @text="Share"
          @icon={{ShareIcon}}
          @disabled={{this.blank}}
          @onClick={{this.share}}
        />
        <CanonButton
          @text="Copy"
          @icon={{CopyIcon}}
          @iconStyle="oversized"
          @kind="primary"
          @disabled={{this.blank}}
          @flashesCopied={{true}}
          @onClick={{this.copy}}
        />
      </CanonGrid>
    </CanonRows>
  </template>
}
