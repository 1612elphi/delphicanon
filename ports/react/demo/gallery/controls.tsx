import { useState } from 'react';
import CanonBigNumberField from '../../src/components/canon-big-number-field.tsx';
import CanonDecimalField from '../../src/components/canon-decimal-field.tsx';
import CanonDualList, {
  type CanonDualItem,
} from '../../src/components/canon-dual-list.tsx';
import CanonFigure from '../../src/components/canon-figure.tsx';
import CanonFileCell from '../../src/components/canon-file-cell.tsx';
import CanonFromTo from '../../src/components/canon-from-to.tsx';
import CanonGrid from '../../src/components/canon-grid.tsx';
import CanonHeading from '../../src/components/canon-heading.tsx';
import CanonLoader from '../../src/components/canon-loader.tsx';
import CanonMenuCell from '../../src/components/canon-menu-cell.tsx';
import CanonNumberField from '../../src/components/canon-number-field.tsx';
import CanonRow from '../../src/components/canon-row.tsx';
import CanonRows from '../../src/components/canon-rows.tsx';
import CanonSlider from '../../src/components/canon-slider.tsx';
import CanonStatus from '../../src/components/canon-status.tsx';
import CanonSwitch from '../../src/components/canon-switch.tsx';
import CanonTextArea from '../../src/components/canon-text-area.tsx';
import CanonTextCell from '../../src/components/canon-text-cell.tsx';

import '../../../../demo-app/components/gallery/controls.css';

export const pane = 'sidebar';
export const order = 40;

// ∑CG: gallery, a status shown as a padded row of its own
//   spec: example warning status text for the status-as-row variant; three to five words, sentence case, no period
//   sample: "Status as a row"
const statusRowText = '∑CG';

const switches = ['Images', 'Files', 'Sound'];
const longestSwitch = 'Images';
const whole = (value: number) => String(Math.round(value));
const rates = ['23.976', '24', '25'];

export default function Controls() {
  const [number, setNumber] = useState(200);
  const [big, setBig] = useState('16');
  const [seconds, setSeconds] = useState(1.5);
  const [factor, setFactor] = useState(1);
  const [hidden, setHidden] = useState<CanonDualItem[]>([
    { id: 'b', name: 'Beta', caption: 'two' },
    { id: 'd', name: 'Delta', caption: 'four' },
  ]);
  const [shown, setShown] = useState<CanonDualItem[]>([
    { id: 'a', name: 'Alpha', caption: 'one' },
    { id: 'c', name: 'Gamma', caption: 'three' },
  ]);

  const stepBig = (direction: -1 | 1) =>
    setBig(String(Math.max(0, (parseInt(big) || 0) + direction)));

  const moveRight = (id: string) => {
    const item = hidden.find((i) => i.id === id);
    if (!item) return;
    setHidden(hidden.filter((i) => i !== item));
    setShown([...shown, item]);
  };

  const moveLeft = (id: string) => {
    const item = shown.find((i) => i.id === id);
    if (!item) return;
    setShown(shown.filter((i) => i !== item));
    setHidden([...hidden, item]);
  };

  const reorder = (id: string, delta: -1 | 1) => {
    const index = shown.findIndex((i) => i.id === id);
    const other = index + delta;
    if (index < 0 || other < 0 || other >= shown.length) return;
    const next = [...shown];
    [next[index], next[other]] = [next[other]!, next[index]!];
    setShown(next);
  };

  return (
    <CanonRows framed>
      <CanonHeading text="Components" />
      <CanonRow title="Switch">
        {(titleId) => <CanonSwitch on aria-labelledby={titleId} />}
      </CanonRow>
      <CanonRow title="Number" form="flush">
        {(titleId) => (
          <CanonNumberField
            value={number}
            max={5000}
            step={50}
            unit="items"
            labelledBy={titleId}
            onChange={setNumber}
          />
        )}
      </CanonRow>
      <CanonRow title="Figure" detail="Follows Number">
        <CanonFigure text={String(number)} unit="px" size={28} />
      </CanonRow>
      <CanonRow title="Slider" form="flush">
        {(titleId) => <CanonSlider value={0.65} labelledBy={titleId} />}
      </CanonRow>
      <CanonRow title="Stepped slider" form="flush">
        {(titleId) => (
          <CanonSlider
            value={80}
            min={1}
            max={100}
            step={1}
            readout={whole}
            labelledBy={titleId}
          />
        )}
      </CanonRow>
      <CanonRow title="Text" form="flush">
        {(titleId) => (
          <CanonTextCell placeholder="Trigger" aria-labelledby={titleId} />
        )}
      </CanonRow>
      <CanonRow title="File" form="flush">
        {(titleId) => <CanonFileCell labelledBy={titleId} />}
      </CanonRow>
      <CanonRow title="Image" form="flush">
        {(titleId) => <CanonFileCell accept="image/*" labelledBy={titleId} />}
      </CanonRow>
      <CanonGrid>
        {switches.map((title, index) => (
          <CanonRow key={title} title={title} sizingTitle={longestSwitch}>
            {(id) => <CanonSwitch on={index % 2 === 0} aria-labelledby={id} />}
          </CanonRow>
        ))}
      </CanonGrid>
      <CanonHeading text="Big number" />
      <CanonBigNumberField
        value={big}
        placeholder="0"
        unit="PX"
        label="Big number"
        onStep={stepBig}
        onInput={setBig}
      />
      <CanonRow title="Decimal" form="flush">
        {(titleId) => (
          <CanonDecimalField
            value={seconds}
            labelledBy={titleId}
            onChange={setSeconds}
          />
        )}
      </CanonRow>
      <CanonRow title="Signed, six places" form="flush">
        {(titleId) => (
          <CanonDecimalField
            value={factor}
            unit="×"
            step={0.001}
            decimals={6}
            signed
            labelledBy={titleId}
            onChange={setFactor}
          />
        )}
      </CanonRow>
      <CanonTextArea
        placeholder="Text area"
        height={120}
        aria-label="Text area"
      />
      <CanonRow title="Menu" form="flush">
        {(titleId) => (
          <CanonMenuCell items={rates} selected={0} labelledBy={titleId} />
        )}
      </CanonRow>
      <CanonFromTo items={rates} from={0} to={2} />
      <CanonRow title="Status">
        <div className="gallery-inline">
          <CanonStatus text="Granted" tone="ok" />
          <CanonStatus text="Not granted" tone="warn" />
          <CanonStatus text="Stopped" tone="muted" />
        </div>
      </CanonRow>
      <CanonStatus text={statusRowText} tone="warn" row />
      <CanonRow title="Loader">
        <div className="gallery-inline gallery-loaders">
          <CanonLoader />
          <CanonLoader mode="comet" reverse />
          <CanonLoader mode="dot" />
          <CanonLoader mode="twin" />
          <CanonLoader mode="thinking" />
          <CanonLoader cell={4} gap={1} />
        </div>
      </CanonRow>
      <CanonRow title="Dual list" form="stacked">
        <CanonDualList
          left={hidden}
          right={shown}
          leftTitle="Hidden"
          rightTitle="Shown"
          listHeight={140}
          onMoveRight={moveRight}
          onMoveLeft={moveLeft}
          onReorder={reorder}
        />
      </CanonRow>
    </CanonRows>
  );
}
