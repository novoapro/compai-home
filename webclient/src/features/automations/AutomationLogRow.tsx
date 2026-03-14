import { memo, useMemo, useCallback } from 'react';
import { Icon } from '@/components/Icon';
import { StatusBadge } from '@/components/StatusBadge';
import type { AutomationExecutionLog } from '@/types/automation-log';
import { formatDuration } from '@/utils/date-utils';
import { useTick } from '@/hooks/useTick';
import './AutomationLogRow.css';

const STATUS_COLORS: Record<string, string> = {
  running: 'var(--status-running)',
  success: 'var(--status-active)',
  failure: 'var(--status-error)',
  skipped: 'var(--status-inactive)',
  conditionNotMet: 'var(--status-inactive)',
  cancelled: 'var(--status-inactive)',
};

interface AutomationLogRowProps {
  log: AutomationExecutionLog;
  index?: number;
  onClick: (logId: string) => void;
}

export const AutomationLogRow = memo(function AutomationLogRow({ log, index = 0, onClick }: AutomationLogRowProps) {
  const statusColor = STATUS_COLORS[log.status] || 'var(--tint-main)';

  const timeStr = useMemo(() => {
    return new Date(log.triggeredAt).toLocaleTimeString(undefined, {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  }, [log.triggeredAt]);

  const tick = useTick(log.status === 'running');
  const duration = useMemo(() => {
    if (!log.completedAt && log.status !== 'running') return null;
    return formatDuration(log.triggeredAt, log.completedAt ?? undefined);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [log.triggeredAt, log.completedAt, log.status, tick]);

  const messageClass = log.status === 'failure' ? 'error'
    : log.status === 'success' ? 'success'
    : log.status === 'cancelled' ? 'cancelled'
    : '';

  const handleClick = useCallback(() => {
    onClick(log.id);
  }, [onClick, log.id]);

  return (
    <div
      className="wflr-card animate-card-enter"
      style={{ animationDelay: `${index * 30}ms` }}
      onClick={handleClick}
    >
      <div className="wflr-status-icon" style={{ color: statusColor }}>
        {log.status === 'running' ? (
          <span className="animate-pulse-custom">
            <Icon name="bolt-circle-fill" size={32} />
          </span>
        ) : (
          <Icon name="bolt-circle-fill" size={32} />
        )}
      </div>

      <div className="wflr-content">
        <div className="wflr-header-row">
          <span className="wflr-name">{log.automationName}</span>
          <StatusBadge status={log.status} />
        </div>
        {log.triggerEvent?.triggerDescription && (
          <div className="wflr-trigger-text">{log.triggerEvent.triggerDescription}</div>
        )}
        <div className="wflr-meta-row">
          <span className="wflr-step-count">{log.blockResults.length} steps</span>
          {log.errorMessage && (
            <span className={`wflr-message ${messageClass}`}>{log.errorMessage}</span>
          )}
        </div>
      </div>

      <div className="wflr-time-col">
        <span className="wflr-time">{timeStr}</span>
        {duration && <span className="wflr-duration">{duration}</span>}
      </div>

      <Icon name="chevron-right" size={14} className="wflr-chevron" />
    </div>
  );
});
