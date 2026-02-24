import { Component, input, computed } from '@angular/core';
import { WorkflowExecutionLog } from '../../../core/models/workflow-log.model';
import { IconComponent } from '../../../shared/components/icon.component';
import { StatusBadgeComponent } from '../../../shared/components/status-badge.component';
import { DurationPipe } from '../../../shared/pipes/duration.pipe';

@Component({
  selector: 'app-workflow-log-row',
  standalone: true,
  imports: [IconComponent, StatusBadgeComponent, DurationPipe],
  template: `
    <div class="workflow-row">
      <!-- Status icon -->
      <div class="status-icon" [style.color]="statusColor()">
        @if (log().status === 'running') {
          <span class="animate-pulse">
            <app-icon name="bolt-circle-fill" [size]="28" />
          </span>
        } @else {
          <app-icon name="bolt-circle-fill" [size]="28" />
        }
      </div>

      <!-- Content -->
      <div class="content">
        <div class="header-row">
          <span class="workflow-name">{{ log().workflowName }}</span>
          <app-status-badge [status]="log().status" />
        </div>
        @if (log().triggerEvent?.triggerDescription) {
          <div class="trigger-text">{{ log().triggerEvent!.triggerDescription }}</div>
        }
        <div class="meta-row">
          <span class="step-count">{{ log().blockResults.length }} steps</span>
          @if (log().errorMessage) {
            <span class="error-text">{{ log().errorMessage }}</span>
          }
        </div>
      </div>

      <!-- Time -->
      <div class="time-col">
        <span class="time">{{ timeStr() }}</span>
        <span class="duration">
          @if (log().completedAt) {
            {{ log().triggeredAt | duration: log().completedAt }}
          } @else if (log().status === 'running') {
            {{ log().triggeredAt | duration }}
          }
        </span>
      </div>

      <!-- Chevron -->
      <app-icon name="chevron-right" [size]="14" />
    </div>
  `,
  styles: [`
    .workflow-row {
      display: flex;
      align-items: flex-start;
      gap: var(--spacing-sm);
      padding: var(--spacing-sm) var(--spacing-md);
      background: var(--bg-content);
      border-bottom: 1px solid var(--border-color);
      cursor: pointer;
      transition: background var(--transition-fast);
    }
    .workflow-row:hover {
      background: var(--bg-hover);
    }
    .status-icon {
      flex-shrink: 0;
    }
    .content {
      flex: 1;
      min-width: 0;
    }
    .header-row {
      display: flex;
      align-items: center;
      gap: var(--spacing-sm);
      flex-wrap: wrap;
    }
    .workflow-name {
      font-size: var(--font-size-base);
      font-weight: var(--font-weight-semibold);
      color: var(--text-primary);
    }
    .trigger-text {
      font-size: var(--font-size-sm);
      color: var(--text-secondary);
      margin-top: 2px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .meta-row {
      display: flex;
      align-items: center;
      gap: var(--spacing-sm);
      margin-top: 2px;
    }
    .step-count {
      font-size: var(--font-size-xs);
      color: var(--text-tertiary);
    }
    .error-text {
      font-size: var(--font-size-xs);
      color: var(--status-error);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .time-col {
      display: flex;
      flex-direction: column;
      align-items: flex-end;
      flex-shrink: 0;
    }
    .time {
      font-size: var(--font-size-xs);
      color: var(--text-tertiary);
    }
    .duration {
      font-size: var(--font-size-xs);
      color: var(--text-tertiary);
      font-family: var(--font-mono);
    }
    app-icon {
      color: var(--text-tertiary);
      flex-shrink: 0;
      padding-top: 6px;
    }
    @media (max-width: 768px) {
      .workflow-row {
        padding: var(--spacing-xs) var(--spacing-sm);
        gap: var(--spacing-xs);
      }
      .workflow-name {
        font-size: var(--font-size-sm);
      }
      .trigger-text {
        font-size: var(--font-size-xs);
      }
    }
    @media (max-width: 480px) {
      .time-col {
        display: none;
      }
      .meta-row {
        flex-wrap: wrap;
      }
    }
  `]
})
export class WorkflowLogRowComponent {
  log = input.required<WorkflowExecutionLog>();

  readonly statusColor = computed(() => {
    const map: Record<string, string> = {
      running: 'var(--status-running)',
      success: 'var(--status-active)',
      failure: 'var(--status-error)',
      skipped: 'var(--status-inactive)',
      conditionNotMet: 'var(--status-warning)',
      cancelled: 'var(--status-inactive)',
    };
    return map[this.log().status] || 'var(--tint-main)';
  });

  readonly timeStr = computed(() => {
    return new Date(this.log().triggeredAt).toLocaleTimeString(undefined, {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  });
}
