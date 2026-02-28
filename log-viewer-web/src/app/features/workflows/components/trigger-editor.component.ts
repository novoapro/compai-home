import { Component, input, output, computed, inject } from '@angular/core';
import { WorkflowTriggerDraft } from '../workflow-editor.types';
import { DevicePickerComponent, DevicePickerValue } from './device-picker.component';
import { DeviceRegistryService } from '../../../core/services/device-registry.service';
import { triggerAutoName, parseSmartValue } from '../workflow-editor-utils';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonToggleModule } from '@angular/material/button-toggle';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';

const TRIGGER_TYPES = [
  { value: 'deviceStateChange', label: 'Device State Change' },
  { value: 'schedule', label: 'Schedule' },
  { value: 'sunEvent', label: 'Sun Event' },
  { value: 'webhook', label: 'Webhook' },
  { value: 'workflow', label: 'Callable (by other workflows)' },
];

const SCHEDULE_TYPES = [
  { value: 'once', label: 'Once' },
  { value: 'daily', label: 'Daily' },
  { value: 'weekly', label: 'Weekly' },
  { value: 'interval', label: 'Interval' },
];

const TRIGGER_CONDITIONS = [
  { value: 'changed', label: 'Changes' },
  { value: 'equals', label: 'Equals' },
  { value: 'notEquals', label: 'Not Equals' },
  { value: 'greaterThan', label: 'Greater Than' },
  { value: 'lessThan', label: 'Less Than' },
  { value: 'greaterThanOrEqual', label: 'Greater Than or Equal' },
  { value: 'lessThanOrEqual', label: 'Less Than or Equal' },
  { value: 'transitioned', label: 'Transitioned' },
];

const RETRIGGER_POLICIES = [
  { value: 'ignoreNew', label: 'Ignore new (default)' },
  { value: 'cancelAndRestart', label: 'Cancel & restart' },
  { value: 'queueAndExecute', label: 'Queue & execute' },
  { value: 'cancelOnly', label: 'Cancel only' },
];

const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

