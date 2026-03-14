import { memo, useMemo, useRef, useCallback } from 'react';
import { Icon } from '@/components/Icon';
import type { Automation, TriggerTypeKey } from '@/types/automation-log';
import { TRIGGER_TYPE_LABELS, TRIGGER_TYPE_ICONS } from '@/types/automation-log';
import { relativeTime } from '@/utils/date-utils';
import './AutomationCard.css';

interface AutomationCardProps {
  automation: Automation;
  index?: number;
  onToggleEnabled: (automationId: string, enabled: boolean) => void;
  onDelete: (automationId: string) => void;
  onClick: (automationId: string) => void;
  selectionMode?: boolean;
  isSelected?: boolean;
  onSelect?: (automationId: string) => void;
  onLongPress?: (automationId: string) => void;
}

const SWIPE_THRESHOLD = 80;
const LONG_PRESS_DELAY = 500;

export const AutomationCard = memo(function AutomationCard({
  automation,
  index = 0,
  onToggleEnabled,
  onDelete,
  onClick,
  selectionMode = false,
  isSelected = false,
  onSelect,
  onLongPress,
}: AutomationCardProps) {
  const triggerType: TriggerTypeKey = automation.triggers.length > 0
    ? (automation.triggers[0]?.type ?? 'deviceStateChange')
    : 'deviceStateChange';

  const triggerIcon = TRIGGER_TYPE_ICONS[triggerType];
  const triggerLabel = TRIGGER_TYPE_LABELS[triggerType];

  const statusColor = useMemo(() => {
    if (!automation.isEnabled) return 'var(--status-inactive)';
    if (automation.metadata.consecutiveFailures > 0) return 'var(--status-error)';
    if (automation.metadata.totalExecutions > 0) return 'var(--status-active)';
    return 'var(--tint-main)';
  }, [automation.isEnabled, automation.metadata.consecutiveFailures, automation.metadata.totalExecutions]);

  const statusBg = `color-mix(in srgb, ${statusColor} 15%, transparent)`;
  const pillBg = `color-mix(in srgb, ${statusColor} 12%, transparent)`;

  // Swipe state refs (no re-renders needed during gesture)
  const containerRef = useRef<HTMLDivElement>(null);
  const cardRef = useRef<HTMLDivElement>(null);
  const startXRef = useRef(0);
  const currentXRef = useRef(0);
  const swipingRef = useRef(false);
  const longPressTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const didLongPressRef = useRef(false);

  const clearLongPress = useCallback(() => {
    if (longPressTimerRef.current) {
      clearTimeout(longPressTimerRef.current);
      longPressTimerRef.current = null;
    }
  }, []);

  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    if (selectionMode) return;
    const touch = e.touches[0]!;
    startXRef.current = touch.clientX;
    currentXRef.current = 0;
    swipingRef.current = false;
    didLongPressRef.current = false;

    // Start long-press timer
    longPressTimerRef.current = setTimeout(() => {
      didLongPressRef.current = true;
      onLongPress?.(automation.id);
      // Vibrate if available
      if (navigator.vibrate) navigator.vibrate(30);
    }, LONG_PRESS_DELAY);
  }, [selectionMode, onLongPress, automation.id]);

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    if (selectionMode) return;
    const touch = e.touches[0]!;
    const diff = startXRef.current - touch.clientX;

    // If moving, cancel long press
    if (Math.abs(diff) > 10) {
      clearLongPress();
    }

    if (diff > 10) {
      if (!swipingRef.current) containerRef.current?.classList.add('swiping');
      swipingRef.current = true;
      // Apply resistance after threshold
      const capped = Math.min(diff, SWIPE_THRESHOLD * 1.8);
      currentXRef.current = capped;
      if (cardRef.current) {
        cardRef.current.style.transform = `translateX(${-capped}px)`;
        cardRef.current.style.transition = 'none';
      }
    } else if (diff < -10 && swipingRef.current) {
      // Swiping back
      currentXRef.current = 0;
      if (cardRef.current) {
        cardRef.current.style.transform = 'translateX(0)';
        cardRef.current.style.transition = 'none';
      }
    }
  }, [selectionMode, clearLongPress]);

  const handleTouchEnd = useCallback(() => {
    clearLongPress();
    if (selectionMode) return;

    if (swipingRef.current && currentXRef.current >= SWIPE_THRESHOLD) {
      // Trigger delete confirmation
      if (cardRef.current) {
        cardRef.current.style.transition = 'transform 200ms ease';
        cardRef.current.style.transform = 'translateX(0)';
      }
      onDelete(automation.id);
    } else if (swipingRef.current) {
      // Snap back
      if (cardRef.current) {
        cardRef.current.style.transition = 'transform 200ms ease';
        cardRef.current.style.transform = 'translateX(0)';
      }
    }
    swipingRef.current = false;
    currentXRef.current = 0;
    containerRef.current?.classList.remove('swiping');
  }, [selectionMode, onDelete, clearLongPress, automation.id]);

  const handleClick = useCallback(() => {
    if (didLongPressRef.current) return;
    if (selectionMode) {
      onSelect?.(automation.id);
    } else {
      onClick(automation.id);
    }
  }, [selectionMode, onSelect, onClick, automation.id]);

  const handleToggle = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    onToggleEnabled(automation.id, e.target.checked);
  }, [onToggleEnabled, automation.id]);

  return (
    <div ref={containerRef} className="auto-card-swipe-container">
      {/* Delete action revealed behind the card */}
      <div className="wf-swipe-action-delete">
        <Icon name="trash" size={18} />
        <span>Delete</span>
      </div>

      <div
        ref={cardRef}
        className={`auto-card animate-card-enter${selectionMode ? ' selection-mode' : ''}${isSelected ? ' selected' : ''}`}
        style={{ animationDelay: `${index * 40}ms` }}
        onClick={handleClick}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
      >
        {selectionMode && (
          <div className="wf-select-check">
            <div className={`wf-checkbox${isSelected ? ' checked' : ''}`}>
              {isSelected && <Icon name="checkmark" size={12} />}
            </div>
          </div>
        )}

        <div className="wf-trigger-icon" style={{ color: statusColor }}>
          <div className="wf-trigger-icon-bg" style={{ background: statusBg }}>
            <Icon name={triggerIcon} size={18} />
          </div>
        </div>

        <div className="wf-content">
          <div className="wf-name-row">
            <span className="wf-name">{automation.name}</span>
            {!automation.isEnabled && <span className="wf-disabled-badge">Disabled</span>}
          </div>

          <div className="wf-stats-row">
            <span className="wf-trigger-pill" style={{ color: statusColor, background: pillBg }}>
              {triggerLabel}
            </span>
            <span className="wf-stat">
              <Icon name="bolt-circle-fill" size={12} />
              {automation.triggers.length}
            </span>
            <span className="wf-stat">
              <Icon name="rectangles-group" size={12} />
              {automation.blocks.length}
            </span>
            {automation.metadata.totalExecutions > 0 && (
              <span className="wf-stat">
                <Icon name="play-circle-fill" size={12} />
                {automation.metadata.totalExecutions}
              </span>
            )}
          </div>

          {automation.description && (
            <div className="wf-description">{automation.description}</div>
          )}

          {automation.metadata.lastTriggeredAt && (
            <div className="wf-last-triggered">
              Last triggered {relativeTime(automation.metadata.lastTriggeredAt)}
            </div>
          )}
        </div>

        {!selectionMode && (
          <div className="wf-right-actions" onClick={e => e.stopPropagation()}>
            <label className="wf-toggle-wrapper">
              <input
                type="checkbox"
                checked={automation.isEnabled}
                onChange={handleToggle}
              />
              <span className="wf-toggle-track" />
            </label>
          </div>
        )}
      </div>
    </div>
  );
});
