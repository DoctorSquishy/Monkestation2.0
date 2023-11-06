import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { toFixed } from 'common/math';
import { BooleanLike } from 'common/react';
import { InfernoNode } from 'inferno';
import { useBackend, useLocalState } from 'tgui/backend';
import { Box, Button, Chart, Flex, LabeledList, ProgressBar, Section, Tabs, Slider, Stack } from 'tgui/components';
import { getGasFromPath } from 'tgui/constants';
import { Window } from 'tgui/layouts';

const logScale = (value) => Math.log2(16 + Math.max(0, value)) - 4;

type ReactorGasMetadata = {
  [key: string]: {
    desc?: string;
    numeric_data: {
      name: string;
      amount: number;
      positive: BooleanLike;
    }[];
  };
};

type ReactorProps = {
  sectionButton?: InfernoNode;
  uid: number;
  area_name: string;
  active: number;
  integrity: number;
  integrity_factors: { name: string; amount: number }[];
  k: number;
  desiredK: number;
  coreTemp: number;
  control_rods: number;
  rods: number;
  pressureData: number;
  tempCoreData: number;
  tempInputData: number;
  tempOutputData: number;
  temp_limit: number;
  temp_limit_factors: { name: string; amount: number }[];
  shutdownTemp: number;
  absorbed_ratio: number;
  gas_composition: { [gas_path: string]: number };
  gas_temperature: number;
  gas_total_moles: number;
  reactor_gas_metadata: ReactorGasMetadata;
};

// LabeledList but stack and with a chevron dropdown.
type ReactorEntryProps = {
  title: string;
  content: InfernoNode;
  detail?: InfernoNode;
  alwaysShowChevron?: boolean;
};

const ReactorEntry = (props: ReactorEntryProps, context) => {
  const { title, content, detail, alwaysShowChevron } = props;
  if (!alwaysShowChevron && !detail) {
    return (
      <Stack.Item>
        <Stack align="center">
          <Stack.Item color="grey" width="125px">
            {title + ':'}
          </Stack.Item>
          <Stack.Item grow>{content}</Stack.Item>
        </Stack>
      </Stack.Item>
    );
  }
  const [activeDetail, setActiveDetail] = useLocalState(context, title, false);
  return (
    <>
      <Stack.Item>
        <Stack align="center">
          <Stack.Item color="grey" width="125px">
            {title + ':'}
          </Stack.Item>
          <Stack.Item grow>{content}</Stack.Item>
          <Stack.Item>
            <Button
              onClick={() => setActiveDetail(!activeDetail)}
              icon={activeDetail ? 'chevron-up' : 'chevron-down'}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      {activeDetail && !!detail && <Stack.Item pl={3}>{detail}</Stack.Item>}
    </>
  );
};

export const ReactorContent = (props, context) => {
  const [tabIndex, setTabIndex] = useLocalState(context, 'tab-index', 1);
  return (
    <Window
      resizable
      width={360}
      height={540}>
      <Window.Content fitted>
        <Tabs>
          <Tabs.Tab
            selected={tabIndex === 1}
            onClick={() => setTabIndex(1)}>
            Status
          </Tabs.Tab>
          <Tabs.Tab
            selected={tabIndex === 2}
            onClick={() => setTabIndex(2)}>
            Control
          </Tabs.Tab>
          <Tabs.Tab
            selected={tabIndex === 3}
            onClick={() => setTabIndex(3)}>
            Control
          </Tabs.Tab>
        </Tabs>
        {tabIndex === 1 && <ReactorStatsSection />}
        {tabIndex === 2 && <ReactorControlRodControl />}
        {tabIndex === 3 && <ReactorModeratorGasses />}
      </Window.Content>
    </Window>
  );
};

export const ReactorStatsSection = (props: ReactorProps, context) => {
  const {
    pressureData,
    tempCoreData,
    tempInputData,
    tempOutputData,
    integrity,
    k,
    coreTemp,
  } = props;

  return (
    <Box height="100%">
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
          value={pressureData}
          minValue={0}
          maxValue={10000}
          color="white">
          {pressureData} kPa
        </ProgressBar>
        Coolant temperature:
        <ProgressBar
          value={tempInputData}
          minValue={0}
          maxValue={1500}
          color="blue">
          {tempInputData} K
        </ProgressBar>
        Outlet temperature:
        <ProgressBar
          value={tempOutputData}
          minValue={0}
          maxValue={1500}
          color="orange">
          {tempOutputData} K
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
      <Section fill title="Reactor Statistics:" height="200px">
        <Chart.Line
          fillPositionedParent
          data={pressureData}
          rangeX={[0, pressureData - 1]}
          rangeY={[0, Math.max(10000, pressureData)]}
          strokeColor="rgba(255,250,250, 1)"
          fillColor="rgba(255,250,250, 0.1)"
        />
        <Chart.Line
          fillPositionedParent
          data={tempCoreData}
          rangeX={[0, tempCoreData - 1]}
          rangeY={[0, Math.max(1800, tempCoreData)]}
          strokeColor="rgba(255, 0, 0 , 1)"
          fillColor="rgba(255, 0, 0 , 0.1)"
        />
        <Chart.Line
          fillPositionedParent
          data={tempInputData}
          rangeX={[0, tempInputData - 1]}
          rangeY={[0, Math.max(1800, tempInputData)]}
          strokeColor="rgba(127, 179, 255 , 1)"
          fillColor="rgba(127, 179, 255 , 0.1)"
        />
        <Chart.Line
          fillPositionedParent
          data={tempOutputData}
          rangeX={[0, tempOutputData - 1]}
          rangeY={[0, Math.max(1800, tempOutputData)]}
          strokeColor="rgba(255, 129, 25 , 1)"
          fillColor="rgba(255, 129, 25 , 0.1)"
        />
      </Section>
    </Box>
  );
};

