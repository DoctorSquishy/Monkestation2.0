import { useBackend, useLocalState } from 'tgui/backend';
import { NtosWindow } from 'tgui/layouts';
import { ReactorContent, ReactorData } from './Reactor';
import { Button, ProgressBar, Section, Table } from 'tgui/components';

type NtosReactorData = ReactorData & { focus_uid?: number };

export const NtosReactor = (props, context) => {
  const { act, data } = useBackend<NtosReactorData>(context);
  const { reactor_data, reactor_gas_metadata, focus_uid } = data;
  const [activeUID, setActiveUID] = useLocalState(context, 'activeUID', 0);
  const activeREACTOR = reactor_data.find(
    (reactor) => reactor.uid === activeUID
  );
  return (
    <NtosWindow height={500} width={700}>
      <NtosWindow.Content>
        {activeREACTOR ? (
          <ReactorContent
            {...activeREACTOR}
            reactor_gas_metadata={reactor_gas_metadata}
            sectionButton={
              <Button icon="arrow-left" onClick={() => setActiveUID(0)}>
                Back
              </Button>
            }
          />
        ) : (
          <Section
            title="Detected Nuclear Reactors"
            buttons={
              <Button
                icon="sync"
                content="Refresh"
                onClick={() => act('PRG_refresh')}
              />
            }>
            <Table>
              {reactor_data.map((reactor) => (
                <Table.Row key={reactor.uid}>
                  <Table.Cell>
                    {reactor.uid + '. ' + reactor.area_name}
                  </Table.Cell>
                  <Table.Cell collapsing color="label">
                    Integrity:
                  </Table.Cell>
                  <Table.Cell collapsing width="120px">
                    <ProgressBar
                      value={reactor.integrity / 100}
                      ranges={{
                        good: [0.9, Infinity],
                        average: [0.5, 0.9],
                        bad: [-Infinity, 0.5],
                      }}
                    />
                  </Table.Cell>
                  <Table.Cell collapsing>
                    <Button
                      icon="bell"
                      color={focus_uid === reactor.uid && 'yellow'}
                      onClick={() =>
                        act('PRG_focus', { 'focus_uid': reactor.uid })
                      }
                    />
                  </Table.Cell>
                  <Table.Cell collapsing>
                    <Button
                      content="Details"
                      onClick={() => setActiveUID(reactor.uid)}
                    />
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </Section>
        )}
      </NtosWindow.Content>
    </NtosWindow>
  );
};