@Component({
  selector: 'app-trigger-editor',
  standalone: true,
  imports: [DevicePickerComponent, MatFormFieldModule, MatInputModule, MatSelectModule, MatButtonToggleModule, MatButtonModule, MatIconModule],
  template: `
    <div class="trigger-editor">
      <!-- Header -->
      <div class="trigger-header">
        <span class="trigger-index">Trigger {{ index() + 1 }}</span>
        <span class="trigger-auto-name">{{ autoDescription() }}</span>
        <button mat-icon-button (click)="removed.emit()" title="Remove trigger" class="remove-btn">
          <mat-icon>cancel</mat-icon>
        </button>
      </div>

      <!-- Type picker -->
      <mat-form-field appearance="fill">
        <mat-label>Type</mat-label>
        <mat-select [value]="draft().type" (selectionChange)="onTypeChange($event.value)">
          @for (t of triggerTypes; track t.value) {
            <mat-option [value]="t.value">{{ t.label }}</mat-option>
          }
        </mat-select>
      </mat-form-field>

      <!-- Per-type fields -->
      @switch (draft().type) {
        @case ('deviceStateChange') {
          <app-device-picker
            [initialDeviceId]="draft().deviceId"
            [initialServiceId]="draft().serviceId"
            [initialCharId]="draft().characteristicId"
            (changed)="onDevicePicked($event)"
          />
          <mat-form-field appearance="fill">
            <mat-label>Condition</mat-label>
            <mat-select [value]="conditionType()" (selectionChange)="onConditionTypeChange($event.value)">
              @for (c of triggerConditions; track c.value) {
                <mat-option [value]="c.value">{{ c.label }}</mat-option>
              }
            </mat-select>
          </mat-form-field>
          @if (conditionType() !== 'changed' && conditionType() !== 'transitioned') {
            <mat-form-field appearance="fill">
              <mat-label>Value</mat-label>
              <input matInput [value]="conditionValueStr()"
                     (change)="onConditionValueChange($event)" placeholder="e.g. true, 50, On" />
            </mat-form-field>
          }
          @if (conditionType() === 'transitioned') {
            <div class="field-row">
              <mat-form-field appearance="fill">
                <mat-label>From</mat-label>
                <input matInput [value]="conditionFromStr()"
                       (change)="onConditionFromChange($event)" placeholder="any" />
              </mat-form-field>
              <mat-form-field appearance="fill">
                <mat-label>To</mat-label>
                <input matInput [value]="conditionToStr()"
                       (change)="onConditionToChange($event)" placeholder="value" />
              </mat-form-field>
            </div>
          }
        }

        @case ('schedule') {
          <mat-form-field appearance="fill">
            <mat-label>Schedule Type</mat-label>
            <mat-select [value]="draft().scheduleType || 'daily'"
                        (selectionChange)="onScheduleTypeChange($event.value)">
              @for (s of scheduleTypes; track s.value) {
                <mat-option [value]="s.value">{{ s.label }}</mat-option>
              }
            </mat-select>
          </mat-form-field>

          @switch (draft().scheduleType || 'daily') {
            @case ('once') {
              <mat-form-field appearance="fill">
                <mat-label>Date</mat-label>
                <input matInput type="date" [value]="draft().scheduleDate || ''"
                       (change)="patchScheduleDate($event)" />
              </mat-form-field>
            }
            @case ('daily') {
              <mat-form-field appearance="fill">
                <mat-label>Time</mat-label>
                <input matInput type="time"
                       [value]="timeString(draft().scheduleTime)"
                       (change)="onTimeChange($event)" />
              </mat-form-field>
            }
            @case ('weekly') {
              <mat-form-field appearance="fill">
                <mat-label>Time</mat-label>
                <input matInput type="time"
                       [value]="timeString(draft().scheduleTime)"
                       (change)="onTimeChange($event)" />
              </mat-form-field>
              <div class="day-picker-section">
                <span class="day-label">Days</span>
                <mat-button-toggle-group multiple [value]="draft().scheduleDays || []"
                                         (change)="onDaysChange($event)">
                  @for (day of days; track $index) {
                    <mat-button-toggle [value]="$index">{{ day }}</mat-button-toggle>
                  }
                </mat-button-toggle-group>
              </div>
            }
            @case ('interval') {
              <mat-form-field appearance="fill">
                <mat-label>Every (seconds)</mat-label>
                <input matInput type="number" min="1"
                       [value]="draft().scheduleIntervalSeconds || 60"
                       (change)="patchInterval($event)" />
              </mat-form-field>
            }
          }
        }

        @case ('sunEvent') {
          <div class="field-row">
            <mat-form-field appearance="fill">
              <mat-label>Event</mat-label>
              <mat-select [value]="draft().event || 'sunrise'"
                          (selectionChange)="patchEvent($event.value)">
                <mat-option value="sunrise">Sunrise</mat-option>
                <mat-option value="sunset">Sunset</mat-option>
              </mat-select>
            </mat-form-field>
            <mat-form-field appearance="fill">
              <mat-label>Offset (minutes)</mat-label>
              <input matInput type="number"
                     [value]="draft().offsetMinutes ?? 0"
                     (change)="patchOffset($event)"
                     placeholder="0 = exact, negative = before" />
            </mat-form-field>
          </div>
        }

        @case ('webhook') {
          <div class="info-box">
            <strong>Token:</strong> {{ draft().token || '(auto-generated on save)' }}
          </div>
        }

        @case ('workflow') {
          <div class="info-box">
            This workflow can be triggered by other workflows using the Execute Workflow block.
          </div>
        }
      }

      <!-- Retrigger policy (shared, except webhook/workflow/schedule) -->
      @if (draft().type === 'deviceStateChange' || draft().type === 'sunEvent') {
        <mat-form-field appearance="fill">
          <mat-label>Retrigger Policy</mat-label>
          <mat-select [value]="draft().retriggerPolicy || 'ignoreNew'"
                      (selectionChange)="patchRetrigger($event.value)">
            @for (p of retriggerPolicies; track p.value) {
              <mat-option [value]="p.value">{{ p.label }}</mat-option>
            }
          </mat-select>
        </mat-form-field>
      }

      <!-- Optional name -->
      <mat-form-field appearance="fill">
        <mat-label>Label (optional)</mat-label>
        <input matInput [value]="draft().name || ''"
               (change)="patchTriggerName($event)"
               placeholder="Human-readable label" />
      </mat-form-field>
    </div>
  `,
  styles: [`
    .trigger-editor {
      display: flex;
      flex-direction: column;
      gap: 2px;
    }
    .trigger-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: var(--spacing-xs);
    }
    .trigger-index {
      font-size: 10px;
      font-weight: var(--font-weight-bold);
      color: var(--text-tertiary);
      text-transform: uppercase;
      letter-spacing: 0.1em;
      flex-shrink: 0;
    }
    .trigger-auto-name {
      flex: 1;
      font-size: var(--font-size-sm);
      font-weight: var(--font-weight-medium);
      color: var(--text-primary);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .remove-btn {
      --mdc-icon-button-icon-color: var(--status-error);
      opacity: 0.6;
    }
    .remove-btn:hover { opacity: 1; }
    .field-row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: var(--spacing-sm);
    }
    .day-picker-section {
      display: flex;
      flex-direction: column;
      gap: 6px;
      margin-bottom: var(--spacing-sm);
    }
    .day-label {
      font-size: 10px;
      font-weight: var(--font-weight-semibold);
      color: var(--text-tertiary);
      letter-spacing: 0.04em;
      text-transform: uppercase;
    }
    mat-form-field {
      width: 100%;
    }
    .info-box {
      padding: var(--spacing-sm) var(--spacing-md);
      border-radius: var(--radius-sm);
      background: color-mix(in srgb, var(--tint-secondary) 8%, transparent);
      color: var(--text-secondary);
      font-size: var(--font-size-sm);
      line-height: 1.5;
    }
  `]
})
export class TriggerEditorComponent {
  private registry = inject(DeviceRegistryService);