export const ReactorControlRodControl = (props: ReactorProps, context) => {
  const {
    pressureData,
    tempCoreData,
    tempInputData,
    tempOutputData,
    integrity,
    k,
    coreTemp,
    rods,
    control_rods,
    shutdownTemp,
    desiredK,
    active,
  } = props;
  const { act, data } = useBackend(context);
  const fuel_rods = rods;

  return (
    <Box height="100%">
      <Section fill title="Power Management:" height="96px">
        {'Reactor Power: '}
        <Button
          disabled={
            (coreTemp > shutdownTemp && active) ||
            (fuel_rods <= 0 && !active) ||
            k > 0
          }
          icon={active ? 'power-off' : 'times'}
          content={active ? 'On' : 'Off'}
          selected={active}
          onClick={() => act('power')}
        />
      </Section>
      <Section fill title="Control Rod Management:" height="100%">
        Control Rod Insertion:
        <ProgressBar
          value={(control_rods / 100) * 100 * 0.01}
          ranges={{
            good: [0.7, Infinity],
            average: [0.4, 0.7],
            bad: [-Infinity, 0.4],
          }}
        />
        <br />
        Neutrons per generation (K):
        <br />
        <ProgressBar
          value={(k / 5) * 100 * 0.01}
          ranges={{
            good: [-Infinity, 0.4],
            average: [0.4, 0.6],
            bad: [0.6, Infinity],
          }}>
          {k}
        </ProgressBar>
        <br />
        Target criticality:
        <br />
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
      </Section>
    </Box>
  );
};

export const ReactorFuelControl = (props: ReactorProps, context) => {
  const { act, data } = useBackend(context);
  const {
    pressureData,
    tempCoreData,
    tempInputData,
    tempOutputData,
    integrity,
    k,
    coreTemp,
    rods,
    shutdownTemp,
    desiredK,
  } = props;
  const shutdown_temp = shutdownTemp;
  return (
    <Section title="Fuel Rod Management" height="100%">
      {rods > 0 ? (
        <Box>
          <Flex direction="column">
            {Object.keys(rods).map((rod) => (
              <Flex key={rod}>
                <Box inline mr={'3rem'} my={'0.5rem'}>
                  {rods[rod].rod_index}. {rods[rod].name}
                </Box>
                <Button
                  inline
                  icon={'times'}
                  content={'Eject'}
                  disabled={coreTemp > shutdown_temp}
                  onClick={() =>
                    act('eject', {
                      rod_index: rods[rod].rod_index,
                    })
                  }
                />
                <ProgressBar
                  value={100 - rods[rod].depletion}
                  minValue={0}
                  maxValue={100}
                  ranges={{
                    good: [75, Infinity],
                    average: [40, 75],
                    bad: [-Infinity, 40],
                  }}
                />
              </Flex>
            ))}
          </Flex>
        </Box>
      ) : (
        <Box fontSize={3}>No rods found.</Box>
      )}
    </Section>
  );
};

