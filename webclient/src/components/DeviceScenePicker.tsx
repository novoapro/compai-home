import { useMemo, useState } from 'react';
import { Icon } from './Icon';
import { getServiceIcon } from '@/utils/service-icons';
import type { RESTDevice, RESTScene } from '@/types/homekit-device';

interface DeviceScenePickerProps {
  devices: RESTDevice[];
  scenes: RESTScene[];
  selectedDeviceIds: Set<string>;
  selectedSceneIds: Set<string>;
  onToggleDevice: (id: string) => void;
  onToggleScene: (id: string) => void;
}

function getDeviceIcon(device: RESTDevice): string {
  const primary = device.services[0];
  return getServiceIcon(primary?.type) ?? getServiceIcon(primary?.name) ?? 'house';
}

export function DeviceScenePicker({
  devices, scenes, selectedDeviceIds, selectedSceneIds,
  onToggleDevice, onToggleScene,
}: DeviceScenePickerProps) {
  const [search, setSearch] = useState('');

  const query = search.toLowerCase().trim();

  const filteredDevicesByRoom = useMemo(() => {
    const filtered = query
      ? devices.filter(d =>
          d.name.toLowerCase().includes(query) ||
          (d.room?.toLowerCase().includes(query) ?? false) ||
          d.services.some(s => s.name.toLowerCase().includes(query))
        )
      : devices;

    const map = new Map<string, RESTDevice[]>();
    for (const device of filtered) {
      const room = device.room ?? 'No Room';
      const list = map.get(room) ?? [];
      list.push(device);
      map.set(room, list);
    }
    return Array.from(map.entries()).sort(([a], [b]) => a.localeCompare(b));
  }, [devices, query]);

  const filteredScenes = useMemo(() => {
    return query
      ? scenes.filter(s => s.name.toLowerCase().includes(query))
      : scenes;
  }, [scenes, query]);

  return (
    <div className="aig-picker">
      <div className="aig-picker-search">
        <Icon name="magnifying-glass" size={13} className="aig-picker-search-icon" />
        <input
          type="text"
          className="aig-picker-search-input"
          placeholder="Filter devices & scenes..."
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
        {search && (
          <button
            type="button"
            className="aig-picker-search-clear"
            onClick={() => setSearch('')}
          >
            <Icon name="xmark-circle-fill" size={14} />
          </button>
        )}
      </div>

      <div className="aig-picker-list">
        {filteredDevicesByRoom.length > 0 && (
          <div className="aig-picker-section">
            <div className="aig-picker-section-title">Devices</div>
            {filteredDevicesByRoom.map(([room, roomDevices]) => (
              <div key={room} className="aig-picker-room">
                <div className="aig-picker-room-name">{room}</div>
                {roomDevices.map(device => {
                  const selected = selectedDeviceIds.has(device.id);
                  return (
                    <div
                      key={device.id}
                      className={`aig-picker-item${selected ? ' selected' : ''}`}
                      role="checkbox"
                      aria-checked={selected}
                      tabIndex={0}
                      onClick={() => onToggleDevice(device.id)}
                      onKeyDown={e => { if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); onToggleDevice(device.id); } }}
                    >
                      <span className="aig-picker-item-icon">
                        <Icon name={getDeviceIcon(device)} size={14} />
                      </span>
                      <span className="aig-picker-item-name">{device.name}</span>
                      <span className={`aig-picker-check${selected ? ' checked' : ''}`}>
                        <Icon name={selected ? 'checkmark-circle-fill' : 'circle'} size={18} />
                      </span>
                    </div>
                  );
                })}
              </div>
            ))}
          </div>
        )}

        {filteredScenes.length > 0 && (
          <div className="aig-picker-section">
            <div className="aig-picker-section-title">Scenes</div>
            {filteredScenes.map(scene => {
              const selected = selectedSceneIds.has(scene.id);
              return (
                <div
                  key={scene.id}
                  className={`aig-picker-item${selected ? ' selected' : ''}`}
                  role="checkbox"
                  aria-checked={selected}
                  tabIndex={0}
                  onClick={() => onToggleScene(scene.id)}
                  onKeyDown={e => { if (e.key === ' ' || e.key === 'Enter') { e.preventDefault(); onToggleScene(scene.id); } }}
                >
                  <span className="aig-picker-item-icon scene">
                    <Icon name="play-circle-fill" size={14} />
                  </span>
                  <span className="aig-picker-item-name">{scene.name}</span>
                  <span className={`aig-picker-check${selected ? ' checked' : ''}`}>
                    <Icon name={selected ? 'checkmark-circle-fill' : 'circle'} size={18} />
                  </span>
                </div>
              );
            })}
          </div>
        )}

        {filteredDevicesByRoom.length === 0 && filteredScenes.length === 0 && query && (
          <div className="aig-picker-empty">No matches for &ldquo;{search}&rdquo;</div>
        )}
      </div>
    </div>
  );
}
