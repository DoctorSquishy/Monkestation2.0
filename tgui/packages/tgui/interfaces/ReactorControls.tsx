import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import { Box, Button, ProgressBar, Section, Slider, Stack, LabeledControls, RoundGauge } from '../components';
import { formatSiUnit } from '../format';
import { toFixed } from 'common/math';
const formatTemperature = (value) => {
  return toFixed(value) + ' K';
};

type ReactorProps = {
  uid: number;
  area_name: string;
  active: number;
  k: number;
  desiredK: number;
  control_rods: number;
  rods: number;
  shutdownTemp: number;
  coreTemp: number;
  integrity: number;
  temp_limit: any;
  pressure: number;
  coolantInput: number;
  coolantOutput: number;
  pressureData: any;
  tempCoreData: any;
  tempInputData: any;
  tempOutputData: any;
};

type ReactorControlProps = {
  uid: number;
  area_name: string;
  active: number;
  k: number;
  desiredK: number;
  control_rods: number;
  shutdownTemp: number;
  coreTemp: number;
  rods: FuelRodData[];
};

type FuelRodData = {
  name: string;
  depletion: number;
  depletion_threshold: number;
  rod_index: number;
};

type ReactorStatProps = {
  uid: number;
  area_name: string;
  integrity: number;
  temp_limit: any;
  k: number;
  coreTemp: number;
  pressure: number;
  coolantInput: number;
  coolantOutput: number;
};

export type ReactorData = {
  reactor_data;
};

export const ReactorControls = (props: ReactorProps, context) => {
  const [tabIndex, setTabIndex] = useLocalState(context, 'tab-index', 1);
  const { uid, area_name } = props;
  const { act, data } = useBackend<ReactorData>(context);
  const { reactor_data } = data;
  return (
    <Window resizable width={360} height={600} theme="ntOS95">
      <Window.Content>
        <ReactorControlRodControl {...reactor_data[0]} />
      </Window.Content>
    </Window>
  );
};

export const ReactorStatsSection = (props: ReactorStatProps, context) => {
  const {
    uid,
    area_name,
    integrity,
    temp_limit,
    k,
    coreTemp,
    pressure,
    coolantInput,
    coolantOutput,
  } = props;

  return (
    <Box height="100%">
      <Section height="6%" align="center" title={uid + '. ' + area_name} />
      <Section title="Legend:">
        Integrity:
        <ProgressBar
          value={integrity / 100}
          ranges={{
            good: [0.9, Infinity],
            average: [0.5, 0.9],
            bad: [-Infinity, 0.5],
          }}>
          {integrity}%
        </ProgressBar>
        Reactor Pressure:
        <ProgressBar
          value={pressure}
          minValue={0}
          maxValue={10000}
          color="white">
          {formatSiUnit(pressure * 1000, 1, 'Pa')}
        </ProgressBar>
        Coolant temperature:
        <ProgressBar
          value={coolantInput}
          minValue={0}
          maxValue={1500}
          color="blue">
          {coolantInput} K
        </ProgressBar>
        Outlet temperature:
        <ProgressBar
          value={coolantOutput}
          minValue={0}
          maxValue={1500}
          color="orange">
          {coolantOutput} K
        </ProgressBar>
        Core temperature:
        <ProgressBar value={coreTemp} minValue={0} maxValue={1500} color="bad">
          {coreTemp} K
        </ProgressBar>
        Neutrons per generation (K):
        <ProgressBar
          value={k / 5}
          ranges={{
            good: [-Infinity, 0.4],
            average: [0.4, 0.6],
            bad: [0.6, Infinity],
          }}>
          {k}
        </ProgressBar>
      </Section>
    </Box>
  );
};

