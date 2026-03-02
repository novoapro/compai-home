import { useState, useMemo, useCallback } from 'react';
import { useDeviceRegistry } from '@/contexts/DeviceRegistryContext';
import { SearchableSelect } from './SearchableSelect';
import type { SelectOption } from './SearchableSelect';
import type { RESTDevice, RESTService } from '@/types/homekit-device';
import './DevicePicker.css';

export interface DevicePickerValue {
  deviceId: string;
  serviceId: string;
  characteristicId: string;
}

interface DevicePickerProps {
  initialDeviceId?: string;
  initialServiceId?: string;
  initialCharId?: string;
  /** When true, only show characteristics with write permission (and hide services/devices with none). */
  writableOnly?: boolean;
  onChange: (value: DevicePickerValue) => void;
}

export function DevicePicker({ initialDeviceId, initialServiceId, initialCharId, writableOnly = false, onChange }: DevicePickerProps) {
  const registry = useDeviceRegistry();

  const [selectedDeviceId, setSelectedDeviceId] = useState(initialDeviceId ?? '');
  const [selectedServiceId, setSelectedServiceId] = useState(initialServiceId ?? '');
  const [selectedCharId, setSelectedCharId] = useState(initialCharId ?? '');

  // Filter helpers for writableOnly mode
  const hasWritableChar = useCallback(
    (svc: RESTService) => svc.characteristics.some((c) => c.permissions.includes('write')),
    [],
  );

  const selectedDevice = useMemo<RESTDevice | undefined>(
    () => registry.devices.find((d) => d.id === selectedDeviceId),
    [registry.devices, selectedDeviceId],
  );

  const selectedService = useMemo<RESTService | undefined>(
    () => selectedDevice?.services.find((s) => s.id === selectedServiceId),
    [selectedDevice, selectedServiceId],
  );

  const deviceOptions = useMemo<SelectOption[]>(
    () => {
      let devices = registry.devices;
      if (writableOnly) {
        devices = devices.filter((d) => d.services.some(hasWritableChar));
      }
      return devices.map((d) => ({ id: d.id, label: d.name, secondary: d.room || undefined }));
    },
    [registry.devices, writableOnly, hasWritableChar],
  );

  const serviceOptions = useMemo<SelectOption[]>(
    () => {
      let services = selectedDevice?.services ?? [];
      if (writableOnly) {
        services = services.filter(hasWritableChar);
      }
      return services.map((s) => ({
        id: s.id,
        label: s.name || s.type,
        secondary: s.name ? s.type : undefined,
      }));
    },
    [selectedDevice, writableOnly, hasWritableChar],
  );

  const charOptions = useMemo<SelectOption[]>(
    () => {
      let chars = selectedService?.characteristics ?? [];
      if (writableOnly) {
        chars = chars.filter((c) => c.permissions.includes('write'));
      }
      return chars.map((c) => ({
        id: c.id,
        label: c.name || c.id,
        secondary: c.type !== c.name ? c.type : undefined,
      }));
    },
    [selectedService, writableOnly],
  );

  const emit = useCallback(
    (devId: string, svcId: string, charId: string) => {
      onChange({ deviceId: devId, serviceId: svcId, characteristicId: charId });
    },
    [onChange],
  );

  return (
    <div className="device-picker">
      <SearchableSelect
        label="Device"
        options={deviceOptions}
        selectedId={selectedDeviceId}
        placeholder="Search devices..."
        onSelect={(id) => {
          setSelectedDeviceId(id);
          setSelectedServiceId('');
          setSelectedCharId('');
          emit(id, '', '');
        }}
        onClear={() => {
          setSelectedDeviceId('');
          setSelectedServiceId('');
          setSelectedCharId('');
          emit('', '', '');
        }}
      />

      {selectedDevice && (
        <SearchableSelect
          label="Service"
          options={serviceOptions}
          selectedId={selectedServiceId}
          placeholder="Search services..."
          onSelect={(id) => {
            setSelectedServiceId(id);
            setSelectedCharId('');
            emit(selectedDeviceId, id, '');
          }}
          onClear={() => {
            setSelectedServiceId('');
            setSelectedCharId('');
            emit(selectedDeviceId, '', '');
          }}
        />
      )}

      {selectedService && (
        <SearchableSelect
          label="Characteristic"
          options={charOptions}
          selectedId={selectedCharId}
          placeholder="Search characteristics..."
          onSelect={(id) => {
            setSelectedCharId(id);
            emit(selectedDeviceId, selectedServiceId, id);
          }}
          onClear={() => {
            setSelectedCharId('');
            emit(selectedDeviceId, selectedServiceId, '');
          }}
        />
      )}
    </div>
  );
}