export const ReactorModeratorGasses = (props: ReactorProps, context) => {
  const {
    sectionButton,
    uid,
    area_name,
    integrity,
    integrity_factors,
    rods,
    pressureData,
    tempCoreData,
    tempInputData,
    tempOutputData,
    shutdownTemp,
    temp_limit,
    temp_limit_factors,
    absorbed_ratio,
    gas_temperature,
    gas_total_moles,
    reactor_gas_metadata,
  } = props;
  const [allGasActive, setAllGasActive] = useLocalState(
    context,
    'allGasActive',
    false
  );
  const gas_composition: [gas_path: string, amount: number][] = flow([
    !allGasActive && filter(([gas_path, amount]) => amount !== 0),
    sortBy(([gas_path, amount]) => -amount),
  ])(Object.entries(props.gas_composition));
  return (
    <Stack height="100%">
      <Stack.Item grow>
        <Section
          fill
          scrollable
          title={uid + '. ' + area_name}
          buttons={sectionButton}>
          <Stack vertical>
            <ReactorEntry
              title="Integrity"
              alwaysShowChevron
              content={
                <ProgressBar
                  value={integrity / 100}
                  ranges={{
                    good: [0.9, Infinity],
                    average: [0.5, 0.9],
                    bad: [-Infinity, 0.5],
                  }}>
                  {toFixed(integrity, 2) + ' %'}
                </ProgressBar>
              }
              detail={
                !!integrity_factors.length && (
                  <LabeledList>
                    {integrity_factors.map(({ name, amount }) => (
                      <LabeledList.Item
                        key={name}
                        label={name + ' (∆)'}
                        labelWrap>
                        <Box color={amount > 0 ? 'green' : 'red'}>
                          {toFixed(amount, 2) + ' %'}
                        </Box>
                      </LabeledList.Item>
                    ))}
                  </LabeledList>
                )
              }
            />
            <ReactorEntry
              title="Absorbed Moles"
              content={
                <ProgressBar
                  value={gas_total_moles}
                  minValue={0}
                  maxValue={2000}
                  ranges={{
                    good: [0, 900],
                    average: [900, 1800],
                    bad: [1800, Infinity],
                  }}>
                  {toFixed(gas_total_moles, 2) + ' Moles'}
                </ProgressBar>
              }
            />
            <ReactorEntry
              title="Temperature"
              content={
                <ProgressBar
                  value={logScale(gas_temperature)}
                  minValue={0}
                  maxValue={logScale(10000)}
                  ranges={{
                    teal: [-Infinity, logScale(100)],
                    good: [logScale(100), logScale(300)],
                    average: [logScale(300), logScale(temp_limit)],
                    bad: [logScale(temp_limit), Infinity],
                  }}>
                  {toFixed(gas_temperature, 2) + ' K'}
                </ProgressBar>
              }
            />
            <ReactorEntry
              title="Temperature Limit"
              alwaysShowChevron
              content={temp_limit + ' K'}
              detail={
                !!temp_limit_factors.length && (
                  <LabeledList>
                    {temp_limit_factors.map(({ name, amount }) => (
                      <LabeledList.Item key={name} label={name} labelWrap>
                        <Box color={amount > 0 ? 'green' : 'red'}>
                          {toFixed(amount, 2) + ' K'}
                        </Box>
                      </LabeledList.Item>
                    ))}
                  </LabeledList>
                )
              }
            />
            <ReactorEntry
              title="Absorption Ratio"
              content={absorbed_ratio * 100 + '%'}
            />
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section
          fill
          scrollable
          title="Gases"
          buttons={
            <Button
              icon={allGasActive ? 'times' : 'book-open'}
              onClick={() => setAllGasActive(!allGasActive)}>
              {allGasActive ? 'Hide Gases' : 'Show All Gases'}
            </Button>
          }>
          <Stack vertical>
            {gas_composition.map(([gas_path, amount]) => (
              <ReactorEntry
                key={gas_path}
                title={getGasFromPath(gas_path)?.label || 'Unknown'}
                content={
                  <ProgressBar
                    color={getGasFromPath(gas_path)?.color}
                    value={amount}
                    minValue={0}
                    maxValue={1}>
                    {toFixed(amount * 100, 2) + '%'}
                  </ProgressBar>
                }
                detail={
                  reactor_gas_metadata[gas_path] ? (
                    <>
                      {reactor_gas_metadata[gas_path].desc && <br />}
                      {reactor_gas_metadata[gas_path].numeric_data.length ? (
                        <>
                          <Box mb={1}>
                            At <b>100% Composition</b> gives:
                          </Box>
                          <LabeledList>
                            {reactor_gas_metadata[gas_path].numeric_data.map(
                              (effect) =>
                                effect.amount !== 0 && (
                                  <LabeledList.Item
                                    key={gas_path + effect.name}
                                    label={effect.name}
                                    color={
                                      effect.positive
                                        ? effect.amount > 0
                                          ? 'green'
                                          : 'red'
                                        : effect.amount < 0
                                          ? 'green'
                                          : 'red'
                                    }>
                                    {effect.amount > 0
                                      ? '+' + effect.amount * 100 + '%'
                                      : effect.amount * 100 + '%'}
                                  </LabeledList.Item>
                                )
                            )}
                          </LabeledList>
                        </>
                      ) : (
                        'Has no composition effects'
                      )}
                    </>
                  ) : (
                    'Has no effects'
                  )
                }
              />
            ))}
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};

export type ReactorData = {
  reactor_data: Omit<ReactorProps, 'sectionButton' | 'reactor_gas_metadata'>[];
  reactor_gas_metadata: ReactorGasMetadata;
};

export const Reactor = (props, context) => {
  const { act, data } = useBackend<ReactorData>(context);
  const { reactor_data, reactor_gas_metadata } = data;
  return (
    <Window width={700} height={400} theme="ntos">
      <Window.Content>
        <ReactorContent
          {...reactor_data[0]}
          reactor_gas_metadata={reactor_gas_metadata}
        />
      </Window.Content>
    </Window>
  );
};
