import { useMemo, useState, type HTMLAttributes, type ReactNode } from 'react';
import type { Rgb } from '@canon/lib/colour.ts';
import {
  channels,
  colourAt,
  pointFor,
  solidSpaces,
  spaceNames,
  type SolidPoint,
  type SolidSpace,
} from '@canon/lib/colour-space.ts';
import { cx } from '../lib/class-names.ts';
import { useLatest } from '../lib/refs.ts';
import CanonColourNotationInput from './canon-colour-notation-input.tsx';
import CanonRow from './canon-row.tsx';
import CanonSegmented from './canon-segmented.tsx';
import CanonSlider from './canon-slider.tsx';
import CanonSwitch from './canon-switch.tsx';
import '@canon/styles/tokens.css';
import '@canon/components/canon-colour-controls.css';

/** The fields of a CanonColourSolidState that `set` changes. */
export interface CanonColourSolidFields {
  space: SolidSpace;
  point: SolidPoint;
  /** The last change of `point` eases, as after a tap on a slider track; drags and picks follow at once. */
  animated: boolean;
  /** The slider row that is the solid's slice; row 3, CMYK's black, never slices. */
  activeRow: number;
  /** Slices along the active row's channel; false cuts the solid away instead. */
  slices: boolean;
  /** The View plane switch. */
  viewPlane: boolean;
  /** True while CMYK's black changes. */
  showsWhole: boolean;
}

/**
 * What a CanonColourSolid shows and what its controls change: the Swift
 * controls held the solid itself, so here both read one state, made by
 * `useCanonColourSolidState`. Pass `space`, `point`, `animated`,
 * `sliceAxis`, `isOrtho` and `showsWhole` to the solid and `pick` as its
 * `onChange`. A new space reaches the solid with the old point; the solid
 * converts it and reports it through `pick`. The functions keep their
 * identity across renders.
 */
export interface CanonColourSolidState extends Readonly<CanonColourSolidFields> {
  readonly colour: Rgb;
  readonly isOrtho: boolean;
  readonly sliceAxis: number | undefined;
  set(changes: Partial<CanonColourSolidFields>): void;
  setPoint(point: SolidPoint, animated: boolean): void;
  /** Eases to `colour`. */
  use(colour: Rgb): void;
  selectSpace(space: SolidSpace): void;
  /** The solid's change callback. */
  pick(point: SolidPoint): void;
}

/** One CanonColourSolidState, held in the calling component's state. */
export function useCanonColourSolidState({
  space = 'hsl',
  colour = [0.12, 0.4, 0.15],
  activeRow = 0,
  slices = true,
  viewPlane = false,
}: {
  space?: SolidSpace;
  colour?: Rgb;
  activeRow?: number;
  slices?: boolean;
  viewPlane?: boolean;
} = {}): CanonColourSolidState {
  const [fields, setFields] = useState<CanonColourSolidFields>(() => ({
    space,
    point: pointFor(space, colour),
    animated: false,
    activeRow,
    slices,
    viewPlane,
    showsWhole: false,
  }));
  const actions = useMemo(() => {
    const set = (changes: Partial<CanonColourSolidFields>) =>
      setFields((fields) => ({ ...fields, ...changes }));
    const setPoint = (point: SolidPoint, animated: boolean) =>
      set({ point, animated });
    return {
      set,
      setPoint,
      use: (colour: Rgb) =>
        setFields((fields) => ({
          ...fields,
          point: pointFor(fields.space, colour),
          animated: true,
        })),
      selectSpace: (space: SolidSpace) => set({ space }),
      pick: (point: SolidPoint) => setPoint(point, false),
    };
  }, []);
  return {
    ...fields,
    ...actions,
    colour: colourAt(fields.space, fields.point),
    isOrtho: fields.slices && fields.viewPlane,
    sliceAxis: fields.slices
      ? channels(fields.space)[Math.min(fields.activeRow, 2)]?.axis
      : undefined,
  };
}

