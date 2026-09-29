import type { TOC } from '@ember/component/template-only';
import CanonTimecode from '#src/components/canon-timecode.gts';
import { hasDigits } from '#src/lib/timecode.ts';

interface PictureSignature {
  Args: { a: string; b: string; subtracts: boolean; result: string };
}

const size = 30;
const halo = 'var(--canon-card)';

// CanonTimecode lights blank hyphens; the iOS counter dims them
const line = (text: string) =>
  hasDigits(text) ? 'tcc-line' : 'tcc-line tcc-blank';

/** The sum as it is written out: A, then the sign and B, a rule, and the result under it, all in the segment font. */
const Picture: TOC<PictureSignature> = <template>
  <div class="tcc-picture">
    <div class="tcc-sum">
      <CanonTimecode
        class="{{line @a}} tcc-operand"
        @text={{@a}}
        @size={{size}}
        @halo={{halo}}
        @label="Timecode A"
      />
      <div class="tcc-row">
        <span class="tcc-sign">{{if @subtracts "−" "+"}}</span>
        <CanonTimecode
          class="{{line @b}} tcc-operand"
          @text={{@b}}
          @size={{size}}
          @halo={{halo}}
          @label="Timecode B"
        />
      </div>
      <div class="tcc-rule"></div>
      <CanonTimecode
        class={{line @result}}
        @text={{@result}}
        @size={{size}}
        @halo={{halo}}
        @label="Result"
      />
    </div>
  </div>
</template>;

export default Picture;
