import { useCallback } from 'react';
import { Icon } from '@/components/Icon';
import { getServiceIcon } from '@/utils/service-icons';

interface DeviceFilterSheetProps {
  isOpen: boolean;
  availableRooms: string[];
  selectedRooms: Set<string>;
  onRoomsChange: (rooms: Set<string>) => void;
  availableServiceTypes: string[];
  selectedServiceTypes: Set<string>;
  onServiceTypesChange: (types: Set<string>) => void;
  reachabilityFilter: 'all' | 'reachable' | 'unreachable';
  onReachabilityChange: (value: 'all' | 'reachable' | 'unreachable') => void;
  onClearAll: () => void;
  onClose: () => void;
}

export function DeviceFilterSheet({
  isOpen,
  availableRooms,
  selectedRooms,
  onRoomsChange,
  availableServiceTypes,
  selectedServiceTypes,
  onServiceTypesChange,
  reachabilityFilter,
  onReachabilityChange,
  onClearAll,
  onClose,
}: DeviceFilterSheetProps) {
  const toggleRoom = useCallback((room: string) => {
    const next = new Set(selectedRooms);
    if (next.has(room)) next.delete(room);
    else next.add(room);
    onRoomsChange(next);
  }, [selectedRooms, onRoomsChange]);

  const toggleServiceType = useCallback((type: string) => {
    const next = new Set(selectedServiceTypes);
    if (next.has(type)) next.delete(type);
    else next.add(type);
    onServiceTypesChange(next);
  }, [selectedServiceTypes, onServiceTypesChange]);

  if (!isOpen) return null;

  return (
    <>
      <div className="fs-backdrop" onClick={onClose} />
      <div className="fs-panel">
        <div className="fs-handle" />

        <div className="fs-header">
          <h3 className="fs-title">Filters</h3>
          <button className="fs-close" onClick={onClose} aria-label="Close filters">
            <Icon name="xmark" size={16} />
          </button>
        </div>

        <div className="fs-body">
          {/* Rooms */}
          {availableRooms.length > 0 && (
            <div className="fs-section">
              <div className="fs-section-label">Room</div>
              <div className="fs-chip-grid">
                {availableRooms.map(room => (
                  <button
                    key={room}
                    className={`fs-chip ${selectedRooms.has(room) ? 'selected' : ''}`}
                    onClick={() => toggleRoom(room)}
                  >
                    <Icon name="map-pin" size={14} />
                    <span>{room}</span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Service types */}
          {availableServiceTypes.length > 0 && (
            <div className="fs-section">
              <div className="fs-section-label">Service Type</div>
              <div className="fs-chip-grid">
                {availableServiceTypes.map(type => {
                  const icon = getServiceIcon(type) ?? 'slider-horizontal';
                  return (
                    <button
                      key={type}
                      className={`fs-chip ${selectedServiceTypes.has(type) ? 'selected' : ''}`}
                      onClick={() => toggleServiceType(type)}
                    >
                      <Icon name={icon} size={14} />
                      <span>{type}</span>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Reachability */}
          <div className="fs-section">
            <div className="fs-section-label">Status</div>
            <div className="fs-chip-grid">
              {(['all', 'reachable', 'unreachable'] as const).map(opt => (
                <button
                  key={opt}
                  className={`fs-chip ${reachabilityFilter === opt ? 'selected' : ''}`}
                  onClick={() => onReachabilityChange(opt)}
                >
                  {opt === 'all' && <><Icon name="wifi" size={14} /><span>All</span></>}
                  {opt === 'reachable' && <><Icon name="wifi" size={14} /><span>Reachable</span></>}
                  {opt === 'unreachable' && <><Icon name="wifi-off" size={14} /><span>Unreachable</span></>}
                </button>
              ))}
            </div>
          </div>
        </div>

        <div className="fs-actions">
          <button className="fs-clear-btn" onClick={onClearAll}>Clear All</button>
          <button className="fs-done-btn" onClick={onClose}>Done</button>
        </div>
      </div>
    </>
  );
}
