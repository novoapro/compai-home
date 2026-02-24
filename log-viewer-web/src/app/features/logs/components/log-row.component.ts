import { Component, input, signal, computed } from '@angular/core';
import { StateChangeLog, LogCategory } from '../../../core/models/state-change-log.model';
import { CategoryIconComponent } from '../../../shared/components/category-icon.component';
import { IconComponent } from '../../../shared/components/icon.component';
import { LogDetailPanelComponent } from './log-detail-panel.component';

@Component({
  selector: 'app-log-row',
  standalone: true,
  imports: [CategoryIconComponent, IconComponent, LogDetailPanelComponent],
  templateUrl: './log-row.component.html',
  styleUrl: './log-row.component.css',
})
export class LogRowComponent {
  log = input.required<StateChangeLog>();

  expanded = signal(false);

  readonly isExpandable = computed(() => {
    const l = this.log();
    return !!(l.detailedRequestBody || l.detailedResponseBody || l.requestBody || l.responseBody);
  });

  readonly isError = computed(() => {
    const cat = this.log().category;
    return cat === LogCategory.WebhookError ||
      cat === LogCategory.ServerError ||
      cat === LogCategory.WorkflowError ||
      cat === LogCategory.SceneError;
  });

  readonly timeStr = computed(() => {
    return new Date(this.log().timestamp).toLocaleTimeString(undefined, {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  });

  readonly formattedOldValue = computed(() => this.formatValue(this.log().oldValue));
  readonly formattedNewValue = computed(() => this.formatValue(this.log().newValue));

  readonly showValueChange = computed(() => {
    const l = this.log();
    return l.category === LogCategory.StateChange && (l.oldValue !== undefined || l.newValue !== undefined);
  });

  readonly showServiceBadge = computed(() => {
    const l = this.log();
    return l.serviceName &&
      l.category !== LogCategory.McpCall &&
      l.category !== LogCategory.RestCall;
  });

  toggle(): void {
    if (this.isExpandable()) {
      this.expanded.set(!this.expanded());
    }
  }

  private formatValue(val: any): string {
    if (val === undefined || val === null) return '—';
    if (typeof val === 'boolean') return val ? 'on' : 'off';
    if (typeof val === 'number') return String(val);
    if (typeof val === 'string') return val;
    return JSON.stringify(val);
  }
}