export const ReactorControlRodControl = (
  props: ReactorControlProps,
  context
) => {
  const {
    uid,
    area_name,
    desiredK,
    k,
    active,
    rods,
    shutdownTemp,
    control_rods,
    coreTemp,
  } = props;
  const { act, data } = useBackend<ReactorData>(context);
  const { reactor_data } = data;
  return (
    <Stack height="100%" vertical fill>
      <Section height="40px" align="center" title={uid + '. ' + area_name} />
      <Stack.Item height="100%" width="100%">
        <Section title="Power Controls" align="center" height="130px">
          <LabeledControls mx={2}>
            <LabeledControls.Item
              bold
              labelColor={active ? 'danger' : 'caution'}
              label="Power Switch"
              color={active ? 'danger' : 'caution'}>
              <Button
                bold
                width="120px"
                lineHeight={4}
                disabled={
                  (coreTemp > shutdownTemp && active) ||
                  (rods.length <= 0 && !active) ||
                  k > 0
                }
                icon={active ? 'power-off' : 'times'}
                color={active ? 'danger' : 'caution'}
                content={active ? 'Reactor On' : 'Reactor Off'}
                selected={active}
                onClick={() => act('power')}
              />
            </LabeledControls.Item>
            <LabeledControls.Item
              bold
              label="Shutdown Temperature"
              color={coreTemp > shutdownTemp ? 'danger' : 'green'}
              labelColor={coreTemp > shutdownTemp ? 'danger' : 'green'}>
              <RoundGauge
                value={coreTemp}
                minValue={0}
                maxValue={shutdownTemp}
                alertAfter={coreTemp > shutdownTemp}
                ranges={{
                  'good': [0, shutdownTemp * 0.7],
                  'average': [shutdownTemp * 0.7, shutdownTemp * 0.9],
                  'bad': [shutdownTemp * 0.9, shutdownTemp],
                }}
                format={formatTemperature}
                size={3}
              />
            </LabeledControls.Item>
          </LabeledControls>
        </Section>
        <Section
          title="Control Rod Management:"
          align="left"
          height="160px"
          bold>
          <Stack.Item>
            Control Rod Insertion:
            <ProgressBar
              value={(control_rods / 100) * 100 * 0.01}
              ranges={{
                good: [0.7, Infinity],
                average: [0.4, 0.7],
                bad: [-Infinity, 0.4],
              }}
            />
          </Stack.Item>
          Neutrons per generation (K):
          <ProgressBar
            value={(k / 5) * 100 * 0.01}
            ranges={{
              good: [-Infinity, 0.4],
              average: [0.4, 0.6],
              bad: [0.6, Infinity],
            }}>
            {k}
          </ProgressBar>
          <Stack.Item>
            {' '}
            Target criticality:
            <Slider
              value={Math.round(desiredK * 10) / 10}
              fillValue={Math.round(k * 10) / 10}
              minValue={0}
              maxValue={5}
              step={0.1}
              stepPixelSize={5}
              onDrag={(e, value) =>
                act('input', {
                  target: value,
                })
              }
            />
          </Stack.Item>
        </Section>
        <Section title="Fuel Rods" height="40%" fill scrollable>
          {rods.length > 0 ? (
            <Stack direction="column">
              {rods.map((rod) => (
                <Box key={rod.name} height="60px" bold>
                  <Stack direction="vertical">
                    <Stack.Item grow>
                      {rod.rod_index + '. ' + rod.name}
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        color="red"
                        icon={'times'}
                        content={'Eject'}
                        disabled={coreTemp > shutdownTemp}
                        onClick={() =>
                          act('eject', {
                            rod_index: rod.rod_index,
                          })
                        }
                      />
                    </Stack.Item>
                  </Stack>

                  <ProgressBar
                    value={rod.depletion_threshold - rod.depletion}
                    minValue={0}
                    maxValue={rod.depletion_threshold}
                    ranges={{
                      good: [
                        rod.depletion_threshold * 0.75,
                        rod.depletion_threshold,
                      ],
                      average: [
                        rod.depletion_threshold * 0.4,
                        rod.depletion_threshold * 0.75,
                      ],
                      bad: [0, rod.depletion_threshold * 0.4],
                    }}
                  />
                </Box>
              ))}
            </Stack>
          ) : (
            <Box fontSize={1}>No rods found.</Box>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};
