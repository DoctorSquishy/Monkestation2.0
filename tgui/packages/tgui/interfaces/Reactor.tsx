import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { toFixed } from 'common/math';
import { BooleanLike } from 'common/react';
import { InfernoNode } from 'inferno';
import { useBackend, useLocalState } from '../backend';
import { Box, Button, Chart, LabeledList, ProgressBar, Section, Stack, Tabs } from '../components';
import { getGasFromPath } from '../constants';
import { Window } from '../layouts';
import { formatSiUnit } from '../format';

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

type ReactorStatProps = {
  integrity: number;
  integrity_factors: { name: string; amount: number }[];
  temp_limit: any;
  k: number;
  coreTemp: number;
  pressure: number;
  pressureMax: number;
  coolantInput: number;
  coolantOutput: number;
  pressureData: any;
  tempCoreData: any;
  tempInputData: any;
  tempOutputData: any;
};

type ReactorProps = {
  sectionButton?: InfernoNode;
  uid: number;
  area_name: string;
  integrity: number;
  integrity_factors: { name: string; amount: number }[];
  temp_limit: any;
  temp_limit_factors: { name: string; amount: number }[];
  waste_multiplier: number;
  waste_multiplier_factors: { name: string; amount: number }[];
  absorbed_ratio: number;
  gas_composition: { [gas_path: string]: number };
  gas_temperature: number;
  gas_total_moles: number;
  reactor_gas_metadata: ReactorGasMetadata;
  k: number;
  coreTemp: number;
  pressure: number;
  pressureMax: number;
  coolantInput: number;
  coolantOutput: number;
  pressureData: any;
  tempCoreData: any;
  tempInputData: any;
  tempOutputData: any;
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
          <Stack.Item width="125px">{title + ':'}</Stack.Item>
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
          <Stack.Item width="125px">{title + ':'}</Stack.Item>
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

export const ReactorContent = (props: ReactorProps, context) => {
  const [currentTab, setTab] = useLocalState(context, 'currentTab', 1);
  const { sectionButton, uid, area_name, integrity, k } = props;
  const { act, data } = useBackend<ReactorData>(context);
  const { reactor_data, reactor_gas_metadata } = data;
  return (
    <Stack vertical fill>
      <Section
        height="40px"
        fontSize="12px"
        align="center"
        title={uid + '. ' + area_name}
        buttons={sectionButton}
      />
      <Section>
        <Stack.Item height="40px">
          <ReactorEntry
            title="Reactor Integrity"
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
          />
        </Stack.Item>
        <Stack.Item height="40px">
          <ReactorEntry
            title="Neutrons per generation (K)"
            content={
              <ProgressBar
                value={k / 5}
                ranges={{
                  good: [-Infinity, 0.4],
                  average: [0.4, 0.6],
                  bad: [0.6, Infinity],
                }}>
                {k}
              </ProgressBar>
            }
          />
        </Stack.Item>
      </Section>
      <Stack.Item>
        <Tabs textAlign="center" fluid>
          <Tabs.Tab
            icon="radiation"
            selected={currentTab === 1}
            onClick={() => setTab(1)}>
            Reactor Status
          </Tabs.Tab>
          <Tabs.Tab
            icon="info"
            selected={currentTab === 2}
            onClick={() => setTab(2)}>
            Moderator Gases
          </Tabs.Tab>
        </Tabs>
      </Stack.Item>
      <Stack.Item grow>
        {currentTab === 1 && <ReactorStatContent {...reactor_data[0]} />}
        {currentTab === 2 && (
          <ReactorModeratorContent
            {...reactor_data[0]}
            reactor_gas_metadata={reactor_gas_metadata}
          />
        )}
      </Stack.Item>
    </Stack>
  );
};

export const ReactorStatContent = (props: ReactorStatProps, context) => {
  const {
    integrity,
    integrity_factors,
    temp_limit,
    k,
    coreTemp,
    pressure,
    pressureMax,
    coolantInput,
    coolantOutput,
    pressureData,
    tempCoreData,
    tempInputData,
    tempOutputData,
  } = props;
  const pressureMapData = pressureData.map((amount, i) => [i, amount]);
  const tempCoreMapData = tempCoreData.map((amount, i) => [i, amount]);
  const tempInputMapData = tempInputData.map((amount, i) => [i, amount]);
  const tempOutputMapData = tempOutputData.map((amount, i) => [i, amount]);

  return (
    <Stack height="100%">
      <Stack.Item grow>
        <Stack.Item height="100%">
          <Section title="Statistics Legend:" height="250px">
            Reactor Pressure:
            <ProgressBar
              value={pressure}
              minValue={0}
              maxValue={pressureMax}
              color="white">
              {formatSiUnit(pressure * 1000, 1, 'Pa')}
            </ProgressBar>
            Coolant temperature:
            <ProgressBar
              value={coolantInput}
              minValue={0}
              maxValue={temp_limit}
              color="blue">
              {coolantInput} K
            </ProgressBar>
            Outlet temperature:
            <ProgressBar
              value={coolantOutput}
              minValue={0}
              maxValue={temp_limit}
              color="orange">
              {coolantOutput} K
            </ProgressBar>
            Core temperature:
            <ProgressBar
              value={coreTemp}
              minValue={0}
              maxValue={temp_limit}
              color="bad">
              {coreTemp} K
            </ProgressBar>
          </Section>
        </Stack.Item>
      </Stack.Item>
      <Stack.Item grow>
        <Stack.Item />
        <Section fill title="Reactor Statistics:" height="250px">
          <Chart.Line
            fillPositionedParent
            data={pressureMapData}
            rangeX={[0, pressureMapData.length - 1]}
            rangeY={[0, Math.max(pressureMax, ...pressureData)]}
            strokeColor="rgba(255,250,250, 1)"
            fillColor="rgba(255,250,250, 0.1)"
            strokeWidth="3"
          />
          <Chart.Line
            fillPositionedParent
            data={tempCoreMapData}
            rangeX={[0, tempCoreMapData.length - 1]}
            rangeY={[0, Math.max(temp_limit, ...tempCoreData)]}
            strokeColor="rgba(255, 0, 0 , 1)"
            fillColor="rgba(255, 0, 0 , 0.1)"
            strokeWidth="3"
          />
          <Chart.Line
            fillPositionedParent
            data={tempInputMapData}
            rangeX={[0, tempInputMapData.length - 1]}
            rangeY={[0, Math.max(temp_limit, ...tempInputData)]}
            strokeColor="rgba(127, 179, 255 , 1)"
            fillColor="rgba(127, 179, 255 , 0.1)"
            strokeWidth="3"
          />
          <Chart.Line
            fillPositionedParent
            data={tempOutputMapData}
            rangeX={[0, tempOutputData.length - 1]}
            rangeY={[0, Math.max(temp_limit, ...tempOutputData)]}
            strokeColor="rgba(255, 129, 25 , 1)"
            fillColor="rgba(255, 129, 25 , 0.1)"
            strokeWidth="3"
          />
        </Section>
      </Stack.Item>
    </Stack>
  );
};

export const ReactorModeratorContent = (props: ReactorProps, context) => {
  const {
    sectionButton,
    uid,
    area_name,
    integrity,
    integrity_factors,
    temp_limit,
    temp_limit_factors,
    waste_multiplier,
    waste_multiplier_factors,
    absorbed_ratio,
    gas_temperature,
    gas_total_moles,
    reactor_gas_metadata,
    k,
    coreTemp,
    pressure,
    pressureMax,
    coolantInput,
    coolantOutput,
    pressureData,
    tempCoreData,
    tempInputData,
    tempOutputData,
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
        <Box height="100%">
          <Section title="Moderator Stats" fill>
            <Stack vertical>
              <ReactorEntry
                title="Reactor Integrity"
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
                title="Moderator Absorbed Moles"
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
                title="Moderator Temperature"
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
                title="Fuel Waste Multiplier"
                alwaysShowChevron
                content={
                  <ProgressBar
                    value={waste_multiplier}
                    minValue={0}
                    maxValue={20}
                    ranges={{
                      good: [-Infinity, 0.8],
                      average: [0.8, 2],
                      bad: [2, Infinity],
                    }}>
                    {toFixed(waste_multiplier, 2) + ' x'}
                  </ProgressBar>
                }
                detail={
                  !!waste_multiplier_factors.length && (
                    <LabeledList>
                      {waste_multiplier_factors.map(({ name, amount }) => (
                        <LabeledList.Item key={name} label={name} labelWrap>
                          <Box color={amount < 0 ? 'green' : 'red'}>
                            {toFixed(amount, 2) + ' x'}
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
        </Box>
      </Stack.Item>
      <Stack.Item grow>
        <Section
          fill
          scrollable
          title="Moderator Gases"
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
                                    labelColor={
                                      effect.positive
                                        ? effect.amount > 0
                                          ? 'green'
                                          : 'red'
                                        : effect.amount < 0
                                          ? 'green'
                                          : 'red'
                                    }
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
    <Window width={700} height={500}>
      <Window.Content>
        <ReactorContent
          {...reactor_data[0]}
          reactor_gas_metadata={reactor_gas_metadata}
        />
      </Window.Content>
    </Window>
  );
};