export interface CanonColourControlsProps extends HTMLAttributes<HTMLDivElement> {
  state: CanonColourSolidState;
  /** Title of the notation row; default Any notation. */
  notationTitle?: string;
  /** Leaves out the notation row, for a tool with its own input. */
  hidesNotation?: boolean;
  /** Rows placed between the sliders and the View plane switch. */
  children?: ReactNode;
}

const spaceTitles = solidSpaces.map((space) => spaceNames[space]);
const fixed = (decimals: number) => (value: number) => value.toFixed(decimals);
const rowIndices = [0, 1, 2, 3];

/**
 * Rows that drive a CanonColourSolid: any notation beside an eyedropper,
 * the space, one slider per channel and the View plane switch. The active
 * slider row is the solid's slice. Place it inside a CanonRows.
 */
export default function CanonColourControls({
  state,
  notationTitle,
  hidesNotation,
  children,
  className,
  ...rest
}: CanonColourControlsProps) {
  const list = channels(state.space);
  const lit = state.slices ? Math.min(state.activeRow, 2) : -1;
  const longest = list.reduce(
    (a, c) => (c.name.length > a.length ? c.name : a),
    '',
  );
  const latest = useLatest(state);

  // CanonSlider has no touch-down callback: a touch picks the row, black shows the whole solid
  const touches = useMemo(
    () =>
      rowIndices.map((index) => (slider: HTMLDivElement) => {
        const down = () => {
          if (index === 3) latest.current.set({ showsWhole: true });
          else latest.current.set({ activeRow: index });
          window.addEventListener('pointerup', up);
          window.addEventListener('pointercancel', up);
        };
        const up = () => {
          latest.current.set({ showsWhole: false });
          window.removeEventListener('pointerup', up);
          window.removeEventListener('pointercancel', up);
        };
        slider.addEventListener('pointerdown', down);
        return () => {
          slider.removeEventListener('pointerdown', down);
          up();
        };
      }),
    [latest],
  );

  const slide = (index: number, value: number, dragging: boolean) => {
    const channel = list[index];
    if (!channel) return;
    const point = [...state.point] as SolidPoint;
    point[channel.axis] = (value - channel.offset) / channel.scale;
    // taps ease, drags follow
    state.set({
      point,
      animated: !dragging,
      ...(index < 3 && { activeRow: index }),
    });
  };

  return (
    <div className={cx('canon-colour-controls', className)} {...rest}>
      {!hidesNotation && (
        <CanonRow
          title={notationTitle ? notationTitle : 'Any notation'}
          form="stacked"
        >
          {(titleId) => (
            <CanonColourNotationInput
              colour={state.colour}
              onColour={state.use}
              labelledBy={titleId}
            />
          )}
        </CanonRow>
      )}
      <CanonRow title="Space" form="stacked">
        <CanonSegmented
          items={spaceTitles}
          selected={solidSpaces.indexOf(state.space)}
          columns={4}
          onChange={(index) => state.selectSpace(solidSpaces[index]!)}
        />
      </CanonRow>
      {list.map((channel, index) => (
        <CanonRow
          key={index}
          className={cx(
            'canon-colour-controls-channel',
            index === lit && 'canon-colour-controls-lit',
          )}
          title={channel.name}
          detail={channel.detail}
          form="flush"
          sizingTitle={longest}
        >
          {(titleId) => (
            <CanonSlider
              value={
                state.point[channel.axis]! * channel.scale + channel.offset
              }
              min={channel.min}
              max={channel.max}
              readout={fixed(channel.decimals)}
              labelledBy={titleId}
              onChange={(value, dragging) => slide(index, value, dragging)}
              ref={touches[index]}
            />
          )}
        </CanonRow>
      ))}
      {children}
      <CanonRow title="View plane">
        {(titleId) => (
          <CanonSwitch
            on={state.viewPlane}
            onChange={(on) => state.set({ viewPlane: on })}
            aria-labelledby={titleId}
          />
        )}
      </CanonRow>
    </div>
  );
}