  index = input.required<number>();
  draft = input.required<WorkflowTriggerDraft>();
  changed = output<WorkflowTriggerDraft>();
  removed = output<void>();

  readonly autoDescription = computed(() => {
    const d = this.draft();
    return d.name || triggerAutoName(d, this.registry);
  });

  readonly triggerTypes = TRIGGER_TYPES;
  readonly scheduleTypes = SCHEDULE_TYPES;
  readonly triggerConditions = TRIGGER_CONDITIONS;
  readonly retriggerPolicies = RETRIGGER_POLICIES;
  readonly days = DAYS;

  readonly conditionType = computed(() => (this.draft().condition as any)?.type ?? 'changed');
  readonly conditionValueStr = computed(() => {
    const v = (this.draft().condition as any)?.value;
    return v !== undefined ? String(v) : '';
  });
  readonly conditionFromStr = computed(() => {
    const v = (this.draft().condition as any)?.from;
    return v !== undefined ? String(v) : '';
  });
  readonly conditionToStr = computed(() => {
    const v = (this.draft().condition as any)?.to;
    return v !== undefined ? String(v) : '';
  });

  patch(changes: Partial<WorkflowTriggerDraft>): void {
    this.changed.emit({ ...this.draft(), ...changes });
  }

  onTypeChange(type: string): void {
    const base = { ...this.draft(), type: type as WorkflowTriggerDraft['type'] };
    delete (base as any).deviceId;
    delete (base as any).serviceId;
    delete (base as any).characteristicId;
    delete (base as any).condition;
    delete (base as any).scheduleType;
    delete (base as any).scheduleDate;
    delete (base as any).scheduleTime;
    delete (base as any).scheduleDays;
    delete (base as any).scheduleIntervalSeconds;
    delete (base as any).event;
    delete (base as any).offsetMinutes;
    if (type === 'schedule') base.scheduleType = 'daily';
    if (type === 'sunEvent') { base.event = 'sunrise'; base.offsetMinutes = 0; }
    this.changed.emit(base);
  }

  onDevicePicked(val: DevicePickerValue): void {
    this.patch({ deviceId: val.deviceId, serviceId: val.serviceId, characteristicId: val.characteristicId });
  }

  onConditionTypeChange(type: string): void {
    let condition: any = { type };
    if (type !== 'changed') condition.value = true;
    if (type === 'transitioned') { delete condition.value; condition.from = undefined; condition.to = true; }
    this.patch({ condition });
  }

  onConditionValueChange(event: Event): void {
    const raw = (event.target as HTMLInputElement).value;
    const current = { ...(this.draft().condition ?? { type: 'equals' }) } as any;
    current.value = parseSmartValue(raw);
    this.patch({ condition: current });
  }

  onConditionFromChange(event: Event): void {
    const raw = (event.target as HTMLInputElement).value;
    const current = { ...(this.draft().condition ?? { type: 'transitioned' }) } as any;
    current.from = raw === '' ? undefined : parseSmartValue(raw);
    this.patch({ condition: current });
  }

  onConditionToChange(event: Event): void {
    const raw = (event.target as HTMLInputElement).value;
    const current = { ...(this.draft().condition ?? { type: 'transitioned' }) } as any;
    current.to = parseSmartValue(raw);
    this.patch({ condition: current });
  }

  onScheduleTypeChange(scheduleType: string): void {
    this.patch({ scheduleType, scheduleDays: scheduleType === 'weekly' ? [1, 2, 3, 4, 5] : undefined });
  }

  onTimeChange(event: Event): void {
    const val = (event.target as HTMLInputElement).value;
    const [hourStr, minuteStr] = val.split(':');
    this.patch({ scheduleTime: { hour: +hourStr, minute: +minuteStr } });
  }

  onDaysChange(event: any): void {
    this.patch({ scheduleDays: (event.value as number[]).sort() });
  }

  timeString(t: { hour: number; minute: number } | undefined): string {
    if (!t) return '08:00';
    return `${String(t.hour).padStart(2, '0')}:${String(t.minute).padStart(2, '0')}`;
  }

  patchEvent(value: string): void {
    this.patch({ event: value as any });
  }

  patchScheduleDate(e: Event): void {
    this.patch({ scheduleDate: (e.target as HTMLInputElement).value });
  }

  patchInterval(e: Event): void {
    this.patch({ scheduleIntervalSeconds: +(e.target as HTMLInputElement).value });
  }

  patchOffset(e: Event): void {
    this.patch({ offsetMinutes: +(e.target as HTMLInputElement).value });
  }

  patchTriggerName(e: Event): void {
    this.patch({ name: (e.target as HTMLInputElement).value || undefined });
  }

  patchRetrigger(value: string): void {
    this.patch({ retriggerPolicy: value });
  }
}
