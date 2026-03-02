import { Icon } from '@/components/Icon';
import { getServiceIcon } from '@/utils/service-icons';
import { CharacteristicsTable } from './CharacteristicsTable';
import type { RESTDevice } from '@/types/homekit-device';

interface DeviceCardProps {
  device: RESTDevice;
  isExpanded: boolean;
  onToggle: () => void;
}

export function DeviceCard({ device, isExpanded, onToggle }: DeviceCardProps) {
  const primaryService = device.services[0];
  const iconName = getServiceIcon(primaryService?.type) ?? getServiceIcon(primaryService?.name) ?? 'house';
  const serviceCount = device.services.length;

  return (
    <div className={`device-card ${isExpanded ? 'expanded' : ''}`}>
      <button className="device-card-header" onClick={onToggle} type="button">
        <span className="device-card-icon">
          <Icon name={iconName} size={22} style={{ color: 'var(--tint-main)' }} />
        </span>
        <div className="device-card-info">
          <span className="device-card-name">{device.name}</span>
          <span className="device-card-meta">
            {device.room && (
              <span className="device-room-badge">{device.room}</span>
            )}
            <span className="device-service-count">
              {serviceCount} {serviceCount === 1 ? 'service' : 'services'}
            </span>
          </span>
        </div>
        <div className="device-card-right">
          <span
            className={`reachability-dot ${device.isReachable ? 'reachable' : 'unreachable'}`}
            title={device.isReachable ? 'Reachable' : 'Unreachable'}
          />
          <Icon
            name={isExpanded ? 'chevron-down' : 'chevron-right'}
            size={18}
            className="device-card-chevron"
          />
        </div>
      </button>

      {isExpanded && (
        <div className="device-card-body">
          {device.services.map(svc => {
            const svcIcon = getServiceIcon(svc.type) ?? getServiceIcon(svc.name) ?? 'slider-horizontal';
            return (
              <div key={svc.id} className="device-service-section">
                <div className="device-service-header">
                  <Icon name={svcIcon} size={16} style={{ color: 'var(--text-secondary)' }} />
                  <span className="device-service-name">{svc.name}</span>
                  <span className="device-service-type-badge">{svc.type}</span>
                </div>
                <CharacteristicsTable
                  characteristics={svc.characteristics}
                  serviceId={svc.id}
                />
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
