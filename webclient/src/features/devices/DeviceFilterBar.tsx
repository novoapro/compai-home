import { Icon } from '@/components/Icon';

interface DeviceFilterBarProps {
  searchText: string;
  onSearchChange: (value: string) => void;
  availableRooms: string[];
  selectedRooms: Set<string>;
  onRoomsChange: (rooms: Set<string>) => void;
  availableServiceTypes: string[];
  selectedServiceTypes: Set<string>;
  onServiceTypesChange: (types: Set<string>) => void;
  reachabilityFilter: 'all' | 'reachable' | 'unreachable';
  onReachabilityChange: (value: 'all' | 'reachable' | 'unreachable') => void;
  hasActiveFilters: boolean;
  onClearFilters: () => void;
}

export function DeviceFilterBar({
  searchText,
  onSearchChange,
  availableRooms,
  selectedRooms,
  onRoomsChange,
  availableServiceTypes,
  selectedServiceTypes,
  onServiceTypesChange,
  reachabilityFilter,
  onReachabilityChange,
  hasActiveFilters,
  onClearFilters,
}: DeviceFilterBarProps) {
  const toggleRoom = (room: string) => {
    const next = new Set(selectedRooms);
    if (next.has(room)) next.delete(room);
    else next.add(room);
    onRoomsChange(next);
  };

  const toggleServiceType = (type: string) => {
    const next = new Set(selectedServiceTypes);
    if (next.has(type)) next.delete(type);
    else next.add(type);
    onServiceTypesChange(next);
  };

  return (
    <div className="device-filter-bar">
      <div className="device-filter-search">
        <Icon name="magnifying-glass" size={16} className="device-filter-search-icon" />
        <input
          type="text"
          className="device-filter-search-input"
          placeholder="Search devices..."
          value={searchText}
          onChange={e => onSearchChange(e.target.value)}
        />
        {searchText && (
          <button
            className="device-filter-search-clear"
            onClick={() => onSearchChange('')}
            type="button"
            aria-label="Clear search"
          >
            <Icon name="xmark" size={14} />
          </button>
        )}
      </div>

      <div className="device-filter-chips">
        {/* Room chips */}
        {availableRooms.length > 0 && (
          <div className="device-filter-group">
            <span className="device-filter-group-label">Room</span>
            <div className="device-filter-chip-row">
              {availableRooms.map(room => (
                <button
                  key={room}
                  className={`device-filter-chip ${selectedRooms.has(room) ? 'active' : ''}`}
                  onClick={() => toggleRoom(room)}
                  type="button"
                >
                  {room}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Service type chips */}
        {availableServiceTypes.length > 0 && (
          <div className="device-filter-group">
            <span className="device-filter-group-label">Type</span>
            <div className="device-filter-chip-row">
              {availableServiceTypes.map(type => (
                <button
                  key={type}
                  className={`device-filter-chip ${selectedServiceTypes.has(type) ? 'active' : ''}`}
                  onClick={() => toggleServiceType(type)}
                  type="button"
                >
                  {type}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Reachability */}
        <div className="device-filter-group">
          <span className="device-filter-group-label">Status</span>
          <div className="device-filter-chip-row">
            {(['all', 'reachable', 'unreachable'] as const).map(opt => (
              <button
                key={opt}
                className={`device-filter-chip ${reachabilityFilter === opt ? 'active' : ''}`}
                onClick={() => onReachabilityChange(opt)}
                type="button"
              >
                {opt === 'all' && 'All'}
                {opt === 'reachable' && (
                  <><Icon name="wifi" size={13} style={{ marginRight: 2 }} /> Reachable</>
                )}
                {opt === 'unreachable' && (
                  <><Icon name="wifi-off" size={13} style={{ marginRight: 2 }} /> Unreachable</>
                )}
              </button>
            ))}
          </div>
        </div>
      </div>

      {hasActiveFilters && (
        <button className="device-filter-clear-btn" onClick={onClearFilters} type="button">
          <Icon name="xmark" size={14} />
          Clear filters
        </button>
      )}
    </div>
  );
}
